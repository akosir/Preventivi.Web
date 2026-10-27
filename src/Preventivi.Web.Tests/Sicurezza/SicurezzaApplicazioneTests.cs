using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using Preventivi.Core.Allegati;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;
using System.Security.Claims;
using Xunit;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class SicurezzaApplicazioneTests
{
    [Fact]
    public async Task VerificaAsync_PasswordCorretta_RestituisceUtente()
    {
        var hasher = new PasswordHasher<UtenteAccesso>();
        var utente = CreaUtente();
        utente = CopiaConHash(utente, hasher.HashPassword(utente, "password-corretta"));
        var servizio = new AutenticazioneApplicazioneService(
            new RepositoryFinto(utente),
            hasher);

        var risultato = await servizio.VerificaAsync("admin", "password-corretta");

        Assert.NotNull(risultato);
        Assert.Equal(utente.IdUtente, risultato.IdUtente);
    }

    [Fact]
    public async Task VerificaAsync_PasswordErrata_NegaAccesso()
    {
        var hasher = new PasswordHasher<UtenteAccesso>();
        var utente = CreaUtente();
        utente = CopiaConHash(utente, hasher.HashPassword(utente, "password-corretta"));
        var servizio = new AutenticazioneApplicazioneService(
            new RepositoryFinto(utente),
            hasher);

        var risultato = await servizio.VerificaAsync("admin", "password-errata");

        Assert.Null(risultato);
    }

    [Fact]
    public async Task VerificaAsync_UtenteSenzaPassword_NegaAccesso()
    {
        var servizio = new AutenticazioneApplicazioneService(
            new RepositoryFinto(CreaUtente()),
            new PasswordHasher<UtenteAccesso>());

        var risultato = await servizio.VerificaAsync("admin", "qualsiasi-password");

        Assert.Null(risultato);
    }

    [Fact]
    public void ClaimsFactory_InserisceIdentitaRuoliEPermessi()
    {
        var principal = ClaimsApplicazioneFactory.Crea(CreaUtente());

        Assert.True(principal.Identity?.IsAuthenticated);
        Assert.Equal("admin", principal.Identity?.Name);
        Assert.True(principal.IsInRole(AutorizzazioneApplicazione.RuoloAdmin));
        Assert.Contains(
            principal.Claims,
            claim => claim.Type == AutorizzazioneApplicazione.ClaimPermesso &&
                claim.Value == PermessiApplicazione.Preventivi);
    }

    [Fact]
    public void ConfiguraCookie_ImpostaSessioneMobileNonPersistenteLatoBrowser()
    {
        var options = new CookieAuthenticationOptions();

        AutorizzazioneApplicazione.ConfiguraCookie(
            options,
            richiediHttpsCookie: false);

        Assert.Equal(TimeSpan.FromHours(12), options.ExpireTimeSpan);
        Assert.True(options.SlidingExpiration);
        Assert.True(options.Cookie.HttpOnly);
        Assert.Null(options.Cookie.MaxAge);
        Assert.Equal("/Account/Login", options.LoginPath);
    }

    [Theory]
    [InlineData(true, CookieSecurePolicy.Always)]
    [InlineData(false, CookieSecurePolicy.SameAsRequest)]
    public void ConfiguraCookie_RispettaObbligoHttps(
        bool richiediHttpsCookie,
        CookieSecurePolicy attesa)
    {
        var options = new CookieAuthenticationOptions();

        AutorizzazioneApplicazione.ConfiguraCookie(
            options,
            richiediHttpsCookie);

        Assert.Equal(attesa, options.Cookie.SecurePolicy);
    }

    [Fact]
    public async Task PolicyModulo_PermessoPresente_Autorizza()
    {
        var service = CreaAuthorizationService(isDevelopment: false);
        var principal = CreaPrincipal(
            new Claim(
                AutorizzazioneApplicazione.ClaimPermesso,
                PermessiApplicazione.Preventivi));

        var risultato = await service.AuthorizeAsync(
            principal,
            resource: null,
            AutorizzazioneApplicazione.PolicyPreventivi);

        Assert.True(risultato.Succeeded);
    }

    [Fact]
    public async Task PolicyModulo_PermessoAssente_Nega()
    {
        var service = CreaAuthorizationService(isDevelopment: false);
        var principal = CreaPrincipal();

        var risultato = await service.AuthorizeAsync(
            principal,
            resource: null,
            AutorizzazioneApplicazione.PolicyPreventivi);

        Assert.False(risultato.Succeeded);
    }

    [Fact]
    public async Task PolicyModulo_AdminAutorizzaSenzaPermessoEsplicito()
    {
        var service = CreaAuthorizationService(isDevelopment: false);
        var principal = CreaPrincipal(new Claim(
            ClaimTypes.Role,
            AutorizzazioneApplicazione.RuoloAdmin));

        var risultato = await service.AuthorizeAsync(
            principal,
            resource: null,
            AutorizzazioneApplicazione.PolicyClienti);

        Assert.True(risultato.Succeeded);
    }

    [Theory]
    [InlineData(AllegatoEntita.Preventivi, PermessiApplicazione.Preventivi)]
    [InlineData(AllegatoEntita.PreventiviRigheComponenti, PermessiApplicazione.Preventivi)]
    [InlineData(AllegatoEntita.PreventiviRigheMateriali, PermessiApplicazione.Preventivi)]
    [InlineData(AllegatoEntita.PreventiviRigheLavorazioni, PermessiApplicazione.Preventivi)]
    [InlineData(AllegatoEntita.Clienti, PermessiApplicazione.Clienti)]
    [InlineData(AllegatoEntita.RichiesteClienti, PermessiApplicazione.RichiesteClienti)]
    public void Allegati_PermessoEntitaCorrispondente_Autorizza(
        string entita,
        string permesso)
    {
        var principal = CreaPrincipal(new Claim(
            AutorizzazioneApplicazione.ClaimPermesso,
            permesso));

        Assert.True(AutorizzazioneApplicazione.PuoAccedereAllEntitaAllegato(
            principal,
            entita));
    }

    [Fact]
    public void Allegati_EntitaSconosciuta_Nega()
    {
        var principal = CreaPrincipal(new Claim(
            ClaimTypes.Role,
            AutorizzazioneApplicazione.RuoloAdmin));

        Assert.False(AutorizzazioneApplicazione.PuoAccedereAllEntitaAllegato(
            principal,
            "EntitaNonPrevista"));
    }

    [Theory]
    [InlineData(false, false)]
    [InlineData(true, true)]
    public async Task PolicyDevelopmentAdmin_RispettaAmbiente(
        bool isDevelopment,
        bool atteso)
    {
        var service = CreaAuthorizationService(isDevelopment);
        var principal = CreaPrincipal(new Claim(
            ClaimTypes.Role,
            AutorizzazioneApplicazione.RuoloAdmin));

        var risultato = await service.AuthorizeAsync(
            principal,
            resource: null,
            AutorizzazioneApplicazione.PolicyDevelopmentAdmin);

        Assert.Equal(atteso, risultato.Succeeded);
    }

    private static IAuthorizationService CreaAuthorizationService(bool isDevelopment)
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddAuthorization(options =>
            AutorizzazioneApplicazione.ConfiguraPolicy(options, isDevelopment));
        return services.BuildServiceProvider()
            .GetRequiredService<IAuthorizationService>();
    }

    private static ClaimsPrincipal CreaPrincipal(params Claim[] claims)
    {
        var elenco = new List<Claim> { new(ClaimTypes.Name, "utente") };
        elenco.AddRange(claims);
        return new ClaimsPrincipal(new ClaimsIdentity(elenco, "Test"));
    }

    private static UtenteAccesso CreaUtente()
    {
        return new UtenteAccesso
        {
            IdUtente = 1,
            Username = "admin",
            NomeCompleto = "Amministratore",
            Attivo = true,
            Ruoli = [AutorizzazioneApplicazione.RuoloAdmin],
            Permessi = [PermessiApplicazione.Preventivi]
        };
    }

    private static UtenteAccesso CopiaConHash(UtenteAccesso utente, string hash)
    {
        return new UtenteAccesso
        {
            IdUtente = utente.IdUtente,
            Username = utente.Username,
            NomeCompleto = utente.NomeCompleto,
            PasswordHash = hash,
            Attivo = utente.Attivo,
            Ruoli = utente.Ruoli,
            Permessi = utente.Permessi
        };
    }

    private sealed class RepositoryFinto : IUtenteAccessoRepository
    {
        private readonly UtenteAccesso? _utente;

        public RepositoryFinto(UtenteAccesso? utente)
        {
            _utente = utente;
        }

        public Task<UtenteAccesso?> GetByUsernameAsync(
            string username,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(
                string.Equals(_utente?.Username, username, StringComparison.OrdinalIgnoreCase)
                    ? _utente
                    : null);
        }

        public Task<bool> InizializzaPasswordAdminAsync(
            string username,
            string passwordHash,
            CancellationToken cancellationToken = default)
        {
            throw new NotSupportedException();
        }
    }
}
