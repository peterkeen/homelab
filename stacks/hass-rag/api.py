import requests
import chromadb
import os
import sys
import logging
import json
import yaml

from datetime import datetime
from ollama import ChatResponse, Client
from ollama._types import ChatRequest
from chromadb.utils.embedding_functions import OllamaEmbeddingFunction
from chromadb.config import DEFAULT_TENANT, DEFAULT_DATABASE, Settings

from fastapi import FastAPI
from fastapi_utils.tasks import repeat_every

logging.basicConfig(level=logging.DEBUG, format='%(asctime)s %(message)s')  # Set the desired level here

logging.info("loading prereqs")

hass_base_url = os.environ["HASS_BASE_URL"]
hass_access_token = os.environ["HASS_API_TOKEN"]

ollama_base_url = os.environ["OLLAMA_BASE_URL"]

data_path = os.environ["DATA_PATH"]

chroma_client = chromadb.PersistentClient(
    path=data_path,
    settings=Settings(),
    tenant=DEFAULT_TENANT,
    database=DEFAULT_DATABASE,
)

embedding_func = OllamaEmbeddingFunction(
    model_name="mxbai-embed-large:latest",    
    url=ollama_base_url + "/api/embeddings",
)

collection = chroma_client.get_or_create_collection(name="hass", embedding_function=embedding_func)

app = FastAPI()

ollama_client = Client(
    host=ollama_base_url
)

devices_template = """
{%- for area in areas() %}
{%- for device in area_devices(area) %}
  {%- if not device_attr(device, "disabled_by") and not device_attr(device, "entry_type") and device_attr(device, "name") %}
    {%- for entity in device_entities(device) %}
      {%- set entity_domain = entity.split('.')[0] %}
      {%- if not is_state(entity,'unavailable') and not is_state(entity,'unknown') and not is_state(entity,"None") and not is_hidden_entity(entity) %}
{{area}}|{{area_name(area)}}|{{state_attr(entity, 'friendly_name')}}|{{entity}}
      {%- endif %}
    {%- endfor %}
  {%- endif %}
{%- endfor %}
{%- endfor %}
"""

@app.on_event("startup")
@repeat_every(seconds=15*60)
def refresh_embeddings():
    logging.info("refreshing embeddings")
    device_data = expand(devices_template)
    entity_docs = []
    entity_ids = set()

    for line in device_data.split("\n"):
        area_id, area_name, entity_name, entity_id = line.split("|")
        title = f"{entity_name} (entity id: {entity_id}) in area {area_name} (area id: {area_id})"
        entity_docs.append({
            "title": title,
            "area_id": area_id, 
            "area_name": area_name,
            "entity_id": entity_id,
            "entity_name": entity_name,            
        })
        entity_ids.add(entity_id)

    known_docs = collection.get(include=[])
    for known_id in known_docs["ids"]:
        if known_id not in entity_ids:
            logging.info(f"deleting id {known_id}")
            collection.delete(ids=[known_id])

    for doc in entity_docs:
        collection.upsert(
            documents=[doc["title"]],
            ids=[doc["entity_id"]],
            metadatas=[doc]
        )

def hass_api_post(name, data):
    return requests.post(
        hass_base_url + "/api/" + name,
        json=data,
        headers={"Authorization": f"Bearer {hass_access_token}"},
        timeout=10
    )

def expand(template):
    resp = hass_api_post("template", {"template": template})
    return resp.text


@app.get("/")
def read_root():
    return {"ok": True}

@app.post("/api/chat")
def process_completions(request: ChatRequest):
    new_messages = []

    discovered_entity_names = set()

    system_prompt = ""

    states = []

    for m in request["messages"]:
        if m["role"] == "system":
            system_prompt += m["content"]
        elif m["role"] == "user":
            docs = collection.query(
                query_texts=[m["content"]]
            )

            for i in range(len(docs["metadatas"][0])):
                distance = docs["distances"][0][i]
                metadata = docs["metadatas"][0][i]

                discovered_entity_names.add(metadata["entity_name"].strip())

            new_messages.append(m)
        else:
            new_messages.append(m)

    system_prompt, exposed_entities_str = system_prompt.split("An overview of the areas and the devices in this smart home:")

    exposed_entities = yaml.safe_load(exposed_entities_str) or []

    entity_states = []

    for exposed_entity in exposed_entities:
        for name in exposed_entity["names"].split(","):
            if name.strip() in discovered_entity_names:
                exposed_entity["names"] = exposed_entity["names"].strip()

                if exposed_entity["domain"] == "light":
                    if "brightness" in exposed_entity.get("attributes", {}):
                        b = exposed_entity["attributes"]["brightness"]

                        if b is not None:
                            exposed_entity["attributes"]["brightness"] = round(float(b) / 255.0 * 100.0, 0)
                    
                entity_states.append(exposed_entity)

    entity_states_str = yaml.dump(entity_states)

    system_message = {
        "role": "system",
        "content": system_prompt + "\nAn overview of the areas and the devices in this smart home:\n\n" + entity_states_str
    }

    request["messages"] = [system_message] + new_messages

    logging.info(request)

    print("completion start", file=sys.stderr)

    completion = ollama_client.chat(**request.model_dump())
    return completion

@app.get("/api/tags")
def process_tags():
    return ollama_client.list()
