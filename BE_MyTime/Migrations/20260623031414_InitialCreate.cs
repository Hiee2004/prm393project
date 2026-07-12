using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BE_MyTime.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FullName = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    Email = table.Column<string>(type: "nvarchar(180)", maxLength: 180, nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    AuthProvider = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    GoogleId = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    AvatarUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    GoogleAccessToken = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    GoogleRefreshToken = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    GoogleTokenExpiredAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ai_plan_drafts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    OriginalInput = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    SuggestedTitle = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true),
                    SuggestedDescription = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    SuggestedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    SuggestedStartTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    SuggestedEndTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    SuggestedFocusMinutes = table.Column<int>(type: "int", nullable: false),
                    SuggestedPriority = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    SuggestedOutputsJson = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    Reason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    Status = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    ConfirmedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_plan_drafts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ai_plan_drafts_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "focus_tasks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(180)", maxLength: 180, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    FocusMinutes = table.Column<int>(type: "int", nullable: false, defaultValue: 25),
                    Priority = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    ScheduledDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    StartTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    EndTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    Repeat = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    ReminderEnabled = table.Column<bool>(type: "bit", nullable: false),
                    ReminderTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    SyncToGoogleCalendar = table.Column<bool>(type: "bit", nullable: false),
                    GoogleCalendarEventId = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_focus_tasks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_focus_tasks_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "user_settings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    DefaultFocusMinutes = table.Column<int>(type: "int", nullable: false, defaultValue: 25),
                    NotificationEnabled = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    AutoSyncGoogleCalendar = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    DailyReviewEnabled = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    DailyReviewTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    PreferredFocusStartTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    PreferredFocusEndTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    TimeZone = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false, defaultValue: "Asia/Ho_Chi_Minh"),
                    ThemeMode = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false, defaultValue: "Light"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_settings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_user_settings_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "focus_outputs",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FocusTaskId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(250)", maxLength: 250, nullable: false),
                    IsCompleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_focus_outputs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_focus_outputs_focus_tasks_FocusTaskId",
                        column: x => x.FocusTaskId,
                        principalTable: "focus_tasks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "focus_sessions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    FocusTaskId = table.Column<int>(type: "int", nullable: false),
                    PlannedSeconds = table.Column<int>(type: "int", nullable: false),
                    ActualFocusSeconds = table.Column<int>(type: "int", nullable: false),
                    CompletedOutputs = table.Column<int>(type: "int", nullable: false),
                    TotalOutputs = table.Column<int>(type: "int", nullable: false),
                    DistractionCount = table.Column<int>(type: "int", nullable: false),
                    TotalDistractionSeconds = table.Column<int>(type: "int", nullable: false),
                    FocusScore = table.Column<double>(type: "float(5)", precision: 5, scale: 2, nullable: false),
                    FeedbackTitle = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: true),
                    FeedbackMessage = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    StartedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_focus_sessions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_focus_sessions_focus_tasks_FocusTaskId",
                        column: x => x.FocusTaskId,
                        principalTable: "focus_tasks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_focus_sessions_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "google_calendar_links",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FocusTaskId = table.Column<int>(type: "int", nullable: false),
                    CalendarId = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    EventId = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    SyncedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_google_calendar_links", x => x.Id);
                    table.ForeignKey(
                        name: "FK_google_calendar_links_focus_tasks_FocusTaskId",
                        column: x => x.FocusTaskId,
                        principalTable: "focus_tasks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "notifications",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    FocusTaskId = table.Column<int>(type: "int", nullable: true),
                    Title = table.Column<string>(type: "nvarchar(160)", maxLength: 160, nullable: false),
                    Message = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    Type = table.Column<string>(type: "nvarchar(40)", maxLength: 40, nullable: false),
                    IsRead = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    ScheduledAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    SentAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notifications", x => x.Id);
                    table.ForeignKey(
                        name: "FK_notifications_focus_tasks_FocusTaskId",
                        column: x => x.FocusTaskId,
                        principalTable: "focus_tasks",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_notifications_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ai_focus_evaluations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FocusSessionId = table.Column<int>(type: "int", nullable: false),
                    DistractionLevel = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    DistractionScore = table.Column<double>(type: "float(5)", precision: 5, scale: 2, nullable: false),
                    FocusScore = table.Column<double>(type: "float(5)", precision: 5, scale: 2, nullable: false),
                    FeedbackTitle = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    FeedbackMessage = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    Suggestion = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    RawAiResponse = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_focus_evaluations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ai_focus_evaluations_focus_sessions_FocusSessionId",
                        column: x => x.FocusSessionId,
                        principalTable: "focus_sessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "distraction_events",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FocusSessionId = table.Column<int>(type: "int", nullable: false),
                    Type = table.Column<string>(type: "nvarchar(40)", maxLength: 40, nullable: false),
                    DurationSeconds = table.Column<int>(type: "int", nullable: false),
                    OccurredAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    Note = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_distraction_events", x => x.Id);
                    table.ForeignKey(
                        name: "FK_distraction_events_focus_sessions_FocusSessionId",
                        column: x => x.FocusSessionId,
                        principalTable: "focus_sessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ai_focus_evaluations_FocusSessionId",
                table: "ai_focus_evaluations",
                column: "FocusSessionId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ai_plan_drafts_UserId_Status",
                table: "ai_plan_drafts",
                columns: new[] { "UserId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_distraction_events_FocusSessionId",
                table: "distraction_events",
                column: "FocusSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_focus_outputs_FocusTaskId",
                table: "focus_outputs",
                column: "FocusTaskId");

            migrationBuilder.CreateIndex(
                name: "IX_focus_sessions_FocusTaskId",
                table: "focus_sessions",
                column: "FocusTaskId");

            migrationBuilder.CreateIndex(
                name: "IX_focus_sessions_UserId_StartedAt",
                table: "focus_sessions",
                columns: new[] { "UserId", "StartedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_focus_tasks_UserId_ScheduledDate",
                table: "focus_tasks",
                columns: new[] { "UserId", "ScheduledDate" });

            migrationBuilder.CreateIndex(
                name: "IX_focus_tasks_UserId_Status",
                table: "focus_tasks",
                columns: new[] { "UserId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_google_calendar_links_FocusTaskId",
                table: "google_calendar_links",
                column: "FocusTaskId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_notifications_FocusTaskId",
                table: "notifications",
                column: "FocusTaskId");

            migrationBuilder.CreateIndex(
                name: "IX_notifications_ScheduledAt",
                table: "notifications",
                column: "ScheduledAt");

            migrationBuilder.CreateIndex(
                name: "IX_notifications_UserId_IsRead",
                table: "notifications",
                columns: new[] { "UserId", "IsRead" });

            migrationBuilder.CreateIndex(
                name: "IX_user_settings_UserId",
                table: "user_settings",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_Email",
                table: "users",
                column: "Email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ai_focus_evaluations");

            migrationBuilder.DropTable(
                name: "ai_plan_drafts");

            migrationBuilder.DropTable(
                name: "distraction_events");

            migrationBuilder.DropTable(
                name: "focus_outputs");

            migrationBuilder.DropTable(
                name: "google_calendar_links");

            migrationBuilder.DropTable(
                name: "notifications");

            migrationBuilder.DropTable(
                name: "user_settings");

            migrationBuilder.DropTable(
                name: "focus_sessions");

            migrationBuilder.DropTable(
                name: "focus_tasks");

            migrationBuilder.DropTable(
                name: "users");
        }
    }
}
