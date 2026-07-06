SELECT
    m.MATCH_ID,
    m.MATCH_NAME,
    m.MATCHTYPE,
    m.MATCH_DATE,
    m.MATCH_TIME,
    m.RESULT_TYPE,   
    m.STATUS,

    s.TEAM_NAME,

    CASE
        WHEN s.INNINGS_ORDER = 1 THEN '1st Innings'
        WHEN s.INNINGS_ORDER = 2 THEN '2nd Innings'
        WHEN s.INNINGS_ORDER = 3 THEN '3rd Innings'
        WHEN s.INNINGS_ORDER = 4 THEN '4th Innings'
    END AS INNINGS,

    CONCAT(s.RUNS, '/', s.WICKETS) AS SCORE,

    s.OVERS,

    CASE
        WHEN s.OVERS > 0
        THEN ROUND(s.RUNS / s.OVERS, 2)
        ELSE NULL
    END AS RUN_RATE

FROM {{ ref('fact_cricket_matches') }} m
JOIN CRICKET_SCORE s
    ON m.MATCH_ID = s.MATCH_ID

ORDER BY
    m.MATCH_DATE DESC,
    m.MATCH_NAME,
    s.INNINGS_ORDER