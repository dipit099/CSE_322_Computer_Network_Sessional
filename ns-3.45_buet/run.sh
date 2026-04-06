#!/usr/bin/env bash
# NS-3 ECC-AODV Simulator — Full Experiment Suite
# Student ID: 2105050 → 2105050 % 8 = 2
# Required: Wireless 802.11 (mobile) + Wireless 802.15.4 (mobile)

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

# ECC-AODV optimal weights (from param tuning: w1=0.6,w2=0.2,w3=0.2 best for most cases)
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
PROTOCOL_MODES=("aodv" "cc-aodv" "ecc-aodv")
NETWORK_TYPES=("802.11" "802.15.4")

# ============================================================================
# Tracing (disabled for batch runs to save disk space)
# ============================================================================
ENABLE_PCAP=false
ENABLE_ROUTE_DISCOVERY=false
ENABLE_ROUTING_TABLE=false
TRACE_INTERVAL=1.0
PCAP_NODES="0"
ASCII_NODES="0"
PACKET_SIZE=512

# ============================================================================
# HELPER
# ============================================================================
run_sim() {
    local proto="$1" net="$2" nodes="$3" flows="$4" pps="$5" speed="$6" outprefix="$7"
    local log="$LOGS_DIR/${outprefix}.log"

    local cmd
    cmd="./ns3 run \"scratch/aodv-simulator \
        --mode=$proto \
        --networkType=$net \
        --nodes=$nodes \
        --time=$SIM_TIME \
        --sinks=$flows \
        --seed=$SEED \
        --minSpeed=$speed \
        --maxSpeed=$speed \
        --pps=$pps \
        --packetSize=$PACKET_SIZE \
        --ccBaseThreshold=$CC_BASE_THRESHOLD \
        --w1=$W1 \
        --w2=$W2 \
        --w3=$W3 \
        --trace=false \
        --routeDiscoveryTrace=false \
        --routingTableTrace=false \
        --output=${outprefix} \
        --outputDir=${OUTPUT_DIR}\" 2>&1"

    if timeout 120 bash -c "$cmd" > "$log" 2>&1; then
        local pdr delay tput loss energy
        # macOS-compatible extraction (no -P flag): match pattern then extract number
        pdr=$(grep   "^PDR:"              "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        delay=$(grep "^Avg E2E Delay:"   "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        tput=$(grep  "^Throughput:"       "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        loss=$(grep  "^Packet Loss Rate:" "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "100")
        energy=$(grep "^Total Energy Consumed:" "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        printf "OK  PDR=%-6s Tput=%-8s E2E=%-8s Loss=%-6s Energy=%s J\n" \
            "${pdr}%" "${tput}Kbps" "${delay}ms" "${loss}%" "$energy"
    else
        printf "TIMEOUT/FAIL\n"
    fi
}

# ============================================================================
# MAIN
# ============================================================================
cd "$PROJECT_DIR"

echo "========================================================"
echo " ECC-AODV Full Experiment Suite — Student ID 2105050"
echo "========================================================"
echo ""

# Build
echo ">>> Building..."
if ./ns3 build 2>&1 | tail -3; then
    echo "Build OK"
else
    echo "Build FAILED — aborting"
    exit 1
fi
echo ""

mkdir -p "$OUTPUT_DIR" "$LOGS_DIR"

# ======================================================
# EXPERIMENT 1: Vary Number of Nodes (20,40,60,80,100)
#   Fixed: flows=10, pps=100, speed=5 m/s
# ======================================================
echo "========================================================"
echo "EXP 1: Vary Number of Nodes (flows=10, pps=100, speed=5)"
echo "========================================================"
for net in "${NETWORK_TYPES[@]}"; do
    for proto in "${PROTOCOL_MODES[@]}"; do
        for nodes in "${NODE_CONFIGS[@]}"; do
            local_flows=10
            if [ "$local_flows" -gt "$((nodes / 2))" ]; then local_flows=$((nodes / 2)); fi
            prefix="exp1-${net//./}-${proto}-n${nodes}"
            printf "  [EXP1] net=%-8s proto=%-8s nodes=%-4s ... " "$net" "$proto" "$nodes"
            run_sim "$proto" "$net" "$nodes" "$local_flows" 100 5 "$prefix"
        done
    done
done

# ======================================================
# EXPERIMENT 2: Vary Number of Flows (10,20,30,40,50)
#   Fixed: nodes=40, pps=100, speed=5 m/s
# ======================================================
echo ""
echo "========================================================"
echo "EXP 2: Vary Number of Flows (nodes=40, pps=100, speed=5)"
echo "========================================================"
for net in "${NETWORK_TYPES[@]}"; do
    for proto in "${PROTOCOL_MODES[@]}"; do
        for flows in "${FLOW_CONFIGS[@]}"; do
            local_flows=$flows
            if [ "$local_flows" -gt 20 ]; then local_flows=20; fi  # max 50% of 40 nodes
            prefix="exp2-${net//./}-${proto}-f${flows}"
            printf "  [EXP2] net=%-8s proto=%-8s flows=%-4s ... " "$net" "$proto" "$flows"
            run_sim "$proto" "$net" 40 "$local_flows" 100 5 "$prefix"
        done
    done
done

# ======================================================
# EXPERIMENT 3: Vary Packets Per Second (100..500)
#   Fixed: nodes=40, flows=10, speed=5 m/s
# ======================================================
echo ""
echo "========================================================"
echo "EXP 3: Vary PPS (nodes=40, flows=10, speed=5)"
echo "========================================================"
for net in "${NETWORK_TYPES[@]}"; do
    for proto in "${PROTOCOL_MODES[@]}"; do
        for pps in "${PPS_CONFIGS[@]}"; do
            prefix="exp3-${net//./}-${proto}-pps${pps}"
            printf "  [EXP3] net=%-8s proto=%-8s pps=%-5s ... " "$net" "$proto" "$pps"
            run_sim "$proto" "$net" 40 10 "$pps" 5 "$prefix"
        done
    done
done

# ======================================================
# EXPERIMENT 4: Vary Speed (5,10,15,20,25 m/s)
#   Fixed: nodes=40, flows=10, pps=100
# ======================================================
echo ""
echo "========================================================"
echo "EXP 4: Vary Speed (nodes=40, flows=10, pps=100)"
echo "========================================================"
for net in "${NETWORK_TYPES[@]}"; do
    for proto in "${PROTOCOL_MODES[@]}"; do
        for speed in "${SPEED_CONFIGS[@]}"; do
            prefix="exp4-${net//./}-${proto}-s${speed}"
            printf "  [EXP4] net=%-8s proto=%-8s speed=%-4s ... " "$net" "$proto" "$speed"
            run_sim "$proto" "$net" 40 10 100 "$speed" "$prefix"
        done
    done
done

# ======================================================
# SUMMARY
# ======================================================
echo ""
echo "========================================================"
echo " ALL EXPERIMENTS COMPLETE"
echo "========================================================"
echo ""
echo "Results CSVs:"
find "$OUTPUT_DIR" -name "*.csv" | sort | while read -r f; do
    echo "  $f  ($(wc -l < "$f") lines)"
done
echo ""
echo "Log files: $LOGS_DIR/"
echo ""
echo "Done."
