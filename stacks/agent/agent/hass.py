import asyncio
import os

from aiohttp import ClientSession

from hass_client import HomeAssistantClient
from hass_client.models import Event

import logging
import chromadb
from chromadb.utils.embedding_functions.ollama_embedding_function import (
    OllamaEmbeddingFunction,
)

class HassAgent(object):
    def __init__(self, url, token):
        self.url = url
        self.token = token
        self.states = {}        
        self._ready = asyncio.Event()

        ollama_ef = OllamaEmbeddingFunction(
            url=os.environ["OLLAMA_API_BASE"],
            model_name="granite-embedding:30m",
        )

        self.chroma = chromadb.EphemeralClient()
        self.collection = self.chroma.create_collection(
            name="hass",
            embedding_function=ollama_ef,
        )

    async def start(self):
        self.states = {}

        async with ClientSession() as session:
            await self.connect(session)

    async def connect(self, session):
        """Connect to the server."""
        websocket_url = self.url.replace("http", "ws") + "/api/websocket"
        self.client = HomeAssistantClient(websocket_url, self.token, session)

        async with self.client as client:
            async with asyncio.TaskGroup() as tg:
                tg.create_task(self.setup_states(client))

    def process_event(self, event):
        if event["event_type"] != "state_changed":
            return

        self.states[event["data"]["entity_id"]] = event["data"]["new_state"]

    async def setup_states(self, client):
        states_list = await client.get_states()
        for state in states_list:
            self.states[state["entity_id"]] = state

        ids = [s["entity_id"] for s in states_list]
        friendly_names = [s["attributes"].get("friendly_name", s["entity_id"]) for s in states_list]

        loop = asyncio.get_running_loop()

        def add_stuff():
            self.collection.add(
                ids=ids,
                documents=friendly_names,
            )

            self._ready.set()            

        futex = loop.run_in_executor(None, add_stuff)

        await client.subscribe_events(self.process_event)


    def get_state(self, entity_id):
        state = self.states.get(entity_id, {})
        state["_ready"] = self._ready.is_set()

        return state

    def find_entities(self, query):
        return self.collection.query(query_texts=[query])
