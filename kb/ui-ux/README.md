---
id: kb-uiux-index
scope: team/arch-ui-ux
category: runbook
tags: [compose, ui, ux, checklist, index]
---

# UI/UX behaviour KB (Compose)

KB này phủ **lỗi hành vi UI/UX** — loại lỗi mà so ảnh preview/Figma không bắt được: tab và pager lệch nhau,
bàn phím đẩy quảng cáo, nháy khi chuyển thumbnail → video, bấm "thêm vào list" mà số không tăng, carousel
không vuốt vòng được, mất vị trí cuộn khi quay lại, bấm 2 lần mở 2 màn...

## Vì sao không viết theo từng issue

Viết KB sau mỗi bug thì KB luôn chạy sau bug. KB này đi theo hướng ngược lại: **liệt kê trước mọi loại
component có trên màn hình (archetype) và mọi trục có thể hỏng (axis)**, rồi định nghĩa hợp đồng hành vi
cho từng ô của ma trận. Một màn hình mới chỉ cần nhận diện archetype là có ngay checklist đầy đủ, kể cả
những lỗi chưa từng xảy ra.

```
            AX-STATE  AX-TRANS  AX-LAYOUT  AX-INTERACT  AX-LIFE  AX-ASYNC  AX-A11Y  AX-PERF  AX-MONET
tabs-pager     ●         ●         ●          ●           ●                  ●
carousel       ●         ●         ●          ●           ●         ●        ●        ●
lazy-list      ●         ●         ●          ●           ●         ●        ●        ●        ●
video          ●         ●         ●          ●           ●         ●        ●        ●        ●
search/input   ●         ●         ●          ●           ●         ●        ●                 ●
...            (ma trận đầy đủ: mỗi file archetype có mục "Edge-case matrix" theo từng axis)
```

## Cấu trúc

| File | Dùng khi |
|---|---|
| [`axes.md`](axes.md) | 9 trục lỗi xuyên suốt + bất biến (invariant) áp cho mọi component |
| [`archetypes/tabs-pager.md`](archetypes/tabs-pager.md) | Tab, chip, segmented control điều khiển nội dung |
| [`archetypes/carousel-banner.md`](archetypes/carousel-banner.md) | Banner hero, carousel, auto-scroll, endless swipe, indicator |
| [`archetypes/lazy-list-feed.md`](archetypes/lazy-list-feed.md) | LazyColumn/Row/Grid, section ngang, paging, scroll restore |
| [`archetypes/video-player-feed.md`](archetypes/video-player-feed.md) | Player, thumbnail → video, feed dọc kiểu short video |
| [`archetypes/search-text-input.md`](archetypes/search-text-input.md) | Ô search, TextField, IME, gợi ý, kết quả |
| [`archetypes/toggle-counter-actions.md`](archetypes/toggle-counter-actions.md) | Like, thêm vào list, follow, số đếm, trạng thái dùng chung giữa màn |
| [`archetypes/async-action-cta.md`](archetypes/async-action-cta.md) | Nút gọi mạng/IAP/ads, unlock, claim; feedback toast/snackbar |
| [`archetypes/sheets-dialogs-overlays.md`](archetypes/sheets-dialogs-overlays.md) | Bottom sheet, dialog, popup, overlay chồng nhau |
| [`archetypes/image-media-loading.md`](archetypes/image-media-loading.md) | Ảnh poster, placeholder, crossfade, tỉ lệ |
| [`archetypes/navigation-back.md`](archetypes/navigation-back.md) | Bottom nav, back, deep link, giữ state tab, điều hướng trùng |
| [`archetypes/timers-countdown.md`](archetypes/timers-countdown.md) | Đếm ngược, auto-advance, check-in, quà theo thời gian |
| [`archetypes/ad-slots.md`](archetypes/ad-slots.md) | Banner/native/interstitial/reward ad trong layout |
| [`runbooks/screen-audit.md`](runbooks/screen-audit.md) | Audit chủ động 1 màn / 1 app trước khi QA tìm ra |
| [`runbooks/runtime-verification.md`](runbooks/runtime-verification.md) | Cách chứng minh hành vi khi app chạy (UI test, device, video) |
| [`scripts/ui-ux-scan.sh`](scripts/ui-ux-scan.sh) | Quét tĩnh tìm dấu hiệu nghi vấn theo rule ID |

## Cách dùng theo workflow

| Workflow | Bắt buộc đọc |
|---|---|
| Build màn/component mới (`coding-compose`, `coding-feature`) | Archetype tương ứng → mục **Contract** + **Reference implementation** |
| Review PR (`coding-review`) | Archetype của mọi composable bị sửa → mục **Detect** + **Contract** |
| Fix UI theo Figma (`ui-fix-loop`, `ui-from-figma-update`) | Sau khi đạt điểm Figma, chạy `screen-audit.md` cho màn đó — điểm Figma không chứng minh hành vi |
| Fix bug UI (`bug`, `bug-fixer`) | Tìm rule ID trùng triệu chứng → sửa đúng contract, thêm test ở mục **Verify** |
| Audit app (trước release, sau khi clone app) | `runbooks/screen-audit.md` + `scripts/ui-ux-scan.sh` |

## Quy ước

- Rule ID `UX-<AREA>-<NNN>`; mức **MUST / SHOULD / FORBIDDEN** theo CONTRIBUTING.
- Mỗi rule có: lý do 1 câu, cách phát hiện (tĩnh hoặc runtime), cách verify.
- Code mẫu là Compose Foundation/Material3 chuẩn; đối chiếu version của project trước khi copy.
- Project rule (CLAUDE.md, quyết định của user) thắng KB này. Một rule không áp dụng → ghi `N/A + lý do` trong audit, không im lặng bỏ qua.
- Thêm rule mới: chỉ khi nó khái quát được cho archetype (không gắn tên app/feature), kèm Verify. Bug cụ thể của một app thuộc `projects/<app>`.

Frontmatter (`scope`, `category`, `tags`) theo enum của team-knowledge (`docs/knowledge-base-ops.md`) để có thể `kb_push` nguyên file sang team-knowledge khi cần.
