FROM ghcr.io/actions/actions-runner:2.311.0

USER root

# Add Microsoft repository
RUN wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb

# Update and install all packages
RUN apt-get update && \
    apt-get install -y curl jq wget apt-transport-https software-properties-common powershell && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

USER runner

ENTRYPOINT ["./entrypoint.sh"]

