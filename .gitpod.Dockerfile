# Dev container for OpenPortfolio

FROM gitpod/workspace-base:latest

USER gitpod

RUN sudo install-packages python3-pip

# Based on the "Python" section of https://github.com/gitpod-io/workspace-images/blob/master/full/Dockerfile
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
        setuptools wheel virtualenv pipenv pylint rope flake8 \
        mypy autopep8 pep8 pylama pydocstyle bandit notebook \
        twine \
    && sudo rm -rf /tmp/*

ENV PIP_USER=false OP_WORKSPACE=/workspace/OpenPortfolio
RUN sudo apt-get update -y && \
    sudo apt-get upgrade -y && \
    sudo apt-get install -y python3.9 python3.9-venv && \
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3.9 - && \
    source $HOME/.poetry/env && \
    cd ${OP_WORKSPACE} && \
    poetry install
