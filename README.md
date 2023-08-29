# MikroTik Backup Script 🚀

This script is used to backup the configuration of MikroTik routers and switches running RouterOS and upload them to a GitHub repository. It uses SSH to connect to the routers, exports the configuration, optionally with sensitive data, and then uploads the modified configuration to GitHub if changes are detected.

## Prerequisites 👆

- SSH access to the MikroTik routers
- A GitHub repository to store the backups
- A GitHub Personal Access Token with appropriate permissions
- The routers' hostnames or IP addresses

## Environment Variables 📖

The script uses the following environment variables:

- `GITHUB_TOKEN`: Your GitHub Personal Access Token
- `MIKROTIK_SSH_KEY`: The SSH private key to connect to the routers
- `MIKROTIK_SSH_USER`: The username to be used for connecting to the router
- `ROUTERS`: A space-separated list of the routers' hostnames or IP addresses
- `SHOW_SENSITIVE`: Wether or not to include sensitive data in the backups
- `GITHUB_REPO`: The GitHub repository to store the backups, in the format `username/repo`
- `GITHUB_USER`: The username to be used for committing to the GitHub repository
- `GITHUB_EMAIL`: The email to be used for committing to the GitHub repository

## Usage ⌛️

1. Set the environment variables mentioned above.
2. Run the script: `./backup.sh`

## Note 💡

The script will only upload a new backup to GitHub if the configuration has changed since the last backup.

The script has been tested on Linux and should work on other Unix-like systems. However, it has not been tested on Windows.
