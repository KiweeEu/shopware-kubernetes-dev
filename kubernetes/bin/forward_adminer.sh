#!/usr/bin/env bash
kubectl port-forward -n development svc/adminer 8081:8001
