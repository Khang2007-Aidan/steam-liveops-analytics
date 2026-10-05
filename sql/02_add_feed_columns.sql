-- Them 2 cot phan loai nguon tin vao bang news_item.
--
-- Ly do: feedlabel la NHAN CHO NGUOI DOC, khong phai ma phan loai.
-- Vi du "Community Announcements", "TF2 Blog", "Product Update" deu la nguon
-- chinh thuc nhung ten khac nhau, con "PC Gamer" thi khong.
-- Loc bang feedlabel la phai liet ke tay tung ten, sot luc nao khong hay.
--
-- feedname va feed_type la truong may doc, Steam tra ve san trong API
-- nhung truoc day khong luu.
--
-- Chay mot lan. Chay lai cung khong sao vi co IF NOT EXISTS.

ALTER TABLE news_item ADD COLUMN IF NOT EXISTS feedname  text;
ALTER TABLE news_item ADD COLUMN IF NOT EXISTS feed_type integer;

-- Xem phan bo sau khi nap lai du lieu:
--   SELECT feed_type, feedname, feedlabel, COUNT(*)
--   FROM news_item
--   GROUP BY feed_type, feedname, feedlabel
--   ORDER BY COUNT(*) DESC;
