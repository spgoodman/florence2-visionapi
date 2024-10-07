# Florence2 Vision API Server

This project implements a Vision API server using **Florence2** (and variants) with fast inference and automatic model unloading when not in use.

## Purpose

The Vision API server provides a an efficient way to process images using the Florence-2 model. It offers various image analysis capabilities through different prompts, making it versatile for a range of computer vision tasks.

## Model

The server uses the Florence-2 model, by default the fine-tune of Florence-2-base, **Florence-2-base-PromptGen-v1.5**, which is fine-tuned for image captioning. Read more about this model here:  [MiaoshouA/Florence-2-base-PromptGen-v1.5](https://huggingface.co/MiaoshouAI/Florence-2-base-PromptGen-v1.5)

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

2. The `vision-server.sh` script will automatically set up a virtual environment and install the required packages when run for the first time.

## Starting the Server

To start the server, use the `vision-server.sh` script:

```
./vision-server.sh [--host HOST] [--port PORT]
```

By default, the server will run on `localhost:54880`. You can specify a different host and port using the optional arguments.

## Creating a Service

To run the Florence2 Vision API server as a system service, you can create a systemd service file. Here's an example:

1. Create a new service file:
   ```
   sudo nano /etc/systemd/system/florence2-vision-api.service
   ```

2. Add the following content (adjust paths as necessary):
   ```
   [Unit]
   Description=Florence2 Vision API Server
   After=network.target

   [Service]
   ExecStart=/path/to/florence2-visionapi/vision-server.sh
   WorkingDirectory=/path/to/florence2-visionapi
   User=<your-username>
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

3. Save the file and exit the editor.

4. Reload systemd, enable and start the service:
   ```
   sudo systemctl daemon-reload
   sudo systemctl enable florence2-vision-api
   sudo systemctl start florence2-vision-api
   ```

## Sample Command Line Applications

### vision-client.sh

This script allows you to send image processing requests to the server from the command line.

Usage:
```
./vision-client.sh <prompt> <image_file_path>
```

Example:
```
./vision-client.sh CAPTION cat.jpg
```

Available prompts:
- `<GENERATE_TAGS>`
- `<MORE_DETAILED_CAPTION>`
- `<CAPTION>`
- `<DETAILED_CAPTION>`
- `<MIXED_CAPTION>`

See the README on Huggingface at [MiaoshouAI/Florence-2-base-PromptGen-v1.5](https://huggingface.co/MiaoshouAI/Florence-2-base-PromptGen-v1.5) for full details of each prompt and expected output.

### vision-caption-folder-images.sh

This script processes all images in a specified folder using the Vision API server.

Usage:
```
./vision-caption-folder-images.sh <folder_path> <prompt>
```

Example:
```
./vision-caption-folder-images.sh ./images CAPTION
```

This script will process all images in the specified folder using the given prompt and save the results in a text file named `captions.txt` in the same folder.

## API Endpoints

1. `/prompts` (GET): Returns a list of available prompts.
2. `/process_image` (POST): Processes an image with a given prompt.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Author

Steve Goodman (spgoodman)
