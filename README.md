# GitOps Repository for Cloud-Native Application on Amazon EKS

## Overview

This repository manages **GitOps-driven Kubernetes deployments** for a containerized Dry Cleaning Web Application running on **Amazon EKS**.

It serves as the **declarative deployment and runtime operations repository** for the platform and contains environment-specific manifests for:

- application workloads
- ingress resources
- observability components
- centralized logging
- distributed tracing
- backup and restore tooling

All runtime changes are managed through Git and synchronized into the cluster using **ArgoCD**.

---

## Purpose of This Repository

This repository exists to separate **runtime deployment state** from **infrastructure provisioning**.

### Infrastructure is handled elsewhere
The EKS cluster, networking, IAM, and database are provisioned in a separate Terraform-based platform repository.

### This repository manages runtime operations
This repo is responsible for:

- deploying workloads to Kubernetes
- environment-specific application manifests
- GitOps sync targets for ArgoCD
- monitoring and dashboards
- centralized logging
- distributed tracing
- backup and restore operations

This separation reflects a more realistic **platform engineering / GitOps workflow**.

---

## GitOps Workflow

ArgoCD continuously monitors this repository and synchronizes changes into the EKS cluster.

### Deployment Flow

```text
Developer / CI updates manifests
        ↓
Push to gitops-repo
        ↓
ArgoCD detects change
        ↓
Syncs manifests to EKS
        ↓
Workloads updated declaratively
```

---

## Benefits of this model
* Git is the source of truth
* environment changes are traceable
* rollbacks are simple through Git history
* cluster drift is reduced
* deployments are reproducible

---

# Repository Structure
```text
├── README.md
├── apps
│   ├── dev
│   │   ├── backend-dev.yaml
│   │   └── frontend-dev.yaml
│   ├── prod
│   │   ├── backend-prod.yaml
│   │   └── frontend-prod.yaml
│   └── staging
│       ├── backend-staging.yaml
│       └── frontend-staging.yaml
├── backup
│   ├── trust-policy-velero.json
│   ├── velero-policy.json
│   ├── velero-v1.17.1-linux-amd64
│   │   ├── LICENSE
│   │   └── examples
│   └── velero-v1.17.1-linux-amd64.tar.gz
├── images
│   ├── grafana-prod-monitoring.png
│   ├── loki-logs.png
│   ├── node-exporter-grafana.png
│   └── running nodes.png
├── k8s
│   ├── backend
│   │   ├── dev
│   │   │   ├── deployment.yaml
│   │   │   ├── ingress.yaml
│   │   │   ├── kustomization.yaml
│   │   │   └── service.yaml
│   │   ├── prod
│   │   │   ├── deployment.yaml
│   │   │   ├── ingress.yaml
│   │   │   ├── kustomization.yaml
│   │   │   └── service.yaml
│   │   └── staging
│   │       ├── deployment.yaml
│   │       ├── ingress.yaml
│   │       ├── kustomization.yaml
│   │       └── service.yaml
│   └── frontend
│       ├── dev
│       │   ├── deployment.yaml
│       │   ├── ingress.yaml
│       │   ├── kustomization.yaml
│       │   └── service.yaml
│       ├── prod
│       │   ├── deployment.yaml
│       │   ├── ingress.yaml
│       │   ├── kustomization.yaml
│       │   └── service.yaml
│       └── staging
│           ├── deployment.yaml
│           ├── ingress.yaml
│           ├── kustomization.yaml
│           └── service.yaml
├── logging
│   ├── configure-ebs-loki-irsa.sh
│   ├── loki-s3-policy.json
│   ├── loki-values.yaml
│   ├── trust-policy-ebs.json
│   └── trust-policy-loki.json
└── monitoring
    ├── grafana-ingress.yaml
    ├── high-cpu-alert.yaml
    ├── kubecost-ingress.yaml
    ├── kubecost-values.yaml
    └── otel-values.yaml
```

---

# Application Overview

The deployed application consists of:

* Frontend – React-based web interface
* Backend API – application service connected to PostgreSQL

Each environment includes Kubernetes manifests for:

* Deployments
* Services
* Ingress resources
* Namespace-specific workload configuration

# Environments

This repository manages deployments across three isolated Kubernetes namespaces.

| Environment | Namespace | Purpose                   |
| ----------- | --------- | ------------------------- |
| DEV         | dev       | Development testing       |
| STAGING     | staging   | Pre-production validation |
| PROD        | prod      | Production environment    |

Each environment is represented declaratively in Git and synchronized independently.

---

# Repository Design
## Why this repo is separate

This repository was intentionally separated from the infrastructure codebase to enforce a clean distinction between:

### Platform provisioning

Handled in Terraform:

* VPC
* EKS
* RDS
* IAM / OIDC / IRSA

### Runtime operations

