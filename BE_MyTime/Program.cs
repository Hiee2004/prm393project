using BE_MyTime.Data;
using BE_MyTime.Interfaces;
using BE_MyTime.Repositories;
using BE_MyTime.Services.Auth;
using BE_MyTime.Services.AI;
using BE_MyTime.Services.Streaks;
using BE_MyTime.Services.Tasks;
using BE_MyTime.Services.Users;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using System.Text.Json;

namespace BE_MyTime
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.
            const string FrontendCorsPolicy = "FrontendCorsPolicy";
            builder.Logging.ClearProviders();
            builder.Logging.AddConsole();
            builder.Logging.AddDebug();

            builder.Services.AddCors(options =>
            {
                options.AddPolicy(FrontendCorsPolicy, policy =>
                 {
                   policy.WithOrigins(
                         "http://localhost:61133",
                         "http://localhost:3000",
                         "http://localhost:5000",
                         "http://localhost:5173"
                )
             .AllowAnyHeader()
             .AllowAnyMethod();
                });
            });
            builder.Services.AddDbContext<AppDbContext>(options =>
            {
                options.UseSqlServer(
                    builder.Configuration.GetConnectionString("DefaultConnection")
                );
            });

            builder.Services.AddControllers();
            builder.Services.Configure<ApiBehaviorOptions>(options =>
            {
                options.InvalidModelStateResponseFactory = context =>
                {
                    var errors = context.ModelState
                        .Where(entry => entry.Value?.Errors.Count > 0)
                        .ToDictionary(
                            entry => entry.Key,
                            entry => entry.Value!.Errors
                                .Select(error => string.IsNullOrWhiteSpace(error.ErrorMessage)
                                    ? "Invalid value."
                                    : error.ErrorMessage)
                                .ToArray());

                    return new BadRequestObjectResult(new
                    {
                        message = "Validation failed.",
                        errors
                    });
                };
            });
            builder.Services.AddHttpClient();
            var dataProtectionPath = Path.Combine(
                AppContext.BaseDirectory,
                "App_Data",
                "DataProtectionKeys"
            );
            Directory.CreateDirectory(dataProtectionPath);
            builder.Services
                .AddDataProtection()
                .PersistKeysToFileSystem(new DirectoryInfo(dataProtectionPath));
            builder.Services.AddScoped<PasswordService>();
            builder.Services.AddScoped<JwtService>();
            builder.Services.AddScoped<IAuthService, AuthService>();
            builder.Services.AddScoped<UserRepository>();
            builder.Services.AddScoped<IUserService, UserService>();
            builder.Services.AddScoped<INotificationService, NotificationService>();
            builder.Services.AddScoped<FocusTaskRepository>();

            builder.Services.AddScoped<
                IFocusTaskService,
                FocusTaskService>();
            builder.Services.AddScoped<IProductivityStreakService, ProductivityStreakService>();
            builder.Services.AddScoped<IAiTimeManagerService, AiTimeManagerService>();
            builder.Services.AddScoped<FocusSessionRepository>();

            builder.Services.AddScoped<
                IFocusSessionService,
                FocusSessionService>();
            var jwtKey = builder.Configuration["Jwt:Key"];
            if (string.IsNullOrWhiteSpace(jwtKey))
            {
                throw new InvalidOperationException("Jwt:Key is not configured.");
            }

            builder.Services
                .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = builder.Configuration["Jwt:Issuer"],
                        ValidAudience = builder.Configuration["Jwt:Audience"],
                        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
                        ClockSkew = TimeSpan.Zero
                    };
                });

            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(options =>
            {
                options.SwaggerDoc("v1", new OpenApiInfo { Title = "MyTime API", Version = "v1" });
                options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    In = ParameterLocation.Header,
                    Description = "Enter your JWT token."
                });
                options.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
            });
            builder.Services.AddAuthorization();
            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseExceptionHandler(errorApp =>
            {
                errorApp.Run(async context =>
                {
                    var exception = context.Features.Get<IExceptionHandlerFeature>()?.Error;
                    var (statusCode, message) = exception switch
                    {
                        UnauthorizedAccessException => (StatusCodes.Status401Unauthorized, exception.Message),
                        InvalidOperationException => (StatusCodes.Status400BadRequest, exception.Message),
                        KeyNotFoundException => (StatusCodes.Status404NotFound, exception.Message),
                        _ => (StatusCodes.Status500InternalServerError, "An unexpected server error occurred.")
                    };

                    context.Response.StatusCode = statusCode;
                    context.Response.ContentType = "application/json";

                    await context.Response.WriteAsync(JsonSerializer.Serialize(new
                    {
                        message
                    }));
                });
            });

            if (!app.Environment.IsDevelopment())
            {
                app.UseHttpsRedirection();
            }
            app.UseCors(FrontendCorsPolicy);
            app.UseAuthentication();
            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
