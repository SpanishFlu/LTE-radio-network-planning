# LTE Radio Network Planning Using MATLAB

An educational LTE downlink planning simulator for studying
base-station deployment, cellular coverage, frequency reuse,
interference, and sectorization.

## Features

- Hexagonal deployment with 19 base-station sites
- Urban macrocell path-loss modeling at 2 GHz
- Omnidirectional and three-sector antenna configurations
- Frequency reuse factors of 1, 3, and 7
- Received-power, SINR, and serving-cell maps
- Coverage and idealized rate comparisons across 18 scenarios

## Requirements

- MATLAB
- Base MATLAB functions; LTE Toolbox is not required

Tested MATLAB version: [add the version you actually used]

## Quick Start

1. Download or clone this repository.
2. Open MATLAB.
3. Navigate to the repository root.
4. Run:

```matlab
run(fullfile('src', 'lte_radio_network_planning.m'))
```

Generated files are saved in `results/`.

## Simulation Scenarios

| Parameter | Values |
|---|---|
| Number of sites | 19 |
| Inter-site distance | 500, 750, 1,000 m |
| Sectors per site | 1, 3 |
| Frequency reuse factor | 1, 3, 7 |
| Carrier frequency | 2 GHz |
| Total conducted power per site | 46 dBm |
| Total resource blocks | 50 |

## Example Output

Add representative figures here after running the simulation.

<!-- Uncomment after committing the corresponding image:
![Radio planning maps](docs/figures/radio_maps.png)
-->

## Results

Scenario metrics are exported to:

`results/scenario_summary.csv`

See [Results Analysis](docs/results-analysis.md) for interpretation.

## Methodology

See [Methodology](docs/methodology.md) for propagation equations,
antenna assumptions, interference calculations, and coverage criteria.

## Limitations

- Educational system-level model, not an LTE waveform simulator
- No terrain, building, shadowing, or fast-fading model
- Full-load interference assumption
- Received power is not LTE RSRP
- Shannon-based rate estimates are not measured LTE throughput
- Finite deployment introduces boundary effects

## Project Structure

- `src/`: simulation code
- `docs/`: documentation and selected figures
- `results/`: simulation outputs
- `tests/`: validation checks

## License

See `LICENSE`.
