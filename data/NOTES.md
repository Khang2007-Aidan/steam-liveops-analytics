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


  ---

## Độ tin cậy của lịch thu thập — đo ngày 06/10/2026

### Nơi script thực sự chạy

Toàn bộ việc thu thập chạy trên máy chủ GitHub (GitHub Actions), không chạy
trên máy cá nhân. Máy cá nhân chỉ cần cho bước nạp dữ liệu vào PostgreSQL,
và bước đó làm lúc nào cũng được.

Hệ quả phải nhớ: **cơ sở dữ liệu cục bộ luôn chậm hơn kho trên GitHub.**
Dữ liệu sinh ra sau lần `Pull` cuối cùng thì chưa có trên máy. Ngày 06/10
đã gặp đúng chuyện này: 2 lần thu gần nhất không có trong DB, tưởng là mất
dữ liệu, thực ra chỉ là chưa Pull.

Quy trình đúng mỗi lần kiểm tra: **Pull trước, nạp sau, rồi mới đếm.**

### Số liệu đo được

Cửa sổ đo: 27/09/2026 08:27 UTC → 06/10/2026 00:48 UTC (9 ngày).

- Workflow `collect-players` chạy **29 lần**, cả 29 lần đều thành công.
  Không có lần nào `Cancelled`, không có lần nào `Failure`.
- Lịch đặt 4 lần/ngày (`cron: "17 1,7,13,19 * * *"`), tức kỳ vọng khoảng
  36 lần trong cửa sổ này. Thực tế 29. **Đạt khoảng 80%.**
- `fact_player_count` có 812 dòng = 29 × 28. **Không lần thu nào sót game.**
  Mỗi lần chạy đều lấy đủ cả 28 game hoặc không lấy được gì.
- Không có ngày nào mất sạch dữ liệu.

### Độ trễ: lớn và có quy luật

Không có lần chạy nào sớm hơn giờ đặt. Tất cả đều trễ.

| Mốc đặt (UTC) | Thực tế chạy vào khoảng | Trễ | Xuất hiện |
|---|---|---|---|
| 01:17 | 06:31 – 07:10 | +5h15 → +5h55 | 8/9 ngày |
| 07:17 | 12:32 – 13:11 | +5h15 → +5h55 | **2/9 ngày** |
| 13:17 | 13:41 – 15:59 | +0h24 → +2h42 | 8/9 ngày |
| 19:17 | 22:07 – 23:49 | +2h50 → +4h32 | 8/9 ngày |

Độ trễ không ngẫu nhiên: mốc 01:17 trễ đúng khoảng 5,5 tiếng gần như mọi ngày.

**Giả thuyết về mốc 07:17 (chưa kiểm chứng):** vì mốc 01:17 bị đẩy tới
06:50–07:10, nó vừa chạy xong thì 07:17 tới giờ, và GitHub bỏ qua lần kích
hoạt mới. Khớp với việc không thấy dòng `Cancelled` nào — lần chạy đó không
được tạo ra để mà hủy. Đây là suy đoán dựa trên mẫu hình quan sát được,
chưa xác nhận bằng tài liệu của GitHub.

### Hệ quả thật: 3 cụm mẫu mỗi ngày, không phải 4

Bỏ khái niệm "mốc đã đặt", nhìn theo giờ thật:

| Cụm (UTC) | Giờ VN tương ứng | Số mẫu / 9 ngày |
|---|---|---|
| 06:31 – 07:10 | 13:30 – 14:10 | 8 |
| 12:32 – 15:59 | 19:30 – 23:00 | 10 |
| 22:07 – 23:49 | 05:00 – 06:50 | 8 |
| 00:48 (một lần duy nhất) | 07:48 | 1 |

Khung **00:00–06:00 UTC** (07:00–13:00 giờ VN) gần như không có dữ liệu.
Phải ghi rõ trong báo cáo: bộ dữ liệu này **mù** ở khung giờ đó.

### Quy tắc bắt buộc khi tính mức nền

1. **Không** dùng "lần thu thứ mấy" làm đơn vị. Nó không ổn định.
2. Gom theo **giờ thật** bằng `EXTRACT(HOUR FROM collected_at AT TIME ZONE 'UTC')`,
   chia thành 4 ô 6 tiếng: [00,06) [06,12) [12,18) [18,24).
3. So sánh trước–sau sự kiện **chỉ trong cùng một ô**. Không bao giờ so chéo ô.
   Lý do: số người chơi chênh 32–41% giữa các khung giờ trong cùng một ngày
   (đo ngày 28/09). Nếu so chéo ô, chênh lệch do giờ giấc sẽ bị hiểu nhầm
   thành tác động của sự kiện.
