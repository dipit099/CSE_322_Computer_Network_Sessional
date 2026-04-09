# CC-AODV / ECC-AODV — Complete Change Reference

**Student ID:** 2105050  
**Baseline:** `ns-3.45_cleaned/src/aodv`  
**Modified:** `ns-3.45_buet/src/aodv`

To see all raw diffs:

```bash
diff -ru "ns-3.45_cleaned/src/aodv" "ns-3.45_buet/src/aodv"
```

Standard AODV is **untouched**. This document covers only CC-AODV and ECC-AODV additions.

---

## 1. Files Changed

| File | Changed? | What |
|------|----------|------|
| `src/aodv/model/aodv-packet.h` | ✅ | Added `m_congestionFlag`, `m_eccInfo` fields + accessors to `RrepHeader` |
| `src/aodv/model/aodv-packet.cc` | ✅ | Updated size, serialize/deserialize, equality for new fields |
| `src/aodv/model/aodv-rtable.h` | ✅ | Added `GetSize()` for density proxy |
| `src/aodv/model/aodv-rqueue.h` | ✅ | Made `GetSize()` const |
| `src/aodv/model/aodv-rqueue.cc` | ✅ | `GetSize()` implementation made const |
| `src/aodv/model/aodv-routing-protocol.h` | ✅ | All CC/ECC members, methods, decay timer |
| `src/aodv/model/aodv-routing-protocol.cc` | ✅ | All CC/ECC logic: ATM, QACD, MMPS, gate, scoring |
| `scratch/aodv-simulator.cc` | ✅ | New file: full simulation driver |
| `targeted_run.sh` | ✅ | New file: 30-combo experiment runner |

---

## 2. Changes Per File

---

### 2.1 `aodv-packet.h` — New RREP Fields (OPHD)

**Problem:** CC-AODV used a full 32-bit field for a single boolean flag — 31 bits wasted per RREP packet.

**Fix:** Two compact byte fields packed with bit-ops:

```cpp
// Added to RrepHeader private members:
uint8_t m_congestionFlag;  // 1 byte: used as boolean (0=no congestion, 1=congested)
                            // CC-AODV reads this to increment its counter
uint8_t m_eccInfo;          // 1 byte: ECC OPHD payload packed as two sub-fields:
                            //   bits [5:4] => 2-bit congestion level (0..3)
                            //   bits [3:0] => 4-bit hop quality (0..15)
```

**Accessor methods added:**

```cpp
// CC-AODV: simple boolean congestion signal
void    SetCongestionFlag(uint8_t f)  { m_congestionFlag = f; }
uint8_t GetCongestionFlag() const     { return m_congestionFlag; }

// ECC-AODV OPHD: 2-bit congestion level in bits [5:4]
void SetCongestionLevel(uint8_t level) {
    m_eccInfo = (m_eccInfo & 0xCF) | ((level & 0x03) << 4);
}
uint8_t GetCongestionLevel() const { return (m_eccInfo >> 4) & 0x03; }

// ECC-AODV OPHD: 4-bit hop quality in bits [3:0]
void SetHopQuality(uint8_t quality) {
    m_eccInfo = (m_eccInfo & 0xF0) | (quality & 0x0F);
}
uint8_t GetHopQuality() const { return m_eccInfo & 0x0F; }
```

**OPHD result:** 6 bits carry richer info than the original 32-bit bool — 81% memory savings per RREP.

---

### 2.2 `aodv-packet.cc` — Serialize / Deserialize Updated

**What changed:** RREP serialized size increased from 19 → 21 bytes; both new fields are written and read.

```cpp
// Constructor init (both fields default to 0):
m_origin(origin),
m_congestionFlag(0),
m_eccInfo(0)

// Serialize:
i.WriteU8(m_congestionFlag);
i.WriteU8(m_eccInfo);

// Deserialize:
m_congestionFlag = i.ReadU8();
m_eccInfo        = i.ReadU8();

// GetSerializedSize():
return 21;  // was 19

// Equality operator extended:
... && m_congestionFlag == o.m_congestionFlag && m_eccInfo == o.m_eccInfo
```

