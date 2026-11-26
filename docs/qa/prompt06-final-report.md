# Báo cáo cuối cùng Prompt 06 — thế giới, khám phá, cốt truyện và nhiệm vụ

**Nhánh phát triển:** `phase-5-world-exploration-story`
**PR #9:** `OPEN`, `DRAFT`, base `phase-4-esper-summon-economy`, URL `https://github.com/AnhhTuann/FFBE-Remastered/pull/9`
**Checkpoint Prompt 06:** `af9cceaca88cf7de92dcb96907c40223f0783fa2`, tag `checkpoint/prompt-06-world-exploration-story` (giữ nguyên)
**Checkpoint Prompt 06.1:** `d3d5fd8805cadae82cc4389e676c776f9ed1f9c4`, tag annotated `checkpoint/prompt-06.1-world-integrity` (tag object `696da594d0e9353e80c438955268377c4b7fdbe6`)
**Phạm vi báo cáo này:** Prompt 06.1 — hardening sau checkpoint Prompt 06; không mở Prompt 07, không hợp nhất PR, không đổi base PR #9.
**Trạng thái rights gate:** `not_passed`.

## 1. Tóm tắt triển khai (Implementation Summary)

Prompt 06.1 giữ nguyên vertical slice thế giới tổng hợp của Prompt 06 và chỉ bổ sung hardening: bảo vệ file lưu tương lai/lỗi, giao dịch ghi dữ liệu nguyên tử, chuyển settlement trận chiến vào thời điểm trận kết thúc, ngăn farm thưởng một lần, sửa Dialog Panel và mở rộng bằng chứng GUI. Đợt follow-up cuối bổ sung hai hàng bảo vệ: receipt `run_id` là ranh giới idempotency ngay trước mọi mutation, và settlement thất bại giữ cả result lẫn context để retry lưu tại chỗ mà không đánh lại trận.

Các hành vi được giữ nguyên: đường dẫn `user://player_state_v3.json`, định dạng tổng thể version 4, phần `world` bổ sung version 1, di cư v1–v4, ba ngôn ngữ `vi`/`en`/`ja`, điều khiển bàn phím/chuột, quest, treasure và battle-return hiện hữu. Không có nội dung FFBE gốc, asset được bảo vệ, dịch vụ trực tuyến hay giao dịch tiền thật nào được thêm vào.

## 2. Nguyên nhân gốc rễ (Root Causes Found)

| # | Nguyên nhân | Hệ quả trước hardening |
|---:|---|---|
| 1 | Save tương lai/lỗi bị từ chối trong bộ nhớ nhưng không khóa đường dẫn ghi | Một `commit()`, `save()`, `reset_to_defaults()`, claim thưởng hoặc ghi trực tiếp `SaveManager.atomic_write()` vẫn có thể ghi đè byte cần giữ lại |
| 2 | Backup di cư chỉ là best-effort, không kiểm tra lỗi | Lỗi ghi `.mig.bak` vẫn có thể dẫn tới normalize/ghi tiếp |
| 3 | Thưởng trận, trạng thái thế giới và quest được settle ở các thời điểm khác nhau | Ghi trận thành công nhưng ghi quest/world thất bại có thể để progress không nhất quán |
| 4 | Encounter boss dùng fixture `repeatable = true` và claim key theo `run_id` | Retry hoặc `run_id` mới có thể farm lại phần thưởng one-time |
| 5 | `on_battle_result()` không có receipt định danh, trigger/result identity và context validation | Kết quả replay, sai trigger hoặc sai location có thể cộng progress trùng |
| 6 | Dialog Panel có kích thước cố định, nút lựa chọn không cuộn được, focus không có neighbor và label cũ không bị dọn | Overflow/ẩn nút ở resolution nhỏ và điều hướng bàn phím không ổn định |
| 7 | Harness GUI trước đó chỉ chụp transition trận | Chưa chứng minh được màn hình victory/defeat/retry/return đi qua settlement thật |
| 8 | Receipt chỉ được kiểm tra ở `on_battle_result()` return path | Gọi lại `settle_world_battle()` với cùng `run_id` vẫn có thể cộng quest object cần nhiều victory |
| 9 | Chỉ giữ `_pending_battle_result`, không giữ context và không có retry-save action | Retry/menu/QA auto-return có thể bỏ kết quả chưa lưu; người chơi phải đánh lại trận |

## 3. Tệp đã thay đổi (Files Changed)

**Lõi lưu và giao dịch**