Handled here in GitOps:

* Kubernetes manifests
* environment-specific deployment definitions
* observability stack
* logging
* tracing
* backup tooling

## Why this matters

This separation improves:

* maintainability
* auditability
* operational clarity
* deployment safety

It also mirrors how many engineering teams separate:

* platform / infrastructure concerns
* application delivery and runtime concerns

---

# Kubernetes Workload Layout

The k8s/ directory contains environment-specific manifests for both services.

## Backend

Each environment contains:

* deployment.yaml
* service.yaml
* ingress.yaml
* kustomization.yaml

## Frontend

Each environment contains:

* deployment.yaml
* service.yaml
* ingress.yaml
* kustomization.yaml

## Design Intent

This structure keeps deployments:

* isolated by environment
* easy to modify
* easy to audit
* GitOps-friendly

# ArgoCD Applications

The apps/ directory defines the ArgoCD application objects for each environment and workload.

### Examples include:

* backend-dev
* frontend-dev
* backend-staging
* frontend-staging
* backend-prod
* frontend-prod

## Purpose

These application definitions allow ArgoCD to:

* track workload state
* reconcile manifests
* surface sync health
* enable environment-level deployment visibility

# Observability Stack

This repository includes the operational components needed to observe and troubleshoot workloads running on EKS.

Observability is treated as a first-class operational concern, not an afterthought.

# Monitoring

Monitoring is implemented using Prometheus and Grafana.

## Components
* kube-prometheus-stack for Kubernetes and application metrics
* Grafana for dashboards and visualization
* alert definitions for key operational conditions
* ingress configuration for dashboard access
* optional cost visibility with Kubecost

## Monitoring Goals

The monitoring setup is intended to provide visibility into:

* pod health and restart behavior
* deployment rollout health
* node availability
* CPU / memory utilization
* namespace workload health
* cluster operational state

## Monitoring Files

Located in monitoring/:

* grafana-ingress.yaml
* high-cpu-alert.yaml
* kubecost-ingress.yaml
* kubecost-values.yaml
* otel-values.yaml

# Logging

Centralized logging is implemented using Grafana Loki.

## Logging Design

Logs are collected from Kubernetes workloads and made queryable in Grafana for troubleshooting and operational analysis.

### Capabilities
* centralized workload log aggregation
* namespace-based log filtering
* easier debugging across environments
* persistent log storage backed by Amazon S3

### Example Queries

Logs can be filtered in Grafana using labels such as:
```logql
{namespace="dev"}
```

```logql
{namespace="prod"}
```

### Logging Files

Located in logging/:

* loki-values.yaml
* loki-s3-policy.json
* trust-policy-ebs.json
* trust-policy-loki.json
* configure-ebs-loki-irsa.sh

## Design Notes

Loki is configured to use AWS-backed storage and IAM integration for secure access patterns.

# Tracing

Distributed tracing is implemented using Grafana Tempo.

## Purpose

Tracing provides request-level visibility across services and helps diagnose:

* slow requests
* backend dependency latency
* service-to-service bottlenecks
* end-to-end request behavior

This improves troubleshooting beyond what logs and metrics alone can provide.

# OpenTelemetry (OTel)

This repository includes support for OpenTelemetry-based instrumentation and telemetry collection.

## Purpose

OTel is used to unify collection of:

* metrics
* logs
* traces

### Benefits
* centralized telemetry pipeline
* consistent observability approach
* easier integration across Grafana ecosystem components

### Integrations

OpenTelemetry data is routed into:

* Prometheus for metrics
* Loki for logs
* Tempo for traces

# Backup & Disaster Recovery

This repository includes declarative backup and restore tooling using Velero.

## Backup Scope

Velero supports backup of:

* Kubernetes resources
* namespace workloads
* persistent volumes
* EBS-backed storage through snapshots

### Storage Strategy

Backups are stored in Amazon S3.

### Recovery Use Cases

This improves recovery readiness for scenarios such as:

* accidental namespace deletion
* broken workload deployments
* failed environment changes
* persistent volume recovery

### Backup Features
* scheduled backups
* on-demand backups
* namespace restore
* full cluster restore (where applicable)

### Backup Files

Located in backup/:

* trust-policy-velero.json
* velero-policy.json
* Velero installation assets

# Deployment Workflow

This repository participates in the deployment lifecycle as follows:

1. Application manifests are updated in Git
2. ArgoCD automatically synchronizes changes
3. Workloads are deployed into the target namespace
4. Health is observed through monitoring dashboards
5. Logs are collected in Loki
6. Traces are visualized in Tempo
7. Backups are maintained through Velero

This makes the runtime platform observable, traceable, and recoverable.

# CI/CD Integration

This repository works alongside the image promotion repository:

