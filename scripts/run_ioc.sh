#!/usr/bin/env bash
set -euo pipefail

# Configure EPICS environment
EPICS_BASE_VERSION="7.0.8"
EPICS_HOST_ARCH="linux-x86_64"
EPICS_BASE_DIR="/opt/epics-${EPICS_BASE_VERSION}/base"
export PATH="${EPICS_BASE_DIR}/bin/${EPICS_HOST_ARCH}:${PATH}"

cd /ioc/iocBoot
exec procServ --foreground -n sga-ps-ioc 2000 ./st.cmd