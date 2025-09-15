FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      coreutils \
      curl \
      git \
      gnupg \
      nano \
      openssl \
      sed \
      tar \
      tree \
      unzip \
      vim \
      xz-utils \
      watch \
      software-properties-common \
      lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add Docker’s official GPG key and repo
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker CLI
RUN apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install Docker Compose v2 plugin
RUN mkdir -p /usr/local/lib/docker/cli-plugins/ && \
    curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-$(uname -m) \
    -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose


# Install jq
RUN curl -fsSL https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 \
    -o /usr/local/bin/jq && chmod +x /usr/local/bin/jq

# Install yq
RUN curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.45.2/yq_linux_amd64 \
    -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Install Inso
RUN curl -fsSL https://github.com/Kong/insomnia/releases/download/core%4011.1.0/inso-linux-11.1.0.tar.xz | \
    tar -xJ -C /usr/local/bin/

# Install decK
RUN curl -fsSL https://github.com/Kong/deck/releases/download/v1.49.2/deck_1.49.2_linux_amd64.tar.gz | \
    tar -xz -C /usr/local/bin/ deck

# Install jwt-cli
RUN curl -fsSL https://github.com/mike-engel/jwt-cli/releases/download/6.2.0/jwt-linux.tar.gz | \
    tar -xz -C /usr/local/bin/

# Install httpie
RUN curl -fsSL https://github.com/httpie/cli/releases/download/3.2.2/http \
    -o /usr/local/bin/http && \
    ln -s /usr/local/bin/http /usr/local/bin/https && \
    chmod +x /usr/local/bin/http /usr/local/bin/https

# Install Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_linux_amd64.zip \
    -o /tmp/terraform.zip && \
    unzip /tmp/terraform.zip terraform -d /usr/local/bin/ && \
    rm /tmp/terraform.zip

