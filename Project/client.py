import asyncio
import sys

async def tcp_echo_client(message):
    reader, writer = await asyncio.open_connection('localhost', 15700)

    print(f'Send: {message}')
    writer.write(message.encode())
    await writer.drain()

    data = await reader.read(100)
    print(f'Received: {data.decode()}')

    print('Close the connection')
    writer.close()
    await writer.wait_closed()

if __name__ == "__main__":
    try:
        arg = sys.argv[1]
    except IndexError:
        raise SystemExit("Usage: server.py <message>")

    asyncio.run(tcp_echo_client(arg))