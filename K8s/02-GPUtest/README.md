
# Create the pod
`kubectl apply -f cuda-test.yaml`

# Get a list of running pods
`kubectl get pods`

# Get logs of running pods
`kubectl logs cuda-test`

# Cleanup
`kubectl delete -f cuda-test.yaml`
