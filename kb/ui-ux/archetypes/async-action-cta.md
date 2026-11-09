---
id: kb-uiux-async-action-cta
scope: team/arch-ui-ux
category: pattern
tags: [compose, cta, button, iap, rewarded-ad, double-tap, loading, toast, snackbar]
---

# Nút hành động bất đồng bộ (CTA, mua, unlock, claim) và phản hồi

**Nhận diện:** nút gây request/IAP/xem ad/trừ coin: "Unlock", "Buy", "Watch ad", "Claim", "Check-in",
"Restore", "Continue"; toast/snackbar thông báo kết quả.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-CTA-001 | MUST | Chặn thao tác lặp ở **ViewModel** (state `InProgress` bỏ qua intent mới, hoặc `Mutex`/job đơn), không chỉ ở UI. Nút hiển thị loading và `enabled = false` khi đang chạy. | UX-IN-002 — tap đúp trừ coin 2 lần / mở 2 IAP sheet. |
| UX-CTA-002 | MUST | Mọi kết thúc đều có trạng thái: thành công (feedback + state mới), thất bại (thông báo lý do hiểu được + giữ nguyên trạng thái trước), huỷ (im lặng, trở lại bình thường). Không kết thúc "im lặng" khi lỗi. | UX-A1-001. |
| UX-CTA-003 | MUST | Kết quả bất đồng bộ (IAP callback, reward callback) đến sau khi rời màn vẫn được áp vào nguồn dữ liệu chung, không crash, không mất phần thưởng. | UX-LF-001, mất tiền = lỗi nghiêm trọng nhất. |
| UX-CTA-004 | MUST | Reward ad: chỉ cấp thưởng khi có callback "earned reward"; no-fill/timeout → thông báo + nút thử lại/đường khác; đóng sớm → không thưởng, không treo loading. | UX-MO-003. |
| UX-CTA-005 | MUST | Side-effect một lần (navigate, toast, mở IAP) qua `Channel`/effect flow tiêu thụ một lần — không lưu trong state rồi phát lại khi rotation. | UX-LF-002. |
| UX-CTA-006 | MUST | Toast/snackbar: không chồng nhiều cái cùng lúc (thay cái cũ), không che CTA/bottom nav, đọc được ở font 2.0, nằm trên IME khi bàn phím mở. | |
| UX-CTA-007 | SHOULD | Điều hướng từ click (open detail/player) chống double-tap: bỏ qua click thứ 2 trong ~500ms hoặc khi route đích đã ở trên cùng. | Mở 2 màn chồng nhau. |
| UX-CTA-008 | SHOULD | Nút có text dài/giá: không cắt giá; cho phép 2 dòng hoặc thu nhỏ có kiểm soát; giá theo locale từ store. | UX-LY-003. |
| UX-CTA-009 | FORBIDDEN | `onClick = { scope.launch { repo.purchase() } }` trực tiếp trong Composable; `delay()` để "chờ cho chắc". | Logic trong UI, race, không test được. |

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| INTERACT | Tap đúp/tap 5 lần nhanh; tap 2 CTA khác nhau cùng lúc |
| ASYNC | Mạng chậm; lỗi server; IAP pending/cancel; reward no-fill; ad đóng sớm |
| LIFE | Bấm Buy → background giữa luồng IAP → quay lại; rotate khi đang loading |
| STATE | Coin/unlock cập nhật ở mọi màn sau thành công (xem toggle-counter-actions) |
| LAYOUT | Font 2.0 + ngôn ngữ dài trên nút giá |
| A11Y | Nút loading có mô tả "Đang xử lý"; toast được TalkBack đọc |

## Detect

- `ui-ux-scan.sh` `UX-CTA-009`: `scope.launch` trong lambda `onClick` ở file Composable; `UX-CTA-007`: `onClick = { navController.navigate(` không có guard.

## Verify

- Unit test ViewModel: gửi intent 2 lần liền → repository được gọi 1 lần; lỗi → state cũ + effect lỗi; huỷ → không effect.
- Device: tap đúp nhanh trên mọi CTA trả phí.
