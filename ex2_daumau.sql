-- Calculate the DAU/MAU for every day in the month of October

WITH mau AS 
(SELECT date_trunc('month', act_time_local) AS mnth, count(DISTINCT owner) AS ct FROM activity_data GROUP BY mnth)
SELECT
    act_time_local::DATE AS local_date,
    count(DISTINCT owner) AS dau,
    max(mau.ct) --should only be one value/month, but need an aggregate function
FROM 
    activity_data JOIN mau ON (date_trunc('month',act_time_local)=mau.mnth)
WHERE
    act_time_local>='2015-10-01 00:00:00'
    AND act_time_local<'2015-11-01 00:00:00'
GROUP BY act_time_local::DATE
ORDER BY act_time_local::DATE
;