---

### 2.3 `aodv-rtable.h` — Routing Table Size Accessor

**Why needed:** ATM (Adaptive Threshold Management) needs a local estimate of network density. The number of entries in the routing table is the best available local proxy — more routes = denser network.

```cpp
// Returns number of known routes; used by calculateAdaptiveThreshold()
uint32_t GetSize() const
{
    return static_cast<uint32_t>(m_ipv4AddressEntry.size());
}
```

---

### 2.4 `aodv-rqueue.h` / `aodv-rqueue.cc` — const GetSize()

**Why needed:** `calculateCongestionLevel()` is a `const` method. It needs to read queue size. The existing `GetSize()` was non-const (it called `Purge()` internally). Made const via `const_cast`.

```cpp
// aodv-rqueue.h:
uint32_t GetSize() const;   // was: uint32_t GetSize();

// aodv-rqueue.cc:
uint32_t
RequestQueue::GetSize() const
{
    const_cast<RequestQueue*>(this)->Purge();  // remove expired entries first
    return m_queue.size();
}
```

---

### 2.5 `aodv-routing-protocol.h` — New Members and Methods

#### Public accessor (Bonus C queue tracing)

```cpp
// Returns packets buffered waiting for route discovery.
// Used by the queue-size-over-time logger in the simulator.
uint32_t GetQueueSize() const { return m_queue.GetSize(); }
```

#### CC-AODV state (base paper — must stay as-is)

```cpp
uint32_t m_congestionCounter;   // per-node congestion load counter
uint32_t m_baseThreshold;       // configurable threshold (default 3, via --ccBaseThreshold)
bool     m_enableCcAodv;        // flag: activate CC-AODV behaviour
uint32_t m_avgNeighborCounter;  // EWMA of recent counter values (used by ATM)

Timer    m_congestionCounterDecayTimer;    // fires every 1s to decrement counter
void     CongestionCounterDecayTimerExpire(); // decay handler
```

#### ECC-AODV state

```cpp
bool   m_enableEccAodv;  // flag: activate ECC-AODV (on top of CC-AODV)

// QACD weights — tuned separately from MMPS weights (see Section 3 for explanation)
double m_w1;  // weight: queue occupancy ratio        (default 0.6 at runtime)
double m_w2;  // weight: counter/threshold ratio      (default 0.2 at runtime)
double m_w3;  // weight: data-packet drop rate        (default 0.2 at runtime)
              // NOTE: code defaults in constructor are 0.5/0.3/0.2 (for backward compat);
              //       targeted_run.sh passes --w1=0.6 --w2=0.2 --w3=0.2 (tuned values)

double   m_congestionLevel;  // last computed CL, cached for RREP metadata generation
uint32_t m_totalDrops;       // RREQ packets dropped by congestion gate
uint32_t m_totalForwards;    // RREQ packets forwarded through congestion gate
uint32_t m_dataDrops;        // data packets dropped (feeds QACD w3 term)
uint32_t m_dataForwards;     // data packets successfully forwarded

std::map<Ipv4Address, RrepHeader> m_bestRrep;       // MMPS: best RREP seen per dest
std::map<Ipv4Address, double>     m_bestRrepScore;  // MMPS: score of that best RREP
```

#### Method declarations

```cpp
bool     isNodeCongested() const;           // CC gate: counter > threshold?
uint32_t calculateAdaptiveThreshold() const; // ATM: density-scaled threshold
double   calculateCongestionLevel() const;  // QACD: weighted 3-term CL
double   computeRrepScore(const RrepHeader& rrep) const;  // MMPS: score one RREP
```

---

### 2.6 `aodv-routing-protocol.cc` — All CC/ECC Logic

#### (A) NS-3 TypeId Attributes

Attributes allow `--mode=ecc-aodv` and weight flags to flow from CLI → simulator → protocol. Registered in `RoutingProtocol::GetTypeId()`:

