#!/bin/bash

# Exports OPENAI_API_KEY for this shell session by reading it from .env.
# The key itself lives only in .env / Secrets.xcconfig (both gitignored).

ENV_FILE="$(dirname "$0")/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ No .env file found. Copy the key into $ENV_FILE first (see Secrets.example.xcconfig)."
    return 1 2>/dev/null || exit 1
fi

export OPENAI_API_KEY="$(grep -E '^OPENAI_API_KEY=' "$ENV_FILE" | head -n1 | cut -d= -f2-)"

if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ OPENAI_API_KEY not set in .env"
    return 1 2>/dev/null || exit 1
fi

echo "✅ OpenAI API key exported for this session"
