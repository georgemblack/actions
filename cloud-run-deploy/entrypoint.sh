#!/bin/sh

set -e

sanitize() {
  if [ -z "${1}" ]
  then
    >&2 echo "Unable to find ${2}. Did you configure your workflow correctly?"
    exit 1
  fi
}

sanitize "${INPUT_SERVICENAME}" "serviceName"
sanitize "${INPUT_GCLOUDPROJECTID}" "gcloudProjectId"
sanitize "${INPUT_GCLOUDSERVICEACCOUNT}" "gcloudServiceAccount"
sanitize "${INPUT_GCLOUDRUNTIMESERVICEACCOUNT}" "gcloudRuntimeServiceAccount"
sanitize "${GCLOUD_AUTH}" "GCLOUD_AUTH"

# Get version from timestamp
# Format: YYYYMMDDHHMMSS
PACKAGE_VERSION=$(date "+%Y%m%d%H%M%S")

# Set project
gcloud config set project ${INPUT_GCLOUDPROJECTID}

# Auth w/service account
echo ${GCLOUD_AUTH} | base64 --decode > ./key.json
gcloud auth activate-service-account --key-file=./key.json
rm ./key.json

# Submit build
gcloud builds submit \
  --gcs-log-dir gs://georgeblack-meta/cloud-build/logs \
  --gcs-source-staging-dir gs://georgeblack-meta/cloud-build/source \
  --tag gcr.io/${INPUT_GCLOUDPROJECTID}/${INPUT_SERVICENAME}:${PACKAGE_VERSION}

# Deploy
gcloud run deploy ${INPUT_SERVICENAME} \
  --concurrency 20 \
  --max-instances 200 \
  --memory 256Mi \
  --platform managed \
  --allow-unauthenticated \
  --service-account ${INPUT_GCLOUDRUNTIMESERVICEACCOUNT} \
  --region us-central1 \
  --image gcr.io/${INPUT_GCLOUDPROJECTID}/${INPUT_SERVICENAME}:${PACKAGE_VERSION}
