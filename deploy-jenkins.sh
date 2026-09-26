#!/usr/bin/env bash
# Deploy Jenkins on OpenShift with dynamic pod agents
# Prereqs: oc (logged in), helm 3
set -euo pipefail

# Default: the project you're currently using (Developer Sandbox can't create new projects)
NAMESPACE="${NAMESPACE:-$(oc project -q)}"
RELEASE="${RELEASE:-jenkins}"

echo ">> Using project ${NAMESPACE}"
oc project "${NAMESPACE}"

command -v helm >/dev/null || { echo "helm is not installed: https://helm.sh/docs/intro/install/"; exit 1; }

echo ">> Adding Jenkins Helm repo"
helm repo add jenkins https://charts.jenkins.io >/dev/null 2>&1 || true
helm repo update

echo ">> Installing / upgrading Jenkins"
helm upgrade --install "${RELEASE}" jenkins/jenkins \
  -n "${NAMESPACE}" \
  -f jenkins-values.yaml \
  --wait --timeout 15m

echo ">> Exposing Jenkins with an HTTPS Route"
oc get route "${RELEASE}" -n "${NAMESPACE}" >/dev/null 2>&1 || \
  oc create route edge "${RELEASE}" --service="${RELEASE}" --port=http \
     --insecure-policy=Redirect -n "${NAMESPACE}"

HOST=$(oc get route "${RELEASE}" -n "${NAMESPACE}" -o jsonpath='{.spec.host}')
PASS=$(oc get secret "${RELEASE}" -n "${NAMESPACE}" -o jsonpath='{.data.jenkins-admin-password}' | base64 -d)

echo ">> Setting Jenkins URL to https://${HOST}"
helm upgrade "${RELEASE}" jenkins/jenkins -n "${NAMESPACE}" \
  -f jenkins-values.yaml \
  --set controller.jenkinsUrl="https://${HOST}" \
  --wait --timeout 15m

echo
echo "==============================================="
echo " Jenkins URL : https://${HOST}"
echo " User        : admin"
echo " Password    : ${PASS}"
echo "==============================================="
