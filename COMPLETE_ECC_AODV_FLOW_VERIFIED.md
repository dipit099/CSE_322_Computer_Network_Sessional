# Complete ECC-AODV Protocol Flow - VERIFIED & CORRECTED

**Date:** March 18, 2026  
**Status:** ✅ All bugs fixed and verified in code  
**Changes Made:**
1. ✅ SetCongestionFlag now set for BOTH CC-AODV AND ECC-AODV (not CC-AODV only)
2. ✅ ECC-AODV increments counter when receiving RREP with flag=1
3. ✅ Congestion level now reflects counter feedback + queue + drops

---

## PHASE 1: FORWARD RREQ

```
┌─────────────────────────────────────────────────────────────────┐
│                   SOURCE NODE initiates                          │
│                   SendRequest() → Broadcasts RREQ               │
│                   (No CC/ECC metrics in RREQ yet)               │
└─────────────────────┬───────────────────────────────────────────┘
                      │ RREQ packet
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│           INTERMEDIATE NODE receives RREQ                        │
│           RecvRequest(packet, receiver, sender) [LINE 1441]     │
│                                                                 │
│  ▶ Decision Point: Should I forward this RREQ?                 │
│                                                                 │
│  IF CC-AODV enabled (m_enableCcAodv=true):                     │
│  ├─ Calculate: isNodeCongested() [LINE 395]                    │
│  ├─ Returns: m_congestionCounter > m_baseThreshold (=4)        │
│  ├─ If true → DROP RREQ (return, no forward) [LINE 1473]       │
│  └─ Else → FORWARD RREQ                                         │
│                                                                 │
│  IF ECC-AODV enabled (m_enableEccAodv=true):                   │
│  ├─ Calculate: m_congestionLevel = calculateCongestionLevel()  │
│  │             = w1*qRatio + w2*cRatio + w3*dropRate           │
│  │             where cRatio = counter / adaptiveThreshold      │
│  ├─ If level >= 0.7 → DROP RREQ (return, no forward) [LINE 1474]
│  └─ Else → FORWARD RREQ                                         │
│                                                                 │
│  ⚠️  NO CALCULATIONS YET FOR RREP FIELDS                        │
│      (CongestionLevel, HopQuality not set during forward)       │
│      (CongestionFlag not set, will be set by destination)       │
│                                                                 │
└─────────────────────┬───────────────────────────────────────────┘
                      │ Forwarded RREQ (unchanged)
                      ▼
        [More intermediate nodes repeat above]
                      │
                      ▼
        ┌────────────────────────────────────┐
        │     DESTINATION receives RREQ      │
        └────────────────────────────────────┘
```

**Code Reference:** `RecvRequest()` at line 1441
- CC-AODV check: lines 1472-1473
- ECC-AODV check: lines 1466-1474
- Counter value: `m_congestionCounter` (incremented on RREP reception)

---

## PHASE 2: BACKWARD RREP GENERATION AT DESTINATION

