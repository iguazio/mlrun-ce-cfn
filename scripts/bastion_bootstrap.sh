#!/usr/bin/env bash
# Bastion Bootstrapping
# authors: tonynv@amazon.com, sancard@amazon.com, ianhill@amazon.com
# NOTE: This requires GNU getopt. On Mac OS X and FreeBSD you must install GNU getopt and mod the checkos function so that it's supported

set -xe

# Required for reading in the custom EKS environment variables
source /root/.bashrc

# Configuration
PROGRAM='Linux Bastion'
IMDS_BASE_URL='http://169.254.169.254/latest'
HARDWARE=$(uname -m)
if [[ "${HARDWARE}" == 'x86_64' ]]; then
  ARCHITECTURE='amd64'
  ARCHITECTURE2='64bit'
elif [[ "${HARDWARE}" == 'aarch64' ]]; then
  ARCHITECTURE='arm64'
  ARCHITECTURE2='arm64'
else
  echo "[FAILED] Unsupported architecture: '${HARDWARE}'."
  exit 1
fi

##################################### Functions Definitions
checkos() {
  platform='unknown'
  unamestr=`uname`
  if [[ "${unamestr}" == 'Linux' ]]; then
    platform='linux'
  else
    echo "[WARNING] This script is not supported on MacOS or FreeBSD"
    exit 1
  fi
  echo "${FUNCNAME[0]} ended"
}

imdsv2_token() {
  curl -sSX PUT "${IMDS_BASE_URL}/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600"
}

imds_request() {
  REQUEST_PATH=$1
  if [[ -z $TOKEN ]]; then
    TOKEN=$(imdsv2_token)
  fi
  curl -sSH "X-aws-ec2-metadata-token: $TOKEN" "${IMDS_BASE_URL}/${REQUEST_PATH}"
}

retry_command() {
  local -r __tries="$1"; shift
  local -r __run="$@"
  local -i __backoff_delay=2

  until $__run
  do
    if (( __current_try == __tries ))
    then
      echo "Tried $__current_try times and failed!"
      return 1
    else
      echo "Retrying ...."
      sleep $((((__backoff_delay++)) + ((__current_try++))))
    fi
  done

}

setup_environment_variables() {
  REGION=$(imds_request meta-data/placement/availability-zone/)
  #ex: us-east-1a => us-east-1
  REGION=${REGION: :-1}

  ETH0_MAC=$(/sbin/ip link show dev eth0 | /bin/egrep -o -i 'link/ether\ ([0-9a-z]{2}:){5}[0-9a-z]{2}' | /bin/sed -e 's,link/ether\ ,,g')

  _userdata_file="/var/lib/cloud/instance/user-data.txt"

  INSTANCE_ID=$(imds_request meta-data/instance-id)
  EIP_LIST=$(grep EIP_LIST ${_userdata_file} | sed -e 's/EIP_LIST=//g' -e 's/\"//g')

  LOCAL_IP_ADDRESS=$(imds_request meta-data/network/interfaces/macs/${ETH0_MAC}/local-ipv4s/)

  CWG=$(grep CLOUDWATCHGROUP ${_userdata_file} | sed -e 's/CLOUDWATCHGROUP=//g' -e 's/\"//g')

  export REGION ETH0_MAC EIP_LIST CWG LOCAL_IP_ADDRESS INSTANCE_ID
}

verify_dependencies() {
  local awscli_version=$(aws --version 2>&1 | cut -d "/" -f2-)
  if [[ "${awscli_version}" =~ ^1\..+Python\/2\. ]]; then
    if [[ "${release}" == "AMZN" ]]; then
      yum remove -y awscli
    fi

    echo "Installing AWS CLI..."
    wget -nv -O "./awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-$HARDWARE.zip"
    unzip -q ./awscliv2.zip
    ./aws/install
  fi
  echo "${FUNCNAME[0]} Ended"
}

usage() {
  echo "$0 <usage>"
  echo " "
  echo "options:"
  echo -e "--help \t Show options for this script"
  echo -e "--banner \t Enable or disable bastion message"
  echo -e "--enable \t SSH banner"
  echo -e "--tcp-forwarding \t Enable or disable TCP forwarding"
  echo -e "--x11-forwarding \t Enable or disable X11 forwarding"
}

