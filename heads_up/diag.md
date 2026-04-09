# ECC-AODV: Complete Reference with DestinationOnly Flag & RREP Pass-Through

## Section 1: RREP Responder Identity

```
QUESTION: WHO CREATES AN RREP?

Two types of RREP creators (responders):

┌─────────────────────────────────────────────────────────────────┐
│ CASE A: Destination Responder                                   │
│ ─────────────────────────────────────────────────────────────────│
│ Condition: RREQ.dst == my address                              │
│ Code path: RecvRequest() → IsMyOwnAddress(dst) == true         │
│            → SendReply(rreqHeader, toOrigin)   [Line 1666]      │
│ Creates RREP with:                                             │
│   ├─ hopCount = 0 (destination is 0 hops away)                │
│   ├─ CongestionLevel = dest's local m_congestionLevel          │
│   ├─ HopQuality = (1 - dest_queue_ratio) × 15                 │
│   └─ CongestionFlag = 1 (enable counter feedback)             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ CASE B: Intermediate Responder (With Cached Route)             │
│ ─────────────────────────────────────────────────────────────────│
│ Conditions: ALL must be true                                   │
│   ├─ LookupRoute(dst, toDst) == true ✅                       │
│   ├─ toDst.GetValidSeqNo() == true ✅                         │
│   ├─ toDst.GetFlag() == VALID ✅                              │
│   ├─ SeqNo condition satisfied ✅                              │
│   └─ !rreqHeader.GetDestinationOnly() ✅ KEY                  │
│                                                                 │
│ Code path: RecvRequest() [Line 1607]                           │
│ if (!rreqHeader.GetDestinationOnly() && toDst.GetFlag()...) {│
│     SendReplyByIntermediateNode(toDst, toOrigin, ...)          │
│     return;  // Reply sent, don't forward RREQ                │
│ }                                                              │
│                                                                 │
│ Creates RREP with:                                             │
│   ├─ hopCount = toDst.hopCount (cached distance to dst)        │
│   ├─ CongestionLevel = intermediate's local m_congestionLevel  │
│   ├─ HopQuality = (1 - intermediate_queue_ratio) × 15          │
│   └─ CongestionFlag = 1                                        │
│                                                                 │
│ ADVANTAGE: Source gets early reply + multiple candidates!     │
└─────────────────────────────────────────────────────────────────┘

KEY: Responder = node that CREATED that RREP
     CL/HQ = Responder's LOCAL STATE (not from destination always!)
```

---

## Section 2: DestinationOnly Flag (CRITICAL FOR ECC-AODV)

```
WHERE: In RREQ header [aodv-packet.h]

┌──────────────────────────────────────────────────────────────────┐
│ RECOMMENDED: DestinationOnly = false (DEFAULT) ✅                │
├──────────────────────────────────────────────────────────────────┤
│ Set by source in SendRequest():                                  │
│   if (m_destinationOnly) {  ← Check this member variable        │
│       rreqHeader.SetDestinationOnly(true);                      │
│   }                                                              │
│   // If m_destinationOnly=false, flag defaults to false ✅      │
│                                                                  │
│ Intermediate processing at Line 1607:                           │
│   if (!rreqHeader.GetDestinationOnly() &&  ← FALSE check        │
│       toDst.GetFlag() == VALID) {                               │
│       SendReplyByIntermediateNode(...);  ← CALLED ✅            │
│       return;  ← Don't forward RREQ                             │
│   }                                                              │
│                                                                  │
│ RESULT:                                                          │
│   ✅ Intermediates CAN reply from cache                         │
│   ✅ Multiple RREP candidates reach source                      │
│   ✅ ECC-AODV MMPS can score each candidate                     │
│   ✅ Best multi-hop path selected                               │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ NOT RECOMMENDED: DestinationOnly = true (BLOCKS INTERMEDIATES)  │
├──────────────────────────────────────────────────────────────────┤
│ Set by source:                                                   │
│   rreqHeader.SetDestinationOnly(true);                          │
│                                                                  │
│ Intermediate processing at Line 1607:                           │
│   if (!rreqHeader.GetDestinationOnly() &&  ← TRUE check fails   │
│       toDst.GetFlag() == VALID) {                               │
│       // CONDITION FALSE, so NOT entered                        │
│       // SendReplyByIntermediateNode() NOT called ❌            │
│   }                                                              │
│   // Continue: forward RREQ instead of replying                │
│                                                                  │
│ RESULT:                                                          │
│   ❌ RREQ always reaches destination (slower)                   │
│   ❌ Only one RREP candidate (destination only)                 │
│   ❌ MMPS cannot optimize (no choice)                           │
│   ❌ Intermediate's good routes never used                      │
└──────────────────────────────────────────────────────────────────┘

DECISION: For ECC-AODV, use DEFAULT (DestinationOnly = false)
```

