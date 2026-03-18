# ECC-AODV Architecture & Decay Timer Flowchart

## Flowchart 1: Complete CC-AODV & ECC-AODV Signal Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CONGESTION SIGNAL PROPAGATION                         │
│                     (How Congestion Info Travels Source→Dest)               │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ 1. ROUTE DISCOVERY (RREQ → RREP)                                             │
└──────────────────────────────────────────────────────────────────────────────┘

    Source A                Intermediate B,C              Destination E
    ========                ==============                =============

    [1] Broadcast RREQ
        congestionFlag = 0
        (no congestion yet)
                    │
                    ├──> [2] Rebroadcast
                    │        (pass through)
                    │
                    └──────────────────────> [3] E receives RREQ
                                                 │
                                                 ├─ Check local metrics:
                                                 │  • Queue: 80% full
                                                 │  • Counter: 3
                                                 │  • CL = 0.35 (QACD)
                                                 │
                                                 ├─ Congested! Set:
                                                 │  congestionFlag = 1 (binary)
                                                 │  eccInfo.CL = 2 (packed, ECC-only)
                                                 │  eccInfo.HQ = 3 (packed, ECC-only)
                                                 │
                                                 ├─ [4] Generate RREP
                                                 │  (with congestion markings)
                                                 └─>

    [5] C forwards RREP
        ├─ Reads congestionFlag = 1
        ├─ m_congestionCounter++ (now 2)
        ├─ Measures own state:
        │  • Queue: 40% full
        │  • Local CL = 0.2
        ├─ ECC-mode: Update OPHD
        │  eccInfo.CL = 1
        │  eccInfo.HQ = 10
        └─> Forward RREP
                    │
    [6] B forwards RREP
        ├─ Reads congestionFlag = 1
        ├─ m_congestionCounter++ (now 1)
        ├─ Measures own state:
        │  • Queue: 5% full (nearly empty)
        │  • Local CL = 0.05
        ├─ ECC-mode: Update OPHD
        │  eccInfo.CL = 0
        │  eccInfo.HQ = 14
        └─> Forward RREP
                    │
    [7] A receives RREP
        ├─ Reads congestionFlag = 1 ◄─── CRITICAL FOR CC-AODV
        ├─ m_congestionCounter++ (now 1)
        │
        ├─ CC-AODV logic:
        │  └─ Counter = 1, Threshold = 4
        │     → Not congested yet (1 ≤ 4)
        │
        └─ ECC-AODV logic (if enabled):
           ├─ Computes score for this RREP
           │  Score = 0.3*(1/3) + 0.4*(14/15) + 0.3*(1/0+1)
           │        = 0.1 + 0.37 + 0.3 = 0.77 (excellent)
           │
           └─ If previous RREPs existed:
              └─ Keeps highest-score route (MMPS)

┌──────────────────────────────────────────────────────────────────────────────┐
│ 2. DECAY TIMER OPERATION (CRITICAL FIX)                                      │
└──────────────────────────────────────────────────────────────────────────────┘

    Time ─────────────────────────────────────────────────────────────

    A's counter:
    ─────────────
    t=0.0s:   Counter = 0 (init)
              ↓ (RREP arrives with flag=1)
    t=0.5s:   Counter = 1 ◄─── +1 from RREP
              │
              │ (1-second timer fires)
              ↓
    t=1.0s:   Counter = 0 ◄─── -1 from decay timer ✓✓✓
              │
              │ (More RREPs arrive)
              ↓
    t=1.5s:   Counter = 1 (+1)
    t=2.0s:   Counter = 0 (-1 decay)
    t=2.5s:   Counter = 2 (+1 twice)
    t=3.0s:   Counter = 1 (-1 decay)
    ...

    WITHOUT DECAY TIMER (BROKEN):
    ──────────────────────────────
    t=0.5s:   Counter = 1 ◄─── +1 from RREP
    t=1.0s:   Counter = 1 (still 1, no decay!)
    t=1.5s:   Counter = 2 (+1)
    t=2.0s:   Counter = 2 (still 2!)
    t=30.0s:  Counter = 2 (STUCK at 2 forever)
              ↓
              Network thinks permanently congested
              RREQ drops never stop
              CC-AODV broken ✗✗✗

