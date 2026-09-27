# Ghi chú chất lượng dữ liệu

Những cái bẫy đã phát hiện. Đọc trước khi viết truy vấn.

## dim_game.csv

- `price_vnd = 0` có HAI nghĩa: game miễn phí, hoặc game không bán ở cửa hàng
  VN. Phân biệt bằng `is_free` và `available_vn`.
- `release_date` là ngày phát hành HIỆN TẠI, không phải lần đầu xuất hiện.
  Game từng ở giai đoạn truy cập sớm sẽ mang ngày rời early access.
  Ví dụ Valheim ghi 9 Sep 2026, Palworld ghi 9 Jul 2026.
  Chưa kiểm chứng. Đừng dùng cột này để tính tuổi game khi chưa xác minh.
- `available_vn = False` với 4 game: Path of Exile, NARAKA, Lost Ark,
  HELLDIVERS 2. Quan sát được: không có trên cửa hàng Steam VN.
  Giả định chưa kiểm chứng: do có nhà phát hành riêng theo khu vực.

## prices/

- `price_final` và `price_initial` KHÔNG cùng đơn vị giữa các dòng.
  `country_code = vn` thì đơn vị là đồng, `us` thì là đô la.
  Không bao giờ tính trung bình cột giá mà không lọc theo `country_code`.
- Game miễn phí luôn có giá 0.

## news/

- `feedlabel` phân biệt nguồn tin. Chỉ `Community Announcements` là thông báo
  chính thức từ nhà phát hành. Các giá trị khác như PCGamesN, PC Gamer,
  GamingOnLinux, PlayGround.ru là bài báo viết về game.
  Khi gán nhãn sự kiện vận hành chỉ dùng nhóm chính thức.
- Mỗi ngày Steam trả về lại các tin cũ nên dữ liệu trùng lặp giữa các file.
  Lọc trùng bằng `news_gid` khi nạp vào database.
- Tin tức có lịch sử lùi về nhiều tháng, nhưng dữ liệu người chơi chỉ bắt đầu
  từ 2026-09-27. Không thể phân tích sự kiện xảy ra trước ngày đó.

## players/

- Điểm dữ liệu đầu tiên: 2026-09-27 08:27 UTC.
- `collected_at_utc` là thời điểm gọi API thật sự, không phải giờ đã hẹn trong
  lịch. GitHub Actions thường chạy trễ vài phút.
- Số người chơi đồng thời là chỉ số gián tiếp. Không phải số người dùng hằng
  ngày, không phải doanh thu.

## API Steam

- `appdetails` trả về khóa ngoài cùng KHÔNG bằng appid đã hỏi.
  Hỏi 570 có thể nhận về khóa 2120612. Phải đọc `steam_appid` bên trong `data`.