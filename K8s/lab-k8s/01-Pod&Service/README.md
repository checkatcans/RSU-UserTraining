


# Create the pod
`kubectl apply -f pod-definition.yml`

# Get a list of running pods
`kubectl get pods`

# Get logs of running pods
`kubectl logs myapp-pod`

# Get more info
`kubectl get pods -o wide
kubectl describe pod myapp-pod`

# Cleanup
`kubectl delete -f pod-definition.yml`
