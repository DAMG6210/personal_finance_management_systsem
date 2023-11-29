create database personal_fin_mange;
use personal_fin_mange;
SELECT * from dbo.USER_DETAILS;
SELECT * from dbo.profile;

create table Trading_Account( 
    ACCOUNT_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    PROFILE_ID UNIQUEIDENTIFIER NOT NULL,
    BROKER_ID UNIQUEIDENTIFIER NOT NULL,
    ACCOUNT_TYPE VARCHAR(10) NOT NULL,
    ACCOUNT_NUMBER VARCHAR(15) NOT NULL,
    CURRENT_BALANCE MONEY NOT NULL,
    LAST_UPDATED DATETIME not null,
    PRIMARY KEY CLUSTERED([ACCOUNT_ID] ASC),
    FOREIGN key ([PROFILE_ID]) REFERENCES dbo.profile([PROFILE_ID]),
    FOREIGN key ([BROKER_ID]) REFERENCES dbo.BROKER([BROKER_ID])
)

ALTER TABLE dbo.Trading_Account
add CONSTRAINT TA_Valid_Last_Updated_Date CHECK(LAST_UPDATED <= GETDATE());


Alter Table dbo.Trading_Account
add CONSTRAINT TA_valid_Money CHECK(CURRENT_BALANCE >= 0);


CREATE TABLE BROKER(
    BROKER_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    NAME VARCHAR(15) NOT NULL CHECK ([NAME] like '^[a-zA-Z]{2,}$'),
    API_ENDPOINT VARCHAR(50),
    PHONE_NUM NVARCHAR(20) NOT NULL CHECK ([PHONE_NUM] like '^.+\d+$'),
    ADDRESS NVARCHAR(25),
    PRIMARY KEY CLUSTERED( [BROKER_ID] ASC),
)

CREATE TABLE STOCK_BOOK(
    HOLDING_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    ACCOUNT_ID UNIQUEIDENTIFIER NOT NULL,
    NAME VARCHAR(40) NOT NULL,
    SYMBOL VARCHAR(20) NOT NULL,
    INVESTMENT_TYPE CHAR(1) NOT NULL,
    Quantity  DECIMAL(18,2) NOT NULL,
    AVG_VALUE DECIMAL(8,3) NOT NULL,
    PRIMARY KEY CLUSTERED([HOLDING_ID] ASC),
    FOREIGN key ([ACCOUNT_ID]) REFERENCES dbo.Trading_Account([ACCOUNT_ID])
)

CREATE TABLE SIP_DETAILS
(
    SIP_HOLDING_ID UNIQUEIDENTIFIER NOT NULL,
    DATE DATE NOT NULL,
    FREQUENCY CHAR(1) NOT NULL,
    QUANTITY INT NOT NULL,
    AMOUNT MONEY NOT NULL,
    NXT_PAY_DATE DATE NOT NULL,
    PRIMARY KEY CLUSTERED([SIP_HOLDING_ID] ASC),
    FOREIGN KEY ([SIP_HOLDING_ID]) REFERENCES dbo.STOCK_BOOK([HOLDING_ID])
)

Alter Table dbo.SIP_DETAILS
add CONSTRAINT SD_Valid_Quantity CHECK(QUANTITY >= 1);


Alter Table dbo.SIP_DETAILS 
add CONSTRAINT SD_Valid_Amount check(AMOUNT >= 0),
CONSTRAINT SD_Valid_Nxt_Pay_Date check(NXT_PAY_DATE >= getdate());


CREATE TABLE TRANSACTION_HISTORY
(
    TRANSACTION_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    HOLDING_ID UNIQUEIDENTIFIER NOT NULL,
    DATE DATE NOT NULL,
    SYMBOL NVARCHAR(10) NOT NULL,
    PRICE MONEY NOT NULL,
    QUANTITY DECIMAL(18,2) NOT NULL,
    BUY_SELL CHAR(1) NOT NULL CHECK ([BUY_SELL] IN ('B','S')),
    PRIMARY KEY CLUSTERED([TRANSACTION_ID] ASC),
    FOREIGN KEY ([HOLDING_ID]) REFERENCES dbo.STOCK_BOOK([HOLDING_ID])
)


