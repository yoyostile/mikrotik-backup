# MikroTik Backup Script 🔄

This script is your one-stop solution 🛠️ to backing up the configuration of MikroTik routers/switches and uploading them to a GitHub repository. It's like a safety net 🥅 for your router configurations!

## 📋 What does the script do?

1. 🗝️ Uses SSH to connect to the routers.
2. 📤 Exports the configuration.
3. 🚫 With or without sensitive data.
4. 🔄 Checks for any changes since the last backup.
5. 📤 Uploads the modified configuration to GitHub if changes are detected.

## 🏗️ Prerequisites

- SSH access to the MikroTik routers.
- A GitHub repository to store the backups.
- A GitHub Personal Access Token with appropriate permissions.
- The routers' hostnames or IP addresses.

### 📦 Dependencies

This script relies on several software packages to function correctly:

- `curl`, `openssh-client`, `jq`, `git`

All these dependencies are installed in the Docker image, so you don't need to worry about them if you're running the script in a Docker container or a Kubernetes CronJob. If you're running the script directly on your system, make sure to install these dependencies first.

## 🌍 Environment Variables

The script uses the following environment variables:

- `GITHUB_TOKEN`: Your GitHub Personal Access Token.
- `MIKROTIK_KEY_PATH`: The SSH private key path to connect to the routers (defaults to ~/.ssh/id_rsa).
- `ROUTERS`: A space-separated list of the routers' hostnames or IP addresses.
- `GITHUB_REPO`: The GitHub repository to store the backups, in the format `username/repo`.
- `GITHUB_USER`: The username to be used for committing to the GitHub repository.
- `GITHUB_EMAIL`: The email to be used for committing to the GitHub repository.
- `SHOW_SENSITIVE`: Wether or not to export sensitive data (defaults to `false`).

## 🏃‍♀️ Usage

1. Set the environment variables mentioned above.
2. Run the script: `./backup.sh`

## 📝 Note

The script has been tested on Linux and should work on other Unix-like systems. However, it has not been tested on Windows.
Happy backing up! 💾🎉

## 🐳 Docker Support

This repository also includes a Dockerfile. You can build a Docker image and run this script inside a Docker container. This is especially useful if you want to run this script in environments that don't have bash or the necessary dependencies installed.

### 🏗️ Building the Docker image

You can build the Docker image by running the following command:

```bash
docker build -t mikrotik-backup .
```

### 🏃‍♀️ Running the Docker container

You can run the Docker container by running the following command:

```bash
docker run -e GITHUB_TOKEN=<your-token> -e MIKROTIK_SSH_KEY=<your-key> -e ROUTERS=<your-routers> -e GITHUB_REPO=<your-repo> -e GITHUB_USER=<your-username> -e GITHUB_EMAIL=<your-email> mikrotik-backup
```

Replace `<your-token>`, `<your-key>`, `<your-routers>`, `<your-repo>`, `<your-username>`, and `<your-email>` with your actual values. Note that in this case we're using the whole key inline, not a path to the key. 

## 🎡 Kubernetes CronJob

You can also use this Docker image in a Kubernetes CronJob to run backups on a schedule. Here is an example:

```yaml
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mikrotik-backup
  namespace: default
spec:
  schedule: "@hourly"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: mikrotik-backup
              image: yoyostile/mikrotik-backup:latest
              envFrom:
                - secretRef:
                    name: mikrotik-backup
          restartPolicy: OnFailure
```

In this example, the CronJob is scheduled to run every hour. The environment variables are loaded from a Secret named `mikrotik-backup`. Replace `yoyostile/mikrotik-backup:latest` with the name and tag of your Docker image. But of course, you can also use mine. 
