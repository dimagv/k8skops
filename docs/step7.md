###### [back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step6.md)

# Step 7. Insurancetruck App

### 1. Mysql [link](https://www.mysql.com/)

```sh
{
MYSQL_ROOT_PASS=dev2016
MYSQL_USER=dev
MYSQL_PASS=dev2016
MYSQL_DB=dev_insurance

sed -i -e "s@{{MYSQL_ROOT_PASS}}@${MYSQL_ROOT_PASS}@g" src/insurancetruck/mysql/dev/values.yaml
sed -i -e "s@{{MYSQL_USER}}@${MYSQL_USER}@g" src/insurancetruck/mysql/dev/values.yaml
sed -i -e "s@{{MYSQL_PASS}}@${MYSQL_PASS}@g" src/insurancetruck/mysql/dev/values.yaml
sed -i -e "s@{{MYSQL_DB}}@${MYSQL_DB}@g" src/insurancetruck/mysql/dev/values.yaml

helm install --name mysql-$NAMESPACE -f src/insurancetruck/mysql/dev/values.yaml stable/mysql --namespace $NAMESPACE
}
```

### 2. Import Mysql DB

```sh
kubectl run mysql-client --image=mysql:5.7 -i --rm --restart=Never --namespace $NAMESPACE -- mysql -h mysql-$NAMESPACE -uroot -pdev2016 dev_insurance < src/insurancetruck/mysql/dev/dev_insurance.sql

# test
kubectl run mysql-client --image=mysql:5.7 -it --rm --restart=Never --namespace $NAMESPACE -- mysql -h mysql-$NAMESPACE -uroot -pdev2016 dev_insurance -e 'SHOW TABLES;'
```

### 3. phpMyAdmin [link](https://www.phpmyadmin.net/)

```sh
{
sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/insurancetruck/pma/dev/values.yaml
sed -i -e "s@{{NAMESPACE}}@${NAMESPACE}@g" src/insurancetruck/pma/dev/values.yaml
helm install --name phpmyadmin-$NAMESPACE -f src/insurancetruck/pma/dev/values.yaml stable/phpmyadmin --namespace $NAMESPACE
}
```

### 4. Deploy `it_2.71_backend` [link](http://54.152.51.78:10080/ironjab/it_2.71_backend)

#### 4.1. Create AWS ECR repo

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

aws ecr put-lifecycle-policy --repository-name ironjab/it_2.71_backend --lifecycle-policy-text file://src/insurancetruck/ecr-lifecycle-policy/policy.json
```

#### 4.2. Build docker image

```sh
git clone http://54.152.51.78:10080/ironjab/it_2.71_backend.git

docker build -t 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_backend:latest it_2.71_backend
```

#### 4.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$(aws ecr get-login --no-include-email --region us-east-1)

docker push 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_backend:latest
```

#### 4.4. Deploy helm chart

```sh
{
REPO=532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_backend
MYSQL_HOST=mysql-$NAMESPACE
MYSQL_ROOT_PASS=dev2016
MYSQL_USER=dev
MYSQL_PASS=dev2016
MYSQL_DB=dev_insurance
REDIS_PASS=dev2016

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{NAMESPACE}}@${NAMESPACE}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{REPO}}@${REPO}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{MYSQL_HOST}}@${MYSQL_HOST}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{MYSQL_ROOT_PASS}}@${MYSQL_ROOT_PASS}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{MYSQL_USER}}@${MYSQL_USER}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{MYSQL_PASS}}@${MYSQL_PASS}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{MYSQL_DB}}@${MYSQL_DB}@g" src/insurancetruck/backend/values.yaml
sed -i -e "s@{{REDIS_PASS}}@${REDIS_PASS}@g" src/insurancetruck/backend/values.yaml

helm dependency build src/insurancetruck/backend/chart
helm install --name backend-$NAMESPACE -f src/insurancetruck/backend/values.yaml src/insurancetruck/backend/chart --namespace=$NAMESPACE
}
```

### 5. Deploy `it_2.71_frontend` [link](http://54.152.51.78:10080/ironjab/it_2.71_frontend)

#### 5.1. Create AWS ECR repo
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

aws ecr put-lifecycle-policy --repository-name ironjab/it_2.71_frontend --lifecycle-policy-text file://src/insurancetruck/ecr-lifecycle-policy/policy.json
```

#### 5.2. Build docker image

```sh
git clone http://54.152.51.78:10080/ironjab/it_2.71_frontend.git

sed -i -e "s@'process.env.API_URL'.*@'process.env.API_URL': JSON.stringify('https://backend.${NAMESPACE}.${DNS_ZONE}'),@g" it_2.71_frontend/webpack.dev.config.js

docker build -t 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_frontend:latest it_2.71_frontend
```

#### 5.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$(aws ecr get-login --no-include-email --region eu-central-1)

docker push 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_frontend:latest
```

#### 5.4. Deploy helm chart

```sh
{
REPO=532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_2.71_frontend

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/insurancetruck/frontend/values.yaml
sed -i -e "s@{{NAMESPACE}}@${NAMESPACE}@g" src/insurancetruck/frontend/values.yaml
sed -i -e "s@{{REPO}}@${REPO}@g" src/insurancetruck/frontend/values.yaml

helm install --name frontend-$NAMESPACE -f src/insurancetruck/frontend/values.yaml src/insurancetruck/frontend/chart --namespace=$NAMESPACE
}
```

