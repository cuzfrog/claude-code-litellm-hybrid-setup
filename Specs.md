# Task T1 - "Neon-Rift" Procedural Survival

## 1. Overview
Build a 2D side-scrolling space-survival game called **Neon-Rift** using **Vite + Typescript + HTML5 Canvas**. No external assets. All visuals drawn procedurally via Canvas API.

---

## 2. Architecture (Mandatory)

### 2.1 Entity Class Hierarchy
All game objects **must** extend a base `Entity` class. No exceptions.

```
Entity (base)
├── Ship          – player-controlled
├── BlackHole     – gravitational hazard
├── Debris        – collision hazard; blue variant refuels ship on contact
├── Particle      – visual effect only
└── RiftExit      – win-condition trigger at end of each level
```

- Each subclass implements `update(dt)` and `draw(ctx)`.
- Game logic lives in the subclass, not in a monolithic game loop.
- No business logic outside of entity classes and the `Game` orchestrator.

### 2.2 Game Loop
- Fixed-timestep update (e.g., 60 Hz) with variable-rate rendering and **interpolation**.
- Pattern: accumulate `delta`, step physics in fixed increments, render with alpha blend.

### 2.3 Object Pool
- `ParticlePool` manages all `Particle` instances to eliminate GC spikes.
- Particles are acquired (`pool.acquire()`) and released (`pool.release(p)`) — never `new`-allocated at runtime.

---

## 3. Game Structure

### 3.1 Levels
- **3 levels**. Each level lasts exactly **2 minutes** of rightward auto-scroll.
- After surviving all 3 levels and passing the `RiftExit` on Level 3, the player **wins**.
- Difficulty scales per level:

| Level | Debris density | Black hole size |
|-------|---------------|-----------------|
| 1     | Low           | Small           |
| 2     | Medium        | Medium          |
| 3     | High          | Large           |

### 3.2 Checkpoints
- One checkpoint spawns at the **1-minute mark** (midpoint) of each level.
- On death, player restarts from the **latest reached checkpoint** (or level start if none reached).

### 3.3 Win / Loss
- **Win:** touch `RiftExit` after the 2-minute scroll ends on each level; clear all 3 levels.
- **Loss (instant game over):** ship touches a `BlackHole` center or a non-blue `Debris` object → restart from last checkpoint.

---

## 4. Mechanics

### 4.1 Scrolling & Camera
- The world scrolls **rightward** at a constant speed automatically.
- The ship can move freely within the visible screen bounds.
- At the 2-minute mark the scroll **stops** and a `RiftExit` portal appears on the right edge.

### 4.2 Ship Physics (Newtonian)
- The ship has `velocity` (vec2) and `angle`. It **drifts** — no instant stop.
- `W` — apply thrust force in the facing direction; costs fuel.
- `A / D` — rotate the ship (angular, no fuel cost).
- `Space` — **boost**: apply a large one-shot thrust impulse in the facing direction; costs fuel. Has a short cooldown.
- When fuel reaches 0, thrust and boost are disabled; the ship still drifts.

### 4.3 Fuel
- Starts at 100%. Depleted by thrust (continuous) and boost (fixed cost per use).
- Replenished by contacting **blue Debris** (auto-collect on overlap).
- Fuel level shown in HUD. No other effect when empty beyond disabling thrust/boost.

### 4.4 Black Holes (Gravitational Wells)
- Spawned procedurally as the level scrolls in.
- Exert a pull on the ship using the **inverse-square law**:
  ```
  F = G * M / d²
  acceleration = F (applied toward black hole center each fixed step)
  ```
- **Must include a code comment** explaining the formula and variable meanings.
- Touching the black hole's center radius = instant death.

### 4.5 Procedural Generation
- As the screen scrolls right, new content is generated on-the-fly in **chunks** (e.g., one chunk = one screen-width).
- Each chunk contains: background stars, scattered `Debris`, blue `Debris` (fuel pickups), and `BlackHole` entities.
- Chunks that have fully scrolled off the left edge are culled from memory.

---

## 5. Visuals

- Use `globalCompositeOperation = 'lighter'` for neon glow effects on all entities.
- **Screen shake**: utility function `shakeScreen(intensity, duration)` triggered on death collision.
- All drawing uses Canvas primitives only (`arc`, `lineTo`, `fillRect`, etc.).

---

## 6. HUD
Displayed at all times in a corner overlay:
- `FUEL: 87%`
- `VEL: 142 u/s`
- `DIST: 3240 u`
- `LVL: 2`

---

## 7. Code Quality
- ES6+ syntax throughout.
- No magic numbers — use named constants (e.g., `THRUST_FORCE`, `BOOST_COST`, `CHUNK_WIDTH`).

---

## 8. Project Setup
- Project lives at `ai_test/lissom-skills/${GAME_DIR}/`
- `npm run dev` serves at `http://0.0.0.0:8878`.
- **TDD**: write tests (e.g., Vitest) for all core logic before implementing:
  - Physics: thrust acceleration, drift, black hole gravity formula.
  - Fuel: depletion on thrust/boost, refuel on pickup, floor at 0.
  - Chunk generation: chunks spawn ahead, old chunks are culled.
  - Checkpoint: death respawns at correct position.
- Test commands must complete within **30 seconds**. If a test times out, fix it.
