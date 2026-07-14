using BE_MyTime.Models;
using Microsoft.EntityFrameworkCore;

namespace BE_MyTime.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {

        }
        public DbSet<User> Users => Set<User>();

        public DbSet<UserSetting> UserSettings => Set<UserSetting>();

        public DbSet<FocusTask> FocusTasks => Set<FocusTask>();

        public DbSet<FocusOutput> FocusOutputs => Set<FocusOutput>();

        public DbSet<FocusSession> FocusSessions => Set<FocusSession>();

        public DbSet<FocusTaskCompletion> FocusTaskCompletions => Set<FocusTaskCompletion>();

        public DbSet<DistractionEvent> DistractionEvents => Set<DistractionEvent>();

        public DbSet<AiFocusEvaluation> AiFocusEvaluations => Set<AiFocusEvaluation>();

        public DbSet<Notification> Notifications => Set<Notification>();

        public DbSet<AiPlanDraft> AiPlanDrafts => Set<AiPlanDraft>();

        public DbSet<GoogleCalendarLink> GoogleCalendarLinks => Set<GoogleCalendarLink>();

        public DbSet<ScheduledTask> ScheduledTasks => Set<ScheduledTask>();
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            ConfigureUsers(modelBuilder);
            ConfigureUserSettings(modelBuilder);
            ConfigureFocusTasks(modelBuilder);
            ConfigureFocusOutputs(modelBuilder);
            ConfigureFocusSessions(modelBuilder);
            ConfigureFocusTaskCompletions(modelBuilder);
            ConfigureDistractionEvents(modelBuilder);
            ConfigureAiFocusEvaluations(modelBuilder);
            ConfigureNotifications(modelBuilder);
            ConfigureAiPlanDrafts(modelBuilder);
            ConfigureGoogleCalendarLinks(modelBuilder);
            ConfigureScheduledTasks(modelBuilder);
        }

        private static void ConfigureUsers(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>(entity =>
            {
                entity.ToTable("users");

                entity.HasKey(x => x.Id);

                entity.Property(x => x.FullName)
                    .IsRequired()
                    .HasMaxLength(120);

                entity.Property(x => x.Email)
                    .IsRequired()
                    .HasMaxLength(180);

                entity.HasIndex(x => x.Email)
                    .IsUnique();

                entity.Property(x => x.PasswordHash)
                    .HasMaxLength(500);

                entity.Property(x => x.AuthProvider)
                    .HasConversion<string>()
                    .HasMaxLength(30);

                entity.Property(x => x.GoogleId)
                    .HasMaxLength(200);

                entity.Property(x => x.AvatarUrl)
                    .HasMaxLength(500);

                entity.Property(x => x.GoogleAccessToken)
                    .HasMaxLength(2000);

                entity.Property(x => x.GoogleRefreshToken)
                    .HasMaxLength(2000);

                entity.Property(x => x.CreatedAt)
                    .HasDefaultValueSql("GETUTCDATE()");
            });
        }

        private static void ConfigureUserSettings(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<UserSetting>(entity =>
            {
                entity.ToTable("user_settings");

                entity.HasKey(x => x.Id);

                entity.HasIndex(x => x.UserId)
                    .IsUnique();

                entity.Property(x => x.DefaultFocusMinutes)
                    .HasDefaultValue(25);

                entity.Property(x => x.NotificationEnabled)
                    .HasDefaultValue(true);

                entity.Property(x => x.AutoSyncGoogleCalendar)
                    .HasDefaultValue(false);

                entity.Property(x => x.DailyReviewEnabled)
                    .HasDefaultValue(true);

                entity.Property(x => x.TimeZone)
                    .HasMaxLength(80)
                    .HasDefaultValue("Asia/Ho_Chi_Minh");

                entity.Property(x => x.ThemeMode)
                    .HasMaxLength(30)
                    .HasDefaultValue("Light");

                entity.Property(x => x.EnergyProfileJson)
                    .HasMaxLength(2000);

                entity.HasOne(x => x.User)
                    .WithOne(x => x.Setting)
                    .HasForeignKey<UserSetting>(x => x.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        private static void ConfigureFocusTasks(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<FocusTask>(entity =>
            {
                entity.ToTable("focus_tasks");

                entity.HasKey(x => x.Id);

                entity.Property(x => x.Title)
                    .IsRequired()
                    .HasMaxLength(180);

                entity.Property(x => x.Description)
                    .HasMaxLength(1000);

                entity.Property(x => x.FocusMinutes)
                    .HasDefaultValue(25);

                entity.Property(x => x.Difficulty)
                    .HasDefaultValue(3);

                entity.Property(x => x.Priority)
                    .HasConversion<string>()
                    .HasMaxLength(30);

                entity.Property(x => x.Status)
                    .HasConversion<string>()
                    .HasMaxLength(30);

                entity.Property(x => x.Repeat)
                    .HasConversion<string>()
                    .HasMaxLength(30);

                entity.Property(x => x.GoogleCalendarEventId)
                    .HasMaxLength(300);

                entity.Property(x => x.CompletedAt);

                entity.HasIndex(x => new { x.UserId, x.Deadline });

                entity.Property(x => x.CreatedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasIndex(x => new { x.UserId, x.ScheduledDate });

                entity.HasIndex(x => new { x.UserId, x.Status });

                entity.HasOne(x => x.User)
                    .WithMany(x => x.FocusTasks)
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        private static void ConfigureFocusOutputs(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<FocusOutput>(entity =>
            {
                entity.ToTable("focus_outputs");

                entity.HasKey(x => x.Id);

                entity.Property(x => x.Title)
                    .IsRequired()
                    .HasMaxLength(250);

                entity.Property(x => x.IsCompleted)
                    .HasDefaultValue(false);

                entity.Property(x => x.SortOrder)
                    .HasDefaultValue(0);

                entity.Property(x => x.CreatedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasIndex(x => x.FocusTaskId);

                entity.HasOne(x => x.FocusTask)
                    .WithMany(x => x.Outputs)
                    .HasForeignKey(x => x.FocusTaskId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        private static void ConfigureFocusSessions(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<FocusSession>(entity =>
            {
                entity.ToTable("focus_sessions");

                entity.HasKey(x => x.Id);

                entity.Property(x => x.FocusScore)
                    .HasPrecision(5, 2);

                entity.Property(x => x.FeedbackTitle)
                    .HasMaxLength(120);

                entity.Property(x => x.FeedbackMessage)
                    .HasMaxLength(1000);

                entity.Property(x => x.StartedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasIndex(x => new { x.UserId, x.StartedAt });

                entity.HasIndex(x => x.FocusTaskId);

                entity.HasOne(x => x.User)
                    .WithMany(x => x.FocusSessions)
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.NoAction);

                entity.HasOne(x => x.FocusTask)
                    .WithMany(x => x.Sessions)
                    .HasForeignKey(x => x.FocusTaskId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        private static void ConfigureDistractionEvents(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DistractionEvent>(entity =>
            {
                entity.ToTable("distraction_events");

                entity.HasKey(x => x.Id);

                entity.Property(x => x.Type)
                    .HasConversion<string>()
                    .HasMaxLength(40);

                entity.Property(x => x.Note)
                    .HasMaxLength(500);

                entity.Property(x => x.OccurredAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasIndex(x => x.FocusSessionId);

                entity.HasOne(x => x.FocusSession)
                    .WithMany(x => x.DistractionEvents)
                    .HasForeignKey(x => x.FocusSessionId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        private static void ConfigureAiFocusEvaluations(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<AiFocusEvaluation>(entity =>
            {
                entity.ToTable("ai_focus_evaluations");

                entity.HasKey(x => x.Id);

                entity.HasIndex(x => x.FocusSessionId)
                    .IsUnique();

                entity.Property(x => x.DistractionLevel)
                    .HasConversion<string>()
                    .HasMaxLength(30);

                entity.Property(x => x.DistractionScore)
                    .HasPrecision(5, 2);

                entity.Property(x => x.FocusScore)
                    .HasPrecision(5, 2);

                entity.Property(x => x.FeedbackTitle)
                    .IsRequired()
                    .HasMaxLength(120);

                entity.Property(x => x.FeedbackMessage)
                    .IsRequired()
                    .HasMaxLength(1000);

                entity.Property(x => x.Suggestion)
                    .HasMaxLength(1000);

                entity.Property(x => x.RawAiResponse)
                    .HasMaxLength(2000);

                entity.Property(x => x.CreatedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasOne(x => x.FocusSession)
                    .WithOne(x => x.AiFocusEvaluation)
                    .HasForeignKey<AiFocusEvaluation>(x => x.FocusSessionId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        private static void ConfigureNotifications(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Notification>(entity =>
            {
                entity.ToTable("notifications");

                entity.HasKey(x => x.Id);

                entity.Property(x => x.Title)
                    .IsRequired()
                    .HasMaxLength(160);

                entity.Property(x => x.Message)
                    .IsRequired()
                    .HasMaxLength(1000);

                entity.Property(x => x.Type)
                    .HasConversion<string>()
                    .HasMaxLength(40);

                entity.Property(x => x.IsRead)
                    .HasDefaultValue(false);

                entity.Property(x => x.CreatedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasIndex(x => new { x.UserId, x.IsRead });

                entity.HasIndex(x => x.ScheduledAt);

                entity.HasOne(x => x.User)
                    .WithMany(x => x.Notifications)
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(x => x.FocusTask)
                    .WithMany()
                    .HasForeignKey(x => x.FocusTaskId)
                    .OnDelete(DeleteBehavior.ClientSetNull);
            });
        }

        private static void ConfigureAiPlanDrafts(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<AiPlanDraft>(entity =>
            {
                entity.ToTable("ai_plan_drafts");

                entity.HasKey(x => x.Id);

                entity.Property(x => x.OriginalInput)
                    .IsRequired()
                    .HasMaxLength(300);

                entity.Property(x => x.SuggestedTitle)
                    .HasMaxLength(300);

                entity.Property(x => x.SuggestedDescription)
                    .HasMaxLength(1000);

                entity.Property(x => x.SuggestedOutputsJson)
                    .HasMaxLength(4000);

                entity.Property(x => x.Reason)
                    .HasMaxLength(1000);

                entity.Property(x => x.SuggestedPriority)
                    .HasConversion<string>()
                    .HasMaxLength(30);

                entity.Property(x => x.Status)
                    .HasConversion<string>()
                    .HasMaxLength(30);

                entity.Property(x => x.CreatedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasIndex(x => new { x.UserId, x.Status });

                entity.HasOne(x => x.User)
                    .WithMany(x => x.AiPlanDrafts)
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        private static void ConfigureGoogleCalendarLinks(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<GoogleCalendarLink>(entity =>
            {
                entity.ToTable("google_calendar_links");

                entity.HasKey(x => x.Id);

                entity.HasIndex(x => x.FocusTaskId)
                    .IsUnique();

                entity.Property(x => x.CalendarId)
                    .IsRequired()
                    .HasMaxLength(300);

                entity.Property(x => x.EventId)
                    .IsRequired()
                    .HasMaxLength(300);

                entity.Property(x => x.SyncedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasOne(x => x.FocusTask)
                    .WithOne(x => x.GoogleCalendarLink)
                    .HasForeignKey<GoogleCalendarLink>(x => x.FocusTaskId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        private static void ConfigureFocusTaskCompletions(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<FocusTaskCompletion>(entity =>
            {
                entity.ToTable("focus_task_completions");

                entity.HasKey(x => x.Id);

                entity.Property(x => x.CompletedOn)
                    .HasColumnType("date");

                entity.Property(x => x.CreatedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasIndex(x => new { x.FocusTaskId, x.CompletedOn })
                    .IsUnique();

                entity.HasOne(x => x.FocusTask)
                    .WithMany(x => x.CompletionLogs)
                    .HasForeignKey(x => x.FocusTaskId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

        private static void ConfigureScheduledTasks(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ScheduledTask>(entity =>
            {
                entity.ToTable("scheduled_tasks");

                entity.HasKey(x => x.Id);

                entity.Property(x => x.TitleSnapshot)
                    .IsRequired()
                    .HasMaxLength(180);

                entity.Property(x => x.AiScore)
                    .HasPrecision(8, 2);

                entity.Property(x => x.IsOverlapAllowed)
                    .HasDefaultValue(true);

                entity.Property(x => x.CreatedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                entity.HasIndex(x => new { x.UserId, x.StartTime });

                entity.HasIndex(x => new { x.FocusTaskId, x.SessionNumber });

                entity.HasOne(x => x.User)
                    .WithMany(x => x.ScheduledTasks)
                    .HasForeignKey(x => x.UserId)
                    .OnDelete(DeleteBehavior.NoAction);

                entity.HasOne(x => x.FocusTask)
                    .WithMany(x => x.ScheduledTasks)
                    .HasForeignKey(x => x.FocusTaskId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }

    }
}
