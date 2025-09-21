from queue import Queue
from threading import Thread, Lock
import socket
import time

class TCPServer:
    def __init__(self, host: str, port: int, receive_callback=None, packet_size: int=2048):
        """Initialize the TCP server.
        This server listens for incoming TCP connections and processes received messages.

        Args:
            host (str): The hostname or IP address to bind the server to.
            port (int): The port number to listen on.
            receive_callback (function(respond: bytes), optional): A callback function to handle received messages.
            packet_size (int, optional): The maximum size of a packet to receive.
        """
        self._host = host
        self._port = port
        if receive_callback is not None:
            self._receive_callback = receive_callback
        else:
            self._receive_callback = lambda x: print(x.decode('utf-8').strip('\0'))
        self._server_socket = None
        self._message_queue = Queue()
        self._clients = []
        self._clients_lock = Lock()
        self.PACKET_SIZE = packet_size

    def start_server(self):
        """Start the TCP server and listen for incoming connections."""
        self._server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._server_socket.bind((self._host, self._port))
        self._server_socket.listen(1)
        print(f"Server started, listening on {self._host}:{self._port}")
        self._serve_forever()

    def start_server_nowait(self):
        """Start the server in a separate thread without blocking."""
        server_thread = Thread(target=self.start_server)
        server_thread.daemon = True
        server_thread.start()
        return server_thread

    def _handle_client(self, conn, addr):
        print(f"Connection established with {addr}")
        while True:
            try:
                reply = ""
                reply = conn.recv(self.PACKET_SIZE)
                if not reply:
                    print("Client disconnected.")
                    break
                
                message = self._receive_callback(reply)
                if message is None:
                    print("No message to send")
                    continue

                print(f"Sending message to client: {message}")

                conn.send(message)
                
            except Exception as e:
                print(e)
                break
        conn.close()
        print("Connection closed.")

    def _serve_forever(self):
        if self._server_socket is None:
            raise RuntimeError("Server not started. Call start_server() first.")
        try:
            while True:
                client_socket, addr = self._server_socket.accept()
                with self._clients_lock:
                    self._clients.append(client_socket)
                    
                Thread(target=self._handle_client, args=(client_socket, addr), daemon=True).start()
        except KeyboardInterrupt:
            print("Server closing...")
        except Exception as e:
            print(e)
        finally:
            self._server_socket.close()
            self._server_socket = None
            for client in self._clients:
                client.close()
            print("Server stopped.")
                
    def stop_server(self):
        """Stop the TCP server and close all client connections."""
        if self._server_socket:
            try:
                self._server_socket.close()
            except Exception as e:
                print(f"Error closing server socket: {e}")