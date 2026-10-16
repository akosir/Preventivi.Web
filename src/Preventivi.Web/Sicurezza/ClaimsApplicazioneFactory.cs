using Microsoft.AspNetCore.Authentication.Cookies;
using Preventivi.Core.Sicurezza;
using System.Security.Claims;

namespace Preventivi.Web.Sicurezza;

public static class ClaimsApplicazioneFactory
{
    public static ClaimsPrincipal Crea(UtenteAccesso utente)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, utente.IdUtente.ToString()),
            new(ClaimTypes.Name, utente.Username)
        };

        if (!string.IsNullOrWhiteSpace(utente.NomeCompleto))
        {
            claims.Add(new Claim(ClaimTypes.GivenName, utente.NomeCompleto));
        }

        claims.AddRange(utente.Ruoli.Select(ruolo =>
            new Claim(ClaimTypes.Role, ruolo)));
        claims.AddRange(utente.Permessi.Select(permesso =>
            new Claim(AutorizzazioneApplicazione.ClaimPermesso, permesso)));

        var identity = new ClaimsIdentity(
            claims,
            CookieAuthenticationDefaults.AuthenticationScheme);

        return new ClaimsPrincipal(identity);
    }
}
