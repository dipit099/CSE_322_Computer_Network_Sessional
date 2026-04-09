#!/usr/bin/env bash
# ECC-AODV Targeted Sweep — 802.11 Mobile + Static
# Protocols: aodv, cc-aodv, ecc-aodv
#
# Column-wise pairing: index i uses NODES[i], FLOWS[i], PPS[i], SPEEDS[i] together.
# Mobile:  MOBILE_NODES[i] + MOBILE_FLOWS[i] + MOBILE_PPS[i] + MOBILE_SPEEDS[i]
# Static:  STATIC_NODES[i] + STATIC_FLOWS[i] + STATIC_PPS[i] + STATIC_AREAS[i]
#
# Total: (mobile_rows + static_rows) × 3 protocols

set -euo pipefail

PROJECT_DIR="/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet"
OUTPUT_DIR="targets_final"
LOGS_DIR="targets_final_logs"
REPORT_FILE="${OUTPUT_DIR}/targeted-winners-and-metrics.txt"

SIM_TIME=30
SEED=1
CC_BASE_THRESHOLD=4
W1=0.6    # QACD weight: queue occupancy
W2=0.2    # QACD weight: counter ratio
W3=0.2    # QACD weight: data drop rate
PACKET_SIZE=512

RUN_TIMEOUT=600   # per-run timeout in seconds
SLEEP_BETWEEN=3   # seconds between runs (keeps laptop cool)

# -----------------------------------------------------------------------
# Tracing toggles — set to "true" to enable.
#
#  ENABLE_TRACE       -> PHY ASCII .tr + PCAP + IPv4 drop log + mobility log
#  ENABLE_RD_TRACE    -> RREQ/RREP packet logs     (needs ENABLE_TRACE=true)
#  ENABLE_RT_TRACE    -> Routing table snapshots    (needs ENABLE_TRACE=true)
#  ENABLE_PER_NODE_TPUT -> per-node throughput CSV  (Bonus B, standalone)
#  ENABLE_QUEUE_TRACE   -> queue-size-over-time CSV (Bonus C, standalone)
#  QUEUE_POLL_INTERVAL  -> seconds between queue samples
#
# All OFF for bulk runs; flip individually for targeted single runs.
ENABLE_TRACE=false
ENABLE_RD_TRACE=false
ENABLE_RT_TRACE=false
TRACE_INTERVAL=1.0
ENABLE_PER_NODE_TPUT=false
ENABLE_QUEUE_TRACE=false
QUEUE_POLL_INTERVAL=1.0
# -----------------------------------------------------------------------

# Edit these arrays to change the experiment configs.
# All four MOBILE_* arrays must be the same length.
# All four STATIC_* arrays must be the same length.
# COLUMN WISE VALYYES CONSIDERING

MOBILE_NODES=(20 20 40 40 60 60 80 100)
MOBILE_FLOWS=(10 20 10 20 30 30 40 50)
MOBILE_PPS=(100 200 100 200 400 300 400 500)
MOBILE_SPEEDS=(5 20 25 10 5 15 10 15)

STATIC_NODES=(20 20 40 40 60 60 80 100)
STATIC_FLOWS=(10 20 20 30 20 30 50 50)
STATIC_PPS=(100 200 200 300 200 300 500 500)
STATIC_AREAS=(5 4 3 3 2 2 1 1)


PROTOCOLS=("aodv" "cc-aodv" "ecc-aodv")

# -----------------------------------------------------------------------
# Global counters for total metric wins across all configs
# Index 0=aodv  1=cc-aodv  2=ecc-aodv  (bash 3.2 compatible — no assoc arrays)
TOTAL_WINS=(0 0 0)

report_line() {
    echo "$1" | tee -a "$REPORT_FILE"
}

report_blank() {
    echo "" | tee -a "$REPORT_FILE"
}

report_printf() {
    printf "$@" | tee -a "$REPORT_FILE"
}

# -----------------------------------------------------------------------
validate_column_lengths() {
    local m="${#MOBILE_NODES[@]}"
    if [[ "$m" -ne "${#MOBILE_FLOWS[@]}" || "$m" -ne "${#MOBILE_PPS[@]}" || "$m" -ne "${#MOBILE_SPEEDS[@]}" ]]; then
        echo "ERROR: MOBILE_* arrays must all have the same length." >&2; exit 1
    fi
    local s="${#STATIC_NODES[@]}"
    if [[ "$s" -ne "${#STATIC_FLOWS[@]}" || "$s" -ne "${#STATIC_PPS[@]}" || "$s" -ne "${#STATIC_AREAS[@]}" ]]; then
        echo "ERROR: STATIC_* arrays must all have the same length." >&2; exit 1
    fi
}

