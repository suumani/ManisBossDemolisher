# Manis Boss Demolisher  
## Test Implementation Status Summary  
**As of:** ver.0.1.6  
**Scope:** Test infrastructure + gameplay behavior tests

---

## 0. 本書の位置づけ

本書は、Manis Boss Demolisher において  
**現在までに実装・検証済みのテスト Pack / Scenario / 基盤** を一覧化し、  
仕様書（SystemSpecification 群）に対する **テストカバレッジの現状**と  
**残タスク**を明確化するための進捗サマリーである。

---

## 1. テスト基盤（Infrastructure）実装状況

### 1.1 実装済みクラス

| 区分 | クラス | 状態 | 備考 |
|---|---|---|---|
| Runtime | TestRuntime | 完了 | test mode / pack識別 / scheduler override |
| Config | TestConfig | 完了 | Pack単位 deterministic knobs |
| Hooks | TestHooks | 完了 | 本番コードの唯一のテスト協力窓口 |
| Bootstrap | TestBootstrap | 完了 | Pack開始/終了、テスト所有状態のみ初期化 |
| Oracle | WorldOracle | 完了 | 物理/仮想/品質/増減の世界状態監査 |
| Deferred | DeferredTestRunner | 実装済（改善余地あり） | MODE-005対応 |
| Deferred | DeferredTestPump | 実装済（改善余地あり） | 単一 tick pump |

### 1.2 基盤に関する未完了事項
- Deferred 系における  
  - `TestRuntime.is_enabled()` ガード  
  - print/log 出力制御（verbose化）
- 通常 Runner / Deferred Runner の実行インターフェース統一（任意）

---

## 2. 実装済み Test Pack 一覧

### 2.1 移動系

#### PACK-MOVE-SCHEDULE
- **コマンド**: `mbd-pack-move-schedule`
- **主目的**:
  - MovePlan 生成と消費
  - Fatal 非移動
  - Phys/Vir 遷移別の距離制約
- **Scenario**:
  - MOVE-SCH-001 ～ MOVE-SCH-003D
- **主オラクル**: 世界状態（位置差分）
- **状態**: **完了（Pass）**

---

### 2.2 Export 基本挙動

#### PACK-EXPORT-BASIC
- **コマンド**: `mbd-pack-export-basic`
- **主目的**:
  - Vulcanus 特例
  - defeated gate
  - cap 抑止
  - 物理 / 仮想切替
- **Scenario**: EXP-BASIC-001 ～ CHUNK-001
- **主オラクル**: 世界状態
- **状態**: **完了（Pass）**

#### PACK-EXPORT-CAP-EDGE
- **コマンド**: `mbd-pack-export-cap-edge`
- **主目的**:
  - cap-1 / cap / cap+ 境界挙動
- **主オラクル**: 世界状態
- **状態**: **完了（Pass）**

---

### 2.3 Export 進行・派生

#### PACK-EXPORT-PROGRESSION（pool-only）
- **コマンド**: `mbd-pack-export-progression`
- **主目的**:
  - selector 候補プールの決定論回帰
- **主オラクル**: 内部状態（flags → pool）
- **状態**: **完了（Pass）**
- **位置づけ**: 低レイヤ寄り（仕様追記必要）

#### PACK-EXPORT-PROGRESSION-WORLD
- **コマンド**: `mbd-pack-export-progression-world`
- **主目的**:
  - Export → world増加 → flags → pool 拡張の連鎖検証
- **主オラクル**: 世界状態
- **副オラクル**: flags / pool
- **状態**: **完了（Pass）**

---

### 2.4 Export 品質

#### PACK-EXPORT-QUAL
- **コマンド**: `mbd-pack-export-qual`
- **主目的**:
  - 初回 normal 保証
  - evo 参照 surface の正当性
- **主オラクル**: 世界状態（品質）
- **状態**: **完了（Pass）**

---

### 2.5 Export × Move 連動

#### PACK-EXPORT-MOVE-INTERACTION
- **コマンド**: `mbd-pack-export-move-interaction`
- **主目的**:
  - 1ロケットで Export と Move が同時成立
- **主オラクル**:
  - Export: 世界状態
  - Move: RocketHistory / MovePlanStore
- **状態**: **完了（Pass）**

---

### 2.6 撃破フラグ（Deferred）

#### PACK-DEFEATED-FLAG
- **コマンド**: `mbd-pack-defeated-flag`
- **主目的**:
  - demolisher 撃破 → defeated=true
  - surface 非伝播
  - 冪等性
- **主Mode**: MODE-005（deferred）
- **主オラクル**: defeated flag
- **状態**: **完了（Pass）**

---

## 3. TestPlan に対するカバレッジ評価

### 3.1 カバー済み領域
- Export 基本挙動
- Export cap 境界
- Export 品質・進行
- Move 計画生成・実行・制約
- Export ↔ Move 連動
- Defeated フラグ（非同期）

### 3.2 未カバー / 部分カバー
- 複数ロケット同tick競合
- 複数 MovePlan 並行存在時の優先度
- VirtualEntityManager の GC / cleanup 系
- ログ抑止・通知系（OBS系は未assert）

---

## 4. 残タスク一覧（優先度つき）

### P1: テスト基盤の完成度向上
- DeferredTestPump / DeferredTestRunner に test-enabled ガード追加
- print 出力の抑制（verbose 制御）

### P2: 運用・保守性
- PROGRESSION 系 Pack の PackID 方針整理
- unique surface を作る Pack の後始末方針

### P3: 仕様書追随
- TestPlan に以下を追記:
  - PACK-EXPORT-CAP-EDGE（専用セーブ不要化）
  - PACK-EXPORT-PROGRESSION / WORLD の位置づけ
  - PACK-DEFEATED-FLAG を MODE-005 の代表例として明記

### P4: 将来拡張（必要になったら）
- 同tick多重イベント
- 大規模ワールド負荷下での Move / Export 安定性
- 観測ログ（OBS系）を副オラクルとしてテスト化

---

## 5. 総括

現時点で、Manis Boss Demolisher の  
**主要なゲーム挙動・境界条件・進行ロジック**は  
自動テストにより高密度にカバーされている。

残タスクは主に  
- テスト基盤の仕上げ  
- 仕様書への反映  
- 将来拡張に向けた余白  

であり、**コア挙動の未検証領域は限定的**である。