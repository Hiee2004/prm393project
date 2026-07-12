using BE_MyTime.DTOs.FocusSessions;
using BE_MyTime.Interfaces;
using BE_MyTime.Models;
using BE_MyTime.Repositories;

namespace BE_MyTime.Services.Tasks
{
    public class FocusSessionService : IFocusSessionService
    {
        private readonly FocusSessionRepository _repository;

        public FocusSessionService(FocusSessionRepository repository)
        {
            _repository = repository;
        }
        public async Task<List<FocusSessionResponse>> GetSessionsAsync(int userId)
        {
            var sessions = await _repository.GetByUserIdAsync(userId);

            return sessions.Select(MapToResponse).ToList();
        }

        public async Task<FocusSessionResponse?> GetSessionAsync(
            int id,
            int userId)
        {
            var session = await _repository.GetByIdAsync(id, userId);

            return session == null
                ? null
                : MapToResponse(session);
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

                // Có thể thay đổi thuật toán sau
                FocusScore = CalculateFocusScore(request),

                FeedbackTitle = "Focus Completed",
                FeedbackMessage = "Good job! Keep your momentum.",
            };

            await _repository.AddAsync(session);

            session = await _repository.GetByIdAsync(session.Id, userId)
                      ?? session;

            return MapToResponse(session);
        }

        public async Task<bool> DeleteSessionAsync(
            int id,
            int userId)
        {
            var session = await _repository.GetByIdAsync(id, userId);

            if (session == null)
                return false;

            await _repository.DeleteAsync(session);

            return true;
        }

        private static double CalculateFocusScore(
            CreateFocusSessionRequest request)
        {
            if (request.PlannedSeconds == 0)
                return 0;

            var ratio =
                (double)request.ActualFocusSeconds /
                request.PlannedSeconds;

            ratio = Math.Min(ratio, 1);

            var score = ratio * 100;

            score -= request.DistractionCount * 5;

            return Math.Max(score, 0);
        }

        private static FocusSessionResponse MapToResponse(
            FocusSession session)
        {
            return new FocusSessionResponse
            {
                Id = session.Id,
                UserId = session.UserId,
                FocusTaskId = session.FocusTaskId,
                TaskTitle = session.FocusTask?.Title ?? "",
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

