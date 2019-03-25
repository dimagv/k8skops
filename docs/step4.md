###### [back](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step3.md)

# Step 4. AuthN and AuthZ

### 1. Keycloak [link](https://www.keycloak.org)
Open Source Identity and Access Management For Modern Applications and Services

#### 1.1. Create namespace
```sh
kubectl create namespace keycloak
```

#### 1.2. Deploy keycloak
```sh
{
sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/keycloak/values.yaml
helm install --name keycloak stable/keycloak -f src/keycloak/values.yaml --namespace keycloak
}
```

#### 1.2. Configure keycloak

1. Sign In [link](https://keycloak.k8s.ironjab.com/auth)
    * Username: `keycloak`
    * Password: `kubectl -n keycloak get secret keycloak-http -o yaml | grep "password:" | awk '{print $2}' | base64 --decode`
2. Create new realm for cluster [link](https://keycloak.k8s.ironjab.com/auth/admin/master/console/#/create/realm)
    * Name: `cluster1`
3. Increate token ttl to 30min [link](https://keycloak.k8s.ironjab.com/auth/admin/master/console/#/realms/cluster1/token-settings)
    * Access Token Lifespan: `30`
4. Create kubernetes client [link](https://keycloak.k8s.ironjab.com/auth/admin/master/console/#/create/client/cluster1)
    * Client ID: `kubernetes`
    * Client Protocol: `openid-connect`
5. Configure client (settings tab)
    * Access Type: `confidential`
    * Direct Access Grants Enabled: `False`
    * Valid Redirect URIs: 

        ```sh
        http://127.0.0.1:5555/callback # for auth-cli
        https://keycloak-gatekeeper.k8s.ironjab.com/oauth/callback # for gatekeeper
        https://dashboard.k8s.ironjab.com/oauth/callback
        https://prometheus.k8s.ironjab.com/oauth/callback
        https://alertmanager.k8s.ironjab.com/oauth/callback
        ```
6. Create client mappers:

    ```sh
    Name: name
    Mapper Type: User Property
    Property: username
    Token Claim Name: name
    Claim JSON Type: String
    ```

    ```sh
    Name: groups
    Mapper Type: Group Membership
    Token Claim Name: groups
    Full group path: False
    ``` 

    ```sh
    Name: audience
    Mapper Type: Audience
    Included Client Audience: kubernetes
    Add to ID token: True
    ```
7. Get secret (credentials tab)

    ```sh
    4158b320-a82d-40e6-b239-01a83a2ae882
    ```

### 2. keycloak-gatekeeper [link](https://github.com/keycloak/keycloak-gatekeeper)
A OpenID / Keycloak Proxy service

#### 2.1. Create namespace
```sh
kubectl create ns keycloak-gatekeeper
```

#### 2.2. Deploy keycloak-gatekeeper
```sh
KEYCLOAK_SECRET=4158b320-a82d-40e6-b239-01a83a2ae882

{
sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/keycloak-gatekeeper/alertmanager.yaml
sed -i -e "s@{{KEYCLOAK_SECRET}}@${KEYCLOAK_SECRET}@g" src/keycloak-gatekeeper/alertmanager.yaml

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/keycloak-gatekeeper/prometheus.yaml
sed -i -e "s@{{KEYCLOAK_SECRET}}@${KEYCLOAK_SECRET}@g" src/keycloak-gatekeeper/prometheus.yaml

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/keycloak-gatekeeper/kubernetes-dashboard.yaml
sed -i -e "s@{{KEYCLOAK_SECRET}}@${KEYCLOAK_SECRET}@g" src/keycloak-gatekeeper/kubernetes-dashboard.yaml

kubectl create -f src/keycloak-gatekeeper
}
```

### 3. Auth-cli
Connect to an OIDC provider and authenticate users before configuring their kubeconfig

```sh
{
KEYCLOAK_CLIENT=kubernetes
KEYCLOAK_SECRET=4158b320-a82d-40e6-b239-01a83a2ae882
KEYCLOAK_REALM=https://keycloak.k8s.ironjab.com/auth/realms/cluster1
KUBECLUSTER=https://api.cluster1.k8s.ironjab.com

./src/auth-cli/auth-cli --client-id=$KEYCLOAK_CLIENT --client-secret=$KEYCLOAK_SECRET --issuer=$KEYCLOAK_REALM --kubecluster=$KUBECLUSTER
}
```
> **or compile the application with your defaults**

<!-- ### 4. Add Auth0 user admin rights
```sh
{
AUTH0_USER_USERNAME=dimag # auth0 created user at step 1.7 username

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/admin-user/clusterrolebinding.yaml
sed -i -e "s@{{AUTH0_USER_USERNAME}}@${AUTH0_USER_USERNAME}@g" src/admin-user/clusterrolebinding.yaml
kubectl apply -f src/admin-user/clusterrolebinding.yaml
}
``` -->

<!-- ## Demo

<p align="center">
  <a target="_blank" href="https://asciinema.org/a/197034">
  <img src="https://asciinema.org/a/197034.png" width="885"></image>
  </a>
</p> -->

# What's next?

### Step 5. [Monitoring](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step5.md)