CREATE TABLE NOTIFICATION
(
    NOTIFICATION_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    PROFILE_ID UNIQUEIDENTIFIER NOT NULL,
    Notification_TYPE VARCHAR(10) NOT NULL,
    TIMESTAMP DATETIME NOT NULL,
    AMOUNT MONEY NOT NULL,
    DUE_DATE DATETIME NOT NULL,
    MESSAGE NVARCHAR(MAX),
    ISREAD BIT NOT NULL,
    PRIMARY KEY CLUSTERED([NOTIFICATION_ID] ASC),
    FOREIGN KEY ([PROFILE_ID]) REFERENCES dbo.profile([PROFILE_ID])
)


CREATE TABLE FINANCIAL_GOALS
(
    GOAL_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    PROFILE_ID UNIQUEIDENTIFIER NOT NULL,
    GOAL_NAME VARCHAR(50) NOT NULL CHECK ([GOAL_NAME] like '^[a-zA-Z]{2,}$'),
    GOAL_DESCRIPTION VARCHAR(255) NOT NULL,
    TARGET_AMOUNT MONEY NOT NULL,
    TARGET_DATE DATE NOT NULL,
    START_DATE DATE NOT NULL,
    PRIMARY KEY CLUSTERED([GOAL_ID] ASC),
    FOREIGN KEY ([PROFILE_ID]) REFERENCES dbo.profile([PROFILE_ID])
)


alter TABLE dbo.FINANCIAL_GOALS
add CONSTRAINT FG_Valid_Amount check(TARGET_AMOUNT >= 1),
CONSTRAINT FG_Target_Date CHECK((TARGET_DATE > GETDATE() and (TARGET_DATE > START_DATE))),
CONSTRAINT FG_Start_Date CHECK(START_DATE >= GETDATE());


create TABLE GOAL_PROGRESS
(
    PROGRESS_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    GOAL_ID UNIQUEIDENTIFIER NOT NULL,
    DATE DATE NOT NULL,
    AMOUNT MONEY NOT NULL,
    CURRENT_AMOUNT MONEY NOT NULL,
    PRIMARY KEY CLUSTERED([PROGRESS_ID] ASC),
    FOREIGN KEY ([GOAL_ID]) REFERENCES dbo.FINANCIAL_GOALS([GOAL_ID])
)

ALTER TABLE GOAL_PROGRESS
add CONSTRAINT GP_Valid_Amount CHECK (AMOUNT >= CURRENT_AMOUNT);

create table USER_DETAILS 
(
	USER_ID UNIQUEIDENTIFIER default NEWID() PRIMARY KEY,
	USER_NAME VARCHAR(20) NOT NULL,
	USER_PASSWORD VARBINARY(64) NOT NULL,
	FAILED_LOGIN_ATTEMPTS INT ,
	PASSWORD_LAST_UPDATED DATETIME,
	LAST_LOGIN_DATE DATETIME,
	MFA_ENABLED BIT	
);

CREATE MASTER KEY 
ENCRYPTION BY PASSWORD = 'DAMG6210!'
DROP TRIGGER HashPasswordTrigger;
go;
CREATE TRIGGER HashPasswordTrigger ON USER_DETAILS 
INSTEAD OF INSERT
AS
BEGIN
    PRINT 'HELLO FROM TRIGGER HashPasswordTrigger'
    
    INSERT INTO USER_DETAILS  
    (USER_ID, USER_NAME, USER_PASSWORD, FAILED_LOGIN_ATTEMPTS, PASSWORD_LAST_UPDATED, LAST_LOGIN_DATE, MFA_ENABLED)
    SELECT 
        NEWID(), 
        USER_NAME, 
        HASHBYTES('SHA2_256', USER_PASSWORD), 
        FAILED_LOGIN_ATTEMPTS, 
        PASSWORD_LAST_UPDATED, 
        LAST_LOGIN_DATE, 
        MFA_ENABLED
    FROM inserted
END;

alter table user_details 
add constraint valid_PASSWORD_LAST_UPDATED check(PASSWORD_LAST_UPDATED <= GETDATE());