- `game/core/player_state.gd`: bốn trạng thái lưu, khóa ghi, `transaction()` với snapshot/rollback, pending battle result/context, `settle_world_battle()` với early duplicate receipt guard, `retry_pending_battle_settlement()`, `_stage_world_battle()`, claim key one-time ổn định.
- `game/core/save_manager.gd`: path guard, fault hook backup, prevalidate JSON trước khi ghi, khôi phục `.bak` khi rename thất bại.
- `game/world/quest_settlement.gd` và `.uid`: lớp stage thuần cho quest, reward, unlock; không tự commit.

**Settlement thế giới và trận chiến**

- `game/world/interaction_controller.gd`: treasure/reward/quest một giao dịch, `on_battle_result()` theo receipt, chặn trigger one-time đã claim.
- `game/world/quest_manager.gd`: `record_event()` một transaction duy nhất.
- `game/battle/battle_result.gd`, `battle_manager.gd`, `reward_resolver.gd`: truyền cờ `one_time` tới reward resolver.
- `game/scenes/battle/battle_scene.gd`: settle trong `_record_result()`, ẩn/chặn Retry sau victory one-time, khóa selector khi có world context, QA auto-return về exploration; follow-up thêm nút `battle.retry_save` và chặn Menu/Retry/selector/auto-return khi settlement còn pending.

**Dialog, QA và tài liệu**

- `game/world/dialogue_panel.gd`, `game/scenes/world/dialogue_panel.tscn`: choices cuộn được, responsive sizing, focus neighbors, dọn prompt/status cũ.
- `game/world/exploration_area.gd`: scenario `haven_npc_choice`, focus dialogue và dọn trạng thái cũ.
- `game/tests/prompt06_world_test_suite.gd`: 14 kịch bản fault-injection/idempotency/one-time cộng test mới `test_duplicate_settlement_and_pending_recovery` với quest fixture hai victory, kiểm tra fingerprint bộ nhớ và byte file lưu.
- `tools/qa/capture_prompt06.sh`, `tools/qa/prompt06_visual_report.py`, `tests/test_phase3_qa_tools.py`: ma trận 117 ảnh, world-context thật cho capture trận chiến.
- Localization `vi`/`en`/`ja` thêm `battle.one_time_cleared`; follow-up thêm `battle.retry_save`; coverage JSON/report và kỳ vọng test cập nhật lên 831 keys.
- Tài liệu cập nhật: `docs/qa/prompt06-final-report.md`, `docs/qa/prompt06-visual-review.md`, `docs/architecture/world-exploration.md`, `docs/data-dictionary/world-story-schema.md`, `docs/localization/coverage-report.md`.

## 4. Kết quả toàn vẹn lưu (Save Integrity Results)

- Save status gồm `NORMAL`, `MIGRATING`, `READ_ONLY_FUTURE_VERSION`, `LOAD_FAILED`. Chỉ `NORMAL` cho phép ghi; `MIGRATING` chỉ cho phép tạo `.mig.bak`; hai trạng thái terminal khóa target path.
- Future top-level version hoặc `world.version` bị từ chối trước backup, normalize và ghi. Test xác nhận raw bytes và hash metadata không đổi sau mọi đường dẫn ghi, claim, migration, reset và recovery.
- Profile mới không có save vẫn ở `NORMAL`; save có nhưng không đọc được chuyển sang `LOAD_FAILED`. `recover_from_load_failure()` không reset được file tương lai.
- `transaction()` chặn nested commit, snapshot toàn bộ `data`, validate trước commit, emit đúng một `state_changed` và rollback toàn bộ khi write lỗi.
- `atomic_write()` prevalidate JSON đã serialize và khôi phục `.bak` nếu rename tới target thất bại.

## 5. Kết quả giao dịch trận/điểm/nhân vật (Battle/Quest/Treasure Transaction Results)

