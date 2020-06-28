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
sanitize "${INPUT_RUNTIMESERVICEACCOUNT}" "runtimeServiceAccount"
sanitize "${INPUT_CLOUDBUILDBUCKET}" "cloudBuildBucket"
sanitize "${GCLOUD_AUTH}" "GCLOUD_AUTH"

# Set defaults
SERVICE_NAME=${INPUT_SERVICENAME}
PROJECT_ID=${INPUT_PROJECTID}
RUNTIME_SERVICE_ACCOUNT=${INPUT_RUNTIMESERVICEACCOUNT}
CLOUD_BUILD_BUCKET=${INPUT_CLOUDBUILDBUCKET}
REGION=${INPUT_REGION:='us-central1'}
CONCURRENCY=${INPUT_CONCURRENCY:='100'}
MAX_INSTANCES=${INPUT_MAXINSTANCES:='100'}

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
  --gcs-log-dir gs://${CLOUD_BUILD_BUCKET}/logs \
  --gcs-source-staging-dir gs://${CLOUD_BUILD_BUCKET}/source \
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
