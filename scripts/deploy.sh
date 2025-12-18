#!/usr/bin/env bash
#
# ==============================================================================
# Script:        deploy.sh
# Author:        Abdalrahman Bashir
# Date:          2025-12-18
# Version:       0.1
# Purpose:       Automated Orchestration of AWS, Cloudflare, and Ansible.
# Description:   Provision infrastructure via Terraform, update DNS via 
#                Cloudflare API, and configure the server via Ansible.
# ==============================================================================

# --- 1. STRICT MODE ---
set -euo pipefail

# --- 2. GLOBAL VARIABLES ---
TF_DIR="../terraform"
ANSIBLE_DIR="../ansible"
INVENTORY_FILE="${ANSIBLE_DIR}/hosts.ini"
SSH_KEY="~/.ssh/id_rsa_terraform"

# --- 3. LOGGING FUNCTIONS ---
log_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1" >&2
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1" >&2
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}


# --- 4. PRE-FLIGHT CHECKS ---
check_env() {
    local env_file="./variables.env"

    if [[ -f "$env_file" ]]; then
        log_info "Loading environment variables from ${env_file}..."
        source "$env_file"
    else
        log_info "No variables.env found. Relying on manually exported variables."
    fi

    local required_vars=("CLOUDFLARE_TOKEN" "CLOUDFLARE_ZONE" "DOMAIN_NAME" "CERT_EMAIL")
    local missing_count=0

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Variable \${$var} is not set."
            missing_count=$((missing_count + 1))
        fi
    done

    if [[ $missing_count -gt 0 ]]; then
        log_error "Missing ${missing_count} required environment variable(s)."
        echo "Check the variables.env file or export them manually."
        exit 1
    fi

    log_success "Pre-flight checks passed: Environment is ready."
}


# --- 5. CORE FUNCTIONS ---
provision_infrastructure() {
    log_info "Initializing Infrastructure Provisioning Terraform..."
    cd "$TF_DIR"
    
    terraform apply -auto-approve >&2
    
    local ip
    ip=$(terraform output -raw instance_public_ip)
    
    if [[ -z "$ip" ]]; then
        log_error "Failed to retrieve Instance IP from Terraform."
        exit 1
    fi
    
    echo "$ip"
}

update_inventory() {
    local node_ip="$1"
    log_info "Generating Ansible Inventory: ${INVENTORY_FILE}"
    
    cat <<EOF > "$INVENTORY_FILE"
[webservers]
${node_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}
EOF
}

configure_server() {
    log_info "Starting Configuration Management Ansible..."
    cd "$ANSIBLE_DIR"
    
    log_info "Waiting for SSH to stabilize 20 seconds..."
    sleep 20
    
    ansible-playbook -i hosts.ini setup.yml
}

# --- 6. EXECUTION LOGIC ---
main() {
    clear
    echo "============================================================"
    echo "   CLOUD PLATFORM DEPLOYMENT - ARCHITECT: NAKSHSAT"
    echo "============================================================"
    
    check_env
    
    # Run Provisioning and capture IP
    INSTANCE_IP=$(provision_infrastructure)
    log_success "Infrastructure is live at: ${INSTANCE_IP}"
    
    # Update Local Artifacts
    update_inventory "$INSTANCE_IP"
    
    # Run Configuration
    configure_server
    
    echo "============================================================"
    log_success "DEPLOYMENT COMPLETE!"
    log_info "Access the sandbox at: https://sandbox.abdalrahman.tech"
    echo "============================================================"
}

# Entry point
main "$@"