┌──────────────────────────────────────────────────────────────────────────────┐
│ 3. RREQ ADMISSION CONTROL (CONGESTION GATE)                                  │
└──────────────────────────────────────────────────────────────────────────────┘

    When a new RREQ arrives at node B:

        ┌─────────────────────────────────────────┐
        │ Read RREQ destination                   │
        │ Check if route already exists            │
        └─────────────────────┬───────────────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
            ┌───────▼──────────┐    ┌──▼───────────────┐
            │ ECC-AODV         │    │ CC-AODV only     │
            │ mode = true?     │    │ mode = true?     │
            └──────┬────────────┘    └──┬───────────────┘
                   │                     │
           ┌───────▼─────────────┐   ┌──▼─────────────────────┐
           │ Compute CL:         │   │ Check threshold:       │
           │ CL = w1*Q + w2*C +  │   │ if counter > 4:        │
           │     w3*DropRate     │   │     DROP RREQ ✓        │
           │                     │   │ else:                  │
           │ if CL >= 0.7:       │   │     FORWARD RREQ ✓     │
           │     DROP RREQ ✓     │   └────────────────────────┘
           │ else:               │
           │     FORWARD RREQ ✓  │
           └─────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ 4. ENHANCED PATH SCORING (ECC MMPS)                                          │
└──────────────────────────────────────────────────────────────────────────────┘

    When multiple RREPs arrive for same destination:

        RREP 1 (Path via B):
        ├─ HopCount = 3
        ├─ HopQuality (from OPHD) = 14
        ├─ CongestionLevel (from OPHD) = 0
        ├─ Score = 0.3*(1/3) + 0.4*(14/15) + 0.3*(1/0+1)
        │        = 0.1 + 0.37 + 0.3 = 0.77 ◄─── BEST
        └─ Select this route ✓

        RREP 2 (Path via C):
        ├─ HopCount = 4
        ├─ HopQuality = 8
        ├─ CongestionLevel = 2
        ├─ Score = 0.3*(1/4) + 0.4*(8/15) + 0.3*(1/2+1)
        │        = 0.075 + 0.213 + 0.1 = 0.388 ◄─── WORSE
        └─ Skip ✗

        CC-AODV (binary flag only):
        └─ Both have congestionFlag = 1
           No way to differentiate
           Might pick wrong path ✗

┌──────────────────────────────────────────────────────────────────────────────┐
│ 5. NETWORK ADAPTATION LOOP (FEEDBACK CONTROL)                                │
└──────────────────────────────────────────────────────────────────────────────┘

    WITH DECAY TIMER (self-regulating):
    ───────────────────────────────────

    High traffic → congestion detected → RREPs flagged → counters up
         ↑                                                     ↓
         │                                            RREQ drops increase
         │                                                     ↓
         │                                   Traffic reduces (fewer route req)
         │                                                     ↓
         │                                         Less load on network
         │                                                     ↓
         │                             Counters decay (every 1 second)
         └──────────────────────────────────────────────────────

    OSCILLATION: Counter oscillates based on recent congestion
                 Frequency = ~1 second (timer granularity)
                 Amplitude = network load dependent


    WITHOUT DECAY TIMER (BROKEN):
    ────────────────────────────

    High traffic → congestion → RREPs flagged → counters up
         ↑                                            ↓
         │                                   STUCK FOREVER!
         │                                   Counters never decrease
         │                                   RREQ drops continue
         │                                            ↓
         └─────────────── Network remains congested ✗

