#!/bin/bash
#
# Windows shell provisioner for Ansible playbooks, based on KSid's
# windows-vagrant-ansible: https://github.com/KSid/windows-vagrant-ansible
#
# @see README.md
# @author Jeff Geerling, 2014

# Uncomment if behind a proxy server.
# export {http,https,ftp}_proxy='http://username:password@proxy-host:80'

ANSIBLE_PLAYBOOK=$1
PLAYBOOK_DIR=${ANSIBLE_PLAYBOOK%/*}

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

# Make sure Ansible playbook exists.
if [ ! -f "/vagrant/$ANSIBLE_PLAYBOOK" ]; then
  echo "Cannot find Ansible playbook."
  exit 1
fi

# Install Ansible and its dependencies if it's not installed already.
if ! command -v ansible >/dev/null; then
  echo "Installing Ansible dependencies and Git."
  if [[ ! -z ${YUM} ]]; then
    yum install -y git python python-devel
  elif [[ ! -z ${APT_GET} ]]; then
    apt-get update
    apt-get install -y git python python-dev libffi-dev g++ libssl-dev
  else
    echo "Neither yum nor apt-get are available."
    exit 1;
  fi


  # Install GCC / required build tools.
  if [[ ! -z $YUM ]]; then
    yum install -y gcc
  elif [[ ! -z $APT_GET ]]; then
    apt-get install -y build-essential python-pip
  fi

  echo "Installing required python modules."
  pip install paramiko pyyaml jinja2 markupsafe

  echo "Installing Ansible."
  pip install ansible
fi

# Install requirements.
echo "Installing Ansible roles from requirements file, if available."
find "/vagrant/$PLAYBOOK_DIR" \( -name "requirements.yml" -o -name "requirements.txt" \) -exec sudo ansible-galaxy install --ignore-errors -r {} \;

# Run the playbook.
echo "Running Ansible provisioner defined in Vagrantfile."
ansible-playbook -i 'localhost,' "/vagrant/${ANSIBLE_PLAYBOOK}" --extra-vars "is_windows=true" --connection=local