---

## Section 3: Forward Phase (RREQ Broadcast with Congestion Gating)

```
RREQ PROPAGATES THROUGH NETWORK

                          A (source)
                          │
                   broadcast RREQ
                   DestinationOnly=false ✅
                   hopCount=0
                          │
           ┌──────────────┼──────────────┐
           │              │              │
           v              v              v
          B              C              E (has cache!)
      RecvRequest()  RecvRequest()  RecvRequest()
           │              │              │
        Checks:        Checks:        Checks:
        ├─Dupe? NO    ├─Dupe? NO    ├─Dupe? NO
        ├─ECC gate?   ├─ECC gate?   ├─ECC gate?
        │ CL=0.3      │ CL=0.2      │ CL=0.6
        │ PASS ✅     │ PASS ✅     │ PASS ✅
        │             │             │
        ├─Cache? NO   ├─Cache? NO   ├─Cache? YES ✅
        ├─Forward     ├─Forward     ├─Valid? YES ✅
        │  RREQ       │  RREQ       ├─!DestOnly? YES ✅
        │             │             │
        v             v             └─ SendReplyByIntermediateNode()
        D          (D also gets it)    RREP sent back to A!
    RecvRequest()      │               hop=2, CL=0.6, HQ=5
      │                │               (no more RREQ forwarding)
      ├─Dupe of C      │
      │ NO            v
      ├─ECC gate?    RecvRequest()
      │ PASS ✅     (D is destination)
      │             │
      ├─Cache? NO   └─ SendReply()
      ├─Forward      RREP sent back to A!
      │  RREQ        hop=0, CL=0.2, HQ=12
      │
      v (to D)
     D (reached)
      │
      └─ Also creates SendReply() RREP

RESULT:  A receives TWO RREP candidates:
         ├─ From E (intermediate):  hop=2, CL=0.6, HQ=5
         └─ From D (destination):   hop=0, CL=0.2, HQ=12
         (Can compare and score!)
```

---

## Section 4: RREP Forwarding (Forward Phase for RREP Packets)

```
RREP TRAVELS BACK TO SOURCE

At E (responder, right after creation):
  ┌──────────────────────────────────┐
  │ RREP packet:                     │
  │ hopCount = 2 (to D via F)        │
  │ CL = 0.6 (E's metric)            │
  │ HQ = 5 (E's queue quality)       │
  │ flag = 1 (counter feedback on)   │
  │ Sender = E                       │
  └──────────────────────────────────┘
              │ sent to F
              v
At F (forwarding intermediate):
  RecvReply() processing [Line 1841]:
      hop_old = 2
      hop_new = 2 + 1 = 3  ✅ INCREMENTED
      
      ✗ SetCongestionLevel(...) NOT called
      ✗ SetHopQuality(...) NOT called
      
      if (flag==1) {
          m_congestionCounter++  ✅ Counter incremented
      }
      
      Forward packet...
  
  ┌──────────────────────────────────┐
  │ RREP packet (after F):           │
  │ hopCount = 3 ✅ CHANGED          │
  │ CL = 0.6 ✅ UNCHANGED (E's)     │
  │ HQ = 5 ✅ UNCHANGED (E's)       │
  │ flag = 1 ✅ UNCHANGED            │
  │ Sender = F (UDP layer)           │
  └──────────────────────────────────┘
              │ sent to A
              v
At A (source, upon reception):
  RecvReply() processing:
      hop_old = 3
      hop_new = 3 + 1 = 4  ✅ Incremented by receiver
      
      CL = 0.6 ✅ INTACT from E
      HQ = 5 ✅ INTACT from E
      
      Score_E = 0.3/4 + 0.4*(5/15) + 0.3/(0.6+1)
              = 0.075 + 0.1333 + 0.1875
              = 0.396

SIMULTANEOUSLY from D (destination):
  At D (responder, right after creation):
    hopCount = 0 (destination)
    CL = 0.2 (D's metric)
    HQ = 12 (D's queue quality)
    flag = 1
              │
    (travels D → C → B → A)
              │
  At C, B (forwarders):
    hopCount increments by 1 each
    ✗ CL NOT modified (stays 0.2)
    ✗ HQ NOT modified (stays 12)
    counter++ each
              │
  At A (source, upon reception):
    hopCount = 0+1+1+1 = 3  ✅
    CL = 0.2 ✅ INTACT from D
    HQ = 12 ✅ INTACT from D
    
    Score_D = 0.3/3 + 0.4*(12/15) + 0.3/(0.2+1)
            = 0.1 + 0.32 + 0.25
            = 0.67 ✅ HIGHER

COMPARISON (MMPS Route Selection):
  Score_E (0.396) vs Score_D (0.67)
  → 0.67 WINS! ✅
  
  Route update [Line 1919]:
      if (m_enableEccAodv) {
          shouldUpdate = eccBetterScore;  // TRUE
      }
      if (shouldUpdate) {
          m_routingTable.Update(...)
          Use D-originated path!
      }
```

