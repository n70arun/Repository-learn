#!/bin/bash

kind delete cluster --name kind-cluster-pandora
docker network rm kind kind-net || true
docker network create --driver=bridge --subnet=172.20.0.0/16 kind-net
#kind create cluster --name kind-cluster-pandora --config K8S-Config-1CP-2W.yaml
KIND_EXPERIMENTAL_DOCKER_NETWORK=kind-net kind create cluster --config K8S-Config-1CP-2W.yaml


