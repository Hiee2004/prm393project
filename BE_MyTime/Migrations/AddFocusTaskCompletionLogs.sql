IF OBJECT_ID(N'[focus_task_completions]', N'U') IS NULL
BEGIN
    CREATE TABLE [focus_task_completions] (
        [Id] int NOT NULL IDENTITY,
        [FocusTaskId] int NOT NULL,
        [CompletedOn] date NOT NULL,
        [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
        CONSTRAINT [PK_focus_task_completions] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_focus_task_completions_focus_tasks_FocusTaskId]
            FOREIGN KEY ([FocusTaskId]) REFERENCES [focus_tasks] ([Id]) ON DELETE CASCADE
    );

    CREATE UNIQUE INDEX [IX_focus_task_completions_FocusTaskId_CompletedOn]
        ON [focus_task_completions] ([FocusTaskId], [CompletedOn]);
END
GO
