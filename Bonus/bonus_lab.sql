---====---
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;

-- TASK 1: SCHEMA (DDL)
CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE NOT NULL CHECK (LENGTH(iin) = 12 AND iin ~ '^\d{12}$'),
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(16),
    email VARCHAR(120),
    status VARCHAR(20) NOT NULL CHECK (status IN('active','blocked','frozen')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt NUMERIC(18,2) NOT NULL DEFAULT 1000000.00
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    account_number VARCHAR(34) UNIQUE NOT NULL CHECK (account_number ~ '^KZ\d{18}$'),
    currency VARCHAR(3) NOT NULL CHECK (currency IN('KZT','USD','EUR','RUB')),
    balance NUMERIC(18,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency   VARCHAR(3) NOT NULL,
    rate NUMERIC(18,6) NOT NULL CHECK (rate > 0),
    valid_from TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id   INT REFERENCES accounts(account_id),
    amount NUMERIC(18,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    exchange_rate NUMERIC(18,6),
    amount_kzt NUMERIC(18,2),
    type VARCHAR(20) NOT NULL CHECK (type IN('transfer','deposit','withdrawal','salary_batch','salary')),
    status VARCHAR(20) NOT NULL CHECK (status IN('pending','completed','failed','reversed')),
    parent_transaction_id INT REFERENCES transactions(transaction_id) ON DELETE SET NULL,
    new_values JSONB DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    description TEXT
);

CREATE TABLE IF NOT EXISTS audit_logs (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id INT,
    action VARCHAR(50) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by TEXT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

-- =============================
INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('123458789012','Monkey D. Luffy','+7-701-1234567','luffy@onepiece.com','active',500000),
('234567990123','Roronoa Zoro','+7-701-2345678','zoro@onepiece.com','active',300000),
('345670901234','Nami','+7-701-3456789','nami@onepiece.com','blocked',200000),
('456789012345','Usopp','+7-701-4567890','usopp@onepiece.com','frozen',150000),
('567890123456','Sanji','+7-701-5678901','sanji@onepiece.com','active',400000),
('678901234567','Chopper','+7-701-6789012','chopper@onepiece.com','active',350000),
('70012345678','Nico Robin','+7-701-7890123','robin@onepiece.com','active',600000),
('894123456789','Franky','+7-701-8901234','franky@onepiece.com','blocked',250000),
('901234667890','Brook','+7-701-9012345','brook@onepiece.com','active',500000),
('012345578901','Jinbe','+7-701-0123456','jinbe@onepiece.com','frozen',450000);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active) VALUES
(1,'KZ123456789012345678','KZT',100000,TRUE),
(2,'KZ123456789012345679','USD',5000,TRUE),
(3,'KZ123456789012345680','EUR',3000,FALSE),
(4,'KZ123456789012345681','RUB',100000,FALSE),
(5,'KZ123456789012345682','KZT',200000,TRUE),
(6,'KZ123456789012345683','KZT',150000,TRUE),
(7,'KZ123456789012345684','USD',7000,TRUE),
(8,'KZ123456789012345685','EUR',10000,FALSE),
(9,'KZ123456789012345686','RUB',300000,TRUE),
(10,'KZ123456789012345687','KZT',250000,TRUE);

INSERT INTO exchange_rates (from_currency,to_currency,rate,valid_from,valid_to) VALUES
('USD','KZT',400,'2025-01-01'::timestamptz,'2025-12-31'::timestamptz),
('EUR','KZT',450,'2025-01-01'::timestamptz,'2025-12-31'::timestamptz),
('RUB','KZT',5.5,'2025-01-01'::timestamptz,'2025-12-31'::timestamptz),
('KZT','USD',0.0025,'2025-01-01'::timestamptz,'2025-12-31'::timestamptz),
('USD','EUR',0.9,'2025-01-01'::timestamptz,'2025-12-31'::timestamptz),
('EUR','USD',1.1,'2025-01-01'::timestamptz,'2025-12-31'::timestamptz),
('USD','RUB',70,'2025-01-01'::timestamptz,'2025-12-31'::timestamptz),
('RUB','USD',0.013,'2025-01-01'::timestamptz,'2025-12-31'::timestamptz);

INSERT INTO transactions (from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,description,created_at,completed_at) VALUES
(1,2,1000,'KZT',1,1000,'transfer','completed','Payment A',now()-interval '7 days', now()-interval '7 days'),
(2,4,100,'USD',400,40000,'transfer','completed','Payment B',now()-interval '6 days', now()-interval '6 days'),
(5,6,2000,'KZT',1,2000,'deposit','completed','Salary',now()-interval '5 days', now()-interval '5 days'),
(7,8,3000,'USD',400,1200000,'transfer','failed','To blocked',now()-interval '4 days', NULL),
(9,10,1500,'RUB',5.5,8250,'withdrawal','reversed','Reverse',now()-interval '3 days', now()-interval '3 days'),
(6,1,500,'KZT',1,500,'transfer','completed','To Luffy',now()-interval '2 days', now()-interval '2 days'),
(2,5,700,'USD',400,280000,'deposit','completed','Topup',now()-interval '1 day', now()-interval '1 day'),
(10,4,1000,'KZT',1,1000,'withdrawal','completed','ATM',now()-interval '12 hours', now()-interval '12 hours'),
(8,7,2000,'EUR',450,900000,'transfer','completed','Services',now()-interval '6 hours', now()-interval '6 hours'),
(4,9,400,'RUB',5.5,2200,'transfer','pending','Friend',now()-interval '1 hour', NULL);

INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, changed_by, changed_at, ip_address) VALUES
('customers',1,'UPDATE','{"status":"active"}','{"status":"blocked"}','admin',now()-interval '10 days','192.168.0.1'),
('accounts',2,'INSERT',NULL,'{"balance":5000}','admin',now()-interval '9 days','192.168.0.2');

-- TASK 3: UTILITIES (helper functions)

CREATE OR REPLACE FUNCTION get_rate(p_from VARCHAR, p_to VARCHAR)
RETURNS NUMERIC AS $$
DECLARE r NUMERIC;
BEGIN
  SELECT rate INTO r FROM exchange_rates
   WHERE from_currency = p_from AND to_currency = p_to
     AND valid_from <= now() AND (valid_to IS NULL OR valid_to > now())
   ORDER BY valid_from DESC LIMIT 1;
  IF r IS NULL THEN RAISE EXCEPTION 'RATE_NOT_FOUND: %->%', p_from, p_to; END IF;
  RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION to_kzt(p_amount NUMERIC, p_currency VARCHAR)
RETURNS NUMERIC AS $$
BEGIN
  IF p_currency = 'KZT' THEN RETURN round(p_amount,2); END IF;
  RETURN round(p_amount * get_rate(p_currency,'KZT'),2);
END;
$$ LANGUAGE plpgsql;


-- TASK 4: process_transfer (transactional, ACID, SELECT FOR UPDATE, SAVEPOINT, audit)

CREATE OR REPLACE FUNCTION process_transfer(
  p_from_acc_num TEXT,
  p_to_acc_num   TEXT,
  p_amount       NUMERIC,
  p_currency     VARCHAR,
  p_description  TEXT,
  p_performed_by TEXT DEFAULT 'system',
  p_ip           INET DEFAULT '127.0.0.1'
) RETURNS JSON AS $$
DECLARE
  v_from RECORD;
  v_to   RECORD;
  v_customer RECORD;
  v_amount_kzt NUMERIC;
  v_rate_cross NUMERIC := 1;
  v_tx_id INT;
  v_old JSONB;
  v_new JSONB;
BEGIN
  IF p_amount <= 0 THEN RETURN json_build_object('success',false,'code','E001','message','Amount must be > 0'); END IF;

  -- audit attempt
  INSERT INTO audit_logs(table_name,action,new_values,changed_by,changed_at,ip_address)
  VALUES('transactions','ATTEMPT',jsonb_build_object('from',p_from_acc_num,'to',p_to_acc_num,'amount',p_amount,'currency',p_currency,'desc',p_description),p_performed_by,now(),p_ip);

  -- lock rows
  SELECT * INTO v_from FROM accounts WHERE account_number = p_from_acc_num FOR UPDATE;
  IF NOT FOUND THEN RETURN json_build_object('success',false,'code','E002','message','Source account not found'); END IF;

  SELECT * INTO v_to FROM accounts WHERE account_number = p_to_acc_num FOR UPDATE;
  IF NOT FOUND THEN RETURN json_build_object('success',false,'code','E003','message','Destination account not found'); END IF;

  IF NOT v_from.is_active THEN RETURN json_build_object('success',false,'code','E004','message','Source inactive'); END IF;
  IF NOT v_to.is_active THEN RETURN json_build_object('success',false,'code','E005','message','Destination inactive'); END IF;

  SELECT status,daily_limit_kzt INTO v_customer FROM customers WHERE customer_id = v_from.customer_id;
  IF v_customer.status <> 'active' THEN RETURN json_build_object('success',false,'code','E006','message','Customer status not active'); END IF;

  -- compute KZT equivalent for limit checks
  v_amount_kzt := to_kzt(p_amount, p_currency);

  -- check daily limit
  IF (SELECT COALESCE(SUM(amount_kzt),0) FROM transactions WHERE from_account_id = v_from.account_id AND status='completed' AND type='transfer' AND created_at::date = now()::date) + v_amount_kzt > v_customer.daily_limit_kzt THEN
    RETURN json_build_object('success',false,'code','E007','message','Daily limit exceeded');
  END IF;

  -- compute cross rate for credit side
  IF v_from.currency <> v_to.currency THEN
    v_rate_cross := get_rate(v_from.currency, v_to.currency);
  ELSE
    v_rate_cross := 1;
  END IF;

  -- insert pending transaction + savepoint
  BEGIN
    SAVEPOINT sp_transfer;

    INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,description)
    VALUES (v_from.account_id, v_to.account_id, p_amount, p_currency, v_rate_cross, v_amount_kzt, 'transfer', 'pending', p_description)
    RETURNING transaction_id INTO v_tx_id;

    -- check balance (sender's balance expressed in sender currency)
    IF v_from.balance < p_amount THEN
      ROLLBACK TO SAVEPOINT sp_transfer;
      UPDATE transactions SET status='failed', completed_at=now() WHERE transaction_id = v_tx_id;
      INSERT INTO audit_logs(table_name,record_id,action,new_values,changed_by,changed_at,ip_address)
        VALUES('transactions',v_tx_id,'FAILED',jsonb_build_object('error','Insufficient funds'),p_performed_by,now(),p_ip);
      RETURN json_build_object('success',false,'code','E008','message','Insufficient funds');
    END IF;

    -- debit sender
    v_old := (SELECT to_jsonb(row(account_id,balance)) FROM accounts WHERE account_id = v_from.account_id);
    UPDATE accounts SET balance = round(balance - p_amount,2) WHERE account_id = v_from.account_id;
    v_new := (SELECT to_jsonb(row(account_id,balance)) FROM accounts WHERE account_id = v_from.account_id);
    INSERT INTO audit_logs(table_name,record_id,action,old_values,new_values,changed_by,changed_at,ip_address)
      VALUES('accounts',v_from.account_id,'DEBIT',v_old,v_new,p_performed_by,now(),p_ip);

    -- credit receiver (convert amounts if needed)
    v_old := (SELECT to_jsonb(row(account_id,balance)) FROM accounts WHERE account_id = v_to.account_id);
    UPDATE accounts SET balance = round(balance + (p_amount * v_rate_cross),2) WHERE account_id = v_to.account_id;
    v_new := (SELECT to_jsonb(row(account_id,balance)) FROM accounts WHERE account_id = v_to.account_id);
    INSERT INTO audit_logs(table_name,record_id,action,old_values,new_values,changed_by,changed_at,ip_address)
      VALUES('accounts',v_to.account_id,'CREDIT',v_old,v_new,p_performed_by,now(),p_ip);

    -- finalize transaction
    UPDATE transactions SET status='completed', completed_at=now() WHERE transaction_id = v_tx_id;
    v_new := (SELECT row_to_json(t) FROM transactions t WHERE transaction_id = v_tx_id);
    INSERT INTO audit_logs(table_name,record_id,action,new_values,changed_by,changed_at,ip_address)
      VALUES('transactions',v_tx_id,'COMPLETED',v_new,p_performed_by,now(),p_ip);

    RETURN json_build_object('success',true,'code','OK','message','Transfer completed','transaction_id',v_tx_id);
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT sp_transfer;
    IF v_tx_id IS NOT NULL THEN
      UPDATE transactions SET status='failed', completed_at=now(), new_values = jsonb_build_object('error',SQLERRM) WHERE transaction_id = v_tx_id;
      INSERT INTO audit_logs(table_name,record_id,action,new_values,changed_by,changed_at,ip_address)
        VALUES('transactions',v_tx_id,'FAILED_EXCEPTION',jsonb_build_object('error',SQLERRM),p_performed_by,now(),p_ip);
    END IF;
    RETURN json_build_object('success',false,'code','E999','message',SQLERRM);
  END;
END;
$$ LANGUAGE plpgsql;

-- =============================
-- TASK 5: process_salary_batch (advisory lock, SAVEPOINT per payment, continue-on-error)

CREATE OR REPLACE FUNCTION process_salary_batch(
  p_company_account_num TEXT,
  p_payments JSONB,         -- array of objects { "iin":"...", "amount":123.45, "description":"..." }
  p_performed_by TEXT DEFAULT 'payroll',
  p_ip INET DEFAULT '127.0.0.1'
) RETURNS JSONB AS $$
DECLARE
  v_company RECORD;
  v_lock_key BIGINT;
  v_total_kzt NUMERIC := 0;
  v_elem JSONB;
  v_idx INT := 0;
  v_failed JSONB := '[]'::jsonb;
  v_success INT := 0;
  v_batch_tx INT;
  v_rate NUMERIC;
  v_amount_kzt NUMERIC;
  v_child_tx INT;
  v_rec_account RECORD;
BEGIN
  -- acquire company account row locck
  SELECT * INTO v_company FROM accounts WHERE account_number = p_company_account_num FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false,'message','Company account not found'); END IF;

  -- advisory lock per company string
  v_lock_key := abs(hashtext(p_company_account_num))::bigint;
  PERFORM pg_advisory_xact_lock(v_lock_key);

  -- compute total required in KZT
  FOR v_elem IN SELECT * FROM jsonb_array_elements(p_payments)
  LOOP
    v_total_kzt := v_total_kzt + to_kzt((v_elem->>'amount')::numeric, (v_elem->>'currency')::text);
  END LOOP;

  -- check company funds (convert company balance to KZT)
  IF to_kzt(v_company.balance, v_company.currency) < v_total_kzt THEN
    RETURN jsonb_build_object('success',false,'message','Insufficient company funds','required_kzt',v_total_kzt,'available_kzt',to_kzt(v_company.balance,v_company.currency));
  END IF;

  -- insert parent batch transaction
  INSERT INTO transactions(from_account_id, amount, currency, amount_kzt, type, status, description)
  VALUES (v_company.account_id, v_total_kzt / COALESCE(NULLIF(get_rate(v_company.currency,'KZT'),NULL),1), v_company.currency, v_total_kzt, 'salary_batch', 'pending', 'Salary batch')
  RETURNING transaction_id INTO v_batch_tx;

  -- iterate payments: try each, on error record and continue
  v_idx := 0;
  FOR v_elem IN SELECT * FROM jsonb_array_elements(p_payments)
  LOOP
    v_idx := v_idx + 1;
    BEGIN
      -- find recipient active account by customer's iin, prefer KZT
      SELECT a.* INTO v_rec_account
      FROM accounts a JOIN customers c ON a.customer_id = c.customer_id
      WHERE c.iin = v_elem->>'iin' AND a.is_active = TRUE
      ORDER BY CASE WHEN a.currency='KZT' THEN 0 ELSE 1 END
      LIMIT 1
      FOR UPDATE NOWAIT;

      IF NOT FOUND THEN
        v_failed := v_failed || jsonb_build_object('index',v_idx,'iin',v_elem->>'iin','error','recipient not found or inactive');
        CONTINUE;
      END IF;

      -- compute amount_kzt (based on payment currency)
      v_amount_kzt := to_kzt((v_elem->>'amount')::numeric, (v_elem->>'currency')::text);

      -- create savepoint for this payment
      EXECUTE 'SAVEPOINT sp_' || v_batch_tx || '_' || v_idx;

      -- insert child transaction (pending)
      INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,description,parent_transaction_id)
      VALUES (v_company.account_id, v_rec_account.account_id, (v_elem->>'amount')::numeric, (v_elem->>'currency')::text, COALESCE(NULLIF(get_rate(v_company.currency, v_rec_account.currency),NULL),1), v_amount_kzt, 'salary', 'pending', COALESCE(v_elem->>'description','salary'), v_batch_tx)
      RETURNING transaction_id INTO v_child_tx;

      -- update balances immediately for simplicity (still inside same transaction)
      -- debit company (in company currency)
      UPDATE accounts SET balance = round(balance - ((v_amount_kzt) / get_rate(v_company.currency,'KZT')),2) WHERE account_id = v_company.account_id;
      -- credit recipient (convert if needed)
      UPDATE accounts SET balance = round(balance + ((v_amount_kzt) / get_rate(v_rec_account.currency,'KZT')),2) WHERE account_id = v_rec_account.account_id;

      -- mark child tx completed
      UPDATE transactions SET status='completed', completed_at = now() WHERE transaction_id = v_child_tx;

      -- log per-child audit
      INSERT INTO audit_logs(table_name,record_id,action,new_values,changed_by,changed_at,ip_address)
        VALUES('transactions',v_child_tx,'INSERT',jsonb_build_object('status','completed','amount_kzt',v_amount_kzt),p_performed_by,now(),p_ip);

      v_success := v_success + 1;

      -- release savepoint
      EXECUTE 'RELEASE SAVEPOINT sp_' || v_batch_tx || '_' || v_idx;

    EXCEPTION WHEN OTHERS THEN
      -- rollback to savepoint for this payment and record failure
      BEGIN
        EXECUTE 'ROLLBACK TO SAVEPOINT sp_' || v_batch_tx || '_' || v_idx;
      EXCEPTION WHEN OTHERS THEN NULL; END;
      v_failed := v_failed || jsonb_build_object('index',v_idx,'iin',v_elem->>'iin','error',SQLERRM);
      CONTINUE;
    END;
  END LOOP;

  -- mark parent batch completed
  UPDATE transactions SET status='completed', completed_at = now(), new_values = jsonb_build_object('successful',v_success,'failed',jsonb_array_length(v_failed)) WHERE transaction_id = v_batch_tx;

  RETURN jsonb_build_object('success',true,'batch_tx',v_batch_tx,'total_kzt',v_total_kzt,'successful',v_success,'failed',jsonb_array_length(v_failed),'failed_details',v_failed);

