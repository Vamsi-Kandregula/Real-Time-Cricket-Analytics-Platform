{{ config(
    materialized='table'
) }}

WITH venue_scores AS (
    SELECT
        m.VENUE_NAME,
        m.CITY,
        s.TEAM_NAME,
        s.SCORE,
        TRY_CAST(REGEXP_SUBSTR(s.SCORE, '^[0-9]+') AS INTEGER) AS RUNS,
        ROW_NUMBER() OVER (PARTITION BY m.VENUE_NAME, m.CITY ORDER BY TRY_CAST(REGEXP_SUBSTR(s.SCORE, '^[0-9]+') AS INTEGER) DESC NULLS LAST, s.OVERS ASC) AS rn
    FROM {{ ref('fact_cricket_matches') }} m
    JOIN {{ ref('fact_match_score') }} s ON m.MATCH_ID = s.MATCH_ID
    WHERE s.SCORE IS NOT NULL
),

highest_scores AS (
    SELECT 
        VENUE_NAME, 
        CITY, 
        TEAM_NAME AS HIGHEST_SCORER_TEAM, 
        SCORE AS HIGHEST_SCORE
    FROM venue_scores
    WHERE rn = 1
),

basic_stats AS (
    SELECT
        m.VENUE_NAME,
        m.CITY,
        COUNT(DISTINCT m.MATCH_ID) AS MATCHES_PLAYED,
        ROUND(AVG(CASE WHEN s.INNINGS = '1st Innings' THEN TRY_CAST(REGEXP_SUBSTR(s.SCORE, '^[0-9]+') AS INTEGER) END)) AS AVG_INNINGS_1_SCORE,
        ROUND(AVG(CASE WHEN s.INNINGS = '2nd Innings' THEN TRY_CAST(REGEXP_SUBSTR(s.SCORE, '^[0-9]+') AS INTEGER) END)) AS AVG_INNINGS_2_SCORE
    FROM {{ ref('fact_cricket_matches') }} m
    LEFT JOIN {{ ref('fact_match_score') }} s ON m.MATCH_ID = s.MATCH_ID
    GROUP BY m.VENUE_NAME, m.CITY
)

