# Boss Classes & Demolisher Taxonomy

docs/SystemSpecification/04_BossClasses.md
Version: v1.0 (confirmed)

## 0. 本書の位置づけ

本書は、Manis Boss Demolisher における デモリッシャーの分類体系（Taxonomy）と強さの定義を規定する。

本分類は以下の仕様の 一次根拠となる：
 - Invasion Export（輸出個体の選定・進行・初回normal・品質ロール）
 - Rocket Sound Reaction / Move（移動可否・evo依存）
 - Defeated 判定（撃破の対象範囲）
 - ドロップポリシー（標準種 / -alt 種）
 - CAP 判定における「生存デモリッシャー総数」の対象定義

本書に定義されない 暗黙の分類・強さ比較・例外処理は禁止する。

## 1. 用語定義（Terminology）
### TAX-TERM-001: default

 - Factorio公式（Space Age core）で提供される 3種のみを指す。
   - small-demolisher
   - medium-demolisher
   - big-demolisher

### TAX-TERM-002: normal

 - Factorioにおける標準的な進化ラインを指す概念。
 - 本Modでは以下を含む：
   - small / medium / big
   - behemoth（本Modが追加）

### TAX-TERM-003: additional

 - 本Modが追加した、標準進化ラインを拡張する系列。
 - 例：
   - manis-normal 系
   - speedstar 系

### TAX-TERM-004: fatal

 - サイズ・速度・地形影響が過剰であり、 通常の再配置・繁殖・移動ロジックに適さない系列。
 - 本Modでは以下を指す：
   - gigantic 系
   - crazy-king 系

※ 上記用語は歴史的経緯により残す（後方互換目的）。

## 2. 分類の基本軸
### TAX-AXIS-001: Combat vs Fatal

 - Combat
   - 戦闘対象として成立するデモリッシャー
   - Move（惑星内移動）の対象になり得る
 - Fatal
   - 襲ってくる敵ではなく、地形制約レベルの脅威
   - Move の対象外（移動しない）

### TAX-AXIS-002: Planet species policy（標準 / -alt）
 - Vulcanus：
   - 標準種（non--alt）を使用
 - その他惑星（Nauvis / Gleba / Fulgora / Aquilo）：
   - -alt 種を使用

#### 目的

 - タングステン入手難度の制御
 - タングステンの無制限拡散を防止する

## 3. 強さの同等性と系列間関係
### TAX-POWER-001: Strength equivalence

以下は 完全に同等の強さとみなす：

 - manis-small-demolisher ≡ small-demolisher
 - manis-medium-demolisher ≡ medium-demolisher
 - manis-big-demolisher ≡ big-demolisher
 - -alt 種は non--alt と 強さ完全同等
   - 差分は corpse / drop のみ

### TAX-POWER-002: Series hierarchy (relative strength)

同サイズ帯における系列間の強さ関係は以下：

```
default / manis-normal
        < speedstar
        < gigantic
        < king
```

### TAX-POWER-003: King supremacy

 以下が常に成り立つ：

```
manis-gigantic-behemoth-demolisher
    < manis-crazy-gigantic-king-demolisher
manis-speedstar-behemoth-demolisher
    < manis-crazy-gigantic-king-demolisher
```

（-alt も同様）

## 4. 系列ごとの内部強さ順
### 4.1 default / manis-normal 系
```
small < medium < big < behemoth
```
 - behemoth は本Modが追加する上位段階

### 4.2 speedstar 系（Combat）
```
speedstar-small
  < speedstar-medium
  < speedstar-big
  < speedstar-behemoth
```

### 4.3 gigantic 系（Fatal）
```
gigantic-small
  < gigantic-medium
  < gigantic-big
  < gigantic-behemoth
```

### 4.4 king 系（Fatal）
 - crazy-gigantic-king は 単一段階
 - 全デモリッシャー中の最上位

## 5. Name Sets（仕様上の集合）
### TAX-SET-001: ALL

 - 本Modが扱う すべてのデモリッシャー

