#!/usr/bin/env bash
# ECC-AODV Parameter Tuning (CSV-only, tracing disabled)

set -euo pipefail

PROJECT_DIR="/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet"
cd "$PROJECT_DIR"

PARAM_RESULTS_CSV="outputs/ecc-param-tuning-results.csv"

TIME_SEC=30
SEED=1
CC_BASE_THRESHOLD=4

# Test configurations: (w1:w2:w3) - QACD weights
# w1=queue, w2=counter_ratio, w3=drop_rate
PARAM_CONFIGS=(
  "0.3:0.4:0.3"   # Balanced (default proposal)
  "0.5:0.3:0.2"   # Queue-heavy
  "0.2:0.5:0.3"   # Counter-heavy
  "0.3:0.3:0.4"   # Drop-rate-heavy
  "0.4:0.4:0.2"   # Queue+Counter
  "0.1:0.5:0.4"   # Minimal queue, max counter
  "0.6:0.2:0.2"   # Very queue-heavy
  "0.2:0.2:0.6"   # Very drop-rate-heavy
)

# Node configurations: nodes:sinks
CONFIGS=(
  "20:10"
  "30:15"
  "40:20"
)

SPEED_CONFIGS=(
  "0:5"    # static
  "4:10"   # mobile
)

echo "=========================================="
echo "ECC-AODV Parameter Tuning"
echo "=========================================="
echo "Test configs: ${#PARAM_CONFIGS[@]} parameter sets"
echo "Node configs: ${#CONFIGS[@]} node configurations"
echo "Speed configs: ${#SPEED_CONFIGS[@]} speed profiles"
echo "Total runs planned: $((${#PARAM_CONFIGS[@]} * ${#CONFIGS[@]} * ${#SPEED_CONFIGS[@]}))"
echo "Tracing: disabled"
echo ""

# Initialize CSV header
cat > "$PARAM_RESULTS_CSV" << 'CSVEOF'
nodes,sinks,speed_min,speed_max,w1,w2,w3,pdr,delay_ms,throughput_kbps,loss_rate
CSVEOF

RUN_COUNT=0
TOTAL_RUNS=$((${#PARAM_CONFIGS[@]} * ${#CONFIGS[@]} * ${#SPEED_CONFIGS[@]}))

for nodes_config in "${CONFIGS[@]}"; do
  IFS=':' read -r nodes sinks <<< "$nodes_config"
  
  for speed_config in "${SPEED_CONFIGS[@]}"; do
    IFS=':' read -r min_speed max_speed <<< "$speed_config"
    
    for param_config in "${PARAM_CONFIGS[@]}"; do
      IFS=':' read -r w1 w2 w3 <<< "$param_config"
      
      RUN_COUNT=$((RUN_COUNT + 1))
      PERCENT=$((RUN_COUNT * 100 / TOTAL_RUNS))
      
      printf "[%2d/%d %3d%%] n=%d speed=%s-%s w=(%s,%s,%s) ... " \
        "$RUN_COUNT" "$TOTAL_RUNS" "$PERCENT" "$nodes" "$min_speed" "$max_speed" "$w1" "$w2" "$w3"
      
      OUTPUT=$(timeout 70 ./ns3 run "scratch/aodv-simulator \
        --mode=ecc-aodv \
        --nodes=${nodes} \
        --time=${TIME_SEC} \
        --sinks=${sinks} \
        --seed=${SEED} \
        --minSpeed=${min_speed} \
        --maxSpeed=${max_speed} \
        --ccBaseThreshold=${CC_BASE_THRESHOLD} \
        --w1=${w1} --w2=${w2} --w3=${w3} \
        --trace=false" 2>&1 || true)
      
      PDR=$(echo "$OUTPUT" | grep "PDR:" | sed 's/.*PDR:[[:space:]]*//' | sed 's/[[:space:]]*%.*//' | tail -1)
      DELAY=$(echo "$OUTPUT" | grep "Avg E2E Delay:" | sed 's/.*Avg E2E Delay:[[:space:]]*//' | sed 's/[[:space:]]*ms.*//' | tail -1)
      THROUGHPUT=$(echo "$OUTPUT" | grep "Throughput:" | sed 's/.*Throughput:[[:space:]]*//' | sed 's/[[:space:]]*Kbps.*//' | tail -1)
      LOSS_RATE=$(echo "$OUTPUT" | grep "Packet Loss Rate:" | sed 's/.*Packet Loss Rate:[[:space:]]*//' | sed 's/[[:space:]]*%.*//' | tail -1)

      PDR=${PDR:-0}
      DELAY=${DELAY:-0}
      THROUGHPUT=${THROUGHPUT:-0}
      LOSS_RATE=${LOSS_RATE:-100}
      
      # Write CSV
      echo "$nodes,$sinks,$min_speed,$max_speed,$w1,$w2,$w3,$PDR,$DELAY,$THROUGHPUT,$LOSS_RATE" >> "$PARAM_RESULTS_CSV"

      echo "PDR=${PDR}%"
    done
  done
done

echo ""
echo "=========================================="
echo "Parameter tuning complete!"
echo "Results saved to: $PARAM_RESULTS_CSV"
echo "=========================================="

echo "Top 5 by PDR:"
tail -n +2 "$PARAM_RESULTS_CSV" | sort -t',' -k8 -nr | head -5 | awk -F',' '{printf "  n=%s speed=%s-%s w=(%s,%s,%s) PDR=%s%% Delay=%sms TP=%sKbps\n", $1,$3,$4,$5,$6,$7,$8,$9,$10}'
