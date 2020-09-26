/* Table, view, function, and procedure drops for re-executability */

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Unit')
BEGIN
	DROP TABLE Unit
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Model')
BEGIN
	DROP TABLE Model
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Color')
BEGIN
	DROP TABLE Color
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Interior')
BEGIN
	DROP TABLE Interior
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Clients')
BEGIN
	DROP TABLE Clients
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name  = 'addColor')
BEGIN
	DROP PROCEDURE addColor
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name  = 'addInterior')
BEGIN
	DROP PROCEDURE addInterior
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name  = 'addModel')
BEGIN
	DROP PROCEDURE addModel
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name  = 'addUnit')
BEGIN
	DROP PROCEDURE addUnit
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name  = 'sellUnit')
BEGIN
	DROP PROCEDURE sellUnit
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name = 'addClient')
BEGIN
	DROP PROCEDURE addClient
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name = 'tagUnit')
BEGIN
	DROP PROCEDURE tagUnit
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name = 'Month_Sales')
BEGIN
	DROP PROCEDURE Month_Sales
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name = 'Quarter_Sales')
BEGIN
	DROP PROCEDURE Quarter_Sales
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name ='Annual_Sales')
BEGIN
	DROP PROCEDURE Annual_Sales
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name = 'Is_Sold')
BEGIN
	DROP PROCEDURE Is_Sold
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name = 'Available')
BEGIN
	DROP PROCEDURE Available
END
GO

DROP VIEW IF EXISTS dbo.Inv_AverageLotLife
DROP VIEW IF EXISTS dbo.Inv_DefectCounts
DROP VIEW IF EXISTS dbo.Sold_AverageLotLife
DROP VIEW IF EXISTS dbo.Sold_DefectCounts
DROP VIEW IF EXISTS dbo.Sold_Clients_forMarketing
DROP VIEW IF EXISTS dbo.Active_Inventory
GO

DROP FUNCTION IF EXISTS dbo.Inv_ModelLotLife
DROP FUNCTION IF EXISTS dbo.Inv_ModelDefects
DROP FUNCTION IF EXISTS dbo.Sold_ModelLotLife
DROP FUNCTION IF EXISTS dbo.Sold_Modeldefects

/*
	Table creation follows. Several are needed for various purposes, including dependancy, normalization, and reporting.
*/

CREATE TABLE Model
(
	model_name VARCHAR(30) not null 
	CONSTRAINT PK_model PRIMARY KEY (model_name)
	-- Model name is used as primary key for ease of entry and instance creation
)

CREATE TABLE Color
(
	color_code varchar(3) NOT NULL,
	color_name varchar(30) NOT NULL,
	-- Color code is used as primary key for the same reason as in the model table
	CONSTRAINT PK_color PRIMARY KEY (color_code),
)
GO

CREATE TABLE Interior
(
	interior_code varchar(3) NOT NULL,
	interior_name varchar(30) NOT NULL,
	-- Same consistent reason for using interior code as PK
	CONSTRAINT PK_interior PRIMARY KEY (interior_code),
)
GO

CREATE TABLE Clients -- It would be helpful to have all of our clients' information for reference and marketing purposes 
(
	client_ID int IDENTITY,
	client_surname varchar(30) NOT NULL,
	client_forename varchar(30) NOT NULL,
	client_street varchar(50) NOT NULL,
	client_city varchar(20) NOT NULL,
	client_state varchar(2) NOT NULL,
	client_zip varchar(5) NOT NULL,
	client_email varchar(50) NOT NULL UNIQUE,
	client_telephone varchar(10) NOT NULL UNIQUE,
	CONSTRAINT PK_client PRIMARY KEY (client_ID),
)
GO
	
