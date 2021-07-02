FROM gitpod/workspace-full

USER gitpod

ENV PIP_USER=false OP_WORKSPACE=/workspace/OpenPortfolio

RUN sudo apt-get update -y && \
    sudo apt-get upgrade -y && \
    sudo apt-get install -y python3.9 python3.9-venv && \
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3.9 - && \
    pushd ${OP_WORKSPACE} && \
    poetry install && \
    popd
