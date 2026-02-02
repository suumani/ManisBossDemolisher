# Boss Classes & Demolisher Taxonomy – Spec Coverage Matrix (Updated)
`docs/SystemSpecification/04_BossClasses.md` (v1.0 confirmed)

**Test Status:** ver.0.1.6  

---

## 1. 用語定義（Terminology）

### TAX-TERM-001: default（公式3種）
**判定**
- N/A（用語定義）

---

### TAX-TERM-002: normal（small/medium/big/behemoth）
**対応テスト**
- PACK-EXPORT-PROGRESSION（pool-only）
- PACK-EXPORT-PROGRESSION-WORLD（world連鎖）

**判定**
- ✅ 進行（解禁）文脈として実質カバー  
- ※「強さ同等」そのものはバランス領域（本サマリではテスト対象外扱い）

---

### TAX-TERM-003: additional（manis-normal / speedstar）
**対応テスト**
- PACK-EXPORT-PROGRESSION（pool-only）
- PACK-EXPORT-PROGRESSION-WORLD（PROG-002〜PROG-005）

**判定**
- ✅ 実質カバー

---

### TAX-TERM-004: fatal（gigantic / king）
**対応テスト**
- PACK-EXPORT-PROGRESSION（gigantic/king 解禁）
- PACK-EXPORT-PROGRESSION-WORLD（PROG-004/005）
- PACK-MOVE-SCHEDULE（MOVE-SCH-002：fatal不動）

**判定**
- ✅ 実質カバー

---

## 2. 分類の基本軸

### TAX-AXIS-001: Combat vs Fatal
**内容**
- Combat：Move対象
- Fatal：Move対象外

**対応テスト**
- PACK-MOVE-SCHEDULE：MOVE-SCH-002（fatalは動かない）
- PACK-MOVE-SCHEDULE：MOVE-SCH-003A..003D（Phys/Virの遷移別テストの前提としてCombatを扱う）

**判定**
- ✅ 核要件はカバー  
- ⚠️ ALL_COMBAT / ALL_FATAL の「集合完全性」は未スモーク

**残タスク（P3）**
- Name Sets スモーク（代表名が集合に含まれること）  
  - combat代表：manis-small(-alt), manis-speedstar-small(-alt)  
  - fatal代表：manis-gigantic-small(-alt), king(-alt)

---

### TAX-AXIS-002: Planet species policy（標準 / -alt）
**内容**
- Vulcanus：non-alt
- その他：-alt

**対応テスト**
- ❌ 直接未カバー（現行は force_pick による固定が中心）

**判定**
- ❌ 未カバー（重要）

**残タスク（P2）**
- species policy の世界挙動テスト  
  - Vulcanus trigger / 非Vulcanus trigger それぞれで  
    「同一進行段階における選定が non-alt / -alt に分岐する」ことを検証

---

## 3. 強さの同等性と系列間関係

### TAX-POWER-001/002/003
**内容**
- 強さ同等 / 系列ヒエラルキー / king最上位

**対応テスト**
- ❌ 直接未カバー

**判定**
- N/A（バランス・設計合意領域としてプレイテスト扱いが自然）
- ※ここを自動テストで保証するなら、別途「戦闘評価」仕様が必要

---

## 4. 系列ごとの内部強さ順
**対応テスト**
- 進行（解禁順序）の観点で間接的に関連（PROGRESSION系）
- 強さ比較の自動検証はなし

**判定**
- ⚠️ 進行の前提として実質カバー / 強さ自体はN/A

---

## 5. Name Sets（仕様上の集合）

### TAX-SET-001: ALL
**用途**
- Defeated判定対象
- Export/Capの total 対象

**対応テスト**
- PACK-DEFEATED-FLAG（DEF-SCOPE-001として機能）
- Export/Cap は “ALLを使っている前提” だが集合完全性は未検証

**判定**
- ⚠️ 部分カバー（用途の挙動は検証済み、集合完全性は未）

**残タスク（P3）**
- ALL 含有スモーク（主要系列の代表名が ALL に含まれる）

---

### TAX-SET-002: ALL_COMBAT / TAX-SET-003: ALL_FATAL
**対応テスト**
- MOVE-SCH-002 は fatal不動を検証（分類の効果は見ている）
- 集合の完全性は未

**判定**
- ⚠️ 部分カバー

**残タスク（P3）**
- 代表名ベースの含有スモーク（combat/fatal それぞれ）

---

### TAX-SET-004: ALL_BOSS
**対応テスト**
- ❌ 未カバー（本スレッドで依存機能のテスト未共有）

**判定**
- ⚠️ 未カバー（依存する挙動仕様があるなら、その仕様側で要件化が必要）

**残タスク（P3）**
- ALL_BOSS を参照する機能仕様（徘徊範囲制限等）が存在するなら、テスト対象を別途起票

---

## 6. Export進行（Unlock Progression）

### TAX-PROG-001: scope=dest_surface, evo非依存
**対応テスト**
- PACK-EXPORT-PROGRESSION-WORLD：PROG-006（surface独立性）
- PACK-EXPORT-QUAL：品質/evoは別軸として検証

**判定**
- ✅ 完全カバー

---

### TAX-PROG-002: baseline policy（defaultは制御対象外、manis基準）
**対応テスト**
- PROGRESSION系が manis 系のみを前提にしている（暗黙）
- 「defaultが選ばれない」こと自体の明示テストはなし

**判定**
- ⚠️ 暗黙カバー

**残タスク（P4・低優先）**
- Export/Move の選定で default が候補にならないことのスモーク

---

### TAX-PROG-003/004/005: tier構造（normal→speedstar→gigantic→king）
**対応テスト**
- PACK-EXPORT-PROGRESSION（pool-only）：PROG-001〜005
- PACK-EXPORT-PROGRESSION-WORLD：PROG-002〜006

**判定**
- ✅ 完全カバー

---

## 7. Moveにおける可否

### MOV-CLASS-001: Move eligibility（ALL_COMBATのみ）
**対応テスト**
- PACK-MOVE-SCHEDULE：MOVE-SCH-002（fatal不動）
- 03側の “evo閾値境界” は未（03の残タスク）

**判定**
- ✅ 核要件はカバー

---

## 8. Defeated フラグにおける撃破対象

### DEF-SCOPE-001: Defeated definition（DemolisherNames.ALL）
**対応テスト**
- PACK-DEFEATED-FLAG：DEF-001/002/003B

**判定**
- ✅ 完全カバー

---

# 残タスク総覧（04起点・Type Key削除後）

## P2（仕様として重要）
- TAX-AXIS-002: Planet species policy（Vulcanus=non-alt / 他=-alt）の世界挙動テスト

## P3（スモークで足りる）
- TAX-SET-001/002/003: Name Sets 含有スモーク（代表名が集合に含まれる）
- TAX-SET-004: ALL_BOSS が依存する挙動仕様の有無確認 → あればテスト起票

## P4（低優先）
- TAX-PROG-002: default demolisher が制御対象に入らないことのスモーク

---

## 総括
- 進行（tier）・fatal不動・defeated範囲は強固にテスト化済み
- 最大の未カバー領域は **planet species policy（標準/altの選定）**
