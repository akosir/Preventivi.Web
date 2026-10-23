
using System.Globalization;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Localization;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Core.ParametriSistema;
using Preventivi.Core.Preventivi;
using Preventivi.Core.Preventivi.Eliminazione;
using Preventivi.Core.Sicurezza;
using Preventivi.Data.Allegati;
using Preventivi.Data.Comune;
using Preventivi.Data.ParametriSistema;
using Preventivi.Data.Preventivi;
using Preventivi.Data.Sicurezza;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.UI.ModelBinding;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services
    .AddRazorPages(options =>
        AutorizzazioneApplicazione.ConfiguraPagine(options))
    .AddMvcOptions(options =>
    {
        options.ModelBinderProviders.Insert(
            0,
            new FlexibleDecimalModelBinderProvider());
        options.ModelBindingMessageProvider.SetValueMustBeANumberAccessor(
            _ => "Inserire un numero valido.");
    });

var culturaItaliana = CultureInfo.GetCultureInfo("it-IT");
builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    options.DefaultRequestCulture = new RequestCulture(culturaItaliana);
    options.SupportedCultures = [culturaItaliana];
    options.SupportedUICultures = [culturaItaliana];
});

builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
        AutorizzazioneApplicazione.ConfiguraCookie(
            options,
            builder.Configuration.GetValue<bool?>(
                "Sicurezza:RichiediHttpsCookie")
            ?? !builder.Environment.IsDevelopment()));

builder.Services.AddAuthorization(options =>
    AutorizzazioneApplicazione.ConfiguraPolicy(
        options,
        builder.Environment.IsDevelopment()));

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

builder.Services.AddScoped<
    IModelloPreventivoRepository,
    ModelloPreventivoRepository>();

builder.Services.AddScoped<
    IPreventivoEliminazioneRepository,
    PreventivoEliminazioneRepository>();

builder.Services.AddScoped<
    IPreventivoEliminazioneService,
    PreventivoEliminazioneService>();

builder.Services.AddScoped<
    global::Preventivi.Core.Clienti.IClienteRepository,
    global::Preventivi.Data.Clienti.ClienteRepository>();

builder.Services.Configure<StorageOptions>(
    builder.Configuration.GetSection(StorageOptions.SectionName));

builder.Services.AddScoped<
    IAllegatoStorageService,
    AllegatoStorageService>();

builder.Services.AddScoped<
    global::Preventivi.Core.Allegati.IAllegatoRepository,
    global::Preventivi.Data.Allegati.AllegatoRepository>();

builder.Services.AddScoped<
    IParametriSistemaRepository,
    ParametriSistemaRepository>();

builder.Services.AddScoped<
    IUtenteAccessoRepository,
    UtenteAccessoRepository>();

builder.Services.AddScoped<IPasswordHasher<UtenteAccesso>, PasswordHasher<UtenteAccesso>>();
builder.Services.AddScoped<AutenticazioneApplicazioneService>();
builder.Services.AddScoped<PasswordAdminInitializer>();

builder.Services.AddScoped<
    global::Preventivi.Core.Allegati.Application.IAllegatoApplicationService,
    global::Preventivi.Data.Allegati.AllegatoApplicationService>();



var app = builder.Build();

if (args.Contains(
    "--inizializza-password-admin",
    StringComparer.OrdinalIgnoreCase))
{
    await using var scope = app.Services.CreateAsyncScope();
    var initializer = scope.ServiceProvider.GetRequiredService<PasswordAdminInitializer>();
    await initializer.EseguiAsync();
    return;
}

// Configure the HTTP request pipeline.
app.UseRequestLocalization();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseRouting();

app.UseAuthentication();

app.UseAuthorization();

app.MapStaticAssets()
   .AllowAnonymous();
app.MapRazorPages()
   .WithStaticAssets();

app.Run();
