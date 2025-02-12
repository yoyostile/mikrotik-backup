FROM debian:bookworm-slim

RUN apt update && apt install -y curl bash openssh-client jq git iputils-ping && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ~/.ssh && mkdir /mikrotik-backup
WORKDIR /mikrotik-backup

COPY backup.sh .

CMD echo "$MIKROTIK_SSH_KEY" > ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa && \
    for ROUTER in $ROUTERS; do ssh-keyscan -H $ROUTER >> ~/.ssh/known_hosts || true; done && \
    /bin/bash backup.sh
