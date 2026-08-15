FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ansible \
       curl \
       jq \
       openssh-client \
       smartmontools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ansible.cfg inventory.ini proxmox_health.sh bootstrap_trust.sh run_and_notify.sh /app/

RUN chmod +x /app/proxmox_health.sh /app/bootstrap_trust.sh /app/run_and_notify.sh

CMD ["sleep", "infinity"]
