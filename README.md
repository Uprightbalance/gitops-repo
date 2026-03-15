# GitOps Repository for Cloud-Native Application on EKS

This repository manages **GitOps-driven deployments** of a containerized Dry Cleaning Web Application across **DEV → STAGING → PROD** environments on Amazon EKS.  

All deployments are declarative and automated via ArgoCD, ensuring reproducible environments, traceable changes, and rollback capability.

---

## Repository Overview
```
├── README.md
├── apps
│   ├── dev
│   │   ├── backend-dev.yaml
│   │   └── frontend-dev.yaml
│   ├── prod
│   │   ├── backend-prod.yaml
│   │   └── frontend-prod.yaml
│   └── staging
│       ├── backend-staging.yaml
│       └── frontend-staging.yaml
├── images
│   └── images
├── k8s
│   ├── backend
│   │   ├── dev
│   │   │   ├── deployment.yaml
│   │   │   ├── ingress.yaml
│   │   │   ├── kustomization.yaml
│   │   │   └── service.yaml
│   │   ├── prod
│   │   │   ├── deployment.yaml
│   │   │   ├── ingress.yaml
│   │   │   ├── kustomization.yaml
│   │   │   └── service.yaml
│   │   └── staging
│   │       ├── deployment.yaml
│   │       ├── ingress.yaml
│   │       ├── kustomization.yaml
│   │       └── service.yaml
│   └── frontend
│       ├── dev
│       │   ├── deployment.yaml
│       │   ├── ingress.yaml
│       │   ├── kustomization.yaml
│       │   └── service.yaml
│       ├── prod
│       │   ├── deployment.yaml
│       │   ├── ingress.yaml
│       │   ├── kustomization.yaml
│       │   └── service.yaml
│       └── staging
│           ├── deployment.yaml
│           ├── ingress.yaml
│           ├── kustomization.yaml
│           └── service.yaml
├── logging
│   ├── configure-ebs-loki-irsa.sh
│   ├── loki-s3-policy.json
│   ├── loki-values.yaml
│   ├── trust-policy-ebs.json
│   └── trust-policy-loki.json
└── monitoring
    ├── grafana-ingress.yaml
    └── high-cpu-alert.yaml
```
---

## Application Overview

The application consists of:

- **Frontend** – React-based web interface.  
- **Backend API** – RESTful service with PostgreSQL database.  

Each environment namespace contains:

- Backend and frontend deployments  
- Services and ingress resources  
- Configured monitoring and logging  

---

## GitOps Deployment (ArgoCD)

ArgoCD monitors this repository and automatically synchronizes changes to the EKS cluster.

Workflow:

1. Developer pushes changes to `gitops-repo`.  
2. ArgoCD detects the changes.  
3. Manifests are applied to the corresponding Kubernetes environment (DEV, STAGING, PROD).  
4. Deployment history is fully auditable via Git.  
5. Rollbacks can be performed by reverting manifests in Git.  

---

## Monitoring

- **Prometheus / kube-prometheus-stack** is deployed to monitor cluster and application metrics.  
- **Grafana** is deployed for dashboards and alert visualization.  
- High CPU or critical events trigger alerts defined in `monitoring/high-cpu-alert.yaml`.  
- Grafana ingress is configured in `monitoring/grafana-ingress.yaml` for web access.  

---

## Logging

- **Grafana Loki** is used for centralized log aggregation.  
- Loki stores logs in S3 via IRSA-enabled EBS/IAM roles.  
- Promtail (or Fluent Bit) is deployed to forward container logs to Loki.  
- Loki configuration and IAM policies are in the `logging/` directory:  

  - `loki-values.yaml` – Helm values for Loki deployment  
  - `trust-policy-ebs.json` – EBS IRSA trust policy  
  - `trust-policy-loki.json` – Loki S3 IAM trust policy  
  - `loki-s3-policy.json` – S3 bucket permissions for Loki  

- Logs can be queried in Grafana using `{namespace="dev"}` or `{namespace="prod"}`.  

---

## Namespaces & Environments

| Environment | Namespace | Purpose |
|-------------|-----------|---------|
| DEV         | dev       | Development / testing |
| STAGING     | staging   | Pre-production validation |
| PROD        | prod      | Production workload |

---

## Deployment Workflow

1. Application manifests are updated in this repo.  
2. ArgoCD automatically synchronizes the environment namespace.  
3. Monitored via Prometheus/Grafana dashboards.  
4. Logs collected and aggregated via Loki.  

---

## CI/CD Integration

- Works in tandem with the **Image Promotion Repository**:  
  [backend-frontend--DEV_TAG-IMAGE-promote-to-staging-prod-env](https://github.com/Uprightbalance/backend-frontend--DEV_TAG-IMAGE-promote-to-staging-prod-env.git)  
- Images are promoted **DEV → STAGING → PROD** ensuring the same artifact is deployed across environments.  

