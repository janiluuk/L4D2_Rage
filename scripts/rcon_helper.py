#!/usr/bin/env python3
"""
Simple RCON client for Source games (TCP-based)
Source RCON Protocol: https://developer.valvesoftware.com/wiki/Source_RCON_Protocol
"""
import socket
import struct
import sys
import time

def test_connection(host, port, timeout=5):
    """Test if we can connect to the server"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, int(port)))
        sock.close()
        return result == 0
    except Exception as e:
        return False

def send_rcon(host, port, password, command):
    """Send RCON command to game server
    Supports both binary Source RCON protocol and text-based protocol
    """
    sock = None
    try:
        # Test connection first
        if not test_connection(host, port, timeout=5):
            return None, f"Cannot connect to {host}:{port} - server may be down or port blocked"
        
        # Create TCP socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(15)
        try:
            sock.connect((host, int(port)))
        except socket.timeout:
            return None, f"Connection timeout to {host}:{port} - server may be down or unreachable"
        except socket.gaierror as e:
            return None, f"DNS resolution failed for {host}: {str(e)}"
        except ConnectionRefusedError:
            return None, f"Connection refused by {host}:{port} - server may not be running or RCON disabled"
        
        # Try text-based protocol first (most common for SourceMod/custom servers)
        # Send PASS command immediately
        sock.sendall(f"PASS {password}\n".encode())
        time.sleep(0.2)
        
        # Read any response (greeting or password confirmation)
        sock.settimeout(2)
        greeting = b''
        try:
            greeting = sock.recv(4096)
            # Check for authentication errors
            if b"error" in greeting.lower() or b"invalid" in greeting.lower() or b"failed" in greeting.lower() or b"incorrect" in greeting.lower():
                return None, "Authentication failed - incorrect password"
        except socket.timeout:
            pass  # No response, continue
        
        # Send command
        sock.sendall(f"{command}\n".encode())
        time.sleep(0.3)
        
        # Read response
        sock.settimeout(5)
        response = b''
        chunks_read = 0
        max_chunks = 50  # Prevent infinite loop
        
        while chunks_read < max_chunks:
            try:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                response += chunk
                chunks_read += 1
                
                # If we got less than a full buffer, wait a bit for more
                if len(chunk) < 4096:
                    time.sleep(0.1)
                    try:
                        sock.settimeout(0.3)
                        more = sock.recv(4096)
                        if more:
                            response += more
                            chunks_read += 1
                        else:
                            break
                    except socket.timeout:
                        break
                    except:
                        break
            except socket.timeout:
                break
        
        if response:
            result = response.decode('utf-8', errors='ignore').strip()
            # Filter out password prompts, PASS commands, and error messages
            lines = []
            for line in result.split('\n'):
                line = line.strip()
                if line and 'PASS' not in line and 'password protected' not in line.lower() and 'must send pass' not in line.lower():
                    lines.append(line)
            
            if lines:
                return '\n'.join(lines), None
            elif result:
                return result, None
            else:
                return None, "Empty response from server"
        else:
            return None, "No response received from server"
        
        # Fall back to binary Source RCON protocol
        sock.settimeout(10)
        
        # Step 1: Authenticate with binary protocol
        auth_id = -1
        auth_type = 3  # SERVERDATA_AUTH
        auth_body = password.encode() + b'\x00\x00'
        auth_length = 4 + 4 + len(auth_body)
        auth_packet = struct.pack('<i', auth_length) + struct.pack('<i', auth_id) + struct.pack('<i', auth_type) + auth_body
        sock.send(auth_packet)
        
        # Try to receive auth response
        auth_success = False
        sock.settimeout(2)
        try:
            length_data = sock.recv(4)
            if len(length_data) == 4:
                packet_length = struct.unpack('<i', length_data)[0]
                if 0 <= packet_length <= 4096:
                    remaining = packet_length
                    auth_response = b''
                    while remaining > 0:
                        chunk = sock.recv(min(remaining, 4096))
                        if not chunk:
                            break
                        auth_response += chunk
                        remaining -= len(chunk)
                    
                    if len(auth_response) >= 8:
                        response_id = struct.unpack('<i', auth_response[0:4])[0]
                        if response_id == -1:
                            auth_success = True
        except socket.timeout:
            auth_success = True  # Assume success if no response
        
        sock.settimeout(10)
        
        # Step 2: Send command
        request_id = 1
        command_type = 2  # SERVERDATA_EXECCOMMAND
        command_body = command.encode() + b'\x00\x00'
        command_length = 4 + 4 + len(command_body)
        command_packet = struct.pack('<i', command_length) + struct.pack('<i', request_id) + struct.pack('<i', command_type) + command_body
        sock.send(command_packet)
        
        # Receive response
        try:
            length_data = sock.recv(4)
            if len(length_data) < 4:
                return None, "Invalid response length"
            
            packet_length = struct.unpack('<i', length_data)[0]
            if packet_length <= 0 or packet_length > 4096:
                return None, f"Invalid packet length: {packet_length}"
            
            remaining = packet_length
            response_data = b''
            while remaining > 0:
                chunk = sock.recv(min(remaining, 4096))
                if not chunk:
                    break
                response_data += chunk
                remaining -= len(chunk)
            
            if len(response_data) >= 8:
                response_body = response_data[8:].rstrip(b'\x00')
                response = response_body.decode('utf-8', errors='ignore').strip()
                if response:
                    return response, None
            
            return None, "Empty response from server"
        except socket.timeout:
            return None, "Timeout waiting for command response"
        finally:
            if sock:
                sock.close()
            
    except socket.timeout:
        return None, f"Connection timeout to {host}:{port} - check network connectivity"
    except socket.error as e:
        errno = e.errno if hasattr(e, 'errno') else None
        if errno == 111:  # Connection refused
            return None, f"Connection refused by {host}:{port} - server may not be running or RCON disabled"
        elif errno == 110 or errno == 113:  # Connection timed out
            return None, f"Connection timeout to {host}:{port} - server may be down or unreachable"
        elif errno == 101:  # Network unreachable
            return None, f"Network unreachable: {host}:{port} - check network connectivity"
        else:
            return None, f"Connection error: {str(e)} (errno: {errno})"
    except Exception as e:
        return None, f"Unexpected error: {str(e)}"
    finally:
        if sock:
            try:
                sock.close()
            except:
                pass

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: rcon_helper.py <host> <port> <password> <command>")
        sys.exit(1)
    
    host = sys.argv[1]
    port = int(sys.argv[2])
    password = sys.argv[3]
    command = ' '.join(sys.argv[4:])
    
    response, error = send_rcon(host, port, password, command)
    if error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
    else:
        print(response)
        sys.exit(0)