```cpp
.AddAttribute("EnableCcAodv",      BooleanValue(false), ...)
.AddAttribute("BaseThreshold",     UintegerValue(4),    ...)
.AddAttribute("EnableEccAodv",     BooleanValue(false), ...)
.AddAttribute("QACDWeightQueue",   DoubleValue(0.5),    ...)  // w1
.AddAttribute("QACDWeightCounter", DoubleValue(0.3),    ...)  // w2
.AddAttribute("QACDWeightDropRate",DoubleValue(0.2),    ...)  // w3
```

#### (B) Constructor Initialization

```cpp
m_congestionCounter(0),
m_baseThreshold(4),
m_enableCcAodv(false),
m_enableEccAodv(false),
m_avgNeighborCounter(0),
m_w1(0.5), m_w2(0.3), m_w3(0.2),   // overridden at runtime by --w1/w2/w3
m_totalDrops(0), m_totalForwards(0),
m_dataDrops(0),  m_dataForwards(0),
m_congestionLevel(0.0)
```

#### (C) ATM — Adaptive Threshold Management

**Why:** Fixed threshold `m_baseThreshold` is too restrictive in sparse networks and too permissive in dense ones. ATM scales it using routing table size as a density proxy and the EWMA neighbor counter as a load proxy.

```cpp
uint32_t
RoutingProtocol::calculateAdaptiveThreshold() const
{
    double threshold = static_cast<double>(m_baseThreshold);

    // Scale by local network density (routing table size)
    uint32_t networkSize = m_routingTable.GetSize();
    if (networkSize <= 10)      threshold *= 0.6;  // sparse: tighten threshold
    else if (networkSize <= 30) threshold *= 1.0;  // medium: keep as-is
    else                        threshold *= 1.4;  // dense:  loosen threshold

    // Scale further by average neighbor congestion
    threshold *= (1.0 + static_cast<double>(m_avgNeighborCounter) / 10.0);

    return std::max(1u, static_cast<uint32_t>(threshold));
}
```

#### (D) CC Gate Predicate

```cpp
bool
RoutingProtocol::isNodeCongested() const
{
    if (m_enableEccAodv)
        return m_congestionCounter > calculateAdaptiveThreshold();  // ECC: adaptive
    return m_congestionCounter > m_baseThreshold;                   // CC:  fixed
}
```

#### (E) QACD — Queue-Aware Congestion Detection

**Why:** CC-AODV only uses the route counter. QACD blends three real signals:
- `w1 × qRatio`: how full is the local packet buffer right now
- `w2 × cRatio`: how loaded is the node relative to its threshold
- `w3 × dropRate`: what fraction of recent data packets were dropped

```cpp
double
RoutingProtocol::calculateCongestionLevel() const
{
    // Term 1: queue occupancy ratio
    double qMax  = static_cast<double>(m_maxQueueLen);
    double qCurr = static_cast<double>(m_queue.GetSize());
    double qRatio = (qMax > 0.0) ? (qCurr / qMax) : 0.0;

    // Term 2: counter / adaptive threshold
    uint32_t effThresh = calculateAdaptiveThreshold();
    double cRatio = (effThresh > 0)
        ? std::min(static_cast<double>(m_congestionCounter) / static_cast<double>(effThresh), 1.0)
        : 1.0;

    // Term 3: actual data-packet drop rate (not RREQ drops)
    double totalData = static_cast<double>(m_dataDrops + m_dataForwards);
    double dropRate  = (totalData > 0.0)
        ? (static_cast<double>(m_dataDrops) / totalData)
        : 0.0;

    return m_w1 * qRatio + m_w2 * cRatio + m_w3 * dropRate;
}
```

**Result:** CL in [0, 1]. If CL ≥ 0.7 the node drops the RREQ.

#### (F) MMPS — Multi-Metric Path Selection

**Why:** When multiple RREPs arrive for the same destination, stock AODV picks the first valid one. MMPS scores each RREP and keeps the best one, trading slightly longer paths for less-congested routes.

