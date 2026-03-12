kubectl apply -f ollama-deployment.yaml
kubectl apply -f ollama-service.yaml
kubectl apply -f gradio-deployment.yaml  
kubectl apply -f gradio-service.yaml    


# Pull model
kubectl exec -it -n test01-restricted deploy/ollama -- ollama pull scb10x/llama3.1-typhoon2-8b-instruct

# Restart deployment after pull model
kubectl rollout restart deployment/gradio-chatbot -n test01-restricted


try access on web, will found the model for testing
