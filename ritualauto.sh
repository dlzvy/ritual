#!/bin/bash

curl -s https://raw.githubusercontent.com/dlzvy/LOGOTES/main/logo1.sh | bash
sleep 5

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}Skrip ini memerlukan hak akses root.${NC}"
    echo "Silakan coba dengan perintah 'sudo -i' untuk masuk sebagai pengguna root, lalu jalankan skrip ini lagi."
    exit 1
fi

SCRIPT_PATH="$HOME/Ritual.sh"

function install_node() {

    read -p "Masukkan private key dompet EVM, harus dimulai dengan 0x, disarankan menggunakan dompet baru: " private_key
    read -p "Masukkan alamat dompet yang sesuai, harus dimulai dengan 0x, disarankan menggunakan dompet baru: " wallet_address
    read -p "Masukkan RPC, harus di jaringan Base: " rpc_address
    read -p "Masukkan port: " port1

    sudo apt update

    if ! command -v git &> /dev/null
    then
        echo -e "${YELLOW}Git tidak terdeteksi, sedang menginstal...${NC}"
        sudo apt install git -y
    else
        echo -e "${GREEN}Git sudah terinstal.${NC}"
    fi

    git clone https://github.com/ritual-net/infernet-node

    cd infernet-node

    tag="v1.0.0"

    docker build -t ritualnetwork/infernet-node:$tag .

    cd deploy

    cat > config.json <<EOF
{
  "log_path": "infernet_node.log",
  "manage_containers": true,
  "server": {
    "port": 4000,
    "rate_limit": {
      "num_requests": 100,
      "period": 100
    }
  },
  "chain": {
    "enabled": true,
    "trail_head_blocks": 3,
    "rpc_url": "$rpc_address",
    "registry_address": "0xe2F36C4E23D67F81fE0B278E80ee85Cf0ccA3c8d",
    "wallet": {
      "max_gas_limit": 5000000,
      "private_key": "$private_key",
      "payment_address": "$wallet_address",
      "allowed_sim_errors": ["not enough balance"]
    },
    "snapshot_sync": {
      "sleep": 3,
      "starting_sub_id": 160000,
      "batch_size": 800,
      "sync_period": 30
    }
  },
  "docker": {
    "username": "username"
  },
  "redis": {
    "host": "redis",
    "port": 6379
  },
  "forward_stats": true,
  "startup_wait": 1.0,
  "containers": [
    {
      "id": "hello-world",
      "image": "ritualnetwork/hello-world-infernet:latest",
      "external": true,
      "port": "3000",
      "allowed_delegate_addresses": [],
      "allowed_addresses": [],
      "allowed_ips": [],
      "command": "--bind=0.0.0.0:3000 --workers=2",
      "env": {},
      "volumes": [],
      "accepted_payments": {
        "0x0000000000000000000000000000000000000000": 1000000000000000000,
        "0x59F2f1fCfE2474fD5F0b9BA1E73ca90b143Eb8d0": 1000000000000000000
      },
      "generates_proofs": false
    }
  ]
}
EOF

    echo -e "${GREEN}File konfigurasi telah disiapkan.${NC}"

    sudo apt install pkg-config curl build-essential libssl-dev libclang-dev -y

    if ! command -v docker &> /dev/null
    then
        echo -e "${YELLOW}Docker tidak terdeteksi, sedang menginstal...${NC}"
        sudo apt-get install ca-certificates curl gnupg lsb-release

        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt-get update

        sudo apt-get install docker-ce docker-ce-cli containerd.io -y 
        DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
        mkdir -p $DOCKER_CONFIG/cli-plugins
        curl -SL https://github.com/docker/compose/releases/download/v2.25.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
        sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        docker compose version
        
    else
        echo -e "${GREEN}Docker sudah terinstal.${NC}"
    fi

    docker compose up -d

    echo -e "${CYAN}========================= Instalasi Selesai ======================================${NC}"
    echo "Silakan masuk ke direktori infernet-node/deploy, lalu gunakan perintah docker compose logs -f untuk memeriksa log."
}

function check_service_status() {
    cd infernet-node/deploy
    docker compose logs -f
}

function main_menu() {
    clear
    echo -e "${BLUE}Silakan pilih tindakan yang ingin dilakukan:${NC}"
    echo -e "${YELLOW}1. Instal Node${NC}"
    echo -e "${YELLOW}2. Periksa Log Node${NC}"
    read -p "Masukkan pilihan (1-2): " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    *) echo -e "${RED}Pilihan tidak valid.${NC}" ;;
    esac
}

main_menu