# Step 7. Drone.io (CI/CD)

it-backend and it-frontend REVISION=1 was deployed at step 6

### 1. Deploy drone

```sh
$ DNS_ZONE=example.com
$ GOGS_USER=gdv

$ drone=src/drone/values.yaml
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" "${drone}"
$ sed -i -e "s@{{GOGS_USER}}@${GOGS_USER}@g" "${drone}"
$ helm install --name drone src/drone/drone -f $drone --namespace it-dev

$ cert=src/drone/drone-certificate.yaml
$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" "${cert}"
$ kubectl apply -f $cert

check https://drone.example.com   
```

### 2. Create test repos

* Create 2 test repos in GOGS (`it-backend-test` and `it-frontend-test`)

### 3. Configure drone

1. Open https://drone.example.com
2. Sign in as $GOGS_USER
3. Activate **TEST** repos (`it-backend-test` and `it-frontend-test`). **DON'T ACTIVATE REAL REPOS**. It will replace existing webhook with drone's webhook
4. Get drone api token https://drone.example.com/account/token

### 4. Create drone service account

```sh
$ kubectl create serviceaccount --namespace kube-system drone
$ kubectl create clusterrolebinding drone-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:drone
```

### 5. Set drone secrets

```sh
$ DRONE_SERVER=https://drone.example.com
$ DRONE_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0ZXh0IjoiZ2R2IiwidHlwZSI6InVzZXIifQ.k0mJdool0CJhmM5MihuYWxx36AQmbMh_n_w2fbE7kpY
$ AWS_ACCESS_KEY_ID=
$ AWS_SECRET_ACCESS_KEY=
$ DRONE_SA_TOKEN=$(kubectl -n kube-system get secret $(kubectl -n kube-system get secret | grep drone | awk '{print $1}') -o yaml | grep "token:" | awk '{print $2}' | base64 -d)
$ K8S_API_SERVER=https://api.it.example.com

# it-backend-test
$ REPO=ironjab/it-backend-test
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image quay.io/ipedrazas/drone-helm -name dev_api_server -value $K8S_API_SERVER
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image quay.io/ipedrazas/drone-helm -name dev_kubernetes_token -value $DRONE_SA_TOKEN
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image plugins/ecr -name ecr_access_key -value $AWS_ACCESS_KEY_ID
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image plugins/ecr -name ecr_secret_key -value $AWS_SECRET_ACCESS_KEY
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image plugins/ecr -name ecr_region -value eu-central-1

# it-frontend-test
$ REPO=ironjab/it-frontend-test
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image quay.io/ipedrazas/drone-helm -name dev_api_server -value $K8S_API_SERVER
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image quay.io/ipedrazas/drone-helm -name dev_kubernetes_token -value $DRONE_SA_TOKEN
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image plugins/ecr -name ecr_access_key -value $AWS_ACCESS_KEY_ID
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image plugins/ecr -name ecr_secret_key -value $AWS_SECRET_ACCESS_KEY
$ docker run --env="DRONE_SERVER=$DRONE_SERVER" --env="DRONE_TOKEN=$DRONE_TOKEN" drone/cli secret add -repository $REPO -image plugins/ecr -name ecr_region -value eu-central-1
```

### 6. Configure test repos

1. Clone `it_2.71_backend` and `it_2.71_frontend`

```sh
# it-backend
$ git clone ssh://git@54.152.51.78:10022/ironjab/it_2.71_backend.git
# it-frontend
$ git clone ssh://git@54.152.51.78:10022/ironjab/it_2.71_frontend.git
```
2. Change remote repository URL to break nothing in the working app

```sh
# it-backend
$ cd it_2.71_backend && git remote set-url origin http://54.152.51.78:10080/ironjab/it-backend-test.git && cd ..

# it-frontend
$ cd it_2.71_frontend && git remote set-url origin http://54.152.51.78:10080/ironjab/it-frontend-test.git && cd ..
```

3. Configure .drone.yaml

```sh
$ REGISTRY=784590408214.dkr.ecr.eu-central-1.amazonaws.com

# it-backend
$ REPO=784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/backend
$ drone=src/drone/.drone.backend.yml
$ sed -i -e "s@{{REPO}}@${REPO}@g" "${drone}"
$ sed -i -e "s@{{REGISTRY}}@${REGISTRY}@g" "${drone}"
$ mv $drone it_2.71_backend/.drone.yml

# it-frontend
$ REPO=784590408214.dkr.ecr.eu-central-1.amazonaws.com/insurancetruck/frontend
$ drone=src/drone/.drone.frontend.yml
$ sed -i -e "s@{{REPO}}@${REPO}@g" "${drone}"
$ sed -i -e "s@{{REGISTRY}}@${REGISTRY}@g" "${drone}"
$ mv $drone it_2.71_frontend/.drone.yml
```

4. Configure helm charts

```sh
# it-backend
$ cp -r src/it-backend/it-backend it_2.71_backend/helm
$ cp src/it-backend/values.yaml it_2.71_backend/helm # values.yaml should be configured from the previous step6
$ cd it_2.71_backend 
$ git add . && git commit -m "add ci/cd" && git push origin master
$ cd ..

# it-frontend
$ vi it_2.71_frontend/webpack.prod.config.js # change `process.env.API_URL` => https://it-backend.example.com
$ cp -r src/it-frontend/it-frontend it_2.71_frontend/helm
$ cp src/it-frontend/values.yaml it_2.71_frontend/helm # values.yaml should be configured from the previous step6
$ cd it_2.71_frontend
$ git add . && git commit -m "add ci/cd" && git push origin master
$ cd ..
```

5. Check

```sh
# should see running builds
1) open https://drone.example.com/ironjab/ 
2) $ helm ls
```

## Demo

<p align="center">
  <a target="_blank" href="https://asciinema.org/a/197077">
  <img src="https://asciinema.org/a/197077.png" width="885"></image>
  </a>
</p>

### Step 8. [Additionally](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step8.md)