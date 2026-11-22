# Results Analysis

## 1. Status

**Simulation results have not yet been recorded in this document.**

All numerical results must be taken from the generated simulation
outputs. Statements about performance improvements must be
supported by those results.

## 2. Execution Record

| Item | Recorded value |
|---|---|
| Execution date | To be recorded |
| MATLAB version | To be recorded |
| Operating system | To be recorded |
| Git commit | To be recorded |
| Configuration changes | None, or describe changes |
| Validation test outcome | To be recorded |

## 3. Result Files

The simulation generates:

| File | Purpose |
|---|---|
| `scenario_summary.csv` | Metrics for all 18 scenarios |
| `planning_results.mat` | Configuration, summary, and reference maps |
| `deployment.png` | Site locations and sector orientations |
| `radio_maps.png` | Received power, SINR, association, and coverage |
| `scenario_comparison.png` | Comparisons across planning scenarios |
| `path_loss.png` | Applied propagation model |

The reference maps correspond to:

- Inter-site distance: 750 m
- Three sectors per site
- Frequency reuse factor: 1

These maps illustrate one scenario, not all 18.

## 4. Summary Table

The table below highlights the 750 m scenarios.

Replace each “Pending” value with the matching value from
`results/scenario_summary.csv`.

| Sectors | Reuse | Coverage (%) | Mean SINR (dB) | Mean rate (Mbps) | P5 rate (Mbps) |
|---:|---:|---:|---:|---:|---:|
| 1 | 1 | Pending | Pending | Pending | Pending |
| 1 | 3 | Pending | Pending | Pending | Pending |
| 1 | 7 | Pending | Pending | Pending | Pending |
| 3 | 1 | Pending | Pending | Pending | Pending |
| 3 | 3 | Pending | Pending | Pending | Pending |
| 3 | 7 | Pending | Pending | Pending | Pending |

Report rate values as **idealized rate proxies**, not measured
LTE throughput.

## 5. Inter-Site Distance Analysis

Compare 500, 750, and 1,000 m while holding sector count and
reuse factor constant.

### Questions

- How does coverage percentage change?
- Does mean SINR change substantially?
- What happens to the fifth-percentile rate?
- How much does site density change?

### Interpretation considerations

Larger spacing increases propagation distances.

However, both desired and interfering signals change with spacing.
It is therefore inappropriate to assume that SINR must decrease
in direct proportion to received power.

The evaluation hexagon also grows with inter-site distance.
These results are not a fixed-service-area deployment comparison.

### Recorded observations

- Coverage trend: Pending
- SINR trend: Pending
- Rate trend: Pending
- Important qualifications: Pending

## 6. Frequency Reuse Analysis

Compare reuse 1, 3, and 7 while holding spacing and sector count
constant.

### Resource allocation

| Reuse factor | RBs per cell | Occupied bandwidth |
|---:|---:|---:|
| 1 | 50 | 9.00 MHz |
| 3 | 16 | 2.88 MHz |
| 7 | 7 | 1.26 MHz |

### Questions

- Which reuse factor provides the highest coverage?
- Which provides the highest mean SINR?
- Does a SINR increase compensate for reduced bandwidth?
- Which provides the best fifth-percentile rate?

### Interpretation considerations

Higher reuse factors change the co-channel interference pattern
but reduce bandwidth per cell.

Transmit power per site remains fixed, so power is concentrated
into fewer resource blocks at higher reuse factors. This must be
considered when interpreting the comparison.

A higher SINR does not automatically imply a higher rate proxy.

### Recorded observations

- Coverage comparison: Pending
- SINR comparison: Pending
- Bandwidth versus rate trade-off: Pending
- Preferred configuration for the stated objective: Pending

## 7. Sectorization Analysis

Compare one-sector and three-sector sites at the same spacing
and reuse factor.

### Questions

- Does sectorization change coverage?
- Where do sector boundaries appear in the association map?
- Does mean SINR improve?
- Are weak points concentrated near sector boundaries?

### Interpretation considerations

The three-sector configuration combines:

- Directional antenna gain
- Different radiation patterns
- Equal division of site power among sectors
- Same-site interference between sectors sharing a group

Consequently, this is not a directivity-only comparison.

The exported rate proxy is also not an aggregate site-capacity
measurement.

### Recorded observations

- Coverage comparison: Pending
- SINR comparison: Pending
- Boundary behavior: Pending
- Rate comparison: Pending

## 8. Spatial Map Analysis

### Serving-cell received power

Identify strong and weak regions relative to site positions.

Do not label this map as LTE RSRP.

### SINR

Inspect whether low-SINR areas coincide with low received power
or occur despite adequate signal strength.

### Serving-cell distribution

Inspect association boundaries and sector footprints.

A serving-cell ID represents a sector cell, not necessarily a
distinct base-station site.

### Coverage

Coverage requires both the received-power and SINR thresholds.

A binary coverage map alone does not show which criterion caused
an outage.

### Recorded observations

- Strong-signal regions: Pending
- Low-SINR regions: Pending
- Association patterns: Pending
- Outage locations: Pending

## 9. Metric Interpretation

### Mean SINR

This is the arithmetic mean of pointwise SINR values in dB.

It is not the same as converting average linear SINR to dB.

### Mean rate proxy

Uncovered points contribute zero.

The value assumes each evaluated point independently receives
all assigned cell bandwidth.

### Fifth-percentile rate proxy

This describes the lower tail of the evaluated spatial samples.

It may be zero if enough evaluated points are uncovered.

### Site density

Site density is a geometric metric. This project does not
calculate deployment cost or operating expenditure.

## 10. Validation

Run:

    testResults = runtests(fullfile('tests', 'test_planning.m'));
    disp(testResults);
    assert(all([testResults.Passed]), 'Planning tests failed.');

Record:

- Number of passed tests: Pending
- Number of failed tests: Pending
- Number of incomplete tests: Pending
- Any warnings or execution issues: Pending

These tests check implementation consistency and generated
outputs. They do not validate the model against field measurements.

## 11. Conclusions

Complete this section using measured simulation outputs.

1. Coverage-oriented configuration:
   Pending, with supporting coverage value.

2. Rate-oriented configuration:
   Pending, with supporting rate values.

3. Main reuse trade-off:
   Pending.

4. Main sectorization finding:
   Pending.

5. Main limitation affecting interpretation:
   Pending.

If selecting a preferred scenario, state the optimization
objective. There is no universal “best” configuration independent
of coverage, bandwidth, and deployment requirements.

## 12. Future Work

- Add spatially correlated shadowing
- Add terrain and building information
- Model antenna downtilt
- Include load-dependent interference
- Introduce user distributions and scheduling
- Compare deployments over a fixed service area
- Increase surrounding tiers to examine edge effects
- Compare predictions with measurements