4. Số mẫu mỗi ô không đều nhau. Phải báo cáo số mẫu kèm theo mọi con số
   trung vị.

Quyết định từ Ngày 1 là ghi **giờ gọi API thật**, không ghi giờ theo lịch.
Chính quyết định đó cho phép phát hiện toàn bộ vấn đề này. Nếu ghi theo lịch
thì bây giờ vẫn đang tin rằng có 4 mẫu/ngày ở 4 thời điểm cố định, và mọi
kết luận về sau đều sai mà không có dấu hiệu nào.

### Quyết định: KHÔNG sửa lịch cron

Lịch hiện tại không tốt, nhưng vẫn giữ nguyên.

Lý do: đổi cách lấy mẫu giữa chừng thì dữ liệu trước và sau không so sánh
được với nhau. Sự kiện xảy ra sau khi đổi sẽ có nhiều mẫu hơn sự kiện xảy ra
trước, và chênh lệch đó trông giống hệt chênh lệch thật.

Mức nền cần 14 ngày liên tục. Hiện mới có 9. Đổi lịch lúc này là vứt cả 9 ngày.

Nếu sau này cần đổi: đổi tại một ngày rõ ràng, ghi ngày đó vào file này,
và phân tích hai giai đoạn tách biệt.

---

## Giới hạn của dữ liệu tin tức — chốt ngày 02/10/2026

### Quy tắc nguồn chính thức

View `official_news` (`sql/04`) lọc theo:
`feed_type = 1` OR `feedname LIKE 'steam\_%'` OR `feedname = 'tf2_blog'`

Giả thuyết ban đầu rằng `feed_type` tách được nguồn chính thức với báo chí
đã **thất bại**: chỉ giá trị 1 là `steam_community_announcements`, còn giá trị
0 chứa cả `steam_updates` (chính thức) lẫn `PC Gamer` (báo chí).

TF2 dùng kênh `tf2_blog` riêng, khác 27 game còn lại. Bỏ ra là mất gần hết
sự kiện của game đó, nên đưa vào — nhưng phải ghi rõ sự khác biệt này
trong báo cáo.

### Một thông báo có thể chứa nhiều loại sự kiện

Giả định ngầm "một thông báo = một loại sự kiện" là **sai**.

Ví dụ thật, THE FINALS, khuôn `Store Update #.#.#`:
một bài chứa cùng lúc cửa hàng + vé sự kiện + tin esports + vá lỗi + mùa mới.

Hệ quả: với loại bài này không quy được uplift về một nguyên nhân nào.
Vì vậy nhóm `nhieu_bantin` bị loại khỏi tập mốc sự kiện. Mốc sự kiện phải
là bài **chỉ nói một chuyện**.

### Cột `snippet` không phải lúc nào cũng có nội dung

Một số game chỉ đăng lên Steam một cái cọc trỏ sang web riêng.
Ví dụ PUBG, khuôn `<thang> Store Update #`: toàn bộ snippet chỉ là một ảnh
và dòng `Read the full announcement here!` kèm link pubg.com.

Hệ quả: phương pháp "đọc snippet để kiểm chứng nhãn" **không áp dụng được
cho mọi game**. Nhãn của những khuôn này chỉ dựa trên tiêu đề, phải ghi chú
là chưa kiểm chứng.

### Kết quả lọc nhiễu bằng khuôn tiêu đề

65 khuôn lặp từ 10 lần trở lên, phủ 2.697 / 7.941 tin (34%).

| Nhãn | Số khuôn | Số tin |
|---|---|---|
| `nhieu_patch` | 36 | 1.775 |
| `nhieu_bantin` | 15 | 534 |
| `nhieu_hanhchinh` | 5 | 245 |
| `nhieu_quangcao` | 1 | 21 |
| `sukien_lap` | 5 | 88 |
| `sukien_esport` | 3 | 34 |

Nhiễu loại bỏ: 2.575 tin (32,4%). Sự kiện lặp giữ lại: 122 tin (1,5%).

Bộ nhãn ban đầu chỉ có 5 giá trị, phải mở rộng lên 7 sau khi đọc nội dung
thật. **Bộ nhãn nghĩ ra trước khi nhìn dữ liệu luôn thiếu.**

### Kết quả cũ không còn dùng được

Bảng xếp hạng nhịp ra nội dung làm ngày 28/09 (War Thunder 43,8 tin/tháng,
PUBG 22,3, Apex 16,4...) **chưa dùng được**. Nó đếm cả bản tin định kỳ,
devblog và danh sách cấm tài khoản. Phải tính lại sau khi lọc nhiễu.