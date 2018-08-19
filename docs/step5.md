# Step 5. Monitoring

### 1. Kubernetes Dashboard [link](https://github.com/kubernetes/dashboard)
`Kubernetes Dashboard` is a general purpose, web-based UI for Kubernetes clusters. It allows users to manage applications running in the cluster and troubleshoot them, as well as manage the cluster itself.

```sh
$ DNS_ZONE=example.com
$ dashboard=src/dashboard/values.yaml
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" "${dashboard}"
$ helm install --name kubernetes-dashboard src/dashboard/kubernetes-dashboard -f $dashboard --namespace it-dev

$ cert=src/dashboard/kubernetes-dashboard-certificate.yaml
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" "${cert}"
$ kubectl apply -f $cert

check https://dashboard.example.com # replace example.com
```

### 2. [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus) ([Prometheus](https://prometheus.io/) & [Alertmanager](https://prometheus.io/docs/alerting/alertmanager/) & [Grafana](https://grafana.com/))
`kube-prometheus` is a set of Kubernetes manifests, Grafana dashboards, and Prometheus rules combined with documentation and scripts to provide easy to operate end-to-end Kubernetes cluster monitoring with Prometheus using the Prometheus Operator.

```sh
$ DNS_ZONE=example.com
$ GRAFANA_ADMIN_USER=admin # random string
$ GRAFANA_ADMIN_PASSWORD=HeUGOIQI56Drbmm6GQ # random string
$ prometheus=src/kube-prometheus/values.yaml
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" "${prometheus}"
$ sed -i -e "s@{{GRAFANA_ADMIN_USER}}@${GRAFANA_ADMIN_USER}@g" "${prometheus}"
$ sed -i -e "s@{{GRAFANA_ADMIN_PASSWORD}}@${GRAFANA_ADMIN_PASSWORD}@g" "${prometheus}"

$ kubectl create namespace monitoring
$ helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
$ helm install --name prometheus-operator --namespace=monitoring coreos/prometheus-operator
$ helm install --name kube-prometheus --namespace=monitoring -f $prometheus coreos/kube-prometheus

$ certs=src/kube-prometheus/certs
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" "${certs}/alertmanager-certificate.yaml"
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" "${certs}/grafana-certificate.yaml"
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" "${certs}/prometheus-certificate.yaml"

$ kubectl apply -f $certs

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

### Step 6. [Insurancetruck App](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step6.md)
