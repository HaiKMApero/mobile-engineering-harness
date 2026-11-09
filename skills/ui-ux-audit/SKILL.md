---
name: ui-ux-audit
description: Audit chủ động lỗi hành vi UI/UX của app Android Compose (1 màn, 1 feature hoặc cả app) theo KB kb/ui-ux — tab/pager lệch, carousel không vòng, bàn phím đẩy ad, nháy thumbnail→video, số đếm không cập nhật, mất scroll khi back, tap đúp... Xuất báo cáo finding theo rule UX-* (PASS/FAIL/N/A/UNVERIFIED). Dùng khi user nói "audit UI/UX", "screen audit", "rà lỗi hành vi", "check UX trước release", hoặc sau khi fix UI theo Figma. Không fix code trừ khi user yêu cầu.
priority: P1
---

# Skill: ui-ux-audit

Tìm lỗi hành vi UI/UX **trước** khi QA/user báo. Điểm Figma/preview chỉ chứng minh khung hình tĩnh; skill này
kiểm hành vi theo ma trận archetype × axis của KB.

## Tìm KB

KB nằm cùng checkout harness với skill này:

```bash
SKILL_FILE="$(readlink -f ~/.claude/skills/ui-ux-audit/SKILL.md 2>/dev/null || echo skills/ui-ux-audit/SKILL.md)"
KB="$(cd "$(dirname "$SKILL_FILE")/../../kb/ui-ux" && pwd)"
```

Đọc trước: `$KB/README.md`, `$KB/axes.md`, `$KB/runbooks/screen-audit.md` (quy trình chi tiết + bảng triệu chứng → rule).

## Inputs

- Repo app (mặc định: thư mục hiện tại) và thư mục source Kotlin (vd. `app/src/main/java`, `presenter/src/main/kotlin`).
- Phạm vi: một màn, một feature folder, hoặc cả app. Không nói rõ → cả app.
- Mức: `static` (bước 1–3, mặc định) hoặc `runtime` (thêm bước 4, cần device/emulator đang `adb devices`).
- Project rule (`CLAUDE.md`, decision log, spec) — quyết định của user thắng KB; rule bị quyết định loại trừ ghi `N/A (decision)`.

## Procedure

1. **Inventory.** Lấy danh sách màn từ screen registry (`docs/references/*screen-registry*`) hoặc navigation graph.
   Với mỗi màn, liệt kê component → archetype (`$KB/archetypes/*.md`). Không khớp → `unclassified`.
2. **Static scan.** `bash "$KB/scripts/ui-ux-scan.sh" <src-dir> > <work>/ux-scan.tsv`. Mỗi dòng là nghi vấn; mở code xác nhận từng dòng.
3. **Contract walk.** Mỗi (component, archetype): đi qua **Contract** + **Edge-case matrix** của archetype; phần còn lại của màn đi qua 9 trục `axes.md`.
   Kết quả mỗi rule: `PASS` (có bằng chứng) / `FAIL` (rule, file:line, hiện tượng user thấy) / `N/A` (lý do) / `UNVERIFIED` (cần runtime).
   App lớn: chia theo feature group cho subagent song song, mỗi agent nhận đường dẫn KB + danh sách màn + format báo cáo; controller gộp và khử trùng.
4. **Runtime** (chỉ khi mức `runtime` và có device): kiểm các `UNVERIFIED` theo `$KB/runbooks/runtime-verification.md`
   (UI test, uiautomator bounds cho IME, screenrecord + ffmpeg cho nháy, kịch bản back/rotate/background/process death). Lưu bằng chứng.
5. **Report.** Ghi `plans/reports/ui-ux-audit-<yymmdd-hhmm>-<scope>.md` trong repo app (theo naming của project nếu có):
   - Tóm tắt: số màn, số finding theo severity, số UNVERIFIED.
   - Bảng finding: `ID | Severity | Screen | Rule | Hiện tượng | file:line | Hướng sửa | Verify`.
   - Severity: `critical` (mất tiền/dữ liệu, crash) · `high` (sai trạng thái, chặn luồng, vi phạm ad policy) · `medium` (nháy, mất vị trí, lệch đồng bộ) · `low` (polish).
   - Đề xuất gom fix theo **archetype** (một component dùng chung sửa nhiều màn), không theo màn.
   - Danh sách UNVERIFIED còn lại và câu hỏi mở.

## Rules

- Read-only mặc định: không sửa code, không commit. Chỉ fix khi user yêu cầu — khi đó fix theo Contract của rule và thêm test theo mục Verify.
- `UNVERIFIED` không bao giờ được tính là PASS; không có device thì nói rõ phần runtime chưa chạy.
- Mọi FAIL phải có file:line và mô tả hiện tượng người dùng thấy; nghi vấn từ script chưa xác nhận thì không đưa vào FAIL.
- Không ghi nội dung nhạy cảm (token, query người dùng) vào báo cáo.
- Phát hiện lỗi bắt được bằng grep mà script chưa bắt → đề xuất bổ sung rule vào `ui-ux-scan.sh` ở cuối báo cáo.

## Output contract

Báo cáo markdown ở trên + trả lời user: số finding theo severity, top 5 finding, đường dẫn báo cáo, phần chưa verify, và câu hỏi "có fix không".
Kết thúc bằng `Status: DONE | DONE_WITH_CONCERNS | BLOCKED`.
