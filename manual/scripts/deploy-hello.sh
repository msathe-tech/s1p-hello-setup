#!/usr/bin/env bash

echo "Enter Hello repo home dir [~/workspace/hello]: "
read HELLO_HOME
export HELLO_HOME="${$HELLO_HOME:~/workspace/hello}"
echo "HELLO_HOME set to ${HELLO_HOME}"

export "HELLO_CONFIG=${HELLO_HOME}/deploy/manual/config"
echo "HELLO_CONFIG set to ${HELLO_CONFIG}"
echo "Continue? [yN]: "
read CONTINUE
if [CONTINUE != "y"]; then
  echo "Aborting deployment script"
  return
fi

./cleanup.sh

kubectl create namespace hello

./setup-ingress.sh
kubectl get all -n hello

kubectl create -f ${HELLO_HOME}/hello-service/create-hello-service.yaml
kubectl create -f ${HELLO_HOME}/hello-client/create-hello-client.yaml

kubectl create -f ${HELLO_CONFIG}/hello-ingress.yaml

kubectl get all -n hello
