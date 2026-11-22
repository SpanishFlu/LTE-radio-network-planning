# Methodology

## 1. Project Objective

This project implements an educational LTE downlink radio network
planning simulator in MATLAB.

It investigates how base-station spacing, antenna sectorization,
and frequency reuse affect:

- Serving-cell received power
- Signal-to-interference-plus-noise ratio (SINR)
- Cellular coverage
- Serving-cell distribution
- Available radio resources
- Idealized user rate

The project is a system-level planning model. It does not generate
LTE waveforms or implement the complete LTE protocol stack.

## 2. Simulation Parameters

| Parameter | Value |
|---|---|
| Carrier frequency | 2 GHz |
| Number of sites | 19 |
| Deployment tiers | 2 |
| Inter-site distance | 500, 750, 1,000 m |
| Sectors per site | 1 or 3 |
| Frequency reuse factor | 1, 3, or 7 |
| Total conducted transmit power per site | 46 dBm |
| Receiver noise figure | 7 dB |
| Receiver temperature | 290 K |
| Total resource blocks | 50 |
| Bandwidth per resource block | 180 kHz |
| Minimum modeled distance | 35 m |
| Minimum coupling loss | 70 dB |
| Received-power coverage threshold | -100 dBm |
| SINR coverage threshold | -3 dB |
| Simulation grid | 181 × 181 points |

These values are project settings rather than universal LTE
deployment requirements.

A total of 18 scenarios are evaluated:

3 inter-site distances × 2 sector configurations × 3 reuse factors.

## 3. Base-Station Deployment

Sites are placed on a triangular lattice using axial coordinates
(q, r).

For inter-site distance D:

    x = D(q + r/2)
    y = D(sqrt(3)/2)r

The deployment includes coordinates satisfying:

    max(|q|, |r|, |q + r|) <= 2

This produces a central site and two surrounding tiers: 19 sites
in total.

The nominal hexagonal cell radius is:

    R = D / sqrt(3)

The area associated with each site is:

    A_site = (sqrt(3)/2)D^2

With D expressed in meters, site density is:

    Site density = 10^6 / A_site  sites/km²

## 4. Evaluation Region

Maps are generated across the entire simulation grid.

Summary metrics are calculated only over the central site's
nominal hexagon. Surrounding sites contribute interference and
may also serve points within this region.

This reduces, but does not eliminate, finite-network edge effects.

The evaluation hexagon changes physical size with inter-site
distance. Consequently, the scenarios do not represent alternative
deployments over one fixed service area.

## 5. Propagation Model

The urban macrocell path-loss expression is:

    PL_macro(dB) = 128.1 + 37.6 log10(d_km)

The expression is taken from the 2 GHz urban macrocell scenario
in 3GPP TR 36.942. Its assumptions include a base-station antenna
approximately 15 m above average rooftop level.

The implementation also calculates free-space path loss:

    PL_FS(dB) = 32.45 + 20 log10(f_MHz) + 20 log10(d_km)

Applied propagation loss is:

    PL = max(PL_macro, PL_FS)

Distances below 35 m are clipped to 35 m. This numerical safeguard
does not make the macrocell model accurate at short distances.

Shadowing, fast fading, building penetration, and terrain effects
are not included.

## 6. Antenna Model

### Omnidirectional configuration

Each site has one cell with an assigned antenna gain of 0 dBi.

### Three-sector configuration

Each site has three cells with boresights of:

- 0 degrees
- 120 degrees
- 240 degrees

Angular offset is wrapped into the interval [-180, 180) degrees.

The horizontal antenna pattern is:

    A(theta) = min(12(theta/65)^2, 20)
    G(theta) = 15 - A(theta)

Here:

- Peak gain is 15 dBi.
- Horizontal beamwidth parameter is 65 degrees.
- Maximum attenuation is 20 dB.

No vertical pattern or electrical downtilt is modeled.

## 7. Transmit Power and Received Power

Total conducted power is fixed at 46 dBm per site.

For S sectors, conducted power per sector is:

    P_cell(dBm) = 46 - 10 log10(S)

Effective coupling loss is:

    L_coupling = max(PL - G, 70)

Received power from each cell is:

    P_rx(dBm) = P_cell - L_coupling

