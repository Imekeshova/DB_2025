--TASK 1
CREATE TABLE restaurant_tables (
    table_id INTEGER PRIMARY KEY,
    table_number INTEGER NOT NULL UNIQUE,
    seating_capacity INTEGER NOT NULL CHECK (seating_capacity BETWEEN 2 AND 12),
    location TEXT NOT NULL CHECK (location IN ('indoor', 'outdoor', 'patio', 'private')),
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT
);

INSERT INTO restaurant_tables VALUES
(1, 101, 4, 'indoor', TRUE, 'near window'),
(2, 102, 6, 'outdoor', TRUE, 'corner table'),
(3, 103, 8, 'patio', FALSE, 'reserved'),
(4, 104, 12, 'private', TRUE, NULL);

-- INSERT INTO restaurant_tables VALUES (5, 105, 15, 'indoor', TRUE, NULL);
-- INSERT INTO restaurant_tables VALUES (6, 106, 6, 'rooftop', TRUE, NULL);
-- INSERT INTO restaurant_tables VALUES (7, 101, 6, 'indoor', TRUE, NULL);




--TASK 2
CREATE TABLE menu_items (
    item_id INTEGER PRIMARY KEY,
    item_name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('starter','main','dessert','drink')),
    price NUMERIC(10,2) NOT NULL CHECK (price > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    allergens TEXT
);

INSERT INTO menu_items VALUES
(1, 'Caesar Salad', 'starter', 3200, TRUE, 'dairy'),
(2, 'Steak Ribeye', 'main',    12500, TRUE, NULL),
(3, 'Tiramisu',     'dessert', 4500,  TRUE, 'eggs,dairy'),
(4, 'Latte',        'drink',   1800,  TRUE, 'dairy');




-- INSERT INTO menu_items VALUES (5, 'Soup', 'soup', 2500, TRUE, NULL);

-- INSERT INTO menu_items VALUES (6, 'Water', 'drink', 0, TRUE, NULL);

-- TaASK 3 Customers
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    phone TEXT,
    email TEXT UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO customers (customer_id, full_name, phone, email) VALUES
(1, 'Anna Adams',  '+7-777-111-22-33', 'anna@example.com'),
(2, 'Brian Brooks', NULL,              'brian@example.com'),
(3, 'Celia Cruz',  '+7-705-000-00-00', NULL);

-- INSERT INTO customers VALUES (4, 'Dup', NULL, 'anna@example.com', NOW());

-- INSERT INTO customers (customer_id, full_name) VALUES (5, NULL);'


--TASK 4
DROP TABLE IF EXISTS orders CASCADE;
CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    item_id      INTEGER NOT NULL REFERENCES menu_items(item_id) ON DELETE RESTRICT,
    quantity     INTEGER NOT NULL CHECK (quantity BETWEEN 1 AND 20),
    order_date   TIMESTAMP NOT NULL DEFAULT NOW(),
    tip          NUMERIC not null CHECK( tip >= 0),
    total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0)
);
INSERT INTO orders (order_id, customer_id, item_id, quantity, total_amount) VALUES
(1, 1, 1, 2, 6400),
(2, 2, 2, 1, 12500),
(3, 3, 4, 3, 5400);


-- INSERT INTO orders VALUES (4, 1, 1, 0, NOW(), 0);
-- INSERT INTO orders VALUES (5, 1, 1, 2, NOW(), -200);
-- INSERT INTO orders VALUES (6, 99, 1, 1, NOW(), 3200);









