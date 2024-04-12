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
- **Reduced Costs** -  Cost is based on job execution time. No need to pay for idling compute resources while they wait for jobs.
- **Flexibility and Independence** - Dockerfiles and entrypoints can be customised to suit different jobs with different dependencies.
- **Auto-Scaling** - The KEDA scaler takes care of spinning up a new container whenever new jobs are queued.  Each job runs in its own container for parallel execution.

# Architecture
![keda-scaled-runners drawio (3)](https://github.com/ethorneloe/azure-apps-jobs-github-runners/assets/129253602/2f21154e-6643-4454-8967-0a045fe950ef)

# Configuration Steps

## GitHub 
1. Create a copy of this repo, using the button below.  When the repo creation page comes up, set the scope of the repo to private.
[![Create a Copy](https://img.shields.io/badge/-Create%20a%20Copy-darkgreen)](https://github.com/ethorneloe/azure-apps-jobs-github-runners/generate)
2. Click on your GitHub profile icon at the top right, and go to `Settings -> Developer Settings -> GitHub Apps` and select `New GitHub App`  
   *Note - If you want this app to be available in your GitHub Organisation, then you need to navigate to the settings for your GitHub Org, and then perform the remaining steps below from the org-based developer settings, rather than your personal developer settings.*
3. Give your app a name such as `Azure KEDA Scaled Runners`.  
   The website field isn't important to get the GitHub App working, it is just there to provide an option for people to get more information about your GitHub App.  You can just use `https://github.com` but another website might be more appropriate for your use case.
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

### Configure Variables, Key Vault, and User-Assigned Managed Identity

1. Make sure you have the latest version of Azure CLI installed.
   ```
   az upgrade
   ```
   More details on installation can be found [here](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
   <br /><br />
1. Add the containerapp extension.
   ```
   az extension add -n containerapp
   ```
   <br />
1. Log into Azure.
   ```
   az login --only-show-errors --output none
   ```
   <br />
1. Save your subscription ID to a variable.

   PowerShell
   ```
   $SUBSCRIPTION_ID = az account show --query "id" -o tsv
   ```

   Bash
   ```
   SUBSCRIPTION_ID = az account show --query "id" -o tsv
   ```
   <br />
1. Place `Dockerfile` and `entrypoint.sh`(included in this repo) together into a local folder.  Fill in values for the variables below and execute.
    
   PowerShell
   ```powershell
   $DOCKERFILE_PATH='<Local path that contains your Dockerfile(just the containing folder without the filename)>'
   $GITHUB_APP_ID='<Your GitHub App ID from earlier in this guide>'
   $GITHUB_INSTALLATION_ID='<Your GitHub Installation ID from earlier in this guide>'
   $LOCAL_PEM_FILE_PATH='<Path to your .pem file from earlier in this guide(full path including filename)>'
   $LOCATION='<Your Preferred Azure Location>'
   $REPO_OWNER='<Your GitHub Account Name>'
   $REPO_NAME='<Your repo name>'
   ```
   
   Bash
   ```Bash
   DOCKERFILE_PATH='<Local path that contains your Dockerfile(just the containing folder without the filename)>'
   GITHUB_APP_ID='<Your GitHub App ID from earlier in this guide>'
   GITHUB_INSTALLATION_ID='<Your GitHub Installation ID from earlier in this guide>'
   LOCAL_PEM_FILE_PATH='<Path to your .pem file from earlier in this guide(full path including filename)>'
   LOCATION='<Your Preferred Azure Location>'
   REPO_OWNER='<Your GitHub Account Name>'
   REPO_NAME='<Your repo name>'
   ```
   <br />
1. Execute this as is, or feel free to change the naming convention as required.
   
   PowerShell    
   ```powershell
   $RANDOM_5_DIGITS = -join (('0123456789abcdefghijklmnopqrstuvwxyz').ToCharArray() | Get-Random -Count 5)
   $CONTAINER_IMAGE_NAME='github-actions-runner:1.0'
   $CONTAINER_REGISTRY_NAME="acrcajgithubrunners$RANDOM_5_DIGITS"
   $CONTAINER_APPS_ENVIRONMENT_NAME="cae-caj-github-runners-$RANDOM_5_DIGITS"
   $CONTAINER_APPS_JOB_NAME="caj-github-runners-$RANDOM_5_DIGITS"
   $KEYVAULT_NAME="kv-caj-gh-runners-$RANDOM_5_DIGITS"
   $KEYVAULT_SECRET_NAME="github-app-key-1"
   $LOG_ANALYTICS_WORKSPACE_NAME = "workspace-caj-github-runners-$RANDOM_5_DIGITS"
   $RESOURCE_GROUP_NAME="rg-caj-github-runners-$RANDOM_5_DIGITS"
   $UAMI_NAME="uami-caj-github-runners-$RANDOM_5_DIGITS"
   ```
      
   Bash    
   ```bash
   RANDOM_5_DIGITS=$(openssl rand -base64 25 | sed -e 's|\(.\{5\}\).*|\1|')
   CONTAINER_IMAGE_NAME='github-actions-runner:1.0'
   CONTAINER_REGISTRY_NAME="acrcajgithubrunners$RANDOM_5_DIGITS"
   CONTAINER_APPS_ENVIRONMENT_NAME="cae-caj-github-runners-$RANDOM_5_DIGITS"
   CONTAINER_APPS_JOB_NAME="caj-github-runners-$RANDOM_5_DIGITS"
   KEYVAULT_NAME="kv-caj-gh-runners-$RANDOM_5_DIGITS"
   KEYVAULT_SECRET_NAME="github-app-key-1"
   LOG_ANALYTICS_WORKSPACE_NAME = "workspace-caj-github-runners-$RANDOM_5_DIGITS"
   RESOURCE_GROUP_NAME="rg-caj-github-runners-$RANDOM_5_DIGITS"
   UAMI_NAME="uami-caj-github-runners-$RANDOM_5_DIGITS"
   ```
   <br />
1. Create the resource group.
   ```
   az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --output none
   ```
   <br />
1. Create the key vault.    

   PowerShell
   ```powershell
   az keyvault create `
     --name $KEYVAULT_NAME `
     --resource-group $RESOURCE_GROUP_NAME `
     --location $LOCATION `
     --enable-rbac-authorization true `
     --output none
   ```
   
   Bash
   ```bash
   az keyvault create \
     --name $KEYVAULT_NAME \
     --resource-group $RESOURCE_GROUP_NAME \
     --location $LOCATION \
     --enable-rbac-authorization true \
     --output none
   ```
   <br />
1. Get your Azure user account ID.
   
   PowerShell
   ```powershell
   $USER_ID = az ad signed-in-user show --query id -o tsv
   ```
   Bash
   ```bash
   $USER_ID=$(az ad signed-in-user show --query objectId -o tsv)
   ```
   <br />

1. Create a role assignment for your account on the key vault to enable administration.

   PowerShell
   ```powershell
   az role assignment create `
     --assignee $USER_ID `
     --role '00482a5a-887f-4fb3-b363-3b7fe8e74483' `
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" `
     --output none
   ```

   Bash
   ```bash
   az role assignment create \
     --assignee $USER_ID \
     --role '00482a5a-887f-4fb3-b363-3b7fe8e74483' \
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" \
     --output none
   ```
   <br />
1. Create a new secret in the key vault for the GitHub App key (contents of pem file).
   
   PowerShell
   ```powershell
    az keyvault secret set `
      --vault-name $KEYVAULT_NAME `
      --name $KEYVAULT_SECRET_NAME `
      --file $LOCAL_PEM_FILE_PATH `
      --output none
    ```
   
   Bash
   ```bash
   az keyvault secret set \
     --vault-name $KEYVAULT_NAME \
     --name $KEYVAULT_SECRET_NAME \
     --file $LOCAL_PEM_FILE_PATH \
     --output none
   ```
   <br />
1. Save the key vault secret URI in a variable as it will be used later.
   
   PowerShell
   ```powershell
   $KEYVAULT_SECRET_URI = az keyvault secret show `
     --name $KEYVAULT_SECRET_NAME `
     --vault-name $KEYVAULT_NAME `
     --query id `
     --output tsv
   ```
   
   Bash
   ```bash
   KEYVAULT_SECRET_URI=$(az keyvault secret show \
     --name $KEYVAULT_SECRET_NAME \
     --vault-name $KEYVAULT_NAME \
     --query id \
     --output tsv)
   ```
   <br />
1. Create a user-assigned managed identity(uami).  This will be used to access the secret, the container registry later on, and also can be used inside the GitHub workflows that run in the container apps job for performing operations in Azure.
   
   PowerShell
   ```powershell
   az identity create `
     --resource-group $RESOURCE_GROUP_NAME `
     --name $UAMI_NAME `
     --location $LOCATION `
     --output none
   ```
   
   Bash
   ```bash
   az identity create \
     --resource-group $RESOURCE_GROUP_NAME \
     --name $UAMI_NAME \
     --location $LOCATION \
     --output none
   ```
   <br />   
1. Get the `id` and `clientId` of the `uami`.

   PowerShell
   ```powershell
   $UAMI_CLIENT_ID = az identity show --name $UAMI_NAME --resource-group $RESOURCE_GROUP_NAME --query clientId --output tsv
   $UAMI_RESOURCE_ID = az identity show --name $UAMI_NAME --resource-group $RESOURCE_GROUP_NAME --query id --output tsv
   ```
   
   Bash
   ```bash
   UAMI_CLIENT_ID=$(az identity show --name $UAMI_NAME --resource-group $RESOURCE_GROUP_NAME --query clientId --output tsv)
   UAMI_RESOURCE_ID=$(az identity show --name $UAMI_NAME --resource-group $RESOURCE_GROUP_NAME --query id --output tsv)
   ```
   <br />
1. Create a `Key Vault Secrets User` role assignment on the key vault for the `uami`. Note the value used with `--role` which corresponds to the `Key Vault Secrets User` role. Microsoft recommends using the id for roles in the event they are renamed.
   
   PowerShell
   ```powershell
   az role assignment create `
     --role '4633458b-17de-408a-b874-0445c86b69e6' `
     --assignee $UAMI_CLIENT_ID `
     --scope /subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP_NAME `
     --output none
   ```
   
   Bash
   ```bash
   az role assignment create \
     --role '4633458b-17de-408a-b874-0445c86b69e6' \
     --assignee $UAMI_CLIENT_ID \
     --scope /subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP_NAME \
     --output none
   ```
   
   If you have not already done so, take some time if you like to check the resources in the Azure Portal to confirm the `uami` and `keyvault` resources are present and the secret is configured correctly with the GitHub App key content.  Also check the role assignment on the keyvault for the `uami`.  Continue to the next steps if everything looks ok.
   <br />
### Create Container-Related Resources and Log Analytics Workspace

1. Create the container registry(acr).
   
   PowerShell
   ```powershell
   az acr create `
     --resource-group $RESOURCE_GROUP_NAME `
     --name $CONTAINER_REGISTRY_NAME `
     --sku Basic `
     --output none
   ```
   
   Bash
   ```bash
   az acr create \
     --resource-group $RESOURCE_GROUP_NAME \
     --name $CONTAINER_REGISTRY_NAME \
     --sku Basic \
     --output none
   ```
   <br />
1. Get the resource ID of the `acr` for role assignment
   
   PowerShell
   ```powershell
   $ACR_RESOURCE_ID = az acr show --resource-group $RESOURCE_GROUP_NAME --name $CONTAINER_REGISTRY_NAME --query id --output tsv
   ```
   
   Bash
   ```bash
   ACR_RESOURCE_ID=$(az acr show --resource-group $RESOURCE_GROUP_NAME --name $CONTAINER_REGISTRY_NAME --query id --output tsv)
   ```
   <br />  
1. Grant the `uami` access to the `acr` to ensure the container apps job can pull images from the `acr`.
   
   PowerShell
   ```powershell
   az role assignment create `
     --assignee $UAMI_CLIENT_ID `
     --scope $ACR_RESOURCE_ID `
     --role '7f951dda-4ed3-4680-a7ca-43fe172d538d' `
     --output none
   ```
   
   Bash
   ```bash
   az role assignment create \
     --assignee $UAMI_CLIENT_ID \
     --scope $ACR_RESOURCE_ID \
     --role '7f951dda-4ed3-4680-a7ca-43fe172d538d' \
     --output none
   ```
   <br />
1. Create a new container based on the Dockerfile.  This step will take several minutes.
   
   PowerShell
   ```powershell
   az acr build `
     --registry "$CONTAINER_REGISTRY_NAME" `
     --image "$CONTAINER_IMAGE_NAME" `
     --file "$DOCKERFILE_PATH\Dockerfile" $DOCKERFILE_PATH
   ```
   
   Bash
   ```bash
   az acr build `
     --registry "$CONTAINER_REGISTRY_NAME" \
     --image "$CONTAINER_IMAGE_NAME" \
     --file "$DOCKERFILE_PATH\Dockerfile" $DOCKERFILE_PATH
   ```
   <br />
1. Create a Log Analytics Workspace(law) to associate with the Container Apps Environment(cae).
   
   PowerShell
   ```powershell
   az monitor log-analytics workspace create `
     --resource-group $RESOURCE_GROUP_NAME `
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME `
     --location $LOCATION `
     --output none
   ```
   
   Bash
   ```bash
   az monitor log-analytics workspace create \
     --resource-group $RESOURCE_GROUP_NAME \
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME \
     --location $LOCATION \
     --output none
   ```
   <br />   
1. Save the `law` ID into a variable.  
   *Note - The ID we need here is the `customerId`*
   
   PowerShell
   ```powershell
   $LOG_ANALYTICS_WORKSPACE_ID = az monitor log-analytics workspace show `
     --query customerId `
     --resource-group $RESOURCE_GROUP_NAME `
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME `
     --output tsv
   ```
   
   Bash
   ```bash
   LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace show \
     --query customerId \
     --resource-group $RESOURCE_GROUP_NAME \
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME \
     --output tsv)
   ```
   <br />  
1. Save the `law` key into a variable.
   
   PowerShell
   ```powershell
   $LOG_ANALYTICS_WORKSPACE_KEY = az monitor log-analytics workspace get-shared-keys `
     --resource-group $RESOURCE_GROUP_NAME `
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME `
     --query primarySharedKey `
     --output tsv
   ```
   
   Bash
   ```bash
   LOG_ANALYTICS_WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
     --resource-group $RESOURCE_GROUP_NAME \
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME \
     --query primarySharedKey \
     --output tsv)
   ```
   <br />   
1. Create the `cae` for the container apps job(caj).
   
   PowerShell
   ```powershell
   az containerapp env create `
     --name $CONTAINER_APPS_ENVIRONMENT_NAME `
     --resource-group $RESOURCE_GROUP_NAME `
     --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_ID `
     --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_KEY `
     --logs-destination log-analytics `
     --location $LOCATION `
     --output none `
     --only-show-errors
   ```
   
   Bash
   ```bash
   az containerapp env create \
     --name $CONTAINER_APPS_ENVIRONMENT_NAME \
     --resource-group $RESOURCE_GROUP_NAME \
     --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_ID \
     --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_KEY \
     --logs-destination log-analytics \
     --location $LOCATION \
     --output none \
     --only-show-errors
   ```
   <br />
1. Create the `caj`.  
   *Note that a placeholder secret is used here.  I wasn't able to get the secret to work properly and show up in the portal correctly when using a keyvaultref at creation time of the job. Instead, I just create this temporary standard container app secret, and then update it to a keyvaultref in the next step.  Also note that the `--mi-user-assigned` option is not needed when `--registry-identity` is the same identity, and there will be a warning about how the `uami` is already added if you supply both.*
   
   PowerShell
   ```powershell
   az containerapp job create `
     --name "$CONTAINER_APPS_JOB_NAME" `
     --resource-group "$RESOURCE_GROUP_NAME" `
     --environment "$CONTAINER_APPS_ENVIRONMENT_NAME" `
     --trigger-type Event `
     --replica-timeout 1800 `
     --replica-retry-limit 0 `
     --replica-completion-count 1 `
     --parallelism 1 `
     --image "$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME" `
     --min-executions 0 `
     --max-executions 10 `
     --polling-interval 30 `
     --registry-identity $UAMI_RESOURCE_ID `
     --scale-rule-name "github-runner" `
     --scale-rule-type "github-runner" `
     --scale-rule-metadata "applicationID=$GITHUB_APP_ID" "installationID=$GITHUB_INSTALLATION_ID" "owner=$REPO_OWNER" "runnerScope=repo" "repos=$REPO_NAME" `
     --scale-rule-auth "appKey=pem" `
     --cpu "2.0" `
     --memory "4Gi" `
     --secrets "pem=keyvaultref:$KEYVAULT_SECRET_URI,identityref:$UAMI_RESOURCE_ID" `
     --env-vars "PEM=secretref:pem" "APP_ID=$GITHUB_APP_ID" "REPO_URL=https://github.com/$REPO_OWNER/$REPO_NAME" "ACCESS_TOKEN_API_URL=https://api.github.com/app/installations/$GITHUB_INSTALLATION_ID/access_tokens" "REGISTRATION_TOKEN_API_URL=https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runners/registration-token" `
     --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io" `
     --output none
   ```

   Bash
   ```bash
   az containerapp job create \
     --name "$CONTAINER_APPS_JOB_NAME" \
     --resource-group "$RESOURCE_GROUP_NAME" \
     --environment "$CONTAINER_APPS_ENVIRONMENT_NAME" \
     --trigger-type Event \
     --replica-timeout 1800 \
     --replica-retry-limit 0 \
     --replica-completion-count 1 \
     --parallelism 1 \
     --image "$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME" \
     --min-executions 0 \
     --max-executions 10 \
     --polling-interval 30 \
     --registry-identity $UAMI_RESOURCE_ID \
     --scale-rule-name "github-runner" \
     --scale-rule-type "github-runner" \
     --scale-rule-metadata "applicationID=$GITHUB_APP_ID" "installationID=$GITHUB_INSTALLATION_ID" "owner=$REPO_OWNER" "runnerScope=repo" "repos=$REPO_NAME" \
     --scale-rule-auth "appKey=pem" \
     --cpu "2.0" \
     --memory "4Gi" \
     --secrets "pem=keyvaultref:$KEYVAULT_SECRET_URI,identityref:$UAMI_RESOURCE_ID" \
     --env-vars "PEM=secretref:pem" "APP_ID=$GITHUB_APP_ID" "REPO_URL=https://github.com/$REPO_OWNER/$REPO_NAME" "ACCESS_TOKEN_API_URL=https://api.github.com/app/installations/$GITHUB_INSTALLATION_ID/access_tokens" "REGISTRATION_TOKEN_API_URL=https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runners/registration-token" \
     --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io" \
     --output none
   ```

   <br />
## Testing the Solution

1. Select your `caj` resource, and then go to the `Logs` section.  If everything has worked correctly you should see the following messages after several minutes (It takes some time for the KEDA scaler to build).
   
   Run this query to see all the logs in the table.  
   ![image](https://github.com/ethorneloe/azure-apps-jobs-github-runners/assets/129253602/f6c69b0d-fcf4-40f6-957d-6c70f3fd3920)

   You should see these messages:  
   ![image](https://github.com/ethorneloe/azure-apps-jobs-github-runners/assets/129253602/66ec817b-ef29-43aa-a95a-f512b184e38e)



1. Run workflows in the repo and watch the runners get created in GitHub, along with the jobs being executed in Azure.

   Ephemeral Self-Hosted Runners for each Job  
   ![image](https://github.com/ethorneloe/azure-apps-jobs-github-runners/assets/129253602/46b06dd2-ce90-424f-806d-b314fb880bf9)  

   Azure Container Apps job execution history  
   ![image](https://github.com/ethorneloe/azure-apps-jobs-github-runners/assets/129253602/8f70b28d-92ad-400a-860c-128cc7b20662)


