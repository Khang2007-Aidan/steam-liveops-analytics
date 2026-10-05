-- Bang gan nhan cho cac KHUON tieu de lap lai.
--
-- Thay cho viec xuat CSV ra Excel. Ly do doi: Excel doc file UTF-8
-- bang bang ma ANSI, lam hong dau gach ngang trong cot khuon
-- (vi du "update – April" thanh "update â€" April"). Khuon la khoa noi,
-- hong khoa la mat dong do ma khong co canh bao nao.
--
-- Bang nay CHAY LAI DUOC nhieu lan ma khong mat nhan da gan:
--   - CREATE TABLE IF NOT EXISTS : da co thi khong tao lai
--   - ON CONFLICT DO UPDATE      : chi cap nhat so_tin va den_ngay,
--                                  KHONG dong vao cot nhan
-- Nen moi tuan co tin moi thi chay lai file nay, so_tin tu cap nhat.
--
-- CHECK la rang buoc do DATABASE kiem tra. Go sai mot chu la no tu choi
-- luu. Day la cach chong go nhan sai, tot hon la tu nho.

CREATE TABLE IF NOT EXISTS khuon_nhan (
    id             serial  PRIMARY KEY,
    appid          integer NOT NULL,
    game           text    NOT NULL,
    khuon          text    NOT NULL,
    so_tin         integer NOT NULL,
    vi_du_tieu_de  text,
    tu_ngay        date,
    den_ngay       date,
    nhan           text,

    CONSTRAINT khuon_nhan_duy_nhat UNIQUE (appid, khuon),

    CONSTRAINT nhan_hop_le CHECK (
        nhan IS NULL OR nhan IN (
            'nhieu_patch',
            'nhieu_bantin',
            'nhieu_hanhchinh',
			'nhieu_quangcao',
            'sukien_lap',
			'sukien_esport',
            'khong_chac'
        )
    )
);

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
INSERT INTO khuon_nhan (appid, game, khuon, so_tin, vi_du_tieu_de, tu_ngay, den_ngay)
SELECT
    k.appid,
    g.name,
    k.k,
    COUNT(*),
    MIN(k.title),
    MIN(k.published_at)::date,
    MAX(k.published_at)::date
FROM khuon    AS k
JOIN dim_game AS g ON g.appid = k.appid
GROUP BY k.appid, g.name, k.k
HAVING COUNT(*) >= 10
ORDER BY COUNT(*) DESC
ON CONFLICT (appid, khuon) DO UPDATE SET
    so_tin   = EXCLUDED.so_tin,
    den_ngay = EXCLUDED.den_ngay;


-- Kiem tra: phai ra 65 dong, va 65 dong chua gan nhan.
SELECT COUNT(*) AS tong, COUNT(*) FILTER (WHERE nhan IS NULL) AS chua_gan
FROM khuon_nhan;


-- Danh sach gon de doc va ghi lai id.
SELECT id, game, so_tin, vi_du_tieu_de
FROM khuon_nhan
ORDER BY id;


