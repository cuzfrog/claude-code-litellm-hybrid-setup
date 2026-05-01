# Task T1 - "Neon-Rift" Procedural Survival

## 1. Overview
Build a 2D side-scrolling space-survival game called **Neon-Rift** using **Vite + TypeScript + HTML5 Canvas**. No external assets. All visuals drawn procedurally via Canvas API. Canvas size: **1280×720 pixels**.

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
- Fixed-timestep update at **60 Hz** with variable-rate rendering.
- Pattern: accumulate `delta`, step physics in fixed 16.67ms increments.
- **No interpolation**: render entities at exact physics positions.

### 2.3 Object Pool
- `ParticlePool` manages all `Particle` instances to eliminate GC spikes.
- Particles are acquired (`pool.acquire()`) and released (`pool.release(p)`) — never `new`-allocated at runtime.

---

## 3. Game Structure

### 3.1 Levels
- **3 levels**. Each level lasts exactly **2 minutes** (120 seconds) of rightward auto-scroll at **100 pixels/second**.
- Total level length: **12,000 pixels** per level.
- `RiftExit` portal appears at the end of **each level** (after 2-minute mark). Touching it advances to the next level or wins if Level 3.
- Between levels, ship state **resets**: fuel → 100%, velocity → (0, 0).
- Difficulty scaling:

| Level | Max debris on screen | Black hole size | Black hole count |
|-------|---------------------|-----------------|------------------|
| 1     | 10                  | Small (50px)    | 2                |
| 2     | 15                  | Medium (100px)  | 2                |
| 3     | 20                  | Large (150px)   | 2                |

- **5% of debris are blue** (fuel pickups); the rest are gray (hazards).

### 3.2 Checkpoints
- Checkpoints are **automatic and invisible**.
- Activated when ship travels **6,000 pixels** (1-minute mark) into a level.
- On death, ship respawns at the latest checkpoint with **100% fuel** and **zero velocity**.

### 3.3 Win / Loss
- **Win:** Touch `RiftExit` on Level 3 to complete the game.
- **Loss:** Ship touches a `BlackHole` center or gray `Debris` → instant death → respawn at last checkpoint.

---

## 4. Mechanics

### 4.1 Scrolling & Camera
- The world scrolls **rightward** at **100 pixels/second** automatically.
- The ship can move freely within the **1280×720 canvas bounds** (hard clamp at edges).
- When the ship reaches screen edges, position is clamped but velocity is preserved (drift continues inward).
- At the 2-minute mark (12,000 pixels), scroll **stops** and `RiftExit` portal spawns at the right edge.

### 4.2 Ship Physics & Controls
- Ship has `velocity` (vec2). It **drifts** with momentum; no instant stop.
- Ship visual orientation is **fixed** (always faces right); no rotation mechanic.
- **WASD Movement:**
  - `W/A/S/D` keys apply **200 pixels/sec²** force in up/left/down/right directions.
  - Multiple keys can be held simultaneously (diagonal movement).
  - **No fuel cost** for WASD movement.
- **Boost (Space key):**
  - One-time impulse that multiplies current velocity by **1.5×**.
  - Costs **25% fuel**.
  - Has **5-second cooldown**.
  - Cannot be used when fuel < 25%.
- **Velocity Limits:**
  - Normal max velocity: **300 pixels/sec**.
  - During/after boost: **450 pixels/sec** (temporary cap).
  - Max velocity returns to 300 px/s after velocity naturally decays below it.
- **Drag:** Velocity multiplied by **0.98** each frame (2% loss per frame).

### 4.3 Fuel
- Starts at **100%** at level start and checkpoint respawn.
- Depleted by boost: **-25% per use**.
- Replenished by contacting **blue Debris**: **+25% per pickup** (auto-collect on overlap).
- Fuel capped at 0% (floor) and 100% (ceiling).
- HUD displays current fuel percentage.

### 4.4 Black Holes (Gravitational Wells)
- Spawned procedurally as level scrolls. **2 black holes** visible at any time.
- Black hole radii by level:
  - Level 1: **50 pixels** (Small)
  - Level 2: **100 pixels** (Medium)
  - Level 3: **150 pixels** (Large)
