FROM huggingface/transformers-pytorch-gpu:4.1.1 AS build

WORKDIR /workspace

COPY requirements.txt .
RUN pip install -r requirements.txt && \
    rm -rf /root/.cache/pip/*
