#!/bin/bash
################################################################################
# Script to run Flat Physical Synthesis (Task 4)
################################################################################
#
# Usage: ./run_flat_pnr.sh
# Or: bash run_flat_pnr.sh
#
# This script runs flat physical synthesis without partitioning
################################################################################

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/../.." && pwd )"

# Change to exe directory (where Innovus should be run from)
cd "${PROJECT_ROOT}/phy/exe" || {
    echo "Error: Cannot change to exe directory"
    exit 1
}

# Check if Innovus is available
if ! command -v innovus &> /dev/null; then
    echo "Error: innovus command not found. Please check your PATH."
    exit 1
fi

echo "=========================================="
echo "Running Flat Physical Synthesis (Task 4)"
echo "=========================================="
echo "Project root: ${PROJECT_ROOT}"
echo "Working directory: $(pwd)"
echo ""

# Check if required files exist
if [ ! -f "../scr/pnr_flat.tcl" ]; then
    echo "Error: pnr_flat.tcl not found"
    exit 1
fi

if [ ! -f "../scr/global_variables.tcl" ]; then
    echo "Error: global_variables.tcl not found"
    exit 1
fi

# Create log directory if it doesn't exist
mkdir -p ../log

# Get timestamp for log files
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Run Innovus
echo "Starting Innovus..."
echo "Log files will be saved to: ../log/flat_pnr_${TIMESTAMP}.log"
echo ""

# Innovus -log option automatically creates .log, .cmd, and .logv files
# Format: -log "log_file cmd_file logv_file" (3 files) or just prefix (auto-named)
innovus -stylus -batch -files ../phy/scr/pnr_flat.tcl \
    -log "../log/flat_pnr_${TIMESTAMP}"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Flat Physical Synthesis Complete!"
    echo "=========================================="
    echo "Reports: ../phy/rpt/flat/"
    echo "Outputs: ../phy/db/flat/"
    echo "Logs: ../log/flat_pnr_${TIMESTAMP}.log, .cmd, .logv"
else
    echo ""
    echo "=========================================="
    echo "Error: Flat Physical Synthesis Failed"
    echo "=========================================="
    echo "Check log files: ../log/flat_pnr_${TIMESTAMP}.*"
    exit $EXIT_CODE
fi

