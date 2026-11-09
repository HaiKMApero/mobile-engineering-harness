---
id: kb-uiux-axes
scope: team/arch-ui-ux
category: runbook
tags: [compose, ux, invariants, checklist]
---

# 9 trục lỗi UI/UX (áp cho mọi archetype)

Mỗi trục là một **loại** lỗi. Với mỗi component trên màn, đi qua đủ 9 trục; trục nào không áp dụng ghi `N/A`.

## AX-STATE — Một nguồn sự thật, đồng bộ giữa các màn

| ID | Mức | Bất biến |
|---|---|---|
| UX-ST-001 | MUST | Giá trị hiển thị (số đếm, đã lưu, đã mở khoá, số coin) đọc từ **một** nguồn quan sát được (Flow từ repository/DB), không copy vào `remember`/biến cục bộ rồi quên cập nhật. |
| UX-ST-002 | MUST | Thao tác người dùng phản ánh lên UI **ngay** (optimistic) hoặc có trạng thái đang xử lý; lỗi thì rollback + báo lỗi. Không để UI đứng yên chờ reload. |
| UX-ST-003 | MUST | Cùng một thực thể hiển thị ở nhiều nơi (Home card, Detail, My List, badge) phải cùng giá trị sau mọi thao tác, kể cả khi quay lại bằng back. |
| UX-ST-004 | MUST | Selection (tab, chip, page, item) lưu theo **key ổn định**, không theo index — dữ liệu đổi thứ tự/xoá phần tử thì selection không nhảy sang item khác. |
| UX-ST-005 | SHOULD | State UI cần sống qua rotation/process death (tab đang chọn, page, query) dùng `rememberSaveable`/`SavedStateHandle`. |

## AX-TRANS — Chuyển trạng thái không nháy, không giật

| ID | Mức | Bất biến |
|---|---|---|
| UX-TR-001 | MUST | Không có frame trống/đen/nhấp nháy giữa 2 trạng thái (placeholder → content, thumbnail → video, loading → data). Lớp cũ chỉ rời đi khi lớp mới **đã vẽ xong**. |
| UX-TR-002 | MUST | Không layout shift: vùng nội dung sắp tới (ảnh, ad, list) giữ chỗ đúng kích thước trước khi có data. |
| UX-TR-003 | SHOULD | Refresh dữ liệu không reset scroll, không nháy skeleton khi đã có data cũ (stale-while-revalidate). |
| UX-TR-004 | SHOULD | Animation tôn trọng "reduce motion"/animator scale = 0. |

## AX-LAYOUT — Bố cục dưới mọi ràng buộc

| ID | Mức | Bất biến |
|---|---|---|
| UX-LY-001 | MUST | IME chỉ đẩy vùng cần nhìn khi gõ (ô nhập, gợi ý). Banner ad, bottom nav, CTA không liên quan **không** bị đẩy lên theo bàn phím. |
| UX-LY-002 | MUST | Edge-to-edge: status bar, navigation bar (gesture/3-button), cutout không che nội dung tương tác. |
| UX-LY-003 | MUST | Font scale 2.0, màn 320dp, text dài, ngôn ngữ dài (de, ru, vi) và RTL: không cắt chữ không có ellipsis, không đè nhau. |
| UX-LY-004 | SHOULD | Tablet/landscape/foldable: không kéo giãn vô lý; tối thiểu không vỡ layout. |

## AX-INTERACT — Cử chỉ và điều khiển nhất quán

