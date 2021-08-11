# CORS Demo with Gloo Edge

With [Gloo' CORS](https://docs.solo.io/gloo-edge/latest/guides/security/cors/) options its possible to set up the backend API with CORS settings without the needed to redeploy the application.

The demo code for the [blog](https://www.solo.io/blog/how-to-update-cors-policies-without-re-deploying-your-api) with cluster setup adapted for [Civo](https://civo.com) with Gloo Edge in deployed with default settings.

## Create Cluster

```shell
civo k3s create my-cluster -r="Traefik" -a="gloo-edge"  --size='g3.k3s.large' --save --wait --merge
```

Once the cluster is deployed check if Gloo Edge is functional,

```shell
glooctl check
```

## Deploy App

### Demo Sources

```shell
git clone https://github.com/kameshsampath/gloo-cors-demo -b civo
```

### Deploy Database

```shell
kubectl apply -k $DEMO_HOME/apps/manifests/fruits-api/db
```

Wait for the DB to be up

```shell
kubectl rollout status -n db deploy/postgresql --timeout=60s
```

### Deploy REST API

```shell
kubectl apply -k $DEMO_HOME/apps/manifests/fruits-api/app
```

Wait for the REST API to be up

```shell
kubectl rollout status -n fruits-app deploy/fruits-api --timeout=60s
```

## Gloo Edge

Check if the upsteram is available

```shell
glooctl get upstream fruits-app-fruits-api-8080
```

```text
-----------------------------------------------------------------------------+
|          UPSTREAM          |    TYPE    |  STATUS  |          DETAILS          |
-----------------------------------------------------------------------------+
| fruits-app-fruits-api-8080 | Kubernetes | Accepted | svc name:      fruits-api |
|                            |            |          | svc namespace: fruits-app |
|                            |            |          | port:          8080       |
|                            |            |          |                           |
-----------------------------------------------------------------------------+
```

Deploy the gateway,

```shell
kubectl apply -n gloo-system -f $DEMO_HOME/apps/manifests/fruits-api/gloo/gateway
```

Check the status of the virtual service

```shell
glooctl get vs fruits-api
```

```text
----------------------------------------------------------------------------------------------
| VIRTUAL SERVICE | DISPLAY NAME | DOMAINS | SSL  |  STATUS  | LISTENERPLUGINS |       ROUTES        |
----------------------------------------------------------------------------------------------
| fruits-api      |              | *       | none | Accepted |                 | / -> 1 destinations |
----------------------------------------------------------------------------------------------
```

### CORS Demo

#### Allowing different origins with CORS

```shell
kubectl apply -n gloo-system -f $DEMO_HOME/demos/manifests/cors/gateway-cors-1.yaml
```

#### Allowing different headers with CORS

```shell
kubectl apply -n gloo-system -f $DEMO_HOME/demos/manifests/cors/gateway-cors-2.yaml
```

#### Other allow methods for CORS

```shell
kubectl apply -n gloo-system -f $DEMO_HOME/demos/manifests/cors/gateway-cors-3.yaml
```