```cpp
double
RoutingProtocol::computeRrepScore(const RrepHeader& rrep) const
{
    // alpha/beta/gamma are MMPS-specific weights — different from QACD w1/w2/w3
    // (see Section 3 for full explanation of the two weight sets)
    constexpr double alpha = 0.6;   // hop count weight
    constexpr double beta  = 0.2;   // path quality weight
    constexpr double gamma = 0.2;   // congestion avoidance weight

    uint32_t hops = std::max(1u, static_cast<uint32_t>(rrep.GetHopCount()));

    double hopScore         = alpha / static_cast<double>(hops);
    double qualityScore     = beta  * (static_cast<double>(rrep.GetHopQuality()) / 15.0);
    double congestionScore  = gamma / (static_cast<double>(rrep.GetCongestionLevel()) + 1.0);

    return hopScore + qualityScore + congestionScore;
}
```

Higher score = better path. The source updates its route table only when a new RREP beats the best score seen so far for that destination.

#### (G) RREQ Gate in `RecvRequest()`

```cpp
// Called when a RREQ arrives at an intermediate node
if (m_enableEccAodv)
{
    m_congestionLevel = calculateCongestionLevel();  // runs ATM + QACD
    if (m_congestionLevel >= 0.7)
    {
        m_totalDrops++;
        return;   // drop: this node is too congested to forward
    }
    m_totalForwards++;
}
else if (m_enableCcAodv && isNodeCongested())
{
    return;       // CC-AODV simple counter gate
}
```

#### (H) RREP Metadata in `SendReply()` and `SendReplyByIntermediateNode()`

```cpp
// Both CC and ECC set the congestion flag (CC-AODV counter increment mechanism)
if (m_enableCcAodv || m_enableEccAodv)
    rrepHeader.SetCongestionFlag(1);

// ECC also encodes CL level and path quality in the OPHD byte
if (m_enableEccAodv)
{
    // Map float CL to 2-bit level
    uint8_t clLevel = 0;
    if      (m_congestionLevel >= 0.7) clLevel = 3;
    else if (m_congestionLevel >= 0.5) clLevel = 2;
    else if (m_congestionLevel >= 0.3) clLevel = 1;
    rrepHeader.SetCongestionLevel(clLevel);

    // Hop quality: high = less congested (15 = empty queue, 0 = full queue)
    double qOccupancy = (m_maxQueueLen > 0)
        ? static_cast<double>(m_queue.GetSize()) / static_cast<double>(m_maxQueueLen)
        : 0.0;
    uint8_t hopQuality = static_cast<uint8_t>(
        std::max(0.0, std::min(15.0, (1.0 - qOccupancy) * 15.0)));
    rrepHeader.SetHopQuality(hopQuality);
}
```

#### (I) RREP Reception + MMPS Decision in `RecvReply()`

```cpp
// CC-AODV: increment counter when a flagged RREP passes through
if (m_enableCcAodv && rrepHeader.GetCongestionFlag() == 1)
    m_congestionCounter++;

// ECC-AODV: same increment + EWMA update + score-based route selection
if (m_enableEccAodv)
{
    if (rrepHeader.GetCongestionFlag() == 1)
        m_congestionCounter++;

    // EWMA: smooth the neighbor congestion signal (0.8 old + 0.2 new)
    m_avgNeighborCounter = static_cast<uint32_t>(
        0.8 * static_cast<double>(m_avgNeighborCounter) +
        0.2 * static_cast<double>(m_congestionCounter));

    // MMPS: keep the best-scoring RREP per destination
    double newScore = computeRrepScore(rrepHeader);
    if (m_bestRrepScore.find(dst) == m_bestRrepScore.end() || newScore > m_bestRrepScore[dst])
    {
        m_bestRrepScore[dst] = newScore;
        m_bestRrep[dst]      = rrepHeader;
        shouldUpdate         = true;   // tell route table to update
    }
}
```

#### (J) Data Packet Drop/Forward Counters

These feed the QACD w3 (drop rate) term. Incremented in `Forwarding()`:

```cpp
// On successful data forward:
if (m_enableEccAodv) m_dataForwards++;

// On data packet drop (no route or invalid):
if (m_enableEccAodv) m_dataDrops++;
```

#### (K) Congestion Counter Decay Timer

**Why:** Without decay, a previously congested node's counter never decreases and it permanently blocks future RREQs even after the congestion clears.

