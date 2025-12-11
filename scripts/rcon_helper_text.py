#!/usr/bin/env python3
"""
Alternative RCON helper that tries text-based protocol first
"""
import socket
import sys
import time

def send_rcon_text(host, port, password, command):
    """Try text-based RCON (like telnet)"""
    sock = None
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(10)
        sock.connect((host, int(port)))
        
        # Read initial greeting (if any)
        sock.settimeout(1)
        try:
            greeting = sock.recv(1024)
            # Server may send greeting about password protection
        except socket.timeout:
            pass
        
        # Send password using PASS command
        sock.sendall(f"PASS {password}\n".encode())
        time.sleep(0.2)
        
        # Read password response
        sock.settimeout(1)
        try:
            pass_response = sock.recv(1024)
            # Check if authentication was successful
            if b"error" in pass_response.lower() or b"invalid" in pass_response.lower():
                return None, "Authentication failed - incorrect password"
        except socket.timeout:
            pass  # Some servers don't send response
        
        # Send command
        sock.sendall(f"{command}\n".encode())
        time.sleep(0.2)
        
        # Read response
        sock.settimeout(2)
        response = b''
        while True:
            try:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                response += chunk
            except socket.timeout:
                break
        
        if response:
            return response.decode('utf-8', errors='ignore').strip(), None
        else:
            return None, "No response received"
            
    except Exception as e:
        return None, str(e)
    finally:
        if sock:
            sock.close()

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: rcon_helper_text.py <host> <port> <password> <command>", file=sys.stderr)
        sys.exit(1)
    
    host = sys.argv[1]
    port = int(sys.argv[2])
    password = sys.argv[3]
    command = ' '.join(sys.argv[4:])
    
    response, error = send_rcon_text(host, port, password, command)
    if error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
    else:
        print(response)
        sys.exit(0)

