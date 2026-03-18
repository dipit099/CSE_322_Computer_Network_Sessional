# CC-AODV Reconfirmation vs Base Paper

## Reconfirmation Result

CC-AODV core logic is implemented correctly in this codebase.

## Code Evidence (ns-3 AODV)

- `src/aodv/model/aodv-routing-protocol.cc:343` - `EnableCcAodv` attribute
- `src/aodv/model/aodv-routing-protocol.cc:348` - `BaseThreshold` attribute
- `src/aodv/model/aodv-routing-protocol.cc:1475` - RREQ admission/drop path when CC-AODV congestion condition is met
- `src/aodv/model/aodv-routing-protocol.cc:1682` and `:1737` - Congestion flag set on RREP
- `src/aodv/model/aodv-routing-protocol.cc:1853` and `:1855` - Congestion counter increment on RREP congestion flag
- `src/aodv/model/aodv-routing-protocol.cc:432` to `:443` - Congestion counter decay timer handler (`m_congestionCounter--` every 1 second and reschedule)
- `src/aodv/model/aodv-routing-protocol.cc:520` and `:521` - Decay timer initialization/schedule in startup

## Why paper vs local metrics can differ

- Different mobility, seeds, offered load, radio/channel models, and queue settings.
- Implementation can be correct while absolute values differ from paper plots.
- Relative trends are more meaningful than exact absolute matching.

## Practical conclusion

- Implementation-level CC-AODV behavior (flagging, countering, thresholding, decay) is present and wired correctly.
- Metric discrepancy is most likely due to scenario/parameter mismatch, not a missing CC-AODV mechanism.
