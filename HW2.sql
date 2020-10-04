-- EXCERCISE 1
SELECT * FROM birdstrikes LIMIT 144,1;
-- "Tennessee"

-- EXERCISE 2
SELECT flight_date FROM birdstrikes ORDER BY flight_date DESC;
SELECT * FROM birdstrikes AS b ORDER BY b.flight_date DESC; -- to make is easier as when you type b. it lists the possibilities
-- "2000-04-18"

-- EXERCISE 3
SELECT DISTINCT cost FROM birdstrikes order by cost DESC LIMIT 49,1;
-- "5345"

-- EXERCISE 4
SELECT state, bird_size FROM birdstrikes WHERE state IS NOT NULL AND bird_size IS NOT NULL;
-- " "

-- EXERCISE 5
SELECT *, datediff(now(), flight_date) AS days_elapsed FROM birdstrikes WHERE state = 'Colorado' AND weekofyear(flight_date) = 52;
-- "7582" (Does week 52 mean Jan. 1-7 in SQL? Shouldn't it be Dec. 25-31?