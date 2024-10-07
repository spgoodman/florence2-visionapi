# Florence2 Vision API Server

This project implements a Vision API server using **Florence2** (and variants) with fast inference and automatic model unloading when not in use.

## Purpose

The Vision API server provides an efficient way to process images using the Florence-2 model. It offers various image analysis capabilities through different prompts, making it versatile for a range of computer vision tasks.

## Model

The server uses the Florence-2 model, by default the fine-tune of Florence-2-base, **Florence-2-base-PromptGen-v1.5**, which is fine-tuned for image captioning. Read more about this model here: [MiaoshouA/Florence-2-base-PromptGen-v1.5](https://huggingface.co/MiaoshouAI/Florence-2-base-PromptGen-v1.5)

Note: The version specified in the model is [createveai/Florence-2-base-PromptGen-v1.5](https://huggingface.co/createveai/Florence-2-base-PromptGen-v1.5) which is the same model weights with corrected config.json and other code fixes.

## Server Features

1. **FastAPI Implementation**: The server is built using FastAPI, providing a fast and modern framework for API development.
2. **Asynchronous Processing**: Requests are processed asynchronously, allowing for efficient handling of multiple requests.
3. **Auto Model Unloading**: The model is automatically unloaded after a period of inactivity (default: 300 seconds), freeing up system resources when not in use.
4. **Request Queueing**: Incoming requests are queued and processed in order.

## Installation

1. Clone the repository:

   ```
   git clone <repository-url>
   cd florence2-visionapi
   ```

2. Install the required packages:
   - For Linux: The `vision-server.sh` script will automatically set up a virtual environment and install the required packages when run for the first time.
   - For Windows: The `vision-server.bat` script will set up a virtual environment and install the required packages when run for the first time.

## Starting the Server

### Linux

To start the server on Linux, use the `vision-server.sh` script:

```
./vision-server.sh [--host HOST] [--port PORT]
```

### Windows

To start the server on Windows, use the `vision-server.bat` script:

```
vision-server.bat [--host HOST] [--port PORT]
```

By default, the server will run on `localhost:54880`. You can specify a different host and port using the optional arguments.

## Sample Command Line Clients

Both should have identical operations. Update the base_url variable in vision-client.sh/ps1 if you change the host & port the server listens on.

### Linux

#### vision-client.sh

This script allows you to send image processing requests to the server from the command line.

Usage:

```
./vision-client.sh <prompt> <image_file_path>
```

Example:

```
./vision-client.sh CAPTION cat.jpg
```

#### vision-caption-folder-images.sh

This script processes all images in a specified folder using the Vision API server.

Usage:

```
./vision-caption-folder-images.sh <folder_path> <prompt>
```

Example:

```
./vision-caption-folder-images.sh ./images CAPTION
```

### Windows

#### vision-client.ps1

This PowerShell script allows you to send image processing requests to the server from the command line on Windows.

Usage:

```
.\vision-client.ps1 <prompt> <image_file_path>
```

Example:

```
.\vision-client.ps1 CAPTION cat.jpg
```

#### vision-caption-folder-images.ps1

This PowerShell script processes all images in a specified folder using the Vision API server on Windows.

Usage:

```
.\vision-caption-folder-images.ps1 <folder_path> <prompt>
```

Example:

```
.\vision-caption-folder-images.ps1 .\images CAPTION
```

These scripts will process all images in the specified folder using the given prompt and save the results in a text file named `captions.txt` in the same folder.

## Available Prompts for MiaoshouAI/Florence-2-base-PromptGen-v1.5

- `GENERATE_TAGS`
- `MORE_DETAILED_CAPTION`
- `CAPTION`
- `DETAILED_CAPTION`
- `MIXED_CAPTION`

See the README on Huggingface at [MiaoshouAI/Florence-2-base-PromptGen-v1.5](https://huggingface.co/MiaoshouAI/Florence-2-base-PromptGen-v1.5) for full details of each prompt and expected output.

## API Endpoints

The API server is primarily intended to be used by other services, rather than command line apps.

1. `/prompts` (GET): Returns a list of available prompts.
2. `/process_image` (POST): Processes an image with a given prompt.

Example payload:

`base64_image=$(base64 -w 0 "cat.jpg")`

```json
{
  "image": "$base64_image",
  "prompt": "<CAPTION>"
}
```

Example curl command to post the above
`curl -s -X POST "http://localhost:54880/process_image" -H "Content-Type: application/json" -d @"payload.json"
`

Sample response:

```json
{"result":"a close-up of a cat with a curious expression"}
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Author

Steve Goodman (spgoodman)