chkstatus() {
  if [[ $? -eq 0 ]]
  then
    echo "Script [PASS]"
  else
    echo "Script [FAILED]" >&2
    exit 1
  fi
}

osrelease() {
  OS=`cat /etc/os-release | grep '^NAME=' |  tr -d \" | sed 's/\n//g' | sed 's/NAME=//g'`
  if [[ "${OS}" == "Ubuntu" ]]; then
    echo "Ubuntu"
  elif [[ "${OS}" == "Amazon Linux AMI" ]] || [[ "${OS}" == "Amazon Linux" ]]; then
    echo "AMZN"
  elif [[ "${OS}" == "CentOS Linux" ]]; then
    echo "CentOS"
  elif [[ "${OS}" == "SLES" ]]; then
    echo "SLES"
  else
    echo "Operating system not found"
  fi
  echo "${FUNCNAME[0]} ended" >> /var/log/cfn-init.log
}

# Setup Amazon EC2 Instance Connect agent
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-set-up.html#ec2-instance-connect-install
setup_ec2_instance_connect() {
  echo "${FUNCNAME[0]} started"

  if [[ "${release}" == "AMZN" ]]; then
    yum install -y ec2-instance-connect
  elif [[ "${release}" == "Ubuntu" ]]; then
    apt-get install -y ec2-instance-connect
  fi
}

setup_logs() {
  echo "${FUNCNAME[0]} started"
  URL_SUFFIX="${URL_SUFFIX:-amazonaws.com}"
  if [[ "${release}" == 'SLES' ]]; then
    zypper install --allow-unsigned-rpm -y "https://amazoncloudwatch-agent-${REGION}.s3.${REGION}.${URL_SUFFIX}/suse/${ARCHITECTURE}/latest/amazon-cloudwatch-agent.rpm"
  elif [[ "${release}" == 'CentOS' ]]; then
    yum install -y "https://amazoncloudwatch-agent-${REGION}.s3.${REGION}.${URL_SUFFIX}/centos/${ARCHITECTURE}/latest/amazon-cloudwatch-agent.rpm"
  elif [[ "${release}" == 'Ubuntu' ]]; then
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
    curl "https://amazoncloudwatch-agent-${REGION}.s3.${REGION}.${URL_SUFFIX}/ubuntu/${ARCHITECTURE}/latest/amazon-cloudwatch-agent.deb" -O
    dpkg -i -E ./amazon-cloudwatch-agent.deb
    rm ./amazon-cloudwatch-agent.deb
  elif [[ "${release}" == 'AMZN' ]]; then
    yum install -y "https://amazoncloudwatch-agent-${REGION}.s3.${REGION}.${URL_SUFFIX}/amazon_linux/${ARCHITECTURE}/latest/amazon-cloudwatch-agent.rpm"
  fi

  cat <<EOF >> /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "force_flush_interval": 5,
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/audit/audit.log",
            "log_group_name": "${CWG}",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

  if [ -x /bin/systemctl ] || [ -x /usr/bin/systemctl ]; then
    systemctl enable amazon-cloudwatch-agent.service
    systemctl restart amazon-cloudwatch-agent.service
  else
    start amazon-cloudwatch-agent
  fi
}

setup_os() {
  echo "${FUNCNAME[0]} started"

  echo "Defaults env_keep += \"SSH_CLIENT\"" >> /etc/sudoers

  if [[ "${release}" == "Ubuntu" ]]; then
    user="ubuntu"
    user_group="ubuntu"
  elif [[ "${release}" == "CentOS" ]]; then
    user="centos"
    user_group="centos"
  elif [[ "${release}" == "SLES" ]]; then
    user="ec2-user"
    user_group="users"
  else
    user="ec2-user"
    user_group="ec2-user"
  fi

  if [[ "${release}" == "CentOS" ]]; then
    /sbin/restorecon -v /etc/ssh/sshd_config
  fi

  if [[ "${release}" == "SLES" ]]; then
    zypper install -y bash-completion
    echo "0 0 * * * zypper patch --non-interactive" > ~/mycron
  elif [[ "${release}" == "Ubuntu" ]]; then
    apt-get install -y unattended-upgrades
    apt-get install -y bash-completion
    echo "0 0 * * * unattended-upgrades -d" > ~/mycron
  else
    OS_VERSION=`cat /etc/os-release | grep '^VERSION=' |  tr -d \" | sed 's/\n//g' | sed 's/VERSION=//g'`
    if [[ "${OS_VERSION}" == "2" ]]; then
      amazon-linux-extras install epel
      yum install -y bash-completion
    else
      yum install -y bash-completion --enablerepo=epel
    fi
    echo "0 0 * * * yum -y update --security" > ~/mycron
  fi

  crontab ~/mycron
  rm ~/mycron
  systemctl restart sshd
  echo "${FUNCNAME[0]} ended"
}