## Image Promotion Repository:
https://github.com/Uprightbalance/backend-frontend--DEV_TAG-IMAGE-promote-to-staging-prod-env.git

# Delivery Model

Images are promoted across:
```text
DEV → STAGING → PROD
```
This ensures the same validated image artifact is deployed across environments, improving release confidence and reducing deployment drift.

---

## Suggested Troubleshooting Scenarios

This repository also supports realistic operational testing and troubleshooting scenarios to validate that the platform is not only deployable, but also **observable, debuggable, and recoverable**.

These scenarios reflect the kinds of issues commonly encountered when operating Kubernetes workloads with GitOps and an observability stack.

---

### 1. High CPU Alert Validation

#### Example Cause
* application resource spike
* runaway process
* insufficient resource requests / limits
* intentionally generated load during testing

#### Symptoms
* Grafana / Prometheus alert fires
* CPU usage spikes on workload or node dashboard
* application may become slow or unstable

#### Troubleshooting Approach

Check current pod resource usage:

```bash
kubectl top pods -n dev
kubectl top nodes
```

Inspect the deployment resource settings:

```bash
kubectl describe deployment backend -n dev
```

#### Review Grafana dashboards for:

* pod CPU trend
* node CPU trend
* namespace resource usage

Validate whether the alert threshold is working as intended or needs tuning.

### What this validates
* monitoring and alerting functionality
* operational visibility
* workload performance troubleshooting

### 2. Missing Logs in Loki

#### Example Cause
* Promtail / log collector not running
* wrong scrape configuration
* namespace labels missing
* Loki ingestion or storage issue

#### Symptoms
* workloads are running, but logs do not appear in Grafana
* specific namespaces or pods have no visible logs
* queries return empty results

#### Troubleshooting Approach

Check whether log collection agents are running:

```bash
kubectl get pods -A | grep -i promtail
```

Inspect collector logs:

```bash
kubectl logs -n <logging-namespace> <collector-pod-name>
```

Check Loki pods and service health:
```bash
kubectl get pods -A | grep -i loki
kubectl get svc -A | grep -i loki
```

Validate Grafana query labels such as:

```logql
{namespace="dev"}
```

## What this validates
* centralized logging pipeline health
* log ingestion troubleshooting
* observability stack debugging

### 3. Tracing Pipeline Issues

#### Example Cause
* OpenTelemetry Collector misconfiguration
* Tempo endpoint mismatch
* app instrumentation not exporting traces
* collector pipeline failure

#### Symptoms
* application works normally, but traces do not appear in Grafana Tempo
* dashboards show metrics and logs, but no request traces
* service dependency visibility is missing

#### Troubleshooting Approach

Check OpenTelemetry Collector pods:

```bash
kubectl get pods -A | grep -i otel
```

Inspect collector logs:

```bash
kubectl logs -n <monitoring-namespace> <otel-collector-pod-name>
```

Validate Tempo service availability:

```bash
kubectl get svc -A | grep -i tempo
```
Review whether the application is configured to export traces to the correct OTLP endpoint.

Validate that:

* collector pipeline is active
* Tempo is reachable
* instrumentation is enabled in the application

### What this validates
* tracing pipeline troubleshooting
* OpenTelemetry debugging
* distributed observability validation

### Backup / Restore Validation

#### Example Cause
* backup job misconfiguration
* Velero storage access issue
* restore test fails due to missing objects or permissions

#### Symptoms
* expected backup does not appear
* restore operation fails or is incomplete
* namespace resources are not fully recovered

#### Troubleshooting Approach

Check Velero installation status:

```bash
kubectl get pods -n velero
```

List available backups:

```bash
velero backup get
```

Describe a specific backup:

```bash
velero backup describe <backup-name> --details
```

List restores:

```bash
velero restore get
```
Test recovery by restoring a non-critical namespace or workload in a controlled environment.

Also validate:

* Velero has access to the S3 backup bucket
* snapshot permissions are correct
* backed-up resources are restorable as expected

### What this validates
* backup integrity
* restore readiness
* disaster recovery confidence

---

# Screenshots
Grafana Monitoring

Node Metrics Dashboard

kubecost efficiency

Loki Logs

Running Nodes

# Future Improvements

Potential enhancements include:

* Kustomize overlays for cleaner environment inheritance
* External Secrets integration with AWS Secrets Manager
* automated backup verification
* SLO / SLA-based alerting
* synthetic health checks
* policy enforcement with Kyverno or OPA
* canary / progressive delivery with Argo Rollouts

# Key Takeaway

This repository demonstrates how to manage Kubernetes application delivery and runtime operations on EKS using a GitOps-first approach.

It combines:

* declarative deployments
* observability
* centralized logging
* tracing
* backup and restore
* environment promotion discipline

into a workflow that is much closer to a real platform operations model than a basic Kubernetes manifests repository.
