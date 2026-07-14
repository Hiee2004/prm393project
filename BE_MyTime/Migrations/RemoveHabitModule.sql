IF OBJECT_ID(N'[habit_logs]', N'U') IS NOT NULL
BEGIN
    DROP TABLE [habit_logs];
END
GO

IF OBJECT_ID(N'[user_progress]', N'U') IS NOT NULL
BEGIN
    DROP TABLE [user_progress];
END
GO

IF OBJECT_ID(N'[habits]', N'U') IS NOT NULL
BEGIN
    DROP TABLE [habits];
END
GO
