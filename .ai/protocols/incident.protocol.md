# Protocol: Incident Response

## Severity Levels
| Level | Definition | Response Time |
|-------|-----------|---------------|
| P1 - Critical | System down, data loss, security breach | 15 minutes |
| P2 - High | Major feature broken, financial impact | 1 hour |
| P3 - Medium | Minor feature broken, workaround available | 4 hours |
| P4 - Low | Cosmetic issue, enhancement request | Next sprint |

## Steps
1. Issue reported (user, bot alert, or monitoring).
2. OPS-L1 triages and assigns severity.
3. IF P1/P2: Escalate to OPS-L3 and notify CTO immediately.
4. IF P3: Assign to OPS-L2 for investigation.
5. IF P4: Log and prioritize in backlog.
6. Investigator performs root cause analysis.
7. Fix developed and tested.
8. Fix deployed via release.protocol or hotfix.
9. Post-mortem documented in episodic memory.