###### [back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step8.md)

# Step 9. Additionally

### Velero [link](https://github.com/heptio/velero)

Backup and migrate Kubernetes applications and their persistent volumes

```sh
# create velero s3 bucket
aws s3api create-bucket --bucket ironjab-k8s-velero --region us-east-1

# edit `velero.sh` script
vi src/velero/velero.sh
# run `velero.sh` script
./src/velero/velero.sh

# install velero cli
curl -LO https://github.com/heptio/velero/releases/download/$(curl -s https://api.github.com/repos/heptio/velero/releases/latest | grep tag_name | cut -d '"' -f 4)/velero-$(curl -s https://api.github.com/repos/heptio/velero/releases/latest | grep tag_name | cut -d '"' -f 4)-linux-amd64.tar.gz

sudo tar -xzvf velero-$(curl -s https://api.github.com/repos/heptio/velero/releases/latest | grep tag_name | cut -d '"' -f 4)-linux-amd64.tar.gz velero -C /usr/local/bin

# set up a daily backup
velero schedule create $CLUSTER_NAME --schedule "0 7 * * *"

# restore
velero restore create --from-backup <SCHEDULE NAME>-<TIMESTAMP>
# Update the Velero server Config, setting restoreOnlyMode to true. This prevents Backup objects from being created or deleted during your Restore process.
```

### Kubewatch [link](https://github.com/bitnami-labs/kubewatch)

`kubewatch` is a Kubernetes watcher that currently publishes notification to Slack. Run it in your k8s cluster, and you will get event notifications in a slack channel.

1. Create a new Bot: https://my.slack.com/services/new/bot
2. Edit the bot to customize it's name, icon and retreive the API token (it starts with xoxb-)
3. Invite the Bot into your channel by typing: /invite @name_of_your_bot in the Slack message area.

```sh
CHANNEL='#ironjab-kubewatch'
TOKEN='xoxb-...'

{
sed -i -e "s@{{CHANNEL}}@${CHANNEL}@g" src/kubewatch/values.yaml
sed -i -e "s@{{TOKEN}}@${TOKEN}@g" src/kubewatch/values.yaml
helm install --name kubewatch stable/kubewatch --values=src/kubewatch/values.yaml --namespace kube-system
}
```