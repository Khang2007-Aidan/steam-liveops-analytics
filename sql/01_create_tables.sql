
-- Tao cau truc bang cho kho du lieu.
-- Chay mot lan duy nhat, hoac chay lai nhieu lan cung khong sao
-- vi deu co IF NOT EXISTS.

-- ---------------------------------------------------------------
-- BANG DIM
-- Grain: mot dong = mot game.
-- Bang dim tra loi cau hoi "no la cai gi", khong chua so do luong.
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_game (
    appid            integer PRIMARY KEY,
    name             text NOT NULL,
    is_free          boolean NOT NULL,
    app_type         text,
    release_date_raw text,        -- de dang text vi Steam tra ve kieu "9 Jul, 2013"
    developer        text,
    publisher        text,
    genres           text,
    price_vnd        bigint,
    available_vn     boolean,
    verified_at      timestamptz
);

-- ---------------------------------------------------------------
-- BANG FACT: luong nguoi choi
-- Grain: mot dong = mot lan do MOT game tai MOT thoi diem.
-- Khoa chinh gom ca hai cot do, nen chay lai script nap
-- cung khong tao ban sao.
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fact_player_count (
    collected_at timestamptz NOT NULL,
    appid        integer NOT NULL REFERENCES dim_game (appid),
    player_count integer NOT NULL,
    PRIMARY KEY (collected_at, appid)
);

-- ---------------------------------------------------------------
-- BANG FACT: gia
-- Grain: mot dong = gia cua MOT game tai MOT thoi diem.
-- country_code bat buoc phai co, vi 500000 dong va 39 do
-- khong the nam chung mot cot ma khong ghi ro don vi.
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fact_price (
    collected_at     timestamptz NOT NULL,
    appid            integer NOT NULL REFERENCES dim_game (appid),
    country_code     text NOT NULL,
    price_final      bigint,
    price_initial    bigint,
    discount_percent integer,
    PRIMARY KEY (collected_at, appid)
);

-- ---------------------------------------------------------------
-- BANG SU KIEN THO: tin tuc
-- Grain: mot dong = mot ban tin, nhan dien boi news_gid.
-- Steam tra ve lai tin cu moi ngay, nen news_gid lam khoa chinh
-- se tu dong loc trung.
-- Cot event_type de trong, sau nay tu gan nhan bang tay.
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS news_item (
    news_gid      text PRIMARY KEY,
    appid         integer NOT NULL REFERENCES dim_game (appid),
    published_at  timestamptz NOT NULL,
    feedlabel     text,
    title         text,
    url           text,
    snippet       text,
    first_seen_at timestamptz,
    event_type    text          -- NULL cho toi khi duoc gan nhan thu cong
);

-- Chi muc giup truy van theo game va theo thoi gian chay nhanh.
CREATE INDEX IF NOT EXISTS idx_player_appid_time
    ON fact_player_count (appid, collected_at);

CREATE INDEX IF NOT EXISTS idx_news_appid_published
    ON news_item (appid, published_at);
