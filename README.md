# makie-demos

Twelve polished, publication-scale figures built with CairoMakie. The primary outputs are 1600×1000 background-transparent PNG files; GLMakie remains available for adapting the same scene graph to interactive windows.

```bash
julia --project=. scripts/render.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

The scenes span 2D, 3D, statistical, flow, matrix, molecular, polar, timeline, topology, and multi-panel compositions. Every output has an adjacent JSON manifest and is checked for transparent, visible, and colorful pixels.

## Transparent PNG reference gallery

`catalog.json` supplies searchable intent and family metadata.

| 3D surface | Vector field | Phase dashboard | Forecast fan |
|---|---|---|---|
| ![surface](out/surface-terrain-transparent.png) | ![vector field](out/vector-field-transparent.png) | ![phase dashboard](out/phase-dashboard-transparent.png) | ![forecast](out/uncertainty-forecast-transparent.png) |
| Correlation matrix | Parallel coordinates | Sankey | Volume slices |
| ![correlation](out/correlation-matrix-transparent.png) | ![parallel coordinates](out/parallel-coordinates-transparent.png) | ![sankey](out/sankey-energy-transparent.png) | ![volume slices](out/volume-slices-transparent.png) |
| Molecule | Polar climate | Gantt | Topology |
| ![molecule](out/molecular-scene-transparent.png) | ![polar climate](out/polar-climate-transparent.png) | ![gantt](out/gantt-system-transparent.png) | ![topology](out/topology-graph-transparent.png) |
