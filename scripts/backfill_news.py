"""
Thu bu lich su tin tuc, chay MOT LAN.

Muc dich: file news thu hang ngay bi cat o 20 tin moi game, do hang so
NEWS_PER_GAME = 20 trong collect_events.py. Script nay hoi Steam voi so luong
lon hon nhieu de lay lich su day du nhat co the.

Script KHONG doan cai tran cua Steam. No hoi mot so lon roi DEM xem Steam thuc
su tra ve bao nhieu, va bao cho ban biet game nao cham tran.

Cach chay:
    python scripts/backfill_news.py
    python scripts/backfill_news.py 500     # tu chon so luong hoi

Ket qua ghi vao data/news/backfill_YYYY-MM-DD.csv, dinh dang giong het file
news hang ngay, nen script nap du lieu tu doc duoc va tu loc trung theo news_gid.
"""

import csv
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

DIM_FILE = Path("data/dim_game.csv")
NEWS_DIR = Path("data/news")
NEWS_URL = "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/"

# So tin hoi moi game. Khong phai gia tri Steam cam ket, chi la so ta hoi.
# Steam tra ve bao nhieu thi script dem va bao lai.
DEFAULT_COUNT = 500

# maxlength = 0 nghia la KHONG cat noi dung. Khac voi file hang ngay dang
# cat o 600 ky tu.
NEWS_MAX_LENGTH = 0

SLEEP_SECONDS = 1.5
TIMEOUT_SECONDS = 30
MAX_RETRIES = 3

COLUMNS = [
    "collected_at_utc",
    "appid",
    "news_gid",
    "published_at_utc",
    "feedname",
    "feed_type",
    "feedlabel",
    "title",
    "url",
    "snippet",
]


def read_games(path):
    if not path.exists():
        print(f"Khong thay {path}. Chay tu thu muc goc cua repo.")
        sys.exit(1)
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def fetch_news(appid, count, session):
    """Tra ve (danh_sach_tin, ly_do_that_bai)."""
    params = {"appid": appid, "count": count, "maxlength": NEWS_MAX_LENGTH}
    reason = "chua goi"

    for attempt in range(MAX_RETRIES):
        try:
            response = session.get(NEWS_URL, params=params, timeout=TIMEOUT_SECONDS)
            if response.status_code >= 400:
                reason = f"HTTP {response.status_code}"
                time.sleep(2**attempt)
                continue
            payload = response.json()
        except requests.RequestException as e:
            reason = f"loi mang: {type(e).__name__}"
            time.sleep(2**attempt)
            continue
        except ValueError:
            reason = "phan hoi khong phai JSON"
            time.sleep(2**attempt)
            continue

        items = (payload.get("appnews") or {}).get("newsitems")
        if items is None:
            return None, "khong co truong newsitems"
        return items, None

    return None, reason


def clean_text(text):
    return " ".join((text or "").split())


def main():
    count = DEFAULT_COUNT
    if len(sys.argv) > 1:
        count = int(sys.argv[1])

    collected_at = datetime.now(timezone.utc)
    stamp = collected_at.isoformat(timespec="seconds")
    day = collected_at.strftime("%Y-%m-%d")

    games = read_games(DIM_FILE)
    NEWS_DIR.mkdir(parents=True, exist_ok=True)
    out_path = NEWS_DIR / f"backfill_{day}.csv"

    print(f"Hoi Steam {count} tin moi game, {len(games)} game.\n")

    total_rows = 0
    at_ceiling = []
    failures = []
    oldest_overall = None

    with requests.Session() as session, open(
        out_path, "w", newline="", encoding="utf-8"
    ) as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS)
        writer.writeheader()

        for i, game in enumerate(games, start=1):
            appid = game["appid"]
            name = game["name"]

            items, reason = fetch_news(appid, count, session)
            if items is None:
                failures.append((appid, name, reason))
                print(f"[{i}/{len(games)}] THAT BAI  {name}  -> {reason}")
                time.sleep(SLEEP_SECONDS)
                continue

            oldest = None
            for item in items:
                published = datetime.fromtimestamp(
                    item.get("date", 0), tz=timezone.utc
                )
                if oldest is None or published < oldest:
                    oldest = published

                writer.writerow(
                    {
                        "collected_at_utc": stamp,
                        "appid": appid,
                        "news_gid": item.get("gid", ""),
                        "published_at_utc": published.isoformat(timespec="seconds"),
                        "feedname": item.get("feedname", ""),
                        "feed_type": item.get("feed_type", ""),
                        "feedlabel": clean_text(item.get("feedlabel")),
                        "title": clean_text(item.get("title")),
                        "url": item.get("url", ""),
                        "snippet": clean_text(item.get("contents")),
                    }
                )
                total_rows += 1

            if oldest is not None and (oldest_overall is None or oldest < oldest_overall):
                oldest_overall = oldest

            # Tra ve dung bang so da hoi nghia la CO THE con tin cu hon
            # ma Steam khong tra. Do la dau hieu cham tran.
            ceiling_flag = ""
            if len(items) == count:
                at_ceiling.append((name, len(items)))
                ceiling_flag = "  <-- CHAM TRAN, co the con tin cu hon"

            oldest_text = oldest.strftime("%Y-%m-%d") if oldest else "khong co tin"
            print(
                f"[{i}/{len(games)}] {name}: {len(items)} tin, "
                f"cu nhat {oldest_text}{ceiling_flag}"
            )

            time.sleep(SLEEP_SECONDS)

    print("\n" + "=" * 70)
    print(f"Ghi {total_rows} dong vao {out_path}")
    if oldest_overall:
        print(f"Tin cu nhat lay duoc: {oldest_overall.strftime('%Y-%m-%d')}")

    if at_ceiling:
        print(f"\n{len(at_ceiling)} game cham tran {count} tin:")
        for name, n in at_ceiling:
            print(f"  {name}")
        print(f"Chay lai voi so lon hon neu muon day du hon: "
              f"python scripts/backfill_news.py {count * 2}")
    else:
        print(f"\nKhong game nao cham tran {count}. "
              f"Day la TOAN BO lich su tin Steam cho ve.")

    if failures:
        print("\nThat bai:")
        for appid, name, reason in failures:
            print(f"  {appid} {name}: {reason}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