- **Gravity well** extends to **3× the black hole radius** (150px / 300px / 450px).
- Exert pull on ship using **inverse-square law**:
  ```
  F = G * M / d²
  acceleration = F (applied toward black hole center each physics step)
  ```
  Where:
  - `G` = gravitational constant (tune so ship needs boost to escape at 2× radius)
  - `M` = black hole mass
  - `d` = distance from ship to black hole center
- **Design constraint:** When ship is within **2× radius** of black hole, WASD movement alone cannot escape; boost required.
- **Code requirement:** Include comment explaining the formula and variable meanings.
- Touching the black hole's center radius = instant death.

### 4.5 Procedural Generation
- Content generated on-the-fly in **chunks** (1 chunk = 1280 pixels = screen width).
- Each chunk contains:
  - Background stars (visual only, no collision)
  - `Debris` entities (max per screen based on level)
  - Blue `Debris` (5% of total debris)
  - `BlackHole` entities (maintain 2 on screen)
- Chunks that scroll fully off the left edge are **culled** from memory.

---

## 5. Visuals

- Use `globalCompositeOperation = 'lighter'` for neon glow effects on all entities.
- **Screen shake**: utility function `shakeScreen(intensity, duration)` triggered on death collision.
- All drawing uses Canvas primitives only (`arc`, `lineTo`, `fillRect`, etc.).
- **Particle effects** (from `ParticlePool`):
  - Continuous trail behind ship during movement
  - Burst on collision/death
  - Visual burst on boost activation
  - Ambient particles around black holes (swirling effect)

---

## 6. HUD
Displayed at all times in a corner overlay (units: pixels = "px"):
- `FUEL: 87%`
- `VEL: 142 px/s` (magnitude of velocity vector)
- `DIST: 3240 px` (distance traveled in current level)
- `LVL: 2` (current level: 1, 2, or 3)

---

## 7. Code Quality
- ES6+ syntax throughout.
- No magic numbers — use named constants for all values:
  - `CANVAS_WIDTH = 1280`, `CANVAS_HEIGHT = 720`
  - `WASD_FORCE = 200` (px/s²)
  - `BOOST_MULTIPLIER = 1.5`
  - `BOOST_FUEL_COST = 25` (%)
  - `BOOST_COOLDOWN = 5000` (ms)
  - `MAX_VELOCITY = 300` (px/s)
  - `BOOST_MAX_VELOCITY = 450` (px/s)
  - `DRAG_COEFFICIENT = 0.98`
  - `SCROLL_SPEED = 100` (px/s)
  - `LEVEL_LENGTH = 12000` (px)
  - `CHECKPOINT_DISTANCE = 6000` (px)
  - `CHUNK_WIDTH = 1280` (px)
  - `BLUE_DEBRIS_RATIO = 0.05` (5%)
  - `FUEL_RESTORE_AMOUNT = 25` (%)
  - Black hole sizes, debris counts, etc. should be **configurable** (use constants or config object).
- All constants grouped in a dedicated constants file/section.

---

## 8. Project Setup
- Project lives at `${GAME_DIR}/`. Do not create it at task dir. `GAME_DIR` is an environment variable.
- `npm run dev` serves at `http://0.0.0.0:8878`.
- **TDD**: Write tests (Vitest) for all core logic **before** implementing:
  - **Physics:**
    - WASD applies 200 px/s² force
    - Drag reduces velocity by 2% per frame
    - Velocity capped at 300 px/s (450 px/s after boost)
    - Hard clamp at screen boundaries
  - **Fuel:**
    - Boost consumes 25% fuel
    - Blue debris restores 25% fuel
    - Fuel floors at 0%, caps at 100%
    - Boost disabled when fuel < 25%
  - **Black hole gravity:**
    - Gravity formula F = G * M / d² correctly implemented
    - At 2× radius, ship cannot escape with WASD alone
    - Must use boost to escape from 2× radius or closer
  - **Chunk generation:**
    - Chunks spawn ahead at correct intervals
    - Old chunks culled when off-screen
    - Debris count matches level requirements
    - 5% of debris are blue
    - 2 black holes maintained on screen
  - **Checkpoint & respawn:**
    - Checkpoint activates at 6000px distance
    - Death respawns ship at checkpoint with 100% fuel, zero velocity
    - Level start respawns ship at (0, 0) if no checkpoint reached
  - **Level transitions:**
    - RiftExit spawns at 12000px per level
    - Touching RiftExit advances level
    - Ship state resets between levels (100% fuel, zero velocity)
  - **Collision detection:**
    - Ship-debris collision triggers death
    - Ship-blue debris collision restores fuel
    - Ship-black hole collision (within radius) triggers death
