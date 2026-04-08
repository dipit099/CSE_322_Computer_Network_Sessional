#!/usr/bin/env bash
# NS-3 ECC-AODV Simulator — Full Experiment Suite
# Student ID: 2105050 → 2105050 % 8 = 2
# Required topologies: Wireless 802.11 mobile + Wireless 802.11 static
# (NOTE: 802.15.4 cannot run AODV — NS-3 AODV is IPv4-only and 802.15.4/6LoWPAN
#  is IPv6-only. We use 802.11 for both mobile and static topologies.)

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================
PROJECT_DIR="/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet"
OUTPUT_DIR="outputs"
LOGS_DIR="logs"

SIM_TIME=30
SEED=1
CC_BASE_THRESHOLD=4

# ECC-AODV optimal weights
W1=0.6
W2=0.2
W3=0.2

# ============================================================================
# REQUIRED PARAMETER VARIATIONS (per report_guidelines.txt)
# ============================================================================
NODE_CONFIGS=("20" "40" "60" "80" "100")
FLOW_CONFIGS=("10" "20" "30" "40" "50")
PPS_CONFIGS=("100" "200" "300" "400" "500")
SPEED_CONFIGS=("5" "10" "15" "20" "25")
AREA_MULTIPLIERS=("1" "2" "3" "4" "5")
PROTOCOL_MODES=("aodv" "cc-aodv" "ecc-aodv")
TOPOLOGIES=("mobile" "static")

PACKET_SIZE=512

run_sim() {
    local proto="$1" topo="$2" nodes="$3" flows="$4" pps="$5" speed="$6" areaMul="$7" outprefix="$8"
    local log="$LOGS_DIR/${outprefix}.log"

    local cmd
    cmd="./ns3 run \"scratch/aodv-simulator \
        --mode=$proto \
        --topology=$topo \
        --nodes=$nodes \
        --time=$SIM_TIME \
        --sinks=$flows \
        --seed=$SEED \
        --minSpeed=$speed --maxSpeed=$speed \
        --areaMultiplier=$areaMul \
        --pps=$pps \
        --packetSize=$PACKET_SIZE \
        --ccBaseThreshold=$CC_BASE_THRESHOLD \
        --w1=$W1 --w2=$W2 --w3=$W3 \
        --trace=false --routeDiscoveryTrace=false --routingTableTrace=false \
        --output=${outprefix} --outputDir=${OUTPUT_DIR}\" 2>&1"

    if timeout 600 bash -c "$cmd" > "$log" 2>&1; then
        local pdr delay tput loss energy
        pdr=$(grep   "^PDR:"                    "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        delay=$(grep "^Avg E2E Delay:"          "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        tput=$(grep  "^Throughput:"             "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        loss=$(grep  "^Packet Loss Rate:"       "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "100")
        energy=$(grep "^Total Energy Consumed:" "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        printf "OK  PDR=%-6s Tput=%-10s E2E=%-10s Loss=%-6s E=%s J\n" \
            "${pdr}%" "${tput}Kbps" "${delay}ms" "${loss}%" "$energy"
    else
        printf "TIMEOUT/FAIL\n"
    fi
}

cd "$PROJECT_DIR"
mkdir -p "$OUTPUT_DIR" "$LOGS_DIR"

echo ">>> Building..."
./ns3 build 2>&1 | tail -3

# Note: this is a heavy "everything" run; for the focused 30-combo run use ./targeted_run.sh
echo "This run.sh is the FULL parameter sweep template. For the focused 30-combo run,"
echo "use ./targeted_run.sh instead. Press Ctrl+C now to abort."
sleep 5

# EXP1 vary nodes
for topo in "${TOPOLOGIES[@]}"; do
    for proto in "${PROTOCOL_MODES[@]}"; do
        for nodes in "${NODE_CONFIGS[@]}"; do
            run_sim "$proto" "$topo" "$nodes" 10 100 5 2 "exp1-${topo}-${proto}-n${nodes}"
            sleep 3
        done
    done
done
