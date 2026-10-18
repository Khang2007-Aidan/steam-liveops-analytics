-- Gan nhan LOAI SU KIEN cho 50 ung vien. Gan tay, 08/10/2026.
-- Chay lai bao nhieu lan cung ra cung ket qua.

-- 1. Them cot ma su kien, dung de gom nhieu thong bao cua MOT su kien.
ALTER TABLE ung_vien_nhan ADD COLUMN IF NOT EXISTS ma_su_kien text;

-- 2. Chot bo nhan. Go sai mot chu la database tu choi.
ALTER TABLE ung_vien_nhan DROP CONSTRAINT IF EXISTS nhan_su_kien_hop_le;
ALTER TABLE ung_vien_nhan ADD  CONSTRAINT nhan_su_kien_hop_le CHECK (
    nhan IS NULL OR nhan IN (
        'mua_moi', 'cap_nhat_noi_dung', 'su_kien_gioi_han', 'cua_hang',
        'giam_gia', 'esport', 'nha_hang', 'khong_phai_su_kien', 'khong_chac'
    )
);

-- 3. Gan nhan.
UPDATE ung_vien_nhan SET nhan = 'mua_moi'           WHERE id IN (13);
UPDATE ung_vien_nhan SET nhan = 'cap_nhat_noi_dung' WHERE id IN (4, 25);
UPDATE ung_vien_nhan SET nhan = 'su_kien_gioi_han'  WHERE id IN (5, 8, 11, 26, 30, 35, 46, 48, 50);
UPDATE ung_vien_nhan SET nhan = 'cua_hang'          WHERE id IN (6, 32, 42, 43, 44);
UPDATE ung_vien_nhan SET nhan = 'giam_gia'          WHERE id IN (34, 36, 37);
UPDATE ung_vien_nhan SET nhan = 'esport'            WHERE id IN (14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 38);
UPDATE ung_vien_nhan SET nhan = 'nha_hang'          WHERE id IN (10, 41);
UPDATE ung_vien_nhan SET nhan = 'khong_phai_su_kien'
WHERE id IN (1, 2, 3, 7, 9, 12, 27, 28, 29, 31, 33, 39, 40, 45, 47, 49);

-- 4. Ma su kien.
-- Mac dinh: moi thong bao la mot su kien rieng.
UPDATE ung_vien_nhan SET ma_su_kien = 'uv' || id WHERE nhan <> 'khong_phai_su_kien';
UPDATE ung_vien_nhan SET ma_su_kien = NULL       WHERE nhan =  'khong_phai_su_kien';

-- Roi gom nhung thong bao cung noi ve mot su kien.
UPDATE ung_vien_nhan SET ma_su_kien = 'pubg_playoffs_2'    WHERE id IN (14, 15);
UPDATE ung_vien_nhan SET ma_su_kien = 'pubg_finals_2'      WHERE id IN (16, 17, 18, 19, 20, 21, 22, 23);
UPDATE ung_vien_nhan SET ma_su_kien = 'wt_desert_predator' WHERE id IN (30, 35);
UPDATE ung_vien_nhan SET ma_su_kien = 'wf_iceblade_narin'  WHERE id IN (42, 44);

-- 5. Kiem tra.
SELECT
    nhan,
    COUNT(*)                   AS so_thong_bao,
    COUNT(DISTINCT ma_su_kien) AS so_su_kien
FROM ung_vien_nhan
GROUP BY nhan
ORDER BY so_su_kien DESC;