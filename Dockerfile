# Multi-staged container spec for OpenPortfolio. 
# This spec will ultimately encompass containers for both development and production.

ARG OP_PY_VERSION=3.9.6
ARG OP_BUILD=/open-portfolio/build
ARG OP_DEPS=/open-portfolio/deps
ARG OP_PYTHON_DIR=${OP_DEPS}/python${OP_PY_VERSION}
ARG OP_VENV_DIR=${OP_DEPS}/op-venv
ARG OP_PYTHON=${OP_PYTHON_DIR}/bin/python3

####################################### op-base #######################################
# - Extends the Buildpack Ubuntu 20.04 image.
# - Installs some additional system utilities.
#######################################################################################
FROM buildpack-deps:focal AS op-base
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
    wget \
    tar \
    && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
RUN add-apt-repository -y ppa:git-core/ppa \
    && apt-get install -y git

#################################### op-py-build ######################################
# Extends op-base.
# - Builds a self-contained python executable in the OP_DEPS directory from sources.
# - Runs tests and sanity checks on the newly-built python.
#######################################################################################
FROM op-base AS op-py-build
ARG OP_PY_VERSION OP_PYTHON_DIR OP_PYTHON OP_BUILD
ENV OP_PYTHON_SOURCES=${OP_BUILD}/python${OP_PY_VERSION}-sources
RUN apt-get install -y \
    wget \
    tar \
    build-essential \
    checkinstall \
    libreadline-gplv2-dev \
    libncursesw5-dev \
    libssl-dev \
    libsqlite3-dev \
    tk-dev \
    libgdbm-dev \
    libc6-dev \
    libbz2-dev
RUN mkdir -p ${OP_PYTHON_SOURCES} ${OP_PYTHON_DIR}
WORKDIR ${OP_PYTHON_SOURCES}
RUN wget https://www.python.org/ftp/python/${OP_PY_VERSION}/Python-${OP_PY_VERSION}.tgz
RUN tar xzf Python-${OP_PY_VERSION}.tgz
WORKDIR ${OP_PYTHON_SOURCES}/Python-${OP_PY_VERSION}
RUN ./configure --prefix=${OP_PYTHON_DIR}
RUN make
RUN make test
RUN make install
RUN test "$(${OP_PYTHON} --version)" = "Python ${OP_PY_VERSION}"

###################################### op-minimal #####################################
# Extends op-base.
# - Copies the isolated python installation from op-py-build.
# - Installs poetry into the isolated python.
# - Adds the workspace directory with pyproject.toml + poetry.lock.
# - Generates the virtualenv containing poetry and all OpenPortfolio dependencies
#   apart from development dependencies and OpenPortfolio itself.
#######################################################################################
FROM op-base AS op-minimal
ARG OP_POETRY_VERSION='1.1.7' 
ARG OP_VENV_DIR OP_PYTHON OP_PYTHON_DIR OP_BUILD OP_DEPS
ENV OP_BUILD_PROJ=${OP_BUILD}/project

COPY --from=op-py-build ${OP_DEPS} ${OP_DEPS}
RUN ${OP_PYTHON} -m pip install --no-cache-dir --upgrade pip && \
    ${OP_PYTHON} -m pip install --no-cache-dir --upgrade setuptools wheel virtualenv
ENV PIP_USER=no
RUN ${OP_PYTHON} -m pip install --prefix=${OP_PYTHON_DIR} poetry==${OP_POETRY_VERSION}

RUN mkdir -p ${OP_VENV_DIR}
RUN ${OP_PYTHON} -m venv ${OP_VENV_DIR}
ENV PATH=${OP_VENV_DIR}/bin:${OP_PYTHON_DIR}/bin:${PATH} PIP_USER=no

RUN mkdir -p ${OP_BUILD_PROJ}
WORKDIR ${OP_BUILD_PROJ}
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-dev --no-root

######################################## op-dev #######################################
# Extends op-base.
# - Creates and configures the OP_USER.
# - Copies dependencies from op-minimal (including the isolated Python and virtualenv).
# - Creates the workspace directory and copies all OpenPortfolio sources into it.
# - Installs OpenPortfolio itself, editable, into the virtualenv.
#######################################################################################
FROM op-base AS op-dev
ARG OP_PYTHON_DIR OP_VENV_DIR OP_DEPS
ARG OP_USER=op-admin OP_WORKSPACE=/workspace OP_UID=30000

ENV HOME=/home/${OP_USER}
RUN useradd -l -u ${OP_UID} -G sudo -md ${HOME} -s \
    /bin/bash -p ${OP_USER} ${OP_USER} && \
    sed -i.bak -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
    /etc/sudoers

USER ${OP_USER}
WORKDIR ${HOME}
RUN sudo echo "Running 'sudo' for ${OP_USER}." && \
    mkdir ${HOME}/.bashrc.d && \
    (echo; echo "for i in \$(ls \${HOME}/.bashrc.d/*); do source \$i; done"; echo) \
    >> ${HOME}/.bashrc
RUN echo "export PATH=${OP_PYTHON_DIR}/bin:"'"${PATH}"' >> ${HOME}/.bashrc.d/op-init
RUN echo "export PIP_USER=no" >> ${HOME}/.bashrc.d/op-init
RUN echo ". ${OP_VENV_DIR}/bin/activate" >> ${HOME}/.bashrc.d/op-init

COPY --from=op-minimal --chown=${OP_USER}:${OP_USER} ${OP_DEPS} ${OP_DEPS}
ENV PATH="${OP_PYTHON_DIR}/bin:${PATH}" PIP_USER=no

COPY ./ ${OP_WORKSPACE}

WORKDIR ${OP_WORKSPACE}
RUN . ${OP_VENV_DIR}/bin/activate && \
    poetry env use ${OP_VENV_DIR}/bin/python3 && \
    poetry install
