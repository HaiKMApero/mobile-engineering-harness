---
id: kb-uiux-carousel-banner
scope: team/arch-ui-ux
category: pattern
tags: [compose, carousel, banner, pager, endless, indicator, auto-scroll]
---

# Carousel / banner hero / endless swipe

**Nhận diện:** banner hero đầu Home, carousel poster có snap, popup "recommended" vuốt ngang, onboarding
slide có indicator chấm. Mọi thứ "vuốt ngang từng trang + chấm chỉ vị trí".

Quyết định đầu tiên: **carousel vòng (endless)** hay **hữu hạn**. Mặc định banner/hero/recommended = vòng;
onboarding/tutorial/hướng dẫn có bước cuối = hữu hạn. Ghi quyết định vào spec màn.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-CAR-001 | MUST | Carousel vòng dùng **virtual page count** lớn (`100_000` hoặc `Int.MAX_VALUE`) và bắt đầu ở trang giữa căn theo `size`: `start = MID - MID % size + index`. Item thật = `page % size`. | Vuốt được cả 2 chiều ngay từ trang đầu; không có cú nhảy về 0. |
| UX-CAR-002 | MUST | `size <= 1`: pageCount = 1, tắt `userScrollEnabled`, không auto-scroll, ẩn indicator. `size == 0`: không render (hoặc skeleton). | Tránh `% 0` crash và carousel 1 ảnh tự trượt. |
| UX-CAR-003 | MUST | Indicator đọc `currentPage % size` (và `currentPageOffsetFraction` nếu indicator chạy theo tay) — không đọc `currentPage` thô. | Indicator đúng ở mọi vòng. |
| UX-CAR-004 | MUST | Pager `key = { "${keys[it % size]}:$it" }` — key gồm id item **và** page ảo. | Key trùng giữa các vòng làm Compose crash/nháy. |
| UX-CAR-005 | MUST | Auto-scroll chỉ chạy khi: `size > 1`, lifecycle RESUMED, không đang kéo (`collectIsDraggedAsState`), animation được bật. Restart delay sau mỗi lần user kéo/đổi trang (`LaunchedEffect(settledPage, isDragged, lifecycle)`). | UX-LF-001; không giật trang ngay sau khi user vừa vuốt. |
| UX-CAR-006 | MUST | Dữ liệu đổi (refresh CMS): giữ banner đang xem theo **key**, tính lại start; bọc trong `key(keys)` để pageCount/key/content đổi đồng thời. | UX-ST-004; tránh index cũ trỏ sai item. |
| UX-CAR-007 | MUST | Click trên trang dùng item `banners[page % size]` tại thời điểm click, không capture index lúc compose cũ. | Mở nhầm phim. |
| UX-CAR-008 | SHOULD | Gần biên virtual (`currentPage == pageCount - 1`) thì `scrollToPage` về trang tương đương ở giữa trước khi animate tiếp. | An toàn khi app mở rất lâu. |
| UX-CAR-009 | SHOULD | Analytics impression/click dùng index thật (1-based nếu spec yêu cầu) và chỉ log khi `settledPage` đổi. | Số liệu không bị nhân. |
| UX-CAR-010 | SHOULD | Peek (thấy mép trang bên cạnh) bằng `contentPadding` + `pageSize = PageSize.Fixed(...)`; không dùng `Modifier.offset`. | Snap đúng và đo được. |
| UX-CAR-011 | FORBIDDEN | Endless giả bằng cách khi tới trang cuối gọi `scrollToPage(0)` (giật ngược), hoặc nhân bản list `items + items + items`. | Thấy cú nhảy; key trùng; tốn bộ nhớ. |

Áp dụng **mọi chỗ** cùng archetype trong app (hero, recommended popup, ranking pager nếu thiết kế là vòng) —
gom vào một component dùng chung `LoopingPager`, không viết lại logic ở từng màn.

## Reference implementation

