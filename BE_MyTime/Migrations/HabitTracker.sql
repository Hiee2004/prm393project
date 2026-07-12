IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

CREATE TABLE [users] (
    [Id] int NOT NULL IDENTITY,
    [FullName] nvarchar(120) NOT NULL,
    [Email] nvarchar(180) NOT NULL,
    [PasswordHash] nvarchar(500) NULL,
    [AuthProvider] nvarchar(30) NOT NULL,
    [GoogleId] nvarchar(200) NULL,
    [AvatarUrl] nvarchar(500) NULL,
    [GoogleAccessToken] nvarchar(2000) NULL,
    [GoogleRefreshToken] nvarchar(2000) NULL,
    [GoogleTokenExpiredAt] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_users] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [ai_plan_drafts] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [OriginalInput] nvarchar(300) NOT NULL,
    [SuggestedTitle] nvarchar(300) NULL,
    [SuggestedDescription] nvarchar(1000) NULL,
    [SuggestedDate] datetime2 NULL,
    [SuggestedStartTime] time NULL,
    [SuggestedEndTime] time NULL,
    [SuggestedFocusMinutes] int NOT NULL,
    [SuggestedPriority] nvarchar(30) NOT NULL,
    [SuggestedOutputsJson] nvarchar(4000) NULL,
    [Reason] nvarchar(1000) NULL,
    [Status] nvarchar(30) NOT NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [ConfirmedAt] datetime2 NULL,
    CONSTRAINT [PK_ai_plan_drafts] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ai_plan_drafts_users_UserId] FOREIGN KEY ([UserId]) REFERENCES [users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [focus_tasks] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [Title] nvarchar(180) NOT NULL,
    [Description] nvarchar(1000) NULL,
    [FocusMinutes] int NOT NULL DEFAULT 25,
    [Priority] nvarchar(30) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [ScheduledDate] datetime2 NULL,
    [StartTime] time NULL,
    [EndTime] time NULL,
    [Repeat] nvarchar(30) NOT NULL,
    [ReminderEnabled] bit NOT NULL,
    [ReminderTime] time NULL,
    [SyncToGoogleCalendar] bit NOT NULL,
    [GoogleCalendarEventId] nvarchar(300) NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_focus_tasks] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_focus_tasks_users_UserId] FOREIGN KEY ([UserId]) REFERENCES [users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [user_settings] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [DefaultFocusMinutes] int NOT NULL DEFAULT 25,
    [NotificationEnabled] bit NOT NULL DEFAULT CAST(1 AS bit),
    [AutoSyncGoogleCalendar] bit NOT NULL DEFAULT CAST(0 AS bit),
    [DailyReviewEnabled] bit NOT NULL DEFAULT CAST(1 AS bit),
    [DailyReviewTime] time NULL,
    [PreferredFocusStartTime] time NULL,
    [PreferredFocusEndTime] time NULL,
    [TimeZone] nvarchar(80) NOT NULL DEFAULT N'Asia/Ho_Chi_Minh',
    [ThemeMode] nvarchar(30) NOT NULL DEFAULT N'Light',
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_user_settings] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_user_settings_users_UserId] FOREIGN KEY ([UserId]) REFERENCES [users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [focus_outputs] (
    [Id] int NOT NULL IDENTITY,
    [FocusTaskId] int NOT NULL,
    [Title] nvarchar(250) NOT NULL,
    [IsCompleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [CompletedAt] datetime2 NULL,
    [SortOrder] int NOT NULL DEFAULT 0,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    CONSTRAINT [PK_focus_outputs] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_focus_outputs_focus_tasks_FocusTaskId] FOREIGN KEY ([FocusTaskId]) REFERENCES [focus_tasks] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [focus_sessions] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [FocusTaskId] int NOT NULL,
    [PlannedSeconds] int NOT NULL,
    [ActualFocusSeconds] int NOT NULL,
    [CompletedOutputs] int NOT NULL,
    [TotalOutputs] int NOT NULL,
    [DistractionCount] int NOT NULL,
    [TotalDistractionSeconds] int NOT NULL,
    [FocusScore] float(5) NOT NULL,
    [FeedbackTitle] nvarchar(120) NULL,
    [FeedbackMessage] nvarchar(1000) NULL,
    [StartedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [CompletedAt] datetime2 NULL,
    CONSTRAINT [PK_focus_sessions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_focus_sessions_focus_tasks_FocusTaskId] FOREIGN KEY ([FocusTaskId]) REFERENCES [focus_tasks] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_focus_sessions_users_UserId] FOREIGN KEY ([UserId]) REFERENCES [users] ([Id])
);
GO

CREATE TABLE [google_calendar_links] (
    [Id] int NOT NULL IDENTITY,
    [FocusTaskId] int NOT NULL,
    [CalendarId] nvarchar(300) NOT NULL,
    [EventId] nvarchar(300) NOT NULL,
    [SyncedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_google_calendar_links] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_google_calendar_links_focus_tasks_FocusTaskId] FOREIGN KEY ([FocusTaskId]) REFERENCES [focus_tasks] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [notifications] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [FocusTaskId] int NULL,
    [Title] nvarchar(160) NOT NULL,
    [Message] nvarchar(1000) NOT NULL,
    [Type] nvarchar(40) NOT NULL,
    [IsRead] bit NOT NULL DEFAULT CAST(0 AS bit),
    [ScheduledAt] datetime2 NULL,
    [SentAt] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    CONSTRAINT [PK_notifications] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_notifications_focus_tasks_FocusTaskId] FOREIGN KEY ([FocusTaskId]) REFERENCES [focus_tasks] ([Id]),
    CONSTRAINT [FK_notifications_users_UserId] FOREIGN KEY ([UserId]) REFERENCES [users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [ai_focus_evaluations] (
    [Id] int NOT NULL IDENTITY,
    [FocusSessionId] int NOT NULL,
    [DistractionLevel] nvarchar(30) NOT NULL,
    [DistractionScore] float(5) NOT NULL,
    [FocusScore] float(5) NOT NULL,
    [FeedbackTitle] nvarchar(120) NOT NULL,
    [FeedbackMessage] nvarchar(1000) NOT NULL,
    [Suggestion] nvarchar(1000) NOT NULL,
    [RawAiResponse] nvarchar(2000) NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    CONSTRAINT [PK_ai_focus_evaluations] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ai_focus_evaluations_focus_sessions_FocusSessionId] FOREIGN KEY ([FocusSessionId]) REFERENCES [focus_sessions] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [distraction_events] (
    [Id] int NOT NULL IDENTITY,
    [FocusSessionId] int NOT NULL,
    [Type] nvarchar(40) NOT NULL,
    [DurationSeconds] int NOT NULL,
    [OccurredAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [Note] nvarchar(500) NULL,
    CONSTRAINT [PK_distraction_events] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_distraction_events_focus_sessions_FocusSessionId] FOREIGN KEY ([FocusSessionId]) REFERENCES [focus_sessions] ([Id]) ON DELETE CASCADE
);
GO

CREATE UNIQUE INDEX [IX_ai_focus_evaluations_FocusSessionId] ON [ai_focus_evaluations] ([FocusSessionId]);
GO

CREATE INDEX [IX_ai_plan_drafts_UserId_Status] ON [ai_plan_drafts] ([UserId], [Status]);
GO

CREATE INDEX [IX_distraction_events_FocusSessionId] ON [distraction_events] ([FocusSessionId]);
GO

CREATE INDEX [IX_focus_outputs_FocusTaskId] ON [focus_outputs] ([FocusTaskId]);
GO

CREATE INDEX [IX_focus_sessions_FocusTaskId] ON [focus_sessions] ([FocusTaskId]);
GO

CREATE INDEX [IX_focus_sessions_UserId_StartedAt] ON [focus_sessions] ([UserId], [StartedAt]);
GO

CREATE INDEX [IX_focus_tasks_UserId_ScheduledDate] ON [focus_tasks] ([UserId], [ScheduledDate]);
GO

CREATE INDEX [IX_focus_tasks_UserId_Status] ON [focus_tasks] ([UserId], [Status]);
GO

CREATE UNIQUE INDEX [IX_google_calendar_links_FocusTaskId] ON [google_calendar_links] ([FocusTaskId]);
GO

CREATE INDEX [IX_notifications_FocusTaskId] ON [notifications] ([FocusTaskId]);
GO

CREATE INDEX [IX_notifications_ScheduledAt] ON [notifications] ([ScheduledAt]);
GO

CREATE INDEX [IX_notifications_UserId_IsRead] ON [notifications] ([UserId], [IsRead]);
GO

CREATE UNIQUE INDEX [IX_user_settings_UserId] ON [user_settings] ([UserId]);
GO

CREATE UNIQUE INDEX [IX_users_Email] ON [users] ([Email]);
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260623031414_InitialCreate', N'8.0.8');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

ALTER TABLE [user_settings] ADD [EnergyProfileJson] nvarchar(2000) NULL;
GO

ALTER TABLE [focus_tasks] ADD [Deadline] datetime2 NULL;
GO

ALTER TABLE [focus_tasks] ADD [Difficulty] int NOT NULL DEFAULT 3;
GO

CREATE TABLE [scheduled_tasks] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [FocusTaskId] int NOT NULL,
    [TitleSnapshot] nvarchar(180) NOT NULL,
    [StartTime] datetime2 NOT NULL,
    [EndTime] datetime2 NOT NULL,
    [SessionNumber] int NOT NULL,
    [AiScore] float(8) NOT NULL,
    [IsOverlapAllowed] bit NOT NULL DEFAULT CAST(1 AS bit),
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NULL,
    CONSTRAINT [PK_scheduled_tasks] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_scheduled_tasks_focus_tasks_FocusTaskId] FOREIGN KEY ([FocusTaskId]) REFERENCES [focus_tasks] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_scheduled_tasks_users_UserId] FOREIGN KEY ([UserId]) REFERENCES [users] ([Id])
);
GO

CREATE INDEX [IX_focus_tasks_UserId_Deadline] ON [focus_tasks] ([UserId], [Deadline]);
GO

CREATE INDEX [IX_scheduled_tasks_FocusTaskId_SessionNumber] ON [scheduled_tasks] ([FocusTaskId], [SessionNumber]);
GO

CREATE INDEX [IX_scheduled_tasks_UserId_StartTime] ON [scheduled_tasks] ([UserId], [StartTime]);
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260707025934_SmartScheduling', N'8.0.8');
GO

COMMIT;
GO

