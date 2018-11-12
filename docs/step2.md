###### [back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step1.md)

# Step 2. Create Kubernetes cluster

### Generate cluster config
```sh
vi src/kops-cluster-tmpl/values.yaml # replace with your values
```
```sh
kops toolbox template --values src/kops-cluster-tmpl/values.yaml --template src/kops-cluster-tmpl/template.yaml --output cluster.yaml
```

### Set environment variables
```sh
export KOPS_STATE_STORE=s3://insurancetruck-k8s-ss
export DNS_ZONE=example.com
export CLUSTER_NAME=insurancetruck.$DNS_ZONE
```

### Create cluster
```sh
{
kops create -f cluster.yaml
kops update cluster $CLUSTER_NAME --yes
}
```

### Wait cluster
```sh
watch kops validate cluster
```

**Please DO NOT MOVE ON until you have validated the cluster!**

# What's next?

### Step 3. [Configure cluster](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step3.md)
