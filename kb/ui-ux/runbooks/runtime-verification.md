---
id: kb-uiux-runtime-verification
scope: team/arch-ui-ux
category: runbook
tags: [verification, compose-ui-test, adb, screenrecord, flicker, ime]
---

# Chứng minh hành vi UI khi app chạy

Preview và so Figma chỉ chứng minh **một khung hình tĩnh**. Các trục sau cần bằng chứng runtime:

| Trục | Công cụ tối thiểu |
|---|---|
| AX-STATE (đồng bộ giữa màn) | Unit test ViewModel với fake repository dùng chung |
| AX-INTERACT (tab ↔ pager, vòng carousel, tap đúp) | Compose UI test (`createAndroidComposeRule`) |
| AX-TRANS (nháy, layout shift) | Device + `screenrecord` + tách frame |
| AX-LAYOUT (IME, insets) | Device: `uiautomator dump` so `bounds` trước/sau |
| AX-LIFE (back, rotate, background, process death) | Device: kịch bản adb |

## Compose UI test mẫu

```kotlin
@Test fun tabsFollowPagerSwipe() {
    rule.setContent { AppTheme { HomeTabsContent(fakeState) } }
    rule.onNodeWithTag("home_pager").performTouchInput { swipeLeft() }
    rule.onNodeWithText("New").assertIsSelected()
}

@Test fun carouselLoopsBackwardsFromFirstPage() {
    rule.setContent { AppTheme { HeroCarousel(banners = fakeBanners(5)) } }
    rule.onNodeWithTag("hero_pager").performTouchInput { swipeRight() }
    rule.onNodeWithContentDescription("Banner 5 of 5").assertIsDisplayed()
}

@Test fun doubleTapOpensDetailOnce() {
    val nav = TestNavHostController(ctx).apply { navigatorProvider.addNavigator(ComposeNavigator()) }
    rule.setContent { AppNavHost(nav) }
    rule.onAllNodesWithTag("drama_card")[0].performClick().performClick()
    assertEquals(1, nav.currentBackStack.value.count { it.destination.route?.startsWith("detail") == true })
}
```

## Device: IME không đẩy ad (UX-SRCH-002 / UX-AD-003)

```bash
adb shell uiautomator dump /sdcard/a.xml && adb pull /sdcard/a.xml before.xml
adb shell input tap <x> <y>          # focus ô search → bàn phím mở
adb shell uiautomator dump /sdcard/a.xml && adb pull /sdcard/a.xml after.xml
# so bounds của node ad (resource-id/testTag) — phải giống nhau, hoặc node ad biến mất nếu spec yêu cầu ẩn
grep -o 'search_banner_ad[^>]*bounds="[^"]*"' before.xml after.xml
```

Compose cần `Modifier.testTag(...)` + `semantics { testTagsAsResourceId = true }` ở root để uiautomator thấy tag.

## Device: phát hiện nháy (UX-VID-001, UX-TR-001)

```bash
adb shell screenrecord --bit-rate 8000000 --time-limit 8 /sdcard/flick.mp4 &
# thao tác: mở player / vuốt sang tập kế
adb pull /sdcard/flick.mp4
ffmpeg -i flick.mp4 -vf "crop=iw:ih*0.6:0:ih*0.2,signalstats,metadata=print:key=lavfi.signalstats.YAVG" -f null - 2>&1 \
  | grep YAVG | awk -F= '{print NR, $2}' > luma.txt
# frame có YAVG gần 16 (đen) kẹp giữa 2 frame sáng = nháy; xuất frame đó để làm bằng chứng:
ffmpeg -i flick.mp4 -vf "select=eq(n\,<N>)" -vframes 1 flicker-frame.png
```

`screenrecord` ~30–60fps có thể bỏ sót nháy 1 frame ở 120Hz; đặt màn 60Hz khi đo hoặc quay bằng camera ngoài khi nghi ngờ.

## Device: lifecycle

```bash
adb shell input keyevent KEYCODE_HOME; sleep 5; adb shell monkey -p <pkg> 1   # background → foreground
adb shell settings put system accelerometer_rotation 0; adb shell settings put system user_rotation 1  # xoay
adb shell am kill <pkg>   # sau khi đưa app background → mô phỏng process death, rồi mở lại từ recents
adb shell settings put system font_scale 2.0   # nhớ trả về 1.0
```

## Ghi bằng chứng

Mỗi rule đã verify ghi: lệnh/test đã chạy, kết quả, file bằng chứng (png/mp4/xml). Rule không chạy được
(không có thiết bị) giữ `UNVERIFIED` trong báo cáo — không ghi PASS.
