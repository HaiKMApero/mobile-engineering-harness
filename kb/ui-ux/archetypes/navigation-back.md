---
id: kb-uiux-navigation-back
scope: team/arch-ui-ux
category: pattern
tags: [compose, navigation, bottom-nav, back, deep-link, state-restore]
---

# Điều hướng, bottom nav, back, deep link

**Nhận diện:** bottom navigation, mở Detail/Player từ nhiều nơi, back, deep link/notification, splash → home.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-NAV-001 | MUST | Đổi tab bottom nav giữ state từng tab: `navigate(route) { popUpTo(startDestination) { saveState = true }; launchSingleTop = true; restoreState = true }`. | Quay lại tab Home phải đúng chỗ cũ. |
| UX-NAV-002 | MUST | Chọn lại tab đang mở → cuộn về đầu / về root của tab (không mở chồng). | |
| UX-NAV-003 | MUST | Điều hướng từ click có chống trùng: bỏ qua nếu lifecycle của entry hiện tại không RESUMED (`currentBackStackEntry.lifecycle.currentState`), hoặc debounce. | UX-IN-002: double-tap mở 2 Detail. |
| UX-NAV-004 | MUST | Back từ màn sâu về đúng nơi đã đi vào (Detail mở từ Search → back về Search với query còn nguyên). | UX-LF-003. |
| UX-NAV-005 | MUST | Back ở root Home: theo spec (thoát / dialog thoát / interstitial) — một hành vi duy nhất, không thoát khi đang có overlay. | |
| UX-NAV-006 | MUST | Deep link/notification mở đúng màn với back stack hợp lý (back về Home, không thoát app). | |
| UX-NAV-007 | MUST | Tham số route là id ổn định (không truyền object lớn/URL tạm hết hạn); màn đích tự tải lại từ id khi process death. | UX-LF-004. |
| UX-NAV-008 | SHOULD | Badge trên tab (số mục My List, quà) đọc từ nguồn chung (xem toggle-counter-actions). | |
| UX-NAV-009 | FORBIDDEN | Ẩn/hiện bottom nav bằng điều kiện làm nội dung nhảy (đổi padding) mà không animate; bottom nav bị IME đẩy lên. | |

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| STATE | Home cuộn sâu → My List → Home: đúng vị trí; tab bị kill do process death |
| INTERACT | Double tap card; tap 2 card khác nhau cùng lúc; tap tab liên tục |
| LIFE | Mở từ notification khi app đã chạy / đã bị kill |
| LAYOUT | Bottom nav font 2.0 (nhãn), gesture nav |

## Detect

- `ui-ux-scan.sh` `UX-NAV-001`: `navigate(` cho route tab không có `restoreState`.
- `UX-NAV-003`: `onClick = { navController.navigate(` hoặc `onOpen…(id)` gọi thẳng navigate không guard.

## Verify

- Compose navigation test (`TestNavHostController`): double click → back stack chỉ thêm 1 entry.
- Device: chạy kịch bản "cuộn – mở – back" trên mỗi tab.
