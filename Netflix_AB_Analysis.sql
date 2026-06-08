-- Create the foundational 'movies' table with appropriate data types
CREATE TABLE movies (
    name VARCHAR(255),
    rating VARCHAR(50),
    genre VARCHAR(100),
    year INT,
    released VARCHAR(255),
    score NUMERIC(3,1),
    votes INT, 
    director VARCHAR(255),
    writer VARCHAR(255),
    star VARCHAR(255),
    country VARCHAR(100),
    budget BIGINT,
    gross BIGINT,
    company VARCHAR(255),
    runtime INT,
    profitability BIGINT,
    score_category VARCHAR(50),
    decade VARCHAR(50),
    runtime_category VARCHAR(50)
);

-- Quick data check: Count total records in the dataset
SELECT COUNT(*) 
FROM movies;

-- Quick data check: Preview the first 5 rows
SELECT * FROM movies
LIMIT 5;

-- Exploratory query: Check all records (Used frequently in your script for quick checks)
SELECT * FROM movies;

-- Exploratory query: Filter specifically for the 'History' genre
SELECT * FROM movies 
WHERE Genre = 'History';

CREATE VIEW key_performance_indicators AS
SELECT 
    COUNT(*) AS total_movies,
    SUM(budget) AS total_budget_spent,
    SUM(gross) AS total_gross_revenue,
    SUM(profitability) AS total_net_profit,
    -- Calculates the overall ROI/Profit Margin percentage
    ROUND((SUM(profitability)::NUMERIC / SUM(budget)::NUMERIC) * 100, 2) AS return_on_investment_pct,
    SUM(votes) AS total_audience_votes,
    ROUND(AVG(score), 2) AS average_imdb_score
FROM movies;

-- View top 10 most common genres in the dataset
CREATE OR REPLACE VIEW genre_distribution AS
SELECT 
    Genre, 
    COUNT(*) AS Genre_Distribution
FROM movies
GROUP BY Genre
ORDER BY Genre_Distribution DESC
LIMIT 10;

-- How Netflix Growing Over Decades
CREATE OR REPLACE TABLE decades_growths AS
SELECT 
	genre,
    decade,
    COUNT(*) AS movies_released,
    SUM(budget) AS total_budget,
    SUM(gross) AS total_gross_revenue,
    SUM(profitability) AS net_profit
FROM movies
GROUP BY decade, genre
ORDER BY decade ASC;



SELECT 
    genre,
    COUNT(*) AS movie_count,
    SUM(gross) AS total_gross_revenue,
    SUM(profitability) AS total_profit,
    ROUND(AVG(score), 2) AS average_score
FROM movies
GROUP BY genre
ORDER BY total_gross_revenue DESC;


-- Analysing MoM growth for the 2019 Jan - Dec
CREATE VIEW month_on_month_metrics AS
WITH monthly_metrics AS (
    SELECT 
        CASE SPLIT_PART(released, ' ', 1)
            WHEN 'January'   THEN 1  WHEN 'February'  THEN 2  WHEN 'March'     THEN 3
            WHEN 'April'     THEN 4  WHEN 'May'       THEN 5  WHEN 'June'      THEN 6
            WHEN 'July'      THEN 7  WHEN 'August'    THEN 8  WHEN 'September' THEN 9
            WHEN 'October'   THEN 10 WHEN 'November'  THEN 11 WHEN 'December'  THEN 12
        END AS month_num,
        CASE SPLIT_PART(released, ' ', 1)
            WHEN 'January'   THEN 'Jan'  WHEN 'February'  THEN 'Feb'  WHEN 'March'     THEN 'Mar'
            WHEN 'April'     THEN 'Apr'  WHEN 'May'       THEN 'May'  WHEN 'June'      THEN 'Jun'
            WHEN 'July'      THEN 'Jul'  WHEN 'August'    THEN 'Aug'  WHEN 'September' THEN 'Sep'
            WHEN 'October'   THEN 'Oct'  WHEN 'November'  THEN 'Nov'  WHEN 'December'  THEN 'Dec'
        END AS month_display,
        SUM(votes) AS current_month_votes,
        SUM(gross) AS current_month_revenue
    FROM movies
    WHERE year = 2019
    GROUP BY SPLIT_PART(released, ' ', 1)
),
ordered_monthly_metrics AS (
    SELECT 
        month_num,
        month_display,
        current_month_votes,
        current_month_revenue,
        LAG(current_month_votes, 1) OVER (ORDER BY month_num) AS previous_month_votes,
        LAG(current_month_revenue, 1) OVER (ORDER BY month_num) AS previous_month_revenue
    FROM monthly_metrics
)
SELECT 
    month_num, 
    month_display AS "Month",
    -- Clean Fix: Outputs a raw math decimal percentage, handles baseline Jan nulls as 0.00
    COALESCE(ROUND(((current_month_votes - previous_month_votes)::NUMERIC / NULLIF(previous_month_votes, 0)) * 100, 2), 0.00) AS user_growth_mom,
    COALESCE(ROUND(((current_month_revenue - previous_month_revenue)::NUMERIC / NULLIF(previous_month_revenue, 0)) * 100, 2), 0.00) AS revenue_growth_mom
