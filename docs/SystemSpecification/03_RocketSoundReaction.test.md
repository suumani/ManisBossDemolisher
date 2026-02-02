# Rocket Sound Reaction & Planetary Move – Spec Coverage Matrix
`docs/SystemSpecification/03_RocketSoundReaction.md` (Draft v0.2)

**Test Status:** ver.0.1.6  
**Purpose:** Map Move specification items to implemented tests and identify remaining tasks.

---

## 1. 基本概念

### MOV-CON-003: Physical / Virtual are equal move subjects
**内容**
- Move は Physical / Virtual を区別しない
- 対象選定・距離計算・上限判定は同一ルール

**対応テスト**
- PACK-MOVE-SCHEDULE:
  - MOVE-SCH-003A..003D（Phys→Phy / Phys→Vir / Vir→Phy / Vir→Vir）
- PACK-EXPORT-BASIC / CHUNK-001（Phys/Virtual切替の前提）

**判定**
- ✅ **完全カバー**

---

## 2. トリガとスケジューリング

### MOV-TRG-001: Rocket launch records recent activity
**内容**
- ロケット発射で recent rocket activity が記録される

**対応テスト**
- PACK-EXPORT-MOVE-INTERACTION:
  - INT-001 / INT-002（RocketHistory 存在の assert）
- PACK-MOVE-SCHEDULE（前提として RocketHistory を使用）

**判定**
- ✅ **実質完全カバー**

---

### MOV-SCH-001: 30-minute scheduler builds a MovePlan
**内容**
- 過去30分以内にロケットがあれば Plan 生成

**対応テスト**
- PACK-MOVE-SCHEDULE:
  - Orchestrator.run_once_all_surfaces() により Plan 生成を検証
- PACK-EXPORT-MOVE-INTERACTION:
  - ロケット→Plan 生成の連動確認

**未検証点**
- **30分境界（≤30分 / >30分）**

**判定**
- ⚠️ **部分カバー**

**残タスク**
- 30分境界テスト（P2）
  - 例：last_rocket_tick = now-29min → Plan生成
  - last_rocket_tick = now-31min → 生成されない

---

### MOV-SCH-002: No recent rocket activity means no plan
**内容**
- 直近30分にロケットなし → Plan生成なし

**対応テスト**
- ❌ 明示的テストなし

**判定**
- ❌ **未カバー**

**残タスク**
- RocketHistory 空 or 期限切れで Plan が生成されないことのテスト（P2）

---

### MOV-SCH-003: Plan lifetime and regeneration
**内容**
- 全 Range 処理完了で Plan破棄
- 30分以内に完了しなければならない
- 30分イベントごとに新規 Plan（継続・マージなし）

**対応テスト**
- PACK-MOVE-SCHEDULE:
  - step進行 → PlanStore.clear による終了確認（暗黙）

**未検証点**
- Plan 未完了のまま30分経過した場合の扱い
- 既存 Plan があっても新規生成されるか

**判定**
- ⚠️ **部分カバー**

**残タスク**
- Plan寿命（タイムアウト）テスト（P2）
- 30分イベント×複数回での Plan再生成テスト（P3）

---

## 3. 実行モデル（1分ステップ）

### MOV-EXEC-001: 1-minute scheduler executes MovePlan step
**内容**
- 1分イベントで1ステップ進める

**対応テスト**
- PACK-MOVE-SCHEDULE:
  - Runner.run_one_step_if_present_all_surfaces() による step 進行

**判定**
- ✅ **実装挙動として十分カバー**
- ※ 実イベント（nth_tick）直結はテストしていないが、TestPlan方針上OK

---

### MOV-EXEC-002: Full surface coverage by ranges
**内容**
- 惑星全体を漏れなく Range 分割
- 各 Range は一度だけ処理

**対応テスト**
- ❌ 直接検証なし

**判定**
- ❌ **未カバー**

**残タスク**
- Range の網羅性・重複なしをどう検証するか設計判断（P3）
  - 実装詳細に強く依存するため、テスト対象外とする判断も合理的

---

### MOV-EXEC-003: Step may result in no movement (SKIP)
**内容**
- 対象なし / 条件不一致 / 距離ロール不成立 → SKIP は正常

**対応テスト**
- PACK-MOVE-SCHEDULE:
  - 複数 step 中に移動が発生しないケースを許容
  - SKIP を異常扱いしていない

**判定**
- ✅ **暗黙カバー**

---

