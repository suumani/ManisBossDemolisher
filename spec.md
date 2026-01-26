# Manis Boss Demolisher — Specification (spec)

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

### 3.2 Invasion Spread via Rocket Launches

- Rocket launches act as  
  **triggers that activate Demolisher activity on other planets**
- Spread targets, range, and intensity depend on:
  - Planet state
  - Existing invasion conditions

- **Export decision**:  
  On every rocket launch, the export (invasion spread) event is always evaluated.  
  It is **not suppressed by probability**.

- **Export cap**:  
  For each destination planet (`dest_surface`), no new export spawn occurs if the number of **currently living Demolishers** on that planet is greater than or equal to `cap(evo)`.
  cap(evo) = floor(evo * 10)
  if evo >= 0.99, then cap = 20

- **Export trigger conditions**:
- A rocket launch is considered an export trigger if **either** of the following is satisfied:
  1) The rocket is launched from Vulcanus  
  2) The rocket is launched from a planet other than Vulcanus, **and** Demolishers have already been defeated on that planet

- **Reference for evo**:
- The `evo` used for `cap(evo)` is the **evolution factor of the source planet** (`trigger_surface`)

- **Definition of living Demolisher count**:
- “Living Demolisher count” refers to all entities on the destination planet that:
  - Belong to the enemy force, and
  - Are included in `DemolisherNames.ALL`

- **Export message display**:
- A message indicating export (invasion spread) is displayed at the time of rocket launch
- Message display is throttled to **at most once every 30 minutes**

> Rockets are not treated as mere progression steps.  
> Rockets are actions that **shake the world itself**, forcing careful transport planning.

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

## 6. Save Data and Determinism

- Global data used:
- `storage.manis_boss_demolisher_flag`
- Multiplayer behavior:
- Determinism is assumed
- Any deviation is treated as a bug

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