# Step 2. Create Kubernetes cluster

### Get default VPC ID 
```sh
$ aws ec2 describe-vpcs --filters "Name=isDefault, Values=true" | jq .Vpcs[0].VpcId
# "vpc-2d885a46"
```

### Create cluster configuration
```sh
# Note: replace values
# --name must be {clusterName}.{route53hostedZone} => {insurancetruck}.{example.com} => insurancetruck.example.com
# --vpc default vpc id
# --dns-zone route53 hosted zone name
$ kops create cluster --cloud=aws --authorization RBAC --image=ami-7c412f13 --name=insurancetruck.example.com --state=s3://insurancetruck-k8s-ss --zones=eu-central-1a,eu-central-1b,eu-central-1c --dns-zone=example.com --node-count=2 --node-volume-size=50 --node-size=t2.medium --master-size=t2.medium --master-volume-size=50 --ssh-public-key=./id_rsa.pub --vpc=vpc-2d885a46 --out=. --target=terraform
```

### Customize Cluster Configuration

> Note: The next command will open the cluter config in your default editor, please save and exit the file once you're done…
```sh
$ kops edit cluster insurancetruck.example.com --state=s3://insurancetruck-k8s-ss
```

Fix broken subnet cidr in the default vpc (kops issue)
```sh
spec: 
  subnets: 
    cidr: 172.31.32.0/19 => 172.31.128.0/19 (or any valid)
```

Add this to the config
```sh
# Note: replace example.com with your dns zone
spec:
  kubeAPIServer:
    # oidc config
    oidcIssuerURL: https://dex.example.com
    oidcClientID: insurancetruck-app
    oidcUsernameClaim: name
    # pv auto resizing feature
    featureGates:
      ExpandPersistentVolumes: "true"
  kubeControllerManager:
    # pv auto resizing feature
    featureGates:
      ExpandPersistentVolumes: "true"
  # external-dns policy
  additionalPolicies:
    node: |
      [
        {
          "Effect": "Allow",
          "Action": [
            "route53:ChangeResourceRecordSets"
          ],
          "Resource": [
            "arn:aws:route53:::hostedzone/*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
```

```sh
$ kops update cluster insurancetruck.example.com --state=s3://insurancetruck-k8s-ss  --yes --out=. --target=terraform
```

### Build the Cluster
```sh
$ terraform init
$ terraform apply
```
```sh
# wait for the cluster
$ watch kops validate cluster --state=s3://insurancetruck-k8s-ss
```

**Please DO NOT MOVE ON until you have validated the cluster!**

## Demo

<p align="center">
  <a target="_blank" href="https://asciinema.org/a/196849">
  <img src="https://asciinema.org/a/196849.png" width="885"></image>
  </a>
</p>

# What's next?

### Step 3. [Configure cluster](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step3.md)