- Test commands must complete within **30 seconds**. If a test times out, fix it.

---

## 9. Acceptance Criteria

### AC1: Project Structure
- Game created under `${GAME_DIR}/` (not in task directory).
- Project uses Vite + TypeScript.
- All source files follow Entity class hierarchy (no exceptions).

### AC2: Game Runs Successfully
- Running `npm run dev` serves game at `http://0.0.0.0:8878`.
- `curl http://0.0.0.0:8878` returns HTTP 200 with non-empty HTML content.
- Canvas renders at 1280×720 pixels.

### AC3: Core Mechanics Tested
All the following test scenarios pass:
1. **Ship movement:** WASD applies 200 px/s² force in correct directions.
2. **Velocity limits:** Ship velocity clamped at 300 px/s normally, 450 px/s after boost.
3. **Drag:** Velocity multiplied by 0.98 each frame.
4. **Screen boundaries:** Ship position clamped at canvas edges (0,0) to (1280, 720).
5. **Boost mechanics:**
   - Boost multiplies velocity by 1.5×.
   - Boost consumes 25% fuel.
   - Boost has 5-second cooldown.
   - Boost disabled when fuel < 25%.
6. **Fuel system:**
   - Fuel starts at 100%.
   - Blue debris restores 25% fuel.
   - Fuel capped at 0-100% range.
7. **Black hole gravity:**
   - Gravity calculated using F = G * M / d².
   - At distance = 2× radius, WASD force insufficient to escape.
   - Boost enables escape from 2× radius.
8. **Collision detection:**
   - Ship-gray debris collision triggers death.
   - Ship-blue debris collision restores fuel (no death).
   - Ship-black hole center collision triggers death.
9. **Checkpoint system:**
   - Checkpoint activates at 6000px distance.
   - Death respawns at checkpoint with 100% fuel and zero velocity.
10. **Level progression:**
    - Each level is 12000px long (120 seconds at 100 px/s).
    - RiftExit spawns at end of level.
    - Touching RiftExit advances to next level.
    - Level 3 RiftExit triggers win condition.
11. **Level transitions:**
    - Ship resets to 100% fuel and zero velocity between levels.
12. **Procedural generation:**
    - Chunks spawn ahead correctly.
    - Debris count matches level (10/15/20 max on screen).
    - 5% of debris are blue.
    - 2 black holes maintained on screen.
    - Old chunks culled when off-screen.
13. **Particle pooling:**
    - Particles acquired from pool (no `new` at runtime).
    - Particles released back to pool after lifespan.

### AC4: Visual Requirements
- All entities drawn with Canvas primitives (no images).
- `globalCompositeOperation = 'lighter'` used for neon glow.
- Screen shake triggered on death.
- Particle effects present for: ship trail, collision burst, boost activation, black hole ambience.

### AC5: HUD Display
- HUD displays: FUEL, VEL, DIST, LVL.
- Values update in real-time.
- Units displayed as "px" or "px/s".

### AC6: Code Quality
- All numeric values defined as named constants (no magic numbers).
- Constants grouped in dedicated file/section.
- ES6+ syntax used throughout.
- Entity class hierarchy strictly enforced.

### AC7: Game Completability
- Player can complete all 3 levels by touching RiftExit at the end of Level 3.
- Win condition clearly indicated (visual or console message).
- Death and respawn system works correctly across all levels.
