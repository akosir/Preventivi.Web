using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.UI.Modules.Account;

namespace Preventivi.Web.Pages.Account;

public sealed class LoginModel : PageModel
{
    private readonly AutenticazioneApplicazioneService _autenticazioneService;
    private readonly ILogger<LoginModel> _logger;

    public LoginModel(
        AutenticazioneApplicazioneService autenticazioneService,
        ILogger<LoginModel> logger)
    {
        _autenticazioneService = autenticazioneService;
        _logger = logger;
    }

    [BindProperty]
    public LoginFormModel Form { get; set; } = new();

    [BindProperty(SupportsGet = true)]
    public string? ReturnUrl { get; set; }

    public IActionResult OnGet()
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return LocalRedirect(Url.IsLocalUrl(ReturnUrl) ? ReturnUrl! : "/");
        }

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        UtenteAccesso? utente;

        try
        {
            utente = await _autenticazioneService.VerificaAsync(
                Form.Username,
                Form.Password,
                cancellationToken);
        }
        catch (Exception exception)
        {
            _logger.LogError(
                exception,
                "Servizio di autenticazione non disponibile.");
            ModelState.AddModelError(
                string.Empty,
                "Accesso temporaneamente non disponibile.");
            return Page();
        }

        if (utente is null)
        {
            ModelState.AddModelError(string.Empty, "Username o password non validi.");
            return Page();
        }

        var principal = ClaimsApplicazioneFactory.Crea(utente);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            principal,
            new AuthenticationProperties
            {
                IsPersistent = false,
                AllowRefresh = true
            });

        return LocalRedirect(Url.IsLocalUrl(ReturnUrl) ? ReturnUrl! : "/");
    }
}
