import requests
import chromadb
import os
import json
import csv
import logging

from datetime import datetime
from openai import OpenAI
from chromadb.utils.embedding_functions import OllamaEmbeddingFunction
from chromadb.config import DEFAULT_TENANT, DEFAULT_DATABASE, Settings

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(message)s')  # Set the desired level here

logging.info("loading prereqs")

hass_base_url = os.environ["HASS_BASE_URL"]
hass_access_token = os.environ["HASS_API_TOKEN"]

litellm_base_url = os.environ["LITELLM_BASE_URL"]
litellm_token = os.environ["LITELLM_TOKEN"]

data_path = os.environ["DATA_PATH"]

chroma_client = chromadb.PersistentClient(
    path=data_path,
    settings=Settings(),
    tenant=DEFAULT_TENANT,
    database=DEFAULT_DATABASE,    
)

embedding_func = OllamaEmbeddingFunction(
    model_name="mxbai-embed-large:latest",
    url="http://nibbler.tailnet-a578.ts.net:11434/api/embeddings"
)

collection = chroma_client.create_collection(name="hass", embedding_function=embedding_func)
hass_access_token = os.environ["HASS_API_TOKEN"]
litellm_token = os.environ["LITELLM_TOKEN"]

def expand(template):
    resp = requests.post(
        "http://home.tailnet-a578.ts.net:8123/api/template",
        json={"template": template},
        headers={"Authorization": f"Bearer {hass_access_token}"},
        timeout=10
    )

    return resp.text

logging.info("generate device list")

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

all_devices_data = expand(devices_template)

logging.info("populating db")

entity_docs = []

for line in all_devices_data.split("\n"):
    area_id, area_name, entity_name, entity_id = line.split("|")
    title = f"{entity_name} (entity id: {entity_id}) in area {area_name} (area id: {area_id})"
    entity_docs.append({
        "title": title,
        "area_id": area_id, 
        "area_name": area_name,
        "entity_id": entity_id,
        "entity_name": entity_name,        
    })

collection.add(
    documents=[d["title"] for d in entity_docs],
    ids=[d["entity_id"] for d in entity_docs],
    metadatas=entity_docs
)

logging.info("done")
