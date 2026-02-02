# PACK-EXPORT-BASIC（拡張） テスト項目一覧

## 対象仕様：01_InvasionExport.md + 関連（02, 04, 90）

Pack前提（共通）

新規シナリオ開始

対象惑星集合は固定：nauvis/gleba/fulgora/vulcanus/aquilo

合否主審：世界状態

dest_surface 上の spawn（増加）/不増（抑止）

必要なら Virtual 状態（ただし Export は原則 Phys を生む想定）

補助：終端ログ（OK/SKIP/FAIL + reason）

シナリオ一覧（仕様ID → テスト名）
EXP-BASIC-001: Vulcanus特例で必ず評価・実行対象になる

根拠：EXP-TRG-001, EXP-ELIG-001

条件：trigger_surface=vulcanus、Defeated=falseでも可

期待：

ExportEval が SKIP ではなく OK または（dest_invalidならSKIP）

dest_valid=true の条件が揃うと 1体増える

主審：dest_surface の個体増加（+1）

EXP-BASIC-002: Non-Vulcanus & Defeated=false は常に実行されない

根拠：EXP-ELIG-002

条件：trigger_surface=nauvis 等、Defeated=false

期待：ExportEval=SKIP（ELIGIBILITY_FAILED）

主審：どのdest_surfaceでも個体が増えない

EXP-BASIC-003: Non-Vulcanus & Defeated=true で実行対象になる

根拠：EXP-ELIG-002, EXP-ELIG-003

条件：trigger_surface=nauvis、Defeated=true

期待：

dest_valid=true の条件が揃うと 1体増える

主審：dest_surface の個体増加（+1）

EXP-BASIC-004: dest_surface は候補集合から完全ランダム、事後に Importable 判定

根拠：EXP-DEST-001/002/003

条件：候補5惑星のうち、いくつか surface 未生成を混ぜる

期待：

未生成が引かれた場合は SKIP（DEST_INVALID）

生成済みが引かれた場合は OK（cap等が無ければ）

主審：

OK なら dest_surface に増加

SKIP なら増加なし

※ ランダム性があるので「N回中1回はDEST_INVALIDが起きる」型テスト（確率吸収）を別途適用可能

EXP-BASIC-005: Exportは1回につき必ず1体のみ

根拠：EXP-COUNT-001

条件：OKが発生する前提を作る（vulcanus等）

期待：1回の発火で増加が +1 を超えない

主審：dest_surface 上の増加数が 必ず +1

EXP-BASIC-006: Type Key は alt/non-alt を統合する

根拠：EXP-TYPE-001/002, TAX-TYPE-002（04）

条件：同一 Type Key の alt / non-alt が存在する設計前提

期待：

期待：品質が必ず normal

主審：world state（生成された entity の quality）

補助：ログの quality=normal

EXP-BASIC-008: 2体目以降は dest_surface evo 依存品質（trigger_surface参照禁止）

根拠：EXP-QUAL-002, EXP-EVO-001（02側含む）

条件：

同一名のentity を2回以上輸入

dest_surface evo をテストモードで固定（TestHooks）

期待：

品質が normal 固定ではなくなる（= roll される）

evo参照が dest_surface である

主審：world state（qualityが期待レンジ内）

補助：ログの dest_evo

※ これは **PACK-EXPORT-QUALITY（次Pack候補）**に切り出すのが自然。
ただし “拡張BASIC”として最低限のスモークは可能。

EXP-BASIC-009: Cap到達時は輸入しない（BASIC側スモーク）

根拠：EXP-CAP-001/002/003

条件：dest_surface に DemolisherNames.ALL が cap 以上いる

期待：SKIP（CAP_REACHED）、増加なし

主審：世界状態（増加なし）

※ 本格境界は PACK-EXPORT-CAP-EDGE に移す

このPackのスコープ確定（宣言）

このPackで必ず完走させる（P1確定）：

EXP-BASIC-001〜005（トリガ・Eligibility・dest・1体性）

EXP-BASIC-007（初回normal）

EXP-BASIC-009（capスモーク）

次Pack（PACK-EXPORT-QUALITY）に切り出す：

EXP-BASIC-006 / 008（entity_name統合×品質ロールの本検証）

次Pack（PACK-EXPORT-CAP-EDGE）に切り出す：

cap境界（直前/到達/超過の3点セット）