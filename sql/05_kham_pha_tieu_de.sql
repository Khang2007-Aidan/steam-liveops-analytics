SELECT LOWER(SPLIT_PART(title, ' ', 1)) AS tu_dau_tien,
       COUNT(*) AS so_tin
FROM official_news
GROUP BY tu_dau_tien
ORDER BY so_tin DESC
LIMIT 30;

-- =====================================================================
-- Phep do 2, ngay 02/10/2026: luat tu khoa phu duoc bao nhieu phan tram?
--
-- Tai sao phai do lai: phep do 1 (tu dau tien) chi phu 8,4% vi nhieu
-- game viet "NARAKA: BLADEPOINT - Update Notes", loai noi dung nam o
-- GIUA cau. Lan nay tim tu khoa o BAT KY DAU bang ILIKE '%...%'.
--
-- ILIKE = LIKE nhung khong phan biet chu hoa chu thuong.
-- Nho bai hoc dau gach duoi: trong LIKE, _ la ky tu bat ky va % la
-- chuoi bat ky, muon tim dung ky tu do phai viet \_ hoac \%.
--
-- CASE WHEN chay tu tren xuong, DUNG o dieu kien dau tien khop.
-- Nen MOI TIN chi dem MOT LAN, khong bi trung.
-- Hau qua: THU TU cac dong duoi la mot QUYET DINH, khong phai ngau nhien.
-- Tin "Hotfix for Season 5" se vao nhom hotfix chu khong vao nhom mua,
-- vi hotfix dung tren. Doi thu tu la doi ket qua. Doc kien phai ghi ro.
--
-- Nhom 99 la cau tra loi tao can: ti le tin ma luat tu khoa KHONG
-- cham toi duoc. Neu 99 nho, luat la du. Neu 99 lon, phan cum co dat dung.
-- =====================================================================

SELECT
    CASE
        WHEN title ILIKE '%hotfix%'                                      THEN '01_hotfix'
        WHEN title ILIKE '%maintenance%'
          OR title ILIKE '%downtime%'
          OR title ILIKE '%server%down%'                                 THEN '02_bao_tri'
        WHEN title ILIKE '%patch%'                                       THEN '03_patch'
        WHEN title ILIKE '%balance%'
          OR title ILIKE '%nerf%'
          OR title ILIKE '%buff%'                                        THEN '04_can_bang'
        WHEN title ILIKE '%new hero%'
          OR title ILIKE '%new character%'
          OR title ILIKE '%new legend%'
          OR title ILIKE '%new operator%'
          OR title ILIKE '%new survivor%'
          OR title ILIKE '%new killer%'                                  THEN '05_nhan_vat_moi'
        WHEN title ILIKE '%season%'
          OR title ILIKE '%chapter%'
          OR title ILIKE '%battle pass%'                                 THEN '06_mua_moi'
        WHEN title ILIKE '%collab%'
          OR title ILIKE '%crossover%'                                   THEN '07_hop_tac'
        WHEN title ILIKE '%tournament%'
          OR title ILIKE '%esports%'
          OR title ILIKE '%championship%'
          OR title ILIKE '%invitational%'                                THEN '08_giai_dau'
        WHEN title ILIKE '%sale%'
          OR title ILIKE '%discount%'
          OR title ILIKE '%free weekend%'
          OR title ILIKE '%free to play%'                                THEN '09_giam_gia'
        WHEN title ILIKE '%event%'
          OR title ILIKE '%festiv%'
          OR title ILIKE '%anniversar%'
          OR title ILIKE '%halloween%'
          OR title ILIKE '%christmas%'
          OR title ILIKE '%lunar new year%'                              THEN '10_su_kien'
        WHEN title ILIKE '%dlc%'
          OR title ILIKE '%expansion%'
          OR title ILIKE '%out now%'
          OR title ILIKE '%release%'
          OR title ILIKE '%launch%'                                      THEN '11_ra_mat'
        WHEN title ILIKE '%update%'
          OR title ILIKE '%notes%'                                       THEN '12_update_chung'
        ELSE '99_chua_phan_loai'
    END AS nhom,
    COUNT(*) AS so_tin,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS phan_tram
FROM official_news
GROUP BY nhom
ORDER BY nhom;


-- =====================================================================
-- Phep do 3, 02/10/2026: nhin tan mat 40 tieu de nhom 99.
--
-- Muc dich: truoc khi viet code phan cum, phai biet trong do la cai gi.
-- Doc 40 dong het 2 phut, re hon viet model nhieu.
--
-- setseed co dinh so ngau nhien. Chay lai van ra DUNG 40 dong do,
-- nen ket qua tai lap duoc. Khong co no thi moi lan chay mot ket qua
-- khac, khong ai kiem chung lai duoc viec minh da lam.
-- Phai chay CA HAI dong cung mot luot (boi den ca 2 roi bam F5).
-- =====================================================================

SELECT setseed(0.42);

SELECT appid, title
FROM news_rule_label
WHERE nhom_luat = '99_chua_phan_loai'
ORDER BY random()
LIMIT 40;