```

---

## Flowchart 2: Timer Mechanism Deep Dive

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    CONGESTION COUNTER DECAY TIMER                         │
│                     (The Critical Fix for CC-AODV)                        │
└──────────────────────────────────────────────────────────────────────────┘

INITIALIZATION (in RoutingProtocol::Start()):
─────────────────────────────────────────────

    m_congestionCounterDecayTimer.SetFunction(
        &RoutingProtocol::CongestionCounterDecayTimerExpire, this);
    
    m_congestionCounterDecayTimer.Schedule(Seconds(1));
    
    ↓
    
    Timer registered and scheduled for first expiration


PERIODIC EXECUTION (every 1 second):
─────────────────────────────────────

    t = 0.0s: Start() called
              Timer armed
              ↓
    
    t = 1.0s: Timer fires!
              ┌─────────────────────────────────────┐
              │ CongestionCounterDecayTimerExpire() │
              │ {                                   │
              │   if (counter > 0)                  │
              │       counter--;                    │
              │   Schedule next in 1 second         │
              │ }                                   │
              └─────────────────────────────────────┘
              ↓
              Counter decreased by 1
              Timer rescheduled
    
    t = 2.0s: Timer fires again
              counter--
              Reschedule
              ↓
    
    t = 3.0s: Timer fires again
              counter--
              Reschedule
              ↓
    
    ... continues every 1 second until protocol stops


INTERACTION WITH RREP PROCESSING:
─────────────────────────────────

    TIMELINE:
    ────────
    
    t = 0.5s:  ┌──────────────────────────┐
               │ RREP arrives with flag=1 │
               │ In RecvReply():          │
               │   counter++              │  (counter: 0 → 1)
               └──────────────┬───────────┘
                              │
    t = 1.0s:                 │  ┌──────────────────────────────┐
                              │  │ Timer fires!                 │
                              │  │ CongestionCounterDecayTimer()│
                              │  │   counter--                  │  (counter: 1 → 0)
                              │  │   Schedule(Seconds(1))       │
                              └──┤  Reschedule for t=2.0s       │
                                 └──────────────┬───────────────┘
                                                │
    t = 1.5s:  ┌──────────────────────────┐    │
               │ More RREPs arrive        │    │
               │ In RecvReply():          │    │
               │   counter++              │    │  (counter: 0 → 1)
               │   counter++              │    │  (counter: 1 → 2)
               └──────────────┬───────────┘    │
                              │                │
    t = 2.0s:                 │  ┌──────────────▼───────────────┐
                              │  │ Timer fires!                 │
                              │  │   counter--                  │  (counter: 2 → 1)
                              └──┤   Schedule(Seconds(1))       │
                                 └──────────────┬───────────────┘
                                                │
    t = 3.0s:                     ┌─────────────▼────────────────┐
                                  │ Timer fires!                 │
                                  │   counter--                  │  (counter: 1 → 0)
                                  │   Schedule(Seconds(1))       │
                                  └──────────────────────────────┘


IMPACT ON RREQ ADMISSION:
────────────────────────

    Time        Counter    Threshold    is_Congested?   RREQ Action
    ────        ───────    ─────────    ─────────────   ───────────
    t=0.5s      1          4            NO              FORWARD ✓
    t=1.0s      0          4            NO              FORWARD ✓
    t=1.5s      2          4            NO              FORWARD ✓
    t=2.0s      1          4            NO              FORWARD ✓
    t=2.5s      4          4            NO (=, not >)   FORWARD ✓
    t=3.0s      3          4            NO              FORWARD ✓
    t=3.5s      5          4            YES             DROP ✗
    t=4.0s      4          4            NO              FORWARD ✓
    t=4.5s      5          4            YES             DROP ✗
    t=5.0s      4          4            NO              FORWARD ✓


SUMMARY:
────────

    ✓ Counter oscillates: increases on RREP, decreases every 1s
    ✓ Provides adaptive feedback: high load → drops, low load → forwards
    ✓ Self-regulating: network stabilizes around threshold
    ✗ Without decay: counter accumulates forever → CC-AODV broken
```

---

## Flowchart 3: Configuration Wiring (AODV vs CC-AODV vs ECC-AODV)