FROM ordered_monthly_metrics
WHERE month_num IS NOT NULL;

-- How Genre is Distributed
SELECT * FROM movies
CREATE VIEW genre_distribution AS
SELECT Genre ,COUNT(*) AS Genre_Distribution
FROM movies
GROUP BY Genre
ORDER BY Genre_Distribution DESC
LIMIT 10

-- Understanding How Much are we leaking
CREATE OR REPLACE VIEW leakage_analysis AS
SELECT 

    genre,
    rating,
    runtime_category,
    score_category,

    -- Total movies in each category combination
    COUNT(*) AS total_movies_produced,

    -- 1. Financial Capital Losses
    SUM(
        CASE 
            WHEN profitability < 0 THEN 1 
            ELSE 0 
        END
    ) AS loss_making_movies,

    -- Loss rate as decimal (Power BI converts to %)
    ROUND(
        SUM(
            CASE 
                WHEN profitability < 0 THEN 1 
                ELSE 0 
            END
        )::NUMERIC
        / COUNT(*)::NUMERIC,
        4
    ) AS money_loss_rate_pct,

    -- Total money lost
    SUM(
        CASE 
            WHEN profitability < 0 
            THEN profitability 
            ELSE 0 
        END
    ) AS total_capital_lost,

    -- 2. Audience Engagement Gaps
    ROUND(AVG(votes),0) AS avg_user_votes,

    -- Movies with poor audience engagement
    SUM(
        CASE 
            WHEN votes < 10000 THEN 1 
            ELSE 0 
        END
    ) AS low_engagement_movies,

    -- Ghosting rate as decimal 
    ROUND(
        SUM(
            CASE 
                WHEN votes < 10000 THEN 1 
                ELSE 0 
            END
        )::NUMERIC
        / COUNT(*)::NUMERIC,
        4
    ) AS user_ghosting_rate_pct

FROM movies
GROUP BY 
    genre,
    rating,
    runtime_category,
    score_category
HAVING COUNT(*) >= 5;


	
-- Which Company is Loosing Money
CREATE VIEW company_max_lost AS
SELECT 
	Company,
    -- Total money lost
    SUM(
        CASE 
            WHEN profitability < 0 
            THEN profitability 
            ELSE 0 
        END
    ) AS total_capital_lost
FROM movies
GROUP BY Company
ORDER BY total_capital_lost ASC
LIMIT 10

-- SELECT * FROM movies



CREATE OR REPLACE VIEW leakage_talent_risk AS
SELECT 
    director,
    COUNT(*) AS total_movies_made,
    SUM(CASE WHEN profitability < 0 THEN profitability ELSE 0 END) AS total_capital_lost,
    ROUND(AVG(score), 2) AS avg_imdb_score
FROM movies
GROUP BY director
HAVING SUM(CASE WHEN profitability < 0 THEN 1 ELSE 0 END) >= 3 -- Show people with repeated losses
ORDER BY total_capital_lost ASC -- Brings the biggest negative numbers to the top
LIMIT 10;


-- Dashboard - 3 Startegic Optimization
CREATE TABLE dashboard3_optimization AS
SELECT 
    genre,
    rating,
    runtime_category,

    CASE 
        WHEN budget < 10000000 THEN 'Low Budget (<$10M)'
        WHEN budget BETWEEN 10000000 AND 50000000 THEN 'Medium Budget ($10M-$50M)'
        WHEN budget BETWEEN 50000000 AND 100000000 THEN 'High Budget ($50M-$100M)'
        ELSE 'Blockbuster Budget (>$100M)'
    END AS budget_tier,

    COUNT(*) AS total_movies_produced,
    ROUND(AVG(budget),0) AS avg_budget_spent,
    ROUND(AVG(gross),0) AS avg_gross_earned,
    ROUND(AVG(profitability),0) AS avg_net_profit,



    -- ROI
    ROUND(
        SUM(profitability)::NUMERIC /
        NULLIF(SUM(budget),0),
        4
    ) AS roi_percentage,

    -- Commercial Success Rate
    ROUND(
        SUM(
            CASE 
                WHEN profitability > 0 THEN 1 
                ELSE 0 
            END
        )::NUMERIC /
        COUNT(*)::NUMERIC,
        4
    ) AS commercial_success_rate_pct,

    ROUND(AVG(votes),0) AS avg_audience_votes

