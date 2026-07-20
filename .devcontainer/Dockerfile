FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        graphviz \
        iverilog \
        make \
        python3 \
        python3-pip \
        python3-venv \
        verilator \
        yosys \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER vscode
