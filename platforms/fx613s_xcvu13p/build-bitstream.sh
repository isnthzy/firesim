#!/bin/bash

# This script is called by FireSim's bitbuilder to create a bit file

# exit script if any command fails
set -e
set -o pipefail

REQUIRED_VIVADO_VERSION="2022.1"
VIVADO_ROOT="${FX613S_VIVADO_ROOT:-/nfs/tools/xilinx/2022.1/Vivado/2022.1}"

if [ -x "$VIVADO_ROOT/bin/vivado" ]; then
    export XILINX_VIVADO="$VIVADO_ROOT"
    export PATH="$XILINX_VIVADO/bin:$PATH"
fi

if ! command -v vivado >/dev/null 2>&1; then
    echo "Vivado $REQUIRED_VIVADO_VERSION is required but was not found" >&2
    exit 1
fi

vivado_version=$(vivado -version 2>/dev/null | sed -n 's/^Vivado v\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' | head -n 1)
if [ "$vivado_version" != "$REQUIRED_VIVADO_VERSION" ]; then
    echo "Vivado $REQUIRED_VIVADO_VERSION is required; found ${vivado_version:-unknown}" >&2
    exit 1
fi

if [ -z "${LM_LICENSE_FILE:-}" ] && [ -n "${XILINXD_LICENSE_FILE:-}" ]; then
    export LM_LICENSE_FILE="$XILINXD_LICENSE_FILE"
fi

usage() {
    echo "usage: ${0} [OPTIONS]"
    echo ""
    echo "Options"
    echo "   --cl_dir    : Custom logic directory to build Vivado bitstream from"
    echo "   --frequency : Frequency in MHz of the desired FPGA host clock."
    echo "   --strategy  : A string to a precanned set of build directives.
                          See aws-fpga documentation for more info/.
                          For this platform TIMING and AREA supported."
    echo "   --board     : FPGA board {fx613s_xcvu13p}."
    echo "   --help      : Display this message"
    exit "$1"
}

CL_DIR=""
FREQUENCY=""
STRATEGY=""
BOARD=""

# getopts does not support long options, and is inflexible
while [ "$1" != "" ];
do
    case $1 in
        --help)
            usage 1 ;;
        --cl_dir )
            shift
            CL_DIR=$1 ;;
        --strategy )
            shift
            STRATEGY=$1 ;;
        --frequency )
            shift
            FREQUENCY=$1 ;;
        --board )
            shift
            BOARD=$1 ;;
        * )
            echo "invalid option $1"
            usage 1 ;;
    esac
    shift
done

if [ -z "$CL_DIR" ] ; then
    echo "no cl directory specified"
    usage 1
fi

if [ -z "$FREQUENCY" ] ; then
    echo "No --frequency specified"
    usage 1
fi

if [ -z "$STRATEGY" ] ; then
    echo "No --strategy specified"
    usage 1
fi

if [ -z "$BOARD" ] ; then
    echo "No --board specified"
    usage 1
fi

# run build
cd "$CL_DIR"
vivado -mode batch -source "$CL_DIR/scripts/main.tcl" -tclargs "$FREQUENCY" "$STRATEGY" "$BOARD"
