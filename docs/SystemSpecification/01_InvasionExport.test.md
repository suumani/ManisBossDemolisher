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

# Invasion Export – Spec Update Coverage & Gap Analysis
`docs/SystemSpecification/01_InvasionExport.md` (v0.1.6)

**Context:**  
本ドキュメントは、`01_InvasionExport.md` の更新（特に **6. 輸出位置選定 / 6.1 Chunk生成状態** の新設）を受けて、  
**現行テスト（ver.0.1.6）との対応関係を再評価**し、  
**新たに発生した残タスクを明確化**するための差分サマリーである。

---

## 1. 更新点の要約（v0.1.6）

### 新設・明確化された仕様
- **6. 輸出位置選定（Spawn Positioning）**
  - EXP-POS-001～004
- **6.1 Chunk生成状態とスポーン形態**
  - EXP-CHUNK-001～003
- **11. 観測（Observability）**
  - OBS-EXP-002（スポーン/実体化ログの必須化）
- **14. 既知の境界条件**
  - 位置選定不安定性
  - Virtual密度非考慮

> これらは、従来「暗黙」「実装依存」だった部分を  
> **仕様として正式に昇格**させた重要な更新である。

---

## 2. 既存テストとの対応状況（更新点フォーカス）

### 2.1 輸出位置選定（EXP-POS）

#### EXP-POS-001: Spawn position is selected per export
**対応テスト**
- PACK-EXPORT-BASIC  
  - EXP-BASIC-VIRT-001  
  - EXP-BASIC-PHY-001  
  - EXP-BASIC-CHUNK-001  

**判定**
- ✅ **完全カバー**  
（dest_surface上で毎回スポーン位置が評価され、結果が world state に反映されている）

---

#### EXP-POS-002: Position selection may fail (SKIP)
**内容**
- 密度・禁則・距離制約により、位置が見つからず SKIP になることがある

**対応テスト**
- ❌ **未カバー**

**判定**
- ❌ **新規未カバー（重要）**

**新規残タスク（P1）**
- 位置選定失敗を **意図的に発生させるテスト**  
  - 例：
    - dest_surface を物理デモリッシャーで高密度充填
    - spawn attempt → SKIP
    - world state に増加が無いことを assert

---

#### EXP-POS-003: Position failure must be observable
**内容**
- SKIP(reason=no_valid_position) をログで観測可能にする

**対応テスト**
- ❌ 未カバー（ログ未assert方針）

**判定**
- ⚠️ **仕様上必須だが、テスト方針としては未対応**

**残タスク（P3・方針判断）**
- ログを  
  - 完全に非テスト対象とする  
  - もしくは「存在のみ」を最小 assert する  
 どちらかを決める必要あり

---

#### EXP-POS-004: Density check scope (Physical only)
**内容**
- 密度判定は Physical entity のみ
- Virtual は考慮しない

**対応テスト**
- PACK-EXPORT-BASIC / VIRT-001 系で
  - Virtual大量存在下でも physical spawn が起き得ることを間接的に確認

**判定**
- ⚠️ **暗黙カバー**

**補足**
- 明示的に「Virtualが密度に含まれない」ことを assert するテストは未実装

---

## 2.2 Chunk生成状態とスポーン形態（EXP-CHUNK）

### EXP-CHUNK-001: Spawn mode depends on chunk generation
**対応テスト**
- PACK-EXPORT-BASIC / EXP-BASIC-CHUNK-001

**判定**
- ✅ **完全カバー**

---

### EXP-CHUNK-002: Chunk coordinate reference
**内容**
- タイル→チャンク変換で判定すること

**対応テスト**
- 上記テストが **tile座標→chunk生成**の前提で動作

**判定**
- ✅ **実質カバー**

---

### EXP-CHUNK-003: Virtual to Physical materialization
**対応テスト**
- PACK-EXPORT-BASIC / EXP-BASIC-CHUNK-001
- PACK-MOVE-SCHEDULE（Vir→Phy 遷移）

**判定**
- ✅ **完全カバー**

---

## 3. 観測（Observability）更新点

### OBS-EXP-002: Spawn positioning log
**内容**
- trigger / export結果 / spawn結果 / 実体化 を INFO ログで出力

**対応テスト**
- ❌ 未カバー（ログ未assert）

**判定**
- ⚠️ **意図的未カバー**

**管理判断**
- 既存方針どおり  
  - *world state を主審*  
  - *ログは副オラクル*  
とするなら、テスト未対応でも仕様違反ではない。

---

## 4. 既知の境界条件（14章）とテスト

### KNOWN-EXP-001: Position selection instability
- 現行テスト未対応
- 仕様として「起こり得る」ことを明記したのみ

→ **テスト必須ではない**（設計上の注意扱い）

---

### KNOWN-EXP-002: Virtual density not considered
- Virtual を密度に含めない仕様は EXP-POS-004 と整合
- 既存テストと矛盾なし

---

## 5. 更新後の残タスク一覧（01起点・最新版）

### P1（新仕様により新規発生：重要）
- **EXP-POS-002**
  - 位置選定失敗 → SKIP の世界挙動テスト
  - （高密度Physical環境を人工的に作る）

### P2（既存から継続）
- EXP-CAP-004: Research による cap 低下
- EXP-CAP-006: Fatal slot reservation
- EXP-DEST: Importable=false の dest 無効テスト

### P3（方針判断）
- EXP-POS-003 / OBS-EXP-002:
  - ログをどこまでテスト対象に含めるか

---

## 6. 総括（v0.1.6時点）

- **Chunk依存の Phys/Virt 分岐は完全にテスト済み**
- 今回の仕様更新で **初めて明確に「未テスト」となったのは位置選定失敗（EXP-POS-002）**
- それ以外は：
  - 既存テストでカバー済み
  - もしくは意図的に非テスト領域

👉 次に追加する価値が最も高いテストは  
**「高密度環境で Export が SKIP になること」**の 1 ケースである。

---

## 次のステップ提案

1. **EXP-POS-002 用の新Pack or Scenario を追加**
   - 例：`PACK-EXPORT-SPAWN-FAILURE`
2. もしくは、ここを **既知制限として仕様のみで留める**と明示

どちらにするか決めれば、  
テスト体系は **仕様 v0.1.6 に対してほぼ完全**になります。