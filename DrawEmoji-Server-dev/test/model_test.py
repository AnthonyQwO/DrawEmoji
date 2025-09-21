from tkinter import Tk, filedialog
import os
import sys
sys.path.insert(1, os.getcwd())
from src.model import ImageToEmoji
import base64

    
def test_send_image():
    """Test the send_image method with user input."""
    image_to_emoji = ImageToEmoji()  # Initialize with default API key and model
    
    image = input("Enter image path, URL, or 'base64' encoded string: ")
    print(image_to_emoji.send_image(image))
        
while True:
    test_send_image()