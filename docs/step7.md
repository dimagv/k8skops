###### [back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step6.md)

# Step 7. Insurancetruck App

### 1. Set environment variables

```sh
export NAMESPACE=insurancetruck-dev
```
> Note: If you want to change namespace name change also RBAC `src/rbac/insurancetruck-dev-admins.yaml`

### 2. Create namespace
```sh
kubectl create namespace $NAMESPACE
```

### 3. Setup helm charts repo [link](https://github.com/hypnoglow/helm-s3)

#### 3.1. Create AWS S3 bucket

```sh
aws s3api create-bucket --bucket ironjab-k8s-charts --region us-east-1
```

#### 3.2. Setup repo

```sh
{
helm plugin install https://github.com/hypnoglow/helm-s3.git
helm s3 init s3://ironjab-k8s-charts
helm repo add ironjab s3://ironjab-k8s-charts
}
```

### 4. Setup `it_aspire` [link](http://54.152.51.78:10080/ironjab/it_aspire)

#### 4.1. Create AWS ECR repo

```sh
aws ecr create-repository --repository-name ironjab/it_aspire

Output:
{
    "repository": {
        "registryId": "532715861419", 
        "repositoryName": "ironjab/it_aspire", 
        "repositoryArn": "arn:aws:ecr:us-east-1:532715861419:repository/ironjab/it_aspire", 
        "createdAt": 1554501222.0, 
        "repositoryUri": "532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_aspire"
    }
}

aws ecr put-lifecycle-policy --repository-name ironjab/it_aspire --lifecycle-policy-text file://src/insurancetruck/aspire/ecr-lifecycle-policy.json
```

#### 4.2. Build docker image

```sh
git clone http://54.152.51.78:10080/ironjab/it_aspire.git

docker build -t 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_aspire:latest it_aspire
```

#### 4.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$(aws ecr get-login --no-include-email --region eu-central-1)

docker push 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_aspire:latest
```

#### 4.4. Push helm chart

```sh
helm package -d src/insurancetruck/aspire src/insurancetruck/aspire/aspire
helm s3 push src/insurancetruck/aspire/aspire-0.1.0.tgz ironjab
```

### 5. Setup `service_vin` [link](http://54.152.51.78:10080/ironjab/service_vin)

#### 5.1. Create AWS ECR repo

```sh
aws ecr create-repository --repository-name ironjab/service_vin

Output:
{
    "repository": {
        "registryId": "532715861419", 
        "repositoryName": "ironjab/service_vin", 
        "repositoryArn": "arn:aws:ecr:us-east-1:532715861419:repository/ironjab/service_vin", 
        "createdAt": 1554486620.0, 
        "repositoryUri": "532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/service_vin"
    }
}

aws ecr put-lifecycle-policy --repository-name ironjab/service_vin --lifecycle-policy-text file://src/insurancetruck/vin/ecr-lifecycle-policy.json
```

#### 5.2. Build docker image

```sh
git clone http://54.152.51.78:10080/ironjab/service_vin.git

docker build -t 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/service_vin:latest service_vin
```

#### 5.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$(aws ecr get-login --no-include-email --region eu-central-1)

docker push 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/service_vin:latest
```

#### 5.4. Push helm chart

```sh
helm package -d src/insurancetruck/vin src/insurancetruck/vin/vin
helm s3 push src/insurancetruck/vin/vin-0.1.0.tgz ironjab
```


### 6. Deploy `it_2.71_backend` [link](http://54.152.51.78:10080/ironjab/it_2.71_backend)

#### 6.1. Create AWS ECR repo

```sh
aws ecr create-repository --repository-name ironjab/it_2.71_backend

Output:
{
    "repository": {
        "registryId": "532715861419", 
        "repositoryName": "ironjab/it_2.71_backend", 
        "repositoryArn": "arn:aws:ecr:us-east-1:532715861419:repository/ironjab/it_2.71_backend", 
        "createdAt": 1554458517.0, 
        "repositoryUri": "532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_backend"
    }
}

aws ecr put-lifecycle-policy --repository-name ironjab/it_2.71_backend --lifecycle-policy-text file://src/insurancetruck/backend/ecr-lifecycle-policy.json
```

#### 6.2. Build docker image

```sh
git clone http://54.152.51.78:10080/ironjab/it_2.71_backend.git

docker build -t 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_backend:latest it_2.71_backend
```

#### 6.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$(aws ecr get-login --no-include-email --region us-east-1)

