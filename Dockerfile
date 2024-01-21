FROM ghcr.io/actions/actions-runner:2.311.0

USER root

# Install required base packages
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg jq lsb-release software-properties-common wget

# Install powershell
RUN export VERSION_ID=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | tr -d '"') && \
    echo "VERSION_ID is: $VERSION_ID" && \
    wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell

# Install the az Module
RUN pwsh -command Install-Module -Name Az -Repository PSGallery -Force

# Install azure cli
RUN mkdir -p /etc/apt/keyrings && \
    curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/microsoft.gpg && \
    AZ_DIST=$(lsb_release -cs) && \
    echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install azure-cli

# Clean up
RUN rm packages-microsoft-prod.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

USER runner

ENTRYPOINT ["./entrypoint.sh"]