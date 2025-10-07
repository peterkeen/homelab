from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sse_starlette import EventSourceResponse
from litellm import acompletion
from contextlib import asynccontextmanager

import logging
import json
import os

import litellm

from .hass import HassAgent

logging.basicConfig()

hass_agent = HassAgent(os.environ["HASS_API_URL"], os.environ["HASS_API_TOKEN"])

@asynccontextmanager
async def lifespan(app: FastAPI):
    await hass_agent.start()
    yield

app = FastAPI(title="OpenAI-compatible API", lifespan=lifespan)

async def redirect_ollama_to_openai_endpoints_filter(data):
    if data["model"].startswith("ollama/"):
        data["model"] = data["model"].replace("ollama/", "openai/")
        data["api_base"] = os.environ["OLLAMA_API_BASE"] + "/v1"
        data["api_key"] = os.environ["OLLAMA_API_KEY"]
    
    return data

async def log_given_filter(data):
    logging.warn(data)
    return data

async def log_system_prompt_filter(data):
    system = [m for m in data["messages"] if m["role"] == "system"]
    logging.debug(system)
    return data

async def replace_system_prompt_filter(data):
    non_system = [m for m in data["messages"] if m["role"] != "system"]
    system = {"content": "You are a helpful assistant named Jarvis", "role": "system"}
    non_system.insert(0, system)
    data["messages"] = non_system
    return data

data_filters = [
    log_given_filter,
    redirect_ollama_to_openai_endpoints_filter,
    # replace_system_prompt_filter,
    # log_system_prompt_filter,
]

@app.post("/chat/completions")
async def chat_completions(request: Request):
    data = await request.json()

    for f in data_filters:
        data = await f(data)

    resp = await acompletion(**data)

    if data.get("stream", False):
        async def stream_response():
            async for part in resp:
                out = json.dumps(part.model_dump())
                yield out

        return EventSourceResponse(stream_response())
    else:
        return JSONResponse(content=resp.model_dump())

@app.get("/models")
async def model_list(request: Request):
    return JSONResponse(content={"data": [], "object": "list"})

@app.get("/state/{entity_id}")
async def get_state(entity_id: str):
    state = hass_agent.get_state(entity_id)
    return JSONResponse(content=state)

@app.get("/query")
async def query_entities(query: str):
    state = hass_agent.find_entities(query)
    return JSONResponse(content=state)