FROM movies
WHERE budget > 0 
AND gross > 0

GROUP BY
    genre,
    rating,
    runtime_category,

    CASE 
        WHEN budget < 10000000 THEN 'Low Budget (<$10M)'
        WHEN budget BETWEEN 10000000 AND 50000000 THEN 'Medium Budget ($10M-$50M)'
        WHEN budget BETWEEN 50000000 AND 100000000 THEN 'High Budget ($50M-$100M)'
        ELSE 'Blockbuster Budget (>$100M)'
    END;


-- Calculating Expected ROI
CREATE VIEW expected_ROI AS
SELECT 
ROUND(AVG(roi_percentage),4) AS optimal_expected_roi
FROM dashboard3_optimization
WHERE commercial_success_rate_pct > 0.60;



-- SELECT * FROM movies

-- Which Genres are highly profitable
SELECT genre, SUM(profitability) AS total_profitability
FROM movies
GROUP BY genre
ORDER BY total_profitability DESC

-- Which Genres Are less profitable
SELECT genre, SUM(profitability) AS total_profitability
FROM movies
GROUP By genre
ORDER BY total_profitability ASC


-- Which Genre are Highly Avg profitable In percentage
SELECT genre,
       ROUND(AVG(
           ((Gross - Budget) * 100.0 / Budget)
       ),2) AS avg_profitability_pct
FROM movies
WHERE Budget > 0
GROUP BY genre
ORDER BY avg_profitability_pct ASC;


-- SELECT * FROM movies

-- How much directors are there
SELECT director, COUNT(*) AS total_movies,

FROM movies
GROUP BY director
ORDER BY total_movies DESC


-- Understanding user Engagement -- (Usefull Table)
CREATE VIEW genre_user_engagement AS

SELECT
    genre,

    -- Total movies in genre
    COUNT(*) AS total_movies,

    -- Average audience votes
    ROUND(AVG(votes),0) AS avg_user_votes,

    -- Total audience votes
    SUM(votes) AS total_votes,

    -- High engagement movies
    SUM(
        CASE
            WHEN votes >= 100000 THEN 1
            ELSE 0
        END
    ) AS highly_engaged_movies,

    -- High engagement rate
    ROUND(
        SUM(
            CASE
                WHEN votes >= 100000 THEN 1
                ELSE 0
            END
        )::NUMERIC
        / COUNT(*)::NUMERIC,
        4
    ) AS engagement_rate_pct

FROM movies
GROUP BY genre
HAVING COUNT(*) >= 5
ORDER BY avg_user_votes DESC;


-- Top 5 Highly profitable Directors
CREATE 
SELECT director, SUM(profitability) AS highly_profitable
FROM movies
GROUP BY director
ORDER BY highly_profitable DESC
LIMIT 5

-- Understanding Directors Performance
CREATE VIEW director_profitability_analysis AS

SELECT
    director,

    COUNT(*) AS total_movies,

    ROUND(AVG(profitability),2) AS avg_profitability,

    SUM(profitability) AS total_profitability,

    MAX(profitability) AS highest_profit_movie,

    SUM(
        CASE
            WHEN profitability > 0 THEN 1
            ELSE 0
        END
    ) AS profitable_movies,

    ROUND(
        SUM(
            CASE
                WHEN profitability > 0 THEN 1
                ELSE 0
            END
        )::NUMERIC
        / COUNT(*)::NUMERIC,
        4
    ) AS success_rate_pct

FROM movies
WHERE director IS NOT NULL
GROUP BY director
HAVING COUNT(*) >= 3
ORDER BY avg_profitability DESC;


-- Which Budget tier is working best amongst all
CREATE VIEW budget_tier_KPI AS
SELECT
budget_tier,
ROUND(AVG(roi_percentage),2) AS avg_roi
FROM dashboard3_optimization
GROUP BY budget_tier
ORDER BY avg_roi DESC
LIMIT 1;


