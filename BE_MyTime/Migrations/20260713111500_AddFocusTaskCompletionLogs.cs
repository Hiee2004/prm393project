using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BE_MyTime.Migrations
{
    public partial class AddFocusTaskCompletionLogs : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "focus_task_completions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FocusTaskId = table.Column<int>(type: "int", nullable: false),
                    CompletedOn = table.Column<DateTime>(type: "date", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_focus_task_completions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_focus_task_completions_focus_tasks_FocusTaskId",
                        column: x => x.FocusTaskId,
                        principalTable: "focus_tasks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_focus_task_completions_FocusTaskId_CompletedOn",
                table: "focus_task_completions",
                columns: new[] { "FocusTaskId", "CompletedOn" },
                unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "focus_task_completions");
        }
    }
}