alter table user_details 
add constraint valid_LAST_LOGIN_DATE check(LAST_LOGIN_DATE <= GETDATE());

alter table user_details 
add constraint VALID_FAILED_LOGIN_ATTEMPTS check(FAILED_LOGIN_ATTEMPTS >= 0);

create table profile (
	PROFILE_ID UNIQUEIDENTIFIER default newid() PRIMARY KEY CLUSTERED,
	USER_ID UNIQUEIDENTIFIER NOT NULL,
	FIRST_NAME VARCHAR(20) NOT NULL, 
	LAST_NAME VARCHAR(20) NOT NULL,
	EMAIL VARCHAR(20)  NOT NULL,
	DOB DATE NOT NULL, 
	PARENT_PROFILE_ID UNIQUEIDENTIFIER,
	SSN VARBINARY(64) NOT NULL, 
	MOBILE_NUMBER VARCHAR(20), 
	GENDER CHAR(1) 
	FOREIGN KEY (USER_ID) references user_details(user_id)
);

ALTER TABLE profile 
ADD CONSTRAINT valid_first_name CHECK(FIRST_NAME like '^[a-zA-Z]{2,}$');

ALTER TABLE profile 
ADD CONSTRAINT valid_last_name CHECK(LAST_NAME like '^[a-zA-Z]{2,}$');

ALTER TABLE profile 
ADD CONSTRAINT valid_email CHECK(EMAIL like '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$');

ALTER TABLE PROFILE
ADD CONSTRAINT VALID_dob CHECK(DOB < GETDATE());

alter table profile 
add FOREIGN KEY (PARENT_PROFILE_ID) references profile(PROFILE_ID);

ALTER TABLE profile 
ADD CONSTRAINT VALID_MOBILE_NUMBER CHECK(MOBILE_NUMBER like '^.+\d+$');

ALTER TABLE profile 
ADD CONSTRAINT valid_gender CHECK(GENDER in ('M','F','O'));

--ADDRESS 
CREATE TABLE Address (
  Address_ID UNIQUEIDENTIFIER default newid() PRIMARY KEY CLUSTERED,
  PROFILE_ID UNIQUEIDENTIFIER NOT NULL REFERENCES profile(PROFILE_ID),
  Address_Type VARCHAR(10) NOT NULL,
  IsPrimary BIT NOT NULL,
  AddressLine1 VARCHAR(30) NOT NULL,
  AddressLine2 VARCHAR(30),
  City VARCHAR(20) NOT NULL,
  ZipCode INT NOT NULL CHECK(ZipCode like '^\d+$'),
  State VARCHAR(20) NOT NULL,
  Country CHAR(2) NOT NULL,
  Notes TEXT
);

CREATE TABLE CREDIT_AGENCY (
  Agency_ID UNIQUEIDENTIFIER default newid() PRIMARY KEY,
  Name VARCHAR(20) NOT NULL,
  MAX_SCORE INT CONSTRAINT CA_VALID_MAX_SCORE CHECK (MAX_SCORE >=100 and MAX_SCORE<= 1000),
  ADDRESS NVARCHAR(255),
  CONTACT_NUMBER NVARCHAR(20) CONSTRAINT CA_VALID_CONTACT_NUM CHECK (CONTACT_NUMBER like '^.+\d+$'),
  CONTACT_EMAIL NVARCHAR(30) CONSTRAINT CA_VALID_CONTACT_EMAIL check(CONTACT_EMAIL like '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$')
);


create TABLE CREDIT_INFO(
	User_Credit_Scored_ID UNIQUEIDENTIFIER default newid() PRIMARY KEY,
	PROFILE_ID UNIQUEIDENTIFIER NOT NULL REFERENCES profile(PROFILE_ID),
	Agency_ID UNIQUEIDENTIFIER NOT NULL REFERENCES CREDIT_AGENCY(Agency_ID),
	CURRENT_SCORE INT CONSTRAINT CI_VALID_CURRENT_SCORE CHECK(CURRENT_SCORE >= 100),
	SCORE_DATE DATE CONSTRAINT CI_VALID_SCORE_DATE CHECK(SCORE_DATE <= GETDATE()),
	REPORT_DATE DATE CONSTRAINT CI_VALID_REPORT_DATE CHECK(REPORT_DATE <= GETDATE()),
	REPORT_FILE NVARCHAR(MAX)
)


