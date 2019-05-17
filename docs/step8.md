###### [back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step7.md)

# Step 8. Jenkins (CI/CD)

### 1. Create namespace

```sh
kubectl create namespace jenkins
```

### 2. Setup jenkins backup

* Create s3 bucket
    ```sh
    aws s3api create-bucket --bucket ironjab-k8s-jenkins --region us-east-1
    ```
* Create IAM role with s3 access policy 
    ```sh
    # run script
    ./src/jenkins/jenkins-backup-role.sh # roleName: k8s-jenkins-backup-$CLUSTER_NAME
    ```

### 3. Deploy jenkins

```sh
{
BACKUP_BUCKET=ironjab-k8s-jenkins
BACKUP_ROLE=k8s-jenkins-backup-$CLUSTER_NAME

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/jenkins/values.yaml
sed -i -e "s@{{BACKUP_BUCKET}}@${BACKUP_BUCKET}@g" src/jenkins/values.yaml
sed -i -e "s@{{BACKUP_ROLE}}@${BACKUP_ROLE}@g" src/jenkins/values.yaml
sed -i -e "s@{{REGION}}@${REGION}@g" src/jenkins/values.yaml
helm install --name jenkins stable/jenkins -f src/jenkins/values.yaml --namespace jenkins
}
```

### 4. Configure repos

* Create GOGS webhooks
    * it_2.71_backend:

        ```sh
        # job={{jenkins_job_name}}
        Payload URL: https://jenkins.k8s.ironjab.com/gogs-webhook/?job=it_2.71_backend
        ```
    * it_2.71_frontend:
    
        ```sh
        # job={{jenkins_job_name}}
        Payload URL: https://jenkins.k8s.ironjab.com/gogs-webhook/?job=it_2.71_frontend
        ```

* Clone repos

    ```sh
    {
    git clone http://54.152.51.78:10080/ironjab/it_2.71_backend.git

    git clone http://54.152.51.78:10080/ironjab/it_2.71_frontend.git
    }
    ```

* Add Jenkinsfile

    ```sh
    REGISTRY=532715861419.dkr.ecr.us-east-1.amazonaws.com

    {
    # it-backend
    REPO=ironjab/it_2.71_backend
    sed -i -e "s@{{REPO}}@${REPO}@g" src/jenkins/Jenkinsfile-backend
    sed -i -e "s@{{REGISTRY}}@${REGISTRY}@g" src/jenkins/Jenkinsfile-backend
    sed -i -e "s@{{NAMESPACE}}@${NAMESPACE}@g" src/jenkins/Jenkinsfile-backend
    cp src/jenkins/Jenkinsfile-backend it_2.71_backend/Jenkinsfile
    }

    {
    # it-frontend
    REPO=ironjab/it_2.71_frontend
    sed -i -e "s@{{REPO}}@${REPO}@g" src/jenkins/Jenkinsfile-frontend
    sed -i -e "s@{{REGISTRY}}@${REGISTRY}@g" src/jenkins/Jenkinsfile-frontend
    sed -i -e "s@{{NAMESPACE}}@${NAMESPACE}@g" src/jenkins/Jenkinsfile-frontend
    cp src/jenkins/Jenkinsfile-frontend it_2.71_frontend/Jenkinsfile
    }
    ```

* Configure helm charts

    ```sh
    {
    # it-backend
    cp -r src/insurancetruck/backend it_2.71_backend/helm
    cd it_2.71_backend 
    git add . && git commit -m "add ci/cd" && git push origin master
    cd ..
    }

    {
    # it-frontend
    sed -i -e "s@'process.env.API_URL'.*@'process.env.API_URL': JSON.stringify('https://backend.${NAMESPACE}.${DNS_ZONE}'),@g" it_2.71_frontend/webpack.dev.config.js

    cp -r src/insurancetruck/frontend it_2.71_frontend/helm
    cd it_2.71_frontend
    git add . && git commit -m "add ci/cd" && git push origin master
    cd ..
    }
    ```

### 5. Configure jenkins

1. Sign In [link](https://jenkins.k8s.ironjab.com/login)
    * Username: `admin`
    * Password: `kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode`
2. Create credentials [link](https://jenkins.k8s.ironjab.com/credentials/store/system/domain/_/newCredentials)

    ```sh
    Kind: SSH Username with private key
    Username: gogs
    Private Key: paste gogs private key directly
    ```

    ```sh
    Kind: AWS Credentials
    ID: ecr-registry
    # create IAM user for jenkins only with ECR access for security purpose
    Access Key ID: ***
    Secret Access Key: ***
    ```
3. Configure kubernetes plugin  [link](https://jenkins.k8s.ironjab.com/configure)
    * Create `Kubernetes Pod Template` by hand:

        ```sh
        podTemplate(
            label: 'insurancetruck', 
            inheritFrom: 'default',
            serviceAccount: 'jenkins',
            containers: [
                containerTemplate(
                    name: 'docker', 
                    image: 'docker:18.06.3',
                    ttyEnabled: true,
                    command: 'cat'
                ),
                containerTemplate(
                    name: 'helm', 
                    image: 'lachlanevenson/k8s-helm:v2.13.1',
                    ttyEnabled: true,
                    command: 'cat'
                )
            ],
            volumes: [
                hostPathVolume(
                    hostPath: '/var/run/docker.sock',
                    mountPath: '/var/run/docker.sock'
                )
            ]
        )
        ```
        
    * Timeout in seconds for Jenkins connection: 600
    * Raw yaml for the Pod:

        ```sh
            apiVersion: v1
            kind: Pod
            metadata:
            labels:
                jenkins: slave
                jenkins/insurancetruck: "true"
            spec:
            nodeSelector:
                kops.k8s.io/instancegroup: nodes-jenkins-spot
            tolerations:
            - key: dedicated
                operator: Equal
                value: jenkins
                effect: NoSchedule
            affinity:
                podAntiAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                - labelSelector:
                    matchExpressions:
                    - key: jenkins
                        operator: In
                        values:
                        - slave
                    - key: jenkins/insurancetruck
                        operator: In
                        values:
                        - "true"
                    topologyKey: "kubernetes.io/hostname"
        ```

4. Configure slack plugin
    * Create incoming webhook [link](https://api.slack.com/incoming-webhooks)

        ```sh
        # Webhook URL
        https://hooks.slack.com/services/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
        ```

    * Global Slack Notifier Settings:

        ```sh
        Slack compatible app URL: https://hooks.slack.com/services/
        Integration Token Credential ID:
            Kind: Secret text
            ID: slack
            Secret: T0MRN6VZL/BHQT9AHNG/qsr6rpEm8SNm8tl6KG7rjfn9
        Channel or Slack ID: "#ironjab-jenkins"
        ```

5. Create jobs [link](https://jenkins.k8s.ironjab.com/view/all/newJob)

    ```sh
    Name: it_2.71_backend
    Type: Multibranch Pipeline
    ```

    ```sh
    Name: it_2.71_frontend
    Type: Multibranch Pipeline
    ```

6. Configure jobs
    * Add branch source:
    
        ```sh
        Type: Git
        Project Repository: ssh://git@54.152.51.78:10022/ironjab/it_2.71_backend.git
                            ssh://git@54.152.51.78:10022/ironjab/it_2.71_frontend.git
        Credentials: gogs
        ```

# What's next?

### Step 9. [Additionally](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step9.md)