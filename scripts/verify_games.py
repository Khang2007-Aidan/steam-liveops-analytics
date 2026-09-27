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
    "available_vn",
    "verified_at_utc",
]


def read_seed(path):
    """Doc danh sach appid can theo doi."""
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def pick_entry(payload, appid):
    """
    Lay phan du lieu ra khoi payload cua Steam.

    Steam KHONG phai luc nao cung dat khoa bang appid minh hoi.
    Vi du hoi appid 570 thi no tra ve {"2120612": {...}}, ben trong moi co
    "steam_appid": 570. Nen khong duoc tin khoa ngoai cung.
    Payload luon chi co dung mot phan tu, lay phan tu do ra la chac an nhat.
    """
    entry = payload.get(str(appid))
    if entry is not None:
        return entry

    for value in payload.values():
        if isinstance(value, dict):
            return value

    return None


NOT_IN_STORE = "khong ban o cua hang nay"


def fetch_app_details(appid, session):
    """
    Lay thong tin game, uu tien cua hang Viet Nam.

    Mot so game khong ban o cua hang VN (vi du Path of Exile o Dong Nam A do
    Garena phat hanh rieng), luc do Steam tra ve success=false. Khi do hoi lai
    cua hang My de van lay duoc ten va the loai, dong thoi ghi nhan
    available_vn=False. Do la du lieu that, khong phai loi.

    Tra ve (data, available_vn, ly_do_that_bai).
    """
    data, reason = fetch_from_region(appid, session, "vn")
    if data is not None:
        return data, True, None

    if reason != NOT_IN_STORE:
        return None, None, reason

    time.sleep(SLEEP_SECONDS)
    data, reason = fetch_from_region(appid, session, "us")
    if data is not None:
        return data, False, None

    return None, None, f"khong co o ca VN lan US: {reason}"


def fetch_from_region(appid, session, country_code):
    """
    Goi Store API cho mot game tai mot cua hang cu the.
    Tra ve (data, ly_do_that_bai). Thanh cong thi ly_do la None.
    """
    params = {"appids": appid, "cc": country_code, "l": "english"}
    reason = "chua goi"

    for attempt in range(MAX_RETRIES):
        try:
            response = session.get(API_URL, params=params, timeout=TIMEOUT_SECONDS)
            if response.status_code >= 400:
                # Giu lai ly do that bai. Nuot loi di la tu bit mat mui cua minh.
                reason = f"HTTP {response.status_code}"
                if response.status_code == 429:
                    reason += " (bi chan toc do, can nghi lau hon)"
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

        entry = pick_entry(payload, appid)
        if entry is None:
            return None, f"payload rong, khoa co: {list(payload)[:3]}"
        if not entry.get("success"):
            return None, NOT_IN_STORE

        data = entry.get("data") or {}
        real_appid = data.get("steam_appid")
        if real_appid is not None and str(real_appid) != str(appid):
            return None, f"appid tra ve la {real_appid}, khong khop"

        return data, None

    return None, reason


def to_row(appid, data, available_vn, verified_at):
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
        # price_overview tra ve don vi nho nhat, VND thi chia 100.
        # Game khong ban o VN thi khong co gia VND, de 0.
        "price_vnd": price.get("initial", 0) // 100 if (price and available_vn) else 0,
        "available_vn": available_vn,
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

            data, available_vn, reason = fetch_app_details(appid, session)
            if data is None:
                failures.append((appid, guess, reason))
                print(f"[{i}/{len(seed_rows)}] THAT BAI  {appid}  ({guess})  -> {reason}")
            else:
                record = to_row(appid, data, available_vn, verified_at)
                results.append(record)

                official = record["name"]
                free_tag = "F2P" if record["is_free"] else "tra phi"
                vn_tag = "" if available_vn else "  [KHONG BAN O VN]"
                print(
                    f"[{i}/{len(seed_rows)}] OK  {appid}  {official}  [{free_tag}]{vn_tag}"
                )

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
    no_vn = [r for r in results if not r["available_vn"]]
    print("\n" + "=" * 60)
    print(f"Ghi {len(results)} game vao {DIM_FILE}")
    print(f"  mien phi: {free_count}   tra phi: {len(results) - free_count}")
    print(f"  khong ban o cua hang VN: {len(no_vn)}")
    for r in no_vn:
        print(f"    {r['appid']}  {r['name']}")

    if mismatches:
        print("\nTEN KHONG KHOP, kiem tra lai appid:")
        for appid, guess, official in mismatches:
            print(f"  {appid}: ghi chu '{guess}' nhung Steam tra ve '{official}'")

    if failures:
        print("\nKHONG LAY DUOC:")
        for appid, guess, reason in failures:
            print(f"  {appid} ({guess}): {reason}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
