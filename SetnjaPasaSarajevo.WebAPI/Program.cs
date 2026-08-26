using SetnjaPasaSarajevo.Common.Services.CryptoService;
using SetnjaPasaSarajevo.Services;
using SetnjaPasaSarajevo.Services.Database;
using SetnjaPasaSarajevo.Services.Validators;
using SetnjaPasaSarajevo.WebAPI.Filters;
using SetnjaPasaSarajevo.WebAPI.Services;
using SetnjaPasaSarajevo.WebAPI.Services.AccessManager;
using SetnjaPasaSarajevo.Model.Requests;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SetnjaPasaSarajevo.Model.Responses;

using System.Text;

var builder = WebApplication.CreateBuilder(args);

//
// ✅ CORS
//
builder.Services.AddCors(options =>
{
    options.AddPolicy("CorsPolicy",
        policy =>
        {
            policy
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
        });
});

//
// ✅ HTTP + Controllers
//
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IAuthenticatedUserAccessor, HttpAuthenticatedUserAccessor>();

builder.Services.AddControllers(options =>
{
    options.Filters.Add<ExceptionFilter>();
});

//
// ✅ DB
//
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<SetnjaPasaSarajevoDbContext>(options =>
    options.UseSqlServer(connectionString)
        .ConfigureWarnings(w => 
            w.Ignore(RelationalEventId.PendingModelChangesWarning))
);


//
// ✅ MAPSTER (FIX)
// ✅ MAPSTER (FIX)
var config = TypeAdapterConfig.GlobalSettings;

// ✅ 🔥 OVO DODAJ (NAJBITNIJE)
config.NewConfig<Reservation, ReservationResponse>()
    .Map(dest => dest.Status,
         src => src.ReservationStatus != null
             ? src.ReservationStatus.Name
             : "Pending");

builder.Services.AddSingleton(config);
builder.Services.AddScoped<IMapper, ServiceMapper>();
//
// ✅ SERVICES (SAMO BITNO)
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IReservationService, ReservationService>();
builder.Services.AddScoped<IPetService, PetService>();
builder.Services.AddScoped<ITimeSlotService, TimeSlotService>();
builder.Services.AddScoped<IRefreshTokenService, RefreshTokenService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IRecommendationService, RecommendationService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddSingleton<IEventPublisher, RabbitMqEventPublisher>();
builder.Services.AddHttpClient();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddScoped<ICryptoService, CryptoService>();

//
// ✅ VALIDATORS
builder.Services.AddScoped<IValidator<UserInsertRequest>, UserInsertValidator>();
builder.Services.AddScoped<IValidator<UserUpdateRequest>, UserUpdateValidator>();
builder.Services.AddScoped<IValidator<ReservationInsertRequest>, ReservationInsertValidator>();
builder.Services.AddScoped<IValidator<ReservationUpdateRequest>, ReservationUpdateValidator>();
builder.Services.AddScoped<IValidator<PetInsertRequest>, PetInsertValidator>();
builder.Services.AddScoped<IValidator<PetUpdateRequest>, PetUpdateValidator>();

//
// ✅ AUTH (JWT)
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(o =>
{
    o.TokenValidationParameters = new TokenValidationParameters
    {
        ValidIssuer = builder.Configuration["JwtToken:Issuer"],
        ValidAudience = builder.Configuration["JwtToken:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["JwtToken:SecretKey"] ?? "")
        ),
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

//
// ✅ SWAGGER
//
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SetnjaPasaSarajevo API",
        Version = "v1"
    });

    var jwtScheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Description = "Unesi JWT token",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Reference = new OpenApiReference
        {
            Id = "Bearer",
            Type = ReferenceType.SecurityScheme
        }
    };

    options.AddSecurityDefinition(jwtScheme.Reference.Id, jwtScheme);

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        { jwtScheme, new string[] { } }
    });
});

var app = builder.Build();

//
// ✅ MIDDLEWARE
//
app.UseSwagger();
app.UseSwaggerUI();

app.UseCors("CorsPolicy");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