- `BattleScene._record_result()` gọi `PlayerState.settle_world_battle()` ngay khi có result. Reward battle, flag encounter, `processed_battle_runs`, `last_battle_result`, interaction count và quest event nằm trong một transaction.
- `settle_world_battle()` kiểm tra `processed_battle_runs[<run_id>]` trước write guard, pending-state và staging. Receipt trùng trả `duplicate: true` và không đụng vào reward/world/quest dù quest object cần hai victory; `run_id` khác vẫn settle riêng.
- `_stage_world_battle()` kiểm tra trigger tồn tại, `kind = encounter_trigger`, `encounter_id` trùng và `area_id` trùng `location_id` khi có context.
- Treasure dùng `claim_world_reward()` với callback stage treasure + quest; failed write rollback cả claim, reward, flag và progress.
- `QuestManager.record_event()` chỉ commit một lần qua `QuestSettlement.stage_event()`; mọi objective bị event tác động được cập nhật chung.
- Khi settlement thất bại, transaction rollback và giữ cả `pending_battle_result` lẫn `pending_battle_context` (trigger/location/encounter). Nút `battle.retry_save` gọi `retry_pending_battle_settlement()` để replay đúng result/context đó qua receipt checks; không đánh lại trận và không grant trùng. Pending được gắn nhãn `world` hoặc `reward`: world replay qua `settle_world_battle()`, reward thường replay qua `claim_battle_reward()`, nên trận không có world context không bị kẹt ở màn hình result. Menu, Retry, pause-return, encounter selector và QA auto-return đều bị chặn khi còn pending. Khi settlement thành công, các pending field bị xóa.

## 6. Kết quả idempotency

| Đối tượng | Khóa/định danh | Hành vi lặp lại |
|---|---|---|
| Treasure | `world|treasure|<id>` | Không claim lại, không cộng gil/item, event quest vô hại |
| Quest reward | `world|quest|<quest_id>` | Chỉ reward lần đầu; unlock vẫn ổn định |
| Repeatable encounter | `battle|run|<run_id>` | Mỗi run mới được reward tương ứng |
| One-time world encounter | `battle|once|<encounter_id>` | Retry/run mới không farm được reward |
| Battle return / duplicate settlement | `processed_battle_runs[<run_id>]` | Return lần hai và gọi settlement lại cùng `run_id` đều no-op trước mọi staging |
| Quest event trùng | progress clamp tới required count | Không vượt mục tiêu, không reward trùng |

## 7. Kết quả fault-injection

Mười bốn kịch bản bắt buộc đều nằm trong `game/tests/prompt06_world_test_suite.gd::test_fault_injection_scenarios()` và chạy trong full Godot suite:

1. Future save load — byte file giữ nguyên, status `READ_ONLY_FUTURE_VERSION`.
2. Future save commit — chặn `save`, `commit`, reset, locale, spending, migration và recovery.
3. Future save reward — chặn battle claim, world claim, staged mutation và direct writer.
4. Treasure commit failure — report `save_failed`, fingerprint state không đổi, retry thành công.
5. Battle settlement failure — rollback reward/world/quest, giữ pending result, retry settlement thành công.
6. Quest staging failure — rollback progress và reward, retry event thành công.
7. Duplicate treasure event — không cộng reward.
8. Duplicate battle result — fingerprint không đổi sau return lần hai.
9. One-time boss victory — flag/claim/receipt ghi trong lúc battle, Retry ẩn.
10. One-time boss retry after victory — claim bị chặn `already_claimed`, trigger bị chặn.
11. One-time boss retry after defeat — Retry vẫn mở, defeat không mark cleared, victory sau đó mới đóng Retry.
12. Repeatable encounter retry — reward run 2 vẫn được cấp, Retry vẫn mở.
13. Battle return after success — không grant reward lần hai.
14. Migration failure — status `LOAD_FAILED`, source bytes giữ nguyên, không để lại `.mig.bak` một phần.

Test bổ sung `test_duplicate_settlement_and_pending_recovery()` kiểm tra riêng: quest fixture hai victory; first victory tăng progress lên 1; duplicate cùng `run_id` giữ nguyên fingerprint bộ nhớ và byte file lưu, không tăng progress, không complete quest, không grant reward; `run_id` khác tăng progress lên 2 và ghi receipt/reward quest vào JSON. Cùng test giả lỗi atomic write boss, khẳng định result/context được giữ, save bytes không đổi, Menu/Retry disabled, nút `battle.retry_save` hiện với localized text, các guard chặn refight/điều hướng, sau đó retry thành công ghi đúng run/trigger/reward và mở điều hướng lại. Test cũng giả lỗi reward thường, xác nhận nhãn `reward`, replay qua claim path và ghi đúng `battle|run|<run_id>` mà không đi qua settlement thế giới.

## 8. GUI trước/sau (GUI Before/After)

