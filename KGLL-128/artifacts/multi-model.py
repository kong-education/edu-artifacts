from openai import OpenAI
import openai
import os

messages = [
    {
        "role": "system",
        "content": "You are a helpful assistance who will reply concisely in less than 50 words."
    },
    {
        "role": "user",
        "content": "What is the capital of France?"
    }
]

model = "gpt-4o"

host = os.environ['KONG_PROXY_URL'] + "/chat"

client = OpenAI(
    api_key="xyz",
    base_url=host,
    default_headers = {"x-llm":"llama2"}
)

response = client.chat.completions.create(
    model=model,
    messages=messages,
    temperature=0.5,
)

print(f"Model: {response.model}\nResponse: {response.choices[0].message.content}\n")
