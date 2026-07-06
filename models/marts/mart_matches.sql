{{ config(
    materialized='table'
) }}

WITH matches AS (
    SELECT * FROM {{ ref('fact_cricket_matches') }}
),

scores AS (
    SELECT * FROM {{ ref('fact_match_score') }}
)

SELECT
    m.MATCH_ID,
    m.TEAM_1,
    m.TEAM_2,
    m.MATCH_NAME,
    m.MATCHTYPE,
    m.STATUS,
    m.WINNER,
    m.RESULT_TYPE,
    m.WIN_MARGIN,
    m.MATCH_DATE,
    m.MATCH_TIME,
    m.VENUE_NAME,
    m.CITY,
    m.MATCHSTARTED,
    m.MATCHENDED,
    m.FETCH_DATE,
    
    -- Score details for Team 1
    MAX(CASE WHEN LOWER(TRIM(s.TEAM_NAME)) = LOWER(TRIM(m.TEAM_1)) THEN s.SCORE END) AS TEAM_1_SCORE,
    MAX(CASE WHEN LOWER(TRIM(s.TEAM_NAME)) = LOWER(TRIM(m.TEAM_1)) THEN s.OVERS END) AS TEAM_1_OVERS,
    MAX(CASE WHEN LOWER(TRIM(s.TEAM_NAME)) = LOWER(TRIM(m.TEAM_1)) THEN s.RUN_RATE END) AS TEAM_1_RUN_RATE,
    
    -- Score details for Team 2
    MAX(CASE WHEN LOWER(TRIM(s.TEAM_NAME)) = LOWER(TRIM(m.TEAM_2)) THEN s.SCORE END) AS TEAM_2_SCORE,
    MAX(CASE WHEN LOWER(TRIM(s.TEAM_NAME)) = LOWER(TRIM(m.TEAM_2)) THEN s.OVERS END) AS TEAM_2_OVERS,
    MAX(CASE WHEN LOWER(TRIM(s.TEAM_NAME)) = LOWER(TRIM(m.TEAM_2)) THEN s.RUN_RATE END) AS TEAM_2_RUN_RATE,
    
    -- Current progress overs for live matches (use the most recent innings overs)
    COALESCE(
        MAX(CASE WHEN s.INNINGS = '4th Innings' THEN s.OVERS END),
        MAX(CASE WHEN s.INNINGS = '3rd Innings' THEN s.OVERS END),
        MAX(CASE WHEN s.INNINGS = '2nd Innings' THEN s.OVERS END),
        MAX(CASE WHEN s.INNINGS = '1st Innings' THEN s.OVERS END)
    ) AS CURRENT_OVERS

FROM matches m
LEFT JOIN scores s ON m.MATCH_ID = s.MATCH_ID
GROUP BY
    m.MATCH_ID,
    m.TEAM_1,
    m.TEAM_2,
    m.MATCH_NAME,
    m.MATCHTYPE,
    m.STATUS,
    m.WINNER,
    m.RESULT_TYPE,
    m.WIN_MARGIN,
    m.MATCH_DATE,
    m.MATCH_TIME,
    m.VENUE_NAME,
    m.CITY,
    m.MATCHSTARTED,
    m.MATCHENDED,
    m.FETCH_DATE
