#!/usr/bin/env bash
##############################################################################
# EPICS Base + modules installer
#  * Base 7.0.8 (default)          – https://epics-controls.org/download/base
#  * asyn R4-45                    – https://github.com/epics-modules/asyn
#  * s7plc 1.5.2                   – https://github.com/paulscherrerinstitute/s7plc
#
# Usage examples:
#   ./install_epics.sh base s7plc asyn
#   ./install_epics.sh asyn        # only build asyn (assumes base exists)
##############################################################################
set -euo pipefail

# ---------- Versions --------------------------------------------------------
EPICS_BASE_VERSION="7.0.8"
ASYN_VERSION="R4-45"
STREAMDEV_VERSION="2.8.26"
S7PLC_VERSION="1.5.2"

# ---------- Architecture / paths -------------------------------------------
EPICS_HOST_ARCH="linux-x86_64"
EPICS_ROOT="/opt/epics-${EPICS_BASE_VERSION}"
EPICS_BASE_DIR="${EPICS_ROOT}/base"
EPICS_MODULES="${EPICS_ROOT}/modules"
JOBS=$(nproc)

# ---------- Environment -----------------------------------------------------
export EPICS_BASE_DIR
export PATH="${EPICS_BASE_DIR}/bin/${EPICS_HOST_ARCH}:${PATH}"

# ---------- Helpers ---------------------------------------------------------
create_directories() {
    for dir in "$@"; do
        [[ -d "$dir" ]] || { mkdir -p "$dir"; echo "Created: $dir"; }
    done
}

# Build any module (tarball URL, dir name)
build_module() {
    local url="$1" dirname="$2"
    cd "${EPICS_MODULES}"

    [[ -d "$dirname" ]] || {
        echo ">> Fetching $dirname …"
        curl -L "$url" -o module.tgz
        tar xf module.tgz
        rm module.tgz
    }

    cd "$dirname"

    # Uncomment TIRPC=NO if building asyn
    if [[ "$dirname" == asyn-* ]]; then
        echo ">> Patching CONFIG_SITE for TIRPC support (asyn)"
        sed -i 's/^#\s*\(TIRPC=YES\)/\1/' configure/CONFIG_SITE
    fi

    # RELEASE.local → EPICS_BASE
    cat > configure/RELEASE.local <<-EOF
    EPICS_BASE=${EPICS_BASE_DIR}
EOF

    echo ">> Building $dirname …"
    make -sj"${JOBS}"
}

# ---------- Installers ------------------------------------------------------
base_install() {
    local caget_bin="${EPICS_BASE_DIR}/bin/${EPICS_HOST_ARCH}/caget"

    if [[ -f "${caget_bin}" ]]; then
        echo ">> EPICS Base already installed (found ${caget_bin}), skipping build."
    else
        echo ">> EPICS Base not found; installing into ${EPICS_BASE_DIR} …"
        echo ">> Installing EPICS Base Dependencies …"
        apt update
        #!/bin/sh

        echo "Installing epics dependencies"

        apt install -y build-essential

        cd "${EPICS_ROOT}" || exit
        # Download and unpack
        curl -L "https://epics-controls.org/download/base/base-${EPICS_BASE_VERSION}.tar.gz" -o base.tar.gz
        tar -xzf base.tar.gz
        cp -r base-7.0.8/* base
        rm base.tar.gz
        rm -r "./base-${EPICS_BASE_VERSION}"
        cd base || exit

        # Build
        echo ">> Building EPICS Base …"
        make -C "${EPICS_BASE_DIR}" -sj"${JOBS}"
    fi
}

asyn_install() {
    apt install -y libtirpc-dev rpcbind
    build_module \
        "https://github.com/epics-modules/asyn/archive/refs/tags/${ASYN_VERSION}.tar.gz" \
        "asyn-${ASYN_VERSION}"
}

streamdevice_install() {
    local url="https://github.com/paulscherrerinstitute/StreamDevice/archive/refs/tags/${STREAMDEV_VERSION}.tar.gz"
    local dirname="StreamDevice-${STREAMDEV_VERSION}"

    echo ">> Installing StreamDevice ${STREAMDEV_VERSION} …"
    cd "${EPICS_MODULES}"

    if [[ ! -d "$dirname" ]]; then
        curl -L "$url" -o stream.tgz
        tar xf stream.tgz && rm stream.tgz
    fi

    cd "$dirname"

    # Patch configure/RELEASE:
    #  - Comment out CALC and PCRE
    #  - Rewrite ASYN and EPICS_BASE
    sed -i -e 's|^CALC=.*|#&|' \
           -e 's|^PCRE=.*|#&|' \
           -e 's|^SUPPORT=.*|#&|' \
           -e 's|^-include=.*|#&|' \
           -e "s|^ASYN=.*|ASYN=${EPICS_MODULES}/asyn-${ASYN_VERSION}|" \
           -e "s|^EPICS_BASE=.*|EPICS_BASE=${EPICS_BASE_DIR}|" \
           configure/RELEASE

    echo ">> Building StreamDevice …"
    make -sj"${JOBS}"
}

s7plc_install() {
    build_module \
        "https://github.com/paulscherrerinstitute/s7plc/archive/refs/tags/${S7PLC_VERSION}.tar.gz"
\
        "s7plc-${S7PLC_VERSION}"
}

# ---------- Dispatcher ------------------------------------------------------
install() {
    for arg in "$@"; do
        case "$arg" in
            base)   base_install   ;;
            asyn)   asyn_install   ;;
            s7plc)  s7plc_install  ;;
            streamdevice) streamdevice_install;;
            *) echo "Invalid arg: $arg (allowed: base asyn s7plc)"; exit 1 ;;
        esac
    done
}

# ---------- Main ------------------------------------------------------------
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [base] [asyn] [s7plc]"
    exit 1
fi

create_directories "${EPICS_ROOT}" "${EPICS_BASE_DIR}" "${EPICS_MODULES}"
install "$@"

echo -e "\n✔ Installation complete."
echo "Add to your shell startup file:"
echo "  export EPICS_BASE_DIR=${EPICS_BASE_DIR}"
echo "  export PATH=\$EPICS_BASE_DIR/bin/${EPICS_HOST_ARCH}:\$PATH"