# Setup AWS Systems Manager (SSM) agent
setup_ssm() {
  echo "${FUNCNAME[0]} started"
  URL_SUFFIX="${URL_SUFFIX:-amazonaws.com}"

  echo "ssm-user ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/ssm-user

  if [[ "${release}" == 'CentOS' ]]; then
    echo 'Installing the AWS Systems Manager (SSM) agent...'
    yum install -y "https://amazon-ssm-${REGION}.s3.${REGION}.${URL_SUFFIX}/latest/linux_${ARCHITECTURE}/amazon-ssm-agent.rpm"
  fi

  if [[ "${release}" == "Ubuntu" ]]; then
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service
  elif [ -x /bin/systemctl ] || [ -x /usr/bin/systemctl ]; then
    systemctl enable amazon-ssm-agent.service
    systemctl restart amazon-ssm-agent.service
  else
    start amazon-ssm-agent
  fi

  # As of 2022-10-03, the AWS Systems Manager plugin for the AWS CLI is only
  # officially hosted from the `session-manager-downloads` bucket in us-east-1
  # (ie: regional buckets are not yet supported).
  # https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
  echo 'Installing the AWS Systems Manager (SSM) plugin for the AWS CLI...'
  if [[ "${release}" == 'AMZN' ]] || [[ "${release}" == 'CentOS' ]]; then
    yum install -y "https://session-manager-downloads.s3.us-east-1.amazonaws.com/plugin/latest/linux_${ARCHITECTURE2}/session-manager-plugin.rpm"
  elif [[ "${release}" == 'SLES' ]]; then
    zypper install --allow-unsigned-rpm -y "https://session-manager-downloads.s3.us-east-1.amazonaws.com/plugin/latest/linux_${ARCHITECTURE2}/session-manager-plugin.rpm"
  elif [[ "${release}" == 'Ubuntu' ]]; then
    wget "https://session-manager-downloads.s3.us-east-1.amazonaws.com/plugin/latest/ubuntu_${ARCHITECTURE2}/session-manager-plugin.deb"
    dpkg -i -E ./session-manager-plugin.deb
    rm ./session-manager-plugin.deb
  fi
}

