-- Creating database, tables, constraints and references.
CREATE DATABASE Company
GO

ALTER DATABASE Company
COLLATE Cyrillic_General_CI_AS
GO

USE Company
GO

CREATE TABLE EmployeeInfos
(
Id int IDENTITY(1,1),
FName nvarchar(30),
LName nvarchar(30),
MName nvarchar(30) NOT NULL,
Phone char(15) CONSTRAINT CK_EmployeeInfos_Phone CHECK (Phone LIKE '([0-9][0-9][0-9]) [0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
BirthDate date CONSTRAINT CK_EmployeeInfos_BirthDate CHECK (BirthDate > '01/01/1950'),
CONSTRAINT PK_EmployeeInfos_Id PRIMARY KEY (Id)
);
GO

CREATE TABLE PositionInfos
(
Id int IDENTITY(1,1),
Name nvarchar(30),
Salary money CONSTRAINT CK_PositionInfos_Salary CHECK (Salary >= 4173),
CONSTRAINT PK_PositionInfos_Id PRIMARY KEY (Id)
);
GO

CREATE TABLE ProjectInfos
(
Id int IDENTITY(1,1),
Name nvarchar(30),
CreatingDate date,
[State] bit, -- varchar(5) CONSTRAINT CK_ProjectInfos_State CHECK ([State] IN ('open', 'closed')),
ClosingDate date NULL,
CONSTRAINT PK_ProjectInfos_Id PRIMARY KEY (Id)
);
GO

CREATE TABLE TaskList
(
Id int IDENTITY(1,1),
ProjectId int NOT NULL,
EmployeeId int NOT NULL,
PositionId int NOT NULL,
CONSTRAINT PK_TaskList_Id PRIMARY KEY (Id),
CONSTRAINT FK_TaskList_EmployeeId FOREIGN KEY (EmployeeId) REFERENCES EmployeeInfos(Id),
CONSTRAINT FK_TaskList_ProjectId FOREIGN KEY (ProjectId) REFERENCES ProjectInfos(Id),
CONSTRAINT FK_TaskList_PositionId FOREIGN KEY (PositionId) REFERENCES PositionInfos(Id)
);
GO

CREATE TABLE TaskInfos
(
TaskId int UNIQUE NOT NULL,
[Status] nvarchar(12) CONSTRAINT CK_TaskInfo_Status CHECK ([Status] IN ('open', 'done', 'not done yet', 'closed')),
[DateCheck] date,
DeadLine date
CONSTRAINT FK_TaskInfo_Id FOREIGN KEY (TaskId) REFERENCES TaskList(Id)
ON DELETE CASCADE
ON UPDATE CASCADE
);
GO