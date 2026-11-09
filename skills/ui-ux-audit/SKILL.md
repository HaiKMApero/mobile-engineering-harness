---
name: ui-ux-audit
description: Audit an Android Compose app, feature or screen for UI/UX behaviour defects (tab/pager desync, non-looping carousels, keyboard pushing ads, thumbnail-to-video flicker, stale counters, lost scroll, double-tap) against the kb/ui-ux rules and write a UX-* findings report. Use when asked to audit UX/behaviour ("audit UI/UX", "rà lỗi hành vi", "screen audit") or after a Figma fix pass. Not for Figma visual scoring or fixing a known UI bug.
priority: P1
---

# Skill: ui-ux-audit

Tìm lỗi hành vi UI/UX **trước** khi QA/user báo. Điểm Figma/preview chỉ chứng minh khung hình tĩnh; skill này
kiểm hành vi theo ma trận archetype × axis của KB.

## Khi dùng và khi chuyển cho skill khác

Dùng khi cần **tìm** lỗi hành vi chưa ai báo trên một màn, một feature hoặc cả app (sau khi clone app, sau đợt fix Figma, trước release).

| Việc | Owner |
|---|---|
| So/chấm UI với Figma (khung hình tĩnh) | `ui-diff-review`, `compare-ui-board`, `ui-from-figma-update` |
| Sửa một bug UI đã biết theo Figma | `ui-fix-loop` |
| Review một PR/diff tổng quát | `coding-review` (dùng chung KB cho phần UI) |
| Render và review @Preview | `testing-preview` |
| Sửa các finding sau audit | `bug` / `bug-fix-orchestrator` (hoặc fix trực tiếp khi user yêu cầu) |

## Tìm KB

KB nằm cùng checkout harness với skill này:

```bash
KB="$(cd "$(readlink -f ~/.claude/skills/ui-ux-audit 2>/dev/null)/../../kb/ui-ux" 2>/dev/null && pwd)"
# Fallback: global harness checkout (see ~/docs/mobile-engineering-harness/integration.md)
[ -f "$KB/README.md" ] || KB="$HOME/docs/mobile-engineering-harness/upstream/kb/ui-ux"
[ -f "$KB/README.md" ] || { echo "kb/ui-ux not found: report BLOCKED"; }
```

Đọc trước: `$KB/README.md`, `$KB/axes.md`, `$KB/runbooks/screen-audit.md` (quy trình chi tiết + bảng triệu chứng → rule).

## Inputs

- Repo app (mặc định: thư mục hiện tại) và thư mục source Kotlin (vd. `app/src/main/java`, `presenter/src/main/kotlin`).
- Phạm vi: một màn, một feature folder, hoặc cả app. Không nói rõ → cả app.
- Mức: `static` (bước 1–3 + 5, mặc định) hoặc `runtime` (bước 1–5, cần device/emulator đang `adb devices`).
- Project rule (`CLAUDE.md`, decision log, spec, và status `not-covered`/`sdk` trong screen registry) — quyết định của user thắng KB; rule bị quyết định loại trừ ghi `N/A (decision)`.

## Procedure

1. **Inventory.** Lấy danh sách màn từ screen registry (`docs/references/*screen-registry*`) hoặc navigation graph.
   Với mỗi màn, liệt kê component → archetype (`$KB/archetypes/*.md`). Trạng thái loading/empty/error/skeleton không cần archetype riêng: đi theo `axes.md` AX-ASYNC. Component khác không khớp → `unclassified` (đề xuất archetype mới chỉ khi nó lặp lại ở nhiều app).
