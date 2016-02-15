-- Calculate the correlation between 
--      coach vibration buzzes (C_CVBUZZ) and
--      good posture time (SG+STG+CG)
--  per user per day in the month of December

WITH
collatedData AS
    (SELECT
        owner,
        act_time_local,
        sum(CASE
            WHEN act_type='C_CVBUZZ' THEN act_value::numeric(20)
            ELSE NULL END) AS c_cvbuzz,
        sum(CASE
            WHEN act_type IN ('SG','STG','CG') THEN act_value::numeric(20)
            ELSE NULL END) AS gp
    FROM activity_data
    WHERE act_time_local >= '2015-12-01 00:00:00' -- for our December requirement
        AND act_time_local < '2016-01-01 00:00:00'
        AND act_type IN ('C_CVBUZZ','SG','STG','CG')
        AND owner <> '' -- just ignore unknown owners
        AND act_value>=0 -- negative values make no sense, ignore as bad data
    GROUP BY owner, act_time_local
    ),
cleanedData as
    (SELECT *
    FROM collatedData
    WHERE c_cvbuzz IS NOT NULL
        AND gp IS NOT NULL
    )
SELECT
    owner, local_date,
    -- nullif returns null if the denominator == 0
    (n*sumBGP - sumBuzz*sumGP) / nullif(sqrt((n*sumBuzz2 - sumBuzz*sumBuzz)*(n*sumGP2 - sumGP*sumGP)),0) AS corr_ab
FROM
    (SELECT owner, act_time_local::DATE AS local_date,
        sum(c_cvbuzz) AS sumBuzz,
        sum(gp) AS sumGP,
        sum(c_cvbuzz*c_cvbuzz) AS sumBuzz2,
        sum(gp*gp) AS sumGP2,
        sum(c_cvbuzz*gp) AS sumBGP,
        count(*) AS n
    FROM
    cleanedData
    GROUP BY owner, act_time_local::DATE
    ) dailySums
ORDER BY owner, local_date
;
