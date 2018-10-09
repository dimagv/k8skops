###### [Back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step4.md)

# Step 5. Monitoring

### 1. Kubernetes Dashboard [link](https://github.com/kubernetes/dashboard)
`Kubernetes Dashboard` is a general purpose, web-based UI for Kubernetes clusters. It allows users to manage applications running in the cluster and troubleshoot them, as well as manage the cluster itself.

```sh
{
sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/dashboard/values.yaml
helm install --name kubernetes-dashboard src/dashboard/kubernetes-dashboard -f src/dashboard/values.yaml --namespace $NAMESPACE

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/dashboard/kubernetes-dashboard-certificate.yaml
kubectl apply -f src/dashboard/kubernetes-dashboard-certificate.yaml --namespace=$NAMESPACE
}

check https://dashboard.example.com # replace example.com
```

### 2. [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus) ([Prometheus](https://prometheus.io/) & [Alertmanager](https://prometheus.io/docs/alerting/alertmanager/) & [Grafana](https://grafana.com/))
`kube-prometheus` is a set of Kubernetes manifests, Grafana dashboards, and Prometheus rules combined with documentation and scripts to provide easy to operate end-to-end Kubernetes cluster monitoring with Prometheus using the Prometheus Operator.

```sh
ALERTMANAGER_SLACK_API_URL=https://hooks.slack.com/services/... # https://api.slack.com/apps
ALERTMANAGER_SLACK_CHANNEL=alertmanager
ALERTMANAGER_SLACK_USERNAME=dimag
GRAFANA_ADMIN_USER=admin # random string
GRAFANA_ADMIN_PASSWORD=HeUGOIQI56Drbmm6GQ # random string

{
kubectl create namespace monitoring
helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
helm install --name prometheus-operator --namespace=monitoring coreos/prometheus-operator

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/kube-prometheus/values.yaml
sed -i -e "s@{{GRAFANA_ADMIN_USER}}@${GRAFANA_ADMIN_USER}@g" src/kube-prometheus/values.yaml
sed -i -e "s@{{GRAFANA_ADMIN_PASSWORD}}@${GRAFANA_ADMIN_PASSWORD}@g" src/kube-prometheus/values.yaml
sed -i -e "s@{{ALERTMANAGER_SLACK_API_URL}}@${ALERTMANAGER_SLACK_API_URL}@g" src/kube-prometheus/values.yaml
sed -i -e "s@{{ALERTMANAGER_SLACK_CHANNEL}}@${ALERTMANAGER_SLACK_CHANNEL}@g" src/kube-prometheus/values.yaml
sed -i -e "s@{{ALERTMANAGER_SLACK_USERNAME}}@${ALERTMANAGER_SLACK_USERNAME}@g" src/kube-prometheus/values.yaml
helm install --name kube-prometheus --namespace=monitoring -f src/kube-prometheus/values.yaml coreos/kube-prometheus

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/kube-prometheus/certs/alertmanager-certificate.yaml
sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/kube-prometheus/certs/grafana-certificate.yaml
sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/kube-prometheus/certs/prometheus-certificate.yaml
kubectl apply -f src/kube-prometheus/certs

# service-monitors
kubectl apply -f src/kube-prometheus/service-monitors
}

check https://alertmanager.example.com # replace example.com
check https://grafana.example.com # replace example.com
check https://prometheus.example.com # replace example.com
```

## Demo

<p align="center">
  <a target="_blank" href="https://asciinema.org/a/197035">
  <img src="https://asciinema.org/a/197035.png" width="885"></image>
  </a>
</p>

# What's next?

### Step 6. [Logging](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step6.md)
