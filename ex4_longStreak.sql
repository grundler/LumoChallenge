-- Calculate longest streak and number of streaks
--  for each user in month of November

-- create some temp tables
WITH
-- table of days, showing whether owner was active or not
activeTable AS
    (SELECT
        owner, act_time_local::DATE AS local_date,
        CASE
            WHEN
                sum(CASE
                    WHEN act_type='C_STEPS' THEN act_value
                    ELSE 0. END) < 500 THEN 0
            WHEN
                sum(CASE
                    WHEN act_type IN ('SG','STG','CG') THEN act_value
                    ELSE 0. END)*5./100. < 30 THEN 0
            ELSE 1
            END AS activeDay
    FROM
        activity_data
    WHERE act_time_local>='2015-11-01 00:00:00' -- for our November requirement
        AND act_time_local<'2015-12-01 00:00:00'
        AND owner <> '' -- just ignore unkown owners, though could use sensor_id as proxy
    GROUP BY owner, local_date
    ),
-- list of active days and how long since previous active day
actRel AS
    (SELECT
        owner, local_date,
        local_date - lag(local_date)
            OVER (PARTITION BY owner ORDER BY local_date) AS nDaysSinceActive
    FROM
      (SELECT
        owner, local_date
        FROM activeTable
        WHERE activeDay=1
        )
    ),
-- create grouping of active days
activeGroups AS
    (SELECT owner, local_date,
        --nDaysSinceActive,
        count(CASE
                WHEN nDaysSinceActive IS NULL THEN 1
                WHEN nDaysSinceActive <> 1 THEN 1
                ELSE NULL
                END)
            OVER (PARTITION BY owner ORDER BY local_date ROWS UNBOUNDED PRECEDING) AS ag
    FROM actRel
    )

-- This is what we're trying to get
SELECT owner,
    (CASE
        WHEN max(stLen) < 2 THEN 0
        ELSE max(stLen)
        END) AS longest_streak,
    count(CASE
            WHEN stLen>1 THEN 1
            ELSE NULL
            END) AS n_streaks
FROM
    -- list of streaks and their lengths
    (SELECT owner, min(local_date) AS startDate,
        count(*) AS stLen
    FROM activeGroups
    GROUP BY owner, ag)
GROUP BY owner
ORDER BY owner
;

--
-- Find active days, so I can test whether output of above makes sense
--

-- select
--     owner, act_time_local::DATE as local_date,
--     CASE
--         WHEN
--             sum(CASE
--                 WHEN act_type='C_STEPS' THEN act_value
--                 ELSE 0. END) < 500 THEN 0
--         WHEN
--             sum(CASE
--                 WHEN act_type IN ('SG','STG','CG') THEN act_value
--                 ELSE 0. END)*5./100. < 30 THEN 0
--         ELSE 1
--         END AS activeDay
-- from
--     activity_data
-- where act_time_local>='2015-11-01 00:00:00'
--     and act_time_local<'2015-12-01 00:00:00'
-- group by owner, local_date
-- order by owner, local_date;
