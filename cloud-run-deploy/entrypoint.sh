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
sanitize "${INPUT_PROJECTID}" "projectId"
sanitize "${INPUT_SERVICEACCOUNT}" "serviceAccount"
sanitize "${INPUT_RUNTIMESERVICEACCOUNT}" "runtimeServiceAccount"
sanitize "${GCLOUD_AUTH}" "GCLOUD_AUTH"

# Set defaults
SERVICE_NAME=${INPUT_SERVICENAME}
PROJECT_ID=${INPUT_PROJECTID}
SERVICE_ACCOUNT=${INPUT_SERVICEACCOUNT}
RUNTIME_SERVICE_ACCOUNT=${INPUT_RUNTIMESERVICEACCOUNT}
REGION=${INPUT_REGION:='us-central1'}
CONCURRENCY=${INPUT_CONCURRENCY:='20'}
MAX_INSTANCES=${INPUT_MAXINSTANCES:='200'}

# Get version from timestamp
# Format: YYYYMMDDHHMMSS
PACKAGE_VERSION=$(date "+%Y%m%d%H%M%S")

# Set project
gcloud config set project ${PROJECT_ID}

# Auth w/service account
echo ${GCLOUD_AUTH} | base64 --decode > ./key.json
gcloud auth activate-service-account --key-file=./key.json
rm ./key.json

# Submit build
gcloud builds submit \
  --gcs-log-dir gs://georgeblack-meta/cloud-build/logs \
  --gcs-source-staging-dir gs://georgeblack-meta/cloud-build/source \
  --tag gcr.io/${PROJECT_ID}/${SERVICE_NAME}:${PACKAGE_VERSION}

# Deploy to Cloud Run
gcloud run deploy ${SERVICE_NAME} \
  --concurrency ${CONCURRENCY} \
  --max-instances ${MAX_INSTANCES} \
  --memory 256Mi \
  --platform managed \
  --allow-unauthenticated \
  --service-account ${RUNTIME_SERVICE_ACCOUNT} \
  --region ${REGION} \
  --image gcr.io/${PROJECT_ID}/${SERVICE_NAME}:${PACKAGE_VERSION}
