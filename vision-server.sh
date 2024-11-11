#!/bin/env bash
# 
# vision-server.sh
#
# Usage: vision-server.sh [--host <host>] [--port <port>]
# Example: vision-server.sh --host localhost --port 54880
# Example (with default values): vision-server.sh
#
# Author: Steve Goodman (spgoodman)
# Date: 2024-11-11
# License: MIT
#
# This script is used to start the vision-server.py script with optional host and port arguments.
# If a virtual environment is not found, it will create one and install the required packages.
#

cd "$(dirname "$0")"
if [[ ! -d ".venv" ]]; then
	echo "No virtual environment found. Hit enter to create virtual environment and attempt install of requirements or CTRL+C to exit."
	read
	echo "Creating virtual environment..."
	python -m venv .venv && \
	echo "Activating virtual environment..." && \
	source .venv/bin/activate && \
	echo "Installing Pytorch into the virtual environment using pip..." && \
	pip install torch torchvision --index-url https://download.pytorch.org/whl/cu124 && \
	echo "Install additional packages from requirements.txt using pip..." && \
	pip install -r requirements.txt || exit 1
else
	source .venv/bin/activate
fi
python vision-server.py "$@"