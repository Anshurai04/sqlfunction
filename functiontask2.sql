CREATE TABLE train_ticket (
    PNR_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    AGE INT NOT NULL,
    gender CHAR(1),
    boardig_station varchar(20) NOT NULL,
    departure_station varchar(20) NOT NULL,
    journey_date DATE NOT NULL DEFAULT CURRENT_DATE);

    -- Table Constraints 
    ALTER TABLE train_ticket
ADD CONSTRAINT chk_passenger_age CHECK (AGE BETWEEN 1 AND 150);

-- 2. GENDER constraint (must be M, F, or O)
ALTER TABLE train_ticket
ADD CONSTRAINT chk_passenger_gender CHECK (gender IN ('M', 'F', 'O'));

-- 3. STATION constraint (boarding and departure stations must be different)
ALTER TABLE train_ticket
ADD CONSTRAINT chk_different_stations CHECK ("boardig_station" <> "departure_station");

-- 4. JOURNEY DATE constraint (must be today or a future date)
ALTER TABLE train_ticket
ADD CONSTRAINT chk_future_journey CHECK (journey_date >= CURRENT_DATE);

-- 5. Name constraint (ensure non-empty string)
ALTER TABLE train_ticket
ADD CONSTRAINT chk_first_name_not_empty CHECK (TRIM(first_name) <> '');

select * from train_ticket



CREATE TABLE train_food (
    -- PNR_id is now the Primary Key for the food order record.
    -- Note: Since this table represents an order *detail*, 
    -- you might consider a separate 'order_id' as PRIMARY KEY 
    -- and keep PNR_id as a foreign key if a single PNR can have multiple food orders.
    PNR_id INT NOT NULL, -- Changed from SERIAL PK to just INT NOT NULL (See note below)
    order_id SERIAL PRIMARY KEY, -- Added a dedicated PK for this table

    -- Constraint 1: Restaurant ID must be positive.
    restrorent_id INT NOT NULL CHECK (restrorent_id > 0),
    
    -- Constraint 2 & 3: Ensure text fields are not empty or just whitespace.
    delevered_station VARCHAR(100) NOT NULL CHECK (TRIM(delevered_station) <> ''),
    "select_food" VARCHAR(100) NOT NULL CHECK (TRIM("select_food") <> ''),
    
    -- Constraint 4: Restricts the food type to a predefined list (e.g., common dietary options).
    food_type VARCHAR(50) NOT NULL CHECK (food_type IN ('Veg', 'Non-Veg', 'Jain', 'Vegan', 'Diabetic')),
    
    -- Constraint 5: Ensures the order date is today or in the future (no past orders).
    order_date DATE NOT NULL DEFAULT CURRENT_DATE CHECK (order_date >= CURRENT_DATE),

    -- Foreign Key Constraint (linking the food order back to the main ticket)
    CONSTRAINT fk_PNR
        FOREIGN KEY (PNR_id)
        REFERENCES train_ticket(PNR_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
    

select * from train_ticket;
select * from train_food;


-- 1. Function to insert a new record into the train_ticket table
-- RETURNS SETOF train_ticket: This tells the function to return the row data.
CREATE OR REPLACE FUNCTION insert_train_ticket_with_aggregate()
RETURNS SETOF train_ticket AS $$
DECLARE
    -- Variables to hold the new PNR_id and the current maximum PNR_id
    new_pnr_id INT;
    max_pnr_id INT;
BEGIN
    -- 1. Find the current maximum PNR_id in the table
    -- NOTE: Since PNR_id is SERIAL, in a real database, you'd let the DB handle the ID.
    -- We continue using MAX() to align with your aggregation pattern.
    SELECT coalesce(max(PNR_id), 0) INTO max_pnr_id FROM train_ticket;
    
    -- 2. Calculate the new ID
    new_pnr_id := max_pnr_id + 1;
    
    -- 3. Insert the new ticket record using the calculated ID
    INSERT INTO train_ticket (
        PNR_id,
        first_name, 
        last_name, 
        age, 
        gender, 
        boardig_station, 
        departure_station, 
        journey_date
    )
    VALUES (
        new_pnr_id, 
        'Sample', 
        'Passenger', 
        30,
        'M', 
        'DELHI',           -- Changed to text to match VARCHAR(20)
        'MUMBAI',          -- Must be different from DELHI
        current_date + interval '1 day' 
    );

    -- 4. RETURN QUERY: Output the newly inserted row to the caller
    RETURN QUERY SELECT * FROM train_ticket WHERE PNR_id = new_pnr_id;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------

-- 2. Function to insert a new record into the train_food table
-- RETURNS SETOF train_food: This tells the function to return the row data.
CREATE OR REPLACE FUNCTION insert_train_food_with_aggregate()
RETURNS SETOF train_food AS $$
DECLARE
    -- Variables for the food order ID
    new_order_id INT;
    max_order_id INT;
    
    -- Variable for the Foreign Key (PNR_id)
    latest_pnr_id INT;
BEGIN
    -- 1. Get the primary key for the new food order record
    SELECT coalesce(max(order_id), 0) INTO max_order_id FROM train_food;
    new_order_id := max_order_id + 1;
    
    -- 2. Find the PNR_id of the most recently inserted ticket
    SELECT max(PNR_id) INTO latest_pnr_id FROM train_ticket;
    
    -- Check if a ticket exists before inserting food
    IF latest_pnr_id IS NULL THEN
        RAISE EXCEPTION 'No ticket (PNR) found in train_ticket table. Run insert_train_ticket_with_aggregate() first.';
    END IF;
    
    -- 3. Insert the new food order record
    INSERT INTO train_food (
        order_id,
        PNR_id, 
        restrorent_id, 
        delevered_station, 
        select_food, 
        food_type, 
        order_date
    )
    VALUES (
        new_order_id,
        latest_pnr_id,   -- Use the ID of the latest ticket (FK)
        101,             -- Sample restaurant ID
        'HYDERABAD',     
        'Paneer Butter Masala', 
        'Veg',           
        current_date
    );

    -- 4. RETURN QUERY: Output the newly inserted row to the caller
    RETURN QUERY SELECT * FROM train_food WHERE order_id = new_order_id;
END;
$$ LANGUAGE plpgsql;
SELECT insert_train_food_with_aggregate();
select insert_train_ticket_with_aggregate();
select  PNR_id ,first_name ,last_name ,AGE ,gender ,boardig_station ,departure_station ,journey_date from train_ticket
select  PNR_id, order_id,restrorent_id,delevered_station,food_type,order_date from train_food