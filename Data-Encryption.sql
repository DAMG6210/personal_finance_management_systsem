CREATE MASTER KEY 
ENCRYPTION BY PASSWORD = 'DAMG6210!'

CREATE CERTIFICATE PersonalFinanceManagenemt
WITH SUBJECT = 'PersonalFinanceManagement';

CREATE SYMMETRIC KEY PasswordKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE PersonalFinanceManagenemt;

OPEN SYMMETRIC KEY PasswordKey
DECRYPTION BY CERTIFICATE PersonalFinanceManagenemt;

CREATE SYMMETRIC KEY SSNkEY
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE PersonalFinanceManagenemt;

OPEN SYMMETRIC KEY SSNkEY
DECRYPTION BY CERTIFICATE PersonalFinanceManagenemt;

CLOSE SYMMETRIC KEY SSNkEY;
CLOSE SYMMETRIC KEY PasswordKey;
