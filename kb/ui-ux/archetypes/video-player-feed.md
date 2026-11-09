---
id: kb-uiux-video-player-feed
scope: team/arch-ui-ux
category: pattern
tags: [compose, video, player, thumbnail, flicker, vertical-pager, short-video]
---

# Video player / thumbnail → video / feed dọc

**Nhận diện:** màn phát tập phim, feed dọc kiểu short video (For You), preview video trong card,
mọi chỗ có ảnh cover hiển thị trước rồi video thay vào.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-VID-001 | MUST | Cover/thumbnail chỉ ẩn khi player báo **frame đầu tiên đã render** cho **đúng media đó** (`onRenderedFirstFrame` ExoPlayer/Media3, `onRenderStart` TTVideoEngine/BytePlus, `MEDIA_INFO_VIDEO_RENDERING_START` MediaPlayer). Không ẩn theo `isPlaying`, `onPrepared`, `STATE_READY`. | READY/playing đến trước khi surface có hình → 1–3 frame đen = nháy. |
| UX-VID-002 | MUST | Cờ "đã có frame" gắn với **media id**: `renderedMediaId == item.id`, reset ngay khi đổi nguồn. Không dùng một boolean chung cho player. | Vuốt sang tập mới: cờ cũ còn `true` → cover tập mới bị ẩn quá sớm. |
| UX-VID-003 | MUST | Surface (`SurfaceView`/`TextureView`) **không bị tạo lại** khi recomposition hoặc khi đổi tập trong cùng màn: `AndroidView(factory = …)` chỉ tạo 1 lần, đổi media bằng `setMediaItem`/`setVideoSource` trên player cũ. Trong pager dọc: 1 player + 1 surface di chuyển tới trang hiện tại, hoặc pool 2–3 player có kiểm soát. | Tạo lại surface = màn đen 1 nhịp. |
| UX-VID-004 | MUST | Cover và video cùng `contentScale`/tỉ lệ (crop vs fit) và cùng khung; cover nằm **trên** surface, ẩn bằng `alpha` (có thể fade 100–150ms), không remove khỏi cây rồi add lại. | Lệch tỉ lệ = nhảy hình khi đổi lớp. |
| UX-VID-005 | MUST | `SurfaceView` trong list/pager: dùng `TextureView` hoặc `SurfaceView.setZOrderMediaOverlay` hợp lý; kiểm tra hiện tượng surface "lọt" qua pager khi vuốt. | SurfaceView vẽ ngoài cây View → nháy khi cuộn. |
| UX-VID-006 | MUST | Pause khi: màn không RESUMED, app background, mở full-screen ad/IAP/sheet che toàn bộ, trang không còn là trang settled. Resume đúng vị trí khi quay lại. | UX-LF-001, UX-MO-003. |
| UX-VID-007 | MUST | Đổi tập nhanh liên tiếp: chỉ tập cuối được phát; request/prepare của tập cũ bị huỷ, callback của tập cũ bị bỏ qua (so media id). | UX-AS-002; tránh tập cũ phát chồng tiếng. |
| UX-VID-008 | MUST | Buffering giữa chừng hiển thị loading trên **frame cuối**, không quay lại cover. Lỗi phát: overlay lỗi + retry, giữ cover. | Không nháy ngược về ảnh. |
| UX-VID-009 | SHOULD | Feed dọc: prefetch/pre-buffer tập kế tiếp; settle trang mới mới bắt đầu phát (không phát khi đang kéo nửa chừng). | Mượt mà không phát 2 video. |
| UX-VID-010 | SHOULD | Overlay điều khiển (play/pause, seek, tên tập) không làm recomposition cả surface; tách state progress ra composable nhỏ đọc trong lambda. | UX-PF-001. |
| UX-VID-011 | FORBIDDEN | `if (isPlaying) VideoSurface() else Thumbnail()` — thay thế qua lại bằng điều kiện. | Vừa tạo lại surface vừa nháy. |

## Reference implementation

```kotlin
@Composable
fun VideoWithCover(
    player: PlayerFacade,               // bọc ExoPlayer/TTVideoEngine, sống lâu hơn composable
    mediaId: String,
    coverUrl: String,
    modifier: Modifier = Modifier,
) {
    // player phát ra id của media vừa vẽ frame đầu; null khi đổi nguồn
    val renderedId by player.renderedMediaId.collectAsStateWithLifecycle()
    val showCover = renderedId != mediaId
    val coverAlpha by animateFloatAsState(if (showCover) 1f else 0f, tween(120), label = "cover")
    Box(modifier) {
        AndroidView(factory = { ctx -> TextureView(ctx).also(player::attach) }, Modifier.matchParentSize())
        AsyncImage(coverUrl, null, Modifier.matchParentSize().graphicsLayer { alpha = coverAlpha },
            contentScale = ContentScale.Crop)
    }
}
// Trong facade: setSource(id) { renderedMediaId.value = null; …prepare… }
//               onRenderedFirstFrame { if (currentId == id) renderedMediaId.value = id }
```

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| STATE | Mở tập đã xem dở → seek đúng vị trí; trạng thái lock/unlock khớp server |
| TRANS | Mở màn → cover → video không có frame đen (quay màn 60fps để kiểm); vuốt sang tập kế; quay lại tập trước |
| LAYOUT | Video 9:16 trên màn 20:9 và 16:9; notch; font 2.0 cho overlay |
| INTERACT | Vuốt dọc nhanh 5 tập; tap pause trong lúc buffering; kéo seek bar trong pager dọc không làm đổi trang |
| LIFE | Home → recent apps → quay lại; khoá màn hình; cuộc gọi đến; rotate |
| ASYNC | Mạng chậm (throttle 3G) → loading trên cover; mất mạng giữa chừng; token hết hạn |
| A11Y | Nút play/pause có label; phụ đề không bị overlay che |
| PERF | Không rò rỉ player khi rời màn (`release` trong `DisposableEffect`/owner lifecycle) |
| MONET | Interstitial/reward mở giữa tập → pause; đóng ad → resume, không có tiếng chồng |

## Detect

- `ui-ux-scan.sh` `UX-VID-001`: file có player + cover/thumbnail mà điều kiện ẩn dùng `isPlaying|isPrepared|STATE_READY|onPrepared`.
- `UX-VID-003`: `AndroidView` tạo `SurfaceView|TextureView` bên trong item của `HorizontalPager|VerticalPager|items(` (surface tạo theo trang).
- `UX-VID-002`: `remember(player)` hoặc `remember { mutableStateOf(false) }` cho cờ first-frame không có media id.

## Verify

- Unit test facade: `setSource(A)`, frame A → rendered=A; `setSource(B)` → rendered=null ngay; callback muộn của A → bỏ qua.
- Device + quay màn: `adb shell screenrecord`, tách frame (`runbooks/runtime-verification.md`) → không có frame tối hoàn toàn giữa cover và video.