## 4. 移動対象の選定

### MOV-ELIG-001: Eligibility by class
**内容**
- Combat 可動
- Fatal 不可動

**対応テスト**
- PACK-MOVE-SCHEDULE:
  - MOVE-SCH-002（fatal は動かない）

**判定**
- ✅ **完全カバー**

---

### MOV-ELIG-002: Eligibility by evo
**内容**
- evo 上昇で可動範囲が広がる

**対応テスト**
- evo override による「動く」側の検証はあり
- **閾値境界（動かない→動く）**は未検証

**判定**
- ⚠️ **部分カバー**

**残タスク**
- evo 閾値境界テスト（P2）

---

### MOV-ELIG-003: Fatal class is immobile by design
**内容**
- Fatal は物理/仮想を問わず Move 対象外

**対応テスト**
- PACK-MOVE-SCHEDULE（fatal 不動）
- Virtual fatal のケースは未明示

**判定**
- ⚠️ **部分カバー**

**残タスク**
- Virtual Fatal が移動しないことの明示テスト（P3）

---

### MOV-ELIG-004: Eligibility applies to Physical and Virtual
**内容**
- Combat/Fatal/evo 判定は Phys/Virt 共通

**対応テスト**
- MOVE-SCH-003A..003D（全遷移型）

**判定**
- ✅ **完全カバー**

---

## 5. 移動量と距離

### MOV-DIST-001: Distance depends on evo
**対応テスト**
- MOVE-SCH-003 系（calc_maxd を用いた上限検証）

**判定**
- ✅ **完全カバー**

---

### MOV-DIST-002: Deterministic random distance
**対応テスト**
- DeterministicRandom 前提
- 単発距離が上限内であることを検証

**判定**
- ✅ **実質カバー**
- ※ 分布テストは意図的に行っていない（TestPlan準拠）

---

### MOV-DIST-003: Distance constraint is per-move delta
**対応テスト**
- MOVE-SCH-003A..003D（全遷移型で per-delta 制約）

**判定**
- ✅ **完全カバー**

---

## 6. 上限と抑止

### MOV-CAP-001: Per-plan move limit
**内容**
- 1 Plan あたりの移動数上限

**対応テスト**
- ❌ 未検証（数値未確定）

**判定**
- ❌ **未カバー（仕様未確定）**

**残タスク**
- 上限値確定後にテスト追加（P3）

---

### MOV-CAP-002: Cap does not guarantee movement
**内容**
- 移動数が0でも正常

**対応テスト**
- MOVE-SCH 系で暗黙的に許容

**判定**
- ✅ **暗黙カバー**

---

## 7. 実装制約

### MOV-IMP-001: Teleport is not used
**内容**
- 移動は create+destroy

**対応テスト**
- ❌ 未検証

**判定**
- ❌ **未カバー（方針仕様）**

**残タスク**
- unit_number 変化等による間接検証を行うか、非テスト対象とする判断（P3）

---

### MOV-IMP-002: Chunk generation determines Phys / Virtual
**内容**
- 未生成→Virtual
- 生成済→Physical
- create_entity 失敗でも Move 成功扱い

**対応テスト**
- PACK-MOVE-SCHEDULE:
  - MOVE-SCH-003B / 003C / 003D
- PACK-EXPORT-BASIC / CHUNK-001

**判定**
- ✅ **完全カバー**

---

## 8. 観測（Observability）

### OBS-MOV-001 / 002 / 003
**内容**
- スケジューリング / step / 遷移はログまたは世界状態で観測可能

**対応テスト**
- 世界状態（遷移）は十分にテスト
- ログは assert しない方針

**判定**
- ⚠️ **意図的未カバー（ログ）**

---

# 9. 残タスク総覧（03起点）

### P2（仕様的に重要）
- MOV-SCH-002: recent rocket なし → Plan生成なし
- MOV-SCH-001: 30分境界（≤30 / >30）
- MOV-ELIG-002: evo 閾値境界

### P3（方針判断）
- MOV-EXEC-002: Range 網羅性テストを行うか
- MOV-IMP-001: teleport 不使用の検証を行うか
- Virtual Fatal 不動の明示テスト

---

## 10. 総括

- Move の **実行・距離・遷移・Fatal排除**というコア挙動は非常に強くカバーされている
- 残りは **時間境界（30分）** と **evo境界** が中心
- Range 網羅性・実装制約系は「テスト対象外」と割り切る判断も十分合理的