# -----------------------------------------------------------------------
# Run one simulation; store parsed metrics in OUT_* global vars.
# Sets OUT_OK=1 on success, OUT_OK=0 on timeout/fail.
run_sim() {
    local proto="$1" topo="$2" nodes="$3" flows="$4" pps="$5" speed="$6" areaMul="$7"
    local prefix="targeted-${topo}-${proto}-n${nodes}-f${flows}-p${pps}-s${speed}-a${areaMul}"
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
        --pps=${pps} \
        --packetSize=${PACKET_SIZE} \
        --ccBaseThreshold=${CC_BASE_THRESHOLD} \
        --w1=${W1} --w2=${W2} --w3=${W3} \
        --trace=${ENABLE_TRACE} \
        --routeDiscoveryTrace=${ENABLE_RD_TRACE} \
        --routingTableTrace=${ENABLE_RT_TRACE} \
        --routingTableInterval=${TRACE_INTERVAL} \
        --perNodeThroughput=${ENABLE_PER_NODE_TPUT} \
        --queueSizeTrace=${ENABLE_QUEUE_TRACE} \
        --queuePollInterval=${QUEUE_POLL_INTERVAL} \
        --output=${prefix} \
        --outputDir=${OUTPUT_DIR}\" 2>&1"

    OUT_OK=0
    OUT_STATUS="FAILED"
    OUT_PDR="0" OUT_TPUT="0" OUT_DELAY="0" OUT_LOSS="100" OUT_ENERGY="0"

    if timeout "${RUN_TIMEOUT}" bash -c "$cmd" > "$log" 2>&1; then
        OUT_PDR=$(grep    "^PDR:"                    "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        OUT_DELAY=$(grep  "^Avg E2E Delay:"          "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        OUT_TPUT=$(grep   "^Throughput:"             "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        OUT_LOSS=$(grep   "^Packet Loss Rate:"       "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "100")
        OUT_ENERGY=$(grep "^Total Energy Consumed:"  "$log" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        OUT_OK=1
        OUT_STATUS="OK"
    else
        local rc=$?
        if [[ "$rc" -eq 124 || "$rc" -eq 137 ]]; then
            OUT_STATUS="TIMEOUT"
        else
            OUT_STATUS="FAILED"
        fi
    fi
}

# -----------------------------------------------------------------------
# Print per-config comparison report and determine winners.
# Accepts: config_key proto1 pdr1 tput1 delay1 loss1 e1  proto2 ...  proto3 ...
print_config_report() {
    local config_key="$1"

    local proto=("$2"   "${10}" "${18}")
    local pdr=(  "$3"   "${11}" "${19}")
    local tput=( "$4"   "${12}" "${20}")
    local delay=("$5"   "${13}" "${21}")
    local loss=( "$6"   "${14}" "${22}")
    local energy=("$7"  "${15}" "${23}")
    local ok=(   "$8"   "${16}" "${24}")
    local status=("$9"  "${17}" "${25}")

    report_blank
    report_line "${config_key}"
    report_blank

    local all_failed=1
    for i in 0 1 2; do
        if [[ "${ok[$i]}" -eq 1 ]]; then
            all_failed=0
            break
        fi
    done

    if [[ "$all_failed" -eq 1 ]]; then
        for i in 0 1 2; do
            report_printf "  %-9s  %s\n" "${proto[$i]}" "${status[$i]}"
        done
        report_blank
        report_line "SO FINAL Winner in this config: N/A (all runs failed)"
        report_line "Criteria: skipped (no successful protocol run)"
        return
    fi

    # ---- find per-metric winner index (0/1/2) ----
    # Higher PDR = better; higher Tput = better; lower Delay = better;
    # lower Loss = better; lower Energy = better.

    # Use awk for float comparisons — bash can't compare floats natively
    local win_pdr win_tput win_delay win_loss win_energy
    win_pdr=$(awk    -v a="${pdr[0]}"    -v b="${pdr[1]}"    -v c="${pdr[2]}"    'BEGIN{m=a;i=0; if(b>m){m=b;i=1}; if(c>m){m=c;i=2}; print i}')
    win_tput=$(awk   -v a="${tput[0]}"   -v b="${tput[1]}"   -v c="${tput[2]}"   'BEGIN{m=a;i=0; if(b>m){m=b;i=1}; if(c>m){m=c;i=2}; print i}')
    win_delay=$(awk  -v a="${delay[0]}"  -v b="${delay[1]}"  -v c="${delay[2]}"  'BEGIN{m=a;i=0; if(b<m){m=b;i=1}; if(c<m){m=c;i=2}; print i}')
    win_loss=$(awk   -v a="${loss[0]}"   -v b="${loss[1]}"   -v c="${loss[2]}"   'BEGIN{m=a;i=0; if(b<m){m=b;i=1}; if(c<m){m=c;i=2}; print i}')
    win_energy=$(awk -v a="${energy[0]}" -v b="${energy[1]}" -v c="${energy[2]}" 'BEGIN{m=a;i=0; if(b<m){m=b;i=1}; if(c<m){m=c;i=2}; print i}')

    # ---- build metric win counts per protocol (for this config) ----
    local wins=(0 0 0)
    wins[$win_pdr]=$(( wins[$win_pdr] + 1 ))
    wins[$win_tput]=$(( wins[$win_tput] + 1 ))
    wins[$win_delay]=$(( wins[$win_delay] + 1 ))
    wins[$win_loss]=$(( wins[$win_loss] + 1 ))
    wins[$win_energy]=$(( wins[$win_energy] + 1 ))

    # ---- accumulate global total metric wins (index: 0=aodv 1=cc-aodv 2=ecc-aodv) ----
    TOTAL_WINS[0]=$(( TOTAL_WINS[0] + wins[0] ))
    TOTAL_WINS[1]=$(( TOTAL_WINS[1] + wins[1] ))
    TOTAL_WINS[2]=$(( TOTAL_WINS[2] + wins[2] ))

    # ---- determine config winner (Highest PDR -> Tput -> Delay -> Loss -> Energy) ----
    # First pass: find protocols tied for best PDR
    local best_pdr
    best_pdr=$(awk -v a="${pdr[0]}" -v b="${pdr[1]}" -v c="${pdr[2]}" \
        'BEGIN{m=a; if(b>m) m=b; if(c>m) m=c; print m}')

    # Among those with best PDR, find best tput, etc.
    # We implement the tiebreaker chain via awk
    local winner_idx
    winner_idx=$(awk \
        -v p0="${pdr[0]}"    -v p1="${pdr[1]}"    -v p2="${pdr[2]}" \
        -v t0="${tput[0]}"   -v t1="${tput[1]}"   -v t2="${tput[2]}" \
        -v d0="${delay[0]}"  -v d1="${delay[1]}"  -v d2="${delay[2]}" \
        -v l0="${loss[0]}"   -v l1="${loss[1]}"   -v l2="${loss[2]}" \
        -v e0="${energy[0]}" -v e1="${energy[1]}" -v e2="${energy[2]}" \
        'BEGIN {
            # arrays
            p[0]=p0; p[1]=p1; p[2]=p2
            t[0]=t0; t[1]=t1; t[2]=t2
            d[0]=d0; d[1]=d1; d[2]=d2
            l[0]=l0; l[1]=l1; l[2]=l2
            e[0]=e0; e[1]=e1; e[2]=e2

            # find max PDR
            mp=p[0]; for(i=1;i<3;i++) if(p[i]>mp) mp=p[i]
            # keep only those with mp (within 0.001 tolerance)
            cand=""; for(i=0;i<3;i++) if(p[i]>=mp-0.001) cand=cand" "i
            if(split(cand,c)==1){ print c[1]; exit }

            # tiebreak: max tput
            mt=0; for(k in c) if(t[c[k]]>mt) mt=t[c[k]]
            cand2=""; for(k in c) if(t[c[k]]>=mt-0.001) cand2=cand2" "c[k]
            if(split(cand2,c2)==1){ print c2[1]; exit }

            # tiebreak: min delay
            md=d[c2[1]]; for(k in c2) if(d[c2[k]]<md) md=d[c2[k]]
            cand3=""; for(k in c2) if(d[c2[k]]<=md+0.001) cand3=cand3" "c2[k]
            if(split(cand3,c3)==1){ print c3[1]; exit }

            # tiebreak: min loss
            ml=l[c3[1]]; for(k in c3) if(l[c3[k]]<ml) ml=l[c3[k]]
            cand4=""; for(k in c3) if(l[c3[k]]<=ml+0.001) cand4=cand4" "c3[k]
            if(split(cand4,c4)==1){ print c4[1]; exit }

            # tiebreak: min energy
            me=e[c4[1]]; for(k in c4) if(e[c4[k]]<me) me=e[c4[k]]
            for(k in c4) if(e[c4[k]]<=me+0.001){ print c4[k]; exit }
        }')

    # ---- print the 3 protocol lines ----
    for i in 0 1 2; do
        local p="${proto[$i]}"
        local pdr_str tput_str delay_str loss_str energy_str

        # tag with (W) if this protocol won that metric
        if [[ "$i" -eq "$win_pdr" ]];    then pdr_str="${pdr[$i]}(W)";     else pdr_str="${pdr[$i]}";    fi
        if [[ "$i" -eq "$win_tput" ]];   then tput_str="${tput[$i]}(W)";   else tput_str="${tput[$i]}";  fi
        if [[ "$i" -eq "$win_delay" ]];  then delay_str="${delay[$i]}(W)"; else delay_str="${delay[$i]}"; fi
        if [[ "$i" -eq "$win_loss" ]];   then loss_str="${loss[$i]}(W)";   else loss_str="${loss[$i]}";  fi
        if [[ "$i" -eq "$win_energy" ]]; then energy_str="${energy[$i]}(W)"; else energy_str="${energy[$i]}"; fi

        if [[ "${ok[$i]}" -eq 0 ]]; then
            report_printf "  %-9s  %s\n" "$p" "${status[$i]}"
        else
            report_printf "  %-9s PDR= %-12s Tput= %-16s Delay= %-16s Loss= %-10s E= %s\n" \
                "$p" "$pdr_str" "$tput_str" "$delay_str" "$loss_str" "$energy_str"
        fi
    done

    local winner_name="${proto[$winner_idx]}"
    report_blank
    report_line "SO FINAL Winner in this config: ${winner_name}"
    report_line "Criteria: Highest PDR -> Higher Throughput -> Lower Delay -> Lower Loss -> Lower Energy"
}

# -----------------------------------------------------------------------
cd "$PROJECT_DIR"
mkdir -p "$OUTPUT_DIR" "$LOGS_DIR"

: > "$REPORT_FILE"
report_line "ECC-AODV Winners + Metrics Summary"
report_line "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
report_line "SIM_TIME=${SIM_TIME}s, SEED=${SEED}, Protocols=${PROTOCOLS[*]}"
report_blank

echo "============================================================"
echo " ECC-AODV Targeted Sweep — 802.11 Mobile + Static"
echo " Student ID: 2105050"
echo " sim_time=${SIM_TIME}s  pps_base=${MOBILE_PPS[0]}+  sleep=${SLEEP_BETWEEN}s"
echo "============================================================"
echo ""

validate_column_lengths

echo ">>> Building..."
if ./ns3 build 2>&1 | tail -3; then
    echo "Build OK"
else
    echo "Build FAILED — aborting"; exit 1
fi
echo ""

total=0; ok=0; fail=0

# -----------------------------------------------------------------------
echo "============================================================"
echo " Topology: MOBILE"
echo "============================================================"
report_line "============================================================"
report_line " Topology: MOBILE"
report_line "============================================================"
for idx in "${!MOBILE_NODES[@]}"; do
    nodes="${MOBILE_NODES[$idx]}"
    flows="${MOBILE_FLOWS[$idx]}"
    pps="${MOBILE_PPS[$idx]}"
    speed="${MOBILE_SPEEDS[$idx]}"
    config_key="mobile,n${nodes},f${flows},p${pps},s${speed},a1"

    echo "------------------------------------------------------------"
    echo " ${config_key}"
    echo "------------------------------------------------------------"

    # Storage for 3 protocols in this config
    proto_list=()
    pdr_list=()
    tput_list=()
    delay_list=()
    loss_list=()
    energy_list=()
    ok_list=()
    status_list=()

    for proto in "${PROTOCOLS[@]}"; do
        printf "  %-9s ... " "$proto"
        run_sim "$proto" "mobile" "$nodes" "$flows" "$pps" "$speed" 1

        if [[ "$OUT_OK" -eq 1 ]]; then
            printf "OK   PDR=%-7s Tput=%-12s E2E=%-12s Loss=%-7s E=%s J\n" \
                "${OUT_PDR}%" "${OUT_TPUT}Kbps" "${OUT_DELAY}ms" "${OUT_LOSS}%" "$OUT_ENERGY"
            ok=$((ok + 1))
        else
            printf "%s\n" "$OUT_STATUS"
            fail=$((fail + 1))
        fi

        proto_list+=("$proto")
        pdr_list+=("$OUT_PDR")
        tput_list+=("$OUT_TPUT")
        delay_list+=("$OUT_DELAY")
        loss_list+=("$OUT_LOSS")
        energy_list+=("$OUT_ENERGY")
        ok_list+=("$OUT_OK")
        status_list+=("$OUT_STATUS")

        total=$((total + 1))
        sleep "$SLEEP_BETWEEN"
    done

    # Per-config winner report
    print_config_report "$config_key" \
        "${proto_list[0]}" "${pdr_list[0]}" "${tput_list[0]}" "${delay_list[0]}" "${loss_list[0]}" "${energy_list[0]}" "${ok_list[0]}" "${status_list[0]}" \
        "${proto_list[1]}" "${pdr_list[1]}" "${tput_list[1]}" "${delay_list[1]}" "${loss_list[1]}" "${energy_list[1]}" "${ok_list[1]}" "${status_list[1]}" \
        "${proto_list[2]}" "${pdr_list[2]}" "${tput_list[2]}" "${delay_list[2]}" "${loss_list[2]}" "${energy_list[2]}" "${ok_list[2]}" "${status_list[2]}"
    report_blank
done

# -----------------------------------------------------------------------
echo "============================================================"
echo " Topology: STATIC"
echo "============================================================"
report_line "============================================================"
report_line " Topology: STATIC"
report_line "============================================================"
for idx in "${!STATIC_NODES[@]}"; do
    nodes="${STATIC_NODES[$idx]}"
    flows="${STATIC_FLOWS[$idx]}"
    pps="${STATIC_PPS[$idx]}"
    areaMul="${STATIC_AREAS[$idx]}"
    config_key="static,n${nodes},f${flows},p${pps},s5,a${areaMul}"

    echo "------------------------------------------------------------"
    echo " ${config_key}"
    echo "------------------------------------------------------------"

    proto_list=()
    pdr_list=()
    tput_list=()
    delay_list=()
    loss_list=()
    energy_list=()
    ok_list=()
    status_list=()

    for proto in "${PROTOCOLS[@]}"; do
        printf "  %-9s ... " "$proto"
        run_sim "$proto" "static" "$nodes" "$flows" "$pps" 5 "$areaMul"

        if [[ "$OUT_OK" -eq 1 ]]; then
            printf "OK   PDR=%-7s Tput=%-12s E2E=%-12s Loss=%-7s E=%s J\n" \
                "${OUT_PDR}%" "${OUT_TPUT}Kbps" "${OUT_DELAY}ms" "${OUT_LOSS}%" "$OUT_ENERGY"
            ok=$((ok + 1))
        else
            printf "%s\n" "$OUT_STATUS"
            fail=$((fail + 1))
        fi

        proto_list+=("$proto")
        pdr_list+=("$OUT_PDR")
        tput_list+=("$OUT_TPUT")
        delay_list+=("$OUT_DELAY")
        loss_list+=("$OUT_LOSS")
        energy_list+=("$OUT_ENERGY")
        ok_list+=("$OUT_OK")
        status_list+=("$OUT_STATUS")

        total=$((total + 1))
        sleep "$SLEEP_BETWEEN"
    done

    # Per-config winner report
    print_config_report "$config_key" \
        "${proto_list[0]}" "${pdr_list[0]}" "${tput_list[0]}" "${delay_list[0]}" "${loss_list[0]}" "${energy_list[0]}" "${ok_list[0]}" "${status_list[0]}" \
        "${proto_list[1]}" "${pdr_list[1]}" "${tput_list[1]}" "${delay_list[1]}" "${loss_list[1]}" "${energy_list[1]}" "${ok_list[1]}" "${status_list[1]}" \
        "${proto_list[2]}" "${pdr_list[2]}" "${tput_list[2]}" "${delay_list[2]}" "${loss_list[2]}" "${energy_list[2]}" "${ok_list[2]}" "${status_list[2]}"
    report_blank
done

# -----------------------------------------------------------------------
echo "============================================================"
echo " DONE: $ok/$total succeeded  ($fail failed/timeout)"
echo "============================================================"
echo ""

# -----------------------------------------------------------------------
# Total metric wins across ALL configs
echo "============================================================"
echo " Total metric wins across all configs"
echo "============================================================"
echo "Protocol | MetricWins"
echo "---------------------"
printf "%-9s | %d\n" "aodv"     "${TOTAL_WINS[0]}"
printf "%-9s | %d\n" "cc-aodv"  "${TOTAL_WINS[1]}"
printf "%-9s | %d\n" "ecc-aodv" "${TOTAL_WINS[2]}"
echo ""

report_line "============================================================"
report_line " Total metric wins across all configs"
report_line "============================================================"
report_line "Protocol | MetricWins"
report_line "---------------------"
report_printf "%-9s | %d\n" "aodv"     "${TOTAL_WINS[0]}"
report_printf "%-9s | %d\n" "cc-aodv"  "${TOTAL_WINS[1]}"
report_printf "%-9s | %d\n" "ecc-aodv" "${TOTAL_WINS[2]}"
report_blank

echo "Summary report: $REPORT_FILE"
