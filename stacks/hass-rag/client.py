from openai import OpenAI

openai_client = OpenAI(
    base_url="http://localhost:8000",
    api_key="abc123",
)

completion = openai_client.chat.completions.create(
    model="qwen2.5:7b",
    messages=[
        {
            "role": "system",
            "content": "You are a helpful assistant named Beatrice.",
        },
        {
            "role": "user",
            "content": "Hello. What is your name?",
        }
    ]
)

print(completion)
