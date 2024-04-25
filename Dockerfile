FROM ubuntu:jammy

ENV KUBE_VERSION=v1.27.4
ENV KUBECTL_VERSION=${KUBE_VERSION}
ENV KREW_VERSION=v0.4.4
ENV HELM_VERSION=v3.14.0
ARG DEBIAN_FRONTEND=noninteractive
RUN echo 'export PATH=/usr/local/bin:$PATH' >> /root/.bashrc
RUN echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /root/.bashrc
RUN echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH' >> /root/.bashrc
RUN echo 'source /root/.kube-alias' >> /root/.bashrc
RUN apt update -y && apt install -y wget curl git tar build-essential file ruby-full locales golang-go sudo --no-install-recommends
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN useradd -m -s /bin/bash linuxbrew \
    && echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
USER root
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
RUN brew install gcc
RUN brew install kube-linter
RUN brew install kompose
RUN brew install kubecolor
RUN brew tap johanhaleby/kubetail && brew install kubetail
RUN mkdir -p /tmp/brew/git \
    && cd /tmp/brew/git \
    && git clone https://github.com/sh0rez/kubectl-neat-diff \
    && cd /tmp/brew/git/kubectl-neat-diff \
    && make install \
    && rm -rf /tmp/brew
RUN mkdir -p /tmp/k9s \
    && cd /tmp/k9s \
    && wget  https://github.com/derailed/k9s/releases/download/v0.32.4/k9s_Linux_amd64.tar.gz \
    && tar -xzvf k9s_Linux_amd64.tar.gz \
    && chmod +x k9s \
    && mv k9s /usr/local/bin/k9s \
    && rm -rf /tmp/k9s
RUN mkdir /root/.kubes
RUN curl -LO https://dl.k8s.io/release/$KUBE_VERSION/bin/linux/amd64/kubectl
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN ( set -x; cd "$(mktemp -d)" && OS="$(uname | tr '[:upper:]' '[:lower:]')" && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && KREW="krew-${OS}_${ARCH}" && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && tar zxvf "${KREW}.tar.gz" && ./"${KREW}" install krew)
RUN curl -sSLo helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" && tar -xzf helm.tar.gz && install ./linux-amd64/helm /usr/local/bin/helm
USER root
WORKDIR /root
CMD ["/bin/bash"]
