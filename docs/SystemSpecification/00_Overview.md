# System Overview — Manis Boss Demolisher
`docs/SystemSpecification/00_Overview.md`

**Status:** Active  
**Scope:** Manis Boss Demolisher

---

# 0. 本書の目的

本書は Manis Boss Demolisher における  
**SystemSpecification 全体の入口（Overview）**として機能する。

本書は以下を整理する。

- Manis Boss Demolisher が **どのようなシステムであるか**
- システムの **責務と境界**
- システムの **実行モデル**
- SystemSpecification 文書構成

本書は **個別挙動の詳細を定義しない。**

ボスクラス判定、惑星状態、侵略輸出、ロケット反応などの詳細は  
後続の SystemSpecification 文書に委譲する。

---

# 1. システムの全体像

Manis Boss Demolisher は、

> **ボス級デモリッシャーを追加し、通常個体とは異なる脅威として世界に導入する Mod**

である。

本 Mod は、デモリッシャーを単なる通常敵ではなく

- 戦闘可能な強敵
- 巨大すぎて直接戦闘に適さない脅威
- 惑星環境そのものを変える存在

として扱う。

これにより、プレイヤーは  
**撃破対象として向き合う場面**と  
**工場レイアウトや進行ルートで回避すべき場面**の両方に直面する。

---

# 2. プレイヤー体験

Manis Boss Demolisher は次のプレイヤー体験を目的とする。

- 通常デモリッシャーとは異なるボス戦体験
- 強敵との戦闘判断
- 巨大個体に対する回避・進路設計
- 惑星環境に対する圧迫感の増加

本 Mod は特に、

- **戦うべき相手**
- **避けるべき相手**
- **世界に圧力を与える相手**

を分離して提示することを意図する。

プレイヤーは

- 戦闘継続
- 撤退
- 基地配置変更
- 惑星上の安全圏確保

といった意思決定を迫られる。

---

# 3. システム責務

Manis Boss Demolisher の責務は次の通り。

| Responsibility | Owner |
|---|---|
| ボス級デモリッシャーの定義 | Manis Boss Demolisher |
| 惑星状態に応じたボス脅威モデル | Manis Boss Demolisher |
| ボス個体クラス管理 | Manis Boss Demolisher |
| 侵略圧力の外部出力 | Manis Boss Demolisher |
| ボス関連反応処理 | Manis Boss Demolisher |

本 Mod は次を責務としない。

- Factorio 本体の enemy AI 制御
- world generation 全体の制御
- 汎用 job orchestration
- 他 Mod のドメインロジック実行

---

# 4. 実行モデル

Manis Boss Demolisher は  
ボス個体、惑星状態、外部反応処理を組み合わせて動作する。

概念上の実行モデルは次の通り。

```
planet state update
↓
boss class evaluation
↓
boss-related reaction / export
↓
observable world impact
```

本 Mod の詳細な起動契機や内部処理順は  
各 SystemSpecification 文書で定義される。

---

# 5. 主要メカニズム

本 Mod の主要メカニズムは次の領域で構成される。

```
planet state model
↓
boss class model
↓
reaction / export
↓
world impact
```

各領域の役割は次の通り。

| System | Role |
|---|---|
| Invasion Export | 外部へ侵略圧力を出力する |
| Planet State Model | 惑星側の状態を管理する |
| Rocket Sound Reaction | 特定トリガに対する反応を定義する |
| Boss Classes | ボス個体の種類と性質を定義する |

詳細は各文書に委譲する。

---

# 6. ボスクラス

Manis Boss Demolisher は  
複数のボスクラスを持つシステムである。

ボスクラスは少なくとも次の差を持ちうる。

- 脅威規模
- 戦闘可否
- 惑星への圧力の与え方
- プレイヤーが取るべき対処

本 Mod において重要なのは、  
**すべての脅威が「倒すべき敵」とは限らない**ことである。

詳細は  
`04_BossClasses.md` に定義される。

---

# 7. 境界と依存関係

Manis Boss Demolisher は  
Manis ecosystem 内で次の境界を持つ。

| System | Responsibility |
|---|---|
| Factorio enemy system | AI / pathfinding / native world behavior |
| 外部 Mod / システム | export を受けた側の処理 |
| 本 Mod | boss threat modeling / reaction / export |

本 Mod は次の処理を行わない。

- Factorio 本体の AI 置換
- 汎用ジョブ制御
- 他 Mod の内部状態直接操作

---

# 8. 観測性

Manis Boss Demolisher は  
ボス関連システムの挙動を観測可能にする。

主な観測対象は次の通り。

- boss class state
- planet state
- reaction result
- export result

観測仕様は  
`90_Observability.md` に定義される。

---

# 9. テスト方針

Manis Boss Demolisher のテストは  
**仕様を基準として設計される。**

テストの基本方針は  
`TestPolicy.md` に定義される。

---

# 10. SystemSpecification 文書構成

Manis Boss Demolisher の仕様は  
以下の文書で構成される。

```
00_Overview.md
01_InvasionExport.md
02_PlanetStateModel.md
03_RocketSoundReaction.md
04_BossClasses.md
90_Observability.md
TestPolicy.md
```

---

# 11. 設計意図

Manis Boss Demolisher は、

> **デモリッシャーを「巨大な世界的脅威」として再構成する**

ことを目的として設計されている。

このシステムは

- 強敵としての戦闘体験
- 回避対象としての地形的脅威
- 惑星全体に圧力を与える存在感

を通じて、

**戦闘か撤退かという意思決定をプレイヤーへ迫ること**

を目指している。

---