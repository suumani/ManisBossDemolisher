# 10_RefactorAndReviewPolicy_Lua.md
Status: ACTIVE
Scope: Manis 全 Lua 実装（レビュー・改善段階で必ず参照）
Purpose:
実装を「動く」状態から「第一線で運用できる整合構造」へ引き上げる。
局所最適や最短実装への逃避を防ぎ、プロジェクト全体整合を維持する。

---

# 0. 基本方針

- 局所合理性よりも **全体整合** を優先する。
- 「最小で効く」ではなく「構造として持続可能か」を評価軸とする。
- コードの見た目よりも、**責務・契約・境界の一貫性**を重視する。
- 判定不能な規約は規約として無効とみなす。

---

# 1. アーキテクチャ整合ゲート（最優先）

以下を満たさない場合、差し戻しとする。

---

## 1.1 ContractDTO契約（必須）

DTOは2種類に分類する：

- **ContractDTO（契約DTO）**
- RunContext（実行文脈）

ContractDTOのみが「契約」として扱われる。

### ContractDTO定義要件（必須）

1. metatableを持つ
2. 唯一の生成関数（`<Name>DTO.new()`）経由のみ生成
3. Constructor内でvalidateを実行
4. validate失敗はerror()
5. 直table生成禁止
6. 完全immutable（top-level変更禁止）
7. 更新は copy-on-write API のみ（with_*）
8. 参照共有による破壊が起きない構造

違反は差し戻し。

---

## 1.2 ContractDTO必須領域（RunContext禁止）

以下の用途では ContractDTO を必須とする：

- UseCase入力
- UseCase出力（ResultDTO）
- Service/Store/Executor の公開API境界
- 永続化対象
- ジョブpayloadの正規化結果
- 2箇所以上で参照されるデータ形

上記に RunContext を使用した場合、即差し戻し。

---

## 1.3 RunContext規約（制限付きmutable）

RunContextは以下を満たす場合のみ許可：

1. runスコープ限定（外部へ渡さない）
2. 公開APIの引数にしない
3. 永続化しない
4. world/storage状態を保持しない（キャッシュは可）
5. キーは固定（未定義キー禁止）
6. mutable領域は `ctx.cache` / `ctx.state` 等に限定

RunContextは契約ではない。
契約の代替として使用してはならない。

---

## 1.4 ResultDTO固定構造


{
ok: boolean,
result: "OK" | "SKIP" | "FAIL",
reason?: "CATEGORY:DETAIL",
detail?: table,
}


- OK/SKIP → ok=true
- FAIL → ok=false
- reasonは必ずカテゴリ付き

ログはResultDTOを反映するのみ。
ログの自由構造は禁止。

---

## 1.5 責務境界

- Handler：オーケストレーションのみ
- Planner：計算のみ
- Executor：実行のみ
- Store：状態保持のみ
- ログ整形はboundary
- domainはboundaryへ依存しない

---

## 1.6 DTO回避防止ゲート

以下を検出した場合、即差し戻し：

- 共有データがtableのまま
- payload正規形がtableのまま
- RunContextをAPI境界で使用
- 複数箇所で参照される形がDTO化されていない

---

# 2. 操作単位規約

順序固定：

1. 前提確定（DTO検証済）
2. 計算（Planner）
3. 実行（Executor）
4. 状態更新（Store）
5. ResultDTO生成
6. ログ整形（boundary）

例外は予約/commit分離のみ許可。

---

# 3. error() 使用規約

error() は前提違反のみ。
業務的失敗は ResultDTO。

---

# 4. 境界コスト契約

- snapshotはrun内1回
- world検索禁止箇所明文化
- 反復内 surface.find_* 禁止

---

# 5. 純粋ロジック隔離（RG-1）

座標・距離・集合演算は副作用禁止。
logic/ 配下に隔離。

---

# 6. 計算量ポリシー（RG-2）

- N×Mは上限宣言必須
- 無制限探索禁止
- index化優先

---

# 7. Replace作法（RG-4）

- 旧経路は同一チケット内で削除
- 移行中はstub化＋error("DEPRECATED_PATH")
- 薄いラッパ共存禁止

# 8. ResultDTO 生成の共通化（RG-5）

- ResultDTO の生成は原則として共通モジュール `ResultDTO` を使用する。
- 目的は「生成形の揺れ防止」であり、ログ整形や event 名の共通化は含めない。
- 新規・改修箇所では `ResultDTO.ok/skip/fail` を用いる。
- 例外的に各ファイルで dto_ok 等を定義してよいが、レビューでは `ResultDTO` への置換を優先する。

---

# 9. レビュー原則

1. Gate違反は即差し戻し
2. DTO回避は許容しない
3. 判定不能は規約不足として規約を修正
4. 局所最適を許容しない


---

# 結論

ContractDTOは完全immutable。
RunContextは限定mutable。
契約と実行文脈を混同しないこと。

AIとのタイアップ前提において、
契約は構造で守る。

# 補足
surface.find_entities_filtered の濫用禁止。１イベントにつき、Handlerで1回の実行までが許容

# やりすぎ基準

原則：domain は ResultDTO固定（{ok,result,reason?,detail?}）
- 境界ログの例外：観測のため、ログメッセージは
{ event: string, dto: ResultDTO } の1形だけ許可（自由構造は禁止）
- event は “観測ラベル” であって契約ではない
- dto が契約の全て

## 暗黙の想定
- モジュール境界を越える形のみDTO必須
- 同一ファイル内の一時構造は許可
- ロジック層までDTO強制すると過剰になります
- その他、試行の補助にならず、設計ポリシーを優先するために設計コスト/処理コストが大きく増加するものは避ける

## factorioの前提
Factorio API 2.0 で開発しており、存在する関数に対するチェックと、存在未確認の関数利用は禁止

悪い例： is_chunk_generatedを仮定で実装している(実在するのに)、かつ、不存在だったときに握りつぶされかねない実装
```
if type(surface.is_chunk_generated) == "function" then
  return surface.is_chunk_generated(chunk_pos) == true
end
return false
```
## 頻発バグの注意

id 生成を乱数で行ってはならない
storage領域の変数にfunctionを設定してはならない