### TAX-SET-002: ALL_COMBAT

 - Combat 系デモリッシャーの全集合

### TAX-SET-003: ALL_FATAL

 - Fatal 系デモリッシャーの全集合

### TAX-SET-004: ALL_BOSS

 - 「ボス扱い」として特別な制御を受ける集合
 - 徘徊範囲制限などに使用される

## 6. Exportにおける「種類（Type Key）」定義
### TAX-TYPE-001: Purpose of Type Key

Type Key は以下の仕様を実現するために用いられる：
 - 各種類の 最初の1体は Quality=normal
 - 2体目以降は品質ロールを行う

### TAX-TYPE-002: Type Key definition (confirmed)

 - Type Key は alt/non--alt を統合する
 - 定義：
```
type_key = base_name(entity_name)
```
 - base_name は -alt サフィックスを除去した名称

#### 例

 - manis-speedstar-small-demolisher
 - manis-speedstar-small-demolisher-alt
→ 同一 Type Key

### TAX-TYPE-003: Rationale

 - -alt は資源ドロップ差分のための派生であり、強さ・進行・品質に影響させるべきではない
 - Type Key を統合することで、「初回normal」が二重に発生することを防ぐ

## 7. Export進行（Unlock Progression）

### TAX-PROG-001: Progression scope
- 進行（解禁）は **dest_surface ごと**に管理される
- evo は進行に影響しない

### TAX-PROG-002: Baseline policy
- 本Modでは、公式 default demolisher は **制御対象に含めない**
- 輸出・移動・品質・進行のすべては、
  **manis 系 demolisher を基準として定義する**
- manis-small / medium / big は、
  公式 default small / medium / big と **同等強度の置換ライン**である

---

### TAX-PROG-003: Combat progression (manis-normal baseline)

#### COMBAT-T1: manis-normal line
- `manis-small-demolisher`
- `manis-medium-demolisher`
- `manis-big-demolisher`
- `manis-behemoth-demolisher`

※ 同一ライン内では、強さは常に  
`small < medium < big < behemoth` を満たす。

---

### TAX-PROG-004: Combat progression (speedstar)

#### COMBAT-T2: speedstar line
- `manis-speedstar-small-demolisher`
- `manis-speedstar-medium-demolisher`
- `manis-speedstar-big-demolisher`
- `manis-speedstar-behemoth-demolisher`

※ speedstar 系は、manis-normal 系より **常に上位**である。

---

### TAX-PROG-005: Fatal progression

#### FATAL-T1: gigantic line
- `manis-gigantic-small-demolisher`
- `manis-gigantic-medium-demolisher`
- `manis-gigantic-big-demolisher`
- `manis-gigantic-behemoth-demolisher`

#### FATAL-T2: king
- `manis-crazy-gigantic-king-demolisher`

※ king は全デモリッシャー中の最上位とする。

## 8. Moveにおける可否
#### MOV-CLASS-001: Move eligibility

 - Move 対象：
   - ALL_COMBAT
 - Move 対象外：
   - ALL_FATAL

#### 理由
 - Fatal 系は襲ってくる敵ではなく、
地形制約レベルの存在として設計されている

## 9. Defeated フラグにおける「撃破」対象
### DEF-SCOPE-001: Defeated definition

 - Defeated=true は、
   - その惑星で
   - DemolisherNames.ALL に属するデモリッシャーを
   - 1体でも撃破した場合に成立する

## 10. 本書の更新ルール
 - 分類・強さ順・Tier の変更は慎重に行う
 - 変更時は必ず：
   - 01_InvasionExport.md
   - 03_RocketSoundReaction.md
への影響を確認・反映する

## まとめ

本書は、Manis Boss Demolisher における
**「何が強く、何が動き、何が最初に現れるか」**を一意に定める。

他の仕様は、本書の分類と強さ定義を 前提条件として設計されなければならない。