---
id: kb-uiux-screen-audit
scope: team/arch-ui-ux
category: runbook
tags: [ux-audit, checklist, compose, qa]
---

# Audit UI/UX chủ động (1 màn hoặc cả app)

Mục tiêu: tìm lỗi hành vi **trước** khi QA/user báo. Chạy khi: clone app mới từ app cũ, sau đợt fix UI theo
Figma, trước release, khi review feature lớn.

## Bước 1 — Inventory archetype

Với mỗi màn (lấy từ screen registry hoặc navigation graph), liệt kê mọi component theo archetype:

```markdown
| Screen | Component (file) | Archetype | Ghi chú |
|---|---|---|---|
| Home | HomeBannerCarousel.kt | carousel-banner | auto-scroll, 5 banner |
| Home | HomeChipRow.kt + content | tabs-pager | chip đổi nội dung bên dưới |
| Search | SearchScreen.kt | search-text-input, ad-slots | banner ad đáy |
```

Component không khớp archetype nào → ghi `unclassified` và xem có cần archetype mới (đề xuất vào KB).

## Bước 2 — Quét tĩnh

```bash
bash <harness>/kb/ui-ux/scripts/ui-ux-scan.sh <app-src-dir> > ux-scan.tsv
```

Mỗi dòng là **nghi vấn** (rule, file:line, gợi ý), không phải kết luận. Đối chiếu với Bước 3.

## Bước 3 — Đi qua contract

Với mỗi cặp (component, archetype): mở file archetype, đi qua **Contract** và **Edge-case matrix**.
Kết quả mỗi rule một trong:

- `PASS` — có bằng chứng (code + test/preview/device).
- `FAIL` — rule id, file:line, mô tả ngắn hiện tượng user thấy.
- `N/A` — lý do (vd. chip chỉ là filter, không có pager).
- `UNVERIFIED` — cần chạy runtime mới kết luận → đưa vào Bước 4.

Áp 9 trục trong `axes.md` cho phần màn không thuộc archetype cụ thể (layout tổng, insets, lifecycle).

## Bước 4 — Kiểm runtime

Mọi `UNVERIFIED` thuộc AX-TRANS, AX-INTERACT, AX-LIFE, AX-LAYOUT(IME), AX-MONET phải kiểm bằng
`runtime-verification.md` (UI test hoặc device). Preview/Figma score **không** đủ cho các trục này.

## Bước 5 — Báo cáo

```markdown
| ID | Severity | Screen | Rule | Hiện tượng | file:line | Hướng sửa | Verify |
|---|---|---|---|---|---|---|---|
| F1 | high | Search | UX-SRCH-002 | Bàn phím đẩy banner ad lên giữa màn | SearchScreen.kt:88 | ad ra ngoài vùng imePadding | device: bounds ad không đổi |
```

Severity: `critical` (mất tiền/dữ liệu, crash), `high` (sai trạng thái, chặn luồng, vi phạm ad policy),
`medium` (nháy, mất vị trí, lệch đồng bộ), `low` (polish).

Gom fix theo **archetype** chứ không theo màn: một `LoopingPager` dùng chung sửa mọi carousel cùng lúc.
Sau khi sửa, rule nào phát hiện được bằng grep nhưng script chưa bắt → bổ sung vào `ui-ux-scan.sh`.

## Ánh xạ lỗi thường gặp → rule

| Triệu chứng | Rule |
|---|---|
| Vuốt nội dung mà tab không đổi / bấm tab không trượt | UX-TAB-001/002 |
| Carousel tới cuối nhảy về đầu, không vuốt ngược được, chấm sai | UX-CAR-001/003/011 |
| Bàn phím đẩy ad/bottom nav lên | UX-SRCH-001/002, UX-AD-003 |
| Nháy đen khi thumbnail → video | UX-VID-001/002/003 |
| Bấm thêm vào list/like mà số không đổi, màn khác không cập nhật | UX-TGL-001/002/003 |
| Back về mất vị trí cuộn / LazyRow về đầu | UX-LST-002, UX-NAV-001 |
| Tap đúp mở 2 màn / trừ coin 2 lần | UX-CTA-001/007, UX-NAV-003 |
| Popup tự hiện lại mỗi lần vào màn | UX-OVL-009 |
| Đồng hồ quà lệch sau khi background | UX-TMR-001/002 |
| Ảnh nháy lại khi quay về màn | UX-IMG-003 |
