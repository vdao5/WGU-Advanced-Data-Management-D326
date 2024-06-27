-- VD - 000861887
-- Please obly run 1 query each.

-- Refresh data
CALL d326_refersh_details();

-- List of customers who spent the most (at store 2)
SELECT * FROM d326_summary WHERE store_id = 2 ORDER BY total DESC LIMIT 100; 

-- List of details payment of customer "Karl Seal" (id 526)
SELECT * FROM d326_details WHERE customer_id = 526;

-- List of potential customer might return after seeing ads
SELECT * FROM d326_summary ORDER BY (last_6_month / 6 - last_month) DESC LIMIT 100;