request_eip() {
  # Is the already-assigned Public IP an elastic IP?
  _query_assigned_public_ip

  set +e
  _determine_eip_assc_status ${PUBLIC_IP_ADDRESS}
  set -e

  if [[ ${_eip_associated} -eq 0 ]]; then
    echo "The Public IP address associated with eth0 (${PUBLIC_IP_ADDRESS}) is already an Elastic IP. Not proceeding further."
    exit 1
  fi

  EIP_ARRAY=(${EIP_LIST//,/ })
  _eip_assigned_count=0

  for eip in "${EIP_ARRAY[@]}"; do
    if [[ "${eip}" == "Null" ]]; then
      echo "Detected a NULL Value, moving on."
      continue
    fi

    # Determine if the EIP has already been assigned.
    set +e
    _determine_eip_assc_status ${eip}
    set -e
    _determine_eip_allocation ${eip}

    # Attempt to assign EIP to the ENI.
    set +e
    aws ec2 associate-address --instance-id ${INSTANCE_ID} --allocation-id  ${eip_allocation} --region ${REGION}

    rc=$?
    set -e

    if [[ ${rc} -ne 0 ]]; then
      echo "Unable to associate EIP ${eip}. Failure. Exiting"
      exit 1
    fi
  done

  echo "${FUNCNAME[0]} ended"
}

_query_assigned_public_ip() {
  # Note: ETH0 Only.
  # - Does not distinguish between EIP and Standard IP. Need to cross-ref later.
  echo "Querying the assigned public IP"
  PUBLIC_IP_ADDRESS=$(imds_request meta-data/public-ipv4/${ETH0_MAC}/public-ipv4s/)
}

_determine_eip_assc_status() {
  # Is the provided EIP associated?
  # Also determines if an IP is an EIP.
  # 0 => true
  # 1 => false
  echo "Determining EIP Association Status for [${1}]"
  set +e
  aws ec2 describe-addresses --public-ips ${1} --output text --region ${REGION} 2>/dev/null  | grep -o -i eipassoc -q
  rc=$?
  set -e
  if [[ ${rc} -eq 1 ]]; then
    _eip_associated=1
  else
    _eip_associated=0
  fi
}

_determine_eip_allocation() {
  echo "Determining EIP Allocation for [${1}]"
  resource_id_length=$(aws ec2 describe-addresses --public-ips ${1} --output text --region ${REGION} | head -n 1 | awk {'print $2'} | sed 's/.*eipalloc-//')
  if [[ "${#resource_id_length}" -eq 17 ]]; then
    eip_allocation=$(aws ec2 describe-addresses --public-ips ${1} --output text --region ${REGION}| egrep 'eipalloc-([a-z0-9]{17})' -o)
  else
    eip_allocation=$(aws ec2 describe-addresses --public-ips ${1} --output text --region ${REGION}| egrep 'eipalloc-([a-z0-9]{8})' -o)
  fi
}

prevent_process_snooping() {
  # Prevent bastion host users from viewing processes owned by other users.
  mount -o remount,rw,hidepid=2 /proc
  awk '!/proc/' /etc/fstab > temp && mv temp /etc/fstab
  echo "proc /proc proc defaults,hidepid=2 0 0" >> /etc/fstab
  echo "${FUNCNAME[0]} ended"
}

setup_kubeconfig() {
  aws eks update-kubeconfig --name "${K8S_CLUSTER_NAME}"

  mkdir -p /home/${user}/.kube
  cp /root/.kube/config /home/${user}/.kube/
  chown -R ${user}:${user_group} /home/${user}/.kube/

  # Add SSM Config for ssm-user
  set +e
  getent passwd ssm-user > /dev/null
  local ssm_user_exists_result=$?
  set -e
  if [ $ssm_user_exists_result -ne 0 ]; then
    /sbin/useradd -d /home/ssm-user -u 1001 -s /bin/bash -m --user-group ssm-user -c "SSM Session Manager Default User"
  fi

  mkdir -p /home/ssm-user/.kube/
  cp /home/${user}/.kube/config /home/ssm-user/.kube/config
  chown -R ssm-user:ssm-user /home/ssm-user/.kube/
}

install_kubernetes_client_tools() {
  mkdir -p /usr/local/bin/

  # https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
  # You must use a kubectl version that is within one minor version
  # difference of your Amazon EKS cluster control plane. For example, a 1.21
  # kubectl client works with Kubernetes 1.20, 1.21 and 1.22 clusters.
  case "${K8S_VERSION}" in
    "1.20")
      KUBECTL_VERSION="1.21.14/2022-10-31"
    ;;
    "1.21")
      KUBECTL_VERSION="1.22.15/2022-10-31"
    ;;
    "1.22")
      KUBECTL_VERSION="1.23.13/2022-10-31"
    ;;
    "1.23" | "1.24")
      KUBECTL_VERSION="1.24.7/2022-10-31"
    ;;
    *)
      echo "[ERROR] Unsupported kubectl Kubernetes cluster version: '${K8S_VERSION}'"
      exit 1
    ;;
  esac

  retry_command 20 curl --retry 5 -o kubectl "https://amazon-eks.s3-us-west-2.amazonaws.com/${KUBECTL_VERSION}/bin/linux/${ARCHITECTURE}/kubectl"

  chmod +x ./kubectl
  mv ./kubectl /usr/local/bin/
  mkdir -p /root/bin
  ln -s /usr/local/bin/kubectl /root/bin/
  ln -s /usr/local/bin/kubectl /opt/aws/bin
  # https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/#enable-kubectl-autocompletion
  /usr/local/bin/kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

  retry_command 20 curl --retry 5 -o helm.tar.gz "https://get.helm.sh/helm-v3.10.2-linux-${ARCHITECTURE}.tar.gz"

  tar -xvf helm.tar.gz
  chmod +x "./linux-${ARCHITECTURE}/helm"
  mv "./linux-${ARCHITECTURE}/helm" /usr/local/bin/helm
  ln -s /usr/local/bin/helm /opt/aws/bin
  rm -rf "./linux-${ARCHITECTURE}/"
  # https://helm.sh/docs/helm/helm_completion_bash/
  helm completion bash > /etc/bash_completion.d/helm
}
##################################### End Function Definitions

