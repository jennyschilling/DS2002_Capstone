# DROP database `retail_sales_dw`;
CREATE DATABASE `retail_sales_dw` /*!40100 DEFAULT CHARACTER SET latin1 */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE retail_sales_dw;
  
# DROP TABLE `sales_fact`;
CREATE TABLE sales_fact (
sale_id int NOT NULL,
sale_date date NOT NULL,
product_id varchar(15) NOT NULL,
customer_id int NOT NULL,
quantity_sold int NOT NULL,
sales_amount int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

# DROP TABLE `customer_dim`;
CREATE TABLE `customer_dim` (
  `customer_id` int NOT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `credit_limit` decimal(10,2) NOT NULL,
  PRIMARY KEY (`customer_id`),
  KEY `first_name` (`first_name`),
  KEY `last_name` (`last_name`),
  KEY `phone` (`phone`),
  KEY `credit_limit` (`credit_limit`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



#############
# insert data
#############
  
TRUNCATE TABLE retail_sales_dw.customer_dim;
INSERT INTO `retail_sales_dw`.`customer_dim`
(`customer_id`,
`first_name`,
`last_name`,
`phone`,
`credit_limit`)
SELECT `customerNumber`,
	`contactFirstName`,
	`contactLastName`,
	`phone`,
	`creditLimit`
FROM classicmodels.customers;
SELECT * FROM retail_sales_dw.customer_dim;

TRUNCATE TABLE `retail_sales_dw`.`sales_fact`;
INSERT INTO `retail_sales_dw`.`sales_fact`
(`sale_id`,
`sale_date`,
`product_id`,
`customer_id`,
`quantity_sold`,
`sales_amount`)
SELECT 
	s.orderNumber AS sale_id,
    s.orderDate AS sale_date,
    sd.productCode AS product_id,
    s.customerNumber AS customer_id,
    sd.quantityOrdered AS quantity_sold,
    sd.priceEach AS sales_amount
FROM classicmodels.orders AS s
INNER JOIN classicmodels.orderdetails AS sd ON s.orderNumber = sd.orderNumber;
SELECT * FROM retail_sales_dw.sales_fact;

SELECT * FROM retail_sales_dw.date_dim;

DROP TABLE IF EXISTS date_dim;
CREATE TABLE date_dim(
 date_key int NOT NULL,
 full_date date NULL,
 date_name char(11) NOT NULL,
 date_name_us char(11) NOT NULL,
 date_name_eu char(11) NOT NULL,
 day_of_week tinyint NOT NULL,
 day_name_of_week char(10) NOT NULL,
 day_of_month tinyint NOT NULL,
 day_of_year smallint NOT NULL,
 weekday_weekend char(10) NOT NULL,
 week_of_year tinyint NOT NULL,
 month_name char(10) NOT NULL,
 month_of_year tinyint NOT NULL,
 is_last_day_of_month char(1) NOT NULL,
 calendar_quarter tinyint NOT NULL,
 calendar_year smallint NOT NULL,
 calendar_year_month char(10) NOT NULL,
 calendar_year_qtr char(10) NOT NULL,
 fiscal_month_of_year tinyint NOT NULL,
 fiscal_quarter tinyint NOT NULL,
 fiscal_year int NOT NULL,
 fiscal_year_month char(10) NOT NULL,
 fiscal_year_qtr char(10) NOT NULL,
  PRIMARY KEY (`date_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

# Here is the PopulateDateDimension Stored Procedure: 
delimiter //

DROP PROCEDURE IF EXISTS PopulateDateDimension//
CREATE PROCEDURE PopulateDateDimension(BeginDate DATETIME, EndDate DATETIME)
BEGIN

	DECLARE LastDayOfMon CHAR(1);

	DECLARE FiscalYearMonthsOffset INT;

	DECLARE DateCounter DATETIME;    #Current date in loop
	DECLARE FiscalCounter DATETIME;  #Fiscal Year Date in loop

	SET FiscalYearMonthsOffset = 6;

	SET DateCounter = BeginDate;

	WHILE DateCounter <= EndDate DO
		SET FiscalCounter = DATE_ADD(DateCounter, INTERVAL FiscalYearMonthsOffset MONTH);

		IF MONTH(DateCounter) = MONTH(DATE_ADD(DateCounter, INTERVAL 1 DAY)) THEN
			SET LastDayOfMon = 'N';
		ELSE
			SET LastDayOfMon = 'Y';
		END IF;

		INSERT INTO date_dim
			(date_key
			, full_date
			, date_name
			, date_name_us
			, date_name_eu
			, day_of_week
			, day_name_of_week
			, day_of_month
			, day_of_year
			, weekday_weekend
			, week_of_year
			, month_name
			, month_of_year
			, is_last_day_of_month
			, calendar_quarter
			, calendar_year
			, calendar_year_month
			, calendar_year_qtr
			, fiscal_month_of_year
			, fiscal_quarter
			, fiscal_year
			, fiscal_year_month
			, fiscal_year_qtr)
		VALUES  (
			( YEAR(DateCounter) * 10000 ) + ( MONTH(DateCounter) * 100 ) + DAY(DateCounter)  #DateKey
			, DateCounter #FullDate
			, CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'/', DATE_FORMAT(DateCounter,'%m'),'/', DATE_FORMAT(DateCounter,'%d')) #DateName
			, CONCAT(DATE_FORMAT(DateCounter,'%m'),'/', DATE_FORMAT(DateCounter,'%d'),'/', CAST(YEAR(DateCounter) AS CHAR(4)))#DateNameUS
			, CONCAT(DATE_FORMAT(DateCounter,'%d'),'/', DATE_FORMAT(DateCounter,'%m'),'/', CAST(YEAR(DateCounter) AS CHAR(4)))#DateNameEU
			, DAYOFWEEK(DateCounter) #DayOfWeek
			, DAYNAME(DateCounter) #DayNameOfWeek
			, DAYOFMONTH(DateCounter) #DayOfMonth
			, DAYOFYEAR(DateCounter) #DayOfYear
			, CASE DAYNAME(DateCounter)
				WHEN 'Saturday' THEN 'Weekend'
				WHEN 'Sunday' THEN 'Weekend'
				ELSE 'Weekday'
			END #WeekdayWeekend
			, WEEKOFYEAR(DateCounter) #WeekOfYear
			, MONTHNAME(DateCounter) #MonthName
			, MONTH(DateCounter) #MonthOfYear
			, LastDayOfMon #IsLastDayOfMonth
			, QUARTER(DateCounter) #CalendarQuarter
			, YEAR(DateCounter) #CalendarYear
			, CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'-',DATE_FORMAT(DateCounter,'%m')) #CalendarYearMonth
			, CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'Q',QUARTER(DateCounter)) #CalendarYearQtr
			, MONTH(FiscalCounter) #[FiscalMonthOfYear]
			, QUARTER(FiscalCounter) #[FiscalQuarter]
			, YEAR(FiscalCounter) #[FiscalYear]
			, CONCAT(CAST(YEAR(FiscalCounter) AS CHAR(4)),'-',DATE_FORMAT(FiscalCounter,'%m')) #[FiscalYearMonth]
			, CONCAT(CAST(YEAR(FiscalCounter) AS CHAR(4)),'Q',QUARTER(FiscalCounter)) #[FiscalYearQtr]
		);
		SET DateCounter = DATE_ADD(DateCounter, INTERVAL 1 DAY);
	END WHILE;
END//

CALL PopulateDateDimension('2000-01-01', '2010-12-31');

SELECT MIN(full_date) AS BeginDate
	, MAX(full_date) AS EndDate
FROM date_dim;
