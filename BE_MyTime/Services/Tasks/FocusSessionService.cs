using BE_MyTime.Data;
using BE_MyTime.DTOs.FocusSessions;
using BE_MyTime.Interfaces;
using BE_MyTime.Models;
using BE_MyTime.Repositories;

namespace BE_MyTime.Services.Tasks
{
    public class FocusSessionService : IFocusSessionService
    {
        private readonly FocusSessionRepository _repository;
        private readonly AppDbContext _db;

        public FocusSessionService(FocusSessionRepository repository, AppDbContext db)
        {
            _repository = repository;
            _db = db;
        }

        public async Task<List<FocusSessionResponse>> GetSessionsAsync(int userId)
        {
            var sessions = await _repository.GetByUserIdAsync(userId);
            return sessions.Select(MapToResponse).ToList();
        }

        public async Task<FocusSessionResponse?> GetSessionAsync(int id, int userId)
        {
            var session = await _repository.GetByIdAsync(id, userId);
            return session == null ? null : MapToResponse(session);
        }

        public async Task<FocusSessionResponse> CreateSessionAsync(
            int userId,
            CreateFocusSessionRequest request)
        {
            var session = new FocusSession
            {
                UserId = userId,
                FocusTaskId = request.FocusTaskId,
                PlannedSeconds = request.PlannedSeconds,
                ActualFocusSeconds = request.ActualFocusSeconds,
                CompletedOutputs = request.CompletedOutputs,
                TotalOutputs = request.TotalOutputs,
                DistractionCount = request.DistractionCount,
                TotalDistractionSeconds = request.TotalDistractionSeconds,
                StartedAt = request.StartedAt,
                CompletedAt = request.CompletedAt,
                FocusScore = CalculateFocusScore(request),
                FeedbackTitle = "Focus Completed",
                FeedbackMessage = "Good job! Keep your momentum.",
            };

            await _repository.AddAsync(session);
            await CreateFocusCompletedNotificationAsync(session, userId);

            session = await _repository.GetByIdAsync(session.Id, userId) ?? session;
            return MapToResponse(session);
        }

        public async Task<bool> DeleteSessionAsync(int id, int userId)
        {
            var session = await _repository.GetByIdAsync(id, userId);
            if (session == null)
            {
                return false;
            }

            await _repository.DeleteAsync(session);
            return true;
        }

        private static double CalculateFocusScore(CreateFocusSessionRequest request)
        {
            if (request.PlannedSeconds == 0)
            {
                return 0;
            }

            var ratio = (double)request.ActualFocusSeconds / request.PlannedSeconds;
            ratio = Math.Min(ratio, 1);

            var score = ratio * 100;
            score -= request.DistractionCount * 5;
            return Math.Max(score, 0);
        }

        private async Task CreateFocusCompletedNotificationAsync(FocusSession session, int userId)
        {
            var focusMinutes = Math.Max(1, (int)Math.Round(session.ActualFocusSeconds / 60d));

            _db.Notifications.Add(new Notification
            {
                UserId = userId,
                FocusTaskId = session.FocusTaskId,
                Title = "Focus session completed",
                Message = $"You focused for {focusMinutes} minute(s) and completed {session.CompletedOutputs}/{session.TotalOutputs} outputs.",
                Type = NotificationType.FocusCompleted,
                SentAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync();
        }

        private static FocusSessionResponse MapToResponse(FocusSession session)
        {
            return new FocusSessionResponse
            {
                Id = session.Id,
                UserId = session.UserId,
                FocusTaskId = session.FocusTaskId,
                TaskTitle = session.FocusTask?.Title ?? string.Empty,
                PlannedSeconds = session.PlannedSeconds,
                ActualFocusSeconds = session.ActualFocusSeconds,
                CompletedOutputs = session.CompletedOutputs,
                TotalOutputs = session.TotalOutputs,
                DistractionCount = session.DistractionCount,
                TotalDistractionSeconds = session.TotalDistractionSeconds,
                FocusScore = session.FocusScore,
                FeedbackTitle = session.FeedbackTitle,
                FeedbackMessage = session.FeedbackMessage,
                StartedAt = session.StartedAt,
                CompletedAt = session.CompletedAt
            };
        }
    }
}