```
┌──────────────────────────────────────────────────────────────────┐
│              DESTINATION receives RREQ                           │
│              Calls: SendReply(rreqHeader, toOrigin) [LINE 1666]  │
│                                                                  │
│  ▶ CREATE RREP HEADER:                                          │
│                                                                  │
│  RrepHeader fields initialized:                                  │
│  ├─ hopCount = 0 (destination is 0 hops away)                  │
│  ├─ dst = myself (destination)                                  │
│  ├─ dstSeqNo = m_seqNo (my sequence number)                     │
│  ├─ origin = RREQ.origin (who asked)                            │
│                                                                  │
│  ▶ SET CONGESTION FLAG:                                         │
│                                                                  │
│  ├─ IF (m_enableCcAodv || m_enableEccAodv):  ✅ [LINE 1680]    │
│  │    └─ SetCongestionFlag(1)                                   │
│  │       [BOTH CC and ECC set this for counter feedback]        │
│  │                                                              │
│  └─ Purpose: Tell intermediate nodes "I'm a valid path"        │
│     and trigger their counter feedback                          │
│                                                                  │
│  ▶ SET ECC-AODV METRICS (if enabled):  [LINE 1686+]           │
│                                                                  │
│  ├─ Calculate m_congestionLevel (from my local queue):          │
│  │   CL = 0.3*qRatio + 0.4*cRatio + 0.3*dropRate              │
│  │                                                              │
│  ├─ Map to CongestionLevel field (0-3):                        │
│  │   ├─ CL >= 0.7 → clLevel = 3                               │
│  │   ├─ CL >= 0.5 → clLevel = 2                               │
│  │   ├─ CL >= 0.3 → clLevel = 1                               │
│  │   └─ CL < 0.3  → clLevel = 0                               │
│  │   └─ SetCongestionLevel(clLevel)  [LINE 1699]              │
│  │                                                              │
│  ├─ Calculate queue occupancy:                                  │
│  │   qOccupancy = queue_size / max_queue  [LINE 1701-1703]    │
│  │                                                              │
│  ├─ Calculate HopQuality:                                       │
│  │   hopQuality = (1.0 - qOccupancy) * 15.0                   │
│  │   Clamped to [0, 15] as uint8_t                            │
│  │   SetHopQuality(hopQuality)  [LINE 1704]                   │
│  │                                                              │
│  └─ Meaning:                                                    │
│     ├─ CongestionLevel: "I'm congested at level 0-3"          │
│     └─ HopQuality: "My queue is 0-15 quality (15=empty)"      │
│                                                                 │
│  ▶ RREP sent back toward origin with:                         │
│    ├─ hopCount = 0                                             │
│    ├─ CongestionFlag = 1  ✅ [BOTH CC and ECC]                │
│    ├─ CongestionLevel = 0-3  (if ECC-AODV)                    │
│    └─ HopQuality = 0-15  (if ECC-AODV)                        │
│                                                                 │
└──────────────────────┬──────────────────────────────────────────┘
                       │ RREP sent back with flag and metrics
                       ▼
```

**Code References:**
- `SendReply()` at line 1666
- SetCongestionFlag: line 1680 (NOW: `if (m_enableCcAodv || m_enableEccAodv)`)
- SetCongestionLevel: line 1699
- SetHopQuality: line 1704

---

## PHASE 3: RREP PROPAGATION THROUGH INTERMEDIATE NODES

```
┌──────────────────────────────────────────────────────────────────┐
│           INTERMEDIATE NODE receives RREP                        │
│           Calls: RecvReply(packet, receiver, sender) [LINE 1841] │
│                                                                  │
│  ▶ EXTRACT from RREP header:                                   │
│    ├─ hopCount (from destination) = 0                          │
│    ├─ CongestionLevel (from destination) = 0-3                │
│    ├─ HopQuality (from destination) = 0-15                    │
│    ├─ CongestionFlag = 1  ✅                                   │
│                                                                  │
│  ▶ INCREMENT hopCount:                                          │
│    └─ hop = rrep.GetHopCount() + 1  [LINE 1858]               │
│       (Now hop = 1 for intermediate, 2 for next, etc)          │
│                                                                  │
│  ▶ COUNTER FEEDBACK (CC-AODV & ECC-AODV):  [LINE 1859+]      │
│                                                                  │
│    IF (m_enableCcAodv && flag == 1):                           │
│    │   m_congestionCounter++  [LINE 1859]                     │
│    │   Reason: "I got a RREP = path is working"               │
│    │                                                            │
│    IF (m_enableEccAodv && flag == 1):  ✅ [LINE 1864+]        │
│    │   m_congestionCounter++  ✅ [LINE 1866]                  │
│    │   Reason: "I got a RREP = track this path reuse"         │
│    │                                                            │
│    THEN (m_enableEccAodv):                                      │
│    └─  Update m_avgNeighborCounter  [LINE 1870-1873]          │
│        = 0.8*oldAvg + 0.2*currentCounter                       │
│        (Exponential weighted average of neighbor activity)     │
│                                                                  │
│  ✗ METRICS NOT MODIFIED:                                        │
│    ├─ CongestionLevel: STAYS as-is (from destination)          │
│    ├─ HopQuality: STAYS as-is (from destination)               │
│    ├─ CongestionFlag: STAYS as-is (= 1)                        │
│    └─ hopCount: INCREMENTED (updated locally)                  │
│                                                                  │
│  ▶ FORWARD RREP toward origin (next hop) with:                │
│    ├─ CongestionLevel (from destination, UNCHANGED)            │
│    ├─ HopQuality (from destination, UNCHANGED)                 │
│    ├─ CongestionFlag (always = 1, UNCHANGED)                   │
│    └─ Updated hopCount (1 more than before)                    │
│                                                                  │
│  Note: Intermediate node's congestion is NOT sent to source     │
│        It only affects its own RREQ drop decision               │
│                                                                  │
└──────────────────────┬──────────────────────────────────────────┘
                       │ RREP forwarded back (destination metrics only)
                       ▼
        [More intermediate nodes - repeat above]
        (Each increments counter, but doesn't change metrics)
                       │
                       ▼
```

