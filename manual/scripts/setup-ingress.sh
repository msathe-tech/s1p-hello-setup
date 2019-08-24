#!/usr/bin/env bash
kubectl get serviceaccount --all-namespaces | grep nginx-ingress-serviceaccount
kubectl delete serviceaccount nginx-ingress-serviceaccount

kubectl get clusterrolebinding | grep nginx-ingress-cluster-role-binding
kubectl delete clusterrolebinding nginx-ingress-cluster-role-binding

kubectl create -f ${HELLO_CONFIG}/service-account.yml
kubectl create -f ${HELLO_CONFIG}/service-account-role.yml

kubectl create -f ${HELLO_CONFIG}/default-backend-service.yml
kubectl create -f ${HELLO_CONFIG}/default-backend.yml

kubectl create -f ${HELLO_CONFIG}/ingress-controller-service.yml
kubectl create -f ${HELLO_CONFIG}/ingress-controller.yml

