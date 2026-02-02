# Rocket Sound Reaction & Planetary Move

docs/SystemSpecification/03_RocketSoundReaction.md  
**Draft v0.2**

## 0. 本書の位置づけ

本書は、ロケット発射を契機として発生する **惑星内移動（Move）** の仕様を定義する。  
Export（侵略拡散）の詳細は `01_InvasionExport.md` を参照する。

本書は **ゲーム挙動（移動が起きる／起きない／どの程度起きる）** を定義する一次資料である。

---

## 1. 基本概念

- Move は 輸出（Export）とは独立した処理系である
- ロケット発射は、以下 2 つを同時に引き起こし得る：
  - Export の評価・実行
  - Move のスケジューリング

### MOV-CON-003: Physical / Virtual are equal move subjects

- Move における対象は、以下 2 種類の存在形態を取る：
  - **Physical Entity（実体）**
  - **Virtual Entity（仮想）**
- Virtual Entity は、
  - 異常状態
  - 一時的退避
 ではなく、**正規の世界状態**である。
- Move の対象選定・距離計算・上限判定は、
  **Physical / Virtual を区別せず同一ルール**で行う。

---

## 2. トリガとスケジューリング

### MOV-TRG-001: Rocket launch records recent activity

- ロケット発射が発生すると、対象惑星に「直近ロケット発射」が記録される

#### 保存候補

- `storage.<mod>.<surface>.last_rocket_tick`

---

### MOV-SCH-001: 30-minute scheduler builds a MovePlan

- 30 分イベント（nth_tick）において、以下を判定する：
  - 過去 30 分以内にロケット発射があったか
- 条件を満たす場合：
  - 惑星全体を Range（セル）に分割
  - MovePlan を生成する

#### 目的

- ロケット発射に対する「即時反応」ではなく、
  遅延・波及的な脅威として表現するため

---

### MOV-SCH-002: No recent rocket activity means no plan

- 過去 30 分以内にロケット発射が無い場合：
  - MovePlan は生成されない

---

### MOV-SCH-003: Plan lifetime and regeneration

- MovePlan は **全 Range 処理完了**で自動破棄される
- MovePlan は **30 分以内に完了しなければならない**
- 30 分イベントごとに、新しい MovePlan を **新規生成**する  
  （過去 Plan の継続・マージは行わない）

---

## 3. 実行モデル（1 分ステップ）

### MOV-EXEC-001: 1-minute scheduler executes MovePlan step

- 1 分イベント（nth_tick）で、MovePlan を 1 ステップずつ実行する
- 各ステップは **小領域（Range / Cell）単位**

---

### MOV-EXEC-002: Full surface coverage by ranges

- MovePlan は惑星全体を **漏れなくカバーする Range 群**で構成される
- 各 Range は **一度だけ**処理される

---

### MOV-EXEC-003: Step may result in no movement

- 各 Step において、以下が成立し得る：
  - 移動対象が存在しない
  - 対象は存在するが移動条件を満たさない
  - 距離ロール・確率判定により移動が発生しない
- この場合、Step は **SKIP として正常終了**する。
- 「Step が存在するが移動が 0 件」という状態は、
  **仕様上の正常系**である。

---

## 4. 移動対象の選定

### MOV-ELIG-001: Eligibility by class

- Combat 系デモリッシャー：移動可能
- Fatal 系デモリッシャー：移動不可（常に対象外）

※ Combat / Fatal の定義は `04_BossClasses.md` を参照

---

### MOV-ELIG-002: Eligibility by evo

- Combat 系デモリッシャーは、evo に依存して段階的に移動可能となる
- evo が上昇するにつれ：
  - 移動可能な種類・個体が増加する
- 最終段階では、Combat 系は **すべて移動可能**

---

### MOV-ELIG-003: Fatal class is immobile by design

- Fatal 系は襲ってくる敵ではない
- Fatal 系は地形制約レベルの脅威として定義される
- よって、Move の対象外とする（移動しない）

