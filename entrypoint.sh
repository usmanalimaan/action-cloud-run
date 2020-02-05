#!/bin/sh

HAS_CHANGED=true

if [ "$INPUT_CHECK_IF_CHANGED" ]; then
    HAS_CHANGED=$(./gitdiff.sh ${INPUT_WORKING_DIRECTORY})
fi

if [ $HAS_CHANGED = false ]; then
    exit 0;
fi

set -e

BRANCH=$(echo $GITHUB_REF | rev | cut -f 1 -d / | rev)
LOCAL_IMAGE_NAME=${GITHUB_REPOSITORY}_${INPUT_WORKING_DIRECTORY}:${GITHUB_SHA}
GCR_IMAGE_NAME=${INPUT_REGISTRY}/${INPUT_PROJECT}/${LOCAL_IMAGE_NAME}
SERVICE_NAME=${INPUT_SERVICE_NAME}--${BRANCH}

echo "BRANCH = ${BRANCH}"
echo "LOCAL_IMAGE_NAME = ${LOCAL_IMAGE_NAME}"
echo "GCR_IMAGE_NAME = ${GCR_IMAGE_NAME}"
echo "SERVICE_NAME = ${SERVICE_NAME}"

# service key

echo "$INPUT_GCP_SERVICE_KEY" | base64 --decode > "$HOME"/gcloud.json

# Prepare env vars if `env` is set to file 

if [ "$INPUT_ENV" ]; then
    ENVS=$(cat "$INPUT_ENV" | xargs | sed 's/ /,/g')
fi

if [ "$ENVS" ]; then
    ENV_FLAG="--set-env-vars $ENVS"
fi

# run 

echo "\nActivate service account..."
gcloud auth activate-service-account --key-file="$HOME"/gcloud.json --project "$INPUT_PROJECT"

echo "\nConfigure docker..."
gcloud auth configure-docker --quiet

cd ${GITHUB_WORKSPACE}/${INPUT_WORKING_DIRECTORY}

echo "\nBuild image..."
docker build -t ${LOCAL_IMAGE_NAME} .
echo "\nTag image..."
docker tag ${LOCAL_IMAGE_NAME} ${GCR_IMAGE_NAME}
echo "\nPush image..."
docker push "$GCR_IMAGE_NAME"

echo "\nDeploy to cloud run..."
gcloud beta run deploy "$SERVICE_NAME" \
  --image "$GCR_IMAGE_NAME" \
  --region "$INPUT_REGION" \
  --platform managed \
  --allow-unauthenticated \
  ${ENV_FLAG}