CREATE TABLE CREDIT_HOSTORY(
	Credit_History_Id UNIQUEIDENTIFIER default newid() PRIMARY KEY,
	Credit_Id UNIQUEIDENTIFIER NOT NULL REFERENCES CREDIT_INFO(User_Credit_Scored_ID),
	Credit_Score INT NOT NULL,
	DATE DATE CONSTRAINT CI_VALID_DATE CHECK(DATE <= GETDATE())
)

CREATE TABLE LENDER(
    LENDER_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    NAME VARCHAR(20) NOT NULL,
    TYPE VARCHAR(10) NOT NULL,
    ADDRESS TEXT NOT NULL,
    CONTACT_INFO VARCHAR(12) NOT NULL,
    WEBSITE NVARCHAR(30) NOT NULL,
    RATING INT NOT NULL,
    LOGO NVARCHAR(20) NOT NULL,
    LICENSING_DETAILS NVARCHAR(MAX) NOT NULL,
    PRIMARY KEY CLUSTERED([LENDER_ID])
)



CREATE TABLE LOANS(
    LOAN_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    PROFILE_ID UNIQUEIDENTIFIER NOT NULL,
    LOAN_NAME VARCHAR(50) NOT NULL,
    LOAN_TYPE VARCHAR(10) NOT NULL,
    LOAN_AMOUNT MONEY NOT NULL,
    INTEREST_RATE DECIMAL(5,2) NOT NULL,
    LOAN_TERM DECIMAL(4,2) NOT NULL,
    [START_DATE] DATE NOT NULL,
    END_DATE DATE NOT NULL,
    INSTALLMENT_AMOUNT MONEY NOT NULL,
    FREQUENCY CHAR(1) NOT NULL,
    PAID_AMOUNT MONEY NOT NULL,
    LENDER_ID UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED([LOAN_ID]),
    FOREIGN key ([PROFILE_ID]) REFERENCES dbo.profile([PROFILE_ID]),
    FOREIGN key ([LENDER_ID]) REFERENCES dbo.LENDER([LENDER_ID])
)

ALTER TABLE dbo.LOANS
add CONSTRAINT LOANS_Valid_DATE CHECK([START_DATE] <= END_DATE);


CREATE TABLE LOAN_DOCUMENTS(
    DOCUMENT_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    LOAN_ID UNIQUEIDENTIFIER NOT NULL,
    DOCUMENT_NAME NVARCHAR(255) NOT NULL,
    DOCUMENT_URL NVARCHAR(MAX) NOT NULL,
    DOCUMENT_DESCRIPTION NVARCHAR(255) NOT NULL,
    FOREIGN key ([LOAN_ID]) REFERENCES dbo.LOANS([LOAN_ID])
)

ALTER TABLE dbo.LOAN_DOCUMENTS
add PRIMARY KEY CLUSTERED([DOCUMENT_ID] ASC);


CREATE TABLE INSTALLMENTS(
    INSTALLMENT_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    LOAN_ID UNIQUEIDENTIFIER NOT NULL,
    DUE_AMOUNT MONEY NOT NULL,
    DUE_DATE DATE NOT NULL,
    PAID_DATE DATE NOT NULL,
    PAYMENT_AMOUT MONEY NOT NULL,
    PAYMENT_METHOD VARCHAR(20) NOT NULL,
    PRIMARY KEY CLUSTERED([INSTALLMENT_ID] ASC),
    FOREIGN key ([LOAN_ID]) REFERENCES dbo.LOANS([LOAN_ID])
)


CREATE TABLE BANK_INFORMATION(
    BANK_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    NAME VARCHAR(20) NOT NULL,
    ADDRESS VARCHAR(50) NOT NULL,
    CONTACT_NUMBER VARCHAR(20) NOT NULL,
    EMAIL VARCHAR(20) NOT NULL,
    PRIMARY KEY CLUSTERED([BANK_ID] ASC),
)


