# Manis Boss Demolisher — Specification (spec)

This document records the **design intent, specifications, and agreed decisions** of Manis Boss Demolisher.  
Its purpose is to preserve explicit criteria, worldview assumptions, and specification priorities that cannot be fully described in the Mod Portal or README.

---

## 0. Purpose and Non-goals

### 0.1 Purpose

- To redefine demolishers not as “temporary obstacles,” but as  
  **primary, planet-scale threats that exert influence across an entire planet**.
- To transform rocket launches and space expansion into  
  **decision-making processes that always involve risk**.
- To strongly encourage the player to consider choices such as:
  - Planet conquest order
  - Transportation planning
  - Abandonment, retreat, or avoidance

### 0.2 Non-goals

- It is not a goal to make all bosses defeatable.
- It is not a goal to make demolishers enemies that must always be fought.
- It does not aim for simple numerical strengthening or difficulty inflation.
- It does not intend to completely destroy existing combat balance.

---

## 1. Mod Positioning

- Category: Content addition / Enemy behavior and world-state expansion
- Target environment: Factorio 2.0+ / Space Age
- Scope of application:
  - Planets where demolishers exist
- Core fantasy:
  - “The further humanity advances into space, the more dangerous the universe becomes.”

---

## 2. Core Player Experience Structure

1. The player operates on a planet and launches rockets.
2. That action acts as a trigger, altering conditions on other planets.
3. Threats intensify as demolishers invade and spread.
4. The player must choose among the following:
   - Respond directly
   - Postpone action
   - Avoid or abandon the planet

*In this mod, demolishers that are excessively powerful are explicitly intended to be avoided rather than fought.*

---

## 3. System Specification Overview

### 3.1 Boss-class Demolishers

- Entities that differ from normal demolishers by possessing  
  **high durability, high attack power, and strong presence**.
- They exist in multiple tiers:
  - Small
  - Medium
  - Large
  - Behemoth
- As tiers increase:
  - Defeat difficulty rises
  - Avoidance or long-term neglect becomes a more realistic choice

---

### 3.2 Invasion Spread Triggered by Rocket Launches

- Rocket launches act as  
  **triggers that activate demolisher activity on other planets**.
- Target destinations, affected range, and intensity depend on:
  - The state of each planet
  - Existing invasion conditions

*Rockets are not merely indicators of progression.*  
*Rockets are actions that shake the world itself.*  
*This forces players to plan rocket transportation with strict precision.*

---

### 3.3 Per-planet State Management

- The following states are tracked on a per-planet basis:
  - Boss demolisher defeated / undefeated
  - Invasion progressing / stalled / subsiding
- Depending on the state:
  - Spawned entities
  - Behavioral tendencies
  - Degree of influence  
  will change accordingly.

---

### 3.4 Reaction to Player Activity

- All demolishers **except giant variants**:
  - React to rocket launch sounds
  - Move and approach the source
- This creates situations where simply “leaving things alone” is not always safe.
- Giant variants are excluded from this behavior by design,
  as they are intended to function as **fixed obstacles on the map**.

---

## 4. Difficulty and Design Philosophy

- Difficulty settings:
  - None are provided by design.
- Intended difficulty:
  - The existence of enemies that cannot be defeated is assumed.
  - There are situations where choosing not to fight is the correct decision.
- In this mod, “failure” is defined as:
  - Not the destruction of a base,
  - But allowing the situation to deteriorate until recovery becomes impractical.

---

## 5. Compatibility Policy

- Global enemy AI and behavior are altered as little as possible.
- If interference with other mods occurs:
  - It is limited to planet-level and demolisher-related behavior.
- Explicit incompatibilities will be documented in the README.

---

## 6. Save Data and Determinism

- Global data used:
  - `storage.manis_boss_demolisher_flag`
- Multiplayer behavior:
  - Determinism is assumed.
  - Any deviation from deterministic behavior is treated as a bug.

---

## 7. Development Status and Roadmap

- Current state:
  - Core invasion-spread logic is implemented.
  - Per-planet state management is stable.
- Future plans:
  - No large-scale feature additions are planned.
  - Focus will remain on balance tuning and compatibility adjustments.

---

## 8. Status of This Specification

- This document takes precedence over the README and Mod Portal descriptions.
- If discrepancies arise between implementation and this specification:
  - A conscious decision must be made to treat the implementation as authoritative,
  - Or to update this specification accordingly.