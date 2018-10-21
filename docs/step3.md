###### [Back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step2.md)

# Step 3. Configure cluster

### 1. Set common environment variables
```sh
export NAMESPACE=it-dev
export DNS_ZONE=example.com
```

### 2. Create namespace
```sh
kubectl create namespace $NAMESPACE
```

### 3. Create PodSecurityPolicy
```sh
kubectl create -f src/psp
```

### 4. Create RBAC
```sh
sed -i -e "s@{{NAMESPACE}}@${NAMESPACE}@g" src/rbac/developers.yaml
kubectl create -f src/rbac
```

### 5. Helm [link](https://github.com/helm/helm)
`Helm` helps you manage Kubernetes applications — Helm Charts helps you define, install, and upgrade even the most complex Kubernetes application.
Charts are easy to create, version, share, and publish — so start using Helm and stop the copy-and-paste madness.

```sh
{
export HELM_HOME=$(pwd)/.helm
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
}
```

### 6. Kube2iam [link](https://github.com/jtblin/kube2iam)
Provide IAM credentials to containers running inside a kubernetes cluster based on annotations.

```sh
{
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
helm install stable/kube2iam --namespace kube-system --name kube2iam --set=extraArgs.base-role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/,host.iptables=true,host.interface=cali+,rbac.create=true,verbose=true
}
```

### 7. Expanding Persistent Volumes Claims [link](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims)
Expanding in-use PVCs is an alpha feature. To use it, enable the ExpandInUsePersistentVolumes feature gate. In this case, you don’t need to delete and recreate a Pod or deployment that is using an existing PVC. Any in-use PVC automatically becomes available to its Pod as soon as its file system has been expanded. This feature has no effect on PVCs that are not in use by a Pod or deployment. You must create a Pod which uses the PVC before the expansion can complete.

```sh
# create resizible storage class 
kubectl apply -f src/storage-class/gp2-resize-storage-class.yaml --namespace $NAMESPACE
```
> Note: Expanding EBS volumes is a time consuming operation. Also, there is a per-volume quota of one modification every 6 hours.

### 8. Metrics-server [link](https://kubernetes.io/docs/tasks/debug-application-cluster/core-metrics-pipeline/)
Starting from Kubernetes 1.8, resource usage metrics, such as container CPU and memory usage, are available in Kubernetes through the Metrics API. These metrics can be either accessed directly by user, for example by using kubectl top command, or used by a controller in the cluster, e.g. Horizontal Pod Autoscaler, to make decisions.

```sh
kubectl apply -f src/metrics-server/v1.8.x.yaml

# test
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```

### 9. Ingress [link](https://kubernetes.io/docs/concepts/services-networking/ingress/)
An API object that manages external access to the services in a cluster, typically HTTP.
`Ingress` can provide load balancing, SSL termination and name-based virtual hosting.

```sh
{
kubectl create namespace nginx-ingress
helm install stable/nginx-ingress --name nginx-ingress -f src/nginx-ingress/values.yaml --namespace nginx-ingress
}
```

### 10. ExternalDNS [link](https://github.com/kubernetes-incubator/external-dns)
Configure external DNS servers (AWS Route53, Google CloudDNS and others) for Kubernetes Ingresses and Services.
`ExternalDNS` synchronizes exposed Kubernetes Services and Ingresses with DNS providers.

```sh
# set vars
vi src/external-dns/external-dns.sh 
```
```sh
# run script
./src/external-dns/external-dns.sh 
```

### 11. Cert-manager [link](https://github.com/jetstack/cert-manager)
Automatically provision and manage TLS certificates in Kubernetes.

```sh
# cert manager
helm install --name cert-manager --namespace kube-system stable/cert-manager
```
```sh
# issuer
{
EMAIL="example\@email.com" # backslash required
sed -i -e "s@{{EMAIL}}@${EMAIL}@g" src/cert-manager/issuer.yaml
kubectl apply -f src/cert-manager/issuer.yaml
}
```

### 12. Check created k8s resources

```sh
helm ls
kubectl get namespaces
kubectl get storageclass gp2-resize
kubectl get deploy metrics-server -n kube-system 
kubectl get deploy external-dns -n $NAMESPACE
kubectl get clusterissuer letsencrypt-prod
```

<!-- ## Demo

<p align="center">
  <a target="_blank" href="https://asciinema.org/a/197030">
  <img src="https://asciinema.org/a/197030.png" width="885"></image>
  </a>
</p> -->

# What's next?

### Step 4. [AuthN and AuthZ](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step4.md)