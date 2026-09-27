"""
Xac minh danh sach game va tao bang dim_game.

Doc data/games_seed.csv (chi co appid + ghi chu do nguoi viet tay),
goi Steam Store API de lay thong tin chinh thuc, roi ghi ra data/dim_game.csv.

Chay lai script nay khi them game moi vao seed.
"""

import csv
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

SEED_FILE = Path("data/games_seed.csv")
DIM_FILE = Path("data/dim_game.csv")
API_URL = "https://store.steampowered.com/api/appdetails"

# Steam gioi han khoang 200 luot goi moi 5 phut cho API nay.
# Nghi 1.5 giay moi lan la an toan, khong bao gio cham tran.
SLEEP_SECONDS = 1.5
TIMEOUT_SECONDS = 20
MAX_RETRIES = 3

COLUMNS = [
    "appid",
    "name",
    "is_free",
    "type",
    "release_date",
    "developer",
    "publisher",
    "genres",
    "price_vnd",
    "verified_at_utc",
]


def read_seed(path):
    """Doc danh sach appid can theo doi."""
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def fetch_app_details(appid, session):
    """Goi Store API cho mot game. Tra ve dict du lieu hoac None neu that bai."""
    params = {"appids": appid, "cc": "vn", "l": "english"}

    for attempt in range(MAX_RETRIES):
        try:
            response = session.get(API_URL, params=params, timeout=TIMEOUT_SECONDS)
            response.raise_for_status()
            payload = response.json()
        except (requests.RequestException, ValueError):
            # Loi mang hoac JSON hong. Cho lau dan roi thu lai: 1s, 2s, 4s.
            time.sleep(2**attempt)
            continue

        entry = payload.get(str(appid))
        if not entry or not entry.get("success"):
            return None
        return entry.get("data")

    return None


def to_row(appid, data, verified_at):
    """Bien JSON cua Steam thanh mot dong phang de ghi vao CSV."""
    price = data.get("price_overview") or {}
    genres = data.get("genres") or []
    release = data.get("release_date") or {}

    return {
        "appid": appid,
        "name": data.get("name", ""),
        "is_free": data.get("is_free", False),
        "type": data.get("type", ""),
        "release_date": release.get("date", ""),
        "developer": "; ".join(data.get("developers") or []),
        "publisher": "; ".join(data.get("publishers") or []),
        "genres": "; ".join(g.get("description", "") for g in genres),
        # price_overview tra ve don vi nho nhat, VND thi chia 100
        "price_vnd": price.get("initial", 0) // 100 if price else 0,
        "verified_at_utc": verified_at,
    }


def main():
    verified_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    seed_rows = read_seed(SEED_FILE)

    results = []
    mismatches = []
    failures = []

    with requests.Session() as session:
        for i, row in enumerate(seed_rows, start=1):
            appid = row["appid"].strip()
            guess = row["ghi_chu"].strip()

            data = fetch_app_details(appid, session)
            if data is None:
                failures.append((appid, guess))
                print(f"[{i}/{len(seed_rows)}] THAT BAI  {appid}  ({guess})")
            else:
                record = to_row(appid, data, verified_at)
                results.append(record)

                official = record["name"]
                free_tag = "F2P" if record["is_free"] else "tra phi"
                print(f"[{i}/{len(seed_rows)}] OK  {appid}  {official}  [{free_tag}]")

                # Canh bao neu ten chinh thuc khac xa ghi chu tay
                if guess.lower()[:8] not in official.lower():
                    mismatches.append((appid, guess, official))

            time.sleep(SLEEP_SECONDS)

    DIM_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(DIM_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS)
        writer.writeheader()
        writer.writerows(results)

    free_count = sum(1 for r in results if r["is_free"])
    print("\n" + "=" * 60)
    print(f"Ghi {len(results)} game vao {DIM_FILE}")
    print(f"  mien phi: {free_count}   tra phi: {len(results) - free_count}")

    if mismatches:
        print("\nTEN KHONG KHOP, kiem tra lai appid:")
        for appid, guess, official in mismatches:
            print(f"  {appid}: ghi chu '{guess}' nhung Steam tra ve '{official}'")

    if failures:
        print("\nKHONG LAY DUOC:")
        for appid, guess in failures:
            print(f"  {appid} ({guess})")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
