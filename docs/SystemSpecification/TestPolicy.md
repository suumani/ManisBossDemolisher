# TestPolicy.md  
テスト方針（Manis Mods 共通）

**Status:** draft（共通ポリシー）  
**Scope:** Manis エコシステム内でテストフレームワークを採用するすべての Mod  
**Purpose:**  
本書は「テストを *どう設計し、どう実行し、どう合否判断するか*」を定義する。  
**テストケース一覧ではない。**

---

## 0. 基本原則（例外なし）

### POL-001: ワールド状態が第一級オラクル
テストの合否判定は、**ログではなくワールド状態**を第一に用いる。

ワールド状態の例：
- 物理エンティティ  
  `surface.find_entities_filtered` / `LuaEntity.valid` / 個体数 / 座標
- 仮想エンティティ  
  `VirtualEntityManager` のストア / 件数 / ID / 座標

ログは **補助情報**であり、以下の目的に限定される：
- 無音終了の防止
- SKIP / FAIL の理由説明
- 回帰時の原因追跡

---

### POL-002: テストは仕様から導出される
テストは必ず `SystemSpecification`（または同等仕様）の **Spec ID** に基づいて作成する。

- すべてのテストケースは 1 つ以上の Spec ID を参照する
- 観測可能な受け入れ条件が書けない仕様は「未完成」
- 実装からテストを逆算してはならない

---

### POL-003: パック単位テスト
テストは **Test Pack（シナリオ集合）**として構成する。

- Pack は初期条件・実行手順・オラクルを定義する
- Pack は回帰とリリース判断の単位である
- 単発テストの寄せ集めは禁止

---

### POL-004: 決定論優先、確率論は最終手段
以下の **決定論的手段**を優先する：

- destination 固定
- pick 固定
- evo override
- cap override
- quality roll override
- spawn position override（テスト専用）

確率吸収（N 回試行）は、
- 一発観測が原理的に不可能な場合のみ許可
- Spec ID と受け入れ条件を必須とする

---

### POL-005: テスト協調は明示的・集中管理
プロダクションコードはテスト状態を直接参照してはならない。

- テスト協調の窓口は **TestHooks のみ**
- TestConfig は「期待条件」を表す（実行状態ではない）
- TestRuntime が有効化・Pack 識別を管理する

---

### POL-006: 終端結果は必須
すべての評価処理は、必ず以下のいずれかで終了する：

- `OK`   : ワールドが仕様通り変化した
- `SKIP` : 条件未達 / 上限 / 位置未確定など
- `FAIL` : 想定外エラー / 不変条件違反

**無音終了はバグとみなす。**

---

## 1. ドキュメントの役割と優先順位

### 1.1 ユーザー向け仕様
`spec.md` / `spec.ja.md`

- プレイヤー体験の意図
- 目的 / 非目的
- なぜこの Mod が存在するのか

---

### 1.2 SystemSpecification（テストの根）
`docs/SystemSpecification/*.md`

- 状態モデル
- 遷移条件
- 境界条件
- 不変条件
- 観測要件（ログ含む）

**テストの唯一の正規情報源**

---

### 1.3 設計メモ（非規範）
`docs/DesignNotes/*`

- 実装制約
- 却下案
- 思考履歴

※ テストの根拠にはならない

---

### 優先順位（衝突時）
1. `spec.md` / `spec.ja.md`
2. `SystemSpecification`
3. `DesignNotes`

---

## 2. テスト基盤（標準構成）

`tests/infrastructure` に以下を置く：

### TestRuntime
- テストモード有効/無効
- 現在の Pack ID
- スケジューラ override 管理

### TestConfig
- Pack 単位の決定論ノブ
- dest / pick / cap / evo / roll override
- （必要に応じて）spawn position override

### TestHooks
- プロダクションコードが参照可能な **唯一のテスト窓口**
- テスト無効時は必ず nil / default を返す

### WorldOracle
- ワールド観測の正規 API
- physical / virtual 両対応
- snapshot / diff ヘルパー

