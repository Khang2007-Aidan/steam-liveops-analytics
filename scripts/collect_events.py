"""
Thu thap gia hien tai va tin tuc / ban cap nhat cua tung game.

Chay 1 lan moi ngay. Ghi ra hai file:
    data/prices/2026-09-26.csv   gia va muc giam gia hom do
    data/news/2026-09-26.csv     cac tin moi nhat cua tung game

File news la nguyen lieu de gan nhan loai su kien sau nay:
che do choi moi / nhan vat moi / hop tac / mua moi / giai dau / chi can bang.
Viec gan nhan lam thu cong, khong tu dong, vi may khong doc duoc y do van hanh.
"""

import csv
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

DIM_FILE = Path("data/dim_game.csv")
PRICE_DIR = Path("data/prices")
NEWS_DIR = Path("data/news")

STORE_URL = "https://store.steampowered.com/api/appdetails"
NEWS_URL = "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/"

SLEEP_SECONDS = 1.5
TIMEOUT_SECONDS = 20
MAX_RETRIES = 3

# So tin hoi moi game moi lan chay.
# Ly do chon 20: script nay chay 1 lan/ngay, chi can lon hon so thong bao mot
# game dang trong 1 ngay. Quan sat 27-28/09: 4 tin moi tren TAT CA 28 game.
# Neu co game nao tra ve dung 20 thi script se CANH BAO o cuoi, luc do phai
# tang so nay len. Khong doan, do roi bao.
NEWS_PER_GAME = 20

# 0 = khong cat noi dung tin. Truoc day de 600 ky tu, lam mat phan cuoi cua
# nhung thong bao dai. Tieu de khong bao gio bi cat.
NEWS_MAX_LENGTH = 0

PRICE_COLUMNS = [
    "collected_at_utc",
    "appid",
    "country_code",
    "price_final",
    "price_initial",
    "discount_percent",
]
NEWS_COLUMNS = [
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
        print(f"Chua co {path}. Chay scripts/verify_games.py truoc.")
        sys.exit(1)
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def get_json(url, params, session):
    """Goi API co thu lai. Tra ve JSON hoac None."""
    for attempt in range(MAX_RETRIES):
        try:
            response = session.get(url, params=params, timeout=TIMEOUT_SECONDS)
            response.raise_for_status()
            return response.json()
        except (requests.RequestException, ValueError):
            time.sleep(2**attempt)
    return None


def pick_entry(payload, appid):
    """
    Steam KHONG phai luc nao cung dat khoa bang appid minh hoi.
    Hoi 570 co the nhan ve {"2120612": {...}}. Payload luon chi co mot phan tu,
    nen lay phan tu do ra la chac an nhat.
    """
    entry = payload.get(str(appid))
    if entry is not None:
        return entry
    for value in payload.values():
        if isinstance(value, dict):
            return value
    return None


def fetch_price(appid, session, country_code):
    """
    Lay gia hien tai tai mot cua hang.

    Game mien phi tra ve gia 0, do khong phai loi.
    Gia luon kem country_code vi 100000 dong va 100000 do la hai chuyen khac han.
    """
    payload = get_json(
        STORE_URL,
        {
            "appids": appid,
            "cc": country_code,
            "l": "english",
            "filters": "price_overview",
        },
        session,
    )
    if not payload:
        return None

    entry = pick_entry(payload, appid) or {}
    if not entry.get("success"):
        return None

    data = entry.get("data") or {}
    price = data.get("price_overview") or {}

    return {
        "country_code": country_code,
        # price_overview tra ve don vi nho nhat cua tien te, chia 100
        "price_final": price.get("final", 0) // 100,
        "price_initial": price.get("initial", 0) // 100,
        "discount_percent": price.get("discount_percent", 0),
    }


def fetch_news(appid, session):
    """Lay cac tin moi nhat cua game. Tra ve list, co the rong."""
    payload = get_json(
        NEWS_URL,
        {
            "appid": appid,
            "count": NEWS_PER_GAME,
            "maxlength": NEWS_MAX_LENGTH,
        },
        session,
    )
    if not payload:
        return []
    return (payload.get("appnews") or {}).get("newsitems") or []


def clean_text(text):
    """Bo xuong dong va khoang trang thua de CSV khong bi vo dong."""
    return " ".join((text or "").split())


def open_writer(path, columns):
    """Mo file de ghi them, tu viet header neu file chua ton tai."""
    path.parent.mkdir(parents=True, exist_ok=True)
    need_header = not path.exists()
    handle = open(path, "a", newline="", encoding="utf-8")
    writer = csv.DictWriter(handle, fieldnames=columns)
    if need_header:
        writer.writeheader()
    return handle, writer


def main():
    collected_at = datetime.now(timezone.utc)
    stamp = collected_at.isoformat(timespec="seconds")
    day = collected_at.strftime("%Y-%m-%d")

    games = read_games(DIM_FILE)

    price_file, price_writer = open_writer(PRICE_DIR / f"{day}.csv", PRICE_COLUMNS)
    news_file, news_writer = open_writer(NEWS_DIR / f"{day}.csv", NEWS_COLUMNS)

    price_ok = 0
    news_rows = 0
    at_ceiling = []

    with requests.Session() as session, price_file, news_file:
        for game in games:
            appid = game["appid"]

            # Game khong ban o cua hang VN thi hoi cua hang US, neu khong se
            # khong bao gio co dong gia nao cho no.
            country_code = "vn" if game.get("available_vn") != "False" else "us"

            price = fetch_price(appid, session, country_code)
            if price is not None:
                price_writer.writerow(
                    {"collected_at_utc": stamp, "appid": appid, **price}
                )
                price_ok += 1
            time.sleep(SLEEP_SECONDS)

            news_items = fetch_news(appid, session)

            # Tra ve dung bang so da hoi nghia la co the con tin bi cat.
            if len(news_items) == NEWS_PER_GAME:
                at_ceiling.append(game["name"])

            for item in news_items:
                published = datetime.fromtimestamp(
                    item.get("date", 0), tz=timezone.utc
                ).isoformat(timespec="seconds")

                news_writer.writerow(
                    {
                        "collected_at_utc": stamp,
                        "appid": appid,
                        # news_gid la ma duy nhat cua tin, dung de loc trung sau nay
                        "news_gid": item.get("gid", ""),
                        "published_at_utc": published,
                        # feedname va feed_type la ma may doc, dung de phan loai
                        # nguon chinh thuc hay bao chi. feedlabel chi la nhan
                        # hien thi cho nguoi doc.
                        "feedname": item.get("feedname", ""),
                        "feed_type": item.get("feed_type", ""),
                        "feedlabel": clean_text(item.get("feedlabel")),
                        "title": clean_text(item.get("title")),
                        "url": item.get("url", ""),
                        "snippet": clean_text(item.get("contents"))[:500],
                    }
                )
                news_rows += 1
            time.sleep(SLEEP_SECONDS)

    print(f"{stamp}  gia: {price_ok}/{len(games)} game   tin: {news_rows} dong")

    if at_ceiling:
        print(
            f"CANH BAO: {len(at_ceiling)} game tra ve dung {NEWS_PER_GAME} tin, "
            f"co the bi cat cut. Tang NEWS_PER_GAME len."
        )
        for name in at_ceiling:
            print(f"  {name}")

    return 0 if price_ok > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
