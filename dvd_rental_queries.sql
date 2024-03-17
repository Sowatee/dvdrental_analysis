-- Create detailed table
DROP TABLE IF EXISTS detailed;
CREATE TABLE detailed (
	name VARCHAR (25),
	category_id INT,
	amount NUMERIC (5,2),
	payment_date TIMESTAMP,
	payment_id INT,
	rental_id INT,
	inventory_id INT,
	film_id INT
);

-- Create summary table
DROP TABLE IF EXISTS summary;
CREATE TABLE summary (
	category_name VARCHAR (25),
	total_revenue NUMERIC(8,2),
	total_rentals INT
);
	
-- Function to transform columns and insert data into summary table
CREATE OR REPLACE FUNCTION update_summary_table() RETURNS VOID AS $$
BEGIN
	-- Delete existing data from the summary table
	DELETE FROM summary;
	
	-- Insert new data into summary table
	INSERT INTO summary (
		category_name, 
		total_revenue, 
		total_rentals
	)
	SELECT name, COUNT(*), SUM(amount)
	FROM detailed
	GROUP BY name;
END;
$$ LANGUAGE plpgsql;
	
-- Trigger Function to Automatically Update Summary Table
CREATE OR REPLACE FUNCTION update_summary_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
	-- Call the update_summary_table() function
	PERFORM update_summary_table();
	RETURN NULL; -- Return null as we're not modifying the triggering operation
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER update_summary_trigger
AFTER INSERT ON detailed
FOR EACH STATEMENT
EXECUTE FUNCTION update_summary_trigger_function();

-- Grab raw data to insert into the detailed table
INSERT INTO detailed (
	name, 
	category_id,
	amount, 
	payment_date, 
	payment_id, 
	rental_id,
	inventory_id,
	film_id
)
SELECT
	c.name,
	c.category_id,
	pay.amount,
	pay.payment_date,
	pay.payment_id,
	r.rental_id,
	i.inventory_id,
	f.film_id
FROM category c
LEFT JOIN film_category f
	ON c.category_id = f.category_id
LEFT JOIN inventory i
	ON f.film_id = i.film_id
LEFT JOIN rental r
	ON i.inventory_id = r.inventory_id
LEFT JOIN payment pay
	ON r.rental_id = pay.rental_id
;

-- STORED PROCEDURE
CREATE OR REPLACE PROCEDURE refresh_data()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Clear the contents of the detailed table
    DELETE FROM detailed;
    -- Clear the contents of the summary table
    DELETE FROM summary;
	-- Grab raw data to insert into the detailed table
	INSERT INTO detailed (
		name, 
		category_id,
		amount, 
		payment_date, 
		payment_id, 
		rental_id,
		inventory_id,
		film_id
	)
	SELECT
		c.name,
		c.category_id,
		pay.amount,
		pay.payment_date,
		pay.payment_id,
		r.rental_id,
		i.inventory_id,
		f.film_id
	FROM category c
	LEFT JOIN film_category f
		ON c.category_id = f.category_id
	LEFT JOIN inventory i
		ON f.film_id = i.film_id
	LEFT JOIN rental r
		ON i.inventory_id = r.inventory_id
	LEFT JOIN payment pay
		ON r.rental_id = pay.rental_id
	;
    -- Update the summary table
    PERFORM update_summary_table();
END;
$$;
