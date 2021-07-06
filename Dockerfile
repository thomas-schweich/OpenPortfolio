# Multi-staged container spec for OpenPortfolio. 
# This spec will ultimately encompass containers for both development and production.

####################################### op_base #######################################
# - Consists of an Ubuntu 20.04 image with the software from buildpack 
# - Installs some additional system utilities which are generally expected on a Linux 
#   machine, including `sudo` and `git`.
#   - `sudo` is included for use by *NON*-root users who are created down the line.
#   - The root user should never use sudo to become another user, as this is a 
#     security risk.
# - Does not perform any user-installs (nor does it create any users), thus does not 
#   include any software specific to OpenPortfolio.
#######################################################################################
FROM buildpack-deps:focal AS op_base
RUN apt-get update
RUN apt-get install -y \
        apt-utils \
        zip \
        unzip \
        bash-completion \
        build-essential \
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
        lsof \
        ssl-cert \
    && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
RUN add-apt-repository -y ppa:git-core/ppa \
    && apt-get install -y git

###################################### op_minimal #####################################
# - Introduces the op-admin user and pyenv with python3.9.
# - Configures passwordless `sudo`.
# - Adds `.bashrc.d` and sources it in `.bashrc`.
# - Performs an initial `sudo` call as op-admin.
# - Adds python3.9 via pyenv.
# - Adds poetry.
# - Adds all common OpenPortfolio dependencies to a virtualenv.
# - Adds the OpenPortfolio sources in a separate step after dependency installation.
#   - This prevents the container from requiring a rebuild of all dependencies every
#     time the sources change.
#######################################################################################
FROM op_base AS op_minimal
ARG OP_USER=op-admin
RUN useradd -l -u 30000 -G sudo -md /home/${OP_USER} -s \
        /bin/bash -p ${OP_USER} ${OP_USER} && \
    sed -i.bak -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
    /etc/sudoers    

ENV HOME=/home/${OP_USER}
WORKDIR ${HOME}
USER ${OP_USER}
RUN sudo echo "Running 'sudo' for ${OP_USER}." && \
    mkdir ${HOME}/.bashrc.d && \
    (echo; echo "for i in \$(ls \${HOME}/.bashrc.d/*); do source \$i; done"; echo) \
        >> ${HOME}/.bashrc
RUN sudo apt-get install -y python3-pip
ENV PATH=${HOME}/.pyenv/bin:${HOME}/.pyenv/shims:$PATH
RUN curl -fsSL \ 
        https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && { echo; \
        echo 'eval "$(pyenv init -)"'; \
        echo 'eval "$(pyenv virtualenv-init -)"'; } >> ${HOME}/.bashrc.d/60-python \
    && pyenv update \
    && pyenv install 3.9.6 \
    && pyenv global 3.9.6 \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir --upgrade \
        setuptools wheel virtualenv \
    && sudo rm -rf /tmp/*
ENV POETRY_VERSION='1.1.7'
RUN python3 -m pip install poetry=="${POETRY_VERSION}"
ENV PIP_USER=no \
    PATH="$PATH:${HOME}/.poetry/bin" \
    OP_WORKSPACE=/workspace
RUN sudo mkdir -p ${OP_WORKSPACE}
RUN sudo chown ${OP_USER}:${OP_USER} ${OP_WORKSPACE}

WORKDIR ${OP_WORKSPACE}
RUN curl -sSL \
    https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py \
        | python - --version "${POETRY_VERSION}" && \
        . $HOME/.poetry/env
RUN python3 -m venv venv
COPY pyproject.toml poetry.lock ./
RUN . venv/bin/activate && poetry install --no-dev --no-root
COPY ./ ./

######################################## op_dev #######################################
# - Adds dev-specific dependencies to the virtualenv.
# - Installs OpenPortfolio itself, editable, from sources.
#######################################################################################
FROM op_minimal AS op_dev
RUN poetry install