-- Most Profitable Genre
CREATE OR REPLACE VIEW most_profitable_genre AS
SELECT 
genre,
SUM(profitability) AS net_profit
FROM movies
GROUP BY genre
ORDER BY net_profit DESC
LIMIT 1


-- Highly Engaged Genre
CREATE VIEW high_engagement_KPI AS
SELECT
genre,
ROUND(AVG(engagement_rate_pct),2) AS engagement
FROM genre_user_engagement
GROUP BY genre
ORDER BY engagement DESC
LIMIT 1;


-- Audience engagment and relation to profit
CREATE VIEW audience_engagement_x_profit AS
SELECT
genre,
    ROUND(
        SUM(
            CASE
                WHEN votes >= 100000 THEN 1
                ELSE 0
            END
        )::NUMERIC
        / COUNT(*)::NUMERIC,
        4
    ) AS engagement_rate_pct,
ROUND(AVG(profitability),2) AS avg_profitability,
ROUND(AVG(votes),2) AS votes
FROM movies
GROUP BY genre
ORDER BY avg_profitability DESC


-- What content actually improves
CREATE OR REPLACE VIEW recommended_content_formula AS
SELECT *
FROM (

    SELECT
        runtime_category,
        rating,
        ROUND(AVG(profitability),2) AS avg_profitability,

        ROW_NUMBER() OVER(
            PARTITION BY runtime_category
            ORDER BY AVG(profitability) DESC
        ) AS rn

    FROM movies
    GROUP BY runtime_category, rating

) t

WHERE rn <= 3;


-- SELECT * FROM movies


-- Testing (Created Table)
CREATE OR REPLACE VIEW movies_enriched AS

SELECT *,
CASE
    WHEN roi_percentage > 100
         AND engagement_rate_pct > 30
    THEN 'Increase Investment'

    WHEN roi_percentage > 50
    THEN 'Maintain'

    ELSE 'Review'
END AS recommendation

FROM (

    SELECT *,

    (gross - budget) AS net_profit,

    ROUND(
        ((gross - budget) * 100.0 /
        NULLIF(budget,0))::numeric
    ,2) AS roi_percentage,

    ROUND(
        (votes * 100.0 /
        MAX(votes) OVER())::numeric
    ,2) AS engagement_rate_pct

    FROM movies

) t;


-- At which genre and rating would generate a avg-high-profits
SELECT
genre,
rating,
ROUND(AVG(profitability),2) avg_profitability
FROM movies
GROUP BY genre,rating
ORDER BY avg_profitability DESC


-- Suggesting contents for making audience engaged
CREATE OR REPLACE VIEW recommended_engaged_content AS

SELECT *
FROM (

    SELECT
        runtime_category,
        rating,

        ROUND(
            AVG(engagement_rate_pct),2
        ) AS avg_engagement,

        ROW_NUMBER() OVER(
            PARTITION BY runtime_category
            ORDER BY AVG(engagement_rate_pct) DESC
        ) AS rn

    FROM movies_enriched
    GROUP BY runtime_category, rating

) t

WHERE rn <= 3;



-- Which director is highly profitable
CREATE VIEW high_profit_dir AS
SELECT
director,
ROUND(AVG(profitability),2)
FROM movies
GROUP BY director
ORDER BY AVG(profitability) DESC
LIMIT 1;


-- Which director is highly audience pulling
CREATE VIEW highest_audience_pulling_dir AS
SELECT
director,
SUM(votes) total_votes
FROM movies
GROUP BY director
ORDER BY total_votes DESC
LIMIT 1;


-- Which director has highest success rates
CREATE VIEW director_success_rate AS
SELECT
director,

-- Movie Analysis
COUNT(*) AS total_movies,
SUM(
	CASE
		WHEN profitability > 0 THEN 1 ELSE 0 END) AS profitable_movies,

ROUND(100.0 * 
	SUM(
		CASE WHEN profitability > 0 THEN 1 ELSE 0 END)/COUNT(*),2) AS success_rate
FROM movies
GROUP BY director
HAVING COUNT(*) >= 15
ORDER BY success_rate DESC,total_movies DESC
LIMIT 10;

-- Understanding Total Profitable Movies directed
CREATE VIEW total_profitable_movies_directed AS
SELECT
	SUM(
		CASE WHEN profitability>0 THEN 1 ELSE 0 END) AS profitable_movies
FROM movies;

-- Total directors 
CREATE VIEW active_director AS
SELECT
COUNT(DISTINCT director)
FROM movies;