EXCEPTION WHEN OTHERS THEN
  -- On any unexpected error: mark parent failed and return summary
  IF v_batch_tx IS NOT NULL THEN
    UPDATE transactions SET status='failed', new_values = jsonb_build_object('error',SQLERRM) WHERE transaction_id = v_batch_tx;
  END IF;
  RETURN jsonb_build_object('success',false,'error',SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- =============================
-- TASK 6: REPORTING VIEWS (window functions, security barrier)
-- =============================
-- View 1: customer_balance_summary
CREATE OR REPLACE VIEW customer_balance_summary AS
WITH rates AS (
  SELECT DISTINCT ON (from_currency) from_currency, rate AS rate_to_kzt
  FROM exchange_rates WHERE to_currency='KZT' AND valid_from <= now() AND (valid_to IS NULL OR valid_to > now()) ORDER BY from_currency, valid_from DESC
),
acct_kzt AS (
  SELECT a.account_id, a.customer_id, a.account_number, a.currency, a.balance,
         round(a.balance * COALESCE(r.rate_to_kzt, 1),2) AS balance_kzt
  FROM accounts a LEFT JOIN rates r ON a.currency = r.from_currency
  WHERE a.is_active = TRUE
),
cust_tot AS (
  SELECT c.customer_id, c.full_name, c.iin, c.daily_limit_kzt,
         SUM(ak.balance_kzt) AS total_balance_kzt,
         COALESCE((SELECT SUM(t.amount_kzt) FROM transactions t JOIN accounts a ON t.from_account_id=a.account_id WHERE a.customer_id=c.customer_id AND t.type='transfer' AND t.status='completed' AND t.created_at::date = now()::date),0) AS today_out_kzt
  FROM customers c JOIN acct_kzt ak ON c.customer_id = ak.customer_id
  GROUP BY c.customer_id, c.full_name, c.iin, c.daily_limit_kzt
)
SELECT
  customer_id, full_name, iin, total_balance_kzt, today_out_kzt,
  round(100.0 * today_out_kzt / NULLIF(daily_limit_kzt,0),2) AS daily_limit_utilization_pct,
  RANK() OVER (ORDER BY total_balance_kzt DESC) AS rank_by_balance
FROM cust_tot;

-- View 2: daily_transaction_report
CREATE OR REPLACE VIEW daily_transaction_report AS
WITH daily AS (
  SELECT date(created_at) AS dt, type, sum(amount_kzt) AS total_kzt, count(*) AS tx_count
  FROM transactions WHERE status='completed' GROUP BY date(created_at), type
)
SELECT
  dt AS transaction_date, type, tx_count, total_kzt,
  SUM(total_kzt) OVER (PARTITION BY type ORDER BY dt ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_kzt,
  LAG(total_kzt) OVER (PARTITION BY type ORDER BY dt) AS prev_day_total_kzt,
  CASE WHEN LAG(total_kzt) OVER (PARTITION BY type ORDER BY dt) IS NULL THEN NULL
       WHEN LAG(total_kzt) OVER (PARTITION BY type ORDER BY dt) = 0 THEN NULL
       ELSE round(100.0*(total_kzt - LAG(total_kzt) OVER (PARTITION BY type ORDER BY dt)) / LAG(total_kzt) OVER (PARTITION BY type ORDER BY dt),2) END AS day_over_day_pct
FROM daily
ORDER BY transaction_date DESC;

-- View 3: suspicious_activity_view (security barrier)
CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
-- flags: large transfers, high frequency, rapid sequence
SELECT 'LARGE' AS flag, t.transaction_id, t.from_account_id, a.customer_id, c.iin, c.full_name, t.amount_kzt, t.created_at, t.description
FROM transactions t JOIN accounts a ON t.from_account_id = a.account_id JOIN customers c ON a.customer_id = c.customer_id
WHERE t.status='completed' AND t.amount_kzt > 5000000

UNION ALL

SELECT 'HIGH_FREQ' AS flag, NULL::int AS transaction_id, a.account_id, c.customer_id, c.iin, c.full_name, NULL::numeric, date_trunc('hour',t.created_at) AS created_at, 'More than 10 transfers in an hour'
FROM transactions t JOIN accounts a ON t.from_account_id = a.account_id JOIN customers c ON a.customer_id = c.customer_id
WHERE t.status='completed' AND t.type='transfer'
GROUP BY a.account_id,c.customer_id,c.iin,c.full_name,date_trunc('hour',t.created_at)
HAVING COUNT(*) > 10

UNION ALL

SELECT 'RAPID' AS flag, t2.transaction_id, t2.from_account_id, a.customer_id, c.iin, c.full_name, t2.amount_kzt, t2.created_at, 'rapid sequence'
FROM transactions t1 JOIN transactions t2 ON t1.from_account_id = t2.from_account_id AND t2.created_at > t1.created_at AND t2.created_at <= t1.created_at + interval '60 seconds'
JOIN accounts a ON t2.from_account_id = a.account_id JOIN customers c ON a.customer_id = c.customer_id
WHERE t1.status='completed' AND t2.status='completed' AND t1.type='transfer' AND t2.type='transfer';

-- =============================
-- TASK 7: INDEX STRATEGY (create several index types)
-- =============================
-- B-tree on account_number
CREATE INDEX IF NOT EXISTS idx_accounts_number ON accounts(account_number);
-- Composite index on from_account_id + created_at
CREATE INDEX IF NOT EXISTS idx_transactions_from_created ON transactions(from_account_id, created_at);
-- Partial index: active accounts
CREATE INDEX IF NOT EXISTS idx_accounts_active ON accounts(account_id) WHERE is_active = TRUE;
-- Expression index for case-insensitive email lookup
CREATE INDEX IF NOT EXISTS idx_customers_email_lower ON customers( lower(email) );
-- GIN index for JSONB audit_logs new_values
CREATE INDEX IF NOT EXISTS idx_audit_new_values_gin ON audit_logs USING gin (new_values);
-- Covering index example (include amount_kzt)
CREATE INDEX IF NOT EXISTS idx_tx_cover ON transactions(from_account_id, created_at) INCLUDE (amount_kzt, status);
-- Hash index for iin equality lookups
CREATE INDEX IF NOT EXISTS idx_customers_iin_hash ON customers USING hash(iin);

-- EXPLAIN ANALYZE commands (run locally and paste outputs in submission)
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM accounts WHERE account_number = 'KZ123456789012345678';
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM transactions WHERE from_account_id = 1 AND created_at > now() - interval '7 days';
-- EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM audit_logs WHERE new_values @> '{"amount_kzt":1000}';

-- =============================
-- TESTS (labelled) — run in psql, observe NOTICE outputs / returned JSON
-- =============================

-- TEST: successful same-currency transfer (KZT -> KZT)
DO $$
DECLARE r JSON;
BEGIN
  r := process_transfer('KZ123456789012345678','KZ123456789012345682',1000,'KZT','TEST KZT transfer','tester','127.0.0.1');
  RAISE NOTICE 'TEST same-currency => %', r;
END;
$$;

-- TEST: successful cross-currency transfer (USD account to KZT account)
DO $$
DECLARE r JSON;
BEGIN
  r := process_transfer('KZ123456789012345679','KZ123456789012345678',100,'USD','TEST USD->KZT','tester','127.0.0.1');
  RAISE NOTICE 'TEST USD->KZT => %', r;
END;
$$;

-- TEST: insufficient funds (should return success=false)
DO $$
DECLARE r JSON;
BEGIN
  r := process_transfer('KZ123456789012345678','KZ123456789012345682',100000000,'KZT','TEST insufficient','tester','127.0.0.1');
  RAISE NOTICE 'TEST insufficient => %', r;
END;
$$;

-- TEST: daily limit exceeded (temporarily set tiny limit and restore)
UPDATE customers SET daily_limit_kzt = 1 WHERE iin = '123456789012';
DO $$
DECLARE r JSON;
BEGIN
  r := process_transfer('KZ123456789012345678','KZ123456789012345682',100,'KZT','TEST daily limit','tester','127.0.0.1');
  RAISE NOTICE 'TEST daily limit => %', r;
END;
$$;
-- revert
UPDATE customers SET daily_limit_kzt = 500000 WHERE iin = '123456789012';

-- TEST: transfer from inactive account (should reject)
UPDATE accounts SET is_active = FALSE WHERE account_number = 'KZ123456789012345682';
DO $$
DECLARE r JSON;
BEGIN
  r := process_transfer('KZ123456789012345678','KZ123456789012345682',10,'KZT','TEST dest inactive','tester','127.0.0.1');
  RAISE NOTICE 'TEST dest inactive => %', r;
END;
$$;
-- restore
UPDATE accounts SET is_active = TRUE WHERE account_number = 'KZ123456789012345682';

-- TEST: salary batch (one valid iin, one invalid)
DO $$
DECLARE payments JSONB := '[{"iin":"123456789012","amount":1000,"description":"Dec salary"},{"iin":"000000000000","amount":2000,"description":"Invalid"}]';
DECLARE res JSONB;
BEGIN
  res := process_salary_batch('KZ123456789012345681', payments, 'payroll','127.0.0.1');
  RAISE NOTICE 'TEST salary batch => %', res;
END;
$$;

-- CONCURRENCY DEMO (instructions only)
-- 1) Session A: BEGIN; SELECT * FROM accounts WHERE account_number='KZ123456789012345678' FOR UPDATE; (do not commit)
-- 2) Session B: call process_transfer(...) using same source account -> it will block until Session A commits/rolls back.
-- This demonstrates row-level locking and isolation.

-- =============================
-- BRIEF NOTES (for submission)
-- - Task 1: process_transfer implements ACID: row locks, SAVEPOINT, audit logging, clear error codes.
-- - Task 2: Views use window functions (RANK, SUM OVER, LAG) and security_barrier for suspicious view.
-- - Task 3: Index strategy includes B-tree, composite, partial, expression, GIN, covering, hash; run EXPLAIN ANALYZE locally and attach outputs.
-- - Task 4: process_salary_batch uses advisory lock and per-payment SAVEPOINTs to continue on individual failures and produce a summary.
-- - Tests: labeled blocks above demonstrate successful and failing scenarios.
-- =============================