CREATE TABLE Unit -- this is our main table for inventory
(
	unit_id int IDENTITY,
	model_year varchar(4) NOT NULL,
	model_name varchar(30) NOT NULL,
	VIN varchar(17) NOT NULL,
	color_code varchar(3) NOT NULL,
	interior_code varchar(3) NOT NULL,
	MSRP int NOT NULL,
	wholesale_date date NOT NULL,
	stock_number varchar(20), -- Note that this can be null at first. This is because we may need to enter vehicles into inventory before stock number assignment, however the stock number is required to process a sale
	client_ID int, -- Only created when the vehicle is in the sale process (tagged)
	sale_date date, -- This is entered when a vehicle is intered into the sale process (tagged) and subsequently moved to the sold table
	sold bit DEFAULT 0, -- Indicates if vehicle sale has been finalized
	CONSTRAINT PK_unit PRIMARY KEY (unit_id),
	CONSTRAINT FK_model FOREIGN KEY (model_name) REFERENCES Model(model_name),
	CONSTRAINT FK_color FOREIGN KEY (color_code) REFERENCES Color(color_code),
	CONSTRAINT FK_interior FOREIGN KEY (interior_code) REFERENCES Interior(interior_code),
	CONSTRAINT FK_unit_client FOREIGN KEY (client_ID) REFERENCES Clients(client_ID),
	CONSTRAINT U1_unit UNIQUE (VIN), 
	CONSTRAINT U2_unit UNIQUE (stock_number)
)
GO

/*
	With tables created, we move to functionality. 
*/

-- We need ways to quickly add colors, interiors, and models. The following three procedures provide this for us. Each checks to see if the color, interior, or model are already present.
CREATE PROCEDURE addColor (@code varchar(3), @name varchar(30))
AS
BEGIN TRANSACTION
	BEGIN TRY -- check for redundany, i.e. if the color is already in the database
		INSERT INTO color (color_code, color_name)
		VALUES (@code, @name)
		SELECT 'Color successfully added'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT 'Color already exists'
		ROLLBACK TRANSACTION
	END CATCH
GO

CREATE PROCEDURE addInterior (@code varchar(3), @name varchar(30))
AS
BEGIN TRANSACTION
	BEGIN TRY -- similar check as for color
		INSERT INTO Interior(interior_code, interior_name)
		VALUES (@code, @name)
		SELECT 'Interior successfully added'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT 'Interior already exists'
		ROLLBACK TRANSACTION
	END CATCH
GO

CREATE PROCEDURE addModel (@name varchar(30))
AS
BEGIN TRANSACTION
	BEGIN TRY -- similar check as for color and interior
		INSERT INTO Model(model_name)
		VALUES (@name)
		SELECT 'Model successfully added'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT 'Model already exists'
		ROLLBACK TRANSACTION
	END CATCH	
GO

-- This procedure allows us to add individuals to our client base.
CREATE PROCEDURE addClient (@lastname varchar(30), @firstname varchar(30), @street varchar(50), @city varchar(20), @state varchar(2), @zip varchar(5), @email varchar(50), @phone varchar(10))
AS
BEGIN TRANSACTION
	BEGIN TRY -- checking for client existence
		INSERT INTO Clients(client_surname, client_forename, client_street, client_city, client_state, client_zip, client_email, client_telephone)
		VALUES (@lastname, @firstname, @street, @city, @state, @zip, @email, @phone)
		SELECT CONCAT('Client ', @firstname,' ',@lastname,' succesfully added'), (Select max(client_ID) FROM Clients) AS Client_ID
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF EXISTS (SELECT * FROM Clients WHERE client_email=@email) --report reason why transaction does not complete
			SELECT CONCAT('Email ',@email,' already exists for client') AS Result,(SELECT client_ID FROM Clients WHERE client_telephone=@phone) AS Client_ID
		ELSE
			SELECT CONCAT('Phone number ',@phone,' already exists') AS Result, (SELECT client_ID FROM Clients WHERE client_telephone=@phone) AS Client_ID
		ROLLBACK TRANSACTION
	END CATCH
GO

