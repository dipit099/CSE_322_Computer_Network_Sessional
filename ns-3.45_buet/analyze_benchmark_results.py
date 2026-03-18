#!/usr/bin/env python3
"""
Comprehensive Benchmark Results Analyzer for ECC-AODV, CC-AODV, and AODV
Parses benchmark output and generates organized statistics
"""

import re
import os
from collections import defaultdict
from pathlib import Path

def parse_benchmark_log(log_file):
    """Parse benchmark log file and extract metrics"""
    results = []
    
    with open(log_file, 'r') as f:
        content = f.read()
    
    # Pattern to match benchmark entries
    pattern = r'\[(\d+)/\d+\] nodes=(\d+), sinks=(\d+), speed=([\d\-\.]+\s+m/s), mode=(\w+)(.*?)(?=\[|\Z)'
    
    matches = re.finditer(pattern, content, re.DOTALL)
    
    for match in matches:
        iteration, nodes, sinks, speed, mode, metrics_text = match.groups()
        
        # Extract PDR
        pdr_match = re.search(r'PDR:\s+([\d\.]+)\s*%', metrics_text)
        pdr = float(pdr_match.group(1)) if pdr_match else 0
        
        # Extract Average E2E Delay
        delay_match = re.search(r'Avg E2E Delay:\s+([\d\.]+)\s*ms', metrics_text)
        delay = float(delay_match.group(1)) if delay_match else 0
        
        # Extract Throughput
        throughput_match = re.search(r'Throughput:\s+([\d\.]+)\s*(Kbps|Mbps)', metrics_text)
        throughput = float(throughput_match.group(1)) if throughput_match else 0
        
        results.append({
            'iteration': int(iteration),
            'nodes': int(nodes),
            'sinks': int(sinks),
            'speed': speed.strip(),
            'mode': mode,
            'pdr': pdr,
            'delay': delay,
            'throughput': throughput
        })
    
    return results

def organize_by_scenario(results):
    """Organize results by network scenarios"""
    scenarios = defaultdict(lambda: {'aodv': {}, 'cc_aodv': {}, 'ecc_aodv': {}})
    
    for result in results:
        scenario = f"{result['nodes']}n_{result['sinks']}s_{result['speed'].replace(' ', '_').replace('-', 'to')}"
        mode_key = result['mode'].lower().replace('-', '_')
        
        if mode_key not in ['aodv', 'cc_aodv', 'ecc_aodv']:
            mode_key = 'ecc_aodv'  # Default to ECC
        
        scenarios[scenario][mode_key] = {
            'pdr': result['pdr'],
            'delay': result['delay'],
            'throughput': result['throughput']
        }
    
    return scenarios

def calculate_improvements(scenarios):
    """Calculate performance improvements"""
    analysis = {}
    
    for scenario, modes in scenarios.items():
        aodv_stats = modes.get('aodv', {})
        cc_aodv_stats = modes.get('cc_aodv', {})
        ecc_aodv_stats = modes.get('ecc_aodv', {})
        
        analysis[scenario] = {
            'aodv': aodv_stats,
            'cc_aodv': cc_aodv_stats,
            'ecc_aodv': ecc_aodv_stats,
            'cc_vs_aodv': {},
            'ecc_vs_aodv': {},
            'ecc_vs_cc': {}
        }
        
        # CC-AODV vs AODV
        if aodv_stats and cc_aodv_stats:
            analysis[scenario]['cc_vs_aodv'] = {
                'pdr_improvement': cc_aodv_stats.get('pdr', 0) - aodv_stats.get('pdr', 0),
                'delay_improvement': aodv_stats.get('delay', 0) - cc_aodv_stats.get('delay', 0),  # Lower is better
                'throughput_improvement': cc_aodv_stats.get('throughput', 0) - aodv_stats.get('throughput', 0)
            }
        
        # ECC-AODV vs AODV
        if aodv_stats and ecc_aodv_stats:
            analysis[scenario]['ecc_vs_aodv'] = {
                'pdr_improvement': ecc_aodv_stats.get('pdr', 0) - aodv_stats.get('pdr', 0),
                'delay_improvement': aodv_stats.get('delay', 0) - ecc_aodv_stats.get('delay', 0),
                'throughput_improvement': ecc_aodv_stats.get('throughput', 0) - aodv_stats.get('throughput', 0)
            }
        
        # ECC-AODV vs CC-AODV
        if cc_aodv_stats and ecc_aodv_stats:
            analysis[scenario]['ecc_vs_cc'] = {
                'pdr_improvement': ecc_aodv_stats.get('pdr', 0) - cc_aodv_stats.get('pdr', 0),
                'delay_improvement': cc_aodv_stats.get('delay', 0) - ecc_aodv_stats.get('delay', 0),
                'throughput_improvement': ecc_aodv_stats.get('throughput', 0) - cc_aodv_stats.get('throughput', 0)
            }
    
    return analysis

