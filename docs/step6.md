###### [back](https://github.com/dimagv/k8skops/blob/master/docs/step5.md)

# Step 6. Logging (EFK)

### 1. Create logging namespace
```sh
kubectl create namespace logging
```

<!-- #### 3. Create PodSecurityPolicy
```sh
kubectl apply -f src/efk/psp.yaml
``` -->

### 2. Elasticsearch [link](https://www.elastic.co/products/elasticsearch)
`Elasticsearch` is a distributed, RESTful search and analytics engine capable of solving a growing number of use cases. As the heart of the Elastic Stack, it centrally stores your data so you can discover the expected and uncover the unexpected.

```sh
{
helm install stable/elasticsearch --name=elasticsearch --namespace=logging -f src/efk/elasticsearch/values.yaml
helm install stable/elasticsearch-exporter --name=elasticsearch-exporter --namespace=logging -f src/efk/elasticsearch-exporter/values.yaml
}
```

### 3. Fluent-bit [link](https://docs.fluentbit.io/manual/about)
`Fluent Bit` is an open source and multi-platform log forwarder tool which aims to be a generic Swiss knife for log collection and distribution.

```sh
helm install src/efk/fluent-bit/fluent-bit --name=fluent-bit --namespace=logging -f src/efk/fluent-bit/values.yaml
```

### 4. Kibana [link](https://www.elastic.co/products/kibana)
`Kibana` lets you visualize your Elasticsearch data and navigate the Elastic Stack, so you can do anything from learning why you're getting paged at 2:00 a.m. to understanding the impact rain might have on your quarterly numbers.

```sh
{
sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/efk/kibana/values.yaml
helm install stable/kibana --name=kibana --namespace=logging -f src/efk/kibana/values.yaml

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/efk/kibana/kibana-certificate.yaml
kubectl apply -f src/efk/kibana/kibana-certificate.yaml --namespace=logging
}
```

### 5. Elasticsearch-curator [link](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/about.html)
`Elasticsearch Curator` helps you curate, or manage, your Elasticsearch indices and snapshots by:
* Obtaining the full list of indices (or snapshots) from the cluster, as the actionable list
*   Iterate through a list of user-defined filters to progressively remove indices (or snapshots) from this actionable list as needed.
*   Perform various actions on the items which remain in the actionable list.

```sh
helm install stable/elasticsearch-curator --name=elasticsearch-curator --namespace=logging -f src/efk/elasticsearch-curator/values.yaml
```

# What's next?

### Step 7. [Insurancetruck App](https://github.com/dimagv/k8skops/blob/master/docs/step7.md)
