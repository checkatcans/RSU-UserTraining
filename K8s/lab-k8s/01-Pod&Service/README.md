# Create the pod
`kubectl apply -f pod-definition.yml`

# Get a list of running pods
`kubectl get pods`

# Get logs of running pods
`kubectl logs myapp-pod`

# Get more info
```bash
kubectl get pods -o wide
kubectl describe pod myapp-pod
```

# Create the service
`kubectl apply -f service-definition.yml`

# Get all of running 
```bash
kubectl get all
Get the NodePort of service/myapp-service
Open browser the go to http://171.102.216.177:NodePort
```

# Cleanup
`kubectl delete -f pod-definition.yml`
