LLM Proxy
---------

* presents a limited OpenAI compatible set of endpoints
* generate embeddings for every entity in home assistant, feed to chromadb or similar
* rewrite system prompt to only include states of entities relevant to the query

pseudocode for completion endpoint:

```
chromadb = {}
relevant_entities = Set()

for message in messages:
    if message is from user:
        relevant_entities << chromadb.query(message)
   
insert relevant entities into template for HA and expand

replace system message with expanded template

pass rewriten messages to LLM
return unadulterated response to client
```