| ID | Mức | Bất biến |
|---|---|---|
| UX-IN-001 | MUST | Hai điều khiển cùng biểu diễn một state (tab ↔ pager, indicator ↔ carousel, chip ↔ list) luôn khớp nhau trong **mọi** đường thay đổi: bấm, vuốt, programmatic, restore. |
| UX-IN-002 | MUST | Tap lặp nhanh / tap 2 nút cùng lúc không mở 2 màn, không gọi 2 request, không trừ coin 2 lần. |
| UX-IN-003 | MUST | Cử chỉ lồng nhau (pager trong pager, list ngang trong pager dọc, sheet trên list) không cướp cử chỉ của nhau. |
| UX-IN-004 | SHOULD | Danh sách vòng (banner, carousel) vuốt vô hạn cả 2 chiều nếu thiết kế là carousel; indicator theo `page mod size`. |
| UX-IN-005 | SHOULD | Touch target ≥ 48dp; vùng bấm khớp vùng nhìn thấy. |

## AX-LIFE — Vòng đời

| ID | Mức | Bất biến |
|---|---|---|
| UX-LF-001 | MUST | Thứ chạy theo thời gian (video, auto-scroll, countdown, polling) dừng khi màn không còn RESUMED / không còn hiển thị, và tiếp tục đúng chỗ khi quay lại. |
| UX-LF-002 | MUST | Collect Flow trong UI bằng `collectAsStateWithLifecycle`; side-effect một lần (navigate, toast) không lặp lại sau rotation. |
| UX-LF-003 | MUST | Quay lại màn (back) giữ scroll position, tab, page, query như lúc rời đi. |
| UX-LF-004 | SHOULD | Process death: không crash, khôi phục tối thiểu màn + tham số route. |

## AX-ASYNC — Mọi trạng thái bất đồng bộ

| ID | Mức | Bất biến |
|---|---|---|
| UX-AS-001 | MUST | Mỗi vùng dữ liệu có đủ: loading, content, empty, error (+ retry), offline. Không có màn trắng. |
| UX-AS-002 | MUST | Kết quả về muộn của request cũ không ghi đè request mới (search gõ nhanh, đổi tab nhanh) — cancel hoặc so khớp key. |
| UX-AS-003 | SHOULD | Paging: loading/error ở cuối list, không chặn toàn màn; không gọi trang trùng. |

## AX-A11Y — Phản hồi và trợ năng

| ID | Mức | Bất biến |
|---|---|---|
| UX-A1-001 | MUST | Mọi thao tác có phản hồi nhìn thấy trong ≤ 100ms (ripple, state, toast); thao tác thất bại có thông báo hiểu được. |
| UX-A1-002 | SHOULD | Icon/ảnh bấm được có `contentDescription`; nhóm semantics hợp lý cho TalkBack; trạng thái chọn có `selected`. |

## AX-PERF — Hiệu năng cảm nhận được

| ID | Mức | Bất biến |
|---|---|---|
| UX-PF-001 | MUST | Lazy list có `key` ổn định và `contentType` (chi tiết UX-LST-001); không tạo lại object nặng (player, bitmap) mỗi recomposition. |
| UX-PF-002 | SHOULD | Ảnh tải đúng kích thước hiển thị; không decode ảnh gốc cho thumbnail. |
| UX-PF-003 | SHOULD | Không jank khi cuộn (đo bằng JankStats/Macrobenchmark khi nghi ngờ). |

## AX-MONET — Quảng cáo và trả phí trong layout

| ID | Mức | Bất biến |
|---|---|---|
| UX-MO-001 | MUST | Slot ad giữ chỗ cố định; no-fill thì thu gọn mượt hoặc giữ placeholder theo spec — không đẩy nội dung giật lên/xuống. |
| UX-MO-002 | MUST | Ad không che CTA, không nằm trong vùng bị IME đẩy, không bị bấm nhầm khi nội dung dịch chuyển. |
| UX-MO-003 | MUST | Full-screen ad / reward: pause video, timer; resume đúng trạng thái sau khi đóng; fail/no-fill có đường ra cho user. |

## Cách dùng trong review

Với diff UI: liệt kê archetype bị chạm → với mỗi archetype mở file của nó → đi qua `Contract` → ghi kết quả
`PASS / FAIL (rule id, file:line) / N/A (lý do) / UNVERIFIED (cần runtime)`. `UNVERIFIED` không được tính là PASS.
