# Florence2 Vision API Server
# 
# This script defines a FastAPI server that listens for incoming requests and processes them using the Florence-2 model.
# The server exposes two endpoints:
# - /prompts: Returns a list of prompts that can be used with the Florence-2 model.
# - /process_image: Processes an image with a given prompt using the Florence-2 model.
#
# The server loads the Florence-2 model when the first request is received and unloads it after a period of inactivity.
# The server uses a queue to process incoming requests asynchronously and in order.
# The server also uses a background task to periodically check if the model has been inactive for a period of time and unload it if necessary.
#
# Usage: python vision-server.py [--host HOST] [--port PORT]
#
# Author: Steve Goodman (spgoodman)
# Date: 2024-10-13
# License: MIT
import base64
from PIL import Image
from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
from contextlib import asynccontextmanager
from pydantic import BaseModel
import torch
import io
import os
from unittest.mock import patch
from transformers.dynamic_module_utils import get_imports
import torchvision.transforms.functional as F
from torchvision import transforms
from transformers import AutoProcessor, AutoModelForCausalLM
import asyncio
from typing import List
import time
import logging
import warnings


logging.basicConfig(level=logging.INFO)
warnings.filterwarnings("ignore")

logger = logging.getLogger("uvicorn")

unload_after_seconds = 300

# Recommended models:
# MiaoshouAI/Florence-2-large-PromptGen-v2.0
# MiaoshouAI/Florence-2-base-PromptGen-v2.0 < smaller and about 20% faster
florence2_model = "MiaoshouAI/Florence-2-base-PromptGen-v2.0"
# List of prompts that can be used with the MiaoshouAI/Florence-2-large-PromptGen-v2.0 and MiaoshouAI/Florence-2-base-PromptGen-v2.0 model. You can add additional prompts from the standard Florence-2 models
florence2_prompts = [
    "<GENERATE_TAGS>",
    "<CAPTION>",
    "<DETAILED_CAPTION>",
    "<MORE_DETAILED_CAPTION>",
    "<ANALYZE>",
    "<MIXED_CAPTION>",
    "<MIXED_CAPTION_PLUS>"
]

class ImageRequest(BaseModel):
    image: str
    prompt: str

class ImageResponse(BaseModel):
    result: str

hf_model = None
device = None
torch_dtype = None
processor = None
last_use_time = 0
model_lock = asyncio.Lock()
request_queue = asyncio.Queue()
torch_compile = False

# Load the model if it has not been loaded yet
def load_model():
    global hf_model, processor, florence2_model, device, torch_dtype, last_use_time, torch_compile
    last_use_time = time.time()
    attention = None
    if hf_model is None:
        logger.info("Loading model")
        if torch.cuda.is_available():
            attention = 'sdpa'
            logger.info("CUDA is available")
            torch_dtype = torch.float16
            device = "cuda:0"
                
        else:
            logger.info("CUDA is not available, using CPU")
            attention = 'full'
            device = "cpu"
            torch_dtype = torch.float32
        hf_model = AutoModelForCausalLM.from_pretrained(florence2_model, attn_implementation=attention, device_map=device,torch_dtype=torch_dtype, trust_remote_code=True).to(device)
        processor = AutoProcessor.from_pretrained(florence2_model, trust_remote_code=True)
        if torch_compile:
            logger.info("Compiling model with torch.compile")
            hf_model.generation_config.cache_implementation = "static"
            hf_model.forward = torch.compile(hf_model.forward, mode="reduce-overhead", fullgraph=True)

# Unload the model if it has not been used for a period of time (unload_after_seconds)
async def unload_model_if_inactive():
    global hf_model, processor, last_use_time, unload_after_seconds
    while True:
        await asyncio.sleep(10)
        if hf_model is not None and time.time() - last_use_time > unload_after_seconds:
            async with model_lock:
                if time.time() - last_use_time > unload_after_seconds:
                    hf_model = None
                    processor = None
                    torch.cuda.empty_cache()
                    logger.info("Model unloaded due to inactivity")

# Process the requests to the API endpoint in the queue
async def process_queue():
    global request_queue
    while True:
        request, future = await request_queue.get()
        try:
            result = await process_single_request(request)
            future.set_result(result)
        except Exception as e:
            logger.error(f"Error processing request: {str(e)}")
            future.set_exception(e)
        finally:
            request_queue.task_done()

# Process a single request passed from the process_queue function
async def process_single_request(request: ImageRequest):
    global hf_model, processor, last_use_time, florence2_prompts, device, torch_dtype
    prompt = request.prompt.upper()
    if prompt not in florence2_prompts:
        raise HTTPException(status_code=400, detail="Invalid prompt")
    try:
        image_received_time = time.time()
        image_data = base64.b64decode(request.image)
        image = Image.open(io.BytesIO(image_data)).convert("RGB")
        #image = F.resize(image, (256, 256))
        processing_time = time.time() - image_received_time
        logger.info(f"Image decoded successfully. Size: {image.size} Processing Time: {processing_time:.2f} seconds")
    except Exception as e:
        logger.error(f"Error decoding image: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Invalid image data: {str(e)}")
    async with model_lock:
        try:
            logger.info("Processing image with model")
            load_model()
            inputs = processor(text=prompt, images=image, return_tensors="pt").to(device, torch_dtype)
            generated_ids = hf_model.generate(
                input_ids=inputs["input_ids"],
                pixel_values=inputs["pixel_values"],
                max_new_tokens=1024,
                do_sample=False,
                num_beams=3,
            )
            generated_text = processor.batch_decode(generated_ids, skip_special_tokens=False)[0]
            parsed_answer = processor.post_process_generation(generated_text, task=request.prompt, image_size=(image.width, image.height))
            processing_time = time.time() - last_use_time
            logger.info(f"Image processed successfully in {processing_time:.2f} seconds")
        except Exception as e:
            logger.error(f"Error processing image with model: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

    return ImageResponse(result=parsed_answer[request.prompt])

@asynccontextmanager
async def lifespan(app: FastAPI):
    asyncio.create_task(unload_model_if_inactive())
    asyncio.create_task(process_queue())
    yield

app = FastAPI(lifespan=lifespan)

@app.get("/prompts", response_model=List[str])
async def prompts():
    return florence2_prompts

@app.get("/model", response_model=str)
async def model():
    return florence2_model

@app.post("/process_image", response_model=ImageResponse)
async def process_image(request: ImageRequest, background_tasks: BackgroundTasks):
    future = asyncio.Future()
    await request_queue.put((request, future))
    background_tasks.add_task(future.result)
    return await future

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="127.0.0.1", help="Host to listen on for HTTP requests")
    parser.add_argument("--port", type=int, default=54880, help="Port to listen on for HTTP requests")
    args = parser.parse_args()
    import uvicorn
    load_model()
    uvicorn.run(app, host=args.host, port=args.port)
