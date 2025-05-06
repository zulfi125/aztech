#!/bin/bash 

# Define color codes
INFO='\033[0;36m'   # Cyan
BANNER='\033[0;35m' # Magenta
YELLOW='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
LIGHTBLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
RESET='\033[0m'
BOLD='\033[1m'
NC='\033[0m'

# Banner
echo -e "${YELLOW}========================================"
echo -e " Script is made by Learn Fast Earn"
echo -e "----------------------------------------${NC}"
echo -e '\e[34m'
cat << "EOF"
██╗     ███████╗ █████╗ ██████╗ ███╗   ██╗    ███████╗ █████╗ ██████╗ ███╗   ██╗
██║     ██╔════╝██╔══██╗██╔══██╗████╗  ██║    ██╔════╝██╔══██╗██╔══██╗████╗  ██║
██║     █████╗  ███████║██████╔╝██╔██╗ ██║    █████╗  ███████║██████╔╝██╔██╗ ██║
██║     ██╔══╝  ██╔══██║██╔═══╝ ██║╚██╗██║    ██╔══╝  ██╔══██║██╔═══╝ ██║╚██╗██║
███████╗███████╗██║  ██║██║     ██║ ╚████║    ██║     ██║  ██║██║     ██║ ╚████║
╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═══╝    ╚═╝     ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═══╝
EOF
echo -e '\e[0m'
echo -e "======================================================="
echo -e "${YELLOW}Telegram: ${GREEN}https://t.me/LearnFastEarn4All${NC}"
echo -e "${YELLOW}Twitter: ${GREEN}@zulfi125678${NC}"
echo -e "${YELLOW}YouTube: ${GREEN}https://www.youtube.com/@LearnFastEarn2.0/${NC}"
echo -e "${YELLOW}Telegram group: ${INFO}https://t.me/learnfastearngroup${NC}"
echo -e "=======================================================\n"

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
sudo apt update -y && sudo apt upgrade -y

# Install common dependencies
echo -e "${CYAN}${BOLD}---- INSTALLING DEPENDENCIES ----${RESET}"
sudo apt install -y curl screen git net-tools psmisc jq

# Check and install Docker
echo -e "\n${CYAN}${BOLD}---- CHECKING DOCKER INSTALLATION ----${RESET}"
if ! command -v docker &>/dev/null; then
    echo -e "${LIGHTBLUE}${BOLD}Docker not found. Installing Docker...${RESET}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}${BOLD}Docker installed successfully!${RESET}"
else
    echo -e "${GREEN}${BOLD}Docker is already installed.${RESET}"
fi

# Allow Docker to run without sudo
echo -e "${LIGHTBLUE}${BOLD}Setting up Docker to run without sudo...${RESET}"
if ! getent group docker > /dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker $USER
sudo systemctl start docker
if [ -S /var/run/docker.sock ]; then
    sudo chmod 666 /var/run/docker.sock
    echo -e "${GREEN}${BOLD}Docker socket permissions updated.${RESET}"
else
    echo -e "${RED}${BOLD}Docker socket not found. Trying to start Docker...${RESET}"
    sudo systemctl start docker
    sudo chmod 666 /var/run/docker.sock
fi

if docker info &>/dev/null; then
    echo -e "${GREEN}${BOLD}Docker is working without sudo.${RESET}"
else
    echo -e "${RED}${BOLD}Failed to configure Docker for non-root use. Defaulting to sudo.${RESET}"
    DOCKER_CMD="sudo docker"
fi

# Install Docker Compose
if ! command -v docker-compose &>/dev/null; then
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose installed.${NC}"
else
    echo -e "${YELLOW}Docker Compose already installed.${NC}"
fi

# Clean previous Aztec setup
[ -d $HOME/.aztec/alpha-testnet ] && rm -r $HOME/.aztec/alpha-testnet

AZTEC_PATH=$HOME/.aztec
BIN_PATH=$AZTEC_PATH/bin
mkdir -p $BIN_PATH

