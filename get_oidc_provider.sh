#!/bin/bash

aws eks describe-cluster --name cluster_name --query "cluster.identity.oidc.issuer" --output text
