# Overview
This repository provides a step-by-step guide on configuring KEDA-scaled self-hosted GitHub runners as Azure Container Apps Jobs, using GitHub App authentication.

# Goals
- To provide easy-to-follow configuration steps suitable for learning and experimentation using Azure CLI.
- To help familiarise the reader with each individual Azure resource and component in the solution, how they interact together, and to raise noteworthy customisation options along the way.
- IaC based deployment options might be added later on, however, there is already a fantastic repo with an IaC deployment option [here](https://github.com/xmi-cs/aca-gh-actions-runner)

# Prerequisites
- An Azure subscription with priviledged access.
- A GitHub account.
- Familiarity with Azure resource deployment and GitHub repo configuration.

# Advantages of Azure Container Apps Jobs
- **Ephemeral Execution** - Each job runs in its own container which is created and destroyed whenever the job needs to execute.
- **Reduced Costs** -  Cost is based on job execution time as opposed to a VM that accrues cost even while idling.
- **Flexibility and Independence** - Dockerfiles and entrypoints can be customised to suit different jobs with different dependencies.
- **Auto-Scaling** - The KEDA scaler takes care of spinning up a new container whenever new jobs are queued.  Each job runs in its own container for parallel execution.

# Solution Diagram

# Configuration Steps

## GitHub 
1. Create a copy of this repo.  
[![Create a Copy](https://img.shields.io/badge/-Create%20a%20Copy-darkgreen)](https://github.com/ethorneloe/azure-apps-jobs-github-runners/generate)
3. Click on your GitHub profile icon at the top right, and go to `Settings -> Developer Settings -> GitHub Apps` and select `New GitHub App`
   *Note - If you want this app to be available in your GitHub Organisation, then you need to navigate to the settings for your GitHub Org, and then perform the remaining steps below from the org-based developer settings, rather than your personal developer settings.*
5. Give your app a name such as `Azure KEDA Scaled Runners`.  
   The website field isn't important to get the GitHub app working, it is just there to provide an option for people to get more informoation about your GitHub App.  You can just use `https://github.com` but another website might be more appropriate for your use case.
6. This GitHub App doesn't need a webhook, so that can be left unticked.
7. For the permissions, we will need the following:  
    - *Repository permissions*
        - `Actions` - `Read-only`
        - `Metadata` - `Read-only`

    - *Organization permissions*
        - `Administration` - `Read-only`
        - `Self-hosted runners` - `Read and write`

    Note: Later on, in the container apps job settings, the KEDA scaler can be configured for repo or org scope.
8. Finally, select `Only on this account` and then click on `Create GitHub App`.
9. There should be a notification to create a new private key at the top of the screen after your app is created. Click that link and create a new key.  Otherwise you can scroll down the page to the private keys section.
10. Now that the GitHub app is created, we need to install it and select the repos it will be available to.  Click on `Install App` and select the account to install the app to.  Depending on the context 


12. After the GitHub app is created there will be a 6 digit App ID. Take note of this as it will be used later on when creating the Azure apps job.



## Azure


## Testing the Solution
