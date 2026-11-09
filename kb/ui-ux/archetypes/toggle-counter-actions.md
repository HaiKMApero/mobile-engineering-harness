---
id: kb-uiux-toggle-counter-actions
scope: team/arch-ui-ux
category: pattern
tags: [compose, state, optimistic-update, counter, like, my-list, single-source-of-truth]
---

# Toggle và số đếm (like, thêm vào list, follow, save)

**Nhận diện:** nút có 2 trạng thái gắn với một thực thể và thường đi kèm số đếm: "Add to list" + số người đã
thêm, tim + số like, follow, bookmark, đánh dấu đã xem; badge số lượng trên tab My List.

## Contract

| ID | Mức | Rule | Lý do |
|---|---|---|---|
| UX-TGL-001 | MUST | Trạng thái và số đếm hiển thị được **dẫn xuất** từ nguồn quan sát được (Flow từ repository/DB/cache dùng chung), không phải field copy một lần từ response chi tiết. | Số không tăng sau khi bấm (UX-ST-001). |
| UX-TGL-002 | MUST | Bấm → UI đổi ngay (optimistic): toggled = !toggled, count ± 1. Request thất bại → rollback cả hai + thông báo. Request thành công → nhận giá trị server (nếu server trả count) mà không nháy. | UX-ST-002. |
| UX-TGL-003 | MUST | Mọi màn hiển thị cùng thực thể (Home card, Detail, Player, My List, badge) cùng quan sát nguồn đó — đổi ở một màn thì màn khác đúng ngay khi quay lại, không cần pull-to-refresh. | UX-ST-003. |
| UX-TGL-004 | MUST | Bấm liên tục: tuần tự hoá hoặc gộp (chỉ gửi trạng thái cuối); count không bao giờ lệch quá ±1 so với trạng thái; không âm. | UX-IN-002. |
| UX-TGL-005 | MUST | Count server là tổng của mọi user, toggle là của user hiện tại: lưu tách `serverCount` và `myDelta` (0/±1 khi chờ đồng bộ); hiển thị `serverCount + myDelta` để refresh không trừ/cộng 2 lần. | Số nhảy +2 hoặc về giá trị cũ sau refresh. |
| UX-TGL-006 | MUST | Thao tác cần đăng nhập/điều kiện (guest, offline) → giải thích và giữ trạng thái cũ, không bật rồi tắt. | |
| UX-TGL-007 | SHOULD | Định dạng số lớn theo locale (1.2K, 1,2 N); animation đổi số không làm đổi chiều rộng gây layout shift (dùng `tabular` figures hoặc min width). | UX-TR-002. |
| UX-TGL-008 | SHOULD | Feedback nhẹ (icon đổi, haptic, toast "Đã thêm vào danh sách" có Undo nếu xoá). | UX-A1-001. |
| UX-TGL-009 | FORBIDDEN | ViewModel gọi `repository.add(id)` rồi **không** cập nhật state và không quan sát lại; hoặc reload toàn bộ màn để lấy số mới. | Nguyên nhân gốc của "bấm mà số không đổi" / nháy toàn màn. |

## Reference implementation

```kotlin
// Repository: nguồn chung, mọi màn quan sát
interface MyListRepository {
    fun observe(dramaId: String): Flow<SavedState>          // saved + count, đã gộp pending delta
    suspend fun setSaved(dramaId: String, saved: Boolean): Result<Unit>
}
data class SavedState(val saved: Boolean, val count: Long)

// Implementation sketch: optimistic trong repository (không trong từng ViewModel)
override suspend fun setSaved(id: String, saved: Boolean) = mutex.withLock {
    val before = local.get(id)
    local.put(id, before.copy(saved = saved, pendingDelta = if (saved) +1 else -1))
    api.setSaved(id, saved)
        .onSuccess { srv -> local.put(id, SavedRow(saved, srv.count, pendingDelta = 0)) }
        .onFailure { local.put(id, before) }                       // rollback
}
```

ViewModel chỉ `combine` `observe(id)` vào UiState và phát effect lỗi — mọi màn hưởng cùng hành vi.

## Edge-case matrix

| Axis | Case phải thử |
|---|---|
| STATE | Detail bấm Add → back về Home card và My List đúng ngay; count 0 → 1 → 0 |
| ASYNC | Offline bấm Add → rollback + thông báo; mạng chậm bấm 5 lần |
| LIFE | Bấm Add rồi kill app ngay → mở lại trạng thái đúng theo server |
| A11Y | Nút có `stateDescription` (Đã thêm / Chưa thêm) |
| LAYOUT | Count 9 → 10 → 1.2K không làm nút đổi kích thước |

## Detect

Khó bắt bằng grep; review bắt buộc trả lời: "giá trị này lấy từ Flow nào, ai cập nhật nó sau khi bấm?".
`ui-ux-scan.sh` `UX-TGL-009` chỉ gợi ý: hàm ViewModel tên `add|save|like|follow|toggle` gọi repository mà không có `update {`/`_state.value` và repository không trả Flow.

## Verify

- Unit test ViewModel với fake repository: bấm → state đổi ngay; fake trả lỗi → rollback; 2 ViewModel (Detail, MyList) cùng repo → cả hai thấy thay đổi.
- Device: Add ở Detail → back → số trên Home/My List đổi.
