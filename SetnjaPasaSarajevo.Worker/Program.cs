using SetnjaPasaSarajevo.Worker;
using Microsoft.EntityFrameworkCore;
using SetnjaPasaSarajevo.Services.Database;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddHostedService<Worker>();
builder.Services.AddPooledDbContextFactory<SetnjaPasaSarajevoDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

await builder.Build().RunAsync();
