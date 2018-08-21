# Step 4. AuthN and AuthZ

### 1. Configure Auth0 [link](https://auth0.com)
Universal authentication & authorization platform for web, mobile, and legacy applications.

1. Sign Up [link](https://auth0.com/signup?&signUpData=%7B%22category%22%3A%22button%22%7D)
2. Create new application (`Regular Web Applications` Type) [link](https://manage.auth0.com/#/applications)
3. Set `Allowed Callback URLs` (App Settings Tab)

```sh
https://dex.example.com/callback # replace example.com
http://127.0.0.1:5555/callback
```
4. Create database connection [link](https://manage.auth0.com/#/connections/database)
    * `Requires Username` = True
    * `Disable Sign Ups` = True
5. Enable DB connection (App Connections Tab: Database)
6. Disable `google-oauth2` (App Connections Tab: Social)
7. Create new user [link](https://manage.auth0.com/#/users)
8. Verify user email. Auth2 will send a message to the created user's email
9. Get application Client ID, Client Secret, Domain (App Settings Tab)

```sh
Domain:        gdv.eu.auth0.com
Client ID:     smcFVCQlqiSgyHpgP9WzcRJCsd3gNOYG
Client Secret: xl7P4qhGNGU1xsfM47_DyVImXrj3a9_2dqvNgdadBlZfhaq0B8gBqiTAAMA68qiu
```

### 2. Dex [link](https://github.com/coreos/dex)
`Dex` is an identity service that uses OpenID Connect to drive authentication for other apps.

`Dex` acts as a portal to other identity providers through "connectors." This lets dex defer authentication to LDAP servers, SAML providers, or established identity providers like GitHub, Google, and Active Directory. Clients write their authentication logic once to talk to dex, then dex handles the protocols for a given backend.

```sh
$ DNS_ZONE=example.com
$ DEX_ID=insurancetruck-app # random string
$ DEX_SECRET=c2cHAtc2VjcmhhbXBsHAtc2VjcmV0ZXBsHAtZS1hhbXBsHAtc2cHAtc2VjcmV0 # random string
$ AUTH0_DOMAIN=https://gdv.eu.auth0.com/ # slash at the end is REQUIRED
$ AUTH0_CLIENT_ID=smcFVCQlqiSgyHpgP9WzcRJCsd3gNOYG # replace with yours
$ AUTH0_CLIENT_SECRET=xl7P4qhGNGU1xsfM47_DyVImXrj3a9_2dqvNgdadBlZfhaq0B8gBqiTAAMA68qiu # replace with yours

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/dex/values.yaml
$ sed -i -e "s@{{DEX_ID}}@${DEX_ID}@g" src/dex/values.yaml
$ sed -i -e "s@{{DEX_SECRET}}@${DEX_SECRET}@g" src/dex/values.yaml
$ sed -i -e "s@{{AUTH0_DOMAIN}}@${AUTH0_DOMAIN}@g" src/dex/values.yaml
$ sed -i -e "s@{{AUTH0_CLIENT_ID}}@${AUTH0_CLIENT_ID}@g" src/dex/values.yaml
$ sed -i -e "s@{{AUTH0_CLIENT_SECRET}}@${AUTH0_CLIENT_SECRET}@g" src/dex/values.yaml
$ helm install --name dex src/dex/dex -f src/dex/values.yaml --namespace it-dev

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/dex/dex-certificate.yaml
$ kubectl apply -f src/dex/dex-certificate.yaml

check https://dex.example.com/.well-known/openid-configuration # replace example.com
```

**Please DO NOT MOVE ON until you have deployed dex!**

### 3. Oauth2_proxy [link](https://github.com/bitly/oauth2_proxy)
A reverse proxy that provides authentication with Google, Github or other provider

```sh
$ DNS_ZONE=example.com
$ CLIENT_ID=insurancetruck-app # value from the DEX_ID (previous step)
$ CLIENT_SECRET=c2cHAtc2VjcmhhbXBsHAtc2VjcmV0ZXBsHAtZS1hhbXBsHAtc2cHAtc2VjcmV0 # value from the DEX_SECRET (previous step)
$ COOKIE_SECRET=d0R2lgvNVnOFWKxjulndOQ== # python -c 'import os,base64; print base64.b64encode(os.urandom(16))'

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/oauth2-proxy/values.yaml
$ sed -i -e "s@{{CLIENT_ID}}@${CLIENT_ID}@g" src/oauth2-proxy/values.yaml
$ sed -i -e "s@{{CLIENT_SECRET}}@${CLIENT_SECRET}@g" src/oauth2-proxy/values.yaml
$ sed -i -e "s@{{COOKIE_SECRET}}@${COOKIE_SECRET}@g" src/oauth2-proxy/values.yaml
$ helm install --name oauth2-proxy src/oauth2-proxy/oauth2-proxy -f src/oauth2-proxy/values.yaml --namespace it-dev

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/oauth2-proxy/oauth2-certificate.yaml
$ kubectl apply -f src/oauth2-proxy/oauth2-certificate.yaml

check https://oauth2.example.com # replace example.com
```

### 4. Add Auth0 user admin rights
```sh
$ DNS_ZONE=example.com
$ AUTH0_USER_USERNAME=exampleUser # auth0 created user at step 1.7 username

$ sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" src/admin-user/clusterrolebinding.yaml
$ sed -i -e "s@{{AUTH0_USER_USERNAME}}@${AUTH0_USER_USERNAME}@g" src/admin-user/clusterrolebinding.yaml
$ kubectl apply -f src/admin-user/clusterrolebinding.yaml
```

## Demo

<p align="center">
  <a target="_blank" href="https://asciinema.org/a/197034">
  <img src="https://asciinema.org/a/197034.png" width="885"></image>
  </a>
</p>

# What's next?

### Step 5. [Monitoring](http://54.152.51.78:10080/ironjab/it-k8s/src/master/docs/step5.md)