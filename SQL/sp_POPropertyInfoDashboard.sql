USE [KeysOnboardDb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Mary Ann Rebera>
-- Create date: <20/09/2018>
-- Description:	<Given Owner Id, find property info for that owner on dashboard>
-- =============================================
CREATE PROCEDURE [dbo].[sp_POPropertyInfoDashboard] 
	@OwnerId int
AS
BEGIN
	SET NOCOUNT ON;
	/* CTE to extract all properties of a specific owner */
    WITH cteOwnerProperty(OwnerId, PropertyId)
	AS
		(
		SELECT OwnerId
			,PropertyId
		FROM OwnerProperty
		--WHERE OwnerId = @OwnerId
		)
	
	SELECT cop.OwnerId,
	COUNT
		(CASE 
			WHEN tp.StartDate <= getdate() AND (tp.EndDate >= getdate() OR tp.EndDate IS NULL)
			THEN 'Occupied'
		END) AS [Occupied]
	,COUNT 
		(CASE
			WHEN getdate() <= tp.StartDate OR getdate() >= tp.EndDate
			THEN 'Vacant'
		END) AS [Vacant]
	,COUNT(cop.PropertyId) AS [Total]
	FROM TenantProperty tp
		INNER JOIN cteOwnerProperty cop on tp.PropertyId = cop.PropertyId
	GROUP BY cop.OwnerId
END
