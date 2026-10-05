-- View: chi cac ban tin tu nguon CHINH THUC.
--
-- View la mot bang AO. No khong luu du lieu, khong ton dung luong.
-- Moi lan truy van, Postgres chay lai cau SELECT ben duoi roi tra ket qua.
-- Nen du lieu luon moi nhat, khong bao gio bi cu.
--
-- Muc dich: bo loc nguon chinh thuc se xuat hien trong moi truy van ve su kien.
-- Chep di chep lai thi som muon cung go sai mot cho. Dinh nghia o day mot lan,
-- moi noi khac chi viet FROM official_news.
--
-- QUY TAC PHAN LOAI, chot ngay 29/09/2026 sau khi doi chieu du lieu that:
--
--   feed_type = 1        -> steam_community_announcements, 7.664 tin.
--                           Day la thong bao cong dong tren Steam.
--
--   feedname LIKE steam_ -> steam_updates (Product Update, 83 tin)
--                           steam_announce (Announcement, 15 tin)
--                           steam_release (Product Release, 7 tin)
--                           Deu la kenh chinh thuc cua Steam, nhung feed_type = 0.
--
--   feedname = tf2_blog  -> 172 tin. Blog cua Valve cho Team Fortress 2.
--                           Quyet dinh dua vao vi day la kenh thong bao chinh
--                           cua game do; bo ra la mat gan het su kien cua TF2.
--                           Phai ghi ro trong bao cao la TF2 dung kenh khac
--                           voi 27 game con lai.
--
-- KHONG tinh la chinh thuc: PCGamesN, PC Gamer, VG247, Gamemag.ru, SteamDB,
-- Rock Paper Shotgun, GamingOnLinux, The Loadout, Eurogamer, PlayGround.ru,
-- CGMagazine, Kotaku, Shacknews. Tat ca la bao chi viet VE game,
-- khong phai nha phat hanh noi.
--
-- Luu y ve dau gach duoi: trong LIKE, ky tu _ la dai dien cho mot ky tu bat ky.
-- Phai viet 'steam\_%' de tim dung dau gach duoi that.
--
-- CANH BAO: view dung SELECT * nhung danh sach cot duoc CO DINH luc tao view.
-- Neu sau nay them cot moi vao news_item thi phai chay lai file nay,
-- khong thi cot moi se khong xuat hien trong view.

CREATE OR REPLACE VIEW official_news AS
SELECT *
FROM news_item
WHERE feed_type = 1
   OR feedname LIKE 'steam\_%'
   OR feedname = 'tf2_blog';


-- Kiem tra nhanh sau khi tao: so dong cua view phai nho hon news_item.
--   SELECT
--       (SELECT COUNT(*) FROM news_item)     AS tong_tin,
--       (SELECT COUNT(*) FROM official_news) AS tin_chinh_thuc;
