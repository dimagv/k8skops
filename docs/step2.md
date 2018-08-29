# Step 2. Create Kubernetes cluster

### Generate cluster config
```sh
$ vi src/kops-cluster-tmpl/values.yaml # replace with your values
$ kops toolbox template --values src/kops-cluster-tmpl/values.yaml --template src/kops-cluster-tmpl/template.yaml --output cluster.yaml
```

### Create cluster
```sh
$ export KOPS_STATE_STORE=s3://insurancetruck-k8s-ss
$ kops create -f cluster.yaml
$ kops update cluster insurancetruck.dimag.xyz --yes
```

### Wait cluster
```sh
$ watch kops validate cluster --state=s3://insurancetruck-k8s-ss
```

**Please DO NOT MOVE ON until you have validated the cluster!**

# What's next?

### Step 3. [Configure cluster](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step3.md)
