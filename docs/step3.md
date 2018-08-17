# Step 3. Configure cluster

### 1. Create it-dev namespace
```sh
$ kubectl create namespace it-dev
```

### 2. Expanding Persistent Volumes Claims [link](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims)
Expanding in-use PVCs is an alpha feature. To use it, enable the ExpandInUsePersistentVolumes feature gate. In this case, you don’t need to delete and recreate a Pod or deployment that is using an existing PVC. Any in-use PVC automatically becomes available to its Pod as soon as its file system has been expanded. This feature has no effect on PVCs that are not in use by a Pod or deployment. You must create a Pod which uses the PVC before the expansion can complete.

```sh
# create resizible storage class 
$ kubectl apply -f src/storage-class/gp2-resize-storage-class.yaml --namespace it-dev
```
> Note: Expanding EBS volumes is a time consuming operation. Also, there is a per-volume quota of one modification every 6 hours.

### 3. Metrics-server [link](https://kubernetes.io/docs/tasks/debug-application-cluster/core-metrics-pipeline/)
Starting from Kubernetes 1.8, resource usage metrics, such as container CPU and memory usage, are available in Kubernetes through the Metrics API. These metrics can be either accessed directly by user, for example by using kubectl top command, or used by a controller in the cluster, e.g. Horizontal Pod Autoscaler, to make decisions.

```sh
$ kubectl apply -f src/metrics-server/v1.8.x.yaml
# test
$ kubectl top no
OR
$ kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```

### 4. Helm [link](https://github.com/helm/helm)
`Helm` helps you manage Kubernetes applications — Helm Charts helps you define, install, and upgrade even the most complex Kubernetes application.
Charts are easy to create, version, share, and publish — so start using Helm and stop the copy-and-paste madness.

```sh
$ export HELM_HOME=$(pwd)/.helm
$ kubectl create serviceaccount --namespace kube-system tiller
$ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
$ helm init --service-account tiller
```

### 5. Ingress [link](https://kubernetes.io/docs/concepts/services-networking/ingress/)
An API object that manages external access to the services in a cluster, typically HTTP.
`Ingress` can provide load balancing, SSL termination and name-based virtual hosting.

```sh
$ kubectl create namespace nginx-ingress
$ helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true --set controller.stats.enabled=true --set controller.metrics.enabled=true --set controller.publishService.enabled=true --namespace nginx-ingress
```

### 6. ExternalDNS [link](https://github.com/kubernetes-incubator/external-dns)
Configure external DNS servers (AWS Route53, Google CloudDNS and others) for Kubernetes Ingresses and Services.
`ExternalDNS` synchronizes exposed Kubernetes Services and Ingresses with DNS providers.

```sh
DNS_ZONE=example.com

dns=src/external-dns/deployment.yaml
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" "${dns}"
$ kubectl apply -f src/external-dns
```

### 7. Cert-manager [link](https://github.com/jetstack/cert-manager)
Automatically provision and manage TLS certificates in Kubernetes.

```sh
EMAIL=example@email.com

issuer=src/cert-manager/issuer.yaml
$ sed -i -e "s@{{EMAIL}}@${EMAIL}@g" "${issuer}"
$ helm install --name cert-manager --namespace kube-system stable/cert-manager
$ kubectl apply -f cert-manager/issuer.yaml
```

# What's next?

### Step 4. [AuthN and AuthZ](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step4.md)