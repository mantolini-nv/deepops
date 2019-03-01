#!/usr/bin/env bash

. /etc/os-release

# Install Software
case "$ID_LIKE" in
    rhel*)
        # Install Ansible
        type ansible >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            echo "Installing Ansible..."
            sudo yum -y install epel-release >/dev/null
            sudo yum -y install ansible >/dev/null
        fi
        ansible --version | head -1

        # Install python-netaddr
        python -c 'import netaddr' >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            echo "Installing python-netaddr..."
            sudo yum -y install ansible python-netaddr >/dev/null
        fi

        # Install git
        type git >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            echo "Installing git..."
            sudo yum -y install git >/dev/null
        fi
        git --version
        ;;
    debian*)
        # Update apt cache
        echo "Updating apt cache..."
        sudo apt-get update >/dev/null

        # Install repo tool
        type apt-add-repository >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            sudo apt-get -y install software-properties-common >/dev/null
        fi

        # Install Ansible
        type ansible >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            echo "Installing Ansible..."
            sudo apt-add-repository -y ppa:ansible/ansible >/dev/null
            sudo apt-get update >/dev/null
            sudo apt-get -y install ansible >/dev/null
        fi
        ansible --version | head -1

        # Install python-netaddr
        python -c 'import netaddr' >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            echo "Installing python-netaddr..."
            sudo apt-get -y install python-netaddr >/dev/null
        fi

        # Install git
        type git >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            echo "Installing git..."
            sudo apt -y install git >/dev/null
        fi
        git --version
        ;;
    *)
        echo "Unsupported Operating System $ID_LIKE"
        exit 1
        ;;
esac

# Install Ansible Galaxy roles
ansible-galaxy install -r requirements.yml

# Update submodules
git status >/dev/null 2>&1
if [ $? -eq 0 ] ; then
    git submodule update --init
fi

# Copy default configuration
CONFIG_DIR=${CONFIG_DIR:-./config}
if [ ! -d "${CONFIG_DIR}" ] ; then
    cp -rfp ./config.example "${CONFIG_DIR}"
    echo "Copied default configuration to ${CONFIG_DIR}"
else
    echo "Configuration directory '${CONFIG_DIR}' exists, not overwriting"
fi
