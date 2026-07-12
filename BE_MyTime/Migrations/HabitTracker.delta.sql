BEGIN TRANSACTION;
GO

CREATE TABLE [habits] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [Title] nvarchar(160) NOT NULL,
    [Description] nvarchar(600) NULL,
    [FrequencyType] nvarchar(20) NOT NULL,
    [WeekDaysCsv] nvarchar(60) NULL,
    [TargetCount] int NOT NULL DEFAULT 1,
    [ReminderTime] time NULL,
    [ColorHex] nvarchar(20) NOT NULL DEFAULT N'#58CC02',
    [IconName] nvarchar(40) NOT NULL DEFAULT N'local_fire_department_rounded',
    [IsArchived] bit NOT NULL DEFAULT CAST(0 AS bit),
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_habits] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_habits_users_UserId] FOREIGN KEY ([UserId]) REFERENCES [users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [user_progress] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [Xp] int NOT NULL,
    [Level] int NOT NULL DEFAULT 1,
    [CurrentStreak] int NOT NULL,
    [BestStreak] int NOT NULL,
    [TotalHabitCompletions] int NOT NULL,
    [LastCompletedOn] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_user_progress] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_user_progress_users_UserId] FOREIGN KEY ([UserId]) REFERENCES [users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [habit_logs] (
    [Id] int NOT NULL IDENTITY,
    [HabitId] int NOT NULL,
    [CompletedOn] datetime2 NOT NULL,
    [Count] int NOT NULL DEFAULT 1,
    [IsCompleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [EarnedXp] int NOT NULL DEFAULT 0,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_habit_logs] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_habit_logs_habits_HabitId] FOREIGN KEY ([HabitId]) REFERENCES [habits] ([Id]) ON DELETE CASCADE
);
GO

CREATE UNIQUE INDEX [IX_habit_logs_HabitId_CompletedOn] ON [habit_logs] ([HabitId], [CompletedOn]);
GO

CREATE INDEX [IX_habits_UserId_IsArchived] ON [habits] ([UserId], [IsArchived]);
GO

CREATE UNIQUE INDEX [IX_user_progress_UserId] ON [user_progress] ([UserId]);
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260711231958_HabitTracker', N'8.0.8');
GO

COMMIT;
GO

