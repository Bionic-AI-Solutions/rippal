# Local GitHub Actions Testing with Act

This document explains how to test GitHub Actions workflows locally using the `act` tool, which allows you to run GitHub Actions in a Docker environment on your local machine.

## What is Act?

`act` is a tool that runs GitHub Actions locally using Docker. It simulates the GitHub Actions environment, allowing you to test workflows before pushing to GitHub.

## Installation

Act is already installed in this project. If you need to install it elsewhere:

```bash
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
sudo mv ./bin/act /usr/local/bin/ && chmod +x /usr/local/bin/act
```

## Configuration

The project includes a `.actrc` configuration file that sets up:
- Docker images for different Ubuntu versions
- Verbose output for debugging
- Platform architecture settings

## Usage

### List Available Workflows

```bash
act --list
```

### Run a Specific Job

```bash
# Run the code-quality job
act -j code-quality

# Run the test job
act -j test

# Run the build job
act -j build
```

### Run All Jobs

```bash
# Run all jobs for push event
act

# Run all jobs for pull_request event
act pull_request
```

### Debug Mode

```bash
# Run with verbose output
act -j code-quality --verbose

# Run with debug output
act -j code-quality --debug
```

## Benefits of Local Testing

1. **Faster Feedback**: Test workflows locally without pushing to GitHub
2. **Cost Savings**: Avoid using GitHub Actions minutes for testing
3. **Debugging**: Easier to debug issues in a local environment
4. **Iteration**: Quickly iterate on workflow changes

## Common Issues and Solutions

### Docker Image Issues

If you encounter Docker image issues:

```bash
# Pull the latest act images
act --pull

# Use specific platform
act --container-architecture linux/amd64
```

### Permission Issues

If you encounter permission issues:

```bash
# Run with sudo if needed
sudo act -j code-quality
```

### Environment Variables

To pass environment variables to act:

```bash
# Create a .secrets file
echo "MY_SECRET=value" > .secrets

# Act will automatically load .secrets file
act -j code-quality
```

## Workflow Development Best Practices

1. **Test Locally First**: Always test workflows with `act` before pushing
2. **Use Specific Jobs**: Test individual jobs rather than entire workflows
3. **Debug Verbosely**: Use `--verbose` flag to see detailed output
4. **Check Dependencies**: Ensure all required files and configurations exist
5. **Validate Syntax**: Use `act --list` to validate workflow syntax

## Integration with Development Workflow

1. Make changes to `.github/workflows/*.yml`
2. Test locally with `act -j <job-name>`
3. Fix any issues found locally
4. Commit and push changes
5. Monitor GitHub Actions for final validation

## Troubleshooting

### Common Error Messages

- **"eslint: not found"**: Missing dependencies in Docker container
- **"Could not find config"**: Missing configuration files
- **"Permission denied"**: Docker permission issues

### Getting Help

- Check the [act documentation](https://github.com/nektos/act)
- Use `act --help` for command options
- Enable verbose mode for detailed debugging

## Example Commands

```bash
# Test code quality checks
act -j code-quality

# Test with specific event
act push

# Test with environment variables
act -j test --env-file .env

# Test with secrets
act -j deploy --secret-file .secrets
```

This local testing approach ensures that GitHub Actions workflows work correctly before they're executed in the cloud, saving time and resources while providing faster feedback during development.
