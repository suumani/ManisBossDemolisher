RNG-001: 乱数源の統一（確定）

使用する乱数は Factorio公式の同期乱数（LuaRandomGenerator）

APIは math.random 互換

各Mod共通で DeterministicRandom.lua を使用する

Export / Move / Quality / Cap に関わる すべてのランダム性はこの乱数源に限定

RNG-002: 決定性要件

同一セーブ・同一入力・同一イベント順序で 結果は再現可能

乱数の使用箇所は **観測可能（ログで追跡可能）**であること