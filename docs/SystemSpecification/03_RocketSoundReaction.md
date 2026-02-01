0. 本書の位置づけ

本書は、ロケット発射を契機として発生する 惑星内移動（Move） の仕様を定義する。
Export（侵略拡散）の詳細は 01_InvasionExport.md を参照する。

本書は **ゲーム挙動（移動が起きる/起きない/どの程度起きる）**を定義する一次資料である。

1. 基本概念

Move は 輸出（Export）とは独立した処理系である

ロケット発射は、以下2つを同時に引き起こし得る：

Export の評価・実行

Move のスケジューリング

2. トリガとスケジューリング
MOV-TRG-001: Rocket launch records recent activity

ロケット発射が発生すると、対象惑星に「直近ロケット発射」が記録される

保存候補

storage.<mod>.<surface>.last_rocket_tick

MOV-SCH-001: 30-minute scheduler builds a MovePlan

30分イベント（nth_tick）において、以下を判定する：

過去30分以内にロケット発射があったか

条件を満たす場合：

惑星全体を Range（セル）に分割

MovePlan を生成する

目的

ロケット発射に対する「即時反応」ではなく、
遅延・波及的な脅威として表現するため

MOV-SCH-002: No recent rocket activity means no plan

過去30分以内にロケット発射が無い場合：

MovePlan は生成されない

MOV-SCH-003: Plan lifetime and regeneration

MovePlan は 全Range処理完了で自動破棄される

MovePlan は 30分以内に完了しなければならない（完了が要件）

30分イベントごとに、新しい MovePlan を 新規生成する
（過去Planの継続・マージは行わない）

3. 実行モデル（1分ステップ）
MOV-EXEC-001: 1-minute scheduler executes MovePlan step

1分イベント（nth_tick）で、MovePlan を 1ステップずつ実行する

各ステップは 小領域（Range/Cell）単位

MOV-EXEC-002: Full surface coverage by ranges

MovePlan は惑星全体を 漏れなくカバーする Range 群で構成される

各 Range は 一度だけ処理される

4. 移動対象の選定
MOV-ELIG-001: Eligibility by class

Combat系デモリッシャー：移動可能

Fatal系デモリッシャー：移動不可（常に対象外）

※ Combat/Fatal の定義は 04_BossClasses.md を参照

MOV-ELIG-002: Eligibility by evo

Combat系デモリッシャーは、evoに依存して段階的に移動可能となる

evoが上昇するにつれ：

移動可能な種類・個体が増加する

最終段階では、Combat系は すべて移動可能

MOV-ELIG-003: Fatal class is immobile by design

Fatal系は 襲ってくる敵ではない

Fatal系は 地形制約レベルの脅威として定義される

よって、Moveの対象外とする（移動しない）

5. 移動量と距離
MOV-DIST-001: Move distance depends on evo

移動距離は evo に依存して増加する

MOV-DIST-002: Distance is randomized deterministically

移動距離は ランダムに決定される

乱数源は DeterministicRandom（LuaRandomGenerator）

同一条件下では結果は再現可能

6. 上限と抑止
MOV-CAP-001: Per-plan move limit

1つの MovePlan あたり、移動するデモリッシャーの総数には上限がある

上限値は別紙で定義（数値は本書では固定しない）

7. 実装制約（仕様としての前提）
MOV-IMP-001: Teleport is not used

デモリッシャーは .teleport を受け付けない

移動は create + destroy によって実現される

※ 本仕様は実装制約だが、挙動に影響するため仕様として明記する

8. 観測（Observability）
OBS-MOV-001: Move scheduling is observable

30分イベントにおいて、以下がログで観測できること：

recent rocket activity の有無

MovePlan 生成の有無（OK/SKIP/FAIL）

OBS-MOV-002: Step execution is observable

1分イベントごとに、以下がログで観測できること：

対象Range

対象個体数

移動成功数

残りステップ数

9. 未決事項 / 後続文書

Range 分割方式（矩形/チャンク/動的）

evo → 移動解禁の具体テーブル

上限値（MOV-CAP-001）の具体数値

これらは 99_TestPlan.md または補助仕様で確定する。

10. 本書の更新ルール

Move の挙動を変更する場合、本書を必ず更新する

Export 仕様との関係が変わる場合、01_InvasionExport.md も同時更新する