-- ==============================================================
-- BAI TAP SQL SO 1
-- Viet cau truy van ngay duoi moi cau hoi. Tu lam truoc, dung tra.
-- Lam xong gui lai toan bo file nay de duoc cham.
-- ==============================================================

-- Cau 1. Liet ke tat ca game: appid va ten, sap xep theo ten A-Z.
-- Ket qua mong doi: 28 dong, 2 cot.



-- Cau 2. Co bao nhieu game mien phi, bao nhieu game tra phi?
-- Goi y: GROUP BY tren cot is_free.
-- Ket qua mong doi: 2 dong.



-- Cau 3. Nhung game nao khong ban o cua hang Viet Nam?
-- Ket qua mong doi: 4 dong, co ten game.



-- Cau 4. Bang fact_player_count dang co bao nhieu dong,
-- va bao nhieu thoi diem do KHAC NHAU?
-- Goi y: COUNT(*) va COUNT(DISTINCT ...) trong cung mot cau.
-- Ket qua mong doi: 1 dong, 2 cot.



-- Cau 5. Tai lan do MOI NHAT, moi game co bao nhieu nguoi choi?
-- Phai hien TEN game chu khong phai appid.
-- Goi y: can JOIN, va can mot cau truy van con de tim thoi diem lon nhat.
-- Ket qua mong doi: 28 dong.



-- Cau 6. Tu ket qua cau 5, lay 5 game dong nguoi choi nhat.
-- Goi y: ORDER BY ... DESC va LIMIT.



-- Cau 7. Trung binh luong nguoi choi cua tung game qua TAT CA cac lan do,
-- kem ten game, sap xep giam dan.
-- Goi y: GROUP BY va AVG. Lam tron bang ROUND neu muon nhin de hon.



-- Cau 8. Game nao dang giam gia tai lan do moi nhat?
-- Hien ten game, muc giam, gia truoc va gia sau, VA CA country_code.
-- Nho ly do phai co country_code: doc lai data/NOTES.md.



-- Cau 9. Trong bang news_item, moi feedlabel co bao nhieu ban tin?
-- Sap xep tu nhieu den it.
-- Cau nay cho thay ro bao chi lan lon voi thong bao chinh thuc the nao.



-- Cau 10. CHI tinh thong bao chinh thuc (feedlabel = 'Community Announcements'):
-- moi game co bao nhieu ban tin? Chi lay nhung game co tu 5 ban tin tro len,
-- sap xep giam dan, co ten game.
-- Goi y: WHERE loc truoc khi gom nhom, HAVING loc sau khi gom nhom.
-- Day la cau kho nhat, no dung gan nhu tat ca nhung gi o tren.


