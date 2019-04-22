###### [back](http://54.152.51.78:10080/ironjab/it-k8s)

# Step 1. Setup your environment

### Install [docker](https://docs.docker.com/install/)
Docker is an open platform for developers and sysadmins to build, ship, and run distributed applications, whether on laptops, data center VMs, or the cloud.

```sh
{
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update && sudo apt-get install -y docker-ce
sudo groupadd docker
sudo usermod -aG docker $USER
}
# Log out and log back in so that your group membership is re-evaluated.
```

### Install [kubectl](https://kubernetes.io/docs/reference/kubectl/overview)
> Kubernetes command-line tool, `kubectl`, to deploy and manage applications on Kubernetes. Using `kubectl`, you can inspect cluster resources; create, delete, and update components.
```sh
{
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
}
```

### Install [helm](https://github.com/helm/helm) 
> `Helm` helps you manage Kubernetes applications — Helm Charts helps you define, install, and upgrade even the most complex Kubernetes application.
> Charts are easy to create, version, share, and publish — so start using `Helm` and stop the copy-and-paste madness.
```sh
{
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
}
```

### Install [kops](https://github.com/kubernetes/kops) 
> The easiest way to get a production grade Kubernetes cluster up and running. 
> `kops` helps you create, destroy, upgrade and maintain production-grade, highly available, Kubernetes clusters from the command line.
> AWS (Amazon Web Services) is currently officially supported, with GCE in beta support , and VMware vSphere in alpha, and other platforms planned.
```sh
{
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops
}
```

### Install [Pip](https://pip.pypa.io/en/stable/installing/)
If you don't have pip, install pip with the script provided by the Python Packaging Authority.

#### To install pip
1. Download the installation script from pypa.io:
    ```sh
    curl -O https://bootstrap.pypa.io/get-pip.py
    # The script downloads and installs the latest version of pip and another required package named setuptools.
    ```

2. Run the script with Python:
    ```sh
    python get-pip.py --user
    ```

3. Add the executable path to your PATH variable: ~/.local/bin
    To modify your PATH variable (Linux, macOS, or Unix)
    * Find your shell's profile script in your user folder. If you are not sure which shell you have, run echo $SHELL.
        ```sh
        ls -a ~
        # .  ..  .bash_history  .bash_logout  .bashrc  .cache  .gnupg  .local  .profile  .ssh
        ```

        * Bash – .bash_profile, .profile, or .bash_login.
        * Zsh – .zshrc
        * Tcsh – .tcshrc, .cshrc or .login.

    * Add an export command to your profile script.
        ```sh
        export PATH=~/.local/bin:$PATH
        # This command adds a path, ~/.local/bin in this example, to the current PATH variable.
        ```

    * Load the profile into your current session.
        ```sh
        source ~/.bashrc
        ```

4. Verify that pip is installed correctly.
    ```sh
    pip --version
    # pip 18.0 from /home/ubuntu/.local/lib/python2.7/site-packages/pip (python 2.7)
    ```

### Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html) with [Pip](https://pip.pypa.io/en/stable/installing/)

```sh
pip install awscli --upgrade --user
```

Verify that the AWS CLI installed correctly.
```sh
aws --version
# aws-cli/1.16.21 Python/2.7.15rc1 Linux/4.15.0-1021-aws botocore/1.12.11
```

### Set AWS credentials. 
>The `kops` user will require the following IAM permissions to function properly:
* AmazonEC2FullAccess
* AmazonRoute53FullAccess
* AmazonS3FullAccess
* IAMFullAccess
* AmazonVPCFullAccess

```sh
# configure the aws client to use your IAM user
aws configure 

# because "aws configure" doesn't export these vars for kops to use, we export them now
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
```

### Generate SSH key.
```sh
ssh-keygen -t rsa -N "" -f id_rsa
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
ID=$(uuidgen) && aws route53 create-hosted-zone --name example.com --caller-reference $ID
```
* Get NS record of the created Zone

```bash
# get zone Id
aws route53 list-hosted-zones | jq '.HostedZones[] | select(.Name=="example.com.") | .Id'
Output:
"/hostedzone/Z3GF3B4D6NF0R2"

# get zone NS record
aws route53 list-resource-record-sets --hosted-zone-id /hostedzone/Z3GF3B4D6NF0R2 --query "ResourceRecordSets[?Type == 'NS'].ResourceRecords" --output=text
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
aws s3api create-bucket --bucket ironjab-k8s-ss --region us-east-1
# enable s3 bucket versioning
aws s3api put-bucket-versioning --bucket ironjab-k8s-ss --versioning-configuration Status=Enabled
```

# What's next?

### Step 2. [Create Kubernetes cluster](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step2.md)