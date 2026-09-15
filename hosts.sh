#!/bin/bash
# Динамический инвентарь Ansible: список ВМ берётся из Yandex Cloud CLI.
# Печатает JSON для inventory-плагина 'script'.

export PATH=/usr/local/bin:/usr/bin:/bin
export YC_CLI_INITIALIZATION_SILENCE=true

YC="${YC_BIN:-$HOME/yandex-cloud/bin/yc}"
KEY="${ANSIBLE_SSH_KEY:-$HOME/.ssh/id_ed25519}"

"$YC" compute instance list --format json 2>/dev/null \
| /usr/bin/jq --arg k "$KEY" '
  [ .[]

    | select(.name | startswith("devops-study-"))
    | select(.status == "RUNNING")
  ] as $vms
  | {
      _meta: {
        hostvars: ($vms | map({
          key: .name,
          value: {
            ansible_host: .network_interfaces[0].primary_v4_address.one_to_one_nat.address,
            ansible_user: "ubuntu",
            ansible_ssh_private_key_file: $k
          }
        }) | from_entries)
      },
      managed: {
        hosts: ($vms | map(.name)),
        vars: {}
      }
    }'
