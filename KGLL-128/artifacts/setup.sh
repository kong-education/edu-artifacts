#!/bin/bash

URL=$KONG_ADMIN_GUI_API_URL
docker compose up -d

echo "Waiting for Kong to enter a ready state..."
while true; do
  RESPONSE_CODE=$(curl -o /dev/null -s -w "%{http_code}" $URL)
  if [ "$RESPONSE_CODE" -eq "200" ]; then
    deck gateway sync --kong-addr $KONG_ADMIN_GUI_API_URL kong.yaml
    break
  fi
for s in / - \\ \|; do 
    printf "\r$s"; sleep .1; 
done; 
done

docker exec kong-lab-ollama ollama pull llama2
docker exec kong-lab-ollama ollama cp llama2 gpt-3.5-turbo
docker exec kong-lab-ollama ollama cp llama2 gpt-4o

