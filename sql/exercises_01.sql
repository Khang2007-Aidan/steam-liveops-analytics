


-- ==============================================================
-- BAI TAP SQL SO 1
-- Viet cau truy van ngay duoi moi cau hoi. Tu lam truoc, dung tra.
-- Lam xong gui lai toan bo file nay de duoc cham.
-- ==============================================================

-- Cau 1. Liet ke tat ca game: appid va ten, sap xep theo ten A-Z.
-- Ket qua mong doi: 28 dong, 2 cot.
SELECT appid, name
FROM dim_game
ORDER BY name;


-- Cau 2. Co bao nhieu game mien phi, bao nhieu game tra phi?
-- Goi y: GROUP BY tren cot is_free.
-- Ket qua mong doi: 2 dong.
SELECT is_free, COUNT(*) AS so_game
FROM dim_game
GROUP BY is_free;


-- Cau 3. Nhung game nao khong ban o cua hang Viet Nam?
-- Ket qua mong doi: 4 dong, co ten game.
SELECT appid, name
FROM dim_game
WHERE available_vn = FALSE
ORDER BY name;


-- Cau 4. Bang fact_player_count dang co bao nhieu dong,
-- va bao nhieu thoi diem do KHAC NHAU?
-- Goi y: COUNT(*) va COUNT(DISTINCT ...) trong cung mot cau.
-- Ket qua mong doi: 1 dong, 2 cot.
SELECT
    COUNT(*)                     AS so_dong,
    COUNT(DISTINCT collected_at) AS so_lan_do
FROM fact_player_count;


-- Cau 5. Tai lan do MOI NHAT, moi game co bao nhieu nguoi choi?
-- Phai hien TEN game chu khong phai appid.
-- Goi y: can JOIN, va can mot cau truy van con de tim thoi diem lon nhat.
-- Ket qua mong doi: 28 dong.
SELECT g.name, f.player_count
FROM fact_player_count AS f
JOIN dim_game AS g ON g.appid = f.appid
WHERE f.collected_at = (SELECT MAX(collected_at) FROM fact_player_count)
ORDER BY f.player_count DESC;


-- Cau 6. Tu ket qua cau 5, lay 5 game dong nguoi choi nhat.
-- Goi y: ORDER BY ... DESC va LIMIT.
SELECT g.name, f.player_count
FROM fact_player_count AS f
JOIN dim_game AS g ON g.appid = f.appid
WHERE f.collected_at = (SELECT MAX(collected_at) FROM fact_player_count)
ORDER BY f.player_count DESC
LIMIT 5;


-- Cau 7. Trung binh luong nguoi choi cua tung game qua TAT CA cac lan do,
-- kem ten game, sap xep giam dan.
-- Goi y: GROUP BY va AVG. Lam tron bang ROUND neu muon nhin de hon.
SELECT g.name,
       ROUND(AVG(f.player_count)) AS trung_binh
FROM fact_player_count AS f
JOIN dim_game AS g ON g.appid = f.appid
GROUP BY g.appid, g.name
ORDER BY trung_binh DESC;


-- Cau 8. Game nao dang giam gia tai lan do moi nhat?
-- Hien ten game, muc giam, gia truoc va gia sau, VA CA country_code.
-- Nho ly do phai co country_code: doc lai data/NOTES.md.
SELECT g.name,
       p.discount_percent,
       p.price_initial,
       p.price_final,
       p.country_code
FROM fact_price AS p
JOIN dim_game AS g ON g.appid = p.appid
WHERE p.discount_percent > 0
  AND p.collected_at = (SELECT MAX(collected_at) FROM fact_price)
ORDER BY p.discount_percent DESC;


-- Cau 9. Trong bang news_item, moi feedlabel co bao nhieu ban tin?
-- Sap xep tu nhieu den it.
-- Cau nay cho thay ro bao chi lan lon voi thong bao chinh thuc the nao.
SELECT feedlabel, COUNT(*) AS so_tin
FROM news_item
GROUP BY feedlabel
ORDER BY so_tin DESC;


-- Cau 10. Nhip ra noi dung: moi game dang bao nhieu thong bao chinh thuc
-- mot thang, trong cung mot cua so 11 thang.
-- Dung view official_news, quy tac loc nguon dinh nghia o 04_view_official_news.sql
SELECT g.name,
       COUNT(*) AS so_thong_bao,
       ROUND(COUNT(*) / 11.0, 1) AS tb_moi_thang
FROM official_news AS n
JOIN dim_game AS g ON g.appid = n.appid
WHERE n.published_at >= '2025-11-01'
GROUP BY g.appid, g.name
HAVING COUNT(*) >= 5
ORDER BY tb_moi_thang DESC;