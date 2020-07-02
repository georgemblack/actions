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
sanitize "${INPUT_RUNTIMESERVICEACCOUNT}" "runtimeServiceAccount"
sanitize "${GCLOUD_AUTH}" "GCLOUD_AUTH"

# Set defaults
SERVICE_NAME=${INPUT_SERVICENAME}
RUNTIME_SERVICE_ACCOUNT=${INPUT_RUNTIMESERVICEACCOUNT}
REGION=${INPUT_REGION:='us-central1'}
CONCURRENCY=${INPUT_CONCURRENCY:='default'}
MAX_INSTANCES=${INPUT_MAXINSTANCES:='default'}

# Get version from timestamp
# Format: YYYYMMDDHHMMSS
PACKAGE_VERSION=$(date "+%Y%m%d%H%M%S")

# Auth w/service account
echo ${GCLOUD_AUTH} | base64 --decode > ./key.json
gcloud auth activate-service-account --key-file=./key.json
rm ./key.json

PROJECT_ID=$(gcloud config get-value project)

# Submit build
gcloud builds submit \
  --config=cloudbuild.yaml \
  --substitutions=_IMAGE="${SERVICE_NAME}:${PACKAGE_VERSION}" .

# Deploy to Cloud Run
gcloud run deploy ${SERVICE_NAME} \
  --concurrency ${CONCURRENCY} \
  --max-instances ${MAX_INSTANCES} \
  --memory 256Mi \
  --platform managed \
  --allow-unauthenticated \
  --service-account ${RUNTIME_SERVICE_ACCOUNT} \
  --region ${REGION} \
  --image us-east1-docker.pkg.dev/${PROJECT_ID}/private/${SERVICE_NAME}:${PACKAGE_VERSION}