---

### MOV-ELIG-004: Eligibility applies to both Physical and Virtual

- Combat / Fatal 判定および evo 判定は、
  - Physical Entity
  - Virtual Entity  
  の **両方に等しく適用**される。
- Fatal 系が Virtual で存在していても、
  Move の対象外であることに変わりはない。

---

## 5. 移動量と距離

### MOV-DIST-001: Move distance depends on evo

- 移動距離は evo に依存して増加する

---

### MOV-DIST-002: Distance is randomized deterministically

- 移動距離はランダムに決定される
- 乱数源は **DeterministicRandom（LuaRandomGenerator）**
- 同一条件下では結果は再現可能

---

### MOV-DIST-003: Distance constraint is per-move delta

- 移動距離制約は、**1 回の移動（delta）ごと**に適用される
- 以下は **すべて同一の距離制約**を受ける：
  - Phys → Phys
  - Phys → Virtual
  - Virtual → Phys
  - Virtual → Virtual
- 累積移動距離に対する制約は **行わない**

---

## 6. 上限と抑止

### MOV-CAP-001: Per-plan move limit

- 1 つの MovePlan あたり、
  移動するデモリッシャーの総数には上限がある
- 上限値は別紙で定義する（数値は本書では固定しない）

---

### MOV-CAP-002: Cap does not guarantee movement

- Cap は **最大値**であり、
  必ずその数だけ移動が発生することは保証されない
- 実際の移動数は、確率・条件により **0 件**になることもある

---

## 7. 実装制約（仕様としての前提）

### MOV-IMP-001: Teleport is not used

- デモリッシャーは `.teleport` を受け付けない
- 移動は **create + destroy** によって実現される

※ 本仕様は実装制約だが、挙動に影響するため仕様として明記する

---

### MOV-IMP-002: Chunk generation determines Phys / Virtual transition

- Move の結果が Physical / Virtual のどちらになるかは、
  **移動先座標の Chunk 生成状態**に依存する
- 以下は **すべて正常系**である：
  - 未生成 Chunk → Virtual 化（Phys → Vir）
  - 生成済 Chunk → 実体化（Vir → Phys）
- `create_entity` が失敗した場合でも、
  Virtual 化または維持によって Move は成功とみなされる

---

## 8. 観測（Observability）

### OBS-MOV-001: Move scheduling is observable

- 30 分イベントにおいて、以下がログで観測できること：
  - recent rocket activity の有無
  - MovePlan 生成の有無（OK / SKIP / FAIL）

---

### OBS-MOV-002: Step execution is observable

- 1 分イベントごとに、以下がログで観測できること：
  - 対象 Range
  - 対象個体数
  - 移動成功数
  - 残りステップ数

---

### OBS-MOV-003: Transition type is observable by world state

- Move の結果として発生する
  Physical / Virtual の遷移は、
  **ログではなく世界状態**によって観測される
- ログは以下を保証するための補助情報である：
  - Step が評価されたこと
  - SKIP / OK / FAIL の理由

---

## 9. 未決事項 / 後続文書

- Range 分割方式（矩形 / チャンク / 動的）
- evo → 移動解禁の具体テーブル
- 上限値（MOV-CAP-001）の具体数値
- 確率要素のテスト吸収方法  
  → `99_TestPlan.md` に委譲する

---

## 10. 本書の更新ルール

- Move の挙動を変更する場合、本書を必ず更新する
- Export 仕様との関係が変わる場合、
  `01_InvasionExport.md` も同時更新する

---

## まとめ

Move は **「ロケット発射の余波」**として設計されている。

即時ではなく、遅延・分割・段階化された脅威として、
Physical / Virtual を含む惑星全体の再配置処理として
プレイヤーに作用する。

Move において  
**「動かない」「仮想になる」「実体化する」**  
いずれも仕様どおりの結果である。