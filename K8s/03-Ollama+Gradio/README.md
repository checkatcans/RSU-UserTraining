# Create Ollama model directory
`mkdir -p /data/home/$USER/ollama_models/models`

# Create the Ollama deployment
`kubectl apply -f ollama-deployment.yaml`

# Create the Ollama service
`kubectl apply -f ollama-service.yaml`

# Get all of running
`kubectl get all`

# Create the Gradio deployment
`kubectl apply -f gradio-deployment.yaml`

# Create the Gradio service
`kubectl apply -f gradio-service.yaml`

# Get all of running
`kubectl get all`

# Manually Pull model
`kubectl exec -it deploy/ollama -- ollama pull scb10x/llama3.1-typhoon2-8b-instruct`

# Restart deployment after pull model
```bash
kubectl rollout restart deployment/gradio-chatbot
try access on web, will found the model for testing
```

# Cleanup
```bash
kubectl delete -f deployment-definition.yml
kubectl delete -f service-definition.yml
```
