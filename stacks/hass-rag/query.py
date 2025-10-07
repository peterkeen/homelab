import requests
import chromadb
import os
import sys
import json
import csv
import logging

from datetime import datetime
from openai import OpenAI
from chromadb.utils.embedding_functions import OllamaEmbeddingFunction
from chromadb.config import DEFAULT_TENANT, DEFAULT_DATABASE, Settings

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(message)s')  # Set the desired level here

logging.info("loading prereqs")

QUERY = " ".join(sys.argv[1:])

chroma_client = chromadb.PersistentClient(
    path="test",
    settings=Settings(anonymized_telemetry=False,),
    tenant=DEFAULT_TENANT,
    database=DEFAULT_DATABASE,
)

embedding_func = OllamaEmbeddingFunction(
    model_name="mxbai-embed-large:latest",
    url="http://nibbler.tailnet-a578.ts.net:11434/api/embeddings"
)
collection = chroma_client.get_or_create_collection(name="hass", embedding_function=embedding_func)

hass_access_token = os.environ["HASS_API_TOKEN"]
litellm_token = os.environ["LITELLM_TOKEN"]

def expand(template):
    resp = requests.post(
        "https://hass.keen.land/api/template",
        json={"template": template},
        headers={"Authorization": f"Bearer {hass_access_token}"},
        timeout=10
    )

    return resp.text

logging.info("query")

results = collection.query(
    query_texts=[QUERY]
)

examples = []
llm_prompt = ""

entity_ids = ",".join([f"'{entity}'" for entity in results['ids'][0]])

states_template = """
{%- for entity in [{{ENTITY_IDS}}] %}
{{ state_attr(entity, 'friendly_name') }} in {{ area_name(area_id(entity)) }} is {{ states(entity) }}.

{%- endfor %}
""".replace("{{ENTITY_IDS}}", entity_ids)

logging.info("generate prompt")

llm_prompt = expand(states_template.replace("{{ENTITY_IDS}}", entity_ids))

prompt = f"""
Current time is {datetime.now().strftime("%H:%M:%S")}.
Today's date is {datetime.now().strftime("%Y-%m-%d")}.

You are a voice assistant for Home Assistant.
Answer questions about the world truthfully.
Answer in plain text. Keep it simple and to the point.
If you don't know the answer to a question say "I don't know."
Do not hallucinate.

{llm_prompt}

"""

prompt = prompt.strip()

logging.info(prompt)

logging.info("chat")

openai_client = OpenAI(
    base_url="https://litellm.tailnet-a578.ts.net",
    api_key=litellm_token,
)

completion = openai_client.chat.completions.create(
    #model="llama3.1:8b",
    # model="claude",
    model="qwen2.5:7b",
    messages=[
        {
            "role": "system",
            "content": prompt,
        },
        {
            "role": "user",
            "content": QUERY,
        }
    ]
)

print(completion.choices[0].message.content)

logging.info("done")
