# Nhịp vận hành và sự quay lại của người chơi

Thu thập và phân tích dữ liệu công khai từ Steam để trả lời một câu hỏi:

> **Trong các game dịch vụ trực tiếp, nhịp ra nội dung mới và loại nội dung đó
> ảnh hưởng thế nào tới việc người chơi quay lại và ở lại?**

Loại nội dung được phân thành: chế độ chơi mới, nhân vật mới, sự kiện hợp tác,
mùa mới, giải đấu, và bản chỉ chỉnh cân bằng.

## Chỉ số

Chốt trước khi có dữ liệu, để tránh chỉnh định nghĩa cho ra kết quả đẹp.

| Chỉ số | Định nghĩa |
|---|---|
| Mức nền | Trung vị lượng người chơi 14 ngày trước sự kiện, tính riêng theo từng khung giờ |
| Mức tăng đỉnh | Đỉnh trong 7 ngày sau sự kiện chia cho mức nền |
| Số ngày tắt | Số ngày từ đỉnh đến khi rơi về trong phạm vi 10% mức nền |
| Nền mới | Trung vị 14 ngày sau khi hết sự kiện chia cho mức nền cũ |

Đơn vị phân tích là **một sự kiện**, không phải một game.

## Giới hạn dữ liệu

Lượng người chơi đồng thời là chỉ số gián tiếp. Dự án này **không có** số người
dùng hằng ngày, không có doanh thu, không có dữ liệu từng người chơi. Mọi kết
luận chỉ nói về số người chơi đồng thời quan sát được trên Steam.

## Cấu trúc dữ liệu

```
data/
  games_seed.csv        appid do nguoi viet tay
  dim_game.csv          bang DIM: ten, the loai, mien phi hay tra phi
  players/YYYY-MM-DD.csv  bang FACT: thoi diem, appid, so nguoi choi
  prices/YYYY-MM-DD.csv   gia va muc giam gia theo ngay
  news/YYYY-MM-DD.csv     tin tuc va ban cap nhat, nguyen lieu de gan nhan su kien
```

Bảng fact chỉ chứa appid và con số, tên game nằm ở bảng dim. Đây là bước đầu
của star schema sẽ dựng ở giai đoạn sau.

## Cách chạy

```bash
pip install -r requirements.txt

python scripts/verify_games.py     # tao dim_game.csv, chay lai khi them game
python scripts/collect_players.py  # 4 lan/ngay
python scripts/collect_events.py   # 1 lan/ngay
```

## Tự động hóa

Hai workflow trong `.github/workflows/` chạy trên máy chủ của GitHub, không cần
để máy cá nhân bật.

| Workflow | Lịch (UTC) |
|---|---|
| collect-players | 01:17, 07:17, 13:17, 19:17 |
| collect-events | 03:43 |

Giờ chạy thực tế có thể trễ, nên mọi bản ghi đều lưu `collected_at_utc` là thời
điểm gọi thật sự chứ không phải giờ đã hẹn.

Lưu ý: GitHub tắt workflow theo lịch nếu repo không có hoạt động trong khoảng 60
ngày. Mỗi tháng vào kiểm tra một lần.

## Nguồn dữ liệu

Toàn bộ là API công khai của Steam, không cần khóa, không đụng thông tin cá nhân:
`GetNumberOfCurrentPlayers`, `appdetails`, `GetNewsForApp`.
Mỗi lượt gọi đều có thời gian nghỉ để không tạo tải bất thường.
