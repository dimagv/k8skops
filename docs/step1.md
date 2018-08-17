# Step 1. Setup your environment

### Install [kubectl](https://kubernetes.io/docs/reference/kubectl/overview)
> Kubernetes command-line tool, `kubectl`, to deploy and manage applications on Kubernetes. Using `kubectl`, you can inspect cluster resources; create, delete, and update components.
```sh
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
```

### Install [helm](https://github.com/helm/helm) 
> `Helm` helps you manage Kubernetes applications — Helm Charts helps you define, install, and upgrade even the most complex Kubernetes application.
> Charts are easy to create, version, share, and publish — so start using `Helm` and stop the copy-and-paste madness.
```sh
$ curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```

### Install [terraform](https://github.com/hashicorp/terraform) 
> `Terraform` is a tool for building, changing, and versioning infrastructure safely and efficiently. 
> `Terraform` can manage existing and popular service providers as well as custom in-house solutions.
```sh
$ wget https://releases.hashicorp.com/terraform/$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | cut -d 'v' -f 2)/terraform_$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | cut -d 'v' -f 2)_linux_amd64.zip
$ unzip terraform_0.11.1_linux_amd64.zip
$ sudo mv terraform /usr/local/bin/
```

### Install [kops](https://github.com/kubernetes/kops) 
> The easiest way to get a production grade Kubernetes cluster up and running. 
> `kops` helps you create, destroy, upgrade and maintain production-grade, highly available, Kubernetes clusters from the command line.
> AWS (Amazon Web Services) is currently officially supported, with GCE in beta support , and VMware vSphere in alpha, and other platforms planned.
```sh
$ curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
$ chmod +x kops-linux-amd64
$ sudo mv kops-linux-amd64 /usr/local/bin/kops
```

### Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html) with Pip
```sh
$ pip install awscli --upgrade --user
```

### Generate SSH key.
```sh
$ ssh-keygen -t rsa -N "" -f id_rsa
```

### Set AWS credentials.
>The `kops` user will require the following IAM permissions to function properly:
* AmazonEC2FullAccess
* AmazonRoute53FullAccess
* AmazonS3FullAccess
* IAMFullAccess
* AmazonVPCFullAccess

```sh
$ cp credentials.example credentials
$ vi credentials

OR

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

## Configure DNS ([Route53 hosted zone](https://console.aws.amazon.com/route53/home?region=eu-central-1#hosted-zones:))

In order to build a Kubernetes cluster with `kops`, we need to prepare
somewhere to build the required DNS records.  There are three scenarios
below and you should choose the one that most closely matches your AWS
situation.

### Scenario 1a: A Domain purchased/hosted via AWS

If you bought your domain with AWS, then you should already have a hosted zone
in Route53.  If you plan to use this domain then no more work is needed.

### Scenario 1b: A subdomain under a domain purchased/hosted via AWS

In this scenario you want to contain all kubernetes records under a subdomain
of a domain you host in Route53.  This requires creating a second hosted zone
in route53, and then setting up route delegation to the new zone.

In this example you own `example.com` and your records for Kubernetes would
look like `etcd-us-east-1c.internal.clustername.subdomain.example.com`

This is copying the NS servers of your **SUBDOMAIN** up to the **PARENT**
domain in Route53.  To do this you should:

* Create the subdomain, and note your **SUBDOMAIN** name servers (If you have
  already done this you can also [get the values](ns.md))

```bash
# Note: This example assumes you have jq installed locally.
ID=$(uuidgen) && aws route53 create-hosted-zone --name subdomain.example.com --caller-reference $ID | \
    jq .DelegationSet.NameServers
```

* Note your **PARENT** hosted zone id

```bash
# Note: This example assumes you have jq installed locally.
aws route53 list-hosted-zones | jq '.HostedZones[] | select(.Name=="example.com.") | .Id'
```

* Create a new JSON file with your values (`subdomain.json`)

Note: The NS values here are for the **SUBDOMAIN**

```
{
  "Comment": "Create a subdomain NS record in the parent domain",
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "subdomain.example.com",
        "Type": "NS",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "ns-1.awsdns-1.co.uk"
          },
          {
            "Value": "ns-2.awsdns-2.org"
          },
          {
            "Value": "ns-3.awsdns-3.com"
          },
          {
            "Value": "ns-4.awsdns-4.net"
          }
        ]
      }
    }
  ]
}
```

* Apply the **SUBDOMAIN** NS records to the **PARENT** hosted zone.

```
aws route53 change-resource-record-sets \
 --hosted-zone-id <parent-zone-id> \
 --change-batch file://subdomain.json
