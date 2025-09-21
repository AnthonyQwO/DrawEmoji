import tkinter as tk
from tkinter import filedialog
import os
import sys

sys.path.insert(1, os.getcwd())  # Ensure the src directory is in the path
from src.model import ImageToEmoji

def select_image_file():
    root = tk.Tk()
    root.withdraw()
    file_path = filedialog.askopenfilename(
        title="Select an image",
        filetypes=[("Image files", "*.png;*.jpg;*.jpeg;*.bmp;*.gif")]
    )
    return file_path

if __name__ == "__main__":
    file_path = select_image_file()
    if not file_path:
        print("No file selected.")
    else:
        model = ImageToEmoji()
        b64_str = model.image_to_base64(file_path)
        print("Base64 string (first 100 chars):")
        print(b64_str[:100])
        print(f"Length: {len(b64_str)}")
        # 將 base64 字串寫入 output.txt
        with open("output.txt", "w") as f:
            f.write(b64_str)
        print("Base64 string written to output.txt")
        print(model.send_image(b64_str))
