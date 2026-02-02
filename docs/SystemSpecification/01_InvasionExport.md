# Invasion Export Specification  
`docs/SystemSpecification/01_InvasionExport.md`

**Version:** v1.0 (confirmed)  
**Scope:** Manis Boss Demolisher

---

## 0. 本書の位置づけ

本書は、ロケット発射をトリガーとして発生する  
**侵略拡散（Export / Import）** の仕様を定義する。

本仕様は以下を対象とする：

- 輸出（Export）の発生条件
- 輸入先（dest_surface）の選定
- 輸入されるデモリッシャーの選定・進行・品質
- 上限（Cap）による抑止
- 観測（ログ）要件

惑星内移動（Move）の詳細は  
`03_RocketSoundReaction.md` に委譲する。

---

## 1. 用語定義

| 用語 | 説明 |
|---|---|
| trigger_surface | ロケット発射が行われた惑星 |
| dest_surface | 輸出（侵略拡散）の輸入先として選定される惑星 |
| Export | ロケット発射を契機に行われる侵略拡散評価・実行 |
| Importable | `game.surfaces[surface_name] ~= nil` を満たす惑星 |
| Defeated | その惑星でデモリッシャーを1体以上撃破した事実 |
| Type Key | 初回normal判定・品質進行に用いる種類キー |

---

## 2. Export の評価タイミング

### EXP-TRG-001: Export is evaluated on every rocket launch
- ロケット発射が発生するたびに、Export は **必ず評価される**
- 確率による評価抑止は行わない

### EXP-TRG-002: Terminal outcome required
- Export の評価は必ず以下いずれかで終端する：
  - `OK`（輸出実行）
  - `SKIP`（条件不一致・上限等）
  - `FAIL`（想定外エラー）

---

## 3. Export 実行条件（Eligibility）

### EXP-ELIG-001: Vulcanus special rule
- trigger_surface が **Vulcanus** の場合：
  - Defeated に関係なく Export 実行対象とする

### EXP-ELIG-002: Non-Vulcanus rule
- trigger_surface が Vulcanus 以外の場合：
  - **Defeated=true のときのみ** Export 実行対象とする

### EXP-ELIG-003: Defeated definition
- Defeated=true は以下を意味する：
  - その惑星上で
  - `DemolisherNames.ALL` に属するデモリッシャーを
  - **1体以上撃破**した

---

## 4. dest_surface の選定

### EXP-DEST-001: Fixed candidate set
dest_surface の抽選候補は、常に以下の **5惑星**とする：

- `nauvis`
- `gleba`
- `fulgora`
- `vulcanus`
- `aquilo`

### EXP-DEST-002: Random pick first, validate after
- 上記候補集合から **完全ランダム**に 1 惑星を抽選する
- 抽選後に、その惑星が有効かを評価し、輸出の成否を決定する

**設計意図**
- 序盤に有効惑星が少数であっても、
  抽選が特定惑星に過度集中することを避ける

### EXP-DEST-003: Destination validity
dest_surface が有効である条件は **Importable のみ**とする：

- `game.surfaces[dest_surface] ~= nil`

※ 他の無効条件は現時点では存在しない  
（追加する場合は本書に明記する）

---

## 5. 輸出個体数

### EXP-COUNT-001: Exactly one entity per export
- 1 回の Export 実行につき、輸入されるデモリッシャーは **常に 1 体**
- 同一実行で複数体を輸入しない

---

## 7. 進行（Unlock Progression）

### EXP-PROG-001: Progression scope
- 進行は **dest_surface ごと**に管理される
- evo は進行に影響しない

### EXP-PROG-002: Tier-based progression
- 進行は `04_BossClasses.md` で定義される **Tier** に従う
- 同一 Tier 内ではランダム選定
- Tier を進めると、次 Tier の候補が解禁される

---

## 8. 品質（Quality）

### EXP-QUAL-001: First-of-type is always normal
- 各 Type Key について、
- **最初の 1 体は必ず Quality = normal**
- 目的：
- Legendary 等の高品質が初回から出現し、
  難易度が破綻することを防ぐ

### EXP-QUAL-002: Subsequent quality is evo-based random
- 2 体目以降は、**dest_surface の evo** に基づいて品質をランダム決定する
- trigger_surface の evo を参照する実装は **バグ**

### EXP-QUAL-003: RNG source
- 乱数は **DeterministicRandom**
- Factorio公式の同期乱数（LuaRandomGenerator）
- `math.random` 互換 API
- 同一条件下では結果は再現可能

---

## 9. Cap（上限）

### EXP-CAP-001: Cap is evaluated on dest_surface
- dest_surface 上の **生存デモリッシャー総数**が
cap(evo) 以上の場合、新規輸入スポーンは行わない（SKIP）

### EXP-CAP-002: Total definition
生存デモリッシャー総数とは：

- dest_surface 上に存在する
- `enemy` force
- `DemolisherNames.ALL` に該当する

全個体数を指す

### EXP-CAP-003: evo reference
- cap(evo) に用いる evo は **dest_surface の evo**
- trigger_surface の evo を用いる実装は **バグ**

### EXP-CAP-004: Research-based reduction
- `ManisDemolisherOreAndProcessing` が有効な場合、
研究により cap を **最大 25% まで低下**させることができる

### EXP-CAP-005: Dual-cap model (global + fatal)

本 Mod の cap は、以下 2 種類の上限で構成される：

combat_cap：Combat + Fatal の合計上限（負荷上限）

fatal_cap：Fatal のみの上限（Fatalが増えすぎないための抑止）

両方の上限は、dest_surface 上の現在数に対して評価される。

### EXP-CAP-006: Reservation policy (Fatal slots are reserved)

本 Mod では、プレイ体験上の理由により：

Combat が先に枠を埋めてしまい Fatal が出現しない
という状況を 仕様違反とみなす。

Fatal 系は「目玉」であり、Combat 系に枠を食われて出現しない状況を防ぐ

Comat系はCombat系＋Fatal系の現在数でCombat_capが適用される
Fatal系は、Fatal系のみの現在数でfatal_capが適用される


---

## 10. メッセージ表示

### EXP-MSG-001: Export message
- 輸出（侵略拡散）を示すメッセージは
**ロケット発射時**に表示される

### EXP-MSG-002: Rate limiting
- 表示頻度は **最大で 30 分に 1 回**に抑止される

---

## 11. 観測（Observability）

### OBS-EXP-001: Required terminal log
Export 評価は必ず以下のログを出力できること：

- outcome: `OK | SKIP | FAIL`
- trigger_surface
- dest_surface（抽選結果）
- dest_valid（Importable 判定）
- defeated(trigger_surface)
- dest_evo
- total(dest) / cap(dest)
- entity_name
- quality

ログフォーマットの詳細は `90_Observability.md` に委譲する。

---

## 12. Move との関係（参照）

### REL-MOV-001: Rocket launch schedules Move
- ロケット発射は、Export に加えて
惑星内移動（Move）のスケジューリングを行う
- Move の詳細は `03_RocketSoundReaction.md` を参照する

---

## 13. 本書の更新ルール

- Export の挙動を変更する場合、本書を必ず更新する
- 変更時は以下との整合を確認する：
- `02_PlanetStateModel.md`
- `03_RocketSoundReaction.md`
- `04_BossClasses.md`

---

### まとめ

Export は  
**「ロケット発射という行為が、別惑星の世界状態を確実に変える」**  
という設計思想を、決定的かつ制御可能に実現するための中核仕様である。

---
