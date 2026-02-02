# Planet Profile & Scheduling Model – Spec Coverage Matrix
`docs/SystemSpecification/02_PlanetStateModel.md` (Draft v0.1)

**Test Status:** ver.0.1.6  
**Purpose:** Map specification items to implemented tests and identify remaining tasks.

---

## 1. 惑星プロファイル（Planet Profile）

### PP-DEF-001: Defeated Flag
**内容**
- そのsurfaceで DemolisherNames.ALL を1体以上撃破 → defeated=true
- Export条件に使用
- 保存: storage.manis_boss_demolisher_flag[...].defeated

**対応テスト**
- PACK-DEFEATED-FLAG: DEF-001 / DEF-002 / DEF-003B
- PACK-EXPORT-BASIC: defeated gate（EXP-BASIC-002/003）
- PACK-EXPORT-MOVE-INTERACTION: non-vulcanus（INT-002）

**判定**
- ✅ 完全カバー

---

### PP-IMP-001: Importable
**内容**
- surface生成済み（game.surfaces[name] ~= nil）なら Importable
- 永続化しない（再計算）

**対応テスト**
- 実装上は暗黙（各Packで ensure_surface している）
- 「Importable=false により dest が無効になる」ケースは未検証

**判定**
- ⚠️ 暗黙カバー（Importable=false 分岐は未テスト）

**残タスク**
- dest_surface が未生成だった場合の挙動（SKIPになること、ログreason）テスト（P2）

---

### PP-SPEC-001: Species Policy（Vulcanus=標準 / その他=-alt）
**内容**
- planetごとに種別（-alt有無）を切替
- 副作用としてドロップ方針（死骸/資源）が変わる

**対応テスト**
- PACK-EXPORT-PROGRESSION-WORLD / PROG-001 で “flagはentity_name完全一致” を検証
- ただし「planetにより -alt を選ぶ」そのものの選定規則は未テスト
- ドロップ差（死骸のminable results等）は未テスト

**判定**
- ❌ 未カバー（種別選定規則 / ドロップ副作用）

**残タスク**
- Vulcanus と非Vulcanusで、同一Tierの選定が標準/altに分岐することのテスト（P2）
- ドロップポリシーのテストをやるかどうかの方針決め（P3）
  - 仕様に含めるならテスト対象
  - 含めないなら 04側へ分離 or “プレイテスト対象” 明記

---

## 2. Export（02側再掲のモデル）

以下は `01_InvasionExport.md` と同内容（または簡略版）として扱えるため、既存の対応をそのまま適用。

- EXP-TRG-001, EXP-TRG-002
- EXP-DEST-001～003
- EXP-SEL-001
- EXP-PROG-001
- EXP-QUAL-001
- EXP-EVO-001, EXP-EVO-002

**対応テスト（代表）**
- PACK-EXPORT-BASIC
- PACK-EXPORT-CAP-EDGE
- PACK-EXPORT-QUAL
- PACK-EXPORT-PROGRESSION / PROGRESSION-WORLD
- PACK-EXPORT-MOVE-INTERACTION

**判定**
- ✅（01側で整理済み）
- 例外：02にしか書かれていない “Progress保存候補(import_progress)” は未検証（後述）

---

## 3. Move（惑星内移動）モデル

### MOV-TRG-001: Rocket launch marks recent rocket activity
**内容**
- ロケット発射で trigger_surface に“直近ロケット活動”が記録される

**対応テスト**
- PACK-EXPORT-MOVE-INTERACTION: INT-001/002（RocketHistory存在のassert）
- PACK-MOVE-SCHEDULE: plan生成前提として RocketHistory を投入/利用

**判定**
- ✅ 実質カバー（少なくとも「記録が残る」を検証）

---

### MOV-PLAN-001: 30min scheduler builds plan if recent rocket exists (within 30min)
**内容**
- 「過去30分以内の発射履歴」を判定して Plan生成

