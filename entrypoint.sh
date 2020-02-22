#!/bin/sh

HAS_CHANGED=true
IMAGE_POSTFIX=""

if [ "$INPUT_WORKING_DIRECTORY" != "." ]; then
    IMAGE_POSTFIX="/${INPUT_WORKING_DIRECTORY}"
fi

if [ "$INPUT_CHECK_IF_CHANGED" ]; then
    HAS_CHANGED=$(./gitdiff.sh ${INPUT_WORKING_DIRECTORY})
fi

if [ $HAS_CHANGED = false ]; then
    exit 0;
fi

set -e

BRANCH=$(echo $GITHUB_REF | rev | cut -f 1 -d / | rev)
GCR_IMAGE_NAME=${INPUT_REGISTRY}/${INPUT_PROJECT}/${GITHUB_REPOSITORY}${IMAGE_POSTFIX}
SERVICE_NAME=${INPUT_SERVICE_NAME}--${BRANCH}

echo "\n\n-----------------------------------------------------------------------------\n\n"
echo "BRANCH = ${BRANCH}"
echo "GCR_IMAGE_NAME = ${GCR_IMAGE_NAME}"
echo "SERVICE_NAME = ${SERVICE_NAME}"
echo "\n\n-----------------------------------------------------------------------------\n\n"

# service key

echo "$INPUT_GCP_SERVICE_KEY" | base64 --decode > "${HOME}/gcloud.json"

# Prepare env vars if `env` is set to file

if [ "$INPUT_ENV" ]; then
    ENVS=$(cat "$INPUT_ENV" | xargs | sed 's/ /,/g')
fi

if [ "$ENVS" ]; then
    ENV_FLAG="--set-env-vars $ENVS"
fi

# run

echo "\nActivate service account..."
gcloud auth activate-service-account \
  --key-file="${HOME}/gcloud.json" \
  --project "${INPUT_PROJECT}"

echo "\nConfigure gcloud cli..."
gcloud config set disable_prompts true
gcloud config set project "${INPUT_PROJECT}"
gcloud config set run/region "${INPUT_REGION}"
gcloud config set run/platform managed

echo "\nConfigure docker..."
gcloud auth configure-docker --quiet

cd ${GITHUB_WORKSPACE}/${INPUT_WORKING_DIRECTORY}

echo "\nBuild image..."
docker build \
  -t ${GCR_IMAGE_NAME}:${GITHUB_SHA} \
  -t ${GCR_IMAGE_NAME}:${BRANCH} \
  --build-arg IMAGE_NAME=${GCR_IMAGE_NAME} \
  --build-arg BRANCH_NAME=${BRANCH} \
  .

echo "\nPush image..."
docker push "$GCR_IMAGE_NAME"

echo "\nDeploy to cloud run..."
gcloud beta run deploy ${SERVICE_NAME} \
  --image "${GCR_IMAGE_NAME}:${GITHUB_SHA}" \
  --region "${INPUT_REGION}" \
  --platform managed \
  --allow-unauthenticated \
  ${ENV_FLAG}
