using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BE_MyTime.Migrations
{
    /// <inheritdoc />
    public partial class SmartScheduling : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "EnergyProfileJson",
                table: "user_settings",
                type: "nvarchar(2000)",
                maxLength: 2000,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "Deadline",
                table: "focus_tasks",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Difficulty",
                table: "focus_tasks",
                type: "int",
                nullable: false,
                defaultValue: 3);

            migrationBuilder.CreateTable(
                name: "scheduled_tasks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    FocusTaskId = table.Column<int>(type: "int", nullable: false),
                    TitleSnapshot = table.Column<string>(type: "nvarchar(180)", maxLength: 180, nullable: false),
                    StartTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EndTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SessionNumber = table.Column<int>(type: "int", nullable: false),
                    AiScore = table.Column<double>(type: "float(8)", precision: 8, scale: 2, nullable: false),
                    IsOverlapAllowed = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_scheduled_tasks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_scheduled_tasks_focus_tasks_FocusTaskId",
                        column: x => x.FocusTaskId,
                        principalTable: "focus_tasks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_scheduled_tasks_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.NoAction);
                });

            migrationBuilder.CreateIndex(
                name: "IX_focus_tasks_UserId_Deadline",
                table: "focus_tasks",
                columns: new[] { "UserId", "Deadline" });

            migrationBuilder.CreateIndex(
                name: "IX_scheduled_tasks_FocusTaskId_SessionNumber",
                table: "scheduled_tasks",
                columns: new[] { "FocusTaskId", "SessionNumber" });

            migrationBuilder.CreateIndex(
                name: "IX_scheduled_tasks_UserId_StartTime",
                table: "scheduled_tasks",
                columns: new[] { "UserId", "StartTime" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "scheduled_tasks");

            migrationBuilder.DropIndex(
                name: "IX_focus_tasks_UserId_Deadline",
                table: "focus_tasks");

            migrationBuilder.DropColumn(
                name: "EnergyProfileJson",
                table: "user_settings");

            migrationBuilder.DropColumn(
                name: "Deadline",
                table: "focus_tasks");

            migrationBuilder.DropColumn(
                name: "Difficulty",
                table: "focus_tasks");
        }
    }
}