| Khía cạnh | Trước Prompt 06.1 | Sau Prompt 06.1 |
|---|---|---|
| Ma trận | 8 scenario × 3 resolution × 3 locale = 72 ảnh | 13 scenario × 3 resolution × 3 locale = 117 ảnh |
| Dialogue | Fixed size, choice overflow, focus không neighbor | Choice cuộn được, focus neighbors, label cũ được dọn, responsive tại 1024×640 / 1280×720 / 1920×1080 |
| Battle GUI | Chỉ transition vào battle | Victory, defeat, Retry và Battle return chạy battle thật trong profile isolate với world settlement |
| Bằng chứng | Geometry/pixel/error count | Geometry/pixel/error count cho 117 ảnh, zero runtime error line; behavior khẳng định bằng headless tests |

Các ảnh là capture cửa sổ Godot thật, không phải mockup hoặc ảnh ghép. Chúng chứng minh render/navigation xảy ra; chúng **không** thay thế phê duyệt trực quan chủ quan của owner. Báo cáo sinh tự động: `docs/qa/prompt06-visual-review.md`. Ma trận 117 ảnh là bằng chứng của Prompt 06.1 trước đó; follow-up này không thêm scenario capture mới, mà kiểm tra trạng thái nút `battle.retry_save` bằng test headless trong profile isolate.

## 9. Kết quả full regression

| Check | Lệnh/đường dẫn | Kết quả |
|---|---|---|
| Godot import (class registration) | `godot --headless --editor --quit --path game --user-dir /tmp/opencode/ffbe-profiles/prompt-06-1-dev` | exit `0`; ba warning Unicode font-cache trước khi scan project, không có `SCRIPT ERROR`/`Parse Error` |
| Godot full suite | `godot --headless --path game --script res://tests/test_runner.gd --user-dir /tmp/opencode/ffbe-profiles/prompt-06-1-dev` | `3642 passed, 0 failed`, exit `0` |
| Negative control | full suite với `FFBE_TEST_NEGATIVE_CONTROL=1` | exit `1`, `3642 passed, 1 failed` |
| Python discovery | `python3 -m unittest discover -s tests -v` | `96 tests`, `OK`, exit `0` |
| Importer security | `python3 -m unittest tests.test_phase3_importer -v` | `22 tests`, `OK`, exit `0` |
| World data + QA tools | `python3 -m unittest tests.test_prompt06_world_data tests.test_phase3_qa_tools -v` | `30 tests`, `OK`, exit `0` |
| Localization | `python3 tools/localization/coverage_report.py --root .` | `status: pass`, `831` keys, `45` world keys, `0` missing, `0` placeholder mismatch, `280` dynamic refs, `0` dynamic error |
| GUI matrix | `tools/qa/prompt06_visual_report.py` | `117` PNG/sidecar pairs, `0` runtime error line (bằng chứng cũ, không chụp lại ở follow-up) |
| `git diff --check` | review trước commit | exit `0` |

Log chi tiết của follow-up nằm dưới `/tmp/opencode/ffbe-logs/prompt061/recovery/`. Các dòng `ERROR` dự kiến trong log Godot đến từ fixture test âm tính; ba dòng Unicode parsing warning trong import/export là tiếng ồn font-cache của engine trước khi project scan, không phải lỗi script hay lỗi dữ liệu dự án.

## 10. Kết quả export

| Artifact | Kết quả |
|---|---|
| Linux release export | `godot --headless --path game --export-release "Linux" build/linux/FFBE-Remastered.x86_64`, exit `0`, ELF64 x86-64 tại `game/build/linux/` |
| Windows release export | `godot --headless --path game --export-release "Windows Desktop" build/windows/FFBE-Remastered.exe`, exit `0`, PE32+ x86-64 tại `game/build/windows/` |
| Smoke binary Linux | `./FFBE-Remastered.x86_64 --headless --quit-after 300` trong profile isolate, exit `0`, không có `SCRIPT ERROR`/`Parse Error`/`ERROR:` |
| Windows runtime | **BLOCKED / NOT RUN** — không có host Windows; exit export không phải bằng chứng chạy runtime |

Export dùng template Godot `4.7.2.stable` có sẵn thông qua profile HOME isolate; không tải template, không nâng engine, không đưa binary vào Git. Các file build nằm dưới `game/build/` và bị Git ignore.

## 11. Git Commit SHA

