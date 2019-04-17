USE Company
GO

-- 1. Получить список всех должностей компании с количеством сотрудников на каждой из них.
SELECT p.Name Position, COUNT(t.PositionId) AS [Count] FROM PositionInfos AS p
LEFT OUTER JOIN TaskList t ON t.PositionId=p.Id
GROUP BY p.Name
GO

-- 2. Определить список должностей компании, на которых нет сотрудников.
SELECT s.Name Position FROM
(SELECT p.Name, COUNT(t.PositionId) AS [Count] FROM PositionInfos AS p
LEFT OUTER JOIN TaskList t ON t.PositionId=p.Id
GROUP BY p.Name) s
WHERE s.[Count] = 0
GO

-- 3. Получить список проектов с указанием, сколько сотрудников каждой должности работает на проекте.
SELECT s.Name Project, p.Name Position, COUNT(t.ProjectId) [Count] FROM ProjectInfos s
JOIN TaskList t ON t.ProjectId=s.Id
JOIN PositionInfos p ON p.Id=t.EmployeeId
GROUP BY s.Name, p.Name
ORDER BY s.Name, p.Name
GO

-- 4. Посчитать на каждом проекте, какое в среднем количество задач приходится на каждого сотрудника.
SELECT s.Project, SUM(s.Tasks)/COUNT(s.EmployeeId) [Tasks/Employee] FROM
(SELECT p.Name Project, t.EmployeeId, COUNT(t.Id) Tasks FROM ProjectInfos p
JOIN TaskList t ON t.ProjectId=p.Id GROUP BY p.Name, t.EmployeeId) s
GROUP BY s.Project
GO

-- 5. Подсчитать длительность выполнения каждого проекта.
SELECT Name, DATEDIFF(DAY, CreatingDate, ClosingDate) Days FROM ProjectInfos
GO

-- 6. Определить сотрудников с минимальным количеством незакрытых задач.
SELECT /*TOP(2)*/ e.LName+' '+e.FName+' '+e.MName FullName, s.CountTask FROM 
(SELECT tl.EmployeeId, COUNT(tl.EmployeeId) CountTask FROM TaskInfos ti
JOIN TaskList tl ON ti.TaskId=tl.Id
WHERE ti.[Status] IN ('open', 'done', 'not done yet')
GROUP BY tl.EmployeeId) s
JOIN EmployeeInfos e ON e.Id=s.EmployeeId
ORDER BY s.CountTask
GO

-- 7. Определить сотрудников с максимальным количеством незакрытых задач, дедлайн которых уже истек.
SELECT /*TOP(2)*/ e.LName+' '+e.FName+' '+e.MName FullName, s.CountTask FROM 
(SELECT tl.EmployeeId, COUNT(tl.EmployeeId) CountTask FROM TaskInfos ti
JOIN TaskList tl ON ti.TaskId=tl.Id
WHERE ti.[Status] IN ('open', 'done', 'not done yet') AND ti.DeadLine < ti.DateCheck
GROUP BY tl.EmployeeId) s
JOIN EmployeeInfos e ON e.Id=s.EmployeeId
ORDER BY s.CountTask DESC
GO

-- 8. Продлить дедлайн незакрытых задач на 5 дней.
UPDATE TaskInfos
SET DeadLine = DATEADD(DAY, 5, Deadline)
WHERE TaskId IN (SELECT TaskId FROM TaskInfos WHERE [Status] LIKE 'closed')
GO

-- 9. Посчитать на каждом проекте количество задач, к которым еще не приступили.
SELECT p.Name, COUNT(ti.[Status]) OpenTask FROM TaskList t
JOIN ProjectInfos p ON p.Id=t.ProjectId
JOIN TaskInfos ti ON ti.TaskId=t.Id
WHERE ti.[Status] LIKE 'open'
GROUP BY p.Name
GO 

-- 10. Перевести проекты в состояние закрыт, для которых все задачи закрыты и задать время закрытия временем закрытия задачи проекта, принятой последней.
 CREATE PROCEDURE spUpdateClosedProject

 AS
	 SET NOCOUNT ON;

	 DECLARE @projectIds TABLE
	 (Id int);

	 DECLARE @closingdates TABLE
	 (Id int, cdate date);

	  INSERT INTO @projectIds SELECT s.Id FROM (SELECT p.Id, COUNT(t.Id) ClosedTasks FROM ProjectInfos p
												    JOIN TaskList t ON t.ProjectId=p.Id
												    JOIN TaskInfos ti ON ti.TaskId=t.Id
												    WHERE ti.[Status] LIKE 'closed'
												    GROUP BY p.Id
												INTERSECT
												    SELECT p.Id, COUNT(t.Id) Tasks FROM ProjectInfos p
												    JOIN TaskList t ON t.ProjectId=p.Id GROUP BY p.Id) s
														
	  INSERT INTO @closingdates SELECT t.ProjectId, ti.DateCheck FROM TaskList t
								JOIN TaskInfos ti ON ti.TaskId=t.Id
								WHERE ti.[Status] LIKE 'closed' AND t.ProjectId IN (SELECT Id FROM @projectIds)

	 UPDATE ProjectInfos
	 SET [State] = 1, ClosingDate = (SELECT r.[Date] FROM (SELECT Id, MAX(cdate) [Date] FROM @closingdates GROUP BY Id) r)
	 WHERE Id = (SELECT Id FROM @projectIds)
 GO

EXEC spUpdateClosedProject

-- 11. Выяснить по всем проектам, какие сотрудники на проекте не имеют незакрытых задач.
	SELECT p.Name, e.LName FROM ProjectInfos p
	JOIN TaskList t ON t.ProjectId=p.Id
	JOIN EmployeeInfos e ON e.Id=t.EmployeeId
	JOIN TaskInfos ti ON t.Id=ti.TaskId
EXCEPT
	SELECT p.Name, e.LName FROM ProjectInfos p
	JOIN TaskList t ON t.ProjectId=p.Id
	JOIN EmployeeInfos e ON e.Id=t.EmployeeId
	JOIN TaskInfos ti ON t.Id=ti.TaskId
	WHERE ti.[Status] LIKE 'closed'
GO

-- 12. Заданную задачу (по названию) проекта перевести на сотрудника с минимальным количеством выполняемых им задач.
CREATE PROCEDURE spSetTaskForEmployee
@taskNumber int
AS
	SET NOCOUNT ON;

	DECLARE @temp int

	SET @temp = (SELECT TOP(1) s.EmployeeId FROM 
				(SELECT tl.EmployeeId, COUNT(tl.EmployeeId) CountTask FROM TaskInfos ti
				JOIN TaskList tl ON ti.TaskId=tl.Id
				GROUP BY tl.EmployeeId) s
				ORDER BY s.CountTask)

	UPDATE TaskList
	SET EmployeeId = @temp
	WHERE Id = @taskNumber

GO

EXECUTE spSetTaskForEmployee 7