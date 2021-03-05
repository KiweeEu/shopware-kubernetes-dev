#!/usr/bin/env bash
kubectl port-forward -n development svc/app-server 8000:8000 8080:8080 9998:9998 9999:9999 8005:8005
