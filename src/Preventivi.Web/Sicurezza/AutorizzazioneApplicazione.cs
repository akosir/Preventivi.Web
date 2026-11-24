using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.Sicurezza;
using System.Security.Claims;

namespace Preventivi.Web.Sicurezza;

public static class AutorizzazioneApplicazione
{
    public const string RuoloAdmin = "ADMIN";
    public const string ClaimPermesso = "permesso";

    public const string PolicyAdmin = "Admin";
    public const string PolicyDevelopmentAdmin = "DevelopmentAdmin";
    public const string PolicyPreventivi = "Preventivi";
    public const string PolicyOrdiniFornitori = "OrdiniFornitori";
    public const string PolicyClienti = "Clienti";
    public const string PolicyRichiesteClienti = "RichiesteClienti";
    public const string PolicyCampionature = "Campionature";
    public const string PolicyAnagrafiche = "Anagrafiche";
    public const string PolicyIndiceAnagrafiche = "IndiceAnagrafiche";

    public static void ConfiguraCookie(
        CookieAuthenticationOptions options,
        bool richiediHttpsCookie)
    {
        options.Cookie.Name = ".Preventivi.Web.Sessione";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.Cookie.SecurePolicy = richiediHttpsCookie
            ? CookieSecurePolicy.Always
            : CookieSecurePolicy.SameAsRequest;
        options.LoginPath = "/Account/Login";
        options.AccessDeniedPath = "/Account/AccessoNegato";
        options.ExpireTimeSpan = TimeSpan.FromHours(12);
        options.SlidingExpiration = true;
    }

    public static void ConfiguraPolicy(
        AuthorizationOptions options,
        bool isDevelopment)
    {
        options.FallbackPolicy = new AuthorizationPolicyBuilder(
                CookieAuthenticationDefaults.AuthenticationScheme)
            .RequireAuthenticatedUser()
            .Build();

        options.AddPolicy(PolicyAdmin, policy =>
            policy.RequireRole(RuoloAdmin));
        options.AddPolicy(PolicyDevelopmentAdmin, policy =>
            policy.RequireAssertion(context =>
                isDevelopment && context.User.IsInRole(RuoloAdmin)));
        AggiungiPolicyModulo(options, PolicyPreventivi, PermessiApplicazione.Preventivi);
        AggiungiPolicyModulo(options, PolicyOrdiniFornitori, PermessiApplicazione.OrdiniFornitori);
        AggiungiPolicyModulo(options, PolicyClienti, PermessiApplicazione.Clienti);
        AggiungiPolicyModulo(
            options,
            PolicyRichiesteClienti,
            PermessiApplicazione.RichiesteClienti);
        AggiungiPolicyModulo(
            options,
            PolicyCampionature,
            PermessiApplicazione.Campionature);
        AggiungiPolicyModulo(
            options,
            PolicyAnagrafiche,
            PermessiApplicazione.Anagrafiche);
        options.AddPolicy(PolicyIndiceAnagrafiche, policy =>
            policy.RequireAssertion(context =>
                PuoAccedereAlPermesso(context.User, PermessiApplicazione.Clienti) ||
                PuoAccedereAlPermesso(context.User, PermessiApplicazione.Anagrafiche)));
    }

    public static void ConfiguraPagine(RazorPagesOptions options)
    {
        options.Conventions.AllowAnonymousToPage("/Account/Login");
        options.Conventions.AllowAnonymousToPage("/Account/AccessoNegato");
        options.Conventions.AllowAnonymousToPage("/Error");
        options.Conventions.AuthorizeFolder("/Preventivi", PolicyPreventivi);
        options.Conventions.AuthorizeFolder("/OrdiniFornitori", PolicyOrdiniFornitori);
        options.Conventions.AuthorizeFolder("/Clienti", PolicyClienti);
        options.Conventions.AuthorizeFolder(
            "/RichiesteClienti",
            PolicyRichiesteClienti);
        options.Conventions.AuthorizeFolder("/Campionature", PolicyCampionature);
        options.Conventions.AddFolderApplicationModelConvention("/Anagrafiche", model =>
        {
            if (model.ViewEnginePath != "/Anagrafiche/Index")
                model.Filters.Add(new Microsoft.AspNetCore.Mvc.Authorization.AuthorizeFilter(PolicyAnagrafiche));
        });
        options.Conventions.AuthorizePage("/Anagrafiche/Index", PolicyIndiceAnagrafiche);
        options.Conventions.AuthorizeFolder("/Dev", PolicyDevelopmentAdmin);
        options.Conventions.AuthorizePage("/TestDb", PolicyDevelopmentAdmin);
    }

    public static bool PuoAccedereAlPermesso(
        ClaimsPrincipal user,
        string permesso)
    {
        return user.Identity?.IsAuthenticated == true &&
            (user.IsInRole(RuoloAdmin) ||
             user.Claims.Any(claim =>
                 claim.Type == ClaimPermesso &&
                 string.Equals(
                     claim.Value,
                     permesso,
                     StringComparison.OrdinalIgnoreCase)));
    }

    public static bool PuoAccedereAllEntitaAllegato(
        ClaimsPrincipal user,
        string entita)
    {
        var permesso = entita switch
        {
            AllegatoEntita.Preventivi => PermessiApplicazione.Preventivi,
            AllegatoEntita.OrdiniFornitori => PermessiApplicazione.OrdiniFornitori,
            AllegatoEntita.PreventiviRigheComponenti => PermessiApplicazione.Preventivi,
            AllegatoEntita.PreventiviRigheMateriali => PermessiApplicazione.Preventivi,
            AllegatoEntita.PreventiviRigheLavorazioni => PermessiApplicazione.Preventivi,
            AllegatoEntita.Clienti => PermessiApplicazione.Clienti,
            AllegatoEntita.RichiesteClienti => PermessiApplicazione.RichiesteClienti,
            AllegatoEntita.Campionature => PermessiApplicazione.Campionature,
            AllegatoEntita.CampionatureRilievi => PermessiApplicazione.Campionature,
            AllegatoEntita.CampionatureAdeguamenti => PermessiApplicazione.Campionature,
            AllegatoEntita.Articoli => PermessiApplicazione.Anagrafiche,
            AllegatoEntita.Fornitori => PermessiApplicazione.Anagrafiche,
            AllegatoEntita.ModelliCiclo => PermessiApplicazione.Anagrafiche,
            AllegatoEntita.DistintaBaseNodi => PermessiApplicazione.Anagrafiche,
            AllegatoEntita.DistintaMateriali => PermessiApplicazione.Anagrafiche,
            AllegatoEntita.DistintaLavorazioni => PermessiApplicazione.Anagrafiche,
            _ => null
        };

        return permesso is not null && PuoAccedereAlPermesso(user, permesso);
    }

    private static void AggiungiPolicyModulo(
        AuthorizationOptions options,
        string nomePolicy,
        string permesso)
    {
        options.AddPolicy(nomePolicy, policy =>
            policy.RequireAssertion(context =>
                PuoAccedereAlPermesso(context.User, permesso)));
    }
}
