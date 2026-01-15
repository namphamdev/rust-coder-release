#!/bin/bash

# Configuration
REPO="namphamdev/rust-coder-release"
WORKFLOW="build_and_release.yml"
BRANCH="main"

# Check if GH CLI is installed
if ! command -v gh &> /dev/null;
then
    echo "Error: GitHub CLI (gh) is not installed."
    exit 1
fi

# 1. Fetch the latest release tag
echo "Fetching latest release..."
LATEST_TAG=$(gh api repos/$REPO/releases/latest --jq '.tag_name' 2>/dev/null)

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" == "null" ]; then
    echo "No releases found. Starting from v1.0.0"
    NEW_TAG="v1.0.0"
else
    echo "Current version: $LATEST_TAG"
    
    # 2. Increment the patch version (v1.0.0 -> v1.0.1)
    # This regex splits v1.0.0 into "v1.0." and "0"
    VERSION_PREFIX=$(echo $LATEST_TAG | grep -oE '^v[0-9]+\.[0-9]+\.')
    PATCH_VERSION=$(echo $LATEST_TAG | grep -oE '[0-9]+$')
    
    if [ -z "$PATCH_VERSION" ]; then
        echo "Error: Could not parse version '$LATEST_TAG'. Expected format like v1.0.0"
        exit 1
    fi
    
    NEW_PATCH=$((PATCH_VERSION + 1))
    NEW_TAG="${VERSION_PREFIX}${NEW_PATCH}"
fi

echo "Increasing version to: $NEW_TAG"

# 3. Trigger the workflow via API
echo "Triggering workflow $WORKFLOW..."
gh workflow run "$WORKFLOW" \
  --repo "$REPO" \
  --ref "$BRANCH" \
  -f tag_name="$NEW_TAG" \
  -f private_branch="main"

if [ $? -eq 0 ]; then
    echo "Successfully triggered release for $NEW_TAG"
    echo "You can monitor progress with: gh run list --workflow=$WORKFLOW"
else
    echo "Failed to trigger workflow."
    exit 1
fi
