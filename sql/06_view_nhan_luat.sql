-- View gan NHAN TAM THOI bang luat tu khoa, chot 02/10/2026.
--
-- Day la BASELINE. Moi phuong phap phuc tap hon (phan cum, model)
-- phai chung minh no tot hon cai nay moi duoc dung.
--
-- Dinh nghia luat o DAY mot lan. Cac file khac chi viet
-- FROM news_rule_label, khong chep lai khoi CASE.
--
-- CASE WHEN chay tu tren xuong, dung o dieu kien dau tien khop,
-- nen MOI TIN chi mot nhan. THU TU la quyet dinh, khong ngau nhien.
--
-- Ket qua do duoc ngay 02/10 tren 7.941 tin chinh thuc:
--   99_chua_phan_loai  3.949  49,7%
--   12_update_chung    1.810  22,8%   <- thung mo ho, qua to
--   11_ra_mat            566   7,1%
--   03_patch             516   6,5%
--   10_su_kien           333   4,2%
--   06_mua_moi           219   2,8%
--   09_giam_gia          216   2,7%
--   01_hotfix            205   2,6%
--   08_giai_dau           73   0,9%
--   04_can_bang           19   0,2%
--   05_nhan_vat_moi       12   0,2%   <- qua it, khong du de phan tich
--   07_hop_tac            12   0,2%   <- qua it, khong du de phan tich
--   02_bao_tri            11   0,1%
--
-- VAN DE DA BIET: luat bat tot phan nhieu (va loi, bao tri) nhung gan
-- nhu mu voi phan NOI DUNG. Dang dieu tra nguyen nhan.
--
-- CANH BAO: view nay dung n.* nen danh sach cot co dinh luc tao.
-- Them cot moi vao news_item thi phai chay lai file nay.

CREATE OR REPLACE VIEW news_rule_label AS
SELECT
    n.*,
    CASE
        WHEN n.title ILIKE '%hotfix%'                                      THEN '01_hotfix'
        WHEN n.title ILIKE '%maintenance%'
          OR n.title ILIKE '%downtime%'
          OR n.title ILIKE '%server%down%'                                 THEN '02_bao_tri'
        WHEN n.title ILIKE '%patch%'                                       THEN '03_patch'
        WHEN n.title ILIKE '%balance%'
          OR n.title ILIKE '%nerf%'
          OR n.title ILIKE '%buff%'                                        THEN '04_can_bang'
        WHEN n.title ILIKE '%new hero%'
          OR n.title ILIKE '%new character%'
          OR n.title ILIKE '%new legend%'
          OR n.title ILIKE '%new operator%'
          OR n.title ILIKE '%new survivor%'
          OR n.title ILIKE '%new killer%'                                  THEN '05_nhan_vat_moi'
        WHEN n.title ILIKE '%season%'
          OR n.title ILIKE '%chapter%'
          OR n.title ILIKE '%battle pass%'                                 THEN '06_mua_moi'
        WHEN n.title ILIKE '%collab%'
          OR n.title ILIKE '%crossover%'                                   THEN '07_hop_tac'
        WHEN n.title ILIKE '%tournament%'
          OR n.title ILIKE '%esports%'
          OR n.title ILIKE '%championship%'
          OR n.title ILIKE '%invitational%'                                THEN '08_giai_dau'
        WHEN n.title ILIKE '%sale%'
          OR n.title ILIKE '%discount%'
          OR n.title ILIKE '%free weekend%'
          OR n.title ILIKE '%free to play%'                                THEN '09_giam_gia'
        WHEN n.title ILIKE '%event%'
          OR n.title ILIKE '%festiv%'
          OR n.title ILIKE '%anniversar%'
          OR n.title ILIKE '%halloween%'
          OR n.title ILIKE '%christmas%'
          OR n.title ILIKE '%lunar new year%'                              THEN '10_su_kien'
        WHEN n.title ILIKE '%dlc%'
          OR n.title ILIKE '%expansion%'
          OR n.title ILIKE '%out now%'
          OR n.title ILIKE '%release%'
          OR n.title ILIKE '%launch%'                                      THEN '11_ra_mat'
        WHEN n.title ILIKE '%update%'
          OR n.title ILIKE '%notes%'                                       THEN '12_update_chung'
        ELSE '99_chua_phan_loai'
    END AS nhom_luat
FROM official_news AS n;