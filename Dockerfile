# Build stage
FROM rust:1.85 AS builder
WORKDIR /app

RUN apt update -y && apt install -y git
RUN git clone --depth 1 https://github.com/sola-st/wasm-r3.git
WORKDIR /app/wasm-r3/crates/replay_gen

RUN cargo build --release --target-dir /app/wasm-r3/crates/replay_gen/target

# Runtime stage
FROM ubuntu:24.04
WORKDIR /app
RUN apt update -y && apt install -y wget

ARG BINARYEN_VERSION=123
RUN ARCH=$(uname -m) && \
    wget -q https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/binaryen-version_${BINARYEN_VERSION}-${ARCH}-linux.tar.gz && \
    tar xzf binaryen-version_${BINARYEN_VERSION}-${ARCH}-linux.tar.gz && \
    mv binaryen-version_${BINARYEN_VERSION}/bin/* /usr/local/bin/ && \
    rm -rf binaryen-version_${BINARYEN_VERSION}-${ARCH}-linux.tar.gz binaryen-version_${BINARYEN_VERSION}

COPY --from=builder /app/wasm-r3/crates/replay_gen/target/release/replay_gen .
RUN mkdir -p /app/output

CMD ["sh", "-c", "./replay_gen trace.r3 index.wasm ./output && mv -f output/replay.wasm output/replay.wasm && echo 'Done'"]
