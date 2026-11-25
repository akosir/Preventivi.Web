using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Preventivi.Core.Sicurezza;

namespace Preventivi.Web.Sicurezza;

public sealed class GestioneUtentiApplicationService(IGestioneUtentiRepository repository,IPasswordHasher<UtenteAccesso> hasher)
{
    public static AmministratoreOperante? Attore(ClaimsPrincipal user) =>
        user.Identity?.IsAuthenticated == true && user.IsInRole(AutorizzazioneApplicazione.RuoloAdmin)
        && int.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier),out var id) && id>0
        && Guid.TryParse(user.FindFirstValue(SessioneApplicazioneEvents.ClaimVersioneSessione),out var versione) && versione!=Guid.Empty
            ? new(id,versione) : null;

    public Task<int> SalvaAsync(AmministratoreOperante attore,int? id,UtenteSalvataggio dati,string? password,CancellationToken cancellationToken=default)
    {
        if(string.IsNullOrWhiteSpace(dati.Username) || dati.Username.Trim().Length>50 || dati.NomeCompleto?.Length>150 || dati.Ruoli.Length==0)
            throw new ArgumentException("Compilare username e almeno un ruolo, rispettando le lunghezze consentite.");
        dati.Username=dati.Username.Trim();
        if(id==attore.IdUtente && !dati.Attivo)
            throw new ArgumentException("Non è possibile disattivare il proprio account.");
        if(id.HasValue) VerificaVersione(dati.VersioneRiga);
        dati.NomeCompleto=string.IsNullOrWhiteSpace(dati.NomeCompleto) ? null : dati.NomeCompleto.Trim();
        string? hash=null;
        if(!id.HasValue)
        {
            VerificaPassword(password);
            hash=hasher.HashPassword(new UtenteAccesso { Username=dati.Username },password!);
        }
        return repository.SalvaAsync(attore,id,dati,hash,cancellationToken);
    }

    public Task ReimpostaAsync(AmministratoreOperante attore,UtenteGestione utente,byte[] versione,string password,CancellationToken cancellationToken=default)
    {
        VerificaPassword(password);
        VerificaVersione(versione);
        var hash=hasher.HashPassword(new UtenteAccesso { IdUtente=utente.IdUtente,Username=utente.Username },password);
        return repository.ReimpostaPasswordAsync(attore,utente.IdUtente,versione,hash,cancellationToken);
    }
    private static void VerificaPassword(string? password)
    {
        if(password is null || password.Length<12 || password.Length>256 || string.IsNullOrWhiteSpace(password))
            throw new ArgumentException("La password deve contenere da 12 a 256 caratteri.");
    }
    private static void VerificaVersione(byte[] versione)
    {
        if(versione.Length!=8) throw new ArgumentException("Versione dei dati non valida. Riaprire la pagina.");
    }
}
