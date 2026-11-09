---
id: kb-uiux-search-text-input
scope: team/arch-ui-ux
category: pattern
tags: [compose, search, textfield, ime, insets, keyboard, debounce]
---

# Search và ô nhập liệu (IME)

**Nhận diện:** màn search, ô nhập tên/feedback/promo code, mọi `TextField`/`BasicTextField`.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-SRCH-001 | MUST | Chọn **một** cơ chế IME: Activity `adjustResize` + edge-to-edge và xử lý bằng `WindowInsets.ime` trong Compose. Chỉ phần cần tránh bàn phím (list kết quả, ô nhập dính đáy) nhận `Modifier.imePadding()`/`imeNestedScroll`. | Đặt `imePadding` lên cả `Scaffold`/root → mọi thứ, kể cả banner ad và bottom nav, bị đẩy lên (UX-LY-001). |
| UX-SRCH-002 | MUST | Banner ad / bottom bar trên màn có ô nhập: đặt **ngoài** vùng được pad IME; khi bàn phím mở thì hoặc ẩn ad, hoặc để bàn phím che ad — theo spec, không để ad trôi lên giữa màn. | Ad trôi lên che gợi ý và dễ bấm nhầm (UX-MO-002). |
| UX-SRCH-003 | MUST | Không cộng dồn insets: chỉ một tầng tiêu thụ `ime`/`navigationBars` (`consumeWindowInsets` sau khi pad). | Khoảng trắng gấp đôi trên bàn phím. |
| UX-SRCH-004 | MUST | Gõ liên tục: debounce 250–400ms cho gợi ý; submit (IME action Search) bỏ qua debounce. Kết quả cũ về muộn không ghi đè (`collectLatest`/`flatMapLatest` hoặc so query). | UX-AS-002. |
| UX-SRCH-005 | MUST | Trạng thái: rỗng (gợi ý/recent/trending), đang tìm, có kết quả, không có kết quả (kèm gợi ý), lỗi mạng (retry). | UX-AS-001. |
| UX-SRCH-006 | MUST | Query, scroll kết quả sống qua rotation và back từ Detail; quay lại không tự bật bàn phím nếu user đã đang xem kết quả. | UX-LF-003. |
| UX-SRCH-007 | MUST | Cuộn list kết quả → ẩn bàn phím (`LocalSoftwareKeyboardController.hide()` khi bắt đầu kéo). Bấm vào kết quả → ẩn bàn phím trước khi điều hướng. | Bàn phím che nửa kết quả. |
| UX-SRCH-008 | SHOULD | Mở màn search: focus ô nhập + mở bàn phím sau khi màn đã vẽ (`LaunchedEffect` + `awaitFrame` hoặc `FocusRequester` trong `onGloballyPositioned`). | Tránh bàn phím bật rồi tắt. |
| UX-SRCH-009 | SHOULD | Nút xoá (✕) hiện khi có text; recent search xoá được từng mục; trim khoảng trắng, query rỗng không submit. | |
| UX-SRCH-010 | FORBIDDEN | Log/analytics chứa nội dung query tự do. | Privacy. |

## Reference implementation (bố cục)

```kotlin
Scaffold(
    contentWindowInsets = WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal),
    bottomBar = { BannerAdSlot(Modifier.navigationBarsPadding()) }, // không imePadding → không bị đẩy
) { inner ->
    Column(Modifier.padding(inner).consumeWindowInsets(inner)) {
        SearchField(query, onQueryChange)
        SearchResults(
            state,
            Modifier.weight(1f).imePadding(),   // chỉ list tránh bàn phím
        )
    }
}
```

Nếu spec muốn ẩn ad khi gõ: `val imeVisible = WindowInsets.isImeVisible` → không render slot (giữ trạng thái load).
Lưu ý: với `adjustResize`, hệ thống thu nhỏ cả cửa sổ trên API < 30 khi **không** bật edge-to-edge → bottomBar vẫn bị đẩy. Bật `enableEdgeToEdge()` để Compose tự quyết qua insets.

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| LAYOUT | Bàn phím mở/đóng: ad, bottom nav đứng yên (hoặc ẩn theo spec); gesture nav và 3-button nav; bàn phím nổi/split trên tablet |
| INTERACT | Gõ nhanh 10 ký tự; xoá hết; bấm recent; bấm kết quả khi bàn phím đang mở |
| ASYNC | Mạng chậm: query A rồi B → chỉ hiện B; không có kết quả; lỗi |
| LIFE | Rotate khi bàn phím mở; back từ Detail → query + vị trí cuộn giữ nguyên |
| A11Y | Ô nhập có label; IME action = Search |

## Detect

- `ui-ux-scan.sh` `UX-SRCH-001`: `imePadding()` trên `Scaffold`/root `Box`/`Column(Modifier.fillMaxSize()...imePadding`, hoặc feature có cả TextField và banner ad.
- Manifest `adjustResize` mà không có `enableEdgeToEdge` → kiểm tra trên API 28–29.

## Verify

- Device (bắt buộc — preview không có bàn phím): mở search, gõ, chụp màn trước/sau mở bàn phím; ad không đổi toạ độ (`uiautomator dump` so `bounds` của ad).
- Compose UI test cho debounce/race với `TestDispatcher` ở ViewModel.
