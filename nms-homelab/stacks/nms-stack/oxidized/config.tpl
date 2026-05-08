---
username: op://JesterTek/Oxidized/OXIDIZED_USERNAME
password: op://JesterTek/Oxidized/OXIDIZED_PASSWORD
model: aoscx
interval: 3600
use_syslog: false
debug: false
threads: 30
timeout: 20
retries: 3
forty-five: 10

rest: 0.0.0.0:8888

vars:
  auth_methods: ["keyboard-interactive", "password"]
  ssh_no_verify: true

groups: {}
models: {}

source:
  default: http
  http:
    url: http://127.0.0.1:8000/api/v0/oxidized
    map:
      name: hostname
      model: os
      group: group
    headers:
      X-Auth-Token: 'op://JesterTek/Oxidized/LIBRENMS_API_TOKEN'

model_map:
  arubaos-cx: aoscx
  arubaos: arubaos
  juniper: junos
  paloalto: panos

output:
  default: git
  git:
    user: Oxidized
    email: oxidized@jestertek.cc
    repo: "/home/oxidized/.config/oxidized/storage.git"
