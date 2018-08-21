# Step 8. Additionally

### Autoscaler [link](https://github.com/kubernetes/kops/tree/master/addons/cluster-autoscaler)

* Edit `cluster-autoscaler.sh` script

```sh
$ vi src/autoscaler/cluster-autoscaler.sh
```

* Run `cluster-autoscaler.sh` script

```sh
$ ./src/autoscaler/cluster-autoscaler.sh
```

### Audit [link](https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md#audit-logging)

* Edit cluster config

```sh
$ kops edit cluster insurancetruck.example.com --state=s3://insurancetruck-k8s-ss
```

* Add audit config

```sh
spec:
  kubeAPIServer:
    auditLogPath: /var/log/kube-apiserver-audit.log
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
$ kops update cluster insurancetruck.example.com --state=s3://insurancetruck-k8s-ss  --yes --out=. --target=terraform
$ terraform apply
$ kops rolling-update cluster insurancetruck.example.com --state=s3://insurancetruck-k8s-ss --yes
```

* Check

1. ssh to master
2. cat /var/log/kube-apiserver-audit.log