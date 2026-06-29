#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing pulse..."
sudo apt install python3-rich python3-psutil -y
pip install readchar --break-system-packages
sudo ln -sf "$SCRIPT_DIR/pulse.py" /usr/local/bin/pulse
sudo chmod +x "$SCRIPT_DIR/pulse.py"
echo "Done! Run 'pulse' from anywhere."
