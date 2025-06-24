#!/usr/bin/env bash
set -euo pipefail

cd ~/sga-ps-ioc/ioc/iocBoot/

procServ \
  --name PowerSuppliesIOC \
  --pidfile /var/run/PowerSuppliesIOC.pid \
  --logfile /var/log/PowerSuppliesIOC.log \
  5001                     \
  ~/sga-ps-ioc/ioc/iocBoot/st.cmd
