# Multi-staged container spec for OpenPortfolio. 
# This spec encompasses containers for both development and production.

####################################### op_base #######################################
# - Consists of an Ubuntu 20.04 image with the software from buildpack 
# - Installs some additional system utilities that are generally expected on a Linux 
#   machine, including `sudo` and `git`.
#   - `sudo` is included for use by *NON*-root users who are created down the line.
#   - The root user should never use sudo to become another user, as this is a 
#     security risk.
# - Does not perform any user-installs (nor does it create any users), thus does not 
#   include any software specific to OpenPortfolio.
#######################################################################################
FROM buildpack-deps:focal AS op_base
COPY install-packages /usr/bin
ARG DEBIAN_FRONTEND=noninteractive
RUN yes | unminimize \
    && install-packages \
        zip \
        unzip \
        bash-completion \
        build-essential \
        ninja-build \
        htop \
        jq \
        less \
        locales \
        man-db \
        nano \
        software-properties-common \
        sudo \
        time \
        vim \
        multitail \
        lsof \
        ssl-cert \
    && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
RUN add-apt-repository -y ppa:git-core/ppa \
    && install-packages git

###################################### op_minimal #####################################
# - Introduces the op-admin user and pyenv with python3.9.
# - Configures passwordless `sudo`.
# - Adds `.bashrc.d` and sources it in `.bashrc`.
# - Performs an initial `sudo` call as op-admin.
# - Adds python3.9 via pyenv.
# - Adds poetry.
# - Adds all common OpenPortfolio dependencies to a virtualenv.
# - Adds the OpenPortfolio sources.
#######################################################################################
FROM op_base AS op_minimal
RUN useradd -l -u 30000 -G sudo -md /home/op-admin -s /bin/bash -p op-admin op-admin \
    && sed -i.bak \
    -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
    /etc/sudoers

ENV HOME=/home/op-admin
WORKDIR $HOME
USER op-admin
RUN sudo echo "Running 'sudo' for op-admin." && \
    mkdir /home/gitpod/.bashrc.d && \
    (echo; echo "for i in \$(ls \$HOME/.bashrc.d/*); do source \$i; done"; echo) >> /home/gitpod/.bashrc
RUN sudo install-packages python3-pip
ENV PATH=$HOME/.pyenv/bin:$HOME/.pyenv/shims:$PATH
RUN curl -fsSL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && { echo; \
        echo 'eval "$(pyenv init -)"'; \
        echo 'eval "$(pyenv virtualenv-init -)"'; } >> /home/gitpod/.bashrc.d/60-python \
    && pyenv update \
    && pyenv install 3.9.6 \
    && pyenv global 3.9.6 \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir --upgrade \
        setuptools wheel virtualenv poetry=="${POETRY_VERSION}" \
    && sudo rm -rf /tmp/*
RUN sudo apt-get update -y
ENV PIP_USER=no PATH="$PATH:$HOME/.poetry/env/bin" OP_WORKSPACE=/workspace OP_VENV=${OP_WORKSPACE}/venv POETRY_VERSION='1.1.7'
RUN python3 -m pip install "poetry==${POETRY_VERSION}"
RUN mkdir -p ${OP_WORKSPACE}
RUN python3 -m venv ${OP_VENV}

WORKDIR ${OP_WORKSPACE}
COPY pyproject.toml poetry.lock ./
RUN . venv/bin/activate && poetry install --no-dev --no-root
COPY ./ ./

######################################## op_dev #######################################
# - Adds dev-specific dependencies to the virtualenv.
# - Installs OpenPortfolio itself, editable, from sources.
#######################################################################################
FROM op_minimal AS op_dev
RUN poetry install

######################################## op_gitpod ####################################
# - Renames op-admin to gitpod.
#######################################################################################
FROM op_dev AS op_gitpod
USER root
RUN usermod -l gitpod op-admin
RUN usermod -d /home/gitpod /home/op-admin
USER gitpod
WORKDIR /workspace
