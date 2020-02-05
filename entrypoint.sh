#!/bin/sh

set -e

BRANCH=$(echo $GITHUB_REF | rev | cut -f 1 -d / | rev)
LOCAL_IMAGE_NAME=${GITHUB_REPOSITORY}_${INPUT_WORKING_DIRECTORY}:${GITHUB_SHA}
GCR_IMAGE_NAME=${INPUT_REGISTRY}/${INPUT_PROJECT}/${LOCAL_IMAGE_NAME}
SERVICE_NAME=${INPUT_WORKING_DIRECTORY}_${BRANCH}

# service key

echo "$INPUT_SERVICE_KEY" | base64 --decode > "$HOME"/gcloud.json

# Prepare env vars if `env` is set to file 

if [ "$INPUT_ENV" ]
then
    ENVS=$(cat "$INPUT_ENV" | xargs | sed 's/ /,/g')
fi

if [ "$ENVS" ]
then
    ENV_FLAG="--set-env-vars $ENVS"
else
    # ENV_FLAG="--clear-env-vars"
fi

# run 

gcloud auth activate-service-account --key-file="$HOME"/gcloud.json --project "$INPUT_PROJECT"
gcloud auth configure-docker

cd $INPUT_WORKING_DIRECTORY

docker build -t ${LOCAL_IMAGE_NAME} .
docker tag ${LOCAL_IMAGE_NAME} ${GCR_IMAGE_NAME}
docker push "$GCR_IMAGE_NAME"

gcloud beta run deploy "$SERVICE_NAME" \
  --image "$GCR_IMAGE_NAME" \
  --region "$INPUT_REGION" \
  --platform managed \
  --allow-unauthenticated \
  ${ENV_FLAG}