Commit hardening Prompt 06 trước đó: `819abcd3032e168c2e6d540271bc4d0f3301270a` — `fix(world): harden save integrity and world settlement`.
Commit hardening Prompt 06.1 follow-up: `d3d5fd8805cadae82cc4389e676c776f9ed1f9c4` — `fix(world): make battle settlement replay-safe and recoverable`.
Tag mới `checkpoint/prompt-06.1-world-integrity` là annotated tag object `696da594d0e9353e80c438955268377c4b7fdbe6`, trỏ tới commit `d3d5fd8805cadae82cc4389e676c776f9ed1f9c4`. Tag Prompt 06 `checkpoint/prompt-06-world-exploration-story` vẫn trỏ tới `af9cceaca88cf7de92dcb96907c40223f0783fa2` và không bị thay thế. Một commit docs-only tiếp theo ghi nhận các SHA này; không thay đổi code, dữ liệu hay ảnh. Không có hard reset, force push, rebase phá hủy, cherry-pick, `git clean` hay ghi đè lịch sử.

## 12. PR #9 đã cập nhật

PR #9 vẫn `OPEN`, `DRAFT`, base `phase-4-esper-summon-economy`, head `phase-5-world-exploration-story`. Chỉ nhánh này được push bình thường và tag mới được push riêng. PR #8, `main`, base/state của PR #9 và tag checkpoint Prompt 06 không bị thay đổi. PR #9 chưa merge, chưa đóng và chưa chuyển DRAFT→READY.

## 13. Rủi ro / blocker còn lại

- Windows runtime: **BLOCKED / NOT RUN** trên host Linux hiện tại; cần owner chạy binary Windows trên máy Windows nếu muốn xác nhận runtime.
- Phê duyệt trực quan/art-direction/readability: **NOT VERIFIED**; tự động hóa chỉ xác nhận geometry, pixel statistics, số dòng lỗi và capture thật.
- Save tương lai/không đọc được được cố ý giữ khóa để owner phục hồi; hardening này không tự động ghi đè dữ liệu đó.
- Prompt 07 chưa được bắt đầu và chỉ được phép sau khi owner phê duyệt checkpoint này.
- Chưa có capture GUI cho trạng thái pending-settlement/retry-save; trạng thái nút và localized text được kiểm tra bằng test headless, không phải screenshot thật.
- Dữ liệu thế giới là fixture tổng hợp, không phải khôi phục địa lý/cốt truyện FFBE gốc.

---

## 14. Prompt 06.1.1 — guard cho `_start_battle()` khi settlement còn pending

Đây là follow-up phòng vệ hẹp sau Prompt 06.1, **không** mở Prompt 07, không thêm gameplay, không đổi base PR #9 và không hợp nhất PR. Phạm vi duy nhất: `game/scenes/battle/battle_scene.gd::_start_battle(encounter_id)` và test/báo cáo liên quan.

Guard được đặt ngay dòng đầu của `_start_battle()`: nếu `has_pending_settlement()` trả về `true`, hàm gọi `_refresh_pending_settlement_ui()` rồi `return` **trước** mọi thao tác dừng timer, load/create manager, đổi `encounter`, đặt `_run_id`, reset `_result_recorded`, xóa `_result_snapshot`, ẩn overlay hay khởi tạo lại combatant/UI. Nhờ đặt ở ranh giới hàm, guard áp dụng cho cả lời gọi nội bộ trực tiếp, không chỉ các nút/menu đã được chặn từ trước. Khi không có settlement pending, luồng khởi tạo trận giữ nguyên.

`game/tests/prompt06_world_test_suite.gd::test_duplicate_settlement_and_pending_recovery()` được mở rộng: bật `FFBE_QA_MODE=1` để `_start_battle()` vượt kiểm tra party (tức là nếu thiếu guard sẽ thật sự mutate trận), capture trạng thái, gọi trực tiếp `_start_battle(SKIRKISH)`, rồi khẳng định `_run_id`, manager và `summary()`, `_result_snapshot`, `_result_recorded`, pending result/context, fingerprint PlayerState, byte file lưu, `reward_claims`, `world` (quest/receipt) không đổi; nút Retry Save vẫn visible với đúng text địa phương hóa `battle.retry_save` và Menu vẫn bị disable. Sau đó `Retry Save` lưu thành công và mở lại điều hướng. Positive control chứng minh `_start_battle()` vẫn tạo run mới, thay manager, xóa snapshot/recorded và cho phép Retry khi đã hết pending. Env QA được khôi phục trước khi kết thúc test; fixture nằm trong profile `/tmp/opencode/ffbe-profiles/prompt-06-1-1-*`, không đọc/ghi save của owner.

### 14.1 Regression fresh (không dùng số của Prompt 06.1)

