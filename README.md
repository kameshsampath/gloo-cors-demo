# CORS Demo

With [Gloo' CORS](https://docs.solo.io/gloo-edge/latest/guides/security/cors/) options its possible to set up the backend API with CORS settings without the needed to redeploy the application.

The following sections shows how to apply these settings to make the front API interact successfully with backend

## Start Fruits UI

```shell
docker run --name=fruits-app -p 8085:8080 quay.io/kameshsampath/fruits-app-ui
```

When you open the URL http://localhost:8085, you will see application is still loading. If you view the console log (Developer Tools) of the browser, you wil notice [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) errors.

## Resolving CORS Errors

Let us resolve the errors one by one

### Allowing Origin

The very first error you face is the backend not allowing requests from `http://locahost:8080`, to fix it update the `fruits-api` Virtual service as shown:

```yaml
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: fruits-api
  namespace: my-gloo
spec:
  displayName: FruitsAPI
  virtualHost:
    options:
      cors:
        allowOriginRegex:
          - '^http(s)?:\/\/localhost(:?[0-9]{0,5})$'
        maxAge: 1d
    domains:
      - '*'
    routes:
      - matchers:
          - prefix: /
        routeAction:
          multi:
            destinations:
              - weight: 100
                destination:
                  upstream:
                    name: fruits-app-fruits-api-8080
                    namespace: my-gloo
```

Update the existing virtual service by,

```shell
kubectl apply -n my-gloo apply -f demos/cors/gateway-cors-1.yaml
```

The above command will allow requests to backend from `Origins` like `http://localhost`, `https://localhost`, `http://localhost:8085`.

Now refreshing the browser you till notice the Fruits data loaded from backend.