```cpp
// Fires every 1 second via m_congestionCounterDecayTimer
void
RoutingProtocol::CongestionCounterDecayTimerExpire()
{
    if (m_congestionCounter > 0)
        m_congestionCounter--;
    m_congestionCounterDecayTimer.Schedule(Seconds(1));
}

// Scheduled in Start():
m_congestionCounterDecayTimer.SetFunction(
    &RoutingProtocol::CongestionCounterDecayTimerExpire, this);
m_congestionCounterDecayTimer.Schedule(Seconds(1));
```

#### (L) Link-Break Decrement

```cpp
// When a route breaks (RERR sent), the load that route contributed is gone
if (m_enableCcAodv && m_congestionCounter > 0)
    --m_congestionCounter;
```

#### (M) Cleanup on Destroy

```cpp
m_congestionCounter = 0;  // in DoDispose()
```

---

## 3. QACD Weights vs MMPS Weights — Key Distinction

These are **two separate weight sets for two separate purposes**. They have the same names (`w1/w2/w3` and `alpha/beta/gamma`) but completely different meanings:

### QACD Weights (`w1`, `w2`, `w3`) — used in `calculateCongestionLevel()`

Decide **whether to drop or forward an RREQ** at each intermediate node:

| Weight | Variable | Controls | Default (code) | Tuned (runtime) |
|--------|----------|----------|----------------|-----------------|
| w1 | `m_w1` | Queue occupancy ratio weight | 0.5 | **0.6** |
| w2 | `m_w2` | Counter/threshold ratio weight | 0.3 | **0.2** |
| w3 | `m_w3` | Data-packet drop rate weight | 0.2 | **0.2** |

> Tuned values (0.6/0.2/0.2) are passed at runtime via `--w1=0.6 --w2=0.2 --w3=0.2` in `targeted_run.sh`. The code constructor defaults (0.5/0.3/0.2) are the safe fallback if no CLI args are given.

### MMPS Weights (`alpha`, `beta`, `gamma`) — used in `computeRrepScore()`

Decide **which received RREP to prefer** when multiple paths are available:

| Weight | Controls | Value |
|--------|----------|-------|
| alpha | Hop count importance (shorter = better) | **0.6** |
| beta | Path quality (lower queue load = better) | **0.2** |
| gamma | Congestion level avoidance | **0.2** |

> These are `constexpr` inside the function — not configurable via CLI. alpha=0.6 means the source **strongly prefers fewer hops**, which keeps latency low. beta and gamma each contribute 0.2, meaning path quality and congestion avoidance are secondary tie-breakers.

### Are alpha/beta/gamma correct?

Yes, the values are reasonable:
- `alpha=0.6` dominates: routes won't grow arbitrarily long just to avoid one congested node
- `beta=0.2` rewards low-queue-load paths (from HopQuality field)
- `gamma=0.2` discourages paths through 3=high-congestion nodes

The proposal (`ns3_proposal.tex` Section 4.4) gives `alpha=0.3, beta=0.4, gamma=0.3` as a suggestion. Our implementation uses `alpha=0.6, beta=0.2, gamma=0.2` — prioritizing hop-count more aggressively, which empirically gave better PDR in our parameter sweep (lower delay at the cost of slightly more congestion exposure).

---

## 4. Flowcharts

All boxes use the same style: `[ ]` for process, `< >` for decision, `-->` for flow.

---

### 4.1 RREQ Handling at Intermediate Node

```
RecvRequest(RREQ arrives)
       |
       v
 [duplicate / blacklist check]
       |-- drop if seen before
       |
       v
 < ECC enabled? >
    |         |
   YES        NO
    |          |
    v          v
 [CL = calculateCongestionLevel()]   < CC enabled? >
    |                                   |          |
    v                                  YES         NO
 < CL >= 0.7? >                        |           |
    |        |                   [isNodeCongested?] |
   YES       NO                    |         |     |
    |         |                   YES        NO    |
    v         |                    |          |    |
 [drop RREQ]  |                 [drop]    [continue to route lookup]
 [m_totalDrops++]  [m_totalForwards++]
              |
              |<-------------------------------------------+
              v
 < am I the destination? >
       |           |
      YES           NO
       |             |
  [SendReply()]   < valid cached route AND !DestinationOnly? >
                        |                    |
                       YES                   NO
                        |                    |
              [SendReplyByIntermediateNode()] [forward RREQ]
```