```
┌────────────────────────────────────────────────────────────────────────┐
│            MODE CONFIGURATION & FEATURE ACTIVATION                     │
│         (How AODV / CC-AODV / ECC-AODV differ)                        │
└────────────────────────────────────────────────────────────────────────┘

    CONFIGURATION SETUP (in simulator or ns-3 attributes):
    ────────────────────────────────────────────────────

        Mode = "aodv"
        ├─ m_enableCcAodv = false
        ├─ m_enableEccAodv = false
        ├─ No decay timer active
        ├─ No counter tracking
        └─ Pure RFC 3561 AODV ✓

        Mode = "cc-aodv"
        ├─ m_enableCcAodv = true  ◄─── ONLY THIS ENABLED
        ├─ m_enableEccAodv = false
        ├─ Decay timer ACTIVE
        ├─ Counter tracks congestion
        ├─ RREQ dropped if counter > threshold
        ├─ No QACD, no MMPS
        └─ Base CC-AODV (paper design) ✓

        Mode = "ecc-aodv"
        ├─ m_enableCcAodv = true   ◄─── BASE CC REQUIRED
        ├─ m_enableEccAodv = true  ◄─── EXTENSIONS ADDED
        ├─ Decay timer ACTIVE
        ├─ + ATM (adaptive threshold)
        ├─ + QACD (congestion level computation)
        ├─ + OPHD (packed RREP fields)
        ├─ + MMPS (path scoring)
        └─ Full ECC-AODV ✓


    FEATURE GATE MAP:
    ────────────────

    Feature                 Gate Expression              Impact
    ───────                 ───────────────              ──────
    Counter increment       m_enableCcAodv              ✓ CC & ECC only
    Decay timer             m_enableCcAodv              ✓ CC & ECC only
    RREQ admission gate     m_enableCcAodv || EccMode  ✓ CC & ECC only
    Adaptive threshold      m_enableEccAodv             ✓ ECC only
    CL computation          m_enableEccAodv             ✓ ECC only
    OPHD packing            m_enableEccAodv             ✓ ECC only
    MMPS path scoring       m_enableEccAodv             ✓ ECC only


    DECISION FLOW AT EACH RREQ RECEPTION:
    ─────────────────────────────────────

        RREQ arrives
        │
        ├─ Duplicate check (standard AODV)
        │
        ├─ Check congestion gate:
        │  │
        │  ├─ ECC-AODV (ecc=true):
        │  │  ├─ Compute CL = w1*Q + w2*C + w3*D
        │  │  ├─ if CL ≥ 0.7:
        │  │  │  └─ DROP ✗
        │  │  └─ if CL < 0.7:
        │  │     └─ FORWARD ✓
        │  │
        │  └─ CC-AODV (cc=true, ecc=false):
        │     ├─ if counter > m_baseThreshold:
        │     │  └─ DROP ✗
        │     └─ if counter ≤ m_baseThreshold:
        │        └─ FORWARD ✓
        │
        └─ Forward to routing (standard AODV) ✓


    RREP PROCESSING FLOW:
    ─────────────────────

        RREP arrives
        │
        ├─ Update reverse route (standard AODV)
        │
        ├─ Check congestion flag:
        │  │
        │  └─ If flag=1 AND m_enableCcAodv:
        │     ├─ counter++  ◄─── INCREMENT (CC & ECC)
        │     │
        │     └─ If m_enableEccAodv:
        │        ├─ Update m_avgNeighborCounter  ◄─── ATM
        │        ├─ Fill OPHD fields (CL, HQ)   ◄─── OPHD
        │        └─ (Other path will use MMPS to select)
        │
        └─ Create forward route (standard AODV) ✓


    TIMER-BASED DECAY:
    ──────────────────

        Every 1 second (if m_enableCcAodv):
        │
        ├─ CongestionCounterDecayTimerExpire()
        │  │
        │  ├─ if counter > 0:
        │  │  └─ counter--
        │  │
        │  └─ Schedule next timer
        │
        └─ Repeat ✓
```

---

## Key Takeaways

**The Decay Timer is Essential:**
- Without it: Counter accumulates forever → CC-AODV broken
- With it: Counter oscillates → adaptive congestion control

**Configuration Matters:**
- AODV: no CC features, pure baseline
- CC-AODV: binary flag + counter + decay timer
- ECC-AODV: all CC features + QACD + MMPS scoring

**Signal Flow:**
- Destination detects congestion → sets flag on RREP
- Intermediate nodes read flag → increment counters
- Decay timer decreases counters every 1 second
- RREQ admission gate uses counter/CL to drop RREQs
- Result: self-regulating network → balanced load