```kotlin
private const val LOOP_PAGES = 100_000
fun loopStart(index: Int, size: Int) = if (size <= 1) 0 else LOOP_PAGES / 2 - (LOOP_PAGES / 2) % size + index

@Composable
fun <T> LoopingPager(
    items: List<T>, key: (T) -> Any, autoScrollMs: Long?, modifier: Modifier = Modifier,
    indicator: @Composable (count: Int, current: Int, position: () -> Float) -> Unit,
    page: @Composable (item: T, realIndex: Int) -> Unit,
) {
    if (items.isEmpty()) return
    val size = items.size
    val keys = items.map(key)
    var selectedKey by rememberSaveable { mutableStateOf<Any?>(null) } // key phải Saveable (String/Long)
    key(keys) {
        val pager = rememberPagerState(initialPage = loopStart(keys.indexOf(selectedKey).coerceAtLeast(0), size)) {
            if (size > 1) LOOP_PAGES else 1
        }
        LaunchedEffect(pager) { snapshotFlow { pager.settledPage }.collect { selectedKey = keys[it % size] } }
        val dragged by pager.interactionSource.collectIsDraggedAsState()
        val lifecycle by LocalLifecycleOwner.current.lifecycle.currentStateAsState()
        LaunchedEffect(pager.settledPage, dragged, lifecycle) {
            if (autoScrollMs == null || size <= 1 || dragged || lifecycle != Lifecycle.State.RESUMED) return@LaunchedEffect
            while (true) {
                delay(autoScrollMs)
                if (pager.isScrollInProgress) continue
                if (pager.currentPage >= pager.pageCount - 2) pager.scrollToPage(loopStart(pager.currentPage % size, size))
                pager.animateScrollToPage(pager.currentPage + 1)
            }
        }
        Column(modifier) {
            HorizontalPager(state = pager, key = { "${keys[it % size]}:$it" }, userScrollEnabled = size > 1) {
                page(items[it % size], it % size)
            }
            if (size > 1) indicator(size, pager.currentPage % size) {
                pager.currentPage % size + pager.currentPageOffsetFraction
            }
        }
    }
}
```

Bản production đã dùng: AAP883 `presenter/feature/home/components/HomeBannerCarousel.kt`
(`bannerLoopStart`, `retainedBannerPage`, auto-scroll theo lifecycle + drag, indicator theo offset).

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| STATE | 0 / 1 / 2 / 7 item; refresh đổi thứ tự khi đang xem item 3 |
| TRANS | Auto-scroll qua biên vòng không thấy giật; ảnh trang kế đã preload |
| LAYOUT | 320dp, font 2.0 (title trên banner), tỉ lệ ảnh giữ nguyên |
| INTERACT | Vuốt trái ngay từ trang đầu → ra item cuối; vuốt nhanh nhiều trang; pager trong LazyColumn không chặn cuộn dọc |
| LIFE | Sang tab khác / background → auto-scroll dừng; quay lại → tiếp tục, đúng item |
| ASYNC | Banner loading = skeleton đúng kích thước (UX-TR-002); lỗi tải ảnh không làm vỡ trang |
| A11Y | Mỗi trang có mô tả "Banner i trên n"; auto-scroll tắt khi TalkBack bật hoặc reduce motion |
| PERF | Không giữ bitmap của 100k trang — chỉ trang hiển thị + `beyondViewportPageCount` |

## Detect

- `ui-ux-scan.sh` rule `UX-CAR-001`: `HorizontalPager` trong file tên/nhóm banner|hero|carousel|recommend mà không có `% size` + page count ảo.
- `UX-CAR-005`: `while (true)` + `delay` trong `LaunchedEffect` không kiểm lifecycle/drag.

## Verify

- Unit test thuần cho `loopStart(index, size)` (size 0/1/n, index biên) và mapping `page % size`.
- Compose UI test: ở trang đầu `swipeRight()` → item hiển thị là item cuối, indicator chấm cuối.
- Device: để Home 30s, chuyển tab rồi quay lại → auto-scroll không nhảy nhiều trang cùng lúc.
