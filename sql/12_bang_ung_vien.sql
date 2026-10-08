-- Bang ung vien su kien TRONG CUA SO QUAN SAT (tu 27/09/2026).
-- Day la tap se duoc gan nhan LOAI SU KIEN bang tay.
--
-- Cung khuon mau voi khuon_nhan (sql/07): co id de goi ten tung dong,
-- nhan ghi bang file UPDATE rieng de dung lai duoc tu dau.
--
-- Chay lai bao nhieu lan cung duoc:
--   - CREATE TABLE IF NOT EXISTS: khong tao lai
--   - ON CONFLICT DO NOTHING: tin da co thi bo qua, KHONG dong vao nhan
-- Moi tuan chay lai, tin moi duoc them vao cuoi voi id moi.
--
-- Cot nhan CHUA co rang buoc CHECK: bo nhan se chot SAU KHI doc du lieu.

CREATE TABLE IF NOT EXISTS ung_vien_nhan (
    id          serial  PRIMARY KEY,
    news_gid    text    NOT NULL UNIQUE,
    appid       integer NOT NULL,
    game        text    NOT NULL,
    ngay_dang   date    NOT NULL,
    tieu_de     text,
    trich_doan  text,
    nhan        text
);

INSERT INTO ung_vien_nhan (news_gid, appid, game, ngay_dang, tieu_de, trich_doan)
SELECT
    n.news_gid,
    n.appid,
    g.name,
    n.published_at::date,
    n.title,
    -- Snippet cua Steam chua ma dinh dang dang [img]...[/img], [p], [h2].
    -- Lan trong: xoa moi the trong ngoac vuong.
    -- Lan ngoai: xoa duong dan anh {STEAM_CLAN_IMAGE}/... con sot lai.
    LEFT(
        regexp_replace(
            regexp_replace(n.snippet, '\[[^\]]*\]', ' ', 'g'),
            '\{STEAM_CLAN_IMAGE\}\S*', ' ', 'g'
        ),
        400
    )
FROM news_ung_vien AS n
JOIN dim_game      AS g ON g.appid = n.appid
WHERE n.published_at >= '2026-09-27'
ORDER BY g.name, n.published_at
ON CONFLICT (news_gid) DO NOTHING;


-- Danh sach de doc. Chi tieu de truoc, cho gon.
SELECT id, game, ngay_dang, tieu_de
FROM ung_vien_nhan
ORDER BY id;

-- Doc noi dung cac dong chua chac truoc khi gan nhan.
SELECT id, game, tieu_de, trich_doan
FROM ung_vien_nhan
WHERE id IN (4, 5, 6, 25, 47, 50)
ORDER BY id;