### TestBootstrap
- Pack 開始 / 終了処理
- テスト専用 transient のみ安全に初期化

---

## 3. テストモード分類

### MODE-001: コマンド駆動（決定論）
- 即時実行
- override 多用
- オラクルはワールド状態

---

### MODE-002: Tick 駆動（実環境）
- 実イベントフローを通す
- scheduler override を併用

---

### MODE-003: ハイブリッド
- 前半を決定論で構築
- 後半を自然進行で検証

---

### MODE-004: 確率吸収（制限付き）
- 一発観測が不可能な場合のみ
- 試行回数と合格条件を仕様に明記

---

## 4. ログ方針（観測性）

### LOG-001: INFO と DEBUG の二層
- **INFO** : リリース可 / 主動線 / 低頻度
- **DEBUG**: 調査用 / 高頻度

---

### LOG-002: 推奨 INFO イベント（共通）

1) **トリガー**
- Rocket launch / command / scheduler tick
- surface / position / tick / gate 情報を含む

2) **終端結果**
- `[X][Result]` / `[X][Skip]`
- 必ず `OK | SKIP | FAIL`
- SKIP は reason を必須

3) **ワールド変化**
- spawn（phy / virt, 座標）
- move（from / to, mode）
- materialize（virt → phy）

---

### LOG-003: 構造化フォーマット
grep 可能な安定トークンを使用：

- `[Export][Result] dest=... kind=phy name=... pos={x,y}`
- `[Move][Step] surface=... mode=phy->virt from={...} to={...} vid=...`

---

### LOG-004: 終端無音禁止
gate / cap / position 失敗などは、
INFO 以上で必ず観測できなければならない。

---

## 5. スポーン位置ポリシー

### POS-001: 位置選定は第一級ロジック
位置が確定できない場合：

- `SKIP reason=no_valid_position`
- INFO ログ必須

---

### POS-002: 密度制約は仕様事項
密度・距離制約（特に Fatal 系）は：

- SystemSpecification に明記
- テストで検証

実装にしか存在しない制約は **仕様漏れ**とみなす。

---

## 6. 仮想エンティティ方針

### VIRT-001: 未生成エリアの安全表現
未生成チャンクでは：

- 物理生成を行わない
- VirtualEntity として保持

---

### VIRT-002: 実体化は観測可能であること
chunk_generated 時：

- 仮想 → 物理変換
- INFO ログ出力
- virtual entry 削除

---

### VIRT-003: 双方向テスト必須
最低限以下を含める：

- ungenerated → virtual
- generated → physical
- 同一座標での virt → phy 切替

---

## 7. 知識汚染防止（重要）

### HYG-001: Mod ごとの独立性
- 他 Mod の挙動を暗黙前提にしない
- 共通なのはフレームワーク思想のみ

---

### HYG-002: ドキュメントが弱い Mod の進め方
1. Pack の目的を文章で固定
2. オラクルを文章で固定
3. 最低限の INFO ログ追加
4. その後にテストと修正

---

## 8. Pack テンプレート（必須）

各 Pack は以下を定義する：

- Pack 名
- 目的 / 非目的
- 主オラクル
- 初期条件
- 実行手順
- 受け入れ条件
- 対応 Spec ID
- 想定 INFO ログ

---

## 9. 変更ルール

### CHG-001: 挙動変更はドキュメントと同時
- プレイヤー体験が変わるなら spec 更新
- SystemSpecification 更新
- Pack 更新

---

### CHG-002: テストが書けない仕様は未完成
アドホックな assert で誤魔化さない。  
まず観測点を追加する。

---

## Appendix A: 最小 Pack 推奨手順

レガシー Mod での最初の一歩：

1. トリガーを 1 つ決める
2. 終端ログを必ず出す
3. WorldOracle snapshot/diff を作る
4. OK / SKIP を証明する Pack を 1 つ書く

これが安全な出発点になる。

---