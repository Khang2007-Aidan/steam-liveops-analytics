
SELECT feed_type,
       feedname,
       feedlabel,
       COUNT(*) AS so_tin
FROM news_item
GROUP BY feed_type, feedname, feedlabel
ORDER BY so_tin DESC;