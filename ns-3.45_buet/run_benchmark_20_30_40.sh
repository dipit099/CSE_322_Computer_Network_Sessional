#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet"
cd "$PROJECT_DIR"

OUTPUT_PREFIX="benchmark-20-30-40"
RESULT_CSV="outputs/${OUTPUT_PREFIX}-results.csv"

TIME_SEC=30
SEED=1
CC_BASE_THRESHOLD=4
MODES=(aodv cc-aodv ecc-aodv)

# Node configurations: nodes, sinks
CONFIGS=(
  "20:10"
  "30:15"
  "40:20"
)

# Speed profiles: min max
SPEED_CONFIGS=(
  "0:5"    # static
  "4:10"   # mobile
)

echo "[1/3] Building..."
./ns3 build 2>&1 | tail -5

echo "[2/3] Creating output directory..."
mkdir -p outputs
rm -f "$RESULT_CSV"

echo "[3/3] Running benchmarks (20/30/40 nodes, AODV/CC-AODV/ECC-AODV, 2 speed profiles)..."
RUN_COUNT=0

for config in "${CONFIGS[@]}"; do
  IFS=':' read -r nodes sinks <<< "$config"
  
  for speed_config in "${SPEED_CONFIGS[@]}"; do
    IFS=':' read -r min_speed max_speed <<< "$speed_config"
    
    for mode in "${MODES[@]}"; do
      RUN_COUNT=$((RUN_COUNT + 1))
      echo "[$RUN_COUNT/18] nodes=$nodes, sinks=$sinks, speed=$min_speed-$max_speed m/s, mode=$mode"
      
      ./ns3 run "scratch/aodv-simulator --mode=${mode} --nodes=${nodes} --time=${TIME_SEC} --sinks=${sinks} --seed=${SEED} --minSpeed=${min_speed} --maxSpeed=${max_speed} --ccBaseThreshold=${CC_BASE_THRESHOLD} --output=${OUTPUT_PREFIX}" 2>&1 | grep -E "PDR|Delay|Throughput" || true
    done
  done
done

echo ""
echo "Results saved to: $RESULT_CSV"
echo "Total runs completed: $RUN_COUNT"
