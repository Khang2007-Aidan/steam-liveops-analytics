-- Gan nhan cho 65 khuon tieu de lap lai. Gan tay, 02/10/2026.
--
-- Vi sao viet thanh file UPDATE thay vi sua trong luoi pgAdmin:
-- file nay nam trong repo, day len GitHub duoc, va dung lai database
-- tu dau bang cach chay 01 -> 08 thi nhan van con nguyen.
--
-- BAY NHAN (7 gia tri):
--   nhieu_patch      Thong bao ve mot PHIEN BAN cu the.
--   nhieu_bantin     Bai ra theo lich, mot bai nhieu chu de.
--   nhieu_hanhchinh  Van hanh: cam tai khoan, bao cao may chu.
--   nhieu_quangcao   Tiep thi thuan, khong co noi dung game.
--   sukien_lap       Su kien co ten rieng, lap theo chu ky.
--   sukien_esport    Lich thi dau / giai dau.
--   khong_chac       Khong xac dinh duoc.
--
-- LICH SU SUA NHAN (giu lai, day la bang chung quy trinh co kiem chung):
--   - Ban dau chi co 5 nhan. Them sukien_esport sau khi thay 3 khuon
--     lich thi dau PUBG khong vua nhom nao.
--   - Them nhieu_quangcao sau khi doc snippet id 31: noi dung la mau
--     quang cao goi thue bao EA Play, dan lai y nguyen moi thang,
--     khong mot chu nao ve Apex.
--   - id 33 (THE FINALS "Store Update") chuyen tu sukien_lap sang
--     nhieu_bantin: doc snippet moi biet day la ban tin tong hop
--     hang tuan, mot bai chua cua hang + su kien + esports + va loi.
--   - id 29 (PUBG "Store Update") giu sukien_lap NHUNG khong kiem
--     chung duoc: PUBG chi dang mot duong link sang pubg.com,
--     snippet khong co noi dung.
--
-- GIOI HAN DA BIET: mot thong bao co the chua NHIEU loai su kien
-- cung luc (vi du id 33). Gan mot nhan duy nhat la mot su don gian hoa.
-- Vi vay nhom nhieu_bantin bi loai khoi tap moc su kien: khong quy
-- duoc uplift ve mot nguyen nhan nao.

ALTER TABLE khuon_nhan DROP CONSTRAINT IF EXISTS nhan_hop_le;
ALTER TABLE khuon_nhan ADD  CONSTRAINT nhan_hop_le CHECK (
    nhan IS NULL OR nhan IN (
        'nhieu_patch',
        'nhieu_bantin',
        'nhieu_hanhchinh',
        'nhieu_quangcao',
        'sukien_lap',
        'sukien_esport',
        'khong_chac'
    )
);


UPDATE khuon_nhan SET nhan = 'nhieu_patch'
WHERE id IN (
     1,  2,  3,  4,  8,  9, 12, 13, 15, 16,
    17, 19, 21, 22, 23, 24, 25, 26, 28, 30,
    38, 41, 43, 45, 47, 48, 51, 52, 54, 55,
    56, 59, 60, 61, 64, 65
);

UPDATE khuon_nhan SET nhan = 'nhieu_bantin'
WHERE id IN (
     6,  7, 10, 14, 20, 27, 33, 34, 35, 39,
    42, 44, 46, 57, 63
);

UPDATE khuon_nhan SET nhan = 'nhieu_hanhchinh'
WHERE id IN (5, 11, 18, 40, 53);

UPDATE khuon_nhan SET nhan = 'nhieu_quangcao'
WHERE id IN (31);

UPDATE khuon_nhan SET nhan = 'sukien_lap'
WHERE id IN (29, 32, 36, 37, 58);

UPDATE khuon_nhan SET nhan = 'sukien_esport'
WHERE id IN (49, 50, 62);


-- Kiem tra 1: chua_gan phai bang 0.
SELECT
    COUNT(*)                             AS tong,
    COUNT(*) FILTER (WHERE nhan IS NULL) AS chua_gan
FROM khuon_nhan;

-- Kiem tra 2: phan bo. So TIN moi quan trong, khong phai so khuon.
SELECT nhan, COUNT(*) AS so_khuon, SUM(so_tin) AS so_tin
FROM khuon_nhan
GROUP BY nhan
ORDER BY so_tin DESC;