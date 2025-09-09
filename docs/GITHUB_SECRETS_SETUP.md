# GitHub Secrets Setup Guide

This guide explains how to set up the required GitHub secrets for the CI/CD pipeline to work properly.

## Required Secrets

The CI/CD pipeline requires three GitHub secrets to be configured:

1. **DOCKERHUB_USERNAME** - Your Docker Hub username
2. **DOCKERHUB_TOKEN** - Your Docker Hub access token
3. **ARGOCD_PASSWORD** - ArgoCD admin password

## Setup Methods

### Method 1: Using the Helper Script (Recommended)

The easiest way to set up GitHub secrets is using the provided helper script:

```bash
./scripts/setup-github-secrets.sh -n <project-name>
```

This script will:
- Prompt you for the required credentials
- Automatically set the secrets in your GitHub repository
- Verify the setup

**Prerequisites:**
- GitHub CLI installed (`gh`)
- Logged in to GitHub CLI (`gh auth login`)

### Method 2: Manual Setup

If you prefer to set up secrets manually:

1. **Go to your repository's secrets page:**
   ```
   https://github.com/Bionic-AI-Solutions/<project-name>/settings/secrets/actions
   ```

2. **Add each secret:**
   - Click "New repository secret"
   - Enter the name and value for each secret

## Detailed Setup Instructions

### 1. Docker Hub Credentials

#### DOCKERHUB_USERNAME
- **What it is**: Your Docker Hub username
- **Where to find it**: Your Docker Hub profile (https://hub.docker.com)
- **Example**: `docker4zerocool`

#### DOCKERHUB_TOKEN
- **What it is**: A Docker Hub access token (NOT your password)
- **How to create**:
  1. Go to [Docker Hub Security Settings](https://hub.docker.com/settings/security)
  2. Click "New Access Token"
  3. Give it a descriptive name (e.g., "GitHub Actions - Project Name")
  4. Set permissions to "Read, Write, Delete"
  5. Click "Generate"
  6. **Copy the token immediately** (you won't be able to see it again)

### 2. ArgoCD Password

#### ARGOCD_PASSWORD
- **What it is**: The ArgoCD admin password
- **How to get it**:
  ```bash
  # Run this command on the Kubernetes cluster where ArgoCD is running
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
  ```
- **Note**: This password is generated when ArgoCD is first installed

## Verification

After setting up the secrets, you can verify they're configured correctly:

### Using GitHub CLI:
```bash
gh secret list --repo Bionic-AI-Solutions/<project-name>
```

### Using GitHub Web Interface:
1. Go to your repository's secrets page
2. You should see all three secrets listed

## Testing the Setup

To test if the secrets are working:

1. **Make a small change** to your project (e.g., update README.md)
2. **Commit and push** the change:
   ```bash
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main
   ```
3. **Check the GitHub Actions**:
   - Go to your repository's Actions tab
   - You should see a workflow run triggered
   - The workflow should successfully build and push the Docker image

4. **Check ArgoCD**:
   - Go to https://argocd.bionicaisolutions.com
   - Look for your application
   - It should automatically sync and deploy

## Troubleshooting

### Common Issues

#### "Docker login failed"
- **Cause**: Invalid Docker Hub credentials
- **Solution**: Verify your DOCKERHUB_USERNAME and DOCKERHUB_TOKEN are correct
- **Check**: Make sure you're using an access token, not your password

#### "ArgoCD login failed"
- **Cause**: Invalid ArgoCD password
- **Solution**: Re-run the kubectl command to get the current password
- **Check**: Make sure ArgoCD is running and accessible

#### "Repository not found"
- **Cause**: GitHub CLI not authenticated or wrong repository
- **Solution**: Run `gh auth login` and verify repository access

### Getting Help

If you encounter issues:

1. **Check the GitHub Actions logs** for detailed error messages
2. **Verify all secrets are set** using `gh secret list`
3. **Test Docker Hub access** manually:
   ```bash
   docker login -u <username> -p <token>
   ```
4. **Test ArgoCD access** manually:
   ```bash
   argocd login argocd.bionicaisolutions.com --username admin --password <password>
   ```

## Security Best Practices

- **Never commit secrets** to your repository
- **Use access tokens** instead of passwords where possible
- **Rotate tokens regularly** for security
- **Use least privilege** - only give necessary permissions
- **Monitor usage** - check Docker Hub and ArgoCD logs for unusual activity

## Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Docker Hub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
- [ArgoCD CLI Documentation](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