2. **Static scan.** `bash "$KB/scripts/ui-ux-scan.sh" <src-dir> > <work>/ux-scan.tsv`. Script là bước lọc rẻ, không phải danh sách việc: lỗi nặng nhất thường đến từ bước 3. Script quét cả source; giữ các dòng thuộc phạm vi audit (lọc theo đường dẫn feature/màn). Mỗi dòng là nghi vấn; mở code xác nhận từng dòng.
3. **Contract walk.** Mỗi (component, archetype): đi qua **Contract** + **Edge-case matrix** của archetype; phần còn lại của màn đi qua 9 trục `axes.md`.
   Kết quả mỗi rule: `PASS` (có bằng chứng) / `FAIL` (rule, file:line, hiện tượng user thấy) / `N/A` (lý do) / `UNVERIFIED` (cần runtime) / `DRIFT` (code trái với quyết định đã ghi — báo để sửa code hoặc sửa decision, tránh QA báo lỗi giả).
   App lớn: chia theo feature group cho subagent song song, mỗi agent nhận đường dẫn KB + danh sách màn + format báo cáo; controller gộp và khử trùng.
   Luôn thêm **một lane dữ liệu xuyên màn** (`data/repository`, `domain`, `di`) cho AX-STATE và `toggle-counter-actions.md`: lỗi đồng bộ giữa màn (một thực thể, nhiều nguồn; optimistic nhân bản ở nhiều ViewModel) không tìm được khi rà từng màn.
4. **Runtime** (chỉ khi mức `runtime` và có device): kiểm các `UNVERIFIED` theo `$KB/runbooks/runtime-verification.md`
   (UI test, uiautomator bounds cho IME, screenrecord + ffmpeg cho nháy, kịch bản back/rotate/background/process death). Lưu bằng chứng.
5. **Report.** Ghi `plans/reports/ui-ux-audit-<yymmdd-hhmm>-<scope>.md` trong repo app (tên này cố định để audit sau tìm lại được; nếu `plans/` bị gitignore thì nói rõ với user báo cáo chỉ nằm trên máy):
   - Tóm tắt: số màn, số finding theo severity, số UNVERIFIED.
   - Bảng finding: `ID | Severity | Screen | Rule | Hiện tượng | file:line | Hướng sửa | Verify`.
   - Severity: `critical` (mất tiền/dữ liệu, crash) · `high` (sai trạng thái, chặn luồng, vi phạm ad policy) · `medium` (nháy, mất vị trí, lệch đồng bộ) · `low` (polish).
   - Đề xuất gom fix theo **archetype** (một component dùng chung sửa nhiều màn), không theo màn.
   - Danh sách UNVERIFIED còn lại và câu hỏi mở.

## Rules

- Read-only mặc định: không sửa code, không commit. Chỉ fix khi user yêu cầu — khi đó fix theo Contract của rule và thêm test theo mục Verify.
- `UNVERIFIED` không bao giờ được tính là PASS; không có device thì nói rõ phần runtime chưa chạy.
- Mọi FAIL phải có file:line (dòng scan chỉ có thư mục, như `UX-AD-003`, phải neo về file:line cụ thể) và mô tả hiện tượng người dùng thấy; nghi vấn từ script chưa xác nhận thì không đưa vào FAIL.
- Không ghi nội dung nhạy cảm (token, query người dùng) vào báo cáo.
- Phát hiện lỗi bắt được bằng grep mà script chưa bắt → đề xuất bổ sung rule vào `ui-ux-scan.sh` ở cuối báo cáo.

## Definition of done

- Báo cáo tồn tại ở `plans/reports/ui-ux-audit-*.md`, liệt kê **mọi** màn trong phạm vi với archetype đã nhận diện.
- Mỗi dòng của `ux-scan.tsv` **thuộc phạm vi** có verdict trong báo cáo: thuộc finding nào (nhiều dòng có thể gộp một finding và ngược lại) hoặc false positive kèm lý do.
- Mỗi FAIL có rule `UX-*` tồn tại trong KB, file:line và hiện tượng; phần runtime chưa chạy được liệt kê là UNVERIFIED.
- Trả lời user bằng ngôn ngữ của user: số finding theo severity, top 5, đường dẫn báo cáo, phần chưa verify, câu hỏi "có fix không"; kết thúc `Status: DONE | DONE_WITH_CONCERNS | BLOCKED`.
