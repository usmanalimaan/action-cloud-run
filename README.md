# Github Action for Google Cloud Run branch deployments

Authenticate with gcloud, build and push image to GCR and deploy as a new revision or branch preview to Cloud Run.

## Usage

Docker image

In your actions workflow, somewhere after the checkout step insert this:

```yaml
- name: Deploy service to Cloud Run
  uses: schliflo/action-cloud-run@1.0.0
  with:
    project: [your-project]
    service_name: [your-service]
    key: ${{ secrets.GCP_CLOUD_RUN_SERVICE_KEY }}
    registry: [eu.gcr.io]
    region: [europe-west1]
    working_directory: [.]
    check_if_changed: [false]
    env: []
```

Your `GCP_CLOUD_RUN_SERVICE_KEY` secret (or whatever you name it) must be a base64 encoded
gcloud service key with the following permissions:

- Service Account User
- Cloud Run Admin
- Storage Admin
