# Planet Profile & Scheduling Model

docs/SystemSpecification/02_PlanetStateModel.md（Draft v0.1）

## 0. 本書の位置づけ

本書は、惑星（surface）単位で管理される状態を、
「状態機械」ではなく 複数の独立したフラグ・進行状況・スケジューラとして定義する。

本書で定義されない暗黙フラグ・暗黙分岐は禁止する。

## 1. 用語
 - trigger_surface：ロケット発射が起きた惑星
 - dest_surface：輸出（侵略拡散）の輸入先として選定される惑星（完全ランダム）
 - Export：ロケット発射を契機に「輸出イベント」を評価・実行する処理
 - Move：ロケット発射を契機に計画され、1分ごとに実行される惑星内移動処理
 - Defeated：その惑星で「デモリッシャーを1体以上撃破した」事実

## 2. 惑星プロファイル（Planet Profile）
### PP-DEF-001: Defeated Flag（撃破済みフラグ）
 - 定義：その惑星上で デモリッシャーを1体以上撃破した場合 true
 - 用途：Export の発生条件に利用される

#### 保存
 - storage.manis_boss_demolisher_flag[surface_name].defeated = true|false

### PP-IMP-001: Importable（輸入可能）
 - 定義：プレイヤーが到着し、surfaceが生成されている惑星は Importable である
 - 判定：game.surfaces[<surface_name>] ~= nil を満たすこと

※ Importable は永続化しなくてよい（再計算可能）。

#### 保存

storage.manis_boss_demolisher_flag[surface_name].importable = true|false
あるいは importable は再計算可能なら保存しない（要決定）

### PP-SPEC-001: Species Policy（種別選定ポリシー）

 - Vulcanus：標準種（default）
 - その他惑星：-alt 種
#### 副作用（ドロップポリシー）

 - 標準種：タングステン豊富な死骸（Factorio公式通り）
 - -alt 種：鉄鉱石・銅鉱石・少量タングステンの死骸（タングステン拡散抑止）

※このドロップ差は “種別選定” の仕様に含める。

## 3. Export（輸出イベント）モデル
### EXP-TRG-001: Export is evaluated on every rocket launch
 - ロケット発射ごとに Export は必ず評価される（確率抑止しない）
 - ただし、評価結果が「実行なし（SKIP）」になり得る（条件不一致・上限等）

#### 観測点（必須ログ）

 - ExportEval OK|SKIP|FAIL
 - trigger_surface / dest_surface / reason

### EXP-TRG-002: Export eligibility by trigger_surface

 - Export はロケット発射ごとに必ず評価される（EXP-TRG-001）
 - 実行対象（輸出試行）になる条件：
   - trigger_surface が Vulcanus の場合：常に対象
   - trigger_surface が Vulcanus 以外の場合：Defeated=true のときのみ対象

### EXP-DEST-001: Destination candidate set

 - 抽選候補は常に以下の5惑星：
   - nauvis, gleba, fulgora, vulcanus, aquilo

### EXP-DEST-002: Random pick first, validate after

 - dest_surface は上記固定集合から 完全ランダムに抽選する
 - 抽選後、dest_surface が 有効であるか評価し、輸出成否を確定する

#### 目的

 - 序盤に「有効な惑星が少ない」状態でも、抽選が少数惑星に過度集中しないようにする

### EXP-DEST-003: Destination validity

 - dest_surface が有効である条件：
   - Importable（PP-IMP-001）を満たすこと（surfaceが生成されていること）
   - その他、輸出不能条件があればここに追加（※01で列挙）

### EXP-SEL-001: One entity is selected per export execution
 - 1回の Export 実行で、輸出されるデモリッシャーは常に 1体
 - 複数体の同時輸出は行わない

### EXP-PROG-001: Per-dest progressive unlock order
 - 選定される1体は、dest_surfaceごとに 進行フラグで管理される
 - 原則：
   - 弱いデモリッシャーから順に輸入される（解禁）
   - 全部解禁されたら完全ランダム

#### 保存（候補）

 - storage.manis_boss_demolisher_flag[dest_surface].import_progress = {...}

### EXP-QUAL-001: First-of-type is normal, later are evo-based random quality

 - 各種類について：
   - その種類の 最初の1体は品質 normal
   - 2体目以降は evo 依存のランダム品質

### EXP-EVO-001: evo reference is dest_surface

 - Export において evo を参照する箇所（品質・Cap）は dest_surface の evoを用いる
 - trigger_surface の evo を用いる実装は バグとみなす

### EXP-EVO-002: evo does not affect unlock progression

 - evo は解禁（weak→strongの順の進行）には影響しない
 - 解禁は dest_surface ごとの進行フラグ（EXP-PROG）にのみ依存する

#### 適用範囲

 - 品質決定（EXP-QUAL）
 - Cap判定（EXP-CAP：01で定義）
 - 解禁（EXP-PROG）には適用しない

## 4. Move（惑星内移動）モデル
### MOV-TRG-001: Rocket launch marks “recent rocket activity”

 - ロケット発射があると、trigger_surface に「直近ロケット発射」が記録される

#### 保存（候補）

storage... [surface].last_rocket_tick

### MOV-PLAN-001: 30min scheduler builds a move plan if recent rocket activity exists

 - 30分イベントで以下を判定する：
   - 「過去30分以内にロケット発射があったか」
 - あった場合、MovePlan を生成する（計画作成）

### MOV-EXEC-001: 1min scheduler executes plan step by step

 - 1分イベントで MovePlan を1ステップ進める
 - ステップは 小領域単位（セル単位）で対象デモリッシャーを抽出し移動する

### MOV-ELIG-001: Move eligibility depends on evo and class

 - 移動可能性は evo に依存する
 - Fatal系は 移動しない（常に対象外）

※ “Fatal/Combat分類” の定義は 04_BossClasses.md 側で確定する

### MOV-IMP-001: Teleport is not used; move is create+destroy based

 - デモリッシャーは .teleport を受け付けない
 - よって移動は create+destroy により実現される（warp）

## 5. 観測（Observability）要件（本書の最低限）
### OBS-REQ-001: Every rocket launch produces terminal logs for both Export and Move trigger

 - ロケット発射時に、少なくとも以下をログ出力できること：
   - Export の評価結果（OK/SKIP/FAIL）
   - Move の“ロケット活動記録”更新

### OBS-REQ-002: Scheduled jobs produce terminal logs
 - 30分イベント：
   - Plan生成の有無（OK/SKIP/FAIL）＋理由
 - 1分イベント：
   - Step実行結果（moved count / step / plan status）

※ ログフォーマットは 90_Observability.md で確定する

