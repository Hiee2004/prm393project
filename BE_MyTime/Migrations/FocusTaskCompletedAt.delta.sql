BEGIN TRANSACTION;
GO

ALTER TABLE [focus_tasks] ADD [CompletedAt] datetime2 NULL;
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260712134340_FocusTaskCompletedAt', N'8.0.8');
GO

COMMIT;
GO

