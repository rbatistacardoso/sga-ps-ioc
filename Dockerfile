FROM debian:12

WORKDIR /tmp

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl build-essential libtirpc-dev rpcbind procserv \
    && rm -rf /var/lib/apt/lists/*

# Copy installer and install EPICS base and modules
COPY scripts/install_epics.sh /tmp/epics_install.sh
RUN chmod +x /tmp/epics_install.sh \
    && /tmp/epics_install.sh base asyn streamdevice \
    && rm /tmp/epics_install.sh

# Copy IOC files
COPY ioc/ /ioc/

# Copy run script
COPY scripts/run_ioc.sh /ioc/run_ioc.sh
RUN chmod +x /ioc/run_ioc.sh

WORKDIR /opt/ioc
 
ENTRYPOINT ["/ioc/run_ioc.sh"]
# ENTRYPOINT ["/bin/sh", "-c", "sleep infinity"]