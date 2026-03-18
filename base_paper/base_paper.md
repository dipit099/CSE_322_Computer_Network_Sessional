

# Reference Document: CC-AODV Implementation & Architecture
[cite_start]**Title:** CC-ADOV: An Effective Multiple Paths Congestion Control/AODV [cite: 1]
[cite_start]**Authors:** Yefa Mai, Fernando Molina Rodriguez, and Dr. Nan Wang [cite: 2]

## 1. Core Concept and Problem Statement
[cite_start]Mobile Ad hoc Networks (MANETs) use reactive routing protocols like Ad-hoc On-Demand Distance Vector (AODV) to deliver data dynamically[cite: 16, 28]. [cite_start]However, standard AODV often suffers from performance degradation because it overuses nodes on the shortest path, even if those nodes are highly congested or busy[cite: 65, 66]. 

[cite_start]To solve this, the authors propose **CC-AODV (Congestion Control AODV)**, which introduces a congestion counter mechanism to reroute data away from stressed nodes, thereby increasing bandwidth utilization and overall network performance[cite: 68, 70, 71].

## 2. Architecture of the CC-AODV Process
[cite_start]The CC-AODV architecture modifies the standard AODV route discovery and maintenance phases by integrating a congestion tracking mechanism[cite: 70, 72]. 

### Route Request (RREQ) Phase
* [cite_start]**Broadcast:** The source node floods the entire network with an RREQ packet to find a path to the destination[cite: 105].
* [cite_start]**Intermediate Node Check:** When an intermediate router receives the RREQ, it checks its internal "congestion counter" against a predefined threshold value[cite: 106].
    * [cite_start]*If Counter < Threshold:* The node updates its routing table and forwards the RREQ to the next router[cite: 107].
    * [cite_start]*If Counter $\ge$ Threshold:* The node drops the RREQ packet to avoid further congestion[cite: 108].

### Route Reply (RREP) Phase
* [cite_start]**Header Modification:** CC-AODV introduces a custom 32-bit "Congestion Flag" to the RREP message header[cite: 109, 129].
* [cite_start]**RREP Generation:** Once the RREQ reaches the destination, the destination node generates an RREP packet with the congestion flag set to *true*[cite: 112].
* [cite_start]**Backtracking & Updating:** The RREP unicasts back to the source node[cite: 113]. [cite_start]As it passes through intermediate nodes, each router checks the congestion flag[cite: 113].
    * [cite_start]*If Flag == True:* The router increments its congestion counter by 1 and updates its routing information[cite: 114].
    * [cite_start]*If Flag == False:* The counter remains unchanged[cite: 114].

## 3. Implementation Rules for the Congestion Counter
[cite_start]During implementation (specifically in NS3), the routing table must manage the congestion counter based on four strict rules[cite: 128, 129]:

1.  [cite_start]**Initialization:** When a routing table is first initialized, the congestion counter is generated and set to `0`[cite: 131].
2.  **Incrementing:** When a node receives an RREP package, it checks the congestion flag. [cite_start]If true, the counter increases by `1`[cite: 133].
3.  [cite_start]**Decrementing:** * The table has a `lifetime` entry; when this lifetime expires, the counter subtracts `1`[cite: 135].
    * [cite_start]If a link breaks and a Route Error (RRER) packet is sent back, breaking the intermediate path, the counter for that node subtracts `1`[cite: 136, 137].
4.  [cite_start]**Resetting:** If a node is completely removed from the network, its congestion counter resets to `0`[cite: 139].

## 4. Simulation Setup & Environment
[cite_start]The architecture was tested using Network Simulator 3 (NS3) on an Ubuntu environment[cite: 141]. 

