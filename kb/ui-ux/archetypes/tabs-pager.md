---
id: kb-uiux-tabs-pager
scope: team/arch-ui-ux
category: pattern
tags: [compose, tabs, chips, pager, ScrollableTabRow, HorizontalPager]
---

# Tabs / chips điều khiển nội dung

**Nhận diện:** một hàng tab, chip, segmented control mà khi chọn thì vùng nội dung bên dưới đổi theo
(Home chip "Popular / New / Romance", tab "Episodes / Similar", tab My List "Saved / History").

Chip chỉ là **filter** (lọc cùng một list, không có hiệu ứng trượt trang) thì vẫn áp AX-STATE và AX-ASYNC, nhưng không bắt buộc pager.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-TAB-001 | MUST | Nội dung theo tab đặt trong `HorizontalPager`; hàng tab là `ScrollableTabRow` (M3 ≥ 1.4: `PrimaryScrollableTabRow`/`SecondaryScrollableTabRow`) hoặc `TabRow` khi ≤ 4 tab cố định. Cả hai dùng **chung một `PagerState`**. | Một nguồn sự thật cho tab đang chọn; vuốt và bấm luôn khớp (UX-IN-001). |
| UX-TAB-002 | MUST | Tab index hiển thị = `pagerState.currentPage` (hoặc `targetPage` khi đang animate), không phải biến `selectedIndex` riêng. | Biến riêng sẽ lệch khi vuốt. |
| UX-TAB-003 | MUST | Bấm tab → `animateScrollToPage`; job cũ bị cancel khi bấm tab khác liên tục. | Tránh 2 animation tranh nhau, pager dừng giữa 2 trang. |
| UX-TAB-004 | MUST | Commit selection (gọi ViewModel, analytics "tab view") theo `settledPage` qua `snapshotFlow { settledPage }.distinctUntilChanged().drop(1)` — không theo `currentPage`. | `currentPage` đổi liên tục khi vuốt qua nhiều trang → log/request thừa. |
| UX-TAB-005 | MUST | Pager `key = { tabs[it].id }`; state trang con (scroll, filter) giữ bằng `rememberSaveableStateHolder().SaveableStateProvider(key)`. | Quay lại tab cũ vẫn ở đúng vị trí cuộn (UX-LF-003). |
| UX-TAB-006 | MUST | Danh sách tab đổi (CMS, remote config) thì khôi phục tab đang chọn theo **key**, không theo index; tab biến mất → về tab đầu. Bọc pager trong `key(tabKeys) { ... }`. | UX-ST-004. |
| UX-TAB-007 | SHOULD | Indicator đi theo ngón tay: dùng `pagerState.currentPage + currentPageOffsetFraction` cho vị trí indicator. | Cảm giác liền mạch. |
| UX-TAB-008 | SHOULD | Tab đang chọn tự cuộn vào giữa/khung nhìn (`ScrollableTabRow` tự làm; hàng chip tự làm thì `LazyListState.animateScrollToItem`). | Tab cuối bị khuất khi chọn bằng vuốt. |
| UX-TAB-009 | SHOULD | Trang con nặng tải dữ liệu lười theo trang đã settle; `beyondViewportPageCount` ≤ 1. | Tránh tải 6 tab cùng lúc. |
| UX-TAB-010 | FORBIDDEN | `when (selected) { 0 -> ListA(); 1 -> ListB() }` để đổi nội dung theo tab khi thiết kế có hiệu ứng trượt/vuốt ngang. | Mất vuốt, mất state từng tab, nội dung giật. |

## Reference implementation

```kotlin
@Composable
fun <T> TabbedPager(
    tabs: List<T>,
    key: (T) -> Any,
    selectedKey: Any?,
    onSettled: (T) -> Unit,
    tab: @Composable (T, selected: Boolean, onClick: () -> Unit) -> Unit,
    page: @Composable (T) -> Unit,
) {
    if (tabs.isEmpty()) return
    val keys = tabs.map(key)
    val saveable = rememberSaveableStateHolder()
    val onSettledLatest by rememberUpdatedState(onSettled)
    key(keys) {
        val pager = rememberPagerState(initialPage = keys.indexOf(selectedKey).coerceAtLeast(0)) { tabs.size }
        val scope = rememberCoroutineScope()
        var job by remember { mutableStateOf<Job?>(null) }
        LaunchedEffect(pager) {
            snapshotFlow { pager.settledPage }.distinctUntilChanged().drop(1)
                .collect { onSettledLatest(tabs[it]) }
        }
        Column {
            SecondaryScrollableTabRow(selectedTabIndex = pager.currentPage, edgePadding = 16.dp) {
                tabs.forEachIndexed { i, t ->
                    tab(t, i == pager.currentPage) {
                        job?.cancel(); job = scope.launch { pager.animateScrollToPage(i) }
                    }
                }
            }
            HorizontalPager(state = pager, key = { keys[it] }, modifier = Modifier.weight(1f)) { i ->
                saveable.SaveableStateProvider(keys[i]) { page(tabs[i]) }
            }
        }
    }
}
```

Bản production đã dùng: AAP883 `presenter/components/tabs/FilterPager.kt` (selection theo key, `settledPage`, `SaveableStateProvider`, cancel scroll job).

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| STATE | Đổi thứ tự/xoá tab từ remote → tab đang chọn giữ theo key |
| TRANS | Bấm tab xa (0 → 5) — không nháy trang trắng giữa đường |
| LAYOUT | Font 2.0, nhãn tab dài, 320dp — tab cuộn ngang, không cắt chữ |
| INTERACT | Vuốt nhanh qua 3 trang; bấm 2 tab liên tiếp nhanh; list dọc trong trang không cướp vuốt ngang |
| LIFE | Rotate / back từ Detail → đúng tab, đúng vị trí cuộn của tab đó |
| ASYNC | Trang con loading/empty/error riêng, không làm cả pager trắng |
| A11Y | Tab có `Role.Tab` + `selected` |

## Detect

- `ui-ux-scan.sh` rule `UX-TAB-001`: file có hàng chip/tab có state chọn mà feature không dùng `PagerState`.
- Review: tìm `selectedIndex`/`selectedTab` nằm cạnh `when(`/`if (` chọn composable nội dung.

## Verify

- Compose UI test: `performTouchInput { swipeLeft() }` trên pager → assert tab thứ 2 `isSelected()`; bấm tab 3 → assert nội dung trang 3 hiển thị và tab 3 selected.
- Unit test (ViewModel): chỉ nhận đúng 1 sự kiện "tab settled" khi vuốt qua nhiều trang.
- Device: back từ Detail về → tab và scroll giữ nguyên.