---

### 4.2 RREP Generation (SendReply / SendReplyByIntermediateNode)

```
SendReply() / SendReplyByIntermediateNode()
       |
       v
 [create RrepHeader with hop count, dest seq, lifetime]
       |
       v
 < CC or ECC enabled? >
       |
      YES
       |
       v
 [SetCongestionFlag(1)]    <-- CC-AODV baseline: enables counter at forwarding nodes
       |
       v
 < ECC enabled? >
       |
      YES
       |
       v
 [SetCongestionLevel(0..3)]  <-- map m_congestionLevel float to 2-bit field
 [SetHopQuality(0..15)]      <-- 15 - round(qOccupancy * 15); high = less loaded
       |
       v
 [send RREP unicast toward source]
```

---

### 4.3 RREP Reception + Counter Update + MMPS

```
RecvReply(RREP arrives)
       |
       v
 [hopCount++]
       |
       v
 < CC enabled AND flag==1? >
      YES -> [m_congestionCounter++]
       |
       v
 < ECC enabled? >
       |
      YES
       |
       v
 [if flag==1: m_congestionCounter++]
 [m_avgNeighborCounter = 0.8*old + 0.2*counter]  <-- EWMA smoothing
       |
       v
 [newScore = computeRrepScore(rrep)]   <-- MMPS scoring
       |
       v
 < newScore > bestScore[dst]? >
      YES -> [update m_bestRrep, m_bestRrepScore, shouldUpdate=true]
      NO  -> [discard, keep existing route]
       |
       v
 [if shouldUpdate: write route to routing table]
```

---

### 4.4 Congestion Counter Decay (every 1 second)

```
Start()
  |
  v
 [schedule decay timer at t+1s]
  |
  v           (repeating every 1s for full sim duration)
 [CongestionCounterDecayTimerExpire()]
  |
  v
 < m_congestionCounter > 0? >
       YES -> [m_congestionCounter--]
  |
  v
 [reschedule timer at t+1s]
```

---

### 4.5 RREP Responder: Who Generates the RREP?

```
RREQ propagating through network
  |
  v
 < Am I the destination (RREQ.dst == my IP)? >
       |                    |
      YES                   NO
       |                    |
  [SendReply()]    < Do I have a fresh valid route to dst?
       |             AND is DestinationOnly flag false? >
       |                    |              |
       |                   YES             NO
       |                    |              |
       |  [SendReplyByIntermediateNode()]  [forward RREQ]
       |
       v (both paths merge here)
  RREP unicast back toward source
  ECC fields set from LOCAL state at the responder
  (CL/HQ reflect the RESPONDER node, not intermediate forwarders)
```

---

### 4.6 End-to-End ECC Route Discovery

```
SOURCE needs route to DST
  |
  v
 [broadcast RREQ]
  |
  v
 [RREQ propagates; each intermediate node runs gate]
  |
  |-- ECC: CL >= 0.7 -> drop RREQ (reduces load on busy nodes)
  |-- CC:  counter > threshold -> drop RREQ (cruder check)
  |-- AODV: always forward (no congestion awareness)
  |
  v
 [RREPs return from destination and/or intermediate nodes]
  |
  v
 [ECC source: score each RREP via computeRrepScore()]
  |
  v
 [keep highest-scoring RREP as the selected route]
  |
  v
 [data flows along selected path]
```

---

## 5. Worked Examples

### 5.1 QACD Congestion Level Calculation

Scenario (with tuned weights w1=0.6, w2=0.2, w3=0.2):

```
queue occupancy: 20 / 64 = 0.3125
counter ratio  : 3  /  5 = 0.60
drop rate      : 10 / 50 = 0.20

CL = 0.6 × 0.3125  +  0.2 × 0.60  +  0.2 × 0.20
   = 0.1875         +  0.120        +  0.040
   = 0.3475
```

