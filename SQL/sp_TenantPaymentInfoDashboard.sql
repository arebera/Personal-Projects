USE [KeysOnboardDb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Mary Ann Rebera>
-- Create date: <25/09/2018>
-- Description:	<Given Tenant Id, find payment details for that tenant on dashboard>
-- =============================================
CREATE PROCEDURE [dbo].[sp_TenantPaymentInfoDashboard] 
	@TenantId int
AS
BEGIN
	SET NOCOUNT ON;
	SELECT tp.TenantId AS 'Tenant Id'
	, per.FirstName + ' ' + per.LastName AS 'Landlord'
	, addr.Number + ' ' + addr.Street + ', ' + addr.Suburb + ', ' + addr.City AS 'Address'
	, tp.PaymentStartDate 'Payment Start Date'
	, FORMAT(tp.PaymentAmount,'C') AS 'Rent'
		/* Display frequency based on the frequency id */
	, CASE WHEN tp.PaymentFrequencyId = 1
			THEN 'Weekly'
		WHEN tp.PaymentFrequencyId = 2
			THEN 'Fortnightly'
		WHEN tp.PaymentFrequencyId = 3
			THEN 'Monthly'
	  END 
	  AS 'Payment Frequency'
		/* If payment start date is in the future, display start date as due date */
	, CASE WHEN (tp.paymentStartDate >= GETDATE())
			THEN tp.paymentStartDate
	/* If payment start date is less than current date, calculate due date based on the payment frequency */
	  ELSE
		(CASE 
			WHEN tp.PaymentFrequencyId = 1
				THEN 
					(CASE -- Current date should be considered as due date
						WHEN DATEPART(DAY,GETDATE()) = DATEPART(DAY,(DATEADD(WEEK,(DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7),tp.PaymentStartDate)))
						THEN DATEADD(WEEK,(DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7),tp.PaymentStartDate)
						ELSE DATEADD(WEEK,(DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7)+1,tp.PaymentStartDate)
					END)
			WHEN tp.PaymentFrequencyId = 2
				THEN 
					/* To determine the next fortnight */
					(CASE WHEN (DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7) % 2 = 0
						THEN 
							(CASE WHEN DATEPART(DAY,GETDATE()) = DATEPART(DAY,(DATEADD(WEEK,(DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7),tp.PaymentStartDate)))
								THEN DATEADD(WEEK,(DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7),tp.PaymentStartDate)					
								ELSE DATEADD(WEEK,(DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7)+2,tp.PaymentStartDate)
							END)
						ELSE
							(CASE WHEN DATEPART(DAY,GETDATE()) = DATEPART(DAY,(DATEADD(WEEK,(DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7),tp.PaymentStartDate)))
								THEN  DATEADD(WEEK,(DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7),tp.PaymentStartDate)	
								ELSE DATEADD(WEEK,(DATEDIFF(DAY, tp.PaymentStartDate, GETDATE())/7)+1,tp.PaymentStartDate)
							END)
					END)
			WHEN tp.PaymentFrequencyId = 3
				THEN -- Validation for dates before and after current date
					(CASE WHEN DATEPART(DAY,GETDATE()) > DATEPART(DAY,tp.PaymentStartDate)
						THEN DATEADD(MONTH, DATEDIFF(MONTH,tp.PaymentStartDate,GETDATE())+1,tp.PaymentStartDate)
						ELSE DATEADD(MONTH, DATEDIFF(MONTH,tp.PaymentStartDate,GETDATE()),tp.PaymentStartDate)
					END)
		END)
	  END
	  AS 'Payment Due Date'

	FROM TenantProperty tp
		INNER JOIN Property pro ON pro.Id = tp.PropertyId
		INNER JOIN Address addr ON addr.AddressId = pro.AddressId
		INNER JOIN OwnerProperty op ON op.PropertyId = tp.PropertyId
		INNER JOIN Person per ON per.Id = op.OwnerId
	WHERE tp.IsActive = 1 -- only considering active tenancies
	AND tp.TenantId = @TenantId
	ORDER BY tp.PaymentStartDate DESC
END