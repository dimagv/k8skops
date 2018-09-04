# Step 6. Insurancetruck App

### 1. Mysql [link](https://www.mysql.com/)

```sh
$ MYSQL_ROOT_PASS=dev2016
$ MYSQL_USER=dev
$ MYSQL_PASS=dev2016
$ MYSQL_DB=dev_insurance

$ sed -i -e "s@{{MYSQL_ROOT_PASS}}@${MYSQL_ROOT_PASS}@g" src/mysql/values.yaml
$ sed -i -e "s@{{MYSQL_USER}}@${MYSQL_USER}@g" src/mysql/values.yaml
$ sed -i -e "s@{{MYSQL_PASS}}@${MYSQL_PASS}@g" src/mysql/values.yaml
$ sed -i -e "s@{{MYSQL_DB}}@${MYSQL_DB}@g" src/mysql/values.yaml
$ helm install --name insurancetruck-db -f src/mysql/values.yaml stable/mysql --namespace $NAMESPACE

# wait some time
$ kubectl get po -n $NAMESPACE -w
```

### 2. Import Mysql DB

```sh
$ kubectl run mysql-client --image=mysql:5.7 -i --rm --restart=Never -- mysql -h insurancetruck-db-mysql -uroot -pdev2016 dev_insurance < src/mysql/dev_insurance.sql

# test
kubectl run mysql-client --image=mysql:5.7 -it --rm --restart=Never -- mysql -h insurancetruck-db-mysql -uroot -pdev2016 dev_insurance -e 'SHOW TABLES;'
```

### 3. phpMyAdmin [link](https://www.phpmyadmin.net/)

```sh
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/pma/values.yaml
$ helm install --name insurancetruck-pma -f src/pma/values.yaml stable/phpmyadmin --namespace $NAMESPACE

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/pma/pma-certificate.yaml
$ kubectl apply -f src/pma/pma-certificate.yaml --namespace=$NAMESPACE

check https://pma.example.com # replace example.com
```

### 4. Deploy `it_2.71_backend` [link](http://54.152.51.78:10080/ironjab/it_2.71_backend)

#### 4.1. Create AWS ECR repo

```sh
$ aws ecr create-repository --repository-name insurancetruck/backend

Output:
{                                                 
    "repository": {                               
        "repositoryArn": "arn:aws:ecr:eu-central-1:784590408214:repository/insurancetruck/backend",  
        "registryId": "784590408214",             
        "repositoryName": "insurancetruck/backend",                                                  
        "repositoryUri": "784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/backend",   
        "createdAt": 1534613601.0                 
    }                                             
}     
```

#### 4.2. Build docker image

```sh
$ git clone ssh://git@54.152.51.78:10022/ironjab/it_2.71_backend.git
$ docker build -t 784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/backend:latest it_2.71_backend
```

#### 4.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$ $(aws ecr get-login --no-include-email --region eu-central-1)
$ docker push 784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/backend:latest
```

#### 4.4. Deploy helm chart

```sh
$ REPO=784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/backend
$ MYSQL_ROOT_PASS=dev2016
$ MYSQL_USER=dev
$ MYSQL_PASS=dev2016
$ MYSQL_DB=dev_insurance
$ REDIS_PASS=dev2016

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/it-backend/values.yaml
$ sed -i -e "s@{{REPO}}@${REPO}@g" src/it-backend/values.yaml
$ sed -i -e "s@{{MYSQL_ROOT_PASS}}@${MYSQL_ROOT_PASS}@g" src/it-backend/values.yaml
$ sed -i -e "s@{{MYSQL_USER}}@${MYSQL_USER}@g" src/it-backend/values.yaml
$ sed -i -e "s@{{MYSQL_PASS}}@${MYSQL_PASS}@g" src/it-backend/values.yaml
$ sed -i -e "s@{{MYSQL_DB}}@${MYSQL_DB}@g" src/it-backend/values.yaml
$ sed -i -e "s@{{REDIS_PASS}}@${REDIS_PASS}@g" src/it-backend/values.yaml
$ helm install --name it-backend -f src/it-backend/values.yaml src/it-backend/it-backend --namespace=$NAMESPACE

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/it-backend/it-backend-certificate.yaml
$ kubectl apply -f src/it-backend/it-backend-certificate.yaml --namespace=$NAMESPACE

check https://it-backend.example.com # replace example.com
```

### 5. Deploy `it_2.71_frontend` [link](http://54.152.51.78:10080/ironjab/it_2.71_frontend)

#### 5.1. Create AWS ECR repo
```sh
$ aws ecr create-repository --repository-name insurancetruck/frontend

