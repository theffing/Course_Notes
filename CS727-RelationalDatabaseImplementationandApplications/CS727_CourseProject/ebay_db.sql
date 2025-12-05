-- eBay Mimic relational database setup for PostgreSQL
-- Run with: psql -d <database> -f ebay_db.sql

BEGIN;

-- Clean slate for repeatable runs
DROP TABLE IF EXISTS feedback, transaction, bid, user_listing_watch, listing, category, user_account CASCADE;

-- === Core tables ===
CREATE TABLE user_account (
    user_id         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        TEXT NOT NULL UNIQUE,
    email           TEXT NOT NULL UNIQUE,
    user_type       TEXT NOT NULL CHECK (user_type IN ('buyer','seller','both')),
    account_status  TEXT NOT NULL DEFAULT 'active' CHECK (account_status IN ('active','suspended','closed')),
    rating          NUMERIC(4,2) NOT NULL DEFAULT 0,
    created_date    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    payment_methods JSONB,
    address         TEXT,
    phone           TEXT
);

CREATE TABLE category (
    category_id    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           TEXT NOT NULL,
    parent_id      INT REFERENCES category(category_id),
    path           TEXT,
    item_specifics JSONB
);

CREATE TABLE listing (
    listing_id    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_id     INT NOT NULL REFERENCES user_account(user_id),
    category_id   INT NOT NULL REFERENCES category(category_id),
    title         TEXT NOT NULL,
    description   TEXT,
    auction_type  TEXT NOT NULL CHECK (auction_type IN ('auction','fixed','mixed')),
    start_price   NUMERIC(12,2) NOT NULL,
    reserve_price NUMERIC(12,2),
    buy_now_price NUMERIC(12,2),
    start_date    TIMESTAMPTZ NOT NULL,
    end_date      TIMESTAMPTZ NOT NULL,
    status        TEXT NOT NULL CHECK (status IN ('active','ended','cancelled','sold')),
    condition     TEXT,
    quantity      INT NOT NULL DEFAULT 1,
    view_count    INT NOT NULL DEFAULT 0
);

CREATE TABLE user_listing_watch (
    user_id    INT NOT NULL REFERENCES user_account(user_id),
    listing_id INT NOT NULL REFERENCES listing(listing_id),
    PRIMARY KEY (user_id, listing_id)
);