SELECT
    b.VENUE_NAME,
    b.CITY,
    b.MATCHES_PLAYED,
    COALESCE(b.AVG_INNINGS_1_SCORE, 0) AS AVG_INNINGS_1_SCORE,
    COALESCE(b.AVG_INNINGS_2_SCORE, 0) AS AVG_INNINGS_2_SCORE,
    COALESCE(h.HIGHEST_SCORE, 'N/A') AS HIGHEST_SCORE,
    COALESCE(h.HIGHEST_SCORER_TEAM, 'N/A') AS HIGHEST_SCORER_TEAM,
    CASE 
        WHEN LOWER(TRIM(b.CITY)) IN ('london', 'chelmsford', 'bristol', 'brighton', 'leeds', 'nottingham') THEN 'England'
        WHEN LOWER(TRIM(b.CITY)) = 'stockholm' THEN 'Sweden'
        WHEN LOWER(TRIM(b.CITY)) = 'kerava' THEN 'Finland'
        WHEN LOWER(TRIM(b.CITY)) IN ('hyderabad', 'bengaluru', 'hubli', 'puducherry', 'mumbai') THEN 'India'
        WHEN LOWER(TRIM(b.CITY)) = 'galle' THEN 'Sri Lanka'
        WHEN LOWER(TRIM(b.CITY)) = 'north sound' THEN 'Antigua'
        WHEN LOWER(TRIM(b.CITY)) = 'kingston' THEN 'Jamaica'
        WHEN LOWER(TRIM(b.CITY)) = 'centurion' THEN 'South Africa'
        WHEN LOWER(TRIM(b.CITY)) = 'melbourne' THEN 'Australia'
        ELSE 'Unknown'
    END AS COUNTRY,
    CASE 
        WHEN LOWER(TRIM(b.CITY)) = 'london' AND LOWER(TRIM(b.VENUE_NAME)) LIKE '%oval%' THEN 'gb'
        WHEN LOWER(TRIM(b.CITY)) = 'london' THEN 'gb'
        WHEN LOWER(TRIM(b.CITY)) = 'chelmsford' THEN 'gb'
        WHEN LOWER(TRIM(b.CITY)) = 'bristol' THEN 'gb'
        WHEN LOWER(TRIM(b.CITY)) = 'brighton' THEN 'gb'
        WHEN LOWER(TRIM(b.CITY)) = 'leeds' THEN 'gb'
        WHEN LOWER(TRIM(b.CITY)) = 'nottingham' THEN 'gb'
        WHEN LOWER(TRIM(b.CITY)) = 'stockholm' THEN 'se'
        WHEN LOWER(TRIM(b.CITY)) = 'kerava' THEN 'fi'
        WHEN LOWER(TRIM(b.CITY)) = 'hyderabad' THEN 'in'
        WHEN LOWER(TRIM(b.CITY)) = 'bengaluru' THEN 'in'
        WHEN LOWER(TRIM(b.CITY)) = 'hubli' THEN 'in'
        WHEN LOWER(TRIM(b.CITY)) = 'puducherry' THEN 'in'
        WHEN LOWER(TRIM(b.CITY)) = 'galle' THEN 'lk'
        WHEN LOWER(TRIM(b.CITY)) = 'north sound' THEN 'ag'
        WHEN LOWER(TRIM(b.CITY)) = 'kingston' THEN 'jm'
        WHEN LOWER(TRIM(b.CITY)) = 'mumbai' THEN 'in'
        WHEN LOWER(TRIM(b.CITY)) = 'centurion' THEN 'za'
        WHEN LOWER(TRIM(b.CITY)) = 'melbourne' THEN 'au'
        ELSE 'un'
    END AS FLAG_CODE,
    CASE 
        WHEN LOWER(TRIM(b.CITY)) = 'london' THEN 51.5074
        WHEN LOWER(TRIM(b.CITY)) = 'chelmsford' THEN 51.7356
        WHEN LOWER(TRIM(b.CITY)) = 'bristol' THEN 51.4545
        WHEN LOWER(TRIM(b.CITY)) = 'brighton' THEN 50.8225
        WHEN LOWER(TRIM(b.CITY)) = 'leeds' THEN 53.8008
        WHEN LOWER(TRIM(b.CITY)) = 'nottingham' THEN 52.9548
        WHEN LOWER(TRIM(b.CITY)) = 'stockholm' THEN 59.3293
        WHEN LOWER(TRIM(b.CITY)) = 'kerava' THEN 60.4034
        WHEN LOWER(TRIM(b.CITY)) = 'hyderabad' THEN 17.3850
        WHEN LOWER(TRIM(b.CITY)) = 'bengaluru' THEN 12.9716
        WHEN LOWER(TRIM(b.CITY)) = 'hubli' THEN 15.3647
        WHEN LOWER(TRIM(b.CITY)) = 'puducherry' THEN 11.9416
        WHEN LOWER(TRIM(b.CITY)) = 'galle' THEN 6.0535
        WHEN LOWER(TRIM(b.CITY)) = 'north sound' THEN 17.1189
        WHEN LOWER(TRIM(b.CITY)) = 'kingston' THEN 17.9716
        WHEN LOWER(TRIM(b.CITY)) = 'mumbai' THEN 18.9750
        WHEN LOWER(TRIM(b.CITY)) = 'centurion' THEN -25.8640
        WHEN LOWER(TRIM(b.CITY)) = 'melbourne' THEN -37.8136
        ELSE 0.0
    END AS LATITUDE,
    CASE 
        WHEN LOWER(TRIM(b.CITY)) = 'london' THEN -0.1278
        WHEN LOWER(TRIM(b.CITY)) = 'chelmsford' THEN 0.4685
        WHEN LOWER(TRIM(b.CITY)) = 'bristol' THEN -2.5879
        WHEN LOWER(TRIM(b.CITY)) = 'brighton' THEN -0.1372
        WHEN LOWER(TRIM(b.CITY)) = 'leeds' THEN -1.5491
        WHEN LOWER(TRIM(b.CITY)) = 'nottingham' THEN -1.1581
        WHEN LOWER(TRIM(b.CITY)) = 'stockholm' THEN 18.0686
        WHEN LOWER(TRIM(b.CITY)) = 'kerava' THEN 25.1018
        WHEN LOWER(TRIM(b.CITY)) = 'hyderabad' THEN 78.4867
        WHEN LOWER(TRIM(b.CITY)) = 'bengaluru' THEN 77.5946
        WHEN LOWER(TRIM(b.CITY)) = 'hubli' THEN 75.1240
        WHEN LOWER(TRIM(b.CITY)) = 'puducherry' THEN 79.8083
        WHEN LOWER(TRIM(b.CITY)) = 'galle' THEN 80.2210
        WHEN LOWER(TRIM(b.CITY)) = 'north sound' THEN -61.7617
        WHEN LOWER(TRIM(b.CITY)) = 'kingston' THEN -76.7936
        WHEN LOWER(TRIM(b.CITY)) = 'mumbai' THEN 72.8258
        WHEN LOWER(TRIM(b.CITY)) = 'centurion' THEN 28.1953
        WHEN LOWER(TRIM(b.CITY)) = 'melbourne' THEN 144.9631
        ELSE 0.0
    END AS LONGITUDE,
    CASE 
        WHEN LOWER(TRIM(b.CITY)) = 'london' AND LOWER(TRIM(b.VENUE_NAME)) LIKE '%oval%' THEN 125
        WHEN LOWER(TRIM(b.CITY)) = 'london' THEN 120
        WHEN LOWER(TRIM(b.CITY)) = 'chelmsford' THEN 140
        WHEN LOWER(TRIM(b.CITY)) = 'bristol' THEN 115
        WHEN LOWER(TRIM(b.CITY)) = 'brighton' THEN 130
        WHEN LOWER(TRIM(b.CITY)) = 'leeds' THEN 125
        WHEN LOWER(TRIM(b.CITY)) = 'nottingham' THEN 135
        WHEN LOWER(TRIM(b.CITY)) = 'stockholm' THEN 160
        WHEN LOWER(TRIM(b.CITY)) = 'kerava' THEN 175
        WHEN LOWER(TRIM(b.CITY)) = 'hyderabad' THEN 290
        WHEN LOWER(TRIM(b.CITY)) = 'bengaluru' THEN 280
        WHEN LOWER(TRIM(b.CITY)) = 'hubli' THEN 270
        WHEN LOWER(TRIM(b.CITY)) = 'puducherry' THEN 285
        WHEN LOWER(TRIM(b.CITY)) = 'galle' THEN 282
        WHEN LOWER(TRIM(b.CITY)) = 'north sound' THEN 70
        WHEN LOWER(TRIM(b.CITY)) = 'kingston' THEN 60
        WHEN LOWER(TRIM(b.CITY)) = 'mumbai' THEN 280
        WHEN LOWER(TRIM(b.CITY)) = 'centurion' THEN 210
        WHEN LOWER(TRIM(b.CITY)) = 'melbourne' THEN 420
        ELSE 250
    END AS MAP_X,
    CASE 
        WHEN LOWER(TRIM(b.CITY)) = 'london' AND LOWER(TRIM(b.VENUE_NAME)) LIKE '%oval%' THEN 85
        WHEN LOWER(TRIM(b.CITY)) = 'london' THEN 80
        WHEN LOWER(TRIM(b.CITY)) = 'chelmsford' THEN 90
        WHEN LOWER(TRIM(b.CITY)) = 'bristol' THEN 95
        WHEN LOWER(TRIM(b.CITY)) = 'brighton' THEN 95
        WHEN LOWER(TRIM(b.CITY)) = 'leeds' THEN 70
        WHEN LOWER(TRIM(b.CITY)) = 'nottingham' THEN 75
        WHEN LOWER(TRIM(b.CITY)) = 'stockholm' THEN 60
        WHEN LOWER(TRIM(b.CITY)) = 'kerava' THEN 55
        WHEN LOWER(TRIM(b.CITY)) = 'hyderabad' THEN 150
        WHEN LOWER(TRIM(b.CITY)) = 'bengaluru' THEN 170
        WHEN LOWER(TRIM(b.CITY)) = 'hubli' THEN 165
        WHEN LOWER(TRIM(b.CITY)) = 'puducherry' THEN 175
        WHEN LOWER(TRIM(b.CITY)) = 'galle' THEN 190
        WHEN LOWER(TRIM(b.CITY)) = 'north sound' THEN 135
        WHEN LOWER(TRIM(b.CITY)) = 'kingston' THEN 140
        WHEN LOWER(TRIM(b.CITY)) = 'mumbai' THEN 160
        WHEN LOWER(TRIM(b.CITY)) = 'centurion' THEN 220
        WHEN LOWER(TRIM(b.CITY)) = 'melbourne' THEN 240
        ELSE 150
    END AS MAP_Y
FROM basic_stats b
LEFT JOIN highest_scores h ON b.VENUE_NAME = h.VENUE_NAME AND b.CITY = h.CITY
