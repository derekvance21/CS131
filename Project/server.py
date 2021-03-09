import asyncio
import json
import aiohttp
import sys
import re
import os
import re
import time
from decimal import Decimal, InvalidOperation
from env import GOOGLE_PLACES_API_KEY
GOOGLE_PLACES_API_URL="https://maps.googleapis.com/maps/api/place/nearbysearch/json"

SERVERS = ["Riley", "Jaquez", "Bernard", "Juzang", "Campbell"]
PORTS = [x for x in range(15700, 15705)] # [15700, 15704]
SERVER_TO_PORT = dict(zip(SERVERS, PORTS))
PORT_TO_SERVER = dict(zip(PORTS, SERVERS))
SERVER_TO_NEIGHBORS = {
    "Riley": ["Jaquez", "Juzang"],
    "Jaquez": ["Riley", "Bernard"],
    "Bernard": ["Jaquez", "Juzang", "Campbell"],
    "Juzang": ["Riley", "Bernard", "Campbell"],
    "Campbell": ["Bernard", "Juzang"]
}

FORMATS = {
    "IAMAT": ["name", "client", "loc", "time"],
    "AT": ["name", "server", "diff", "client", "loc", "time"],
    "WHATSAT": ["name", "client", "radius", "limit"]
}



clients = {}


def parse_msg(msg):
    try:
        fields = re.split("\s+", msg.strip()) 
        name = fields[0]
        # if number of fields for name doesn't match number of fields in command, raise exception
        if len(fields) != len(FORMATS.get(name)):
            raise Exception(msg)

        cmd = dict(zip(FORMATS.get(name), fields) )#, msg=re.sub(r"\s+", " ", msg.strip()))
        
        ## type checks/conversions
        if name in ["IAMAT", "AT"]:
            cmd["time"] = Decimal(cmd.get("time"))
            cmd["loc"] = tuple(map(lambda x: float(x), filter(lambda x: x, re.findall(r"([-\+]\d+\.?\d*)", cmd.get("loc")))))
            # if location not in valid <latitude><longitude>, raise exception
            if len(cmd["loc"]) != 2:
                raise Exception(msg)
        if name in ["AT"]:
            cmd["diff"] = Decimal(cmd.get("diff"))
        if name in ["WHATSAT"]:
            cmd["radius"] = int(cmd.get("radius"))
            cmd["limit"] = int(cmd.get("limit"))

        return cmd
    
    except (IndexError, ValueError, TypeError, InvalidOperation):
        raise Exception(msg)


    
async def api_req():
    async with aiohttp.ClientSession() as session:
        params = [('radius', '10'), ('key', GOOGLE_PLACES_API_KEY), ('location', '-33.867,151.1957362')]
        async with session.get(GOOGLE_PLACES_API_URL, params=params) as response:
            print(await response.text())


def log_input(msg, src):
    log_info(f"Input: {msg!r} from {PORT_TO_SERVER.get(src[1]) or src}")

def log_output(msg, dest):
    port = 
    
    log_info(f"Output: {msg!r} to {PORT_TO_SERVER.get(dest[1]) or dest}")

def log_info(msg):
    with open(f"{server_name}.log", "a") as log:
        log.write(f"{msg}\n")
    print(msg)


def check_to_propagate(cmd):
    client = clients.get(cmd["client"])
    # old message: stored client data is at least as new as this command
    if not client or client["time"] < cmd["time"]:
        clients.update({cmd["client"]: {"loc": cmd["loc"], "time": cmd["time"]}})
        print(clients)
        return True
    else:
        return False



async def forward_AT(msg, server):
    try:
        reader, writer = await asyncio.open_connection('localhost', SERVER_TO_PORT.get(server))
        writer.write(msg.encode())
        await writer.drain()
        writer.close()
        log_output(msg, writer.get_extra_info('peername'))
    except ConnectionRefusedError:
        log_info(f"Failed: {msg!r} to {server}")


async def propagate(msg, src=None):
    # propagate to neighbors that aren't the source of the message
    forwards = (forward_AT(msg, neighbor) for neighbor in SERVER_TO_NEIGHBORS.get(server_name) if neighbor != src)
    await asyncio.gather(*forwards)


async def handle_IAMAT(writer, cmd):
    diff = Decimal(time.time_ns()) / 1000000000 - cmd['time']
    loc = ''.join(map(lambda x: f"{'+' if x >= 0 else ''}{x}", cmd['loc']))
    msg = f"AT {server_name} {'+' if diff >= 0 else ''}{diff} {cmd['client']} {loc} {cmd['time']}\n"
    writer.write(msg.encode())
    await writer.drain()
    writer.close()
    log_output(msg, writer.get_extra_info('peername'))

    if check_to_propagate(cmd):
        await propagate(msg)


async def handle_AT(writer, cmd):
    if check_to_propagate(cmd):
        loc = ''.join(map(lambda x: f"{'+' if x >= 0 else ''}{x}", cmd['loc']))
        msg = f"AT {server_name} {'+' if cmd['diff'] >= 0 else ''}{cmd['diff']} {cmd['client']} {loc} {cmd['time']}\n"
        await propagate(msg, src=cmd["server"])


async def handle_WHATSAT(writer, cmd):
    pass


HANDLES = {
    "IAMAT": handle_IAMAT,
    "AT": handle_AT,
    "WHATSAT": handle_WHATSAT
}

async def handle_msg(reader, writer):
    data = await reader.read()
    msg = data.decode()
    addr = writer.get_extra_info('peername')

    log_input(msg, addr)

    try:
        cmd = parse_msg(msg)
        handle_cmd = HANDLES.get(cmd["name"])
        await handle_cmd(writer, cmd)
        
    except Exception:
        writer.write(f"? {msg}\n".encode())
        await writer.drain()
        writer.close()
        # print(f"Closed the connection to {addr}")
        log_output(f"? {msg}\n", addr)


async def main(server_name):
    server = await asyncio.start_server(handle_msg, 'localhost', SERVER_TO_PORT.get(server_name))
    addr = server.sockets[0].getsockname()

    log_info(f"Server going up on {addr}")

    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    try:
        server_name = sys.argv[1]
    except IndexError:
        raise SystemExit("Usage: server.py <server_name>")

    if server_name not in SERVER_TO_PORT or len(sys.argv) != 2:
        raise SystemExit("Usage: server.py <server_name>")

    try:
        asyncio.run(main(server_name))
        # print(parse_msg("   AT Riley +0.263873386 kiwi.cs.ucla.edu +34.068930-118.445127 1614209128.918963997   \n  "))

    except KeyboardInterrupt:
        log_info(f"Server going down\n---")
        sys.exit(0)