CREATE TABLE bid (
    bid_id     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    listing_id INT NOT NULL REFERENCES listing(listing_id),
    user_id    INT NOT NULL REFERENCES user_account(user_id),
    bid_amount NUMERIC(12,2) NOT NULL CHECK (bid_amount > 0),
    bid_time   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    bid_status TEXT NOT NULL DEFAULT 'active' CHECK (bid_status IN ('active','retracted','winning','outbid')),
    is_proxy   BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE transaction (
    transaction_id  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bid_id          INT NOT NULL UNIQUE REFERENCES bid(bid_id),
    listing_id      INT NOT NULL REFERENCES listing(listing_id),
    buyer_id        INT NOT NULL REFERENCES user_account(user_id),
    seller_id       INT NOT NULL REFERENCES user_account(user_id),
    final_price     NUMERIC(12,2) NOT NULL,
    payment_status  TEXT NOT NULL CHECK (payment_status IN ('pending','paid','refunded')),
    shipping_status TEXT NOT NULL CHECK (shipping_status IN ('pending','shipped','delivered','returned')),
    tracking_number TEXT UNIQUE,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE feedback (
    feedback_id     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id  INT NOT NULL REFERENCES transaction(transaction_id),
    author_user_id  INT NOT NULL REFERENCES user_account(user_id),
    target_user_id  INT NOT NULL REFERENCES user_account(user_id),
    rating          INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    feedback_type   TEXT NOT NULL CHECK (feedback_type IN ('positive','neutral','negative')),
    comment         TEXT,
    is_reciprocated BOOLEAN NOT NULL DEFAULT FALSE,
    feedback_date   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (transaction_id, author_user_id)
);

-- === Indexes ===
CREATE INDEX idx_listing_seller_status ON listing (seller_id, status);
CREATE INDEX idx_listing_category ON listing (category_id);
CREATE INDEX idx_bid_listing_amount ON bid (listing_id, bid_amount DESC);
CREATE INDEX idx_feedback_target ON feedback (target_user_id);
CREATE INDEX idx_watch_user ON user_listing_watch (user_id);

-- === Functions, triggers, and stored procedures ===
CREATE OR REPLACE FUNCTION fn_enforce_bid_rules()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    current_max NUMERIC(12,2);
    start_price NUMERIC(12,2);
    l_status    TEXT;
    l_end       TIMESTAMPTZ;
BEGIN
    SELECT COALESCE(MAX(bid_amount), 0) INTO current_max FROM bid WHERE listing_id = NEW.listing_id;
    SELECT start_price, status, end_date INTO start_price, l_status, l_end
    FROM listing WHERE listing_id = NEW.listing_id FOR UPDATE;

    IF l_status <> 'active' OR NOW() > l_end THEN
        RAISE EXCEPTION 'Listing not active or already ended';
    END IF;

    IF NEW.bid_amount < GREATEST(start_price, current_max + 1) THEN
        RAISE EXCEPTION 'Bid too low. Minimum acceptable: %', GREATEST(start_price, current_max + 1);
    END IF;
    RETURN NEW;
END$$;

CREATE TRIGGER tg_enforce_bid_rules
BEFORE INSERT ON bid
FOR EACH ROW EXECUTE FUNCTION fn_enforce_bid_rules();

CREATE OR REPLACE FUNCTION fn_update_rating_on_feedback()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    new_avg NUMERIC(4,2);
BEGIN
    SELECT AVG(rating)::NUMERIC(4,2) INTO new_avg
    FROM feedback WHERE target_user_id = NEW.target_user_id;
    UPDATE user_account SET rating = new_avg WHERE user_id = NEW.target_user_id;
    RETURN NEW;
END$$;

CREATE TRIGGER tg_update_rating_on_feedback
AFTER INSERT ON feedback
FOR EACH ROW EXECUTE FUNCTION fn_update_rating_on_feedback();

CREATE OR REPLACE PROCEDURE place_bid(p_user_id INT, p_listing_id INT, p_amount NUMERIC, p_is_proxy BOOLEAN DEFAULT FALSE)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO bid (listing_id, user_id, bid_amount, is_proxy)
    VALUES (p_listing_id, p_user_id, p_amount, p_is_proxy);
END$$;

CREATE OR REPLACE FUNCTION finalize_listing(p_listing_id INT)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
    winning_bid bid%ROWTYPE;
    txn_id      INT;
    listing_row listing%ROWTYPE;
BEGIN
    SELECT * INTO listing_row FROM listing WHERE listing_id = p_listing_id FOR UPDATE;
    IF listing_row.status <> 'active' THEN
        RAISE EXCEPTION 'Listing % is not active', p_listing_id;
    END IF;

    SELECT * INTO winning_bid
    FROM bid
    WHERE listing_id = p_listing_id
    ORDER BY bid_amount DESC, bid_time ASC
    LIMIT 1;

    IF winning_bid.bid_id IS NULL THEN
        UPDATE listing SET status = 'ended' WHERE listing_id = p_listing_id;
        RETURN NULL;
    END IF;

    INSERT INTO transaction (bid_id, listing_id, buyer_id, seller_id, final_price, payment_status, shipping_status, tracking_number)
    VALUES (winning_bid.bid_id, p_listing_id, winning_bid.user_id, listing_row.seller_id,
            winning_bid.bid_amount, 'pending', 'pending', CONCAT('AUTO', winning_bid.bid_id))
    RETURNING transaction_id INTO txn_id;

    UPDATE listing SET status = 'sold' WHERE listing_id = p_listing_id;
    RETURN txn_id;
END$$;

-- === Seed data (15+ rows per table) ===
INSERT INTO user_account (username, email, user_type, account_status, rating, payment_methods, address, phone) VALUES
 ('alice','alice@example.com','both','active',4.8,'["visa"]','1 Main St','111-111-1111'),
 ('bob','bob@example.com','buyer','active',4.5,'["paypal"]','2 Main St','222-222-2222'),
 ('carol','carol@example.com','seller','active',4.9,'["visa","amex"]','3 Main St','333-333-3333'),
 ('dave','dave@example.com','both','active',4.2,'["mastercard"]','4 Main St','444-444-4444'),
 ('erin','erin@example.com','buyer','active',4.0,'["paypal"]','5 Main St','555-555-5555'),
 ('frank','frank@example.com','seller','active',4.7,'["visa"]','6 Main St','666-666-6666'),
 ('grace','grace@example.com','both','active',4.6,'["paypal","amex"]','7 Main St','777-777-7777'),
 ('heidi','heidi@example.com','buyer','active',4.3,'["visa"]','8 Main St','888-888-8888'),
 ('ivan','ivan@example.com','seller','active',4.1,'["paypal"]','9 Main St','999-999-9999'),
 ('judy','judy@example.com','both','active',4.4,'["visa"]','10 Main St','000-000-0000'),
 ('kate','kate@example.com','buyer','active',3.9,'["paypal"]','11 Main St','101-010-1010'),
 ('leo','leo@example.com','seller','active',4.0,'["visa"]','12 Main St','202-020-2020'),
 ('mike','mike@example.com','both','active',3.8,'["mastercard"]','13 Main St','303-030-3030'),
 ('nina','nina@example.com','buyer','active',4.7,'["amex"]','14 Main St','404-040-4040'),
 ('oliver','oliver@example.com','seller','active',4.5,'["paypal"]','15 Main St','505-050-5050');

INSERT INTO category (name, parent_id, path, item_specifics) VALUES
 ('Electronics', NULL, 'Electronics', '{"warranty":"boolean"}'),
 ('Phones', 1, 'Electronics/Phones', '{"carrier":"text"}'),
 ('Laptops', 1, 'Electronics/Laptops', '{"ram":"text"}'),
 ('Cameras', 1, 'Electronics/Cameras', '{"megapixels":"int"}'),
 ('Fashion', NULL, 'Fashion', '{"size":"text"}'),
 ('Shoes', 5, 'Fashion/Shoes', '{"size":"text"}'),
 ('Men Clothing', 5, 'Fashion/Men', '{"size":"text"}'),
 ('Women Clothing', 5, 'Fashion/Women', '{"size":"text"}'),
 ('Home', NULL, 'Home', '{"material":"text"}'),
 ('Furniture', 9, 'Home/Furniture', '{"material":"text"}'),
 ('Books', NULL, 'Books', '{"author":"text"}'),
 ('Sports', NULL, 'Sports', '{"brand":"text"}'),
 ('Outdoors', 12, 'Sports/Outdoors', '{"weatherproof":"boolean"}'),
 ('Toys', NULL, 'Toys', '{"age_range":"text"}'),
 ('Collectibles', NULL, 'Collectibles', '{"year":"int"}');

INSERT INTO listing (seller_id, category_id, title, description, auction_type, start_price, reserve_price, buy_now_price, start_date, end_date, status, condition, quantity, view_count) VALUES
 (3,2,'iPhone 13','Good condition','auction',300,350,500, NOW()-INTERVAL '2 day', NOW()+INTERVAL '5 day','active','used',1,12),
 (6,3,'Gaming Laptop','RTX 3060','auction',800,900,1200,NOW()-INTERVAL '1 day',NOW()+INTERVAL '4 day','active','used',1,25),
 (9,4,'DSLR Camera','24MP','auction',400,450,650,NOW()-INTERVAL '3 day',NOW()+INTERVAL '2 day','active','used',1,18),
 (12,6,'Running Shoes','Size 10','auction',50,NULL,90,NOW()-INTERVAL '1 day',NOW()+INTERVAL '6 day','active','new',2,9),
 (15,10,'Coffee Table','Wood','auction',70,80,150,NOW()-INTERVAL '4 day',NOW()+INTERVAL '1 day','active','used',1,6),
 (3,11,'Sci-fi Book Set','Hardcover','auction',30,NULL,60,NOW()-INTERVAL '2 day',NOW()+INTERVAL '3 day','active','new',1,4),
 (6,7,'Men Jacket','Leather','auction',120,150,220,NOW()-INTERVAL '1 day',NOW()+INTERVAL '5 day','active','new',1,7),
 (9,8,'Women Dress','Evening gown','auction',90,110,200,NOW()-INTERVAL '1 day',NOW()+INTERVAL '5 day','active','new',1,11),
 (12,5,'Sneakers Bulk','Sizes mix','auction',200,250,400,NOW()-INTERVAL '2 day',NOW()+INTERVAL '4 day','active','new',5,10),
 (15,9,'Sofa','Sectional','auction',500,600,900,NOW()-INTERVAL '3 day',NOW()+INTERVAL '7 day','active','used',1,5),
 (3,12,'Tennis Racket','Pro','auction',80,90,140,NOW()-INTERVAL '2 day',NOW()+INTERVAL '6 day','active','new',3,13),
 (6,13,'Camping Tent','4-person','auction',150,170,260,NOW()-INTERVAL '1 day',NOW()+INTERVAL '8 day','active','new',2,16),
 (9,14,'Lego Set','Collector','auction',200,220,350,NOW()-INTERVAL '1 day',NOW()+INTERVAL '6 day','active','new',1,21),
 (12,15,'Vintage Coin','Rare','auction',300,320,500,NOW()-INTERVAL '3 day',NOW()+INTERVAL '5 day','active','used',1,19),
 (15,1,'Bluetooth Speaker','Waterproof','auction',40,NULL,80,NOW()-INTERVAL '1 day',NOW()+INTERVAL '4 day','active','new',4,14);

INSERT INTO user_listing_watch (user_id, listing_id) VALUES
 (1,1),(2,1),(4,2),(5,2),(7,3),(8,3),(10,4),(11,4),(13,5),(14,5),
 (2,6),(4,7),(5,8),(7,9),(9,10);

INSERT INTO bid (listing_id, user_id, bid_amount, bid_time, bid_status, is_proxy) VALUES
 (1,2,320,NOW()-INTERVAL '1 day','outbid',false),
 (1,4,360,NOW()-INTERVAL '12 hour','winning',true),
 (2,1,820,NOW()-INTERVAL '8 hour','outbid',false),
 (2,5,880,NOW()-INTERVAL '2 hour','winning',false),
 (3,7,420,NOW()-INTERVAL '1 day','winning',false),
 (4,8,60,NOW()-INTERVAL '5 hour','winning',false),
 (5,13,75,NOW()-INTERVAL '10 hour','winning',false),
 (6,2,35,NOW()-INTERVAL '1 day','outbid',false),
 (6,4,40,NOW()-INTERVAL '3 hour','winning',false),
 (7,5,130,NOW()-INTERVAL '4 hour','outbid',false),
 (7,1,155,NOW()-INTERVAL '1 hour','winning',false),
 (8,11,95,NOW()-INTERVAL '6 hour','winning',false),
 (9,14,260,NOW()-INTERVAL '5 hour','winning',false),
 (10,2,510,NOW()-INTERVAL '7 hour','winning',false),
 (11,7,85,NOW()-INTERVAL '3 hour','winning',false);

INSERT INTO transaction (bid_id, listing_id, buyer_id, seller_id, final_price, payment_status, shipping_status, tracking_number, transaction_date) VALUES
 (2,1,4,3,360,'paid','shipped','TRK001',NOW()-INTERVAL '6 hour'),
 (4,2,5,6,880,'paid','pending','TRK002',NOW()-INTERVAL '1 hour'),
 (5,3,7,9,420,'pending','pending','TRK003',NOW()-INTERVAL '2 hour'),
 (6,4,8,12,60,'paid','delivered','TRK004',NOW()-INTERVAL '1 day'),
 (7,5,13,15,75,'paid','pending','TRK005',NOW()-INTERVAL '3 hour'),
 (9,6,4,3,40,'paid','shipped','TRK006',NOW()-INTERVAL '5 hour'),
 (11,7,1,6,155,'paid','pending','TRK007',NOW()-INTERVAL '30 min'),
 (12,8,11,9,95,'paid','pending','TRK008',NOW()-INTERVAL '2 hour'),
 (13,9,14,12,260,'pending','pending','TRK009',NOW()-INTERVAL '4 hour'),
 (14,10,2,15,510,'paid','shipped','TRK010',NOW()-INTERVAL '1 day'),
 (15,11,7,3,85,'paid','pending','TRK011',NOW()-INTERVAL '20 min'),
 (1,1,2,3,320,'refunded','returned','TRK012',NOW()-INTERVAL '2 day'),
 (3,2,1,6,820,'refunded','returned','TRK013',NOW()-INTERVAL '1 day'),
 (8,6,2,3,35,'refunded','returned','TRK014',NOW()-INTERVAL '3 day'),
 (10,7,5,6,130,'refunded','returned','TRK015',NOW()-INTERVAL '3 day');

INSERT INTO feedback (transaction_id, author_user_id, target_user_id, rating, feedback_type, comment, is_reciprocated, feedback_date) VALUES
 (1,4,3,5,'positive','Great seller',true,NOW()-INTERVAL '5 hour'),
 (2,5,6,4,'positive','Smooth buy',false,NOW()-INTERVAL '50 min'),
 (3,7,9,5,'positive','As described',false,NOW()-INTERVAL '90 min'),
 (4,8,12,4,'positive','Fast ship',false,NOW()-INTERVAL '20 hour'),
 (5,13,15,5,'positive','Excellent',false,NOW()-INTERVAL '2 hour'),
 (6,4,3,4,'positive','All good',false,NOW()-INTERVAL '4 hour'),
 (7,1,6,5,'positive','Great jacket',false,NOW()-INTERVAL '10 min'),
 (8,11,9,4,'positive','Nice dress',false,NOW()-INTERVAL '90 min'),
 (9,14,12,4,'positive','Accurate',false,NOW()-INTERVAL '3 hour'),
 (10,2,15,5,'positive','Love the sofa',false,NOW()-INTERVAL '15 hour'),
 (11,7,3,4,'positive','Racket solid',false,NOW()-INTERVAL '5 min'),
 (12,2,3,3,'neutral','Refunded ok',false,NOW()-INTERVAL '1 day'),
 (13,1,6,3,'neutral','Refunded',false,NOW()-INTERVAL '18 hour'),
 (14,2,3,2,'negative','Returned item',false,NOW()-INTERVAL '2 day'),
 (15,5,6,2,'negative','Returned',false,NOW()-INTERVAL '2 day');

-- === Views and temp table example ===
CREATE OR REPLACE VIEW v_listing_current_price AS
SELECT l.listing_id, l.title, l.status, l.end_date,
       COALESCE(MAX(b.bid_amount), l.start_price) AS current_price,
       COUNT(w.user_id) AS watcher_count
FROM listing l
LEFT JOIN bid b ON b.listing_id = l.listing_id
LEFT JOIN user_listing_watch w ON w.listing_id = l.listing_id
GROUP BY l.listing_id;

CREATE OR REPLACE VIEW v_user_feedback_summary AS
SELECT target_user_id AS user_id,
       COUNT(*) AS total_feedback,
       AVG(rating)::NUMERIC(4,2) AS avg_rating,
       SUM(CASE WHEN feedback_type='positive' THEN 1 ELSE 0 END) AS positives
FROM feedback
GROUP BY target_user_id;

-- Session-scoped helper table
CREATE TEMP TABLE tmp_top_categories ON COMMIT DROP AS
SELECT c.category_id, c.name, COUNT(l.listing_id) AS listing_count
FROM category c
LEFT JOIN listing l ON l.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY listing_count DESC
LIMIT 5;

-- === Example queries to inspect results ===
SELECT * FROM v_listing_current_price ORDER BY listing_id LIMIT 5;
SELECT * FROM v_user_feedback_summary ORDER BY user_id;
SELECT * FROM tmp_top_categories;

COMMIT;


