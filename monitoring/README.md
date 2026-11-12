# Restauranty — Monitoring and Logging

## Overview

Restauranty uses Prometheus and Grafana for application
monitoring on AWS EKS.

The monitoring stack collects metrics from three backend
microservices and provides real-time dashboards.

## Monitored Services

- restauranty-auth
- restauranty-discounts
- restauranty-items

## Monitoring Components

- Prometheus: collects application metrics.
- ServiceMonitor: discovers backend metrics endpoints.
- Grafana: visualizes application metrics.
- Kubernetes Logs: provides application request and error logs.

## Configuration Files

- values.yaml: Prometheus stack configuration.
- servicemonitor.yaml: backend metrics scraping configuration.
- grafana-dashboard.json: exported Grafana dashboard.

## Metrics

All three backend services expose a /metrics endpoint.

Prometheus scrapes these endpoints every 15 seconds.

The Grafana dashboard includes:

1. HTTP Request Rate
2. MongoDB Connection Status

## Verification

The following checks were completed successfully:

- All three Prometheus targets were UP.
- MongoDB connection metrics reported healthy status.
- A test generated 60 HTTP requests to the Items API.
- Grafana detected the resulting increase in request rate.
- Requests without authorization tokens returned HTTP 401.
- Kubernetes logs recorded the requests and errors.

## Access

Prometheus:

kubectl -n monitoring port-forward \
  svc/monitoring-kube-prometheus-prometheus 9090:9090

Grafana:

kubectl -n monitoring port-forward \
  svc/monitoring-grafana 3100:80

Prometheus URL: http://localhost:9090

Grafana URL: http://localhost:3100

## Logging

Application logs can be inspected using:

kubectl -n restauranty logs deployment/restauranty-auth

kubectl -n restauranty logs deployment/restauranty-discounts

kubectl -n restauranty logs deployment/restauranty-items

## Future Improvements

- Centralized logging using Loki and Alloy
- Amazon CloudWatch integration
- Additional infrastructure and application metrics
- Monitoring alerts