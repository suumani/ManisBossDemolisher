# __ManisBossDemolisher__/spec.md

# Manis Boss Demolisher — Specification（spec v.0.1.5）

This document records the **design intent, specifications, and agreed rules** of *Manis Boss Demolisher*.  
Its purpose is to preserve decision criteria, world assumptions, and priority rules that cannot be fully conveyed through the Mod Portal or README.

---

## 0. Purpose and Non-goals

### 0.1 Purpose

- Redefine Demolishers not as temporary obstacles, but as  
  **planet-scale, central threats that shape the game world**
- Transform rocket launches and space expansion into  
  **decisions that always carry risk**
- Strongly encourage players to consider:
  - Planet progression order
  - Logistics and transport planning
  - Leaving, delaying, or abandoning planets

### 0.2 Non-goals

- Making all bosses defeatable is **not** a goal
- Forcing players to fight Demolishers is **not** a goal
- Simple numerical inflation or raw difficulty increase is **not** intended
- Completely destroying the existing combat balance is **not** intended

---

## 1. Mod Positioning

- Category: Content expansion / Enemy behavior & world-state extension
- Target environment: Factorio 2.0+ / Space Age
- Scope:
  - Planets where Demolishers exist
- Core fantasy:
  - *“The further humanity advances into space, the more dangerous the universe becomes.”*

---

## 2. Core Player Experience Loop

1. The player operates on a planet and launches rockets
2. That action becomes a trigger that changes conditions on other planets
3. Invasion and spread of Demolishers increase global threat
4. The player chooses to:
   - Respond
   - Postpone
   - Avoid or abandon

> In this mod, extremely powerful Demolishers are explicitly designed to be **targets for avoidance**, not mandatory combat.

---

## 3. System Specification Overview

### 3.1 Boss-class Demolishers

- Special individuals distinct from normal Demolishers, featuring  
  **high durability, attack power, and presence**
- Multiple strength tiers:
  - Small
  - Medium
  - Large
  - Behemoth
- As tiers increase:
  - Defeat difficulty rises
  - Avoidance and abandonment become realistic choices

---

### 3.2 Invasion Spread via Rocket Launches (Updated)

- Rocket launches act as **global invasion triggers**
- Every launch is evaluated; the system does not rely on random suppression

#### Export Spawn Conditions

For each destination planet (`dest_surface`), export spawning is governed by
**dynamic per-planet population caps**, not a fixed formula.

Export spawning is skipped if **any relevant cap is reached**.

#### Cap Model (Boss Demolisher)

Manis Boss Demolisher uses a **dual-cap system**:

- **Global Cap (Combat Cap)**  
  Limits the total number of Demolishers on a planet  
  (includes both Combat and Fatal classes)

- **Fatal Cap**  
  Limits only Fatal-class Demolishers  
  (does not include Combat-class Demolishers)

Both caps:
- Are evaluated **per planet**
- Include **physical + virtual entities**
- Are dynamically reduced by research

#### Research Interaction

The infinite research  
`manis-demolisher-cap-down`  
reduces both caps by **5% per level**, down to fixed minimums.

- Global Cap minimum: **10**
- Fatal Cap minimum: **10**

#### Definition of “Living Demolisher Count”

A “living Demolisher” includes:

- All physical entities on the planet that:
  - Belong to the enemy force
  - Are included in `DemolisherNames.ALL`
- All virtual (deferred) Demolishers registered for that planet

Virtual entities are counted to prevent:
- Silent cap bypass
- Burst spawns after chunk generation

---

### 3.3 Per-planet State Management

- Each planet tracks the following states:
- Boss Demolisher defeated / not defeated
- Invasion progressing / stalled / stabilized
- Depending on state:
- Spawned entities
- Behavior tendencies
- Degree of impact
may change

---

### 3.4 Reaction to Player Activity

- All Demolishers except giant-class individuals:
- React to rocket launch sounds by moving or approaching
- The design intentionally avoids “safe if ignored” behavior
- Giant-class Demolishers are treated as fixed large-scale obstacles, and are exempt from this reaction

### 3.5 Virtual Entity Handling

Manis Boss Demolisher fully supports **Virtual Entity Management**
as defined in Manis_lib.

#### Purpose

Boss Demolishers may:
- Spawn outside charted areas
- Move into ungenerated chunks
- Be deferred due to spawn safety constraints

To prevent:
- Entity loss
- Duplication
- Cap miscalculation

all such Demolishers are stored as **virtual entities** until safe to materialize.

#### Rules

- Virtual Demolishers:
  - Are counted toward all caps
  - Are materialized automatically on chunk generation
- Virtual entities are not shared across mods
- Identity persistence across Phy ↔ Virt transitions is **not guaranteed**

### 3.6 Combat vs Fatal Classification

Manis Boss Demolisher distinguishes Demolishers by **impact class**, not by lore tier.

- **Combat-class Demolishers**
  - Mobile
  - React to player actions
  - Subject to Global Cap only

- **Fatal-class Demolishers**
  - Extreme size or movement impact
  - Often treated as immovable obstacles
  - Subject to both:
    - Global Cap
    - Fatal Cap

This classification is used consistently for:
- Spawn limits
- Movement logic
- Performance safety

---

## 4. Difficulty and Design Policy

- Difficulty settings:
- Not provided by default
- Intended difficulty:
- Existence of enemies that cannot be defeated
- Situations where choosing *not* to fight is the correct decision
- In this mod, “failure” is defined as:
- Not base destruction
- But allowing the situation to deteriorate beyond recovery

---

## 5. Compatibility Policy

- Global enemy AI and behavior are modified as little as possible
- Interactions with other mods are limited to:
- Planet-specific behavior
- Demolisher-related logic
- Explicit incompatibilities will be documented in the README

---

## 6. Save Data and Determinism (Updated)

- Global data used:
  - `storage.manis_boss_demolisher_flag`
  - Virtual entity storage (via Manis_lib)

- Virtual entities are:
  - Fully serialized
  - Deterministically restored

- Multiplayer behavior:
  - Determinism is strictly required
  - Desync related to virtual handling is treated as a critical bug

---

## 7. Development Status and Roadmap

- Current:
- Invasion spread logic implemented
- Planet-level state management is stable
- Future:
- No large feature additions planned
- Focus on balance tuning and compatibility adjustments

---

## 8. Handling of This Specification

- This document takes precedence over README and Mod Portal descriptions
- If discrepancies arise between implementation and this spec:
- Either the implementation is accepted as the new specification, or
- This document is updated  
— and the decision must be made explicitly