-- Calculate average and 95% CI bounds for posture score by gender
--      (CG+SG+STG)/(CG+SG+STG+CBS+CF+SBS+SBF+SBL+SBR+STBF+STBL+STBR+STBS)
--  during month of October

-- ndf = 30 (31 days in october - 1)
-- z_0.025=1.96
-- t_0.025 w/ ndf(30) = 2.042
SELECT gn AS gender,
    avg(gp/nullif(tp,0))-2.042*stddev(gp/nullif(tp,0))/sqrt(count(*)) AS lower_bound,
    avg(gp/nullif(tp,0)) AS avg_posture,
    avg(gp/nullif(tp,0))+2.042*stddev(gp/nullif(tp,0))/sqrt(count(*)) AS upper_bound
FROM
    (
    SELECT lower(substring(gender FROM 1 FOR 1)) AS gn, act_time_local::DATE AS local_date,
        sum(CASE
            WHEN act_type IN ('SG','STG','CG') THEN act_value::numeric(20)
            ELSE 0. END) AS gp,
        sum(CASE
            WHEN act_type IN
              ('SG','STG','CG','CBS','CBF','SBS','SBF','SBL','SBR','STBF','STBL','STBR','STBS')
              THEN act_value::numeric(20)
            ELSE 0. END) AS tp
    FROM owner_metadata JOIN activity_data ON (owner_metadata.owner = activity_data.owner)
    WHERE act_time_local >= '2015-10-01 00:00:00'
        AND act_time_local < '2015-11-01 00:00:00'
        AND act_value>=0 --negative values are obviously bad, ignore
    GROUP BY gn, local_date
    ) t
WHERE gn <> ''
GROUP BY gn;

