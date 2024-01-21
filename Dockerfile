FROM ghcr.io/actions/actions-runner:2.311.0

USER root

# Update and install all packages
RUN apt-get update && \
    apt-get install -y curl jq wget apt-transport-https software-properties-common && \
    source /etc/os-release && \
    wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get install -y powershell && \
    rm packages-microsoft-prod.deb
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

USER runner

ENTRYPOINT ["./entrypoint.sh"]

