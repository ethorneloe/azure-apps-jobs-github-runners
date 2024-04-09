# Overview
This repository provides a step-by-step guide on configuring KEDA-scaled self-hosted GitHub runners as Azure Container Apps Jobs, using GitHub App authentication.

# Goals
- To provide easy-to-follow configuration steps suitable for learning and experimentation using Azure CLI.
- To help familiarise the reader with each individual Azure resource and component in the solution, how they interact together, and to raise noteworthy customisation options along the way.
- IaC based deployment options might be added later on, however, there is already a repo providing a more automated approach [here](https://github.com/xmi-cs/aca-gh-actions-runner)

# Prerequisites
- An Azure subscription with priviledged access.
- A GitHub account.
- Familiarity with Azure resource deployment and GitHub repo configuration.
- A workstation with Azure CLI installed

# Advantages of Azure Container Apps Jobs
- **Ephemeral Execution** - Each job runs in its own container which is created and destroyed whenever the job needs to execute.
- **Reduced Costs** -  Cost is based on job execution time as opposed to a VM that accrues cost even while idling.
- **Flexibility and Independence** - Dockerfiles and entrypoints can be customised to suit different jobs with different dependencies.
- **Auto-Scaling** - The KEDA scaler takes care of spinning up a new container whenever new jobs are queued.  Each job runs in its own container for parallel execution.

# Architecture
![keda-scaled-runners drawio (3)](https://github.com/ethorneloe/azure-apps-jobs-github-runners/assets/129253602/2f21154e-6643-4454-8967-0a045fe950ef)

# Configuration Steps

## GitHub 
1. Create a copy of this repo.  
[![Create a Copy](https://img.shields.io/badge/-Create%20a%20Copy-darkgreen)](https://github.com/ethorneloe/azure-apps-jobs-github-runners/generate)
2. Click on your GitHub profile icon at the top right, and go to `Settings -> Developer Settings -> GitHub Apps` and select `New GitHub App`  
   *Note - If you want this app to be available in your GitHub Organisation, then you need to navigate to the settings for your GitHub Org, and then perform the remaining steps below from the org-based developer settings, rather than your personal developer settings.*
3. Give your app a name such as `Azure KEDA Scaled Runners`.  
   The website field isn't important to get the GitHub app working, it is just there to provide an option for people to get more informoation about your GitHub App.  You can just use `https://github.com` but another website might be more appropriate for your use case.
4. This GitHub App doesn't need a webhook, so that can be left unticked.
5. For the permissions, we will need the following:  
    - *Repository permissions*
        - `Actions` - `Read-only`
        - `Metadata` - `Read-only`

    - *Organization permissions*
        - `Administration` - `Read-only`
        - `Self-hosted runners` - `Read and write`

    Note: Later on, in the container apps job settings, the KEDA scaler can be configured for repo or org scope.
6. Finally, select `Only on this account` and then click on `Create GitHub App`.
7. After the app is created, there should be a notification to create a new private key at the top of the screen. Click that link and select `Generate a private key`. If there was no notification, simply scroll down the page to the private keys section.  The private key will automatically download into your browser's downloads directory.  Move that to somewhere safe and take note of the filepath, which we will use later with the Azure apps job.
8. At the top of the GitHub App config page, there will be an App ID.  Take note of this as it will be used later for the Azure apps job.
9. Now that the GitHub app is created, we must install it to an account and select the repos it will be available to.  Click on `Install App` at the left-side of the GitHub App settings page, select the account to install the app on, and click on `Install`.  
*Note - Depending on your context you will be choosing a personal account or a GitHub Organisation. Also note that if your app is private and you created your GitHub app with an organisation context, and you want to do this in multiple orgs under the same Enterprise then you will need to create and deploy the app in each org in your GitHub Enterprise instance.*
10. Now select the repos you want this app to work with.  As a minimum, select the repo you created earlier from this template repo and click on `Install`.
11. You will now see the config page representing the installation of the app.  The URL should look similar to this:
    ```
    https://github.com/settings/installations/12345678
    ```  
    Take note of the last 8 digits of this URL as that is the `InstallationID` of the app we will use later on for configuring the Azure apps job
12. If all has gone well, you should have a new GitHub App installed to your account(*personal or org based on your choice*), and you should have:
  - An `App ID`
  - An `Installation ID`
  - A filepath to the GitHub App private key saved earlier on.

## Docker
The docker file in this repo uses GitHub's runner image taken from `ghcr.io/actions/actions-runner`.  From there `Powershell 7`, `Azure CLI`, `Az Module` are added and `entrypoint.sh` gets copied into the image, which is the script that will execute when the container spins up. This entrypoint script connects to the GitHub API with GitHub App-based authentication to register the ephemeral self-hosted runner, which will then pick up a queued job and execute inside the Azure container apps job replica.  The script is based on the GitHub doco here:
- https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api?apiVersion=2022-11-28
- https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app



## Azure

1. 


## Testing the Solution
