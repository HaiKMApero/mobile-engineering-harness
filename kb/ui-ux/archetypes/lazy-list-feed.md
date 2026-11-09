---
id: kb-uiux-lazy-list-feed
scope: team/arch-ui-ux
category: pattern
tags: [compose, lazycolumn, lazyrow, grid, paging, scroll-restore, keys]
---

# Lazy list / section ngang / grid / paging

**Nhận diện:** Home nhiều section (mỗi section một `LazyRow`), list kết quả, grid poster, history, ranking,
danh sách tập.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-LST-001 | MUST | `items(list, key = { it.id }, contentType = { it.type })` cho mọi lazy list có dữ liệu động (`contentType` bắt buộc khi list có hơn một loại item: header, ad, card). Key là id thực thể, duy nhất trong list (cùng phim ở 2 section → key gồm section). | Không key: thêm/xoá đầu list làm nhảy scroll, animation sai, state item lẫn nhau. |
| UX-LST-002 | MUST | Scroll position của list chính và **từng `LazyRow` lồng** giữ khi back từ Detail và khi đổi tab bottom nav: state hoist bằng `rememberLazyListState()` ở cấp ổn định (hoặc `rememberSaveable` map theo section key). | UX-LF-003 — lỗi phổ biến: LazyRow về đầu mỗi lần quay lại. |
| UX-LST-003 | MUST | Refresh/pull-to-refresh không reset scroll và không thay list bằng skeleton khi đã có data. | UX-TR-003. |
| UX-LST-004 | MUST | Paging: trigger tải trang sau khi còn N item (N≈5) bằng `snapshotFlow { lastVisibleIndex }`, chặn gọi trùng khi đang tải; footer loading/error + retry; hết dữ liệu thì không gọi nữa. | UX-AS-003. |
| UX-LST-005 | MUST | Empty state riêng cho list rỗng (không để vùng trắng) và section rỗng thì **ẩn cả header section** theo spec. | UX-AS-001. |
| UX-LST-006 | MUST | Section ngang trong list dọc: không đặt `LazyRow` có chiều cao đo theo nội dung không cố định (gây nhảy khi ảnh tải) — cố định chiều cao theo tỉ lệ card. | UX-TR-002. |
| UX-LST-007 | SHOULD | Nested scroll: không lồng `LazyColumn` trong `Column(verticalScroll)`; dùng một `LazyColumn` với `item {}` cho header/section. | Crash "infinite height" hoặc mất lazy. |
| UX-LST-008 | SHOULD | Nút "lên đầu" / tap lại tab bottom nav đang chọn → cuộn về đầu (`animateScrollToItem(0)`). | Kỳ vọng phổ biến của user. |
| UX-LST-009 | SHOULD | Impression analytics theo item **thực sự hiển thị** ≥ 50% và chỉ một lần mỗi lần xem màn. | Số liệu không bị nhân khi recomposition. |
| UX-LST-011 | MUST | List mở để tiếp tục một vị trí (tập đang xem, mục vừa chọn, kết quả vừa mở) cuộn tới vị trí đó khi mở lần đầu (`initialFirstVisibleItemIndex` hoặc `scrollToItem` một lần), không bắt đầu từ đầu. | Grid 120 tập mở ở EP.80 mà hiện EP.1. |
| UX-LST-010 | FORBIDDEN | `list.forEach { Item(it) }` trong `Column(verticalScroll)` cho list dài/không giới hạn. | Không lazy → jank, OOM. |

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| STATE | Item bị xoá/thêm khi đang xem (unsave ở My List) → không nhảy scroll, đúng item biến mất |
| TRANS | Ảnh tải dần không làm card đổi cao; refresh không nháy |
| LAYOUT | Font 2.0: title 2 dòng không đẩy card khác cao; grid 2 cột trên 320dp |
| INTERACT | Fling dài; LazyRow ngang trong pager ngang (cướp cử chỉ?) |
| LIFE | Cuộn sâu section 3 → Detail → back → đúng vị trí cả dọc lẫn ngang |
| ASYNC | Trang 2 lỗi → footer retry; mất mạng đầu màn → error toàn màn |
| PERF | Cuộn nhanh không jank; `contentType` cho list nhiều loại item |

## Detect

- `ui-ux-scan.sh` `UX-LST-001`: `items(` / `itemsIndexed(` trong Lazy* không có `key =`.
- `UX-LST-010`: `.forEach {` bên trong `Column(` có `verticalScroll`.
- `UX-LST-002`: `rememberLazyListState()` khai báo bên trong `items {}` của list cha (state mất khi item bị dispose).

## Verify

- Compose UI test: cuộn tới index 20 → navigate → back → `assertIsDisplayed` item 20.
- Device: Home → cuộn section ngang tới card 8 → mở Detail → back.