-- Obviously we need a way to enter new vehicles into inventory. This procedure takes the requisite information from the user and inserts it into a new line in the Unit table. 
CREATE PROCEDURE addUnit (@year varchar(4), @model varchar(30), @vin varchar(17), @color varchar(3), @interior varchar(3), @msrp int, @wholesale date, @stock varchar(10))
AS
BEGIN TRANSACTION
	BEGIN TRY -- check to see if the unit we are trying to add is already in our inventory or already sold. If not, complete the addition
			INSERT INTO Unit(model_year, model_name, VIN, color_code, interior_code, MSRP, wholesale_date, stock_number)
			VALUES (@year, @model, @vin, @color, @interior, @msrp, @wholesale, @stock)
			SELECT CONCAT('Stock number',' ',@stock,' ','added successfully')
			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH 
		IF EXISTS (SELECT * FROM Sold WHERE stock_number = @stock) --report reason why transaction does not complete
			SELECT CONCAT('Stock number ',@stock,' was sold on ', (SELECT sale_Date FROM Sold WHERE stock_number=@stock))
		ELSE IF NOT EXISTS (SELECT * FROM Model WHERE model_name=@model)
			SELECT CONCAT('Model ',@model,' does not exist')
		ELSE IF NOT EXISTS (SELECT * FROM Color WHERE color_code=@color)
			SELECT CONCAT('Color code ',@color,' does not exist')
		ELSE IF NOT EXISTS (SELECT * FROM Interior WHERE interior_code=@interior)
			SELECT CONCAT('Interior code ',@interior,' does not exist')
		ELSE IF EXISTS (SELECT * FROM Unit WHERE VIN=@vin)
			SELECT CONCAT('VIN ',@VIN,' is already in inventory with stock number ',(SELECT stock_number FROM Unit WHERE VIN =@vin))
		ELSE IF EXISTS (SELECT * FROM Unit WHERE stock_number=@stock)
			SELECT CONCAT('Stock number ',@stock,' already exists')
		ROLLBACK TRANSACTION
	END CATCH
GO

-- "Tagging" a car is industry-speak for putting a client's name on the car, indicating a deal has been agreed to but not yet finalized.
CREATE PROCEDURE tagUnit (@stock varchar(10), @client int, @sold date)
AS
BEGIN TRANSACTION
	BEGIN TRY -- only commit if stock number exists in inventory, is not sold already, and the client exists
		IF EXISTS (SELECT * FROM Unit WHERE stock_number = @stock  AND sold =0) AND EXISTS (SELECT * FROM Clients WHERE client_ID = @client)
			UPDATE Unit SET sale_date = @sold
			WHERE stock_number =@stock
			UPDATE Unit SET client_ID = @client
			WHERE stock_number = @stock
			SELECT CONCAT('Stock number ',@stock,' successfully tagged for client') AS Result, (SELECT client_ID FROM Clients WHERE client_ID=@client) AS Client_ID
			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF NOT EXISTS (SELECT * FROM Clients WHERE client_ID = @client) --report reason why transaction does not complete
			SELECT 'Client does not exist. Please add them'
		ELSE IF (SELECT client_ID FROM Unit WHERE stock_number=@stock)=@client
			SELECT 'No changes necessary'
		ELSE IF EXISTS (SELECT * FROM Sold WHERE stock_number = @stock)
			SELECT CONCAT('Stock number ',@stock,' is already sold')
		ELSE
			SELECT CONCAT('Stock number ',@stock,' does not exist')
		ROLLBACK TRANSACTION
	END CATCH
GO

-- The following procedure allows us to process a sale: logging the date of sale and re-calculating the age to be how long the car sat before it sold.

CREATE PROCEDURE sellUnit (@stock varchar(10), @saledate date, @client_ID int)
AS
BEGIN TRANSACTION	
	BEGIN TRY -- "Punch" a car (sell it to a client) only if stock number exists and is not already sold
		IF EXISTS (SELECT * FROM Unit WHERE stock_number = @stock AND sold = 0) 
			UPDATE Unit SET sold = 1 WHERE stock_number=@stock
			UPDATE Unit SET sale_date =@saledate WHERE stock_number=@stock
			UPDATE Unit SET client_ID = @client_ID WHERE stock_number=@stock
			SELECT CONCAT('Sale of stock number ',@stock,' complete.')
			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH 
		IF EXISTS (SELECT * FROM Unit WHERE stock_number = @stock AND sold=1) --report reason why transaction does not complete
			SELECT CONCAT('Stock number ',@stock,' is already sold')
		ELSE
			SELECT CONCAT('Stock numer ',@stock,' does not exist')
		ROLLBACK TRANSACTION
	END CATCH
GO

/*
	All of this data is great, but we'd like to be able to quickly generate reports or use it for something. The next few procedures will show sales data for month, quarter, 
	and year based on a date entered by the user. There is also a view for looking at our entire active inventory, a procedure to allow for checking if a certain stock stock number is sold, 
	and a procedure to quickly see available inventory for specific models.
*/

