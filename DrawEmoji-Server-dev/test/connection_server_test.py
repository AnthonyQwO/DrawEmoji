import os
import sys
sys.path.insert(1, os.getcwd())

from src.connection import TCPServer
import time

server = None

s = "start"
def receive_callback(data):
    global s
    s = data.decode('utf-8').strip('\0')
    print(f"Received from client: {s}")
    server.send_message(s.encode('utf-8'))   

server = TCPServer(host='localhost', port=12345, receive_callback=receive_callback)

server.start_server_nowait()


while True:
    time.sleep(1)