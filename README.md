# Pin-Roller Beam Solver

A MATLAB-based structural beam solver for statically determinate pin-roller beams. Takes user-defined point loads and distributed loads, solves for support reactions, and outputs shear force and bending moment diagrams.

---

## Features

- Solves for support reactions (Px, Py, Ry) using matrix equilibrium equations
- Supports multiple point loads at arbitrary positions
- Supports multiple distributed loads (uniform, triangular, trapezoidal)
- Generates shear force diagram
- Generates bending moment diagram
- Queries shear and moment values at any position along the beam

---

## Usage

Run `BeamSolver.m` in MATLAB and follow the prompts:

```
Enter Beam Length: 10
Enter Force values: -18 -82 -150
Enter lever arm distance for Forces: 1 2 8
Enter signed (+,-) Distributed Loads (w1 w2 start stop): -10 -10 3 7
Enter position to generate values from: 5
```

### Input Format

| Prompt              | Description                                                            |
| ------------------- | ---------------------------------------------------------------------- |
| Beam Length         | Total length of beam in meters                                         |
| Force values        | Space-separated force magnitudes in Newtons (negative = downward)      |
| Lever arm distances | Space-separated positions of each force along the beam in meters       |
| Distributed Loads   | Groups of 4 values: `w1 w2 start stop` (negative intensity = downward) |

### Distributed Load Format

Each distributed load requires exactly 4 values entered as a group:

```
w1 w2 start stop
```

- `w1` — intensity at start position (N/m)
- `w2` — intensity at end position (N/m)
- `start` — start position along beam (m)
- `stop` — end position along beam (m)

Multiple distributed loads can be entered in a single line:

```
-10 -10 2 5 -20 0 6 9
```

---

## How It Works

### Reaction Solve

Equilibrium equations are assembled into a linear system **Ax = b** and solved using MATLAB's backslash operator:

```
[1  0  0 ] [Px]   [0              ]
[0  1  1 ] [Py] = [-ΣFy           ]
[0  0  L ] [Ry]   [-Σ(F * x)      ]
```

Distributed loads are converted to equivalent point loads using the trapezoidal centroid formula before the reaction solve:

```
F_eq = ((w1 + w2) / 2) * (stop - start)
x_eq = start + ((w1 + 2*w2) / (3*(w1 + w2))) * (stop - start)
```

### Shear Diagram

At each point along the beam, shear is computed as the sum of all forces (reactions and applied) to the left of that point.

### Moment Diagram

Bending moment is computed by numerically integrating the shear diagram using cumulative summation:

```matlab
moment_val = cumsum(shear_val .* dX);
```

This follows directly from the relationship dM/dx = V.

---

## Assumptions

- Beam starts at x = 0
- Simply supported: pin at x = 0, roller at x = L
- Statically determinate (3 unknowns, 3 equilibrium equations)
- Positive convention: upward forces positive, downward forces negative
- 2D loading — vertical forces and moments only (no horizontal loads beyond Px)

---

## Requirements

- MATLAB R2019b or later (no additional toolboxes required)

---

## Planned Extensions

- [ ] Distributed load shear contribution (continuous, not equivalent point load)
- [ ] User-defined support positions and types
- [ ] Applied moment loads
- [ ] Angled forces with horizontal components
- [ ] Beam diagram panel showing load visualization
- [ ] Max shear and moment output with locations
- [ ] Fixed support (cantilever beam) support

---

## Background

Built as a personal MATLAB project to apply statics concepts programmatically. Serves as a foundation for future structural analysis tools and as a portfolio demonstration of numerical methods, matrix equation solving, and engineering visualization.

**Related concepts:** Shear and moment diagrams, statically determinate beams, numerical integration, linear algebra
