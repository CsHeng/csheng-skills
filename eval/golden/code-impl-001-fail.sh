#!/usr/bin/env bash
# Deploy script for the application service.
# Copies build artifacts to the target host and restarts the service.

DEPLOY_USER=deploy
DEPLOY_HOST=$1
ARTIFACT_DIR=$2
REMOTE_DIR=/opt/app

if [ -z $DEPLOY_HOST ]; then
  echo "Usage: $0 <host> <artifact-dir>"
  exit 1
fi

if [ -z $ARTIFACT_DIR ]; then
  echo "Usage: $0 <host> <artifact-dir>"
  exit 1
fi

echo "Deploying to $DEPLOY_HOST from $ARTIFACT_DIR"

# Copy all artifacts to the remote host
scp -r $ARTIFACT_DIR/* $DEPLOY_USER@$DEPLOY_HOST:$REMOTE_DIR

# Restart the service on the remote host
ssh $DEPLOY_USER@$DEPLOY_HOST systemctl restart app.service

STATUS=$(ssh $DEPLOY_USER@$DEPLOY_HOST systemctl is-active app.service)

if [ $STATUS != "active" ]; then
  echo "ERROR: Service failed to start on $DEPLOY_HOST"
  exit 1
fi

echo "Deploy complete. Service is $STATUS on $DEPLOY_HOST"