```

Now traffic to `*.subdomain.example.com` will be routed to the correct subdomain hosted zone in Route53.

### Scenario 2: Setting up Route53 for a domain purchased with another registrar

If you bought your domain elsewhere, and would like to dedicate the entire domain to AWS you should follow the guide [here](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-to-route-53.html)

### Scenario 3: Subdomain for clusters in route53, leaving the domain at another registrar

If you bought your domain elsewhere, but **only want to use a subdomain in AWS
Route53** you must modify your registrar's NS (NameServer) records.  We'll create
a hosted zone in Route53, and then migrate the subdomain's NS records to your
other registrar.

You might need to grab [jq](https://github.com/stedolan/jq/wiki/Installation)
for some of these instructions.

* Create the subdomain, and note your name servers (If you have already done
  this you can also [get the values](ns.md))

```bash
ID=$(uuidgen) && aws route53 create-hosted-zone --name subdomain.example.com --caller-reference $ID | jq .DelegationSet.NameServers
```

* You will now go to your registrar's page and log in. You will need to create a
  new **SUBDOMAIN**, and use the 4 NS records received from the above command for the new
  **SUBDOMAIN**. This **MUST** be done in order to use your cluster. Do **NOT**
  change your top level NS record, or you might take your site offline.

* Information on adding NS records with
  [Godaddy.com](https://www.godaddy.com/help/set-custom-nameservers-for-domains-registered-with-godaddy-12317)
* Information on adding NS records with [Google Cloud
  Platform](https://cloud.google.com/dns/update-name-servers)

## **Example**. Configure DNS with `Scenario 2` and [`Name.com`](https://name.com) registrar

* Create AWS Route53 Hosted Zone
```bash
$ ID=$(uuidgen) && aws route53 create-hosted-zone --name example.com --caller-reference $ID
```
* Get NS record of the created Zone
```bash
# get zone Id
$ aws route53 list-hosted-zones | jq '.HostedZones[] | select(.Name=="example.com.") | .Id'
Output:
"/hostedzone/Z3GF3B4D6NF0R2"

# get zone NS record
$ aws route53 list-resource-record-sets --hosted-zone-id /hostedzone/Z3GF3B4D6NF0R2 --query "ResourceRecordSets[?Type == 'NS'].ResourceRecords" --output=text
Output:
ns-1720.awsdns-23.co.uk.                          
ns-833.awsdns-40.net.                             
ns-249.awsdns-31.com.                             
ns-1193.awsdns-21.org.
```
* [Buy domain](https://www.name.com/domain/search/example.com)
* Go to the [domain nameservers page](https://www.name.com/account/domain/details/example.com#nameservers) 
* Replace nameservers with route53 hosted-zone nameservers

## Testing your DNS setup

You should now able to dig your domain (or subdomain) and see the AWS Name
Servers on the other end.

```bash
dig ns example.com
```

Should return something similar to:

```
;; ANSWER SECTION:
example.com.        86400  IN  NS  ns-1720.awsdns-23.co.uk.
example.com.        86400  IN  NS  ns-833.awsdns-40.net.
example.com.        86400  IN  NS  ns-249.awsdns-31.com.
example.com.        86400  IN  NS  ns-1193.awsdns-21.org.
```

This is a critical component of setting up clusters. If you are experiencing
problems with the Kubernetes API not coming up, chances are something is wrong
with the cluster's DNS.

**Please DO NOT MOVE ON until you have validated your NS records!**

## Cluster State storage

Kops s3 bucket
```sh
# create s3 bucket
$ aws s3api create-bucket --bucket insurancetruck-k8s-ss --region eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1
# enable s3 bucket versioning
$ aws s3api put-bucket-versioning --bucket insurancetruck-k8s-ss --versioning-configuration Status=Enabled
```

Terraform s3 bucket
```sh
# create s3 bucket
$ aws s3api create-bucket --bucket insurancetruck-terraform-ss --region eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1
# enable s3 bucket versioning
$ aws s3api put-bucket-versioning --bucket insurancetruck-terraform-ss --versioning-configuration Status=Enabled
```

Terraform dynamodb table (for state locking and consistency) 
```sh
# create dynamodb table
$ aws dynamodb create-table --table-name insurancetruck-terraform-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

# What's next?

### Step 2. [Create Kubernetes cluster](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step2.md)