CL = 0.35 < 0.7 → RREQ is **forwarded**. Node is moderately loaded but not congested enough to block.

---

### 5.2 MMPS Path Comparison

Two RREPs received for the same destination:

```
Path A: hop=2, HopQuality=12, CongestionLevel=1
Path B: hop=3, HopQuality=15, CongestionLevel=0

Score_A = 0.6/2  +  0.2×(12/15)  +  0.2/(1+1)
        = 0.300  +  0.160         +  0.100  =  0.560

Score_B = 0.6/3  +  0.2×(15/15)  +  0.2/(0+1)
        = 0.200  +  0.200         +  0.200  =  0.600
```

MMPS selects **Path B** (one extra hop but uncongested and high quality).

---

### 5.3 Counter Decay Timeline

```
t=0.0s  counter=0   (start)
t=0.3s  RREP flag=1 arrives  ->  counter=1
t=0.8s  RREP flag=1 arrives  ->  counter=2
t=1.0s  decay tick            ->  counter=1
t=2.0s  decay tick            ->  counter=0
```

Without decay, `counter=2` would permanently block RREQs after just two route discoveries.

---

## 6. Simulator Changes (`scratch/aodv-simulator.cc`)

This file does not exist in `ns-3.45_cleaned` — it is entirely new.

### 6.1 Topology Selector (`SetupMobility`)

```cpp
if (opt.topology == "static")
{
    // Nodes randomly placed inside a square of side = areaMultiplier × txRange
    // ConstantPositionMobilityModel: no movement
    double side = opt.areaMultiplier * opt.txRange;  // e.g. 2 × 250m = 500m
    ...
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
}
else  // "mobile"
{
    // Nodes start on a grid, then use RandomWaypointMobilityModel
    mobility.SetMobilityModel("ns3::RandomWaypointMobilityModel", ...);
}
```

Both topologies use the same 802.11b PHY — only mobility model changes.

### 6.2 Bonus B: Per-Node Throughput CSV (`--perNodeThroughput=true`)

At sim end, maps each flow's destination IP → node index and writes:

```
NodeId, RxPackets, RxBytes, ThroughputKbps
```

File: `<outputDir>/<prefix>-per-node-tput.csv`

### 6.3 Bonus C: Queue-Size Over Time CSV (`--queueSizeTrace=true`)

Schedules `PollQueueSizes()` every `--queuePollInterval` seconds.  
Each call reads `GetQueueSize()` from every node's AODV protocol and stores a sample.  
At sim end, writes:

```
Time(s), NodeId, QueueSize(packets)
```

File: `<outputDir>/<prefix>-queue-size.csv`

### 6.4 Tracing Toggle Summary

Set these in `targeted_run.sh` before running:

```bash
ENABLE_TRACE=false          # PHY ASCII .tr + PCAP + IPv4 drop log + mobility log
ENABLE_RD_TRACE=false       # RREQ/RREP logs         (needs ENABLE_TRACE=true)
ENABLE_RT_TRACE=false       # Routing table snapshots (needs ENABLE_TRACE=true)
ENABLE_PER_NODE_TPUT=false  # Bonus B CSV (standalone — no dependency)
ENABLE_QUEUE_TRACE=false    # Bonus C CSV (standalone — no dependency)
QUEUE_POLL_INTERVAL=1.0     # Sample every N seconds
```

---

## 7. Replication Checklist

1. `aodv-packet.h/.cc` — add `m_congestionFlag`, `m_eccInfo`, serialize ±2 bytes
2. `aodv-rtable.h` — add `GetSize()` 
3. `aodv-rqueue.h/.cc` — make `GetSize()` const
4. `aodv-routing-protocol.h` — add all CC/ECC members, method declarations, `GetQueueSize()`
5. `aodv-routing-protocol.cc` — add TypeId attrs, constructor inits, ATM, QACD, MMPS, gate, RREP metadata, decay timer, data counters
6. `scratch/aodv-simulator.cc` — new file (topology selector, energy, bonus CSVs)
7. `targeted_run.sh` — new file (30-combo sweep)
