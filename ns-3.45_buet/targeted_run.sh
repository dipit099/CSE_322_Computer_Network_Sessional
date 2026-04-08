#!/usr/bin/env bash
# ECC-AODV Targeted Experiment — 30 combos
# Topologies: 802.11 mobile + 802.11 static  (NO 802.15.4 — AODV is IPv4-only)
# Protocols : aodv, cc-aodv, ecc-aodv
#
# 5 base configs (mobile uses speed, static uses areaMultiplier):
#   nodes=20  flows=10  speed=25 / areaMul=1
#   nodes=40  flows=20  speed=20 / areaMul=2
#   nodes=60  flows=30  speed=15 / areaMul=3
#   nodes=80  flows=40  speed=10 / areaMul=4
#   nodes=100 flows=50  speed=5  / areaMul=5
#
# Total: 5 configs × 2 topologies × 3 protocols = 30 simulations.

set -euo pipefail

PROJECT_DIR="/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet"
OUTPUT_DIR="targetsv3"
LOGS_DIR="targets_logsv3"

SIM_TIME=30
SEED=1
CC_BASE_THRESHOLD=4
W1=0.6
W2=0.2
W3=0.2
PACKET_SIZE=512
PPS=100

# Per-run timeout (seconds). 600s should comfortably accommodate n=100 + 30s sim.
RUN_TIMEOUT=600

# Sleep between runs to keep the laptop cool.
SLEEP_BETWEEN=3

# ----------------------------------------------------------------------------
# Tracing toggles (4 trace types). Set to "true" to enable.
#   PCAP/ASCII PHY trace (wifiPhy.EnablePcap / EnableAsciiAll)  -> ENABLE_TRACE
#   IPv4 drop log + RREQ/RREP/route-table txt logs              -> ENABLE_RD_TRACE
#   Periodic routing-table snapshots                             -> ENABLE_RT_TRACE
#   Mobility log (always on when ENABLE_TRACE=true)              -> (implicit)
# Keep all OFF for the bulk run; turn ON for one-off debugging.
ENABLE_TRACE=false
ENABLE_RD_TRACE=false
ENABLE_RT_TRACE=false
TRACE_INTERVAL=1.0
# ----------------------------------------------------------------------------

# (nodes flows speed areaMul)
declare -a COMBOS=(
    "20  10  25  1"
    "40  20  20  2"
    "60  30  15  3"
    "80  40  10  4"
    "100 50   5  5"
)

PROTOCOLS=("aodv" "cc-aodv" "ecc-aodv")
TOPOLOGIES=("mobile" "static")

run_sim() {
    local proto="$1" topo="$2" nodes="$3" flows="$4" speed="$5" areaMul="$6"
    local prefix="targeted-${topo}-${proto}-n${nodes}-f${flows}-s${speed}-a${areaMul}"
    local log="${LOGS_DIR}/${prefix}.log"

    local cmd
    cmd="./ns3 run \"scratch/aodv-simulator \
        --mode=${proto} \
        --topology=${topo} \
        --nodes=${nodes} \
        --time=${SIM_TIME} \
        --sinks=${flows} \
        --seed=${SEED} \
        --minSpeed=${speed} --maxSpeed=${speed} \
        --areaMultiplier=${areaMul} \
        --pps=${PPS} \
        --packetSize=${PACKET_SIZE} \
        --ccBaseThreshold=${CC_BASE_THRESHOLD} \
        --w1=${W1} --w2=${W2} --w3=${W3} \
        --trace=${ENABLE_TRACE} \
        --routeDiscoveryTrace=${ENABLE_RD_TRACE} \
        --routingTableTrace=${ENABLE_RT_TRACE} \
        --routingTableInterval=${TRACE_INTERVAL} \
        --output=${prefix} \
        --outputDir=${OUTPUT_DIR}\" 2>&1"

    if timeout "${RUN_TIMEOUT}" bash -c "$cmd" > "$log" 2>&1; then
        local pdr delay tput loss energy
        pdr=$(grep   "^PDR:"                    "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        delay=$(grep "^Avg E2E Delay:"          "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        tput=$(grep  "^Throughput:"             "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        loss=$(grep  "^Packet Loss Rate:"       "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "100")
        energy=$(grep "^Total Energy Consumed:" "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        printf "OK   PDR=%-7s Tput=%-12s E2E=%-12s Loss=%-7s E=%s J\n" \
            "${pdr}%" "${tput}Kbps" "${delay}ms" "${loss}%" "$energy"
    else
        printf "TIMEOUT/FAIL  (log: %s)\n" "$log"
    fi
}

# ============================================================================
cd "$PROJECT_DIR"
mkdir -p "$OUTPUT_DIR" "$LOGS_DIR"

echo "============================================================"
echo " ECC-AODV Targeted Run — 30 combos (mobile + static)"
echo " Student ID: 2105050"
echo " sim_time=${SIM_TIME}s  pps=${PPS}  sleep=${SLEEP_BETWEEN}s"
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

for topo in "${TOPOLOGIES[@]}"; do
    echo "============================================================"
    topo_upper=$(echo "$topo" | tr '[:lower:]' '[:upper:]')
    echo " Topology: ${topo_upper}"
    echo "============================================================"
    for combo in "${COMBOS[@]}"; do
        read -r nodes flows speed areaMul <<< "$combo"
        if [[ "$topo" == "mobile" ]]; then
            label="n=${nodes} f=${flows} speed=${speed}m/s"
        else
            label="n=${nodes} f=${flows} area=${areaMul}xTx"
        fi
        echo "------------------------------------------------------------"
        echo " Config: ${label}"
        echo "------------------------------------------------------------"
        for proto in "${PROTOCOLS[@]}"; do
            printf "  %-9s ... " "$proto"
            result=$(run_sim "$proto" "$topo" "$nodes" "$flows" "$speed" "$areaMul")
            echo "$result"
            total=$((total + 1))
            if [[ "$result" == OK* ]]; then ok=$((ok + 1)); else fail=$((fail + 1)); fi
            sleep "$SLEEP_BETWEEN"
        done
        echo ""
    done
done

echo "============================================================"
echo " DONE: $ok/$total succeeded  ($fail failed/timeout)"
echo "============================================================"
echo ""
echo "CSVs in: $OUTPUT_DIR/"
find "$OUTPUT_DIR" -name "targeted-*.csv" 2>/dev/null | sort | while read -r f; do
    echo "  $f  ($(wc -l < "$f") lines)"
done
