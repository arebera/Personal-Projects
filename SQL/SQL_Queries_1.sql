USE KeysOnboardDb

/* Query a - List of all property names and their property id’s for Owner Id: 1426 */
SELECT OP.PropertyId, P.Name AS PropertyName
FROM OwnerProperty OP
INNER JOIN Property P ON OP.PropertyId = P.Id
WHERE OP.OwnerId = 1426


/* Query b - Current home value for each property in (a) */
SELECT PHV.PropertyId, PHV.Value
FROM PropertyHomeValue PHV
INNER JOIN OwnerProperty OP ON PHV.PropertyId = OP.PropertyId
WHERE OP.OwnerId = 1426 AND PHV.IsActive = 1


/*Query c i) - Sum of all payments from tenancy start date to end date for each property in (a) */
SELECT prp.propertyid AS 'Property ID', 
FORMAT((SUM(CASE 
	WHEN prp.FrequencyType = 1
	THEN (prp.Amount * (DATEDIFF(ww,tp.StartDate, tp.EndDate) + 1))
	WHEN prp.FrequencyType = 2
	THEN (prp.Amount * (DATEDIFF(ww,tp.StartDate, tp.EndDate) + 1)/2.0)
	WHEN prp.FrequencyType = 3
	THEN (prp.Amount * (DATEDIFF(mm,tp.StartDate, tp.EndDate) + 1))
	END)),'C')
	AS 'Total Payment'
FROM PropertyRentalPayment prp
	INNER JOIN TargetRentType trt ON prp.FrequencyType = trt.Id
	INNER JOIN TenantProperty tp ON tp.PropertyId = prp.PropertyId
WHERE prp.PropertyId 
IN 
	(SELECT OP.PropertyId FROM OwnerProperty OP
	INNER JOIN Property P ON OP.PropertyId = P.Id
	WHERE OP.OwnerId = 1426) 
GROUP BY prp.PropertyId 

/* Query c ii) Sum of all repayments from start date to end date*/
SELECT op.PropertyId AS 'Property ID', 
	FORMAT(SUM(CASE pr.FrequencyType
		WHEN 1 THEN pr.Amount * (DATEDIFF(ww,pr.StartDate,pr.EndDate)+1)
		WHEN 2 THEN pr.Amount * ((DATEDIFF(ww,pr.StartDate,pr.EndDate)+1)/2.0)
		WHEN 3 THEN pr.Amount * (DATEDIFF(mm,pr.StartDate,pr.EndDate)+1)
		END),'C') AS 'Total Repayment Amount'
FROM PropertyRepayment pr
	INNER JOIN OwnerProperty op ON pr.PropertyId = op.PropertyId
WHERE op.OwnerId = 1426
GROUP BY op.PropertyId


/*Query c iii) To find the yield of a property calculated as (Total Payment / Property Price) * 100 */
WITH ctePropertyPayment (PropertyId, PaymentAmount)
AS
(
	SELECT prp.propertyid AS 'PropertyID', 
	(
		SUM
			(CASE 
				WHEN prp.FrequencyType = 1
				THEN (prp.Amount * (DATEDIFF(ww,tp.StartDate, tp.EndDate) + 1))
				WHEN prp.FrequencyType = 2
				THEN (prp.Amount * (DATEDIFF(ww,tp.StartDate, tp.EndDate) + 1)/2.0)
				WHEN prp.FrequencyType = 3
				THEN (prp.Amount * (DATEDIFF(mm,tp.StartDate, tp.EndDate) + 1))
			END)
	) AS 'TotalPayment'
	
	FROM PropertyRentalPayment prp
		INNER JOIN TargetRentType trt ON prp.FrequencyType = trt.Id
		INNER JOIN TenantProperty tp ON tp.PropertyId = prp.PropertyId
	WHERE prp.PropertyId 
	IN 
		(SELECT op.PropertyId FROM OwnerProperty op
		INNER JOIN Property p ON op.PropertyId = p.Id
		WHERE op.OwnerId = 1426) 
	GROUP BY prp.PropertyId
)

SELECT pp.PropertyId AS 'Property Id'
	,pf.PurchasePrice AS 'Purchase Price'
	, pp.PaymentAmount AS 'Payment Amount'
	, FORMAT((pp.PaymentAmount/pf.PurchasePrice),'P') AS 'Yield' 
FROM ctePropertyPayment pp
	INNER JOIN PropertyFinance pf ON pf.PropertyId = pp.PropertyId


/* Query d) Available jobs in the marketplace*/
SELECT OwnerId, PropertyID, JobRequestId,JobDescription, MaxBudget 
FROM Job j
WHERE J.JobStatusId = 1
AND J.OwnerId IS NOT NULL


/* Query e) List of current tenants and rental amount for properties in (a) */
SELECT tp.PropertyId, pro.Name AS 'Property Name', 
t.Id AS 'Tenant ID', per.FirstName AS 'First Name', per.LastName AS 'Last Name', 
prp.Amount AS 'Rent Amount', trt.Name AS Frequency
FROM Property pro
	INNER JOIN PropertyRentalPayment prp ON prp.PropertyId = pro.Id
	INNER JOIN TargetRentType trt ON trt.Id = prp.FrequencyType
	INNER JOIN TenantProperty tp ON pro.Id = tp.PropertyId
	INNER JOIN Tenant t ON T.Id = tp.TenantId
	INNER JOIN Person per ON per.Id = t.Id
WHERE tp.PropertyId
IN 
	(SELECT op.PropertyId FROM OwnerProperty op
	INNER JOIN Property p ON op.PropertyId = p.Id
	WHERE op.OwnerId = 1426)