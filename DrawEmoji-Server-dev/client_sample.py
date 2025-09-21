import socket
import tkinter as tk
from tkinter import filedialog, simpledialog, messagebox
import base64
from multiprocessing import Process

class TCPClient:
    def __init__(self, host: str, port: int):
        self._host = host
        self._port = port
        self._client_socket = None

    def connect(self):
        """Connect to the server."""
        self._client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._client_socket.connect((self._host, self._port))
        print(f"Connected to server at {self._host}:{self._port}")

    def send_message(self, message: str):
        """Send a message to the server and receive a response."""
        if self._client_socket is None:
            raise RuntimeError("Client not connected. Call connect() first.")
        self._client_socket.sendall(message.encode())
        response = self._client_socket.recv(2000000)
        print(f"Received from server: {response.decode()}")

    def close(self):
        """Close the connection."""
        if self._client_socket:
            self._client_socket.close()
            print("Connection closed.")

def browse_image():
    root = tk.Tk()
    root.withdraw()
    file_path = filedialog.askopenfilename(
        title="Select an image",
        filetypes=[("Image files", "*.png;*.jpg;*.jpeg;*.bmp;*.gif")]
    )
    root.update()
    root.destroy()
    return file_path

def main_ui(client: TCPClient):
    root = tk.Tk()
    root.title("TCP Client")
    root.geometry("400x320")

    # 狀態標籤
    status_var = tk.StringVar(value="Disconnected")
    status_label = tk.Label(root, textvariable=status_var, fg="red")
    status_label.pack(pady=2)

    # 按鈕參考
    btns = {}

    def set_buttons_state(state):
        for k, btn in btns.items():
            if k not in ("connect",):
                btn.config(state=state)

    def connect_action():
        try:
            client.connect()
            status_var.set("Connected")
            status_label.config(fg="green")
            set_buttons_state("normal")
            btns["connect"].config(state="disabled")
            btns["disconnect"].config(state="normal")
        except Exception as e:
            messagebox.showerror("Error", f"Connect failed: {e}")

    def disconnect_action():
        try:
            client.close()
        except Exception:
            pass
        status_var.set("Disconnected")
        status_label.config(fg="red")
        set_buttons_state("disabled")
        btns["connect"].config(state="normal")
        btns["disconnect"].config(state="disabled")

    def send_image():
        file_path = browse_image()
        if file_path:
            with open(file_path, "rb") as img_file:
                b64_str = base64.b64encode(img_file.read()).decode('utf-8')
                client.send_message(b64_str)
                messagebox.showinfo("Sent", "Image (base64) sent.")
        else:
            messagebox.showwarning("No file", "No file selected.")

    def send_path():
        file_path = browse_image()
        if file_path:
            client.send_message(file_path)
            messagebox.showinfo("Sent", "Image path sent.")
        else:
            messagebox.showwarning("No file", "No file selected.")

    def send_url():
        url = simpledialog.askstring("Input", "Enter image URL:")
        if url:
            client.send_message(url)
            messagebox.showinfo("Sent", "URL sent.")
        else:
            messagebox.showwarning("No URL", "No URL entered.")

    def send_base64():
        try:
            with open("output.txt", "r") as f:
                base64_data = f.read()
            client.send_message(base64_data)
            messagebox.showinfo("Sent", "Base64 from output.txt sent.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to read output.txt: {e}")

    def send_custom():
        msg = simpledialog.askstring("Input", "Enter custom message:")
        if msg:
            client.send_message(msg)
            messagebox.showinfo("Sent", "Custom message sent.")

    def close_client():
        disconnect_action()
        root.destroy()

    # 連線/斷線按鈕
    btns["connect"] = tk.Button(root, text="Connect", command=connect_action, width=30)
    btns["connect"].pack(pady=5)
    btns["disconnect"] = tk.Button(root, text="Disconnect", command=disconnect_action, width=30, state="disabled")
    btns["disconnect"].pack(pady=5)

    # 其他操作按鈕
    btns["image"] = tk.Button(root, text="Send Image (base64)", command=send_image, width=30, state="disabled")
    btns["image"].pack(pady=5)
    btns["path"] = tk.Button(root, text="Send Image Path", command=send_path, width=30, state="disabled")
    btns["path"].pack(pady=5)
    btns["url"] = tk.Button(root, text="Send Image URL", command=send_url, width=30, state="disabled")
    btns["url"].pack(pady=5)
    btns["base64"] = tk.Button(root, text="Send Base64 from output.txt", command=send_base64, width=30, state="disabled")
    btns["base64"].pack(pady=5)
    btns["custom"] = tk.Button(root, text="Send Custom Message", command=send_custom, width=30, state="disabled")
    btns["custom"].pack(pady=5)
    btns["exit"] = tk.Button(root, text="Exit", command=close_client, width=30)
    btns["exit"].pack(pady=10)

    root.mainloop()
    
def run_client():
    client = TCPClient(host="localhost", port=8888)
    try:
        main_ui(client)
    finally:
        client.close()

if __name__ == "__main__":
    N = 5
    processes = []
    for _ in range(N):
        p = Process(target=run_client)
        processes.append(p)
        p.start()

    for p in processes:
        p.join() 