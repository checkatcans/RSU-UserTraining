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
```
`Then try access on web, will found the model for testing`

<img width="1624" height="1009" alt="image" src="https://github.com/user-attachments/assets/d96ff664-1432-488a-8c04-d8ee7e8e66bd" />


# Cleanup
```bash
kubectl delete deployment --all
kubectl delete service --all
```
