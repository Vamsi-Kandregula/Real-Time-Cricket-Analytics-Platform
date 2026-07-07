with source as (

    select *
    from {{ source('cricket', 'CRICKET_MATCHES') }}

),

deduped as (

    select *,
           row_number() over (
               partition by MATCH_ID
               order by FETCH_DATE desc
           ) as RN
    from source

)

select
    MATCH_ID,
    TEAM_1,
    TEAM_2,
    MATCH_NAME,
    MATCHTYPE,
    STATUS,

    CAST(
        CONVERT_TIMEZONE(
            'UTC',
            'Asia/Kolkata',
            DATETIMEGMT
        ) AS DATE
    ) AS MATCH_DATE,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'UTC',
            'Asia/Kolkata',
            DATETIMEGMT
        ),
        'HH24:MI'
    ) AS MATCH_TIME,

    VENUE_NAME,
    CITY,
    MATCHSTARTED,
    MATCHENDED,
    FETCH_DATE

from deduped
where rn = 1