-- =====================================================================
-- Phep do 4, 02/10/2026: tim CHUYEN MUC DINH KY bang khuon tieu de.
--
-- Phat hien tu 40 tieu de doc tay: gan mot nua nhom 99 khong phai su kien.
-- No la ban tin dinh ky (This Week in the Realm, Devblog 186,
-- Community Blog #036, This Week in Destiny) va thong bao hanh chinh
-- (NARAKA Banned Players List).
--
-- Nhung bai nay khac nhau CHI O SO va TEN THANG. Xoa hai thu do di
-- thi chung trung khit nhau. Khong can machine learning.
--
-- regexp_replace(chuoi, mau, thay_bang, 'g')
--   'g' = global, thay TAT CA cho khop chu khong chi cho dau tien.
--   Long nhau 2 lan: lan trong xoa so, lan ngoai xoa ten thang.
--
-- HAVING COUNT(*) >= 10: mot khuon lap tren 10 lan trong CUNG MOT GAME
-- thi gan nhu chac chan la chuyen muc dinh ky, khong phai su kien rieng le.
-- So 10 la nguong TAO CHON, khong phai luat tu nhien. Neu ket qua cho thay
-- nguong nay cat nham thi doi lai.
--
-- HAN CHE da biet: 'may' va 'march' cung la tu thuong, bi xoa nham.
-- Chap nhan duoc o buoc do nay, nhung khong duoc dung ket qua nay
-- lam nhan chinh thuc.
-- =====================================================================

SELECT
    g.name AS game,
    regexp_replace(
        regexp_replace(lower(n.title), '[0-9]+', '#', 'g'),
        '(january|february|march|april|may|june|july|august|september|october|november|december)',
        '<thang>', 'g'
    ) AS khuon_tieu_de,
    COUNT(*) AS so_tin
FROM news_rule_label AS n
JOIN dim_game       AS g ON g.appid = n.appid
GROUP BY g.name, khuon_tieu_de
HAVING COUNT(*) >= 10
ORDER BY so_tin DESC
LIMIT 50;


-- =====================================================================
-- Phep do 5, 02/10/2026: tong do phu cua khuon lap, thu nhieu nguong.
--
-- Phep do 4 bi cat o LIMIT 50 nen chi thay duoc 2.537 tin (31,9%).
-- Lan nay dem HET, va thu 4 nguong khac nhau de biet con so 10
-- tao chon co hop ly khong. Day goi la PHAN TICH DO NHAY
-- (sensitivity analysis): doi mot tham so roi xem ket qua lech bao nhieu.
-- Neu ket qua doi it -> tham so khong quan trong, chon sao cung duoc.
-- Neu doi nhieu -> phai can nhac ky, va phai ghi ro trong bao cao.
--
-- WITH ... AS (...) goi la CTE (Common Table Expression) - bang tam
-- chi ton tai trong cau truy van nay. Dung de chia bai toan ra tung
-- buoc cho de doc, thay vi long subquery ba bon tang.
--
-- COUNT(*) FILTER (WHERE ...) la cach Postgres dem co dieu kien
-- ngay trong mot dong SELECT, khoi phai chay 4 cau rieng.
-- =====================================================================

WITH khuon AS (
    -- Buoc 1: tao khuon cho tung tin, giong phep do 4.
    SELECT
        n.appid,
        regexp_replace(
            regexp_replace(lower(n.title), '[0-9]+', '#', 'g'),
            '(january|february|march|april|may|june|july|august|september|october|november|december)',
            '<thang>', 'g'
        ) AS k
    FROM news_rule_label AS n
),
dem AS (
    -- Buoc 2: moi khuon cua moi game lap bao nhieu lan.
    SELECT appid, k, COUNT(*) AS n_lap
    FROM khuon
    GROUP BY appid, k
)
-- Buoc 3: cong so TIN (khong phai so khuon) o tung nguong.
SELECT
    SUM(n_lap)                                 AS tong_tin,
    SUM(n_lap) FILTER (WHERE n_lap >= 3)       AS lap_tu_3_lan,
    SUM(n_lap) FILTER (WHERE n_lap >= 5)       AS lap_tu_5_lan,
    SUM(n_lap) FILTER (WHERE n_lap >= 10)      AS lap_tu_10_lan,
    SUM(n_lap) FILTER (WHERE n_lap >= 20)      AS lap_tu_20_lan,
    COUNT(*)                                   AS so_khuon_khac_nhau,
    COUNT(*) FILTER (WHERE n_lap >= 10)        AS so_khuon_lap_tu_10
FROM dem;


-- =====================================================================
-- Phep do 6, 02/10/2026: xuat 65 khuon lap de GAN NHAN TAY.
--
-- Quyet dinh dua tren phep do 5: chi co 65 khuon lap tu 10 lan tro len,
-- phu 2.697 tin (34%). Doc tay 65 dong re hon viet code phan cum,
-- va ket qua kiem chung duoc tung dong.
--
-- MIN(title) lay mot vi du that de biet khuon do trong doi hinh nao.
-- tu_ngay / den_ngay cho biet chuyen muc do con chay hay da ngung.
-- Mot chuyen muc ngung tu 2019 thi khong anh huong gi toi phan tich
-- cua minh (du lieu CCU chi tu 09/2026 tro di).
-- =====================================================================

WITH khuon AS (
    SELECT
        n.appid,
        n.title,
        n.published_at,
        regexp_replace(
            regexp_replace(lower(n.title), '[0-9]+', '#', 'g'),
            '(january|february|march|april|may|june|july|august|september|october|november|december)',
            '<thang>', 'g'
        ) AS k
    FROM news_rule_label AS n
)
SELECT
    g.name                       AS game,
    k.k                          AS khuon,
    COUNT(*)                     AS so_tin,
    MIN(k.title)                 AS vi_du_tieu_de,
    MIN(k.published_at)::date    AS tu_ngay,
    MAX(k.published_at)::date    AS den_ngay,
    ''                           AS nhan      -- cot de TRONG, may tu dien
FROM khuon    AS k
JOIN dim_game AS g ON g.appid = k.appid
GROUP BY g.name, k.k
HAVING COUNT(*) >= 10
ORDER BY COUNT(*) DESC;