CREATE PROCEDURE Month_Sales (@start_date date)
AS
IF EXISTS (SELECT * FROM Unit WHERE MONTH(sale_date) = month(@start_date) AND YEAR(sale_date) = YEAR(@start_date) AND sold=1)
	SELECT stock_number, model_year, model_name, color_code, interior_code, VIN, MSRP, DATEDIFF(d, wholesale_date, sale_date) AS age FROM Unit
	WHERE MONTH(sale_date) = month(@start_date) AND YEAR(sale_date) = YEAR(@start_date)
ELSE
	SELECT CONCAT('No data to display for ',(SELECT DateName(month, DateAdd(month, MONTH(@start_date),-1))),' ',YEAR(@start_date))
GO

CREATE PROCEDURE Quarter_Sales (@start_date date)
AS
IF EXISTS (SELECT * FROM Unit WHERE DATEPART(Q,sale_date) = DATEPART(Q,@start_date) AND YEAR(sale_date) = YEAR(@start_date) AND sold = 1)
	SELECT stock_number, model_year, model_name, color_code, interior_code, VIN, MSRP, DATEDIFF(d, wholesale_date, sale_date) AS age FROM Unit
	WHERE DATEPART(Q,sale_date) = DATEPART(Q,@start_date) AND YEAR(sale_date) = YEAR(@start_date)
ELSE
	SELECT CONCAT('No data to display for Q',MONTH(@start_date)%4,' ',YEAR(@start_date))
GO

CREATE PROCEDURE Annual_Sales (@year int)
AS
IF EXISTS (SELECT * FROM Unit WHERE YEAR(sale_date) = @year AND sold = 1)
	SELECT stock_number, model_year, model_name, color_code, interior_code, VIN, MSRP, DATEDIFF(d, wholesale_date, sale_date) AS age FROM Unit
	WHERE YEAR(sale_date) = @year
ELSE
	SELECT CONCAT('No data to display for ',YEAR(@year))
GO

CREATE VIEW Active_Inventory AS
SELECT TOP 100
	model_year, 
	model_name, 
	color_code, 
	interior_code, 
	VIN, 
	MSRP, 
	stock_number,
	DATEDIFF(d, wholesale_date, GETDATE()) AS age
FROM Unit
WHERE sold = 0
ORDER BY model_name, model_year
GO

CREATE PROCEDURE Is_Sold (@stock varchar(30))
AS 
IF EXISTS (SELECT * FROM Unit WHERE stock_number=@stock and sold=1) 
	SELECT CONCAT('Stock number ',@stock,' has been sold.') 
ELSE IF NOT EXISTS (SELECT * FROM Unit WHERE stock_number=@stock) 
	SELECT CONCAT('Stock number ',@stock,' does not exist') 
ELSE IF (SELECT client_ID FROM Unit WHERE stock_number=@stock) IS NOT NULL
	SELECT CONCAT('Stock number ',@stock,' is currently tagged for'), (SELECT client_ID FROM Unit WHERE stock_number=@stock) AS Client_ID
ELSE 
	SELECT CONCAT('Stock number ',@stock,' is available')
GO

CREATE PROCEDURE Available(@model varchar(30))
AS
IF EXISTS (SELECT model_name FROM model WHERE model_name=@model) AND EXISTS (SELECT model_name FROM Unit WHERE model_name=@model) AND EXISTS (SELECT model_name FROM Unit WHERE sold =0)
	SELECT TOP 100
		model_year, 
		model_name, 
		color_code, 
		interior_code, 
		VIN, 
		MSRP,
		stock_number,
		DATEDIFF(d, wholesale_date, GETDATE()) AS age
	FROM Unit
	WHERE model_name = @model
	ORDER BY model_year
ELSE IF NOT EXISTS (SELECT model_name FROM model WHERE model_name=@model)
	SELECT CONCAT('Model ',@model,' does not exist')
ELSE
	SELECT CONCAT('No available ',@model,' units')
GO

/*
	Lot life is how long a car sits on the lot before it is sold. With an expressed goal of minimizing this for revenue purposes, this is important to be able to track.
	Similarly, we consider any car with lot life greater than 90 days to be an operational "defect". We have views coded to see both for active inventory and sold vehicles from high level, 
	as well as functions that accept a model name and return the average lot life and defectfor both active inventory and sold units.
*/

