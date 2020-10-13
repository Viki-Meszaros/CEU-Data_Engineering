-- Exercise3
-- Create a stored procedure which returns category of a given row. Row number is IN parameter, while category is OUT parameter. Display the returned category.
-- CAT1 - amount > 100.000, CAT2 - amount > 10.000, CAT3 - amount <= 10.000
use classicmodels;

DROP PROCEDURE IF EXISTS GetCategory;

DELIMITER $$

CREATE PROCEDURE GetCategory(
    	IN  row_num INT, 
    	OUT amount_category  VARCHAR(20)
)
BEGIN
	DECLARE var DECIMAL DEFAULT 0;
    
    SET row_num =row_num-1;
    
    SELECT amount
		INTO var
			FROM payments
				LIMIT row_num, 1;

IF var > 100000 THEN
		SET amount_category = 'CAT1';
	ELSEIF var > 10000 & amount <= 100000 THEN
		SET amount_category = 'CAT2';
    ELSE
		SET amount_category = 'CAT3';
	END IF;
END$$
DELIMITER ;

CALL GetCategory(40, @cat);
SELECT @cat;