The minimum coupling-loss limit prevents unrealistically strong
received power at short distances.

Received power represents integrated power over the cell's
assigned occupied bandwidth. It is not LTE RSRP.

Sectorization changes antenna gain, radiation pattern, and power
per sector. Therefore, comparisons do not isolate antenna
directivity alone.

## 8. Frequency Reuse

Each site is assigned a resource-block group using its axial
coordinates.

| Reuse factor | Group assignment |
|---|---|
| 1 | All sites use group 1 |
| 3 | mod(q - r, 3) + 1 |
| 7 | mod(q + 3r, 7) + 1 |

All sectors at the same site share that site's group.

Different groups use disjoint resource-block subsets.

The number of resource blocks per cell is:

    N_RB = floor(50 / reuse_factor)

| Reuse factor | RBs per cell | Unassigned RBs |
|---|---:|---:|
| 1 | 50 | 0 |
| 3 | 16 | 2 |
| 7 | 7 | 1 |

Occupied bandwidth per cell is:

    B = N_RB × 180,000 Hz

This gives 9 MHz of occupied RB bandwidth for reuse 1, within
the project's nominal 10 MHz carrier configuration.

Total site transmit power remains constant across reuse factors.
Higher reuse factors therefore concentrate power into fewer RBs.

## 9. Serving-Cell Association

Each grid point selects the cell with the strongest received power.

Association does not consider:

- Cell loading
- Handover hysteresis
- Resource availability
- Maximum achievable SINR

The strongest cell may differ from the geometrically nearest site.

## 10. Interference and Noise

The simulator assumes full-load downlink transmission.

Interference is the sum of received powers from all non-serving
cells using the serving cell's resource-block group.

Cells using different groups do not interfere in this model.

Thermal noise is calculated as:

    N = kTB × 10^(NF/10)

Where:

- k = 1.380649 × 10^-23 J/K
- T = 290 K
- B = occupied bandwidth
- NF = receiver noise figure in dB

SINR is calculated in linear power units:

    SINR = P_serving / (P_interference + P_noise)

The displayed value is:

    SINR_dB = 10 log10(SINR)

## 11. Coverage Definition

A point is covered only when both requirements are satisfied:

    Received power >= -100 dBm
    SINR >= -3 dB

Coverage percentage is:

    Coverage (%) = 100 × covered points / evaluated points

Each evaluation-grid point has equal weight.

## 12. Idealized Rate Proxy

The simulator calculates:

    Rate = B log2(1 + SINR)

Rates are converted to Mbps and set to zero at uncovered points.

This is a Shannon-based proxy for a hypothetical user receiving
all assigned cell bandwidth.

It is not measured LTE throughput and excludes scheduling,
protocol overhead, MCS limits, retransmissions, and user sharing.

## 13. Summary Metrics

For each scenario, the simulator exports:

- Inter-site distance
- Sectors per site
- Reuse factor
- Number of sites
- Site density
- Resource blocks per cell
- Unassigned resource blocks
- Coverage percentage
- Mean SINR in dB
- Mean rate proxy
- Fifth-percentile rate proxy

Mean SINR is the arithmetic mean of the pointwise dB values,
not the dB conversion of mean linear SINR.

The fifth-percentile rate uses the sorted sample at index:

    max(1, ceil(0.05 × number_of_samples))

Uncovered points contribute zero to rate statistics.

## 14. Reproducibility and Validation

The current model has no random components.

Reproduction requires:

1. Recording the MATLAB version and code revision.
2. Running the simulation script.
3. Preserving the generated CSV and MAT outputs.
4. Running the validation tests.
5. Reporting assumptions alongside the results.

Passing software tests does not establish agreement with a
real-world LTE network.

## 15. Limitations

- No terrain or building data
- No shadowing or fast fading
- No indoor penetration loss
- No antenna downtilt
- No user traffic or scheduler model
- Full-load interference assumption
- Finite 19-site deployment
- Approximate short-distance propagation behavior
- Received power is not RSRP
- Rate proxy is not actual LTE throughput
- Changing inter-site distance changes the evaluation area
1. 3GPP TR 36.942 V8.4.0, Radio Frequency (RF) system scenarios.
   Published by ETSI as TR 136 942.
2. `src/lte_radio_network_planning.m`, project implementation.