**対応テスト**
- 現状：Orchestrator を直接呼ぶ／RocketHistory.add を直接呼ぶテストはある
- 「30分以内/30分超過の境界」そのものは未検証（時間依存の仕様）

**判定**
- ⚠️ 部分カバー

**残タスク**
- “30分以内はPlan生成 / 30分超過は生成しない” の境界テスト（P2）
  - いまのTestPlanの「周期短縮」方針に合わせた形で作る

---

### MOV-EXEC-001: 1min scheduler executes plan step-by-step
**内容**
- 1分イベントで 1 step 進める（セル単位の実行）

**対応テスト**
- PACK-MOVE-SCHEDULE: MOVE-SCH-001/003系（Runner.run_one_step... でstep進行・距離制約）
- ただし「本当に1分イベントで駆動される」こと自体はテストしていない（手動実行）

**判定**
- ✅/⚠️ 実装検証は十分、スケジューラ結線は暗黙

**残タスク（任意）**
- 1分イベント経由の結線を “イベント駆動” として明示テストするか（P3）
  - 既に Runner を直接叩けているなら、優先度は低い

---

### MOV-ELIG-001: Move eligibility depends on evo and class (fatal does not move)
**内容**
- evo依存
- Fatal系は常に対象外

**対応テスト**
- PACK-MOVE-SCHEDULE: MOVE-SCH-002（fatalは動かない）
- evo依存の閾値は現状 override で吸収している（“低evoで動かない/高evoで動く”の境界は未検証）

**判定**
- ⚠️ 部分カバー（fatalはOK、evo閾値境界は未テスト）

**残タスク**
- evo閾値の境界テスト（P2）
  - 例：evo=threshold-εではmoveしない、evo=threshold+εではmoveする

---

### MOV-IMP-001: Teleport is not used; create+destroy based
**内容**
- teleport不可 → warp（create+destroy）で移動

**対応テスト**
- 直接は未テスト（実装詳細に寄る）

**判定**
- ❌ 未カバー（方針仕様）

**残タスク**
- テスト対象にするかの方針決め（P3）
  - 「teleportを呼んでいない」ことは挙動テストでは保証しにくい
  - 代替：移動後 entity が別unit_numberである等の観測で “create+destroy” を間接証明する（やるなら）

---

## 4. 観測（Observability）要件（02側の最低限）

### OBS-REQ-001 / 002
**内容**
- ロケット発射時：Export終端ログ + Move活動記録ログ
- 30分イベント：Plan生成ログ
- 1分イベント：Step実行ログ

**対応テスト**
- 現状：ログをassertしない方針（TestPlan準拠）  
  ただし “沈黙防止/原因特定” の要件があるため、仕様としては残る。

**判定**
- ❌ 未カバー（意図的）

**残タスク**
- 90_Observability.md に従って「ログ要件をどこまでテスト対象にするか」方針決め（P3）
  - “ログ存在のみ” を副オラクルとして最小テストにする案はあり得る

---

# 5. 残タスク総覧（02起点）

### P2（仕様として未検証・効果が大きい）
- PP-IMP-001: Importable=false の dest 無効（SKIP）テスト
- PP-SPEC-001: planet別（Vulcanus/others）の標準/alt選定テスト
- MOV-PLAN-001: “30分以内/超過” 境界テスト
- MOV-ELIG-001: evo閾値境界テスト（fatal以外）

### P3（方針次第）
- ドロップポリシーを仕様に残すならテスト化（そうでなければプレイテスト扱い明記）
- MOV-IMP-001（create+destroy）をどこまで保証するか
- 観測ログ要件（OBS-REQ-001/002）をテストで扱うか

---

# 6. 総括
- defeated / Export条件 / Export連動 / Move実行の骨格は強くカバー済み
- 残りは「planet別ポリシー（species/Importable）」と「時間境界（30分判定）」が主
- 観測ログは、方針が決まれば最小の補助テスト化は可能