Output:
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:eu-central-1:784590408214:repository/insurancetruck/frontend",
        "registryId": "784590408214",
        "repositoryName": "insurancetruck/frontend",
        "repositoryUri": "784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/frontend",
        "createdAt": 1534620051.0
    }
}
```

#### 5.2. Build docker image

```sh
$ git clone ssh://git@54.152.51.78:10022/ironjab/it_2.71_frontend
$ cd it_2.71_frontend
$ vi webpack.prod.config.js # change `process.env.API_URL` => https://it-backend.example.com
$ chmod +x docker-build.sh && ./docker-build.sh # install nodejs+yarn before
$ docker build -t 784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/frontend:latest .
$ cd ..
```

#### 5.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$ $(aws ecr get-login --no-include-email --region eu-central-1)
$ docker push 784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/frontend:latest
```

#### 5.4. Deploy helm chart

```sh
$ REPO=784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/frontend

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/it-frontend/values.yaml
$ sed -i -e "s@{{REPO}}@${REPO}@g" src/it-frontend/values.yaml
$ helm install --name it-frontend -f src/it-frontend/values.yaml src/it-frontend/it-frontend --namespace=$NAMESPACE

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/it-frontend/it-frontend-certificate.yaml
$ kubectl apply -f src/it-frontend/it-frontend-certificate.yaml --namespace=$NAMESPACE

check https://it-frontend.example.com # replace example.com
```

### 6. Deploy `service_vin` [link](http://54.152.51.78:10080/ironjab/service_vin)

#### 6.1. Create AWS ECR repo

```sh
$ aws ecr create-repository --repository-name insurancetruck/vin

Output:
{                                                 
    "repository": {                               
        "repositoryArn": "arn:aws:ecr:eu-central-1:784590408214:repository/insurancetruck/vin",      
        "registryId": "784590408214",             
        "repositoryName": "insurancetruck/vin",   
        "repositoryUri": "784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/vin",       
        "createdAt": 1535728891.0                 
    }                                             
}    
```

#### 6.2. Build docker image

```sh
$ git clone ssh://git@54.152.51.78:10022/ironjab/service_vin.git
$ docker build -t 784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/vin:latest service_vin
```

#### 6.3. Push docker image

```sh
# retrieve the login command to use to authenticate your Docker client to your registry.
$ $(aws ecr get-login --no-include-email --region eu-central-1)
$ docker push 784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/vin:latest
```

#### 6.4. Deploy helm chart

```sh
$ REPO=784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/vin
$ MYSQL_ROOT_PASS=dev2016
$ MYSQL_USER=dev
$ MYSQL_PASS=dev2016
$ MYSQL_DB=dev_insurance
$ SMTP_NAME=AKIAI6HQ75CCY3NW7KFQ
$ SMTP_PASS=Aj5Zi7yFWBYJF/td/D+C7XThyR5duFZkFXcHuTwGpdsN
$ VIN_NAME=perealuc
$ VIN_PASS="Dec2014!"

$ sed -i -e "s@{{REPO}}@${REPO}@g" src/it-vin/values.yaml
$ sed -i -e "s@{{MYSQL_ROOT_PASS}}@${MYSQL_ROOT_PASS}@g" src/it-vin/values.yaml
$ sed -i -e "s@{{MYSQL_USER}}@${MYSQL_USER}@g" src/it-vin/values.yaml
$ sed -i -e "s@{{MYSQL_PASS}}@${MYSQL_PASS}@g" src/it-vin/values.yaml
$ sed -i -e "s@{{MYSQL_DB}}@${MYSQL_DB}@g" src/it-vin/values.yaml
$ sed -i -e "s@{{SMTP_NAME}}@${SMTP_NAME}@g" src/it-vin/values.yaml
$ sed -i -e "s@{{SMTP_PASS}}@${SMTP_PASS}@g" src/it-vin/values.yaml
$ sed -i -e "s@{{VIN_NAME}}@${VIN_NAME}@g" src/it-vin/values.yaml
$ sed -i -e "s@{{VIN_PASS}}@${VIN_PASS}@g" src/it-vin/values.yaml

$ helm install --name it-vin -f src/it-vin/values.yaml src/it-vin/it-vin --namespace=$NAMESPACE
```

## Demo

<p align="center">
  <a target="_blank" href="https://asciinema.org/a/197051">
  <img src="https://asciinema.org/a/197051.png" width="885"></image>
  </a>
</p>

# What's next?

### Step 7. [Drone.io (CI/CD)](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step7.md)