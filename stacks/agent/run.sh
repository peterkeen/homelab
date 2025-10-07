#!/bin/sh

export ANTHROPIC_API_KEY=$(op read --force op://cwko4woghmlxsmnok6cjuorjnu/eguhj2k4esntmgcrwaemo6i4gi/credential)
export OPENAI_API_KEY=$(op read --force "op://cwko4woghmlxsmnok6cjuorjnu/rmf6trcdm3ucae735uqfzqyeae/Home Assistant API Key")
export HASS_API_TOKEN=$(op read --force op://fmycvdzmeyvbndk7s7pjyrebtq/qhk73pwsgh3qkjjktfawy7f5le/HASS_API_TOKEN)
export OLLAMA_API_BASE=http://ollama.localllama.svc.omicron.keen.land:11434
export OLLAMA_API_KEY=not-used

exec uv run fastapi run agent/server.py
