# Observability Specification  
`docs/SystemSpecification/90_Observability.md`

**Version:** v1.0 (confirmed)  
**Scope:** Manis Boss Demolisher

---

## 0. 本書の位置づけ

本書は、Manis Boss Demolisher における  
**ゲーム挙動を観測可能にするためのログ・観測点仕様**を定義する。

本プロジェクトでは、

- 低レイヤーの単体テストは原則作成しない
- 代わりに、**仕様単位で合否が判断できる観測点**を必須とする

テストは、本書で定義された観測点を根拠として実施される。

---

## 1. 観測の基本方針

### OBS-POL-001: Every evaluated system must terminate visibly
以下のシステムは、必ず **終端ログ**を出力しなければならない：

- Export（侵略拡散）
- Move のスケジューリング（30分イベント）
- Move の実行（1分イベント）

「何も起きなかった」場合も、**SKIP として明示**する。  
沈黙は不正とみなす。

---

### OBS-POL-002: Outcome is classified into three states
すべての観測対象処理は、以下のいずれかで終端する：

- `OK`   : 仕様どおり処理が実行された
- `SKIP` : 条件不一致・上限到達などにより実行されなかった
- `FAIL` : 想定外エラー、または仕様違反

---

### OBS-POL-003: Logs are the primary oracle
- テストはログを一次情報として合否を判断する
- ログは **人間が読める**ことを優先する
- ログは **機械的に検証可能**な構造を持つ

---

## 2. ログの共通フォーマット

### OBS-FMT-001: Structured message
ログは以下の形式で出力されることを推奨する：

- モジュール名
- 処理種別
- outcome
- 主要パラメータ（key=value 形式）

**例**
[ManisBossDemolisher][Export][OK]
trigger=Vulcanus
dest=gleba
dest_valid=true
defeated=true
dest_evo=0.72
total=12 cap=40
type=manis-speedstar-small
quality=normal


※ 実際の実装は Logger 経由で配列連結でもよい。

---

## 3. Export 観測点

### OBS-EXP-001: Export evaluation log (required)

**出力タイミング**
- ロケット発射イベント処理の終了時

**必須項目**
- `outcome` : `OK | SKIP | FAIL`
- `trigger_surface`
- `dest_surface`
- `dest_valid`
- `defeated(trigger_surface)`
- `dest_evo`
- `total(dest)`
- `cap(dest)`
- `type_key`
- `quality`

**理由**
- 輸出が起きた/起きなかった理由を一目で判断できること
- CAP・evo・進行・品質の誤りを即座に検出するため

---

### OBS-EXP-002: Export skip reason
`SKIP` の場合、以下の理由コードを併記する：

- `ELIGIBILITY_FAILED`
- `DEST_INVALID`
- `CAP_REACHED`
- `NO_PROGRESS_AVAILABLE`
- `MESSAGE_RATE_LIMIT`
- その他（明示的に追加）

---

## 4. Move（30分スケジューラ）観測点

### OBS-MOV-SCH-001: MovePlan scheduling log (required)

**出力タイミング**
- 30分イベント処理の終了時

**必須項目**
- `outcome` : `OK | SKIP | FAIL`
- `surface`
- `recent_rocket_activity` : true | false
- `plan_created` : true | false
- `range_count`

**理由**
- 移動が起きなかった理由（ロケット未発射など）を明確にする

---

## 5. Move（1分実行）観測点

### OBS-MOV-EXEC-001: Move step execution log (required)

**出力タイミング**
- 1分イベントごと

**必須項目**
- `outcome` : `OK | SKIP | FAIL`
- `surface`
- `step_index`
- `range_index`
- `eligible_count`
- `moved_count`
- `remaining_steps`

**理由**
- 「移動しない」「途中で止まる」「過剰に移動する」を検出するため

---

### OBS-MOV-EXEC-002: Skip reason
`SKIP` の場合、以下の理由コードを併記する：

- `NO_PLAN`
- `NO_ELIGIBLE_ENTITY`
- `RANGE_EMPTY`
- `CAP_LIMIT`
- その他（明示的に追加）

---

## 6. Defeated フラグ観測

### OBS-DEF-001: Defeated flag update log

**出力タイミング**
- デモリッシャー撃破時

**必須項目**
- `surface`
- `entity_name`
- `type_key`
- `new_defeated_state=true`

**理由**
- Export の可否判定の根拠を追跡可能にするため

---

## 7. RNG 観測（任意だが推奨）

### OBS-RNG-001: RNG usage trace (debug level)

- 使用する乱数源は DeterministicRandom のみ
- 以下の情報をデバッグレベルで出力してよい：
  - 使用箇所（Export / Move / Quality）
  - 使用回数 or シード情報（可能な範囲で）

※ 通常ログでは必須ではないが、  
　決定性崩れの調査時に有効。

---

## 8. 観測点追加のルール

### OBS-RULE-001: New behavior requires new observability
- 新しい仕様・分岐を追加する場合：
  - それを観測できるログ項目を必ず追加する
- 観測できない挙動は、**テスト不能**とみなす

---

## 9. テストとの関係

- 本書で定義された観測点は、
  `99_TestPlan.md` における **合否判定の根拠**となる
- 観測点の無い仕様は、テスト対象にしてはならない

---

### まとめ

Manis Boss Demolisher において、

> **ログはデバッグ用ではなく、仕様の一部である。**

本書は、その前提を明文化するための文書である。

---