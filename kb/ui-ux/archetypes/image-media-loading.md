---
id: kb-uiux-image-media-loading
scope: team/arch-ui-ux
category: pattern
tags: [compose, coil, image, placeholder, crossfade, aspect-ratio]
---

# Ảnh poster, placeholder, crossfade

**Nhận diện:** mọi `AsyncImage`/`SubcomposeAsyncImage`/Glide: poster, avatar, banner, backdrop.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-IMG-001 | MUST | Khung ảnh có kích thước/tỉ lệ cố định **trước** khi ảnh tải (`aspectRatio`, `size`) — không phụ thuộc kích thước ảnh trả về. | UX-TR-002 layout shift. |
| UX-IMG-002 | MUST | Có placeholder (màu surface/shimmer) và error fallback (ảnh mặc định của app); không để khung trống trong suốt. | |
| UX-IMG-003 | MUST | Ảnh đã có trong cache hiện ngay, không fade lại mỗi lần recomposition/back (Coil memory cache key ổn định; không thêm query ngẫu nhiên vào URL). | Nháy ảnh khi quay lại màn. |
| UX-IMG-004 | SHOULD | Crossfade ngắn (100–200ms) chỉ khi tải từ mạng/đĩa. | |
| UX-IMG-005 | SHOULD | Tải đúng kích thước hiển thị (`size(...)`/để Coil tự đo theo constraints); không decode ảnh gốc 4K cho thumbnail. | UX-PF-002. |
| UX-IMG-006 | SHOULD | Ảnh trang kế trong carousel/pager được preload. | |
| UX-IMG-007 | SHOULD | Ảnh bấm được có `contentDescription`; ảnh trang trí `null`. | UX-A1-002. |
| UX-IMG-008 | FORBIDDEN | `Modifier.wrapContentSize()` cho ảnh mạng trong list; `ContentScale.FillBounds` cho poster (méo ảnh). | |

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| TRANS | Back về màn: ảnh không fade lại; refresh không nháy |
| ASYNC | URL 404, URL rỗng, mạng chậm, ảnh rất lớn |
| LAYOUT | Ảnh tỉ lệ khác thiết kế (ngang trong khung dọc) → crop đúng tâm |

## Detect

- `ui-ux-scan.sh` `UX-IMG-001`: `AsyncImage(` mà modifier cùng dòng/khối không có `size|aspectRatio|height|fillMaxSize|matchParentSize`.

## Verify

- Preview với ảnh lỗi/placeholder (LocalAsyncImagePreviewHandler); device với network throttling.
