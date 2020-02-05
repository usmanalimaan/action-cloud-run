# Github Action for Google Cloud Run

An GitHub Action for deploying revisions to Google Cloud Run.

## Usage

Docker image

In your actions workflow, somewhere after the step that builds
`gcr.io/<your-project>/<image>`, insert this:

```bash
- name: Deploy service to Cloud Run
  uses: stefda/action-cloud-run@1.0.0
  with:
    working_directory: [service-api]
    service_key: ${{ secrets.GCP_CLOUD_RUN_SERVICE_KEY }}
    project: [your-project]
    registry: [eu.gcr.io]
    region: [gcp-region]
    env: [path-to-env-file]
```

Your `GCP_CLOUD_RUN_SERVICE_KEY` secret (or whatever you name it) must be a base64 encoded
gcloud service key with the following permissions:

- Service Account User
- Cloud Run Admin
- Storage Admin

The `env` input is optional.

<!-- If you don't provide a path to env file the run deployment will be triggered with the `--clear-env-vars` flag. -->
