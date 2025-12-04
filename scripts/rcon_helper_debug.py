#!/usr/bin/env python3
"""
Debug version of RCON helper to see what's happening
"""
import socket
import struct
import sys

def send_rcon_debug(host, port, password, command):
    """Send RCON command with debug output"""
    sock = None
    try:
        print(f"[DEBUG] Connecting to {host}:{port}...", file=sys.stderr)
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(15)
        sock.connect((host, int(port)))
        print("[DEBUG] Connected successfully", file=sys.stderr)
        
        # Step 1: Authenticate
        auth_id = -1
        auth_type = 3  # SERVERDATA_AUTH
        auth_body = password.encode() + b'\x00\x00'
        # Packet length = 4 (ID) + 4 (type) + body length
        auth_length = 4 + 4 + len(auth_body)
        auth_packet = struct.pack('<i', auth_length) + struct.pack('<i', auth_id) + struct.pack('<i', auth_type) + auth_body
        
        print(f"[DEBUG] Sending auth packet: length={auth_length}, id={auth_id}, type={auth_type}", file=sys.stderr)
        print(f"[DEBUG] Auth packet bytes: {auth_packet.hex()}", file=sys.stderr)
        sock.send(auth_packet)
        print("[DEBUG] Auth packet sent, waiting for response...", file=sys.stderr)
        
        # Receive auth response
        sock.settimeout(10)
        length_data = sock.recv(4)
        print(f"[DEBUG] Received length bytes: {length_data.hex() if length_data else 'None'}", file=sys.stderr)
        
        if len(length_data) < 4:
            return None, f"Only received {len(length_data)} bytes for length (expected 4)"
        
        packet_length = struct.unpack('<i', length_data)[0]
        print(f"[DEBUG] Packet length: {packet_length}", file=sys.stderr)
        
        if packet_length < 0 or packet_length > 4096:
            return None, f"Invalid packet length: {packet_length}"
        
        # Read remaining packet
        remaining = packet_length
        auth_response = b''
        while remaining > 0:
            chunk = sock.recv(min(remaining, 4096))
            if not chunk:
                return None, "Connection closed while reading auth response"
            auth_response += chunk
            remaining -= len(chunk)
        
        print(f"[DEBUG] Auth response bytes: {auth_response.hex()}", file=sys.stderr)
        print(f"[DEBUG] Auth response length: {len(auth_response)}", file=sys.stderr)
        
        if len(auth_response) >= 8:
            response_id = struct.unpack('<i', auth_response[0:4])[0]
            response_type = struct.unpack('<i', auth_response[4:8])[0]
            print(f"[DEBUG] Response ID: {response_id}, Type: {response_type}", file=sys.stderr)
            
            # Check for auth success
            # Success: response_id == -1 (matches our auth ID)
            # OR response_id is positive (some servers echo the request)
            if response_id == -1:
                print("[DEBUG] Authentication successful (ID matches)", file=sys.stderr)
            elif response_id > 0:
                print(f"[DEBUG] Authentication may have succeeded (positive ID: {response_id})", file=sys.stderr)
            else:
                return None, f"Authentication failed - unexpected response ID: {response_id}, type: {response_type}"
        else:
            return None, f"Auth response too short: {len(auth_response)} bytes"
        
        # Some servers send an empty response packet - try to read it
        try:
            sock.settimeout(0.5)
            empty_check = sock.recv(4)
            if len(empty_check) == 4:
                empty_length = struct.unpack('<i', empty_check)[0]
                print(f"[DEBUG] Found additional packet, length: {empty_length}", file=sys.stderr)
                if empty_length > 0 and empty_length < 4096:
                    remaining = empty_length
                    while remaining > 0:
                        chunk = sock.recv(min(remaining, 4096))
                        if not chunk:
                            break
                        remaining -= len(chunk)
        except socket.timeout:
            print("[DEBUG] No additional packet (timeout)", file=sys.stderr)
        except Exception as e:
            print(f"[DEBUG] Error reading additional packet: {e}", file=sys.stderr)
        
        sock.settimeout(10)
        
        # Step 2: Send command
        print(f"[DEBUG] Sending command: {command}", file=sys.stderr)
        request_id = 1
        command_type = 2  # SERVERDATA_EXECCOMMAND
        command_body = command.encode() + b'\x00\x00'
        command_length = 4 + 4 + len(command_body)
        command_packet = struct.pack('<i', command_length) + struct.pack('<i', request_id) + struct.pack('<i', command_type) + command_body
        sock.send(command_packet)
        
        # Receive command response
        length_data = sock.recv(4)
        if len(length_data) < 4:
            return None, "Invalid response length"
        
        packet_length = struct.unpack('<i', length_data)[0]
        print(f"[DEBUG] Command response length: {packet_length}", file=sys.stderr)
        
        remaining = packet_length
        response_data = b''
        while remaining > 0:
            chunk = sock.recv(min(remaining, 4096))
            if not chunk:
                break
            response_data += chunk
            remaining -= len(chunk)
        
        if len(response_data) < 8:
            return None, "Response too short"
        
        response_body = response_data[8:].rstrip(b'\x00')
        response = response_body.decode('utf-8', errors='ignore')
        print(f"[DEBUG] Command response: {response[:100]}", file=sys.stderr)
        return response, None
        
    except socket.timeout as e:
        return None, f"Timeout: {str(e)}"
    except Exception as e:
        return None, f"Error: {str(e)}"
    finally:
        if sock:
            sock.close()

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: rcon_helper_debug.py <host> <port> <password> <command>", file=sys.stderr)
        sys.exit(1)
    
    host = sys.argv[1]
    port = int(sys.argv[2])
    password = sys.argv[3]
    command = ' '.join(sys.argv[4:])
    
    response, error = send_rcon_debug(host, port, password, command)
    if error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
    else:
        print(response)
        sys.exit(0)

