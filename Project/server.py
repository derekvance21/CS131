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


def log_input(msg, source, log):
    log_info(f"Input: {msg!r} from {source}", log)

def log_output(msg, dest, log):
    log_info(f"Output: {msg!r} to {dest}", log)

def log_info(msg, log):
    print(msg)
    log.write(f"{msg}\n")


async def handle_IAMAT(reader, writer, cmd, log):
    server = PORT_TO_SERVER.get(writer.get_extra_info('sockname')[1])
    diff = (Decimal(time.time_ns()) / 1000000000) - cmd['time']
    loc = ''.join(map(lambda x: f"{'+' if x > 0 else ''}{x}", cmd['loc']))
    resp = f"AT {server} {diff} {cmd['client']} {loc} {cmd['time']}\n"
    writer.write(resp.encode())
    await writer.drain()
    log_output(resp, writer.get_extra_info('peername'), log)

    writer.close()
    print(f"Closed the connection to {writer.get_extra_info('peername')}")

    client = clients.get(cmd["client"])
    # old message: stored client data is newer than this command
    if client and cmd["time"] <= client["time"]:
        pass
    else:
        clients.update({cmd["client"]: {"loc": cmd["loc"], "time": cmd["time"]}})
        print(clients)
        # send to neighbors
        # reader, writer = await asyncio.open_connection('localhost', 15700)

    

async def handle_AT(reader, writer, cmd, log):
    pass


async def handle_WHATSAT(reader, writer, cmd, log):
    pass

HANDLES = {
    "IAMAT": handle_IAMAT,
    "AT": handle_AT,
    "WHATSAT": handle_WHATSAT
}


async def handle_msg(reader, writer):
    with open(f"{server_name}.log", "a") as log:
        data = await reader.read()
        msg = data.decode()
        addr = writer.get_extra_info('peername')

        log_input(msg, addr, log)

        try:
            cmd = parse_msg(msg)
            
        except Exception as e:
            writer.write(f"? {msg}".encode())
            await writer.drain()
            log_output(f"? {msg}", addr, log)
            writer.close()
            print(f"Closed the connection to {addr}")
            return

        await HANDLES.get(cmd["name"])(reader, writer, cmd, log)
    

async def main(server_name):
    server = await asyncio.start_server(handle_msg, 'localhost', SERVER_TO_PORT.get(server_name))
    addr = server.sockets[0].getsockname()
    print(f'Serving on {addr}')

    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    try:
        server_name = sys.argv[1]
    except IndexError:
        raise SystemExit("Usage: server.py <server_name>")

    if server_name not in SERVER_TO_PORT:
        raise SystemExit("Usage: server.py <server_name>")

    try:
        asyncio.run(main(server_name))
        # print(parse_msg("   AT Riley +0.263873386 kiwi.cs.ucla.edu +34.068930-118.445127 1614209128.918963997   \n  "))

    except KeyboardInterrupt:
        sys.exit(0)
