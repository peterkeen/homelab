import requests
import chromadb
import os
import sys
import json
import csv
import logging

from datetime import datetime
from ollama import Client
from chromadb.utils.embedding_functions import OllamaEmbeddingFunction
from chromadb.config import DEFAULT_TENANT, DEFAULT_DATABASE, Settings

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(message)s')  # Set the desired level here

QUERY = " ".join(sys.argv[1:])

logging.info("chat")

ollama_client = Client(
    host="http://localhost:8000",
)

completion = ollama_client.chat(
    model="qwen2.5:3b-long",
    messages=[
        {
            "role": "system",
            "content": "i am a banana\nAn overview of the areas and the devices in this smart home:",
        },
        {
            "role": "user",
            "content": QUERY,
        }
    ]
)

print(completion)
logging.info("done")