---

## Section 5: Why Forwarders Don't Modify CL/HQ

```
DESIGN PRINCIPLE: Responder Ownership of Metrics

CL/HQ represent responder's state AT CREATION TIME

If forwarders modified:
  ❌ Lost original responder's metrics
  ❌ Accumulated errors from multiple hops
  ❌ MMPS comparison impossible
  ❌ Intermediate nodes' congestion masked

By preserving:
  ✅ Source sees each responder's ACTUAL state
  ✅ MMPS can distinguish good paths from bad
  ✅ Multiple candidates have DIFFERENT scores
  ✅ Path diversity fully exploited

ANALOGY:
  If intermediate modifies CL/HQ,
  then source can't tell:
  "Is this path good because responder has good queue?"
  or "Is this path bad because intermediate is congested?"
  
  Answer: Preserved metrics solve this!
```

---

## Section 6: Complete Flow Diagram

```
SOURCE broadcasts RREQ
    │
    ├─ DestinationOnly=false ✅
    └─ hopCount=0, no metrics yet
    
INTERMEDIATES receive RREQ
    │
    ├─ Gate: ECC_CL≥0.7 or CC_counter>threshold?
    │        DROP if true, FORWARD if false
    │
    └─ If route to dst exists:
       ├─ Check: !DestinationOnly? ✅
       ├─ Check: route VALID? ✅
       └─ SendReplyByIntermediateNode()
          RREP = intermediate's metrics
          Sent back immediately
    
DESTINATION creates RREP (also sends)
    │
    └─ RREP = destination's metrics
    
FORWARDERS (on RREP return)
    │
    ├─ hopCount++  ✅ MODIFIED
    ├─ ✗ CL unchanged (responder's)
    ├─ ✗ HQ unchanged (responder's)
    └─ counter++   ✅ LOCAL feedback
    
SOURCE receives RREPs
    │
    ├─ Multiple candidates (from different responders)
    ├─ Score each using MMPS
    ├─ Compare scores
    └─ Route to highest-score candidate ✅
    
ROUTING TABLE
    │
    └─ Established to best path
       Next hop = sender of winning RREP
```

---

## Section 7: Counter Decay Timer

```
TIMER: m_congestionCounterDecayTimer (Critical Fix)

Purpose: Prevent sticky congestion
         Allow counter to recover when network quiets

Location: CongestionCounterDecayTimerExpire() [Line ~2180]

Operation:
  Every 1.0 second:
  ┌──────────────────────────┐
  │ if (counter > 0) {       │
  │   counter--              │
  │ }                        │
  │ reschedule in 1.0 second │
  └──────────────────────────┘

Example timeline at node B:
  t=0.0s:  counter = 0 (init)
  t=0.5s:  RREP arrives (flag=1) → counter = 1
  t=1.0s:  Decay timer fires → counter = 0
  t=1.5s:  Another RREP → counter = 1
  t=2.0s:  Decay fires → counter = 0
  t=2.5s:  Two RREPs → counter = 2
  t=3.0s:  Decay fires → counter = 1
  
WITHOUT TIMER (BROKEN):
  t=0.0s:  counter = 0
  t=0.5s:  RREP → counter = 1
  t=5.0s:  counter = 1 (NO DECAY!)
  t=10.0s: counter = 1 (still blocking RREQs forever)
  
WITH TIMER (FIXED):
  counter oscillates 0-n based on recent activity
  → CC-AODV admission control works properly ✅
```

---

## Summary: Key Configuration for ECC-AODV

| Setting | Value | Why |
|---------|-------|-----|
| `DestinationOnly` | false (default) | ✅ Allow intermediates to reply from cache |
| `EnableEccAodv` | true | ✅ Enable MMPS scoring |
| `EnableCcAodv` | true | ✅ Enable counter feedback + QACD |
| Decay timer | 1 second | ✅ Counter recovers naturally |

**Result:** ECC-AODV gets full MMPS benefit from multi-path comparison!
