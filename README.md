# s1p-hello-setup

### Install Prometheus
```
helm install \
    --namespace=monitoring \
    --name=prometheus \
    --version=7.0.0 \
    stable/prometheus
```

### Install Grafana
```
helm install \
    --namespace=monitoring \
    --name=grafana \
    --version=1.12.0 \
    --set=adminUser=admin \
    --set=adminPassword=admin \
    --set=service.type=LoadBalancer \
    stable/grafana
```

1. Get your 'admin' user password by running:
```kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo```
   

2. The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

   grafana.monitoring.svc.cluster.local

   Get the Grafana URL to visit by running these commands in the same shell:
NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 
        ```kubectl get svc --namespace monitoring -w grafana
        export SERVICE_IP=$(kubectl get svc --namespace monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        echo $$SERVICE_IP```
     http://$SERVICE_IP:80

3. Login with the password from step 1 and the username: admin