| Check | Lệnh/đường dẫn | Kết quả |
|---|---|---|
| Godot import | `godot --headless --editor --quit --path game --user-dir /tmp/opencode/ffbe-profiles/prompt-06-1-1-dev` | exit `0`, `0` dòng `SCRIPT ERROR`/`Parse Error` |
| Godot focused Prompt 06 | `godot --headless --path game --script /tmp/opencode/ffbe-profiles/prompt-06-1-1-focused/focused_runner2.gd --user-dir /tmp/opencode/ffbe-profiles/prompt-06-1-1-focused-5` | `329 passed, 0 failed`, exit `0` |
| Godot full suite | `godot --headless --path game --script res://tests/test_runner.gd --user-dir /tmp/opencode/ffbe-profiles/prompt-06-1-1-full-2` | `3662 passed, 0 failed`, exit `0` |
| Negative control | full suite với `FFBE_TEST_NEGATIVE_CONTROL=1`, profile `prompt-06-1-1-negative-2` | exit `1`, `3662 passed, 1 failed` |
| Python discovery | `python3 -m unittest discover -s tests -v` | `96 tests`, `OK`, exit `0` |
| Importer security | `python3 -m unittest tests.test_phase3_importer -v` | `22 tests`, `OK`, exit `0` |
| World data + QA tools | `python3 -m unittest tests.test_prompt06_world_data tests.test_phase3_qa_tools -v` | `30 tests`, `OK`, exit `0` |
| Localization | `python3 tools/localization/coverage_report.py --root .` | `status: pass`, `831` keys, `45` world keys, `0` missing, `0` placeholder mismatch, `280` dynamic refs, `0` dynamic error, exit `0` |
| Linux release export | `godot --headless --path game --export-release "Linux" build/linux/FFBE-Remastered.x86_64` | exit `0`, ELF64 x86-64 |
| Windows release export | `godot --headless --path game --export-release "Windows Desktop" build/windows/FFBE-Remastered.exe` | exit `0`, PE32+ x86-64 |
| Smoke binary Linux | `./FFBE-Remastered.x86_64 --headless --quit-after 300` trong profile isolate | exit `0`, không có `SCRIPT ERROR`/`Parse Error`/`ERROR:` |
| `git diff --check` | review trước commit | exit `0` |

Log mới nằm dưới `/tmp/opencode/ffbe-logs/prompt-06-1-1/`: `import.log`, `focused.log`, `full-suite.log`, `negative-control.log`, `python-discovery.log`, `importer-security.log`, `world-qa.log`, `localization.log`, `export-linux.log`, `export-windows.log`, `smoke-linux.log`. Các dòng `ERROR` dự kiến trong full suite đến từ fixture âm tính; vài dòng resource-at-exit và Unicode font-cache là tiếng ồn engine, không phải lỗi script.

### 14.2 Publication và checkpoint

- Commit code Prompt 06.1.1: `13c370f8cd064c84f2e9363016dac7f28c092579` — `fix(world): guard direct restart during pending settlement`.
- Tag mới `checkpoint/prompt-06.1-direct-restart-guard` là annotated tag object `36b7f5e64f6250fb82ea3551840d47ae7d0536f7`, trỏ tới commit code `13c370f8cd064c84f2e9363016dac7f28c092579`.
- Tag Prompt 06 `checkpoint/prompt-06-world-exploration-story` vẫn trỏ tới `af9cceaca88cf7de92dcb96907c40223f0783fa2`, tag Prompt 06.1 `checkpoint/prompt-06.1-world-integrity` vẫn trỏ tới `d3d5fd8805cadae82cc4389e676c776f9ed1f9c4`; cả hai không bị thay thế.
- PR #9 vẫn `OPEN`, `DRAFT`, base `phase-4-esper-summon-economy`, head `phase-5-world-exploration-story`; không merge, không đổi base, không đụng PR #8 hay `main`. Không force push, hard reset, `git clean` hay rebase phá hủy.

### 14.3 Giới hạn còn lại

- Phục hồi pending vẫn **chỉ trong bộ nhớ**: nếu tiến trình kết thúc bất thường hoặc crash trước khi Retry Save, result/context pending không được khôi phục. Không tuyên bố khả năng chống crash/process-termination.
- Windows runtime: **BLOCKED / NOT RUN** trên host Linux; exit export không phải bằng chứng chạy runtime.
- Phê duyệt trực quan/art-direction/readability: **NOT VERIFIED**; follow-up này kiểm tra trạng thái nút bằng headless test, không chụp GUI mới.
- Rights gate vẫn `not_passed`; toàn bộ nội dung là fixture tổng hợp/remastered design, không đưa asset được bảo vệ, credential, save runtime hay executable vào Git.
