---
id: kb-uiux-timers-countdown
scope: team/arch-ui-ux
category: pattern
tags: [compose, timer, countdown, auto-advance, check-in, reward, clock]
---

# Đếm ngược, auto-advance, phần thưởng theo thời gian

**Nhận diện:** hộp quà đếm ngược, check-in theo ngày, tự chuyển tập kế sau N giây, auto-scroll, OTP resend,
khuyến mãi hết hạn.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-TMR-001 | MUST | Thời điểm kết thúc lưu là **mốc tuyệt đối** (`endAtElapsedRealtime` hoặc epoch server), hiển thị = `end - now`. Không lưu "còn lại 300s" rồi đếm lùi bằng `delay(1000)`. | `delay` trôi, dừng khi background → lệch. |
| UX-TMR-002 | MUST | Chỉ tick UI khi màn RESUMED; khi quay lại tính lại từ mốc. Hết giờ khi đang background → xử lý đúng một lần khi quay lại. | UX-LF-001. |
| UX-TMR-003 | MUST | Logic "claim/đổi ngày" chạy ở ViewModel/use case, idempotent (claim 2 lần chỉ thưởng 1). Mốc ngày theo timezone đã thống nhất (local hay server), test qua nửa đêm và đổi múi giờ. | UX-IN-002. |
| UX-TMR-004 | MUST | Chống gian lận đổi giờ máy khi có thưởng: dùng `elapsedRealtime` cho khoảng ngắn, giờ server cho mốc ngày. | |
| UX-TMR-005 | SHOULD | Text đếm ngược dùng chữ số `tabular` hoặc width cố định → không rung layout mỗi giây. | UX-TR-002. |
| UX-TMR-006 | SHOULD | Auto-advance (tập kế tiếp) có nút huỷ và tắt khi user đang tương tác. | |
| UX-TMR-007 | FORBIDDEN | `while (true) { delay(1000); remaining-- }` trong Composable. | |

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| LIFE | Background 10 phút rồi quay lại; khoá màn hình; process death giữa đếm ngược |
| STATE | Hai màn cùng hiện một đồng hồ quà → cùng giá trị |
| ASYNC | Claim khi mất mạng; claim đúng lúc về 0 |
| LAYOUT | Font 2.0 trên badge đếm ngược nhỏ |
| Clock | Đổi giờ máy +1 ngày; qua nửa đêm; đổi timezone |

## Detect

- `ui-ux-scan.sh` `UX-TMR-007`: `while (true)` + `delay(1000` trong file Composable.

## Verify

- Unit test với clock giả (`TestScope.currentTime`/clock inject): hết giờ, quay lại sau background, claim 2 lần.