**Code References:**
- `RecvReply()` at line 1841
- Increment hopCount: line 1858
- CC-AODV counter feedback: lines 1859-1862
- ECC-AODV counter feedback: lines 1864-1867
- ECC-AODV average update: lines 1870-1873

---

## PHASE 4: RREP RECEPTION AT SOURCE NODE (SCORING & ROUTE SELECTION)

```
┌──────────────────────────────────────────────────────────────────┐
│           SOURCE NODE receives RREP  [LINE 1841]                 │
│           ▶ THIS IS WHERE SCORING HAPPENS (ECC-AODV)            │
│                                                                  │
│  Extract from RREP:                                              │
│  ├─ hopCount (accumulated distance from destination)            │
│  ├─ CongestionLevel (ONLY from destination, unchanged)         │
│  ├─ HopQuality (ONLY from destination, unchanged)              │
│  ├─ CongestionFlag = 1  ✅                                      │
│                                                                  │
│  ▶ INCREMENT hopCount:  [LINE 1858]                            │
│    └─ hop = rrep.GetHopCount() + 1                             │
│       (Now reflects full distance from source to destination)   │
│                                                                  │
│  ▶ COUNTER FEEDBACK (CC-AODV):  [LINE 1859-1862]              │
│    if (m_enableCcAodv && flag == 1):                           │
│    └─ m_congestionCounter++                                     │
│       (Source also increments from RREP receipt)               │
│                                                                  │
│  ▶ COUNTER FEEDBACK + ECC SCORING (ECC-AODV):  [LINE 1864+]   │
│                                                                  │
│    if (m_enableEccAodv && flag == 1):  ✅                      │
│    ├─ m_congestionCounter++  ✅ [LINE 1866]                   │
│    │  (Source tracks path reuse feedback)                      │
│    │                                                            │
│    └─ Update m_avgNeighborCounter  [LINE 1870-1873]            │
│       = 0.8*oldAvg + 0.2*currentCounter                        │
│       (Tracks neighbor congestion trend)                        │
│                                                                  │
│  ▶ SCORE CALCULATION (ECC-AODV ONLY):  [LINE 1878+]           │
│                                                                  │
│  if (m_enableEccAodv):                                           │
│  ├─ newScore = computeRrepScore(rrepHeader)  [LINE 1878]       │
│  │                                                              │
│  │  Inside computeRrepScore (line 419):                        │
│  │  ├─ hopScore = α / hopCount                                 │
│  │  │             = 0.3 / hopCount                             │
│  │  │             Prefers shorter paths                        │
│  │  │                                                          │
│  │  ├─ qualityScore = β * (hopQuality / 15.0)                 │
│  │  │                = 0.4 * (hopQuality / 15.0)              │
│  │  │                Prefers higher quality (less queue)       │
│  │  │                Division by 15 normalizes uint8_t [0,15] │
│  │  │                                                          │
│  │  ├─ congestionScore = γ / (congestionLevel + 1.0)          │
│  │  │                  = 0.3 / (congestionLevel + 1.0)        │
│  │  │                  Prefers lower congestion (+1 avoids /0) │
│  │  │                                                          │
│  │  └─ finalScore = hopScore + qualityScore + congestionScore │
│  │                = 0.3/hops + 0.4*(HQ/15) + 0.3/(CL+1)       │
│  │                ↑           ↑ from DST only  ↑               │
│  │                │           │                └─ from DST only│
│  │                └─ accumulated hops through path             │
│  │                                                              │
│  ├─ WHICH FIELDS CONTRIBUTE:                                   │
│  │  ├─ hopCount: From destination, accumulated (all hops)     │
│  │  ├─ HopQuality: ONLY from destination node                 │
│  │  ├─ CongestionLevel: ONLY from destination node            │
│  │  └─ NOT from intermediate nodes!                           │
│  │                                                              │
│  ├─ COMPARE with best previous score:  [LINE 1879-1883]       │
│  │  if (newScore > m_bestRrepScore[dst]):                     │
│  │     ├─ eccBetterScore = true                               │
│  │     ├─ m_bestRrepScore[dst] = newScore                     │
│  │     └─ m_bestRrep[dst] = rrepHeader                        │
│  │                                                              │
│  └─ This RREP is now candidate for best route                 │
│                                                                  │
│  ▶ ROUTE UPDATE CONDITIONS:  [LINE 1919-1927]                 │
│                                                                  │
│  Update routing table if:                                        │
│  ├─ (i)   SeqNo invalid in table, OR                           │
│  ├─ (ii)  RREP has higher seqNo, OR                            │
│  ├─ (iii) Same seqNo but route was inactive, OR                │
│  ├─ (iv)  Same seqNo but fewer hops, OR                        │
│  └─ (v)   m_enableEccAodv AND eccBetterScore=true ✅          │
│                                                                  │
│  ▶ FINAL RREP ACK (if required):                              │
│    if (rrepHeader.GetAckRequired()):                           │
│    └─ SendReplyAck(sender)  [LINE 1931]                       │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Code References:**
- `RecvReply()` at line 1841
- Increment hopCount: line 1858
- CC-AODV counter: lines 1859-1862
- ECC-AODV counter: lines 1864-1867
- ECC-AODV average update: lines 1870-1873
- Score calculation: line 1878
- Best score comparison: lines 1879-1883
- Route update condition (v): line 1926
- `computeRrepScore()` at line 419

---

## Summary: What Changed & Why

| Component | Before | After | Reason |
|-----------|--------|-------|--------|
| **SetCongestionFlag in SendReply** | Only if CC-AODV | If CC or ECC-AODV | ECC-AODV needs flag for counter feedback |
| **SetCongestionFlag in SendReplyByIntermediateNode** | Only if CC-AODV | If CC or ECC-AODV | Same reason |
| **Counter increment in RecvReply (ECC)** | Never | On flag==1 | ECC must track path reuse across flows |
| **Congestion level calculation** | Only queue+drops | Queue+counter+drops | Counter now reflects multi-flow impact |
| **Metrics at intermediate nodes** | Not applicable | Pass-through only | Source sees only destination metrics |

---

## Key Design Insights

### Why Congestion Flag is Always 1 (Not Conditional)

```cpp
if (m_enableCcAodv || m_enableEccAodv)
{
    SetCongestionFlag(1);  // Always set, never conditional on actual congestion
}
```

**This is CORRECT by design:**
- The flag doesn't mean "I'm congested" - it means "I'm part of a CC/ECC-AODV network"
- It's a signal to receiving nodes: "Please increment your counter (I'm a valid path)"
- Without the flag, intermediate nodes don't know if they should count this RREP
- Conditional flag would require additional state checking and break the protocol

### Why Intermediate Nodes Don't Modify Metrics

```
Path: Src → [Node A: local state] → [Node B: local state] → [Dst: local state]
                        ↓                      ↓                      ↓
                    Queue=50%                Queue=20%             Queue=10%
                    Drops=30                 Drops=5                Drops=0
                    CL=0.6                   CL=0.3                CL=0.1
                      ↓
              Sends RREP with Dst's CL=0.1 (not Node A's 0.6)
                      ↓
              Node B receives RREP with CL=0.1
              (Does NOT overwrite with Node B's 0.3)
                      ↓
              Source receives path with CL=0.1 (destination's value only)
              This means: "Destination is lightly congested"
              But Source doesn't know about Node A's 0.6 or Node B's 0.3!
```

**This is a design choice (not necessarily optimal):**
- ✅ Simple to implement (single uint8_t field)
- ✅ No accumulation errors
- ❌ Misses intermediate congestion (design gap you identified)
- ❌ Only destination's state matters for scoring

---

## Counter Lifecycle (Both CC & ECC)

```
Initialization: m_congestionCounter = 0

Event: RREP received (flag==1)
  → m_congestionCounter++

Event: Every 1 second
  → CongestionCounterDecayTimerExpire()
  → if (m_congestionCounter > 0) m_congestionCounter--

Event: Link breaks to next hop
  → SendErrWhenBreaksLinkToNextHop()
  → --m_congestionCounter

Result: Counter naturally decays as flows complete
        (Exponential decay with 1-second time constant)
```

---

## Testing the Fix

After these changes, ECC-AODV will now:
1. ✅ Set CongestionFlag=1 in RREP (triggers counter feedback)
2. ✅ Increment counter on each RREP received
3. ✅ Counter reflects multi-flow activity on node
4. ✅ Congestion level = 30% queue + 40% counter feedback + 30% drop rate
5. ✅ Source can distinguish between single-flow and multi-flow paths

---

**Last Verified:** March 18, 2026 03:47 UTC  
**All Code References:** aodv-routing-protocol.cc lines verified  
**Status:** ✅ READY FOR TESTING

---

## LATEST CORRECTION & CLARIFICATION (March 18, 2026)

### Part A: RREP Responders & Metrics

**Who creates RREPs?**
- Either destination (when RREQ reaches it) via `SendReply()`
- OR intermediate node with valid cached route via `SendReplyByIntermediateNode()`

**Key Code:**
- Line 1607 in RecvRequest(): `if (!rreqHeader.GetDestinationOnly() && toDst.GetFlag() == VALID)`
- If true → Intermediate replies immediately
- If false (DestinationOnly=true) → Only destination can reply

**Metrics Ownership:**
```
RREP CL/HQ = Responder's LOCAL STATE at creation time

E.g.:
  If E creates RREP:
    CL = E's congestion level
    HQ = E's queue quality
    
  If D (intermediate) creates RREP:
    CL = D's congestion level
    HQ = D's queue quality
    
  NOT some average, NOT from destination
```

### Part B: RREP Pass-Through (Forwarders DO NOT Overwrite)

**At each forwarding node during RecvReply() [Line 1841+]:**

```cpp
// What happens:
hopCount++;                    // ✅ INCREMENT hopCount
m_congestionCounter++;         // ✅ INCREMENT local counter (flag feedback)

// What does NOT happen:
// ✗ SetCongestionLevel(...);  // NOT called - CL stays unchanged
// ✗ SetHopQuality(...);       // NOT called - HQ stays unchanged
```

**Verification:**
- Search aodv-routing-protocol.cc for "SetCongestionLevel" → only in SendReply/SendReplyByIntermediateNode
- Search for "SetHopQuality" → only in SendReply/SendReplyByIntermediateNode
- NOT in RecvReply() → Forwarders never modify these fields

---

### EXAMPLE 1: Realistic A→D Topology with Cached Intermediate

**Network Setup:**
```
         A (source, initiates RREQ for D)
        / \
       B   E (HAS cached route to D)
      /     \
     C       F
      \     /
       \ D /  (destination)
```

**Conditions:**
- DestinationOnly = false (allows E to reply from cache)
- E's cached route to D is VALID (sequenceNo checks pass)
- E is 2 hops away from D via F

**STEP 1: A sends RREQ for D**
- `rreqHeader.SetDestinationOnly(false)` ✅

**STEP 2: B receives RREQ**
- B has no cached route to D → forwards RREQ

**STEP 3: C receives RREQ**
- C has no cached route to D → forwards RREQ

**STEP 4: E receives RREQ (parallel path)**
- E has cached route to D: E → F → D (2 hops)
- Cache is VALID ✅
- DestinationOnly check passes ✅
- E calls `SendReplyByIntermediateNode()` [Line 1722+]

**E measures LOCAL state at RREP creation:**
```
Queue size:         60 packets
Queue capacity:     100 packets
Queue ratio:        60% full

m_congestionCounter: 1
Adaptive threshold:  4
Counter ratio:       1/4 = 0.25

Recent drop rate:    2% (1 dropped / 50 forwarded)

Congestion level = 0.3×0.6 + 0.4×0.25 + 0.3×0.02
                 = 0.18 + 0.10 + 0.006
                 = 0.286

Map to CL: 0.286 < 0.3 → clLevel = 0  (light)
Queue HQ: (1 - 0.6) × 15 = 6
```

**E creates RREP:**
```
hopCount = 2 (cached route E→F→D = 2 hops)
CongestionLevel = 0
HopQuality = 6
CongestionFlag = 1
```

**STEP 5: F forwards E's RREP back to A**
- F receives RREP: hopCount=2, CL=0, HQ=6, flag=1
- F increments hopCount: 2+1=3
- F increments counter: flag==1 → counter++
- **F does NOT modify CL or HQ** ✅
- F forwards: hopCount=3, CL=0, HQ=6, flag=1

**STEP 6: D receives RREQ (finally)**
- D is destination → calls `SendReply()`

**D measures LOCAL state at RREP creation:**
```
Queue size:         85 packets
Queue capacity:     100 packets
Queue ratio:        85% full

m_congestionCounter: 2 (was incremented by earlier RREPs)
Adaptive threshold:  4
Counter ratio:       2/4 = 0.5

Recent drop rate:    5% (5 dropped / 100 forwarded)

Congestion level = 0.3×0.85 + 0.4×0.5 + 0.3×0.05
                 = 0.255 + 0.20 + 0.015
                 = 0.47

Map to CL: 0.47 ≥ 0.3 and < 0.5 → clLevel = 1 (moderate)
Queue HQ: (1 - 0.85) × 15 = 2
```

**D creates RREP:**
```
hopCount = 0 (destination)
CongestionLevel = 1
HopQuality = 2
CongestionFlag = 1
```

**STEP 7: C forwards D's RREP back**
- C receives: hopCount=0, CL=1, HQ=2, flag=1
- C increments hopCount: 0+1=1
- C increments counter: flag==1 → counter++
- **C does NOT modify CL or HQ** ✅
- C forwards: hopCount=1, CL=1, HQ=2, flag=1

**STEP 8: B forwards D's RREP back**
- B receives: hopCount=1, CL=1, HQ=2, flag=1
- B increments hopCount: 1+1=2
- B increments counter: flag==1 → counter++
- **B does NOT modify CL or HQ** ✅
- B forwards: hopCount=2, CL=1, HQ=2, flag=1

**STEP 9: A receives BOTH RREPs**

**RREP #1 from E (earlier arrival, typically):**
- hopCount = 3 (E→F→A takes 1 more hop due to receiving at A)
- CL = 0 (E's local state)
- HQ = 6 (E's queue quality)
- Responder = E

**RREP #2 from D (later arrival, longer path):**
- hopCount = 3 (D→C→B→A takes 3 hops)
- CL = 1 (D's local state)
- HQ = 2 (D's queue quality)
- Responder = D

**STEP 10: A scores both RREP candidates (MMPS)**

**Score formula:** `score = 0.3/hops + 0.4*(HQ/15) + 0.3/(CL+1)`

**Score for E's RREP:**
```
score_E = 0.3/3 + 0.4*(6/15) + 0.3/(0+1)
        = 0.1 + 0.4×0.4 + 0.3
        = 0.1 + 0.16 + 0.3
        = 0.56
```

**Score for D's RREP:**
```
score_D = 0.3/3 + 0.4*(2/15) + 0.3/(1+1)
        = 0.1 + 0.4×0.1333 + 0.15
        = 0.1 + 0.0533 + 0.15
        = 0.3033
```

**STEP 11: A's Route Update Decision (ECC-AODV)**

```
score_E (0.56) > score_D (0.3033) ✅

if (m_enableEccAodv)
    shouldUpdate = eccBetterScore;  // Line 1919
    eccBetterScore = (0.56 > previous_best_score)

Route update = YES (pick E's path)
Next hop toward D = sender of winning RREP
                  = B (on path A→E→F→D, first hop is B)
```

**FINAL ROUTING TABLE:**
```
Dest: D
Next hop: B
Path: A → B → E → F → D (4 hops total)
Via cached intermediate E (faster than waiting for destination)
```

---

### EXAMPLE 2: Edge Case - Intermediate Blocked (DestinationOnly=true)

**Same topology, but with DestinationOnly=true:**

**STEP 4B: E receives RREQ**
- E has cached route to D (valid)
- BUT: `rreqHeader.GetDestinationOnly() == true` ✅ SET
- Condition fails: `if (!rreqHeader.GetDestinationOnly() && ...)`
- **E CANNOT reply from cache** → forwards RREQ instead

**STEP 6: D receives RREQ (now ONLY responder)**
- D creates RREP as before
- CL = 1, HQ = 2

**STEP 9: A receives ONLY D's RREP**
- E's cached path never considered
- A must use destination's path (longer)

**MMPS benefit LOST** ❌

---

### EXAMPLE 3: Key Insight - Why Intermediate CL/HQ Matter

**Compare E and D metrics directly:**

E (light congestion):
```
CL = 0 → less congested
HQ = 6 → moderate queue occupancy
```

D (moderate congestion):
```
CL = 1 → more congested
HQ = 2 → queue near full
```

**If forwarders MODIFIED these metrics:**
- Both paths would report identical metrics (lost information)
- MMPS scoring impossible
- Can't distinguish good routes from bad

**Because forwarders DON'T modify:**
- Source sees each responder's actual state
- MMPS can distinguish E (light) from D (moderate)
- Better route selected ✅

---

### MMPS Route-Update Priority (Code Fix Applied)

**Line 1919-1927 in aodv-routing-protocol.cc:**

```cpp
if (m_enableEccAodv)
{
    shouldUpdate = eccBetterScore;  // MMPS priority ONLY ✅
    if (shouldUpdate)
    {
        NS_LOG_DEBUG("ECC-AODV MMPS: Updating route due to better score");
    }
}
else
{
    // Standard AODV conditions (i, ii, iii, iv, v)
    shouldUpdate = (condition_i || condition_ii || ... || condition_v);
}
```

**Effect:**
- ECC mode: Route update ONLY if new score is better
- Non-ECC mode: Legacy AODV conditions apply
- No mixing of AODV and MMPS logic ✅
