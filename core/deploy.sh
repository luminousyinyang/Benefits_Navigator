#!/bin/bash
PROJECT_ID=$1
REGION="us-east1"
REPO_NAME="benefitsnavigator"
SERVICE_NAME="benefits-backend"

echo "Deploying to Project: $PROJECT_ID..."

# 1. Build and Push to Artifact Registry
# We use the region and repo name you set up in the Console
gcloud builds submit --tag ${REGION}-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$SERVICE_NAME . --project $PROJECT_ID

# 2. Deploy to Cloud Run
gcloud run deploy $SERVICE_NAME \
  --image ${REGION}-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$SERVICE_NAME \
  --region $REGION \
  --allow-unauthenticated \
  --port 8080 \
  --project $PROJECT_ID

echo "Deployment complete!"