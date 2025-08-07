```shell
source ~/start_lab.sh

env | grep -E '(KONG_|FQDN)' | sort

./setup.sh

curl -X POST http://$FQDN:11434/api/generate -d '{
  "model": "llama2",
  "stream": false,
  "prompt": "In less than 30 words, explain Why the sky is blue?"
}' -s | jq .

curl http://$FQDN:11434/api/chat -d '{
	"model": "llama2",
	"stream": false,
	"messages": [
		{
			"role": "system",
			"content": "You will reply in 30 words or less"
		},
		{
			"role": "user",
			"content": "Why is the sky blue?"
		}
	]
}' -s | jq .

curl http://$FQDN:11434/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "gpt-3.5-turbo",
        "messages": [
            {
                "role": "user",
                "content": "Hello!"
            }
        ]
    }' -s | jq .


curl -X POST $KONG_ADMIN_GUI_API_URL/default/routes/llama2-chat/plugins \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d name='ai-proxy' \
  -d instance_name='llama2-ai-proxy' \
  -d config.model.name='llama2' \
  -d config.model.options.llama2_format='ollama' \
  -d config.model.options.upstream_url='http://kong-lab-ollama:11434/api/chat' \
  -d config.model.provider='llama2' \
  -d config.model.options.max_tokens=30 \
  -d config.route_type='llm/v1/chat'

curl -X POST \
  $KONG_PROXY_URL/chat \
  -H 'x-llm: llama2' \
  -H 'Content-Type: application/json' \
  -d '{
	"messages": [
		{
			"role": "system",
			"content": "You will reply in 30 words or less"
		},
		{
			"role": "user",
			"content": "Why is the sky blue?"
		}
	]
}' -s | jq .

curl -X POST $KONG_ADMIN_GUI_API_URL/default/routes/oai-chat/plugins \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d name='ai-proxy' \
  -d instance_name='oai-ai-proxy' \
  -d config.auth.header_name='Authorization' \
  -d config.auth.header_value='Bearer 937c4183-af25-44c4-9e86-5a1ccfccbfb7' \
  -d config.model.name='gpt-3.5-turbo' \
  -d config.model.options.upstream_url='http://kong-lab-ollama:11434/v1/chat/completions' \
  -d config.model.provider='openai' \
  -d config.model.options.max_tokens=30 \
  -d config.route_type='llm/v1/chat'

curl -X POST \
  $KONG_PROXY_URL/chat \
  -H 'Content-Type: application/json' \
  -H 'x-llm: openai' \
  -d '{
	"messages": [
		{
			"role": "system",
			"content": "You will reply in 30 words or less"
		},
		{
			"role": "user",
			"content": "Why is the sky blue?"
		}
	]
}' -s | jq .

curl $KONG_ADMIN_GUI_API_URL/default/plugins/ \
  -X 'POST' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d name=file-log \
  -d config.path=/tmp/ai-logging.log

curl $KONG_ADMIN_GUI_API_URL/default/plugins/llama2-ai-proxy \
  -X 'PATCH' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d config.model.name=llama2 \
  -d config.model.options.upstream_url=http://$FQDN:11434/api/chat \
  -d config.model.options.llama2_format=ollama \
  -d config.model.options.max_tokens=30 \
  -d config.model.provider=llama2 \
  -d config.logging.log_statistics=true \
  -d config.route_type=llm/v1/chat

curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [     
	{       
		"role": "user",       
		"content": "What color is the sky?"     
	}   
] 
}' -s | jq .

docker exec kong-lab-gw cat /tmp/ai-logging.log | jq '.ai | select(. != null)'


curl $KONG_ADMIN_GUI_API_URL/default/plugins/llama2-ai-proxy \
  -X 'PATCH' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d config.model.name=llama2 \
  -d config.model.options.upstream_url=http://$FQDN:11434/api/chat \
  -d config.model.options.llama2_format=ollama \
  -d config.model.provider=llama2 \
  -d config.logging.log_statistics=false \
  -d config.logging.log_payloads=true \
  -d config.route_type=llm/v1/chat

curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [     
	{       
		"role": "user",       
		"content": "What color is the sky?"
	}   
] 
}' -s | jq .

docker exec kong-lab-gw cat /tmp/ai-logging.log | jq '.ai | select(. != null)'

curl $KONG_ADMIN_GUI_API_URL/default/plugins/llama2-ai-proxy \
  -X 'PATCH' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d config.response_streaming=always \
  -d config.model.name=llama2 \
  -d config.model.options.upstream_url=http://$FQDN:11434/api/chat \
  -d config.model.options.llama2_format=ollama \
  -d config.model.provider=llama2 \
  -d config.logging.log_statistics=false \
  -d config.logging.log_payloads=false \
  -d config.route_type=llm/v1/chat

curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [     
	{       
		"role": "user",       
		"content": "What color is the sky?"     
	}   
],
    "stream":true
}'


curl $KONG_ADMIN_GUI_API_URL/default/plugins/llama2-ai-proxy \
  -X 'PATCH' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d config.response_streaming=allow \
  -d config.model.name=llama2 \
  -d config.model.options.upstream_url=http://$FQDN:11434/api/chat \
  -d config.model.options.llama2_format=ollama \
  -d config.model.provider=llama2 \
  -d config.logging.log_statistics=false \
  -d config.logging.log_payloads=false \
  -d config.route_type=llm/v1/chat

curl -X POST $KONG_ADMIN_GUI_API_URL/services/httpbin/routes  \
  -H 'Content-Type: application/x-www-form-urlencoded'   \
  -d 'name=sdk-route' \
  -d "paths[]=~/sdk/(?<model>[^#?%2B]%2B)"


curl -X POST $KONG_ADMIN_GUI_API_URL/default/routes/sdk-route/plugins \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d name='ai-proxy' \
  -d instance_name='sdk-ai-proxy' \
  -d config.auth.header_name='Authorization' \
  -d config.auth.header_value='Bearer 937c4183-af25-44c4-9e86-5a1ccfccbfb7' \
  -d config.model.name='$(uri_captures.model)' \
  -d config.model.options.upstream_url='http://kong-lab-ollama:11434/v1/chat/completions' \
  -d config.model.provider='openai' \
  -d config.model.options.max_tokens=30 \
  -d config.route_type='llm/v1/chat'


python3 oai.py

python3 oai.py

python3 multi-model.py

python3 multi-model.py

curl $KONG_ADMIN_GUI_API_URL/default/plugins/llama2-ai-proxy \
  -X 'PATCH' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d config.model.name=llama2 \
  -d config.model.options.upstream_url=http://$FQDN:11434/api/chat \
  -d config.model.options.llama2_format=ollama \
  -d config.model.options.max_tokens=30 \
  -d config.model.provider=llama2 \
  -d config.route_type=llm/v1/completions

curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [     
	{       
		"role": "user",       
		"content": "What color is the sky?"
	}   
] 
}' -s | jq .

curl $KONG_ADMIN_GUI_API_URL/default/plugins/llama2-ai-proxy \
  -X 'PATCH' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d config.model.name=llama2 \
  -d config.model.options.upstream_url=http://$FQDN:11434/api/chat \
  -d config.model.options.llama2_format=ollama \
  -d config.model.provider=llama2 \
  -d config.route_type=llm/v1/chat 

curl $KONG_ADMIN_GUI_API_URL/default/plugins/llama2-ai-proxy \
  -X 'PATCH' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d config.model.name=llama2 \
  -d config.model.options.upstream_url=http://$FQDN:11434/api/chat \
  -d config.model.options.llama2_format=ollama \
  -d config.model.options.max_tokens=30 \
  -d config.route_type=llm/v1/chat

curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [     
	{       
		"role": "user",       
		"content": "What color is the sky?"
	}
],
	"prompt": "This is an error test"
}' -s | jq .

curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [     
	{       
		"role": "user",       
		"content": "What color is the sky?"
	}
]
}' -s | jq .

curl $KONG_ADMIN_GUI_API_URL/default/plugins/llama2-ai-proxy \
  -X 'PATCH' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d config.model.name=llama2 \
  -d config.model.options.upstream_url=http://$FQDN:11434/api/chat \
  -d config.model.options.llama2_format=ollama \
  -d config.model.options.max_tokens=30 \
  -d config.route_type=llm/v1/chat

 curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [{       
		"role": "user",       
		"content": "What color is the sky?"
	}],
	"model": "yeaImadeThisUP"
}' -s | jq .

curl $KONG_PROXY_URL/chat \
  -X 'POST' \ \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{ 
	"messages1": [
		{
			"role":"system",
			"content":"You are an API expert and will respond in the style of William Shakespeare"
		},
		{
			"role":"user",
			"content":"what is Kong API Gateway?"
		}

	],
	"prompt1": "test"
}' -s | jq .

curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [{       
		"role": "user",       
		"content": "What color is the sky?"
	}]
}' -s | jq .

curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/xml' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [{       
		"role": "user",       
		"content": "What color is the sky?"
	}]
}' -s | jq .

curl $KONG_PROXY_URL/chat \
  -X 'POST' \
  -H 'Content-Type: application/json' \
  -H 'x-llm: llama2' \
  -d '{   
	"messages": 
 [{       
		"role": "user",       
		"content": "What color is the sky?"
	}]
}' -s | jq .