docker push 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_backend:latest
```

#### 6.4. Deploy helm chart

```sh
{
BACKEND_REPO=532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_backend
VIN_REPO=532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/service_vin
ASPIRE_REPO=532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_aspire
MYSQL_ROOT_PASS=dev2016
MYSQL_USER=dev
MYSQL_PASS=dev2016
MYSQL_DB=dev_insurance
REDIS_PASS=dev2016
SMTP_NAME=AKIAI6HQ75CCY3NW7KFQ
SMTP_PASS=Aj5Zi7yFWBYJF/td/D+C7XThyR5duFZkFXcHuTwGpdsN
PUSH_KEY=00D95EA481CB43C19E935925F5064FB49F281663983D47199DC6337488577F30FAC5B3CBCB1F45268080146824BADD0B
VIN_NAME=perealuc
VIN_PASS="Dec2014!"

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{NAMESPACE}}@${NAMESPACE}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{BACKEND_REPO}}@${BACKEND_REPO}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{VIN_REPO}}@${VIN_REPO}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{ASPIRE_REPO}}@${ASPIRE_REPO}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{MYSQL_ROOT_PASS}}@${MYSQL_ROOT_PASS}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{MYSQL_USER}}@${MYSQL_USER}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{MYSQL_PASS}}@${MYSQL_PASS}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{MYSQL_DB}}@${MYSQL_DB}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{REDIS_PASS}}@${REDIS_PASS}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{SMTP_NAME}}@${SMTP_NAME}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{SMTP_PASS}}@${SMTP_PASS}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{PUSH_KEY}}@${PUSH_KEY}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{VIN_NAME}}@${VIN_NAME}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{VIN_PASS}}@${VIN_PASS}@g" src/insurancetruck/backend/values.yaml

helm install --name backend-$NAMESPACE --dep-up -f src/insurancetruck/backend/values.yaml src/insurancetruck/backend/backend --namespace=$NAMESPACE
}
```

#### 6.5. Import Mysql DB

```sh
kubectl run mysql-client --image=mysql:5.7 -i --rm --restart=Never --namespace $NAMESPACE -- mysql -h backend-$NAMESPACE-mysql -uroot -pdev2016 dev_insurance < src/insurancetruck/mysql/dev/dev_insurance.sql

# test
kubectl run mysql-client --image=mysql:5.7 -it --rm --restart=Never --namespace $NAMESPACE -- mysql -h backend-$NAMESPACE-mysql -uroot -pdev2016 dev_insurance -e 'SHOW TABLES;'
```

### 7. Deploy `it_2.71_frontend` [link](http://54.152.51.78:10080/ironjab/it_2.71_frontend)

#### 7.1. Create AWS ECR repo
```sh
aws ecr create-repository --repository-name ironjab/it_2.71_frontend

Output:
{
    "repository": {
        "registryId": "532715861419", 
        "repositoryName": "ironjab/it_2.71_frontend", 
        "repositoryArn": "arn:aws:ecr:us-east-1:532715861419:repository/ironjab/it_2.71_frontend", 
        "createdAt": 1554467399.0, 
        "repositoryUri": "532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_frontend"
    }
}

aws ecr put-lifecycle-policy --repository-name ironjab/it_2.71_frontend --lifecycle-policy-text file://src/insurancetruck/frontend/ecr-lifecycle-policy.json
```

#### 7.2. Build docker image

```sh
git clone http://54.152.51.78:10080/ironjab/it_2.71_frontend.git

sed -i -e "s@'process.env.API_URL'.*@'process.env.API_URL': JSON.stringify('https://backend.${NAMESPACE}.${DNS_ZONE}'),@g" it_2.71_frontend/webpack.dev.config.js

docker build -t 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_frontend:latest it_2.71_frontend
```

#### 7.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$(aws ecr get-login --no-include-email --region eu-central-1)

docker push 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_frontend:latest
```

#### 7.4. Deploy helm chart

```sh
{
REPO=532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_frontend

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/insurancetruck/frontend/values.yaml
sed -i -e "s@{{NAMESPACE}}@${NAMESPACE}@g" src/insurancetruck/frontend/values.yaml
sed -i -e "s@{{REPO}}@${REPO}@g" src/insurancetruck/frontend/values.yaml

helm install --name frontend-$NAMESPACE -f src/insurancetruck/frontend/values.yaml src/insurancetruck/frontend/frontend --namespace=$NAMESPACE
}
```

# What's next?

### Step 8. [Jenkins (CI/CD)](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step8.md)