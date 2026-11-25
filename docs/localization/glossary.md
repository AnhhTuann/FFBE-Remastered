# Localization glossary

Canonical terminology for the three static UI dictionaries. These are **project-authored
conventions for synthetic fixture content**. They are not evidence of recovered original
FFBE text and must not be presented as such.

## 1. Core UI and progression vocabulary

| Concept | English | Vietnamese (preferred) | Japanese | Example key |
|---|---|---|---|---|
| Character | Unit / Character | **Nhân vật** | キャラクター | `viewer.unit`, `details.title` |
| Party | Party | **Đội hình** | 編成 | `party.title`, `menu.party` |
| Equipment | Equipment | **Trang bị** | 装備 | `equipment.title`, `details.equipment` |
| Inventory | Inventory | **Kho đồ** | 所持品 / キャラクター所持一覧 | `equipment.inventory`, `collection.title` |
| Awakening | Awakening | **Thức tỉnh** | 覚醒 | `awakening.title`, `details.awaken` |
| Enhancement | Enhancement | **Cường hóa** | 強化 | `upgrade.title`, `details.upgrade` |
| Summon | Summon | **Triệu hồi** | 召喚 | `menu.collection` |
| Skill | Ability | **Kỹ năng** | アビリティ | `common.abilities`, `battle.abilities` |
| Passive | Passive ability | **Kỹ năng bị động** | パッシブ | `passive.*.name`, `viewer.abilities` |
| Chain | Chain | **Chuỗi liên kích** | チェイン | `battle.chain` |
| Elemental resistance | Elemental resistance | **Kháng nguyên tố** | 属性耐性 | `viewer.stats` |
| Character fragment | Unit fragment | **Mảnh nhân vật** | キャラクターの欠片 | `details.fragments` |
| Victory | Victory | **Chiến thắng** | 勝利 | `common.victory`, `battle.victory` |
| Defeat | Defeat | **Thất bại** | 敗北 | `common.defeat`, `battle.defeat` |
| Limit Burst | Limit Burst | `LB` | `LB（リミット）` | `battle.limit` |
| Super Limit Burst | Super Limit Burst | `SLB` | `SLB（スーパーリミット）` | `battle.super_limit`, `details.super_lb` |
| Trust reward | Trust Master / Super Trust Master reward | `TMR` / `STMR` | `TMR（信頼報酬）` / `STMR（信頼報酬）` | `details.tmr`, `details.stmr` |
| Vision Card | Vision Card | Thẻ Tầm Nhìn | ビジョンカード | `vision.title`, `equipment.vision_card` |
| Materia | Materia | Ma thụ | マテリア | `equipment.materia`, `materia.*.name` |
| Gil | Gil | `gil` | `ギル（gil）` | `battle.rewards` |

## 2. Locked tokens

Keep the following tokens recognizable in all locales. Do not translate them into local
words and do not change their case:

| Token | Meaning | Notes |
|---|---|---|
| `NV` | Neo Vision rarity/form | Japanese uses `NV覚醒`; Vietnamese keeps `NV`. |
| `EX` | EX form / awakening tier | Japanese uses `EX覚醒`. |
| `NV+` | NV+ form | Plus sign is preserved; Japanese uses `NV+覚醒`. |
| `TMR` | Trust Master Reward | Japanese appends `（信頼報酬）`. |
| `STMR` | Super Trust Master Reward | Japanese appends `（信頼報酬）`. |
| `LB` | Limit Burst | Japanese appends `（リミット）`. |
| `SLB` | Super Limit Burst | Japanese appends `（スーパーリミット）`. |
| `gil` | In-game currency | Japanese uses `ギル（gil）`. |
| Digits and `%d` | Levels, slots, turns, counts | Stay ASCII; placeholders are never translated. |

`Overdrive` is also kept as a recognizable system name. Vietnamese uses `Overdrive`;
Japanese uses `オーバードライブ`.

## 3. Placeholder tokens

Never translate or reorder these:

- printf style: `%s`, `%d`, `%(name)s` when introduced.
- named style: `{path}`, `{locale}`, `{name}` for `String.format()`.

Examples in the current dictionaries: `settings.path` (`{path}`),
`settings.locale_changed` (`{locale}`), `collection.copy_count` (`%d`), and
`battle.turn` (`%d`).

## 4. Regional and evidence labels

- `GL` and `JP` are separate source namespaces. Never infer that the same native ID is the
  same record in both regions; composite identities are documented elsewhere.
- Verification labels (`VERIFIED`, `RECOVERED`, `PARTIAL`, `UNVERIFIED`, `UNAVAILABLE`)
  describe evidence, not translation status. A translated label does not make a record
  `VERIFIED`.
- Names under `unit.*`, `ability.*`, `passive.*`, `leader.*`, `equip.*`, `materia.*`, and
  `vision.synthetic_*` are synthetic fixtures (`SYNTHETIC_FIXTURE`), not recovered data.
- Measured dictionary coverage is reported in [coverage-report.md](coverage-report.md).
  That report is evidence of parity and script checks only, not a claim that translation
  is complete or that every scene uses the locale service.
