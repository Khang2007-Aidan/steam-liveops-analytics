
-- Dung tap UNG VIEN SU KIEN tu ket qua gan nhan khuon.
--
-- Hai view, xep tang:
--   news_khuon     gan nhan khuon vao TUNG TIN
--   news_ung_vien  chi giu nhung tin con co the la su kien that
--
-- Quy tac giu lai:
--   nhan_khuon IS NULL  -> tin khong thuoc khuon lap nao.
--                          Tieu de rieng biet, co the la su kien.
--   sukien_lap          -> su kien that, lap theo chu ky.
--   sukien_esport       -> lich thi dau.
-- Bon nhom nhieu_* bi loai.
--
-- CANH BAO ve SELECT *: danh sach cot duoc co dinh luc tao view.
-- Them cot moi vao news_item thi phai chay lai theo thu tu
-- 04 -> 06 -> 11, khong thi cot moi khong xuong toi day.

CREATE OR REPLACE VIEW news_khuon AS
WITH k AS (
    SELECT
        n.*,
        regexp_replace(
            regexp_replace(lower(n.title), '[0-9]+', '#', 'g'),
            '(january|february|march|april|may|june|july|august|september|october|november|december)',
            '<thang>', 'g'
        ) AS khuon
    FROM news_rule_label AS n
)
SELECT
    k.*,
    kn.nhan AS nhan_khuon
FROM k
LEFT JOIN khuon_nhan AS kn
       ON kn.appid = k.appid
      AND kn.khuon = k.khuon;


CREATE OR REPLACE VIEW news_ung_vien AS
SELECT *
FROM news_khuon
WHERE nhan_khuon IS NULL
   OR nhan_khuon IN ('sukien_lap', 'sukien_esport');


-- === Kiem tra 1: con so phai khop voi tinh toan ngay 02/10 ===
SELECT
    (SELECT COUNT(*) FROM official_news)  AS tin_chinh_thuc,
    (SELECT COUNT(*) FROM news_ung_vien)  AS ung_vien,
    (SELECT COUNT(*) FROM official_news)
  - (SELECT COUNT(*) FROM news_ung_vien)  AS da_loai;
-- Mong doi: 7.941 / 5.366 / 2.575


-- === Kiem tra 2: luat tu khoa noi gi ve tap ung vien ===
-- Doi chieu hai cach gan nhan doc lap nhau.
SELECT nhom_luat, COUNT(*) AS so_tin
FROM news_ung_vien
GROUP BY nhom_luat
ORDER BY so_tin DESC;


-- === Kiem tra 3: UNG VIEN TRONG CUA SO QUAN SAT ===
--
-- Day la cau quan trong nhat trong ca file.
--
-- Ly do: muon do tac dong cua mot su kien len so nguoi choi thi phai co
-- du lieu nguoi choi TRUOC va SAU su kien do. Du lieu nguoi choi cua minh
-- chi bat dau tu 27/09/2026. Moi su kien xay ra truoc ngay do la
-- KHONG THE PHAN TICH, du co gan nhan dep den may.
--
-- 5.366 ung vien nghe thi to, nhung phan lon la tin tu nam 2015-2025.
-- Chung van huu ich de do NHIP RA NOI DUNG, nhung khong dung duoc cho
-- phan do uplift.

SELECT
    COUNT(*) FILTER (WHERE published_at >= '2026-09-27')      AS trong_cua_so,
    COUNT(*) FILTER (WHERE published_at <  '2026-09-27')      AS truoc_cua_so,
    COUNT(*)                                                   AS tong
FROM news_ung_vien;


-- === Kiem tra 4: ung vien trong cua so, chia theo game ===
SELECT
    g.name                AS game,
    COUNT(*)              AS so_ung_vien,
    MIN(n.published_at)::date AS som_nhat,
    MAX(n.published_at)::date AS muon_nhat
FROM news_ung_vien AS n
JOIN dim_game      AS g ON g.appid = n.appid
WHERE n.published_at >= '2026-09-27'
GROUP BY g.name
ORDER BY so_ung_vien DESC;

-- === Chan doan 07/10: vi sao chi co 5 ung vien trong cua so? ===

-- A. Tin moi ve co du khong, va bao nhieu la chinh thuc?
SELECT
    (SELECT COUNT(*) FROM news_item
      WHERE published_at >= '2026-09-27')                AS tin_moi_tat_ca,
    (SELECT COUNT(*) FROM official_news
      WHERE published_at >= '2026-09-27')                AS tin_moi_chinh_thuc,
    (SELECT COUNT(*) FROM news_ung_vien
      WHERE published_at >= '2026-09-27')                AS ung_vien;


-- B. Tin moi den tu nhung kenh nao?
-- Neu cot feedname trong rong het thi la loi khau nap du lieu.
SELECT
    feedname,
    feed_type,
    COUNT(*) AS so_tin
FROM news_item
WHERE published_at >= '2026-09-27'
GROUP BY feedname, feed_type
ORDER BY so_tin DESC;


-- C. Trong so tin chinh thuc gan day, bao nhieu bi loai vi khuon nhieu?
SELECT
    COALESCE(nhan_khuon, '(khong thuoc khuon nao)') AS nhan,
    COUNT(*) AS so_tin
FROM news_khuon
WHERE published_at >= '2026-09-27'
GROUP BY nhan_khuon
ORDER BY so_tin DESC;

-- === Chan doan 2: cac tin feedname rong duoc dang ngay nao? ===
-- Neu tat ca deu tu 29/09 tro di thi khop voi gia thuyet:
-- backfill ngay 29/09 lay duoc feedname, con bot chay code cu
-- tu do ve sau thi khong.

SELECT
    published_at::date   AS ngay_dang,
    COUNT(*)             AS so_tin,
    COUNT(*) FILTER (WHERE feedname IS NULL) AS thieu_feedname
FROM news_item
WHERE published_at >= '2026-09-27'
GROUP BY ngay_dang
ORDER BY ngay_dang;