# Call checkos to ensure platform is Linux
checkos
release=$(osrelease)

# Verify dependencies are installed.
verify_dependencies

# Assuming it is, setup environment variables.
setup_environment_variables

## set an initial value
SSH_BANNER="LINUX BASTION"

# Read the options from cli input
TEMP=`getopt -o h --longoptions help,banner:,enable:,tcp-forwarding:,x11-forwarding: -n $0 -- "$@"`
eval set -- "${TEMP}"


if [[ $# == 1 ]]; then
  echo "No input provided! type ($0 --help) to see usage help" >&2
  exit 1
fi

# extract options and their arguments into variables.
while true; do
  case "$1" in
    -h | --help)
      usage
      exit 1
    ;;
    --banner)
      BANNER_PATH="$2";
      shift 2
    ;;
    --enable)
      ENABLE="$2";
      shift 2
    ;;
    --tcp-forwarding)
      TCP_FORWARDING="$2";
      shift 2
    ;;
    --x11-forwarding)
      X11_FORWARDING="$2";
      shift 2
    ;;
    --)
      break
    ;;
    *)
      break
    ;;
  esac
done

# BANNER CONFIGURATION
BANNER_FILE="/etc/ssh_banner"
if [[ ${ENABLE} == "true" ]]; then
  if [[ -z ${BANNER_PATH} ]]; then
    echo "BANNER_PATH is null skipping..."
  else
    echo "BANNER_PATH = ${BANNER_PATH}"
    echo "Creating Banner in ${BANNER_FILE}"
    aws s3 cp "${BANNER_PATH}" "${BANNER_FILE}"  --region ${BANNER_REGION}
    if [[ -e ${BANNER_FILE} ]]; then
      echo "[INFO] Installing banner..."
      echo -e "\n Banner ${BANNER_FILE}" >>/etc/ssh/sshd_config
    else
      echo "[INFO] banner file is not accessible skipping..."
      exit 1;
    fi
  fi
else
  echo "Banner message is not enabled!"
fi

#Enable/Disable TCP forwarding
TCP_FORWARDING=`echo "${TCP_FORWARDING}" | sed 's/\\n//g'`

#Enable/Disable X11 forwarding
X11_FORWARDING=`echo "${X11_FORWARDING}" | sed 's/\\n//g'`

echo "Value of TCP_FORWARDING - ${TCP_FORWARDING}"
echo "Value of X11_FORWARDING - ${X11_FORWARDING}"
if [[ ${TCP_FORWARDING} == "false" ]]; then
  awk '!/AllowTcpForwarding/' /etc/ssh/sshd_config > temp && mv temp /etc/ssh/sshd_config
  echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
fi

if [[ ${X11_FORWARDING} == "false" ]]; then
  awk '!/X11Forwarding/' /etc/ssh/sshd_config > temp && mv temp /etc/ssh/sshd_config
  echo "X11Forwarding no" >> /etc/ssh/sshd_config
fi

if [[ "${release}" == "Operating System Not Found" ]]; then
  echo "[ERROR] Unsupported Linux Bastion OS"
  exit 1
else
  setup_os
  setup_logs
  setup_ssm
  setup_ec2_instance_connect
fi

prevent_process_snooping
request_eip
install_kubernetes_client_tools
setup_kubeconfig

echo "Bootstrap complete."
