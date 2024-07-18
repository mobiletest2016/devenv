## Check microk8s_registry

## Check microk8s_spark

## INSTALL microk8s:

sudo snap install microk8s --classic

microk8s enable dns
microk8s enable registry
microk8s enable istio
microk8s enable helm
microk8s enable helm3

alias microk8s.kubectl

### Basic commands:

kubectl cluster-info

kubectl get pods

kubectl get pods --all-namespaces

kubectl get pods,services --all-namespaces

kubectl describe pod springhello

kubectl get pod springhello -o wide

kubectl describe pod registry-6c9fcc695f-r4sgz --namespace=container-registry

kubectl get pod registry-6c9fcc695f-r4sgz --namespace=container-registry -o wide


### Runtime Edit: (Do it in emergency)

kubectl edit pod springhello


### JSON:

kubectl get pod springhello -o json

kubectl get pod springhello -o jsonpath --template={.status.podIP}

kubectl get pod springhello -o jsonpath --template={.status.hostIP}


### Label:

kubectl label pods springhello color=blue

kubectl describe pod springhello  | grep color

kubectl label pods springhello color-		 ** Remove label **


### Logs:

kubectl logs springhello

kubectl logs -f springhello         ** Continuous logs **

### Command inside container:

kubectl exec springhello -- hostname

kubectl exec springhello -- find / -name *log

### Attach:

kubectl attach -it springhello

### Copy files:
kubectl cp springhello::</path/to/remote/file> </path/to/local/file>

### Port forward:

kubectl port-forward springhello 8080:80

### delete pod:

kubectl delete pods springhello

### Misc:

kubectl get events

kubectl top nodes

kubectl top pods

### Take out host from kubernetes scheduling (for maintainance):

kubectl cordon

### Remove pods from the host:

kubectl drain

### Add host back to kubernetes scheduling:

kubectl uncordon

### Run pod from pod manifest file:		(Make sure the image is in local registry by following:  microk8s_registry)

kubectl apply -f springhello_pod.yml 

kubectl get pod springhello -o jsonpath --template={.status.podIP}

curl 10.1.181.100:8080

### Delete pod:

kubectl delete -f springhello_pod.yml 