def generate_text_report(analysis):
    """Generate comprehensive text report"""
    report = []
    report.append("=" * 100)
    report.append("COMPREHENSIVE BENCHMARK ANALYSIS: ECC-AODV vs CC-AODV vs AODV")
    report.append("=" * 100)
    report.append("")
    
    # Summary statistics
    report.append("SECTION 1: OVERALL PERFORMANCE COMPARISON")
    report.append("-" * 100)
    
    all_pdr_improvements_cc = []
    all_pdr_improvements_ecc = []
    all_delay_improvements_cc = []
    all_delay_improvements_ecc = []
    all_throughput_improvements_cc = []
    all_throughput_improvements_ecc = []
    
    for scenario, data in sorted(analysis.items()):
        if data['cc_vs_aodv']:
            all_pdr_improvements_cc.append(data['cc_vs_aodv'].get('pdr_improvement', 0))
            all_delay_improvements_cc.append(data['cc_vs_aodv'].get('delay_improvement', 0))
            all_throughput_improvements_cc.append(data['cc_vs_aodv'].get('throughput_improvement', 0))
        
        if data['ecc_vs_aodv']:
            all_pdr_improvements_ecc.append(data['ecc_vs_aodv'].get('pdr_improvement', 0))
            all_delay_improvements_ecc.append(data['ecc_vs_aodv'].get('delay_improvement', 0))
            all_throughput_improvements_ecc.append(data['ecc_vs_aodv'].get('throughput_improvement', 0))
    
    if all_pdr_improvements_cc:
        report.append(f"\nCC-AODV vs AODV (Average across all scenarios):")
        report.append(f"  PDR Improvement:        {sum(all_pdr_improvements_cc)/len(all_pdr_improvements_cc):+.2f}%")
        report.append(f"  Delay Reduction:        {sum(all_delay_improvements_cc)/len(all_delay_improvements_cc):+.2f} ms")
        report.append(f"  Throughput Increase:    {sum(all_throughput_improvements_cc)/len(all_throughput_improvements_cc):+.2f} Kbps")
    
    if all_pdr_improvements_ecc:
        report.append(f"\nECC-AODV vs AODV (Average across all scenarios):")
        report.append(f"  PDR Improvement:        {sum(all_pdr_improvements_ecc)/len(all_pdr_improvements_ecc):+.2f}%")
        report.append(f"  Delay Reduction:        {sum(all_delay_improvements_ecc)/len(all_delay_improvements_ecc):+.2f} ms")
        report.append(f"  Throughput Increase:    {sum(all_throughput_improvements_ecc)/len(all_throughput_improvements_ecc):+.2f} Kbps")
    
    report.append("\n")
    report.append("SECTION 2: WHERE CC-AODV OUTPERFORMS STANDARD AODV")
    report.append("-" * 100)
    
    cc_wins_pdr = []
    cc_wins_delay = []
    cc_wins_throughput = []
    
    for scenario, data in sorted(analysis.items()):
        if data['cc_vs_aodv']:
            comp = data['cc_vs_aodv']
            if comp.get('pdr_improvement', 0) > 0:
                cc_wins_pdr.append((scenario, comp['pdr_improvement'], data['aodv']['pdr'], data['cc_aodv']['pdr']))
            if comp.get('delay_improvement', 0) > 0:
                cc_wins_delay.append((scenario, comp['delay_improvement'], data['aodv']['delay'], data['cc_aodv']['delay']))
            if comp.get('throughput_improvement', 0) > 0:
                cc_wins_throughput.append((scenario, comp['throughput_improvement'], data['aodv']['throughput'], data['cc_aodv']['throughput']))
    
    report.append("\nPDR Improvements (CC-AODV > AODV):")
    if cc_wins_pdr:
        cc_wins_pdr.sort(key=lambda x: x[1], reverse=True)
        for scenario, improvement, aodv_val, cc_val in cc_wins_pdr:
            report.append(f"  {scenario}: +{improvement:.2f}% (AODV: {aodv_val:.2f}% → CC-AODV: {cc_val:.2f}%)")
    else:
        report.append("  No significant improvements found")
    
    report.append("\nDelay Improvements (CC-AODV < AODV):")
    if cc_wins_delay:
        cc_wins_delay.sort(key=lambda x: x[1], reverse=True)
        for scenario, improvement, aodv_val, cc_val in cc_wins_delay[:5]:  # Top 5
            report.append(f"  {scenario}: {improvement:+.2f} ms (AODV: {aodv_val:.2f}ms → CC-AODV: {cc_val:.2f}ms)")
    else:
        report.append("  No significant improvements found")
    
    report.append("\nThroughput Improvements (CC-AODV > AODV):")
    if cc_wins_throughput:
        cc_wins_throughput.sort(key=lambda x: x[1], reverse=True)
        for scenario, improvement, aodv_val, cc_val in cc_wins_throughput[:5]:  # Top 5
            report.append(f"  {scenario}: +{improvement:.2f} Kbps (AODV: {aodv_val:.2f} → CC-AODV: {cc_val:.2f})")
    else:
        report.append("  No significant improvements found")
    
    report.append("\n")
    report.append("SECTION 3: WHERE ECC-AODV OUTPERFORMS CC-AODV")
    report.append("-" * 100)
    
    ecc_wins_pdr = []
    ecc_wins_delay = []
    ecc_wins_throughput = []
    
    for scenario, data in sorted(analysis.items()):
        if data['ecc_vs_cc']:
            comp = data['ecc_vs_cc']
            if comp.get('pdr_improvement', 0) > 0:
                ecc_wins_pdr.append((scenario, comp['pdr_improvement'], data['cc_aodv']['pdr'], data['ecc_aodv']['pdr']))
            if comp.get('delay_improvement', 0) > 0:
                ecc_wins_delay.append((scenario, comp['delay_improvement'], data['cc_aodv']['delay'], data['ecc_aodv']['delay']))
            if comp.get('throughput_improvement', 0) > 0:
                ecc_wins_throughput.append((scenario, comp['throughput_improvement'], data['cc_aodv']['throughput'], data['ecc_aodv']['throughput']))
    
    report.append("\nPDR Improvements (ECC-AODV > CC-AODV):")
    if ecc_wins_pdr:
        ecc_wins_pdr.sort(key=lambda x: x[1], reverse=True)
        for scenario, improvement, cc_val, ecc_val in ecc_wins_pdr:
            report.append(f"  {scenario}: +{improvement:.2f}% (CC-AODV: {cc_val:.2f}% → ECC-AODV: {ecc_val:.2f}%)")
    else:
        report.append("  No improvements found")
    
    report.append("\nDelay Improvements (ECC-AODV < CC-AODV):")
    if ecc_wins_delay:
        ecc_wins_delay.sort(key=lambda x: x[1], reverse=True)
        for scenario, improvement, cc_val, ecc_val in ecc_wins_delay[:5]:
            report.append(f"  {scenario}: {improvement:+.2f} ms (CC-AODV: {cc_val:.2f}ms → ECC-AODV: {ecc_val:.2f}ms)")
    else:
        report.append("  No improvements found")
    
    report.append("\nThroughput Improvements (ECC-AODV > CC-AODV):")
    if ecc_wins_throughput:
        ecc_wins_throughput.sort(key=lambda x: x[1], reverse=True)
        for scenario, improvement, cc_val, ecc_val in ecc_wins_throughput[:5]:
            report.append(f"  {scenario}: +{improvement:.2f} Kbps (CC-AODV: {cc_val:.2f} → ECC-AODV: {ecc_val:.2f})")
    else:
        report.append("  No improvements found")
    
    report.append("\n")
    report.append("SECTION 4: DETAILED SCENARIO-BY-SCENARIO ANALYSIS")
    report.append("-" * 100)
    
    for scenario, data in sorted(analysis.items()):
        report.append(f"\nScenario: {scenario}")
        report.append("  AODV Performance:")
        if data['aodv']:
            report.append(f"    PDR: {data['aodv'].get('pdr', 0):.2f}%  |  Delay: {data['aodv'].get('delay', 0):.2f}ms  |  Throughput: {data['aodv'].get('throughput', 0):.2f} Kbps")
        else:
            report.append("    [Data not available]")
        
        report.append("  CC-AODV Performance:")
        if data['cc_aodv']:
            report.append(f"    PDR: {data['cc_aodv'].get('pdr', 0):.2f}%  |  Delay: {data['cc_aodv'].get('delay', 0):.2f}ms  |  Throughput: {data['cc_aodv'].get('throughput', 0):.2f} Kbps")
        else:
            report.append("    [Data not available]")
        
        report.append("  ECC-AODV Performance:")
        if data['ecc_aodv']:
            report.append(f"    PDR: {data['ecc_aodv'].get('pdr', 0):.2f}%  |  Delay: {data['ecc_aodv'].get('delay', 0):.2f}ms  |  Throughput: {data['ecc_aodv'].get('throughput', 0):.2f} Kbps")
        else:
            report.append("    [Data not available]")
        
        report.append("  Improvement Analysis:")
        if data['cc_vs_aodv']:
            report.append(f"    CC vs AODV:  PDR {data['cc_vs_aodv'].get('pdr_improvement', 0):+.2f}%  |  Delay {data['cc_vs_aodv'].get('delay_improvement', 0):+.2f}ms  |  TP {data['cc_vs_aodv'].get('throughput_improvement', 0):+.2f} Kbps")
        if data['ecc_vs_aodv']:
            report.append(f"    ECC vs AODV: PDR {data['ecc_vs_aodv'].get('pdr_improvement', 0):+.2f}%  |  Delay {data['ecc_vs_aodv'].get('delay_improvement', 0):+.2f}ms  |  TP {data['ecc_vs_aodv'].get('throughput_improvement', 0):+.2f} Kbps")
        if data['ecc_vs_cc']:
            report.append(f"    ECC vs CC:   PDR {data['ecc_vs_cc'].get('pdr_improvement', 0):+.2f}%  |  Delay {data['ecc_vs_cc'].get('delay_improvement', 0):+.2f}ms  |  TP {data['ecc_vs_cc'].get('throughput_improvement', 0):+.2f} Kbps")
    
    report.append("\n")
    report.append("=" * 100)
    report.append("END OF REPORT")
    report.append("=" * 100)
    
    return "\n".join(report)

if __name__ == '__main__':
    log_file = '/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/benchmark_run.log'
    
    print("Parsing benchmark log...")
    results = parse_benchmark_log(log_file)
    
    print(f"Found {len(results)} benchmark results")
    
    print("Organizing by scenario...")
    scenarios = organize_by_scenario(results)
    
    print("Calculating improvements...")
    analysis = calculate_improvements(scenarios)
    
    print("Generating report...")
    report = generate_text_report(analysis)
    
    # Save report
    output_file = '/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/outputs/comprehensive-benchmark-stats.txt'
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    with open(output_file, 'w') as f:
        f.write(report)
    
    print(f"\n✓ Report saved to {output_file}")
    print("\n" + report)