echo -e "\n${CYAN}${BOLD}---- INSTALLING AZTEC TOOLKIT ----${RESET}\n"

if [ -n "$DOCKER_CMD" ]; then
  export DOCKER_CMD="$DOCKER_CMD"
fi

curl -fsSL https://install.aztec.network | bash

if ! command -v aztec >/dev/null 2>&1; then
    echo -e "${LIGHTBLUE}${BOLD}Aztec CLI not found in PATH. Adding it for current session...${RESET}"
    export PATH="$PATH:$HOME/.aztec/bin"
    
    if ! grep -Fxq 'export PATH=$PATH:$HOME/.aztec/bin' "$HOME/.bashrc"; then
        echo 'export PATH=$PATH:$HOME/.aztec/bin' >> "$HOME/.bashrc"
        echo -e "${GREEN}${BOLD}Added Aztec to PATH in .bashrc${RESET}"
    fi
fi

if [ -f "$HOME/.bash_profile" ]; then
    source "$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

export PATH="$PATH:$HOME/.aztec/bin"

if ! command -v aztec &> /dev/null; then
  echo -e "${RED}${BOLD}ERROR: Aztec installation failed. Please check the logs above.${RESET}"
  exit 1
fi

echo -e "\n${CYAN}${BOLD}---- UPDATING AZTEC TO ALPHA-TESTNET ----${RESET}\n"
aztec-up alpha-testnet

echo -e "\n${CYAN}${BOLD}---- CONFIGURING NODE ----${RESET}\n"
IP=$(curl -s https://api.ipify.org)
if [ -z "$IP" ]; then
    IP=$(curl -s http://checkip.amazonaws.com)
fi
if [ -z "$IP" ]; then
    IP=$(curl -s https://ifconfig.me)
fi
if [ -z "$IP" ]; then
    echo -e "${LIGHTBLUE}${BOLD}Could not determine IP address automatically.${RESET}"
    read -p "Please enter your VPS/WSL IP address: " IP
fi

echo -e "${LIGHTBLUE}${BOLD}Visit ${PURPLE}https://dashboard.alchemy.com/apps${RESET}${LIGHTBLUE}${BOLD} to create an account and get a Sepolia RPC URL.${RESET}"
read -p "Enter Your Sepolia Ethereum RPC URL: " L1_RPC_URL

echo -e "\n${LIGHTBLUE}${BOLD}Visit ${PURPLE}https://chainstack.com/global-nodes${RESET}${LIGHTBLUE}${BOLD} to create an account and get beacon RPC URL.${RESET}"
read -p "Enter Your Sepolia Ethereum BEACON URL: " L1_CONSENSUS_URL

echo -e "\n${LIGHTBLUE}${BOLD}Please create a new EVM wallet, fund it with Sepolia Faucet and then provide the private key.${RESET}"
read -p "Enter your new evm wallet private key (with 0x prefix): " VALIDATOR_PRIVATE_KEY
read -p "Enter the wallet address associated with the private key you just provided: " COINBASE_ADDRESS

echo -e "\n${CYAN}${BOLD}---- STARTING THE AZTEC NODE ----${RESET}\n"
cat > $HOME/start_aztec_node.sh << EOL
#!/bin/bash
export PATH=\$PATH:\$HOME/.aztec/bin
aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --port 9090 \\
  --l1-rpc-urls $L1_RPC_URL \\
  --l1-consensus-host-urls $L1_CONSENSUS_URL \\
  --sequencer.validatorPrivateKey $VALIDATOR_PRIVATE_KEY \\
  --sequencer.coinbase $COINBASE_ADDRESS \\
  --p2p.p2pIp $IP
EOL

chmod +x $HOME/start_aztec_node.sh
screen -dmS aztec $HOME/start_aztec_node.sh

echo -e "${GREEN}${BOLD} Aztec node started successfully in a screen session.${RESET}\n"

# Final message
echo -e "${YELLOW}----------------------------------------"
echo -e " Thanks for using the script!"
echo -e "----------------------------------------${NC}"
