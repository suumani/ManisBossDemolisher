# Invasion Export – Spec Coverage Matrix
`docs/SystemSpecification/01_InvasionExport.md`

**Spec Version:** v1.0 (confirmed)  
**Test Status:** ver.0.1.6  
**Purpose:** Map specification items to implemented test coverage and identify remaining tasks.

---

## 1. Export トリガー・評価

### EXP-TRG-001: Export is evaluated on every rocket launch
**内容**
- ロケット発射ごとに必ず Export を評価する

**対応テスト**
- PACK-EXPORT-BASIC（全ケース）
- PACK-EXPORT-MOVE-INTERACTION（INT-001 / INT-002）
- PACK-EXPORT-PROGRESSION-WORLD
- PACK-EXPORT-QUAL

**判定**
- ✅ **完全カバー**

---

### EXP-TRG-002: Terminal outcome required (OK / SKIP / FAIL)
**内容**
- Export 評価は必ず終端結果を持つ

**対応テスト**
- OK / SKIP は世界状態で間接的に検証
  - OK: world increase
  - SKIP: no increase (cap / defeated)
- FAIL は未注入

**判定**
- ⚠️ **部分カバー**
- FAIL 経路の明示的テストなし

**残タスク**
- 意図的 FAIL（異常系）を起こすテスト（P3）

---

## 2. Export 実行条件（Eligibility）

### EXP-ELIG-001: Vulcanus special rule
**対応テスト**
- PACK-EXPORT-BASIC / EXP-BASIC-001
- PACK-EXPORT-MOVE-INTERACTION / INT-001

**判定**
- ✅ **完全カバー**

---

### EXP-ELIG-002: Non-Vulcanus requires Defeated=true
**対応テスト**
- PACK-EXPORT-BASIC / EXP-BASIC-002, 003
- PACK-EXPORT-MOVE-INTERACTION / INT-002

**判定**
- ✅ **完全カバー**

---

### EXP-ELIG-003: Defeated definition
**内容**
- DemolisherNames.ALL の撃破が1体以上

**対応テスト**
- PACK-DEFEATED-FLAG（DEF-001 / 002 / 003B）

**判定**
- ✅ **完全カバー**

---

## 3. dest_surface 選定

### EXP-DEST-001: Fixed candidate set (5 planets)
**対応テスト**
- 暗黙的（全Packで5惑星前提）

**判定**
- ⚠️ **暗黙カバー**

**残タスク**
- 候補集合が5惑星であることの明示テスト（P4・低優先）

---

### EXP-DEST-002: Random pick first, validate after
**内容**
- 完全ランダム抽選 → 後段で有効性判定

**対応テスト**
- ランダム性自体は固定化（dest override）して吸収

**判定**
- ⚠️ **設計吸収済み（テストでは非ランダム）**

**備考**
- 意図的に「ランダム分布」はテストしない方針と一致

---

### EXP-DEST-003: Destination validity = Importable only
**対応テスト**
- 存在 surface のみ使用（暗黙）

**判定**
- ⚠️ **暗黙カバー**

---

## 4. 輸出個体数

### EXP-COUNT-001: Exactly one entity per export
**対応テスト**
- PACK-EXPORT-QUAL（find_newly_added_one）
- PACK-EXPORT-BASIC（diffで+1を前提）

**判定**
- ✅ **完全カバー**

---

## 5. 進行（Progression）

### EXP-PROG-001: Progression scope = dest_surface
**対応テスト**
- PACK-EXPORT-PROGRESSION-WORLD / PROG-006

**判定**
- ✅ **完全カバー**

---

### EXP-PROG-002: Tier-based progression
**対応テスト**
- PACK-EXPORT-PROGRESSION（pool-only）
- PACK-EXPORT-PROGRESSION-WORLD

**判定**
- ✅ **完全カバー**

---

## 6. 品質（Quality）

### EXP-QUAL-001: First-of-type is always normal
**対応テスト**
- PACK-EXPORT-QUAL / EXP-QUAL-001

**判定**
- ✅ **完全カバー**

---

### EXP-QUAL-002: Subsequent quality uses dest evo
**対応テスト**
- PACK-EXPORT-QUAL / EXP-EVO-001

**判定**
- ✅ **完全カバー**

---

### EXP-QUAL-003: Deterministic RNG
**対応テスト**
- Roll override による one-shot 証明

**判定**
- ✅ **実質カバー**

---

## 7. Cap（上限）

### EXP-CAP-001～003: cap / total / evo reference
**対応テスト**
- PACK-EXPORT-CAP-EDGE
- PACK-EXPORT-BASIC（抑止）

**判定**
- ✅ **完全カバー**

---

### EXP-CAP-004: Research-based reduction (最大25%)
**対応テスト**
- ❌ **未カバー**

**残タスク**
- Research 有効時の cap 低下テスト（P2）

---

### EXP-CAP-005: Dual-cap model
**対応テスト**
- PACK-EXPORT-CAP-EDGE（combat系中心）

**判定**
- ⚠️ **部分カバー**

**残タスク**
- fatal_cap 単独境界テスト（P2）

---

### EXP-CAP-006: Fatal slot reservation
**対応テスト**
- ❌ **未カバー**

**残タスク**
- Combatが枠を埋めても Fatal が出ることの保証テスト（P2）

---

## 8. メッセージ表示

### EXP-MSG-001 / 002
**対応テスト**
- ❌ **未カバー（意図的）**

**判定**
- 未テスト（観測仕様）

---

## 9. 観測（Observability）

### OBS-EXP-001: Required terminal log
**対応テスト**
- ❌ **未カバー（ログはassertしない方針）**

**判定**
- 設計方針どおり未テスト

---

## 10. Move 連動

### REL-MOV-001: Rocket launch schedules Move
**対応テスト**
- PACK-EXPORT-MOVE-INTERACTION

**判定**
- ✅ **完全カバー**

---

# 11. 残タスク総覧（仕様起点）

### P1（基盤）
- DeferredTestPump / Runner の test-enabled ガード
- print 抑制

### P2（仕様の未カバー部分）
- EXP-CAP-004: Research による cap 低下
- EXP-CAP-006: Fatal slot reservation
- fatal_cap 境界の明示テスト

### P3（異常系・観測）
- EXP-TRG-002: FAIL 経路の明示テスト
- OBS-EXP-001: ログ内容の最低保証（必要なら）

### P4（低優先・網羅性）
- dest_surface 候補集合の明示テスト
- Importable=false ケース（存在しない surface）

---

## 12. 総括

- **Export 仕様のコア挙動はほぼ完全にテスト化済み**
- 未検証領域は主に：
  - Research / Fatal 特化の上限仕様
  - 観測・ログ
  - 意図的な異常系
- 危険なブラックボックスは残っていない

残タスクは **明確かつ限定的**であり、
以後は「どこまでやるか」の判断フェーズに入っている。