CREATE VIEW Inv_AverageLotLife AS
SELECT 
	model_name AS Model,
	AVG(DATEDIFF(d, wholesale_date, GETDATE())) AS "Average age"
FROM Unit
GROUP BY model_name
GO

CREATE VIEW Inv_DefectCounts AS
SELECT 
	model_name AS Model,
	COUNT(model_name) AS Total,
	SUM(
		CASE
			WHEN DATEDIFF(d, wholesale_date, GETDATE()) > 90 then 1
			ELSE 0
		END) 
	AS Defects,
	ROUND(CAST(SUM(
		CASE
			WHEN DATEDIFF(d, wholesale_date, GETDATE()) > 90 then 1
			ELSE 0
		END) AS FLOAT)/CAST(COUNT(model_name) AS FLOAT),2) AS "Defect rate"
FROM Unit
GROUP BY model_name
GO

CREATE VIEW Sold_AverageLotLife AS
SELECT 
	model_name AS Model,
	AVG(DATEDIFF(d, wholesale_date, sale_date)) AS "Average age"
FROM Unit WHERE sold =1
GROUP BY model_name
GO

CREATE VIEW Sold_DefectCounts AS
SELECT 
	model_name AS Model,
	SUM(
		CASE
			WHEN DATEDIFF(d, wholesale_date, sale_date) > 90 then 1
			ELSE 0
		END) 
	AS Defects,
	ROUND(CAST(SUM(
		CASE
			WHEN DATEDIFF(d, wholesale_date, sale_date) > 90 then 1
			ELSE 0
		END) AS FLOAT)/CAST(COUNT(model_name) AS FLOAT),2) AS "Defect rate"
FROM Unit where sold =1
GROUP BY model_name
GO

CREATE FUNCTION Inv_ModelLotLife (@model varchar(30))
RETURNS TABLE
AS
RETURN
	SELECT AVG(DATEDIFF(d, wholesale_date, GETDATE())) AS "Average age" FROM Unit WHERE model_name = @model
GO

CREATE FUNCTION Inv_ModelDefects (@model varchar(30))
RETURNS TABLE
AS
RETURN
	SELECT SUM(
		CASE
			WHEN DATEDIFF(d, wholesale_date, GETDATE()) > 90 then 1
			ELSE 0
		END) 
	AS Defects,
	ROUND(CAST(SUM(
		CASE
			WHEN DATEDIFF(d, wholesale_date, GETDATE()) > 90 then 1
			ELSE 0
		END) AS FLOAT)/CAST(COUNT(model_name) AS FLOAT),2) AS "Defect rate"
	FROM Unit WHERE model_name = @model
GO

CREATE FUNCTION Sold_ModelLotLife (@model varchar(30))
RETURNS TABLE
AS
RETURN
	SELECT AVG(DATEDIFF(d, wholesale_date, sale_date)) AS "Average age" FROM Unit WHERE model_name = @model AND sold =1
GO

CREATE FUNCTION Sold_ModelDefects (@model varchar(30))
RETURNS TABLE
AS
RETURN
	SELECT SUM(
		CASE
			WHEN DATEDIFF(d, wholesale_date, sale_date) > 90 then 1
			ELSE 0
		END) 
	AS Defects,
	ROUND(CAST(SUM(
		CASE
			WHEN DATEDIFF(d, wholesale_date, sale_date) > 90 then 1
			ELSE 0
		END) AS FLOAT)/CAST(COUNT(model_name) AS FLOAT),2) AS "Defect rate"
	FROM Unit WHERE model_name = @model AND sold = 1
GO

/*
	This view provides a concise list of our clients who purchased vehicles along with their email addresses, for digital marketing purposes
*/

CREATE VIEW Sold_Clients_forMarketing AS
SELECT DISTINCT TOP 100
	client_surname AS Last_Name, 
	client_forename AS First_Name,
	client_email AS Email,
	COUNT(Unit.client_ID) AS Purchases
FROM Clients JOIN Unit ON Clients.client_ID=Unit.client_ID
WHERE Unit.sold =1
GROUP BY client_surname, client_forename, client_email
ORDER BY client_surname, client_forename
GO
