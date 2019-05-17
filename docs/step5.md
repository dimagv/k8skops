###### [back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step4.md)

# Step 5. Monitoring

### 1. Kubernetes dashboard [link](https://github.com/kubernetes/dashboard)
`Kubernetes Dashboard` is a general purpose, web-based UI for Kubernetes clusters. It allows users to manage applications running in the cluster and troubleshoot them, as well as manage the cluster itself.

```sh
{
sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/kubernetes-dashboard/values.yaml
helm install stable/kubernetes-dashboard --name kubernetes-dashboard -f src/kubernetes-dashboard/values.yaml --namespace kube-system
}
```

### 2. [Prometheus-operator](https://github.com/helm/charts/tree/master/stable/prometheus-operator) ([Prometheus](https://prometheus.io/) & [Alertmanager](https://prometheus.io/docs/alerting/alertmanager/) & [Grafana](https://grafana.com/))
`prometheus-operator` is a set of Kubernetes manifests, Grafana dashboards, and Prometheus rules combined with documentation and scripts to provide easy to operate end-to-end Kubernetes cluster monitoring with Prometheus using the Prometheus Operator.

#### 2.1. Create monitoring namespace
```sh
kubectl create namespace monitoring
```

<!-- #### 2.3. Create PodSecurityPolicy
```sh
kubectl apply -f src/prometheus-operator/prev/psp.yaml
``` -->

#### 2.2. Create ETCD secret from the master node
```sh
# ssh to master
kubectl --namespace monitoring create secret generic prometheus-operator-etcd --from-file=ca=/etc/kubernetes/pki/kube-apiserver/etcd-ca.crt --from-file=cert=/etc/kubernetes/pki/kube-apiserver/etcd-client.crt --from-file=key=/etc/kubernetes/pki/kube-apiserver/etcd-client.key
```



#### 2.3. Prometheus-operator
```sh
ALERTMANAGER_SLACK_API_URL=https://hooks.slack.com/services/... # https://api.slack.com/apps
ALERTMANAGER_SLACK_CHANNEL=ironjab-alertmanager
ALERTMANAGER_SLACK_USERNAME=dimag
GRAFANA_ADMIN_USER=admin # random string
GRAFANA_ADMIN_PASSWORD=HSA4AeUGOIQI56Drbmm6GQ # random string

{
# install prometheus-operator
sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/prometheus-operator/values.yaml
sed -i -e "s@{{GRAFANA_ADMIN_USER}}@${GRAFANA_ADMIN_USER}@g" src/prometheus-operator/values.yaml
sed -i -e "s@{{GRAFANA_ADMIN_PASSWORD}}@${GRAFANA_ADMIN_PASSWORD}@g" src/prometheus-operator/values.yaml
sed -i -e "s@{{ALERTMANAGER_SLACK_API_URL}}@${ALERTMANAGER_SLACK_API_URL}@g" src/prometheus-operator/values.yaml
sed -i -e "s@{{ALERTMANAGER_SLACK_CHANNEL}}@${ALERTMANAGER_SLACK_CHANNEL}@g" src/prometheus-operator/values.yaml
sed -i -e "s@{{ALERTMANAGER_SLACK_USERNAME}}@${ALERTMANAGER_SLACK_USERNAME}@g" src/prometheus-operator/values.yaml

kubectl create -f src/prometheus-operator/dashboards # grafana dashboards
kubectl create -f src/prometheus-operator/crd
helm install --name prometheus-operator stable/prometheus-operator -f src/prometheus-operator/values.yaml --namespace monitoring
}
```

#### 2.4. Create custom servicemonitors and rules
> For scraping `etcd` metrics open 4001/4002 ports in the aws masters sg!

```sh
{
kubectl create -f src/prometheus-operator/svc # services for servicemonitors
kubectl create -f src/prometheus-operator/servicemonitors
kubectl create -f src/prometheus-operator/rule
}
```

# What's next?

### Step 6. [Logging](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step6.md)