CREATE TABLE ACCOUNTS(
    ACCOUNT_ID UNIQUEIDENTIFIER NOT NULL,
    PROFILE_ID UNIQUEIDENTIFIER NOT NULL,
    ACCOUNT_TYPE VARCHAR(10) NOT NULL,
    PROFILE_NUMBER VARCHAR(20) NOT NULL,
    CURRENT_BALANCE FLOAT NOT NULL,
    BANK_ID UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED([ACCOUNT_ID] ASC),
    FOREIGN key ([PROFILE_ID]) REFERENCES dbo.profile([PROFILE_ID]),
    FOREIGN key ([BANK_ID]) REFERENCES dbo.BANK_INFORMATION([BANK_ID])
)


CREATE TABLE EXPENSE_CATEGORY(
    EXPENSE_CATEGORY_ID UNIQUEIDENTIFIER NOT NULL,
    NAME VARCHAR(20) NOT NULL,
    URL NVARCHAR(MAX) NOT NULL,
    DESCRIPTION VARCHAR(50) NOT NULL,
    PRIMARY KEY CLUSTERED([EXPENSE_CATEGORY_ID] ASC)
)


CREATE TABLE BANK_TRANSACTION(
    BANK_TRANSACTION_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    ACCOUNT_ID UNIQUEIDENTIFIER NOT NULL,
    AMOUNT MONEY NOT NULL,
    TRANSACTION_DATE DATE NOT NULL,
    TRANSACTION_TYPE CHAR(1) NOT NULL,
    EXPENSE_CATEGORY_ID UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED([BANK_TRANSACTION_ID] ASC),
    FOREIGN key ([ACCOUNT_ID]) REFERENCES dbo.ACCOUNTS([ACCOUNT_ID]),
    FOREIGN key ([EXPENSE_CATEGORY_ID]) REFERENCES dbo.EXPENSE_CATEGORY([EXPENSE_CATEGORY_ID])
)


CREATE TABLE CREDIT_CARD(
    CREDIT_CARD_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    PROFILE_ID UNIQUEIDENTIFIER NOT NULL,
    LAST_FOUR_DIGITS NUMERIC(4,0) NOT NULL,
    BANK_ID UNIQUEIDENTIFIER NOT NULL,
    DUE_DATE DATE NOT NULL,
    CREDIT_LIMIT MONEY NOT NULL,
    CREDIT_DUE_AMOUNT MONEY NOT NULL,
    PAYMENT_DUE_AMOUNT MONEY NOT NULL,
    PRIMARY KEY CLUSTERED([CREDIT_CARD_ID] ASC),
    FOREIGN key ([PROFILE_ID]) REFERENCES dbo.profile([PROFILE_ID]),
    FOREIGN key ([BANK_ID]) REFERENCES dbo.BANK_INFORMATION([BANK_ID])
)


CREATE TABLE CREDIT_CARD_TRANSACTION(
    CC_TRANSACTION_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    CREDIT_CARD_ID UNIQUEIDENTIFIER NOT NULL,
    AMOUNT MONEY NOT NULL,
    TRANSACTION_DATE DATE NOT NULL,
    TRANSACTION_TYPE CHAR(1) NOT NULL,
    EXPENSE_CATEGORY_ID UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED([CC_TRANSACTION_ID] ASC),
    FOREIGN key ([CREDIT_CARD_ID]) REFERENCES dbo.CREDIT_CARD([CREDIT_CARD_ID]),
    FOREIGN key ([EXPENSE_CATEGORY_ID]) REFERENCES dbo.EXPENSE_CATEGORY([EXPENSE_CATEGORY_ID])
)


ALTER TABLE dbo.CREDIT_CARD_TRANSACTION
add CONSTRAINT CC_Valid_TRANSACTION_DATE CHECK(TRANSACTION_DATE <= GETDATE());



