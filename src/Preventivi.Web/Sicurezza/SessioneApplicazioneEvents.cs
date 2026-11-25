using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Preventivi.Core.Sicurezza;

namespace Preventivi.Web.Sicurezza;

public sealed class SessioneApplicazioneEvents(IUtenteAccessoRepository repository,ILogger<SessioneApplicazioneEvents> logger) : CookieAuthenticationEvents
{
    public const string ClaimVersioneSessione="versione_sessione";
    public override async Task ValidatePrincipal(CookieValidatePrincipalContext context)
    {
        UtenteAccesso? utente=null;
        try
        {
            if(context.Principal?.Identity?.Name is string username)
                utente=await repository.GetByUsernameAsync(username,context.HttpContext.RequestAborted);
        }
        catch(Exception exception) when(exception is not OperationCanceledException)
        {
            logger.LogWarning("Verifica della sessione non disponibile. Accesso negato.");
        }
        if(!SessioneValida(context.Principal,utente))
        {
            context.RejectPrincipal();
            await context.HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return;
        }
        var aggiornato=ClaimsApplicazioneFactory.Crea(utente!);
        var precedenti=context.Principal!.Claims.Select(x=>(x.Type,x.Value)).OrderBy(x=>x.Type).ThenBy(x=>x.Value);
        var attuali=aggiornato.Claims.Select(x=>(x.Type,x.Value)).OrderBy(x=>x.Type).ThenBy(x=>x.Value);
        if(!precedenti.SequenceEqual(attuali))
        {
            context.ReplacePrincipal(aggiornato);
            context.ShouldRenew=true;
        }
    }

    public static bool SessioneValida(ClaimsPrincipal? principal,UtenteAccesso? utente) =>
        principal?.Identity?.IsAuthenticated==true && utente is { Attivo:true } && !string.IsNullOrWhiteSpace(utente.PasswordHash)
        && int.TryParse(principal.FindFirstValue(ClaimTypes.NameIdentifier),out var id) && id==utente.IdUtente
        && Guid.TryParse(principal.FindFirstValue(ClaimVersioneSessione),out var versione)
        && versione!=Guid.Empty && versione==utente.VersioneSessione;
}
