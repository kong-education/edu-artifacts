import json
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000",
    api_key="dummy"
)

stream = client.chat.completions.create(
    model="gpt-3.5-turbo",
    messages=[{"role": "user", "content": "Tell me the history of Kong Inc."}],
    stream=True,
)

# Keep track of whether the model has been printed
printed_model = False

print('>')
for chunk in stream:
    # Print the model name if it hasn't been printed yet
    if not printed_model:
        model = chunk.model  # assuming the model info is available in the chunk
        if model:
            print(f"\n*********************** Response Model: {model} ***********************\n")
            printed_model = True

    # Print the response content
    print(chunk.choices[0].delta.content or "", end="", flush=True)