---
id: kb-uiux-sheets-dialogs-overlays
scope: team/arch-ui-ux
category: pattern
tags: [compose, bottomsheet, dialog, popup, overlay, back, insets]
---

# Bottom sheet, dialog, popup, overlay

**Nhận diện:** danh sách tập dạng sheet, popup unlock, popup quà, dialog xác nhận, overlay hướng dẫn,
popup recommended khi hết tập.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-OVL-001 | MUST | Hiển thị overlay là **state** (trong UiState hoặc `rememberSaveable`), không phải biến cục bộ mất khi rotation; đóng/mở qua intent. | Popup biến mất hoặc mở lại 2 lần sau rotation. |
| UX-OVL-002 | MUST | Back hệ thống đóng overlay trên cùng trước (`BackHandler` hoặc built-in của `ModalBottomSheet`/`Dialog`), không thoát màn. | Kỳ vọng Android. |
| UX-OVL-003 | MUST | Có quy tắc ưu tiên khi nhiều overlay cùng muốn hiện (gift popup, rate, unlock, ad): **một hàng đợi**, tối đa 1 modal tại một thời điểm. | Popup chồng popup, che nhau. |
| UX-OVL-004 | MUST | Sheet chứa list cuộn: nested scroll hoạt động (kéo list không kéo sheet cho tới khi list ở đầu); nội dung không bị navigation bar che (`navigationBarsPadding` trong sheet). | |
| UX-OVL-005 | MUST | Mở overlay che toàn màn → pause video/timer phía dưới (UX-LF-001); đóng → resume đúng trạng thái. | |
| UX-OVL-006 | MUST | Popup có hành động bất đồng bộ áp đủ `async-action-cta.md` (loading, lỗi, chống tap đúp); đóng popup khi đang xử lý không làm mất kết quả. | |
| UX-OVL-007 | SHOULD | Tap ngoài/scrim: chỉ đóng với popup thông tin; popup thanh toán/quyết định quan trọng theo spec. | |
| UX-OVL-008 | SHOULD | Animation vào/ra không làm nháy nội dung bên dưới (scrim fade, không recreate màn dưới). | UX-TR-001. |
| UX-OVL-009 | FORBIDDEN | Hiện popup trong `LaunchedEffect(Unit)` của màn mà không có cờ "đã hiện" lưu lại. | Hiện lại mỗi lần quay về màn. |

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| STATE | Rotate khi sheet mở; process death khi popup mở |
| LAYOUT | Sheet ở font 2.0 cao hơn màn → cuộn được, nút chính không bị đẩy khỏi màn; landscape |
| INTERACT | Back; tap scrim; kéo sheet xuống khi list đang giữa |
| LIFE | Popup quà + interstitial đến cùng lúc; mở popup rồi background |
| A11Y | Focus vào popup khi mở, trả focus khi đóng; nút đóng có label |

## Detect

- `UX-OVL-009`: `LaunchedEffect(Unit)` set `show…Dialog = true`.
- Review: liệt kê mọi popup có thể tự bật trên một màn → có hàng đợi ưu tiên chưa.

## Verify

- Compose UI test: mở sheet → `Espresso.pressBack()` → sheet đóng, màn còn.
- Device: rotate + back trên mỗi popup.
