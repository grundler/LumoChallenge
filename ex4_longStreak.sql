-- Calculate longest streak and number of streaks
--  for each user in month of November

--with DA as
--(

select
    owner, act_time_local::DATE as local_date,
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
from
    activity_data
where act_time_local>='2015-11-01 00:00:00'
    and act_time_local<'2015-12-01 00:00:00'
group by owner, local_date
order by owner, local_date;
)
select owner, local_date,
  (select count(*)
  from DA AS A
  where A.activeDay <> DA.activeDay
  and A.local_date < DA.local_date
  group by owner) as RG
from DA
order by owner, local_date
;
