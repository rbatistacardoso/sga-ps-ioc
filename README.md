# Sorensen SGA/SGI EPICS IOC

This repository contains an **EPICS IOC** that uses the StreamDevice module to communicate with Sorensen SGA and SGI series power supplies. Only a small subset of common SCPI commands is implemented, providing a lightweight interface for basic control and monitoring.

The project comes with a `Dockerfile` and a `docker-compose.yaml` for easy deployment. The images bundle EPICS Base, Asyn, and StreamDevice, along with the IOC database, protocol file and boot scripts.

## Features

- Implements common commands shared by both SGA and SGI models
- Uses *StreamDevice* over TCP/IP for communication
- Two example power supplies defined in `st.cmd`
- Runtime managed by `procServ`

## Building the Docker image

Clone this repository and run:

```bash
docker compose build
```

This will execute the [Dockerfile](Dockerfile), installing EPICS and copying the IOC files into the image. The EPICS installation steps can be seen in [`scripts/install_epics.sh`](scripts/install_epics.sh).

## Running the IOC

After building, launch the container with:

```bash
docker compose up
```

The container runs in *host* network mode as configured in [`docker-compose.yaml`](docker-compose.yaml). Logs are printed to stdout and can be viewed with `docker logs power_supplies_ioc`.

The IOC boots using [`ioc/iocBoot/st.cmd`](ioc/iocBoot/st.cmd) which loads the protocol file and database from `ioc/`. Two ports are configured: `PS1` and `PS2`. Adjust the IP addresses in `st.cmd` to match your hardware.

## Repository layout

```
.
├── Dockerfile            # Build instructions for the IOC image
├── docker-compose.yaml   # Compose file to run the container
├── ioc/
│   ├── db/ps.db          # EPICS records using StreamDevice
│   ├── protocol/common.proto  # SCPI commands for SGA/SGI
│   ├── iocBoot/st.cmd    # IOC startup script
│   └── run_ioc.sh        # Entrypoint executed by the container
└── scripts/
    ├── install_epics.sh  # Helper script that builds EPICS & modules
    └── test_power_supply.py  # Small CLI to test the power supply
```

## Usage example

With the IOC running you can access PVs such as `SGA:getOutVoltage` or `SGI:setRemoteMode`. The protocol file [`common.proto`](ioc/protocol/common.proto) defines how these PVs map to SCPI commands.

## License

This project is released under the MIT license.
