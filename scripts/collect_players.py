"""
Thu thap luong nguoi choi dong thoi (CCU) cua tung game.

Chay 4 lan moi ngay. Moi lan ghi them mot loat dong vao file cua ngay hom do:
    data/players/2026-09-26.csv

Day la BANG FACT. No chi chua appid va con so, khong chua ten game.
Ten game nam o data/dim_game.csv (bang DIM). Tach nhu vay de sau nay
doi ten game thi chi sua mot cho, va de nap thang vao star schema.
"""

import csv
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

DIM_FILE = Path("data/dim_game.csv")
OUT_DIR = Path("data/players")
API_URL = "https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/"

SLEEP_SECONDS = 0.5
TIMEOUT_SECONDS = 15
MAX_RETRIES = 3

COLUMNS = ["collected_at_utc", "appid", "player_count"]


def read_games(path):
    """Doc danh sach game tu bang dim."""
    if not path.exists():
        print(f"Chua co {path}. Chay scripts/verify_games.py truoc.")
        sys.exit(1)

    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def fetch_player_count(appid, session):
    """Tra ve so nguoi choi dong thoi, hoac None neu that bai."""
    for attempt in range(MAX_RETRIES):
        try:
            response = session.get(
                API_URL, params={"appid": appid}, timeout=TIMEOUT_SECONDS
            )
            response.raise_for_status()
            body = response.json().get("response", {})
        except (requests.RequestException, ValueError):
            time.sleep(2**attempt)
            continue

        # result = 1 nghia la Steam tra ve so hop le
        if body.get("result") == 1:
            return body.get("player_count")
        return None

    return None


def main():
    # Moc thoi gian THAT SU luc goi, khong phai gio da hen trong lich.
    # GitHub Actions hay chay tre, neu tin vao gio hen thi du lieu sai.
    collected_at = datetime.now(timezone.utc)
    stamp = collected_at.isoformat(timespec="seconds")
    day = collected_at.strftime("%Y-%m-%d")

    games = read_games(DIM_FILE)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUT_DIR / f"{day}.csv"
    need_header = not out_path.exists()

    success = 0
    failed = []

    with requests.Session() as session, open(
        out_path, "a", newline="", encoding="utf-8"
    ) as f:
        writer = csv.writer(f)
        if need_header:
            writer.writerow(COLUMNS)

        for game in games:
            appid = game["appid"]
            count = fetch_player_count(appid, session)

            if count is None:
                failed.append(f"{appid} ({game['name']})")
            else:
                writer.writerow([stamp, appid, count])
                success += 1

            time.sleep(SLEEP_SECONDS)

    print(f"{stamp}  ghi {success}/{len(games)} game vao {out_path}")
    if failed:
        print("That bai: " + ", ".join(failed))

    # Chi bao loi khi that bai qua nua. Vai game loi le te thi bo qua,
    # khong de no lam do ca lan chay.
    return 1 if success < len(games) / 2 else 0


if __name__ == "__main__":
    sys.exit(main())
