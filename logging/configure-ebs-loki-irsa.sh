#!/bin/bash
set -e

AWS_ACCOUNT="010741811189"
REGION="us-east-1"
CLUSTER_NAME="dev-cluster>"

### 1️⃣ Create / update EBS CSI Role with IRSA trust policy ###

EBS_ROLE="AmazonEKS_EBS_CSI_DriverRole"

cat > trust-policy-ebs.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/2E58088C97D9DC9AFD533C6633E8C586"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${REGION}.amazonaws.com/id/2E58088C97D9DC9AFD533C6633E8C586:aud": "sts.amazonaws.com",
          "oidc.eks.${REGION}.amazonaws.com/id/2E58088C97D9DC9AFD533C6633E8C586:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF

# Check if role exists
if aws iam get-role --role-name $EBS_ROLE >/dev/null 2>&1; then
    echo "[INFO] Updating assume role policy for existing role $EBS_ROLE..."
    aws iam update-assume-role-policy --role-name $EBS_ROLE --policy-document file://trust-policy-ebs.json
else
    echo "[INFO] Creating EBS CSI IAM role $EBS_ROLE..."
    aws iam create-role --role-name $EBS_ROLE \
      --assume-role-policy-document file://trust-policy-ebs.json \
      --description "EBS CSI Driver IRSA role for EKS cluster $CLUSTER_NAME"
fi

# Attach managed policy
aws iam attach-role-policy --role-name $EBS_ROLE \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

echo "[OK] EBS CSI IAM role configured."

### 2️⃣ Annotate existing ServiceAccount ###
kubectl annotate sa ebs-csi-controller-sa \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT}:role/${EBS_ROLE} --overwrite

echo "[OK] ServiceAccount ebs-csi-controller-sa annotated with IAM role."

### 3️⃣ Loki S3 IAM policy ###
LOKI_POLICY_NAME="LokiS3AccessPolicy"

cat > loki-s3-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::prod-loki-chunks316",
        "arn:aws:s3:::prod-loki-ruler316",
        "arn:aws:s3:::prod-loki-admin316"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::prod-loki-chunks316/*",
        "arn:aws:s3:::prod-loki-ruler316/*",
        "arn:aws:s3:::prod-loki-admin316/*"
      ]
    }
  ]
}
EOF

# Create policy if it doesn’t exist
if ! aws iam list-policies --query "Policies[?PolicyName=='${LOKI_POLICY_NAME}'] | length(@)" --output text | grep -q 1; then
    aws iam create-policy --policy-name $LOKI_POLICY_NAME --policy-document file://loki-s3-policy.json
    echo "[OK] Created Loki S3 access policy."
else
    echo "[INFO] Loki S3 access policy already exists."
fi

# You can create a dedicated Loki IAM role and attach this policy
# Example: assume role for ServiceAccount using IRSA
LOKI_ROLE="LokiRole"
cat > trust-policy-loki.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/2E58088C97D9DC9AFD533C6633E8C586"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${REGION}.amazonaws.com/id/2E58088C97D9DC9AFD533C6633E8C586:sub": "system:serviceaccount:logging:loki"
        }
      }
    }
  ]
}
EOF

if aws iam get-role --role-name $LOKI_ROLE >/dev/null 2>&1; then
    echo "[INFO] Loki IAM role already exists. Updating assume role policy..."
    aws iam update-assume-role-policy --role-name $LOKI_ROLE --policy-document file://trust-policy-loki.json
else
    aws iam create-role --role-name $LOKI_ROLE \
      --assume-role-policy-document file://trust-policy-loki.json \
      --description "Loki S3 access role via IRSA"
fi

# Attach the S3 policy
aws iam attach-role-policy --role-name $LOKI_ROLE \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT}:policy/${LOKI_POLICY_NAME}

# Annotate Loki ServiceAccount
kubectl annotate sa loki -n logging \
  eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT}:role/${LOKI_ROLE} --overwrite

echo "[OK] Loki ServiceAccount annotated and IAM role attached."

### 4️⃣ Restart EBS CSI controller pods ###
kubectl delete pod -n kube-system -l app=ebs-csi-controller
echo "[INFO] Restarted EBS CSI controller pods. Wait until all are Running."

### Done ###
echo "[SUCCESS] IRSA roles for EBS CSI and Loki configured. PVCs and S3 access should work."
