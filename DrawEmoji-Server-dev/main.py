from src.connection import TCPServer
from src.model import ImageToEmoji
from src.backend import BackPlug
from multiprocessing import Process
import tkinter as tk
import logging
import datetime
import os

server = None
model = None
backend_process = None
server_running = False

def receive_callback(result: bytes):
    result = result.decode('utf-8')
    print('Receive message: ' + result)
    try:
        idx = result.rfind(':')
        if idx != -1:
            user_prompt = result[:idx]
            image_base64 = result[idx + 1:]
        else:
            user_prompt = ''
            image_base64 = result
        response = model.send_image(image=image_base64, prompt=user_prompt)
    except Exception as e:
        print(f"Error processing image: {e}")
        response = "Error processing image: " + str(e)
    return response.encode('utf-8')

def _start_backend_api():
    BackPlug().start()

def toggle_server():
    global server, model, backend_process, server_running
    if not server_running:
        # Start server
        server = TCPServer(host='127.0.0.1', port=8888, receive_callback=receive_callback, packet_size=2000000)
        server.start_server_nowait()
        model = ImageToEmoji(prompt_path='src/model/model_prompt.txt', model='gpt-4.1-2025-04-14')
        backend_process = Process(target=_start_backend_api, daemon=True)
        backend_process.start()
        status_var.set("Server is running")
        status_label.config(fg="green")
        toggle_btn.config(text="Stop server")
        server_running = True
        show_server_layout()
    else:
        # Stop server
        if server is not None:
            server.stop_server()
            server = None
        if backend_process is not None:
            backend_process.terminate()
            backend_process = None
        status_var.set("Server stopped")
        status_label.config(fg="red")
        toggle_btn.config(text="Activate the server")
        server_running = False
        show_default_layout()

def on_closing():
    global server_running
    if server_running:
        toggle_server()
    root.destroy()

def show_server_layout():
    toggle_btn.pack_forget()
    exit_btn.pack_forget()
    status_label.pack_forget()

    left_frame.pack(side="left", fill="y", padx=20, pady=20)
    stop_btn.pack(pady=10)
    exit_btn2.pack(pady=10)

    right_frame.pack(side="left", fill="both", expand=True, padx=10, pady=20)
    canvas.pack(fill="both", expand=True)

def show_default_layout():
    left_frame.pack_forget()
    right_frame.pack_forget()
    stop_btn.pack_forget()
    exit_btn2.pack_forget()
    canvas.pack_forget()

    status_label.pack(pady=15)
    toggle_btn.pack(pady=10)
    exit_btn.pack(pady=15)

if __name__ == '__main__':
    root = tk.Tk()
    root.title("DrawEmoji control room")
    root.geometry("320x200")

    status_var = tk.StringVar(value="Server stopped")
    status_label = tk.Label(root, textvariable=status_var, fg="red", font=("Arial", 14))

    toggle_btn = tk.Button(root, text="Activate the server", command=toggle_server, width=20)
    exit_btn = tk.Button(root, text="Leave", command=on_closing, width=20)

    left_frame = tk.Frame(root)
    right_frame = tk.Frame(root, bd=2, relief="solid")
    stop_btn = tk.Button(left_frame, text="Stop server", command=toggle_server, width=15)
    exit_btn2 = tk.Button(left_frame, text="exit", command=on_closing, width=15)
    canvas = tk.Canvas(right_frame, bg="white")

    ip_port_var = tk.StringVar(value="")
    ip_port_label = tk.Label(left_frame, textvariable=ip_port_var, fg="gray", font=("Arial", 10))

    status_label.pack(pady=15)
    toggle_btn.pack(pady=10)
    exit_btn.pack(pady=15)

    def show_server_layout():
        root.geometry("700x500") 
        toggle_btn.pack_forget()
        exit_btn.pack_forget()
        status_label.pack_forget()

        left_frame.pack(side="left", fill="y", padx=20, pady=20)
        stop_btn.pack(pady=10)
        exit_btn2.pack(pady=10)

        ip_port_var.set("IP: 127.0.0.1\nPort: 8888")
        ip_port_label.pack(pady=10)

        right_frame.pack(side="left", fill="both", expand=True, padx=10, pady=20)
        canvas.pack(fill="both", expand=True)

    def show_default_layout():
        root.geometry("320x200")
        left_frame.pack_forget()
        right_frame.pack_forget()
        stop_btn.pack_forget()
        exit_btn2.pack_forget()
        canvas.pack_forget()
        ip_port_label.pack_forget()

        status_label.pack(pady=15)
        toggle_btn.pack(pady=10)
        exit_btn.pack(pady=15)

    globals()['show_server_layout'] = show_server_layout
    globals()['show_default_layout'] = show_default_layout

    root.protocol("WM_DELETE_WINDOW", on_closing)
    root.mainloop()