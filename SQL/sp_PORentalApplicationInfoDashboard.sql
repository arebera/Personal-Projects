USE [KeysOnboardDb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Mary Ann Rebera>
-- Create date: <24/09/2018>
-- Description:	<Given Owner Id, find rental applications info for that owner on dashboard>
-- =============================================
CREATE PROCEDURE [dbo].[sp_PORentalApplicationInfoDashboard] 
	@OwnerId int
AS
BEGIN
	SET NOCOUNT ON;
	SELECT op.OwnerId AS 'Owner Id'
		, COUNT (
				CASE WHEN ra.ApplicationStatusId = 1 AND (ra.IsViewedByOwner IS NULL OR ra.IsViewedByOwner = 0)
				THEN 'New'
				END
				) AS 'New'
		, COUNT (
				CASE WHEN ra.ApplicationStatusId = 2
				THEN 'Approved'
				END
				) AS 'Approved'
		, COUNT (
				CASE WHEN ApplicationStatusId = 1 AND IsViewedByOwner = 1
				THEN 'Pending'
				END
				) AS 'Pending'
		, COUNT (
				CASE WHEN ApplicationStatusId = 3
				THEN 'Rejected'
				END
				) AS 'Rejected'
		, COUNT (ra.Id) AS 'Total'
	FROM RentalApplication ra
		INNER JOIN RentalListing rl ON ra.RentalListingId = rl.Id
		INNER JOIN OwnerProperty op ON op.PropertyId = rl.PropertyId
	WHERE op.OwnerId = @OwnerId
	AND ra.IsActive = 1 -- Only active rental applications are considered
	AND rl.IsActive = 1 -- Only active rental listings are considered
	GROUP BY op.OwnerId
END