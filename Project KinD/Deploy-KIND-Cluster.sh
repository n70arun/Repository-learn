#!/bin/bash

kind delete cluster --name kind-cluster-pandora
kind create cluster --name kind-cluster-pandora --config K8S-Config-1CP-2W.yaml


