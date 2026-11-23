using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;

namespace Preventivi.Web.Pages.Anagrafiche;

public sealed class IndexModel : PageModel
{
    public bool PuoClienti => AutorizzazioneApplicazione.PuoAccedereAlPermesso(User, PermessiApplicazione.Clienti);
    public bool PuoAnagrafiche => AutorizzazioneApplicazione.PuoAccedereAlPermesso(User, PermessiApplicazione.Anagrafiche);
    public void OnGet()
    {
    }
}
