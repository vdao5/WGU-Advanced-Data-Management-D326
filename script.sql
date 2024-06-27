-- VD - 000861887
-- Please run all to create 2 tables d326_details and d326_summary

-- Get last sale date 
CREATE OR REPLACE FUNCTION d326_last_rental_date()
RETURNS TIMESTAMP
LANGUAGE plpgsql
AS
$$
DECLARE ret TIMESTAMP;
BEGIN
	SELECT rental_date FROM rental ORDER BY rental_date DESC LIMIT 1 INTO ret;
	RETURN ret;
END
$$;

-- B. Custom transfromation
CREATE OR REPLACE FUNCTION d326_full_name(
	first_name VARCHAR(45),
	last_name VARCHAR(45)
	)
	RETURNS VARCHAR(100)
	LANGUAGE 'plpgsql'
AS $$
BEGIN
	RETURN first_name || ' ' || last_name;
END
$$;

-- C. Create tables
DROP TABLE IF EXISTS d326_details;
CREATE TABLE d326_details
(
	payment_id INT,
	customer_id INT,
	store_id INT,
	amount NUMERIC(5,2),
	rental_date TIMESTAMP,
	full_name VARCHAR(100),
	PRIMARY KEY (payment_id),
	FOREIGN KEY (payment_id) REFERENCES payment(payment_id),
	FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
	FOREIGN KEY (store_id) REFERENCES store(store_id)
);

DROP TABLE IF EXISTS d326_summary;
CREATE TABLE d326_summary
(
	customer_id INT,
	store_id INT,
	full_name VARCHAR(100),
	last_month NUMERIC(10,2),
	last_6_month NUMERIC(10,2),
	total NUMERIC(10,2),
	PRIMARY KEY (customer_id),
	FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
	FOREIGN KEY (store_id) REFERENCES store(store_id)
);

-- E. Create trigger
CREATE OR REPLACE FUNCTION d326_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	TRUNCATE d326_summary;
	INSERT INTO d326_summary
		SELECT	customer_id,
				store_id,
				full_name,
				COALESCE(SUM(amount) FILTER (WHERE rental_date > d326_last_rental_date() - INTERVAL '30 DAY'), 0), 
				COALESCE(SUM(amount) FILTER (WHERE rental_date > d326_last_rental_date() - INTERVAL '180 DAY'), 0), 
				COALESCE(SUM(amount), 0)
		FROM d326_details
		GROUP BY customer_id, store_id, full_name;
	RETURN NEW;
END;
$$;

CREATE TRIGGER d326_trigger
AFTER INSERT
ON d326_details
FOR EACH STATEMENT
EXECUTE PROCEDURE d326_trigger_function();

-- D. Extract data
CREATE OR REPLACE PROCEDURE d326_refersh_details()
LANGUAGE plpgsql
AS $$
BEGIN
	TRUNCATE d326_details;
	INSERT INTO d326_details
		SELECT	t1.payment_id, 
				t1.customer_id, 
				t2.store_id, 
				t1.amount, 
				t3.rental_date, 
				d326_full_name(t2.first_name, t2.last_name)
		FROM payment as t1
			INNER JOIN customer as t2
			ON t1.customer_id = t2.customer_id
			INNER JOIN rental as t3
			ON t1.rental_id = t3.rental_id;
END;
$$;

CALL d326_refersh_details();

