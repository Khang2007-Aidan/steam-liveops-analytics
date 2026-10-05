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
- Bảng này bị GHI ĐÈ mỗi lần nạp (ON CONFLICT DO UPDATE). Nếu Steam đổi tên
  game, đổi giá, hay một game chuyển từ trả phí sang miễn phí thì giá trị cũ
  mất hẳn, không còn dấu vết. Chưa cần xử lý, nhưng nhớ là có giới hạn này.

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
- Thu bù ngày 29/09 với count = 500, được 12.459 tin duy nhất.
  19 trên 28 game chạm trần 500, nghĩa là lịch sử còn cũ hơn nữa nhưng không
  lấy. Chấp nhận được: game có lịch sử ngắn nhất (War Thunder) vẫn lùi tới
  2025-10, thừa sức cho khoảng thời gian phân tích. Phần bị cắt không dùng được.
- File thu hằng ngày vẫn để NEWS_PER_GAME = 20. Lý do: chỉ cần lớn hơn số
  thông báo một game đăng trong 1 ngày. Script tự cảnh báo nếu có game chạm
  trần 20, lúc đó phải tăng lên.
- Trước ngày 29/09, cột `snippet` bị cắt ở 600 ký tự (NEWS_MAX_LENGTH = 600).
  Từ 29/09 đã bỏ giới hạn. Tiêu đề chưa bao giờ bị cắt.

## players/

- Điểm dữ liệu đầu tiên: 2026-09-27 08:27 UTC.
- `collected_at_utc` là thời điểm gọi API thật sự, không phải giờ đã hẹn trong
  lịch. GitHub Actions thường chạy trễ vài phút.
- Số người chơi đồng thời là chỉ số gián tiếp. Không phải số người dùng hằng
  ngày, không phải doanh thu.
- DAO ĐỘNG THEO GIỜ RẤT LỚN. Đo ngày 27-28/09 tại hai khung giờ khác nhau:
  Counter-Strike 2 giảm 35%, Dota 2 giảm 32%, PUBG giảm 41%.
  Hệ quả: mức nền BẮT BUỘC phải tính riêng theo từng khung giờ. Gộp chung mọi
  giờ thì một sự kiện làm tăng 20% sẽ bị chôn dưới nhiễu 40% của chu kỳ ngày đêm.

## Lịch chạy GitHub Actions

- Lịch cron là "cố gắng hết sức", không phải cam kết. Có lượt bị trễ, có lượt
  bị bỏ hẳn.
- Ghi nhận 27-28/09: đặt 4 lần/ngày cách đều 6 tiếng, thực tế khoảng cách là
  4h25 và 8h42, và thiếu 1 lượt.
- Không được giả định số điểm đo mỗi ngày là cố định. Luôn dùng
  `collected_at_utc`, không bao giờ suy ra thời điểm từ lịch cron.
- GitHub tắt workflow theo lịch nếu repo không có hoạt động khoảng 60 ngày.

## API Steam

- `appdetails` trả về khóa ngoài cùng KHÔNG bằng appid đã hỏi.
  Hỏi 570 có thể nhận về khóa 2120612. Phải đọc `steam_appid` bên trong `data`.
- Giới hạn tốc độ gọi chưa được kiểm chứng. Script đang nghỉ 1,5 giây mỗi lượt
  cho appdetails và 0,5 giây cho API người chơi, con số này là phỏng đoán.