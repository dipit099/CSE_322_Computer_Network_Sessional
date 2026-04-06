#!/usr/bin/env bash
# ECC-AODV Targeted Experiment — 30 combos with PPS variation
# Configs: (nodes=20,flows=10,speed=25,pps=500), (40,20,20,400), (60,30,15,300), (80,40,10,200), (100,50,5,100)
# Networks: 802.11, 802.15.4  |  Protocols: aodv, cc-aodv, ecc-aodv
# Total runs: 5 configs × 2 networks × 3 protocols = 30 simulations

set -euo pipefail

PROJECT_DIR="/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet"
OUTPUT_DIR="targetsv2"
LOGS_DIR="targets_logsv2"

SEED=1
CC_BASE_THRESHOLD=4
W1=0.6
W2=0.2
W3=0.2
PACKET_SIZE=512

# (nodes flows speed simtime timeout_sec pps)
declare -a COMBOS=(
    "20  10  25  30  600  500"
    "40  20  20  30  600  400"
    "60  30  15  30  600  300"
    "80  40  10  30  600  200"
    "100 50   5  30  600  100"
)

PROTOCOLS=("aodv" "cc-aodv" "ecc-aodv")
NETWORKS=("802.11" "802.15.4")

run_sim() {
    local proto="$1" net="$2" nodes="$3" flows="$4" speed="$5" simtime="$6" tout="$7" pps="$8"
    local prefix="targeted-${net//./}-${proto}-n${nodes}-f${flows}-s${speed}-p${pps}"
    local log="${LOGS_DIR}/${prefix}.log"

    local cmd
    cmd="./ns3 run \"scratch/aodv-simulator \
        --mode=${proto} \
        --networkType=${net} \
        --nodes=${nodes} \
        --time=${simtime} \
        --sinks=${flows} \
        --seed=${SEED} \
        --minSpeed=${speed} \
        --maxSpeed=${speed} \
        --pps=${pps} \
        --packetSize=${PACKET_SIZE} \
        --ccBaseThreshold=${CC_BASE_THRESHOLD} \
        --w1=${W1} --w2=${W2} --w3=${W3} \
        --trace=false \
        --routeDiscoveryTrace=false \
        --routingTableTrace=false \
        --output=${prefix} \
        --outputDir=${OUTPUT_DIR}\" 2>&1"

    if timeout "${tout}" bash -c "$cmd" > "$log" 2>&1; then
        local pdr delay tput loss energy
        pdr=$(grep   "^PDR:"                    "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        delay=$(grep "^Avg E2E Delay:"          "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        tput=$(grep  "^Throughput:"             "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        loss=$(grep  "^Packet Loss Rate:"       "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "100")
        energy=$(grep "^Total Energy Consumed:" "$log" | grep -oE '[0-9]+\.[0-9]+'  | head -1 || echo "0")
        printf "OK   PDR=%-6s Tput=%-10s E2E=%-10s Loss=%-6s E=%s J\n" \
            "${pdr}%" "${tput}Kbps" "${delay}ms" "${loss}%" "$energy"
    else
        printf "TIMEOUT/FAIL  (log: %s)\n" "$log"
    fi
}

# ============================================================================
cd "$PROJECT_DIR"
mkdir -p "$OUTPUT_DIR" "$LOGS_DIR"

echo "============================================================"
echo " ECC-AODV Targeted Run — 30 combos"
echo " Student ID: 2105050"
echo "============================================================"
echo ""

echo ">>> Building..."
if ./ns3 build 2>&1 | tail -3; then
    echo "Build OK"
else
    echo "Build FAILED — aborting"; exit 1
fi
echo ""

total=0; ok=0; fail=0

for combo in "${COMBOS[@]}"; do
    read -r nodes flows speed simtime tout pps <<< "$combo"
    echo "------------------------------------------------------------"
    echo " Config: nodes=$nodes  flows=$flows  speed=$speed m/s  pps=$pps  simtime=${simtime}s"
    echo "------------------------------------------------------------"
    for net in "${NETWORKS[@]}"; do
        for proto in "${PROTOCOLS[@]}"; do
            printf "  %-10s %-10s n=%-4s f=%-4s s=%-4s p=%-4s ... " "$net" "$proto" "$nodes" "$flows" "$speed" "$pps"
            result=$(run_sim "$proto" "$net" "$nodes" "$flows" "$speed" "$simtime" "$tout" "$pps")
            echo "$result"
            total=$((total + 1))
            if [[ "$result" == OK* ]]; then ok=$((ok + 1)); else fail=$((fail + 1)); fi
        done
    done
    echo ""
done

echo "============================================================"
echo " DONE: $ok/$total succeeded  ($fail failed/timeout)"
echo "============================================================"
echo ""

# echo "CSVs in: $OUTPUT_DIR/"
# find "$OUTPUT_DIR" -name "targeted-*.csv" 2>/dev/null | sort | while read -r f; do
#     echo "  $f  ($(wc -l < "$f") lines)"
#done
