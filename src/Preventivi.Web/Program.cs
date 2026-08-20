
using Preventivi.Data.Comune;
using Preventivi.Core.Preventivi;
using Preventivi.Data.Preventivi;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

var connectionString =
    builder.Configuration.GetConnectionString("PreventiviDb")
    ?? throw new InvalidOperationException(
        "Connection string 'PreventiviDb' non configurata.");

builder.Services.AddSingleton(
    new SqlConnectionFactory(connectionString));

builder.Services.AddScoped<DatabaseExecutor>();

builder.Services.AddScoped<
    IPreventivoRepository,
    PreventivoRepository>();


var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages()
   .WithStaticAssets();

app.Run();
