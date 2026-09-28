"""
Nap toan bo file CSV trong data/ vao PostgreSQL.

Chay lai bao nhieu lan cung duoc, khong tao ban sao, nho ON CONFLICT DO NOTHING.
Moi tuan co them du lieu thi chay lai la xong.

Cach chay (PowerShell):
    $env:PGPASSWORD = "mat_khau_cua_ban"
    python scripts/load_to_postgres.py

KHONG bao gio viet mat khau thang vao file nay. Repo nay cong khai.
"""

import csv
import os
import sys
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_batch

DATA_DIR = Path("data")

# Doc cau hinh tu bien moi truong. Mat khau khong co gia tri mac dinh.
DB_CONFIG = {
    "host": os.environ.get("PGHOST", "localhost"),
    "port": os.environ.get("PGPORT", "5432"),
    "dbname": os.environ.get("PGDATABASE", "steam_liveops"),
    "user": os.environ.get("PGUSER", "postgres"),
    "password": os.environ.get("PGPASSWORD"),
}


def to_bool(value):
    """CSV luu 'True'/'False' dang chu. Doi ve kieu boolean that."""
    return str(value).strip().lower() == "true"


def to_int(value, default=0):
    """Doi sang so nguyen, o trong thi tra ve gia tri mac dinh."""
    text = str(value).strip()
    if not text:
        return default
    try:
        return int(float(text))
    except ValueError:
        return default


def read_csv(path):
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def load_dim_game(cursor):
    """Nap bang dim. Game da co thi cap nhat lai thong tin moi nhat."""
    path = DATA_DIR / "dim_game.csv"
    rows = read_csv(path)

    records = [
        (
            to_int(r["appid"]),
            r["name"],
            to_bool(r["is_free"]),
            r.get("type") or None,
            r.get("release_date") or None,
            r.get("developer") or None,
            r.get("publisher") or None,
            r.get("genres") or None,
            to_int(r.get("price_vnd", 0)),
            to_bool(r.get("available_vn", "True")),
            r.get("verified_at_utc") or None,
        )
        for r in rows
    ]

    # ON CONFLICT ... DO UPDATE: game cu thi ghi de bang thong tin moi.
    # Dung cho bang dim vi ten hay gia co the doi.
    execute_batch(
        cursor,
        """
        INSERT INTO dim_game (
            appid, name, is_free, app_type, release_date_raw,
            developer, publisher, genres, price_vnd, available_vn, verified_at
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (appid) DO UPDATE SET
            name             = EXCLUDED.name,
            is_free          = EXCLUDED.is_free,
            app_type         = EXCLUDED.app_type,
            release_date_raw = EXCLUDED.release_date_raw,
            developer        = EXCLUDED.developer,
            publisher        = EXCLUDED.publisher,
            genres           = EXCLUDED.genres,
            price_vnd        = EXCLUDED.price_vnd,
            available_vn     = EXCLUDED.available_vn,
            verified_at      = EXCLUDED.verified_at
        """,
        records,
    )
    return len(records)


def load_players(cursor):
    """Nap tat ca file trong data/players/."""
    records = []
    for path in sorted((DATA_DIR / "players").glob("*.csv")):
        for r in read_csv(path):
            records.append(
                (r["collected_at_utc"], to_int(r["appid"]), to_int(r["player_count"]))
            )

    # DO NOTHING: bang fact la du lieu do duoc, da ghi roi thi khong sua.
    execute_batch(
        cursor,
        """
        INSERT INTO fact_player_count (collected_at, appid, player_count)
        VALUES (%s, %s, %s)
        ON CONFLICT (collected_at, appid) DO NOTHING
        """,
        records,
    )
    return len(records)


def load_prices(cursor):
    records = []
    for path in sorted((DATA_DIR / "prices").glob("*.csv")):
        for r in read_csv(path):
            records.append(
                (
                    r["collected_at_utc"],
                    to_int(r["appid"]),
                    r["country_code"],
                    to_int(r["price_final"]),
                    to_int(r["price_initial"]),
                    to_int(r["discount_percent"]),
                )
            )

    execute_batch(
        cursor,
        """
        INSERT INTO fact_price (
            collected_at, appid, country_code,
            price_final, price_initial, discount_percent
        )
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT (collected_at, appid) DO NOTHING
        """,
        records,
    )
    return len(records)


def load_news(cursor):
    """
    Nap tin tuc. Steam tra ve lai tin cu moi ngay nen o day rat nhieu ban trung.
    news_gid la khoa chinh, ON CONFLICT DO NOTHING se tu loc.
    """
    records = []
    for path in sorted((DATA_DIR / "news").glob("*.csv")):
        for r in read_csv(path):
            if not r.get("news_gid"):
                continue
            records.append(
                (
                    r["news_gid"],
                    to_int(r["appid"]),
                    r["published_at_utc"],
                    r.get("feedlabel") or None,
                    r.get("title") or None,
                    r.get("url") or None,
                    r.get("snippet") or None,
                    r["collected_at_utc"],
                )
            )

    execute_batch(
        cursor,
        """
        INSERT INTO news_item (
            news_gid, appid, published_at, feedlabel,
            title, url, snippet, first_seen_at
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (news_gid) DO NOTHING
        """,
        records,
    )
    return len(records)


def count_rows(cursor, table):
    cursor.execute(f"SELECT COUNT(*) FROM {table}")
    return cursor.fetchone()[0]


def main():
    if not DB_CONFIG["password"]:
        print("Chua co mat khau. Chay lenh nay truoc:")
        print('    $env:PGPASSWORD = "mat_khau_cua_ban"')
        return 1

    if not (DATA_DIR / "dim_game.csv").exists():
        print("Khong thay data/dim_game.csv. Chay script nay tu thu muc goc cua repo.")
        return 1

    with psycopg2.connect(**DB_CONFIG) as conn:
        with conn.cursor() as cur:
            read_dim = load_dim_game(cur)
            read_players = load_players(cur)
            read_prices = load_prices(cur)
            read_news = load_news(cur)

            print("Da doc tu file CSV:")
            print(f"  dim_game : {read_dim} dong")
            print(f"  players  : {read_players} dong")
            print(f"  prices   : {read_prices} dong")
            print(f"  news     : {read_news} dong (chua loc trung)")

            print("\nDang co trong database:")
            for table in (
                "dim_game",
                "fact_player_count",
                "fact_price",
                "news_item",
            ):
                print(f"  {table:18} {count_rows(cur, table)} dong")

            # So news trong DB it hon so doc tu file la binh thuong,
            # dung bang so tin DUY NHAT sau khi loc trung theo news_gid.
        conn.commit()

    return 0


if __name__ == "__main__":
    sys.exit(main())
