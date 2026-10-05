-- Cong cu: xem NOI DUNG THAT cua cac tin thuoc mot khuon.
--
-- Ly do co file nay: tu dau den gio gan nhan bang cach nhin TIEU DE.
-- Tieu de ngan va de hieu nham ("Store Update 10.10.0" trong giong ban va
-- nhung thuc ra la cua hang vat pham). Cot snippet co noi dung that.
--
-- Cach dung: doi so o dong "WHERE kn.id = ..." roi chay lai.
-- Dung cho BAT KY khuon nao con phan van.

WITH khuon AS (
    SELECT
        n.appid,
        n.title,
        n.published_at,
        n.snippet,
        n.url,
        regexp_replace(
            regexp_replace(lower(n.title), '[0-9]+', '#', 'g'),
            '(january|february|march|april|may|june|july|august|september|october|november|december)',
            '<thang>', 'g'
        ) AS k
    FROM news_rule_label AS n
)
SELECT
    k.published_at::date  AS ngay,
    k.title               AS tieu_de,
    LEFT(k.snippet, 400)  AS trich_doan,
    k.url
FROM khuon      AS k
JOIN khuon_nhan AS kn
     ON kn.appid = k.appid
    AND kn.khuon = k.k
WHERE kn.id = 33          -- <<< doi so nay de xem khuon khac
ORDER BY k.published_at DESC
LIMIT 8;