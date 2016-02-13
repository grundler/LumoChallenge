-- Calculate average and 95% CI bounds for posture score by gender
--      (CG+SG+STG)/(CG+SG+STG+CBS+CF+SBS+SBF+SBL+SBR+STBF+STBL+STBR+STBS)
--  during month of October

WITH collatedActivityData AS
    (SELECT
        owner,
        --act_time_local::DATE as local_date,
        sum(CASE
            WHEN act_type IN ('SG','STG','CG') THEN act_value::numeric(20)
            ELSE 0. END) AS gp,
        sum(CASE
            WHEN act_type IN ('SG','STG','CG','CBS','CBF','SBS','SBF','SBL','SBR','STBF','STBL','STBR','STBS') THEN act_value::numeric(20)
            ELSE 0. END) AS tp
    FROM activity_data
    WHERE act_time_local >= '2015-10-01 00:00:00'
        AND act_time_local < '2015-11-01 00:00:00'
    GROUP BY owner
    )
SELECT
    lower(substring(gender from 1 for 1)) as gn,
    avg(gp/nullif(tp,0))-1.96*stddev(gp/nullif(tp,0))/sqrt(count(*)) as lower_bound,
    avg(gp/nullif(tp,0)) AS avg_posture,
    avg(gp/nullif(tp,0))+1.96*stddev(gp/nullif(tp,0))/sqrt(count(*)) AS upper_bound
FROM
    owner_metadata JOIN collatedActivityData ON (owner_metadata.owner = collatedActivityData.owner)
GROUP BY gn
;

select gn, 
  avg(gp/nullif(tp,0))-1.96*stddev(gp/nullif(tp,0))/sqrt(count(*)) as lower_bound,
  avg(gp/nullif(tp,0)) AS avg_posture,
  avg(gp/nullif(tp,0))+1.96*stddev(gp/nullif(tp,0))/sqrt(count(*)) AS upper_bound
from
(select lower(substring(gender from 1 for 1)) as gn, act_time_local::DATE as local_date,
        sum(CASE
            WHEN act_type IN ('SG','STG','CG') THEN act_value::numeric(20)
            ELSE 0. END) AS gp,
        sum(CASE
            WHEN act_type IN ('SG','STG','CG','CBS','CBF','SBS','SBF','SBL','SBR','STBF','STBL','STBR','STBS') THEN act_value::numeric(20)
            ELSE 0. END) AS tp
from owner_metadata join activity_data on (owner_metadata.owner = activity_data.owner)
    WHERE act_time_local >= '2015-10-01 00:00:00'
        AND act_time_local < '2015-11-01 00:00:00'
    group by gn, local_date
    ) t
group by gn;

