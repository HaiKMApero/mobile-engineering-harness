---
id: kb-uiux-ad-slots
scope: team/arch-ui-ux
category: pattern
tags: [compose, ads, banner, native, interstitial, rewarded, layout-shift, ime]
---

# Slot quảng cáo trong layout

**Nhận diện:** banner/native ad trong màn (đầu/đáy màn, giữa list), interstitial khi chuyển màn,
reward ad để mở khoá.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-AD-001 | MUST | Slot banner/native giữ chiều cao cố định theo format ngay từ đầu (placeholder/shimmer) — ad về không đẩy nội dung. | UX-MO-001. |
| UX-AD-002 | MUST | No-fill / tắt bởi remote config / user premium: slot **thu gọn** (hoặc không render) theo một quy tắc duy nhất; nếu thu gọn khi user đang nhìn thì animate, không nhảy. | |
| UX-AD-003 | MUST | Slot đáy màn nằm ngoài vùng `imePadding` — bàn phím không đẩy ad lên (xem search-text-input UX-SRCH-002). | UX-MO-002. |
| UX-AD-004 | MUST | Ad không đặt sát CTA chính/khu vực tap thường xuyên; không xuất hiện ở vị trí item vừa bị dịch chuyển (tránh bấm nhầm — vi phạm policy). | Policy AdMob. |
| UX-AD-005 | MUST | Native ad trong list: là item có `key` và `contentType` riêng, vị trí cố định theo index logic; không reload mỗi lần cuộn qua. | UX-PF-001. |
| UX-AD-006 | MUST | Full-screen ad: pause media/timer, chặn input phía dưới; đóng/fail → tiếp tục luồng đã định (điều hướng vẫn diễn ra). Không chặn user nếu ad không tải được trong timeout. | UX-MO-003. |
| UX-AD-007 | SHOULD | Ad slot tôn trọng insets (gesture nav) và dark mode của native template. | |
| UX-AD-009 | MUST | Full-screen ad gắn với một màn/sheet chỉ được `show()` khi host còn hiển thị; job tải/hiện ad bị huỷ khi user đóng host (không chạy trên scope sống lâu hơn host). | Ad bật lên sau khi user đã đóng popup unlock. |
| UX-AD-008 | FORBIDDEN | Đặt banner trong `Scaffold` content cùng `Column` với nội dung có `imePadding` lên root; dùng `wrapContentHeight` cho slot ad. | |

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| LAYOUT | Bàn phím mở; gesture vs 3-button nav; 320dp; font 2.0 với native ad có text |
| ASYNC | Load chậm, no-fill, lỗi, remote config tắt ad, user premium |
| LIFE | Interstitial khi đang phát video; background khi ad full-screen mở |
| INTERACT | Cuộn list có native ad nhanh; tap ngay khi ad vừa hiện |

## Detect

- `ui-ux-scan.sh` `UX-AD-003`: feature có TextField + banner ad; `UX-AD-001`: slot ad với `wrapContentHeight`/không chiều cao.

## Verify

- Build dev dùng test ad id; ép no-fill (remote config/flag) để thấy hành vi thu gọn.
- Device: bàn phím mở → toạ độ ad không đổi.