### 6. Deploy `service_vin` [link](http://54.152.51.78:10080/ironjab/service_vin)

#### 6.1. Create AWS ECR repo

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

aws ecr put-lifecycle-policy --repository-name ironjab/service_vin --lifecycle-policy-text file://src/insurancetruck/ecr-lifecycle-policy/policy.json
```

#### 6.2. Build docker image

```sh
git clone http://54.152.51.78:10080/ironjab/service_vin.git

docker build -t 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/service_vin:latest service_vin
```

#### 6.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$(aws ecr get-login --no-include-email --region eu-central-1)

docker push 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/service_vin:latest
```

#### 6.4. Deploy helm chart

```sh
{
REPO=532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/service_vin
MYSQL_HOST=mysql-$NAMESPACE
MYSQL_ROOT_PASS=dev2016
MYSQL_USER=dev
MYSQL_PASS=dev2016
MYSQL_DB=dev_insurance
SMTP_NAME=AKIAI6HQ75CCY3NW7KFQ
SMTP_PASS=Aj5Zi7yFWBYJF/td/D+C7XThyR5duFZkFXcHuTwGpdsN
VIN_NAME=perealuc
VIN_PASS="Dec2014!"
MAIN_SITE=backend-$NAMESPACE

sed -i -e "s@{{REPO}}@${REPO}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{MYSQL_HOST}}@${MYSQL_HOST}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{MYSQL_ROOT_PASS}}@${MYSQL_ROOT_PASS}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{MYSQL_USER}}@${MYSQL_USER}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{MYSQL_PASS}}@${MYSQL_PASS}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{MYSQL_DB}}@${MYSQL_DB}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{SMTP_NAME}}@${SMTP_NAME}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{SMTP_PASS}}@${SMTP_PASS}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{VIN_NAME}}@${VIN_NAME}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{VIN_PASS}}@${VIN_PASS}@g" src/insurancetruck/vin/values.yaml
sed -i -e "s@{{MAIN_SITE}}@${MAIN_SITE}@g" src/insurancetruck/vin/values.yaml

helm install --name vin-$NAMESPACE -f src/insurancetruck/vin/values.yaml src/insurancetruck/vin/chart --namespace=$NAMESPACE
}
```

### 7. Deploy `it_aspire` [link](http://54.152.51.78:10080/ironjab/it_aspire)

#### 7.1. Create AWS ECR repo

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

aws ecr put-lifecycle-policy --repository-name ironjab/it_aspire --lifecycle-policy-text file://src/insurancetruck/ecr-lifecycle-policy/policy.json
```

#### 7.2. Build docker image

```sh
git clone http://54.152.51.78:10080/ironjab/it_aspire.git

docker build -t 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_aspire:latest it_aspire
```

#### 7.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$(aws ecr get-login --no-include-email --region eu-central-1)

docker push 532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_aspire:latest
```

#### 7.4. Deploy helm chart

```sh
{
REPO=532715861419.dkr.ecr.us-east-1.amazonaws.com/ironjab/it_aspire
MYSQL_HOST=mysql-$NAMESPACE
MYSQL_ROOT_PASS=dev2016
MYSQL_USER=dev
MYSQL_PASS=dev2016
MYSQL_DB=dev_insurance
SMTP_NAME=AKIAI6HQ75CCY3NW7KFQ
SMTP_PASS=Aj5Zi7yFWBYJF/td/D+C7XThyR5duFZkFXcHuTwGpdsN
MAIN_SITE=backend-$NAMESPACE
PUSH_KEY=00D95EA481CB43C19E935925F5064FB49F281663983D47199DC6337488577F30FAC5B3CBCB1F45268080146824BADD0B

sed -i -e "s@{{REPO}}@${REPO}@g" src/insurancetruck/aspire/values.yaml
sed -i -e "s@{{MYSQL_HOST}}@${MYSQL_HOST}@g" src/insurancetruck/aspire/values.yaml
sed -i -e "s@{{MYSQL_ROOT_PASS}}@${MYSQL_ROOT_PASS}@g" src/insurancetruck/aspire/values.yaml
sed -i -e "s@{{MYSQL_USER}}@${MYSQL_USER}@g" src/insurancetruck/aspire/values.yaml
sed -i -e "s@{{MYSQL_PASS}}@${MYSQL_PASS}@g" src/insurancetruck/aspire/values.yaml
sed -i -e "s@{{MYSQL_DB}}@${MYSQL_DB}@g" src/insurancetruck/aspire/values.yaml
sed -i -e "s@{{SMTP_NAME}}@${SMTP_NAME}@g" src/insurancetruck/aspire/values.yaml
sed -i -e "s@{{SMTP_PASS}}@${SMTP_PASS}@g" src/insurancetruck/aspire/values.yaml
sed -i -e "s@{{MAIN_SITE}}@${MAIN_SITE}@g" src/insurancetruck/aspire/values.yaml
sed -i -e "s@{{PUSH_KEY}}@${PUSH_KEY}@g" src/insurancetruck/aspire/values.yaml

helm install --name aspire-$NAMESPACE -f src/insurancetruck/aspire/values.yaml src/insurancetruck/aspire/chart --namespace=$NAMESPACE
}
```

<!-- ## Demo

<p align="center">
  <a target="_blank" href="https://asciinema.org/a/197051">
  <img src="https://asciinema.org/a/197051.png" width="885"></image>
  </a>
</p> -->

# What's next?

### Step 8. [Jenkins (CI/CD)](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step8.md)