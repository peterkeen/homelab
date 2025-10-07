"""Some simple tests/example for the Home Assistant client."""

import argparse
import asyncio
import logging
import os
import sys
import json

from contextlib import suppress

from aiohttp import ClientSession

from hass_client import HomeAssistantClient
from hass_client.models import Event

LOGGER = logging.getLogger()
HASS_URL = os.environ.get('HASS_URL')
HASS_API_TOKEN = os.environ.get('HASS_API_TOKEN')

def get_arguments() -> argparse.Namespace:
    """Get parsed passed in arguments."""
    parser = argparse.ArgumentParser(description="Home Assistant simple client for Python")
    parser.add_argument("--debug", action="store_true", help="Log with debug level")
    return parser.parse_args()


async def start_cli() -> None:
    """Run main."""
    args = get_arguments()
    level = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(level=level)

    async with ClientSession() as session:
        await connect(args, session)


async def connect(args: argparse.Namespace, session: ClientSession) -> None:
    """Connect to the server."""
    websocket_url = HASS_URL.replace("http", "ws") + "/api/websocket"
    async with HomeAssistantClient(websocket_url, HASS_API_TOKEN, session) as client:
        while True:
            await client.subscribe_events(log_events)
            await asyncio.sleep(300)


def log_events(event: Event) -> None:
    """Log node value changes."""
    print(json.dumps(event))

def main() -> None:
    """Run main."""
    with suppress(KeyboardInterrupt):
        asyncio.run(start_cli())

    sys.exit(0)


if __name__ == "__main__":
    main()
