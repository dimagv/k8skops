###### [back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step8.md)

# Step 9. Additionally

<!-- ### Autoscaler [link](https://github.com/kubernetes/kops/tree/master/addons/cluster-autoscaler)

Cluster `Autoscaler` is a component that automatically adjusts the size of a Kubernetes Cluster so that all pods have a place to run and there are no unneeded nodes. 

```sh
# edit `cluster-autoscaler.sh` script
vi src/autoscaler/cluster-autoscaler.sh
```
```sh
# run `cluster-autoscaler.sh` script
./src/autoscaler/cluster-autoscaler.sh
``` -->

### Ark [link](https://github.com/heptio/ark)

Heptio `Ark` is a utility for managing disaster recovery, specifically for your Kubernetes cluster resources and persistent volumes. Brought to you by Heptio.

```sh
# create ark s3 bucket
aws s3api create-bucket --bucket insurancetruck-ark --region eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1

# edit `ark.sh` script
vi src/ark/ark.sh
# run `ark.sh` script
./src/ark/ark.sh

# install ark cli
curl -LO https://github.com/heptio/ark/releases/download/$(curl -s https://api.github.com/repos/heptio/ark/releases/latest | grep tag_name | cut -d '"' -f 4)/ark-$(curl -s https://api.github.com/repos/heptio/ark/releases/latest | grep tag_name | cut -d '"' -f 4)-linux-amd64.tar.gz | tar zx

sudo tar -xzvf ark-v0.9.3-linux-amd64.tar.gz -C /usr/local/bin

# set up a daily backup
ark schedule create <SCHEDULE NAME> --schedule "0 7 * * *"

# restore
ark restore create --from-backup <SCHEDULE NAME>-<TIMESTAMP>
# Update the Ark server Config, setting restoreOnlyMode to true. This prevents Backup objects from being created or deleted during your Restore process.
```

### Kubewatch [link](https://github.com/bitnami-labs/kubewatch)

`kubewatch` is a Kubernetes watcher that currently publishes notification to Slack. Run it in your k8s cluster, and you will get event notifications in a slack channel.

1. Create a new Bot: https://my.slack.com/services/new/bot
2. Edit the bot to customize it's name, icon and retreive the API token (it starts with xoxb-)
3. Invite the Bot into your channel by typing: /join @name_of_your_bot in the Slack message area.

```sh
CHANNEL='#it-kubewatch'
TOKEN='xoxb-...'

{
sed -i -e "s@{{CHANNEL}}@${CHANNEL}@g" src/kubewatch/values.yaml
sed -i -e "s@{{TOKEN}}@${TOKEN}@g" src/kubewatch/values.yaml
helm install --name kubewatch stable/kubewatch --values=src/kubewatch/values.yaml
}
```


<!-- ### Audit [link](https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md#audit-logging)

Kubernetes auditing provides a security-relevant chronological set of records documenting the sequence of activities that have affected system by individual users, administrators or other components of the system.

* Edit cluster config

    ```sh
    kops edit cluster insurancetruck.example.com
    ```

* Add audit config

    ```sh
    spec:
      kubeAPIServer:
        auditLogPath: /var/log/kube-apiserver-audit.log
        auditLogFormat: json
        auditLogMaxAge: 10
        auditLogMaxBackups: 1
        auditLogMaxSize: 100
        auditPolicyFile: /srv/kubernetes/audit.yaml
    ```

* Copy `audit.yaml` config to the master nodes with [fileAssets](https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md#fileassets) feature
 
    ```sh
    spec:
      fileAssets:
        - name: audit.yaml
          path: /srv/kubernetes/audit.yaml
          roles: [Master]
          content: |
            apiVersion: audit.k8s.io/v1beta1 # This is required.
            kind: Policy
            # Don't generate audit events for all requests in RequestReceived stage.
            omitStages:
              - "RequestReceived"
            rules:
              # Log pod changes at RequestResponse level
              - level: RequestResponse
                resources:
                - group: ""
                  # Resource "pods" doesn't match requests to any subresource of pods,
                  # which is consistent with the RBAC policy.
                  resources: ["pods"]
              # Log "pods/log", "pods/status" at Metadata level
              - level: Metadata
                resources:
                - group: ""
                  resources: ["pods/log", "pods/status"]

              # Don't log requests to a configmap called "controller-leader"
              - level: None
                resources:
                - group: ""
                  resources: ["configmaps"]
                  resourceNames: ["controller-leader"]

              # Don't log watch requests by the "system:kube-proxy" on endpoints or services
              - level: None
                users: ["system:kube-proxy"]
                verbs: ["watch"]
                resources:
                - group: "" # core API group
                  resources: ["endpoints", "services"]

              # Don't log authenticated requests to certain non-resource URL paths.
              - level: None
                userGroups: ["system:authenticated"]
                nonResourceURLs:
                - "/api*" # Wildcard matching.
                - "/version"

              # Log the request body of configmap changes in kube-system.
              - level: Request
                resources:
                - group: "" # core API group
                  resources: ["configmaps"]
                # This rule only applies to resources in the "kube-system" namespace.
                # The empty string "" can be used to select non-namespaced resources.
                namespaces: ["kube-system"]

              # Log configmap and secret changes in all other namespaces at the Metadata level.
              - level: Metadata
                resources:
                - group: "" # core API group
                  resources: ["secrets", "configmaps"]

              # Log all other resources in core and extensions at the Request level.
              - level: Request
                resources:
                - group: "" # core API group
                - group: "extensions" # Version of group should NOT be included.

              # A catch-all rule to log all other requests at the Metadata level.
              - level: Metadata
                # Long-running requests like watches that fall under this rule will not
                # generate an audit event in RequestReceived.
                omitStages:
                  - "RequestReceived"
    ```

* Apply changes

    ```sh
    kops update cluster insurancetruck.example.com --yes
    kops rolling-update cluster insurancetruck.example.com --yes
    ```

* Check

    ```sh
    # ssh to master
    cat /var/log/kube-apiserver-audit.log
    ``` -->