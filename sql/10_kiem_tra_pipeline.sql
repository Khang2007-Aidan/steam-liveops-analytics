-- Kiem tra suc khoe cua duong ong thu du lieu.
-- Chay moi tuan. Day la tieu chi dong giai doan 1.
--
-- Hai cau hoi phai tra loi duoc:
--   1. Moi ngay co du 4 lan thu va du 28 game khong?
--   2. Co ngay nao BI MAT HAN khong?
--
-- Cau 2 kho hon cau 1: ngay bi mat thi khong co dong nao trong bang,
-- nen GROUP BY khong bao gio nhin thay no. Phai tu sinh ra day ngay
-- day du roi doi chieu nguoc lai.

-- === Cau 1: tung ngay co bao nhieu lan thu, bao nhieu game ===
SELECT
    collected_at::date          AS ngay,
    COUNT(DISTINCT collected_at) AS so_lan_thu,
    COUNT(DISTINCT appid)        AS so_game,
    COUNT(*)                     AS so_dong
FROM fact_player_count
GROUP BY ngay
ORDER BY ngay;
-- Mong doi: so_lan_thu = 4, so_game = 28, so_dong = 112 moi ngay.
-- Ngay dau (27/09) va ngay hom nay se it hon, do la binh thuong.


-- === Cau 2: co ngay nao bi mat han khong ===
--
-- generate_series sinh ra MOT DAY NGAY lien tuc tu ngay dau den ngay cuoi,
-- ke ca nhung ngay khong co du lieu. Roi loai bo nhung ngay DA CO.
-- Con lai chinh la nhung ngay bi mat.
--
-- Day la ky thuat quan trong: muon tim thu BI THIEU thi phai tu tao ra
-- danh sach day du truoc, vi du lieu khong the tu ke ve cai no khong co.

SELECT d::date AS ngay_bi_mat
FROM generate_series(
    (SELECT MIN(collected_at)::date FROM fact_player_count),
    (SELECT MAX(collected_at)::date FROM fact_player_count),
    interval '1 day'
) AS d
WHERE d::date NOT IN (
    SELECT DISTINCT collected_at::date FROM fact_player_count
);
-- Mong doi: KHONG CO DONG NAO. Co dong nao la ngay do mat sach du lieu.


-- === Phu: khoang cach lon nhat giua hai lan thu lien tiep ===
--
-- LAG() la ham cua so: lay gia tri cua DONG TRUOC trong cung mot thu tu.
-- Dung de do khoang cach giua cac lan thu.
-- Lich dat la 6 tieng mot lan, nen khoang cach binh thuong ~6 tieng.
-- Khoang cach lon hon han nghia la GitHub Actions da bo lo mot lan chay.

WITH moc AS (
    SELECT DISTINCT collected_at
    FROM fact_player_count
),
khoang_cach AS (
    SELECT
        collected_at,
        collected_at - LAG(collected_at) OVER (ORDER BY collected_at) AS cach_lan_truoc
    FROM moc
)
SELECT collected_at, cach_lan_truoc
FROM khoang_cach
WHERE cach_lan_truoc > interval '9 hours'
ORDER BY cach_lan_truoc DESC;
-- Mong doi: khong co dong nao, hoac vai dong le te.
-- GitHub Actions chay theo kieu "co gang het suc", tre vai chuc phut
-- la binh thuong, bo han mot lan thi phai ghi vao NOTES.