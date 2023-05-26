#!/bin/bash

curl -X GET 'http://10.37.70.122/nacos/v2/cs/config?dataId=ask&group=bioos&namespaceId=9e7c9f3b-9913-4444-b33f-4d578a58bfed'| jq '.data' > nacos.out


minikube kubectl -- create cm cm-ask --from-file nacos.out -o yaml --dry-run | minikube kubectl -- apply -f -