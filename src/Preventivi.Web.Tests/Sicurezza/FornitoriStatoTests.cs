using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Web.Pages.Anagrafiche.Fornitori;
using Xunit;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class FornitoriStatoTests
{
    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task CambioStato_Operatore_NegaAccessoPrimaDiAccedereAiDati(bool attiva)
    {
        var pagina = new DettaglioModel(null!, null!, NullLogger<DettaglioModel>.Instance)
        {
            PageContext = new PageContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity(
                        [new Claim(ClaimTypes.Name, "operatore"), new Claim(ClaimTypes.Role, "OPERATORE")],
                        "Test"))
                }
            }
        };

        var risultato = attiva
            ? await pagina.OnPostAttivaAsync(1, Convert.ToBase64String(new byte[8]), CancellationToken.None)
            : await pagina.OnPostDisattivaAsync(1, Convert.ToBase64String(new byte[8]), CancellationToken.None);

        Assert.IsType<ForbidResult>(risultato);
    }
}