CREATE TABLE INSURANCE_PROVIDERS(
    PROVIDER_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    PROVIDER_NAME NVARCHAR(20) NOT NULL,
    WEBSITE NVARCHAR(20) NOT NULL,
    CONTACT_EMAIL NVARCHAR(20) NOT NULL,
    CONTACT_NUMBER NVARCHAR(20) NOT NULL,
    ADDRESS NVARCHAR(255) NOT NULL,
    PRIMARY KEY CLUSTERED([PROVIDER_ID] ASC)
)


CREATE TABLE INSURANCE_TYPE(
    TYPE_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    NAME NVARCHAR(20) NOT NULL,
    DESCRIPTION NVARCHAR(100) NOT NULL,
    PRIMARY KEY CLUSTERED([TYPE_ID] ASC)
)


CREATE TABLE POLICY_DETAILS(
    POLICY_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    PROFILE_ID UNIQUEIDENTIFIER NOT NULL,
    PROVIDER_ID UNIQUEIDENTIFIER NOT NULL,
    TYPE_ID UNIQUEIDENTIFIER NOT NULL,
    POLICY_NUMBER NVARCHAR(20) NOT NULL,
    POLICY_NAME NVARCHAR(50) NOT NULL,
    START_DATE DATE NOT NULL,
    END_DATE DATE NOT NULL,
    PAYMENT_FREQUENCY CHAR(1) NOT NULL,
    PAYMENT_AMOUNT MONEY NOT NULL,
    NEXT_PAY_DATE DATE NOT NULL,
    PRIMARY KEY CLUSTERED([POLICY_ID] ASC),
    FOREIGN key ([PROFILE_ID]) REFERENCES dbo.PROFILE([PROFILE_ID]),
    FOREIGN key ([PROVIDER_ID]) REFERENCES dbo.INSURANCE_PROVIDERS([PROVIDER_ID]),
    FOREIGN key ([TYPE_ID]) REFERENCES dbo.INSURANCE_TYPE([TYPE_ID])
)


CREATE TABLE MFA_METHOD(
    METHOD_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    USER_ID UNIQUEIDENTIFIER NOT NULL,
    METHOD_TYPE VARCHAR(10) NOT NULL, 
    ADDITIONAL_INFORMATION VARCHAR(50) NOT NULL,
    RECOVERY_CODE VARBINARY NOT NULL, 
    PRIMARY KEY CLUSTERED([METHOD_ID] ASC),
    FOREIGN key ([USER_ID]) REFERENCES dbo.USER_DETAILS([USER_ID])
)


CREATE TABLE CLAIM_HISTORY(
    CLAIM_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    POLICY_ID UNIQUEIDENTIFIER NOT NULL,
    CLAIM_AMOUNT MONEY NOT NULL,
    CLAIM_DATE DATE NOT NULL,
    CLAIM_DESCRIPTION NVARCHAR(MAX) NOT NULL,
    PRIMARY KEY CLUSTERED([CLAIM_ID] ASC),
    FOREIGN key ([POLICY_ID]) REFERENCES dbo.POLICY_DETAILS([POLICY_ID])
)

CREATE TABLE HEALTH_INSURANCE(
    HEALTH_POLICY_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    COVERAGE_TYPE VARCHAR(12) NOT NULL,
    DEDUCTIBLE MONEY NOT NULL,
    PRIMARY KEY CLUSTERED([HEALTH_POLICY_ID] ASC),
    --FOREIGN key ([HEALTH_POLICY_ID]) REFERENCES dbo.POLICY_DETAILS([HEALTH_POLICY_ID])
)

CREATE TABLE LIFE_INSURANCE(
    LIFE_POLICY_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    COVERAGE_AMOUNT MONEY NOT NULL,
    BENEFICIARY VARCHAR(20) NOT NULL,
    PRIMARY KEY CLUSTERED([LIFE_POLICY_ID] ASC),
)

CREATE TABLE AUTO_INSURANCE(
    AUTO_POLICY_ID UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL, 
    VEHICLE_MAKE VARCHAR(20) NOT NULL,
    VEHICLE_MODEL VARCHAR(20) NOT NULL,
    PURCHASE_YEAR INT NOT NULL,
    PRIMARY KEY CLUSTERED([AUTO_POLICY_ID] ASC)
)