| Parameter | Value |
| :--- | :--- |
| **Operating System** | [cite_start]Ubuntu 14.04 [cite: 144] |
| **Simulator** | [cite_start]NS3 (ns-3.26) [cite: 144] |
| **Simulation Area** | [cite_start]500 * 500 [cite: 144] |
| **Number of Nodes** | [cite_start]10 (Small), 30 (Medium), 50 (Large) [cite: 144, 146, 147] |
| **MAC Protocol / Channel** | [cite_start]802.11 / Wireless Channel [cite: 144] |
| **Data Packet Size / Type** | [cite_start]512 bytes / UDP [cite: 144] |
| **Routing Protocols Tested** | [cite_start]AODV, C-AODV [cite: 144] |

## 5. Statistical Results (AODV vs. CC-AODV)
[cite_start]The performance was measured across four main metrics[cite: 148]. [cite_start]The data proves that CC-AODV utilizes internal nodes more efficiently by rerouting traffic from busy nodes[cite: 283].

### A. Packet Loss & Packet Delivery Ratio (PDR)
[cite_start]CC-AODV successfully reduces packet loss and increases the delivery ratio in denser networks because routers have more path options[cite: 276, 277].

| Network Size | Packet Loss (AODV) | Packet Loss (CC-AODV) | PDR (AODV) | PDR (CC-AODV) |
| :--- | :--- | :--- | :--- | :--- |
| **10 Nodes** | [cite_start]539 [cite: 167] | [cite_start]544 [cite: 168] | [cite_start]76.80% [cite: 210] | [cite_start]76.34% [cite: 211] |
| **30 Nodes** | [cite_start]1016 [cite: 173] | [cite_start]938 [cite: 174] | [cite_start]33.77% [cite: 213] | [cite_start]42.98% [cite: 214] |
| **50 Nodes** | [cite_start]1291 [cite: 179] | [cite_start]1238 [cite: 180] | [cite_start]7.32% [cite: 216] | [cite_start]7.89% [cite: 217] |

### B. Throughput & End-to-End Delay
[cite_start]Throughput is consistently higher in CC-AODV, meaning network channel utilization is increased[cite: 282, 284]. [cite_start]However, this comes at the cost of a slightly higher End-to-End Delay due to the overhead of rerouting data when a router is in a busy state[cite: 281].

| Network Size | Throughput (AODV) | Throughput (CC-AODV) | Delay (AODV) | Delay (CC-AODV) |
| :--- | :--- | :--- | :--- | :--- |
| **10 Nodes** | [cite_start]36,980 [cite: 222] | [cite_start]45,360 [cite: 223] | [cite_start]0.6117 [cite: 170] | [cite_start]0.6117 [cite: 171] |
| **30 Nodes** | [cite_start]43,764 [cite: 225] | [cite_start]46,116 [cite: 226] | [cite_start]4.4471 [cite: 176] | [cite_start]4.9428 [cite: 177] |
| **50 Nodes** | [cite_start]43,672 [cite: 228] | [cite_start]49,080 [cite: 229] | [cite_start]11.1233 [cite: 182] | [cite_start]13.9471 [cite: 183] |

[cite_start]*(Note: Power consumption remained mostly similar between both protocols, though CC-AODV showed slight improvement at 30 nodes [cite: 285, 286, 287]).*

***

### 📝 Potential Exam/Viva Questions from this Document:
1.  **Conceptual:** What is the primary limitation of standard AODV routing that CC-AODV attempts to solve? *(Focus on the overuse of shortest-path nodes leading to congestion)*
2.  **Structural:** Explain the structural change made to the Route Reply (RREP) message format in CC-AODV. *(Focus on the 32-bit Congestion Flag)*
3.  **Algorithmic Logic:** Under what two specific conditions is the congestion counter decremented by 1 in the routing table? *(Focus on lifetime expiration and RRER packet generation)*
4.  **Trade-off Analysis:** According to the simulation results, CC-AODV improves Throughput and Packet Delivery Ratio but degrades another metric. Which metric is negatively impacted and why? *(Focus on End-to-End delay increasing due to rerouting overhead)*

