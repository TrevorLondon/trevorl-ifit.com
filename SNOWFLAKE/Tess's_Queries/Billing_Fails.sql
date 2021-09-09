SELECT *,lag(CHURN_TYPE, 1) OVER(partition by USER_ID order by event_ORDER asc) FROM (
SELECT
    USER_ID,
    USER_ACTIVITY_TYPE,
    USER_ACTIVITY_DESCRIPTION,
    CASE WHEN (USER_ACTIVITY_TYPE IN ('clonedAlternatePaymentMethod','unmigratedFromPagoManagement') OR USER_ACTIVITY_DESCRIPTION LIKE '%Cybersource%') THEN 'TOKEN_MIGRATION'
    WHEN USER_ACTIVITY_TYPE = 'downgradeFamilyYearlyFromNoEngagement' THEN 'NO_ENGAGEMENT_DOWNGRADE'
    WHEN USER_ACTIVITY_DESCRIPTION LIKE  ('%early fraud%') then 'autodowngrade_fraud_warning'
    WHEN (USER_ACTIVITY_TYPE = 'downgradeFromRequest' OR USER_ACTIVITY_DESCRIPTION LIKE '%previously downgraded%' OR USER_ACTIVITY_DESCRIPTION LIKE '%changed to none%' 
          OR USER_ACTIVITY_DESCRIPTION LIKE '%changed to free%' OR USER_ACTIVITY_DESCRIPTION LIKE '%billing information was cleared%' OR USER_ACTIVITY_DESCRIPTION LIKE '%cleared%') then 'VOLUNTARY_CHURN'
    WHEN (USER_ACTIVITY_DESCRIPTION LIKE '%card expired%' OR USER_ACTIVITY_DESCRIPTION LIKE '%billing info%' ) THEN 'NO_BILLING_INFO'
    WHEN USER_ACTIVITY_TYPE IN ('yearlyFailedAutoRenewal','monthlyFailedAutoRenewal') THEN 'FAILED_AUTH'
    ELSE 'OTHER' END AS CHURN_TYPE,
    ROW_NUMBER () OVER(PARTITION BY USER_ID ORDER BY UPDATED_AT DESC) AS EVENT_ORDER
FROM "ANALYTICS"."ANALYTICS_STAGING"."STAGING_USERACTIVITIES"
WHERE USER_ID IN ()
  AND UPDATED_AT >= '2021-07-01'
  ) WHERE EVENT_ORDER IN ('1','2')
