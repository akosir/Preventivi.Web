namespace Preventivi.Web.Database;

public sealed class ControlloSchemaDatabaseMiddleware
{
    public const string PercorsoManutenzione = "/Sistema/Database";

    private readonly RequestDelegate _next;

    public ControlloSchemaDatabaseMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(
        HttpContext context,
        StatoSchemaDatabaseApplicazione statoApplicazione)
    {
        if (statoApplicazione.Stato.Operativo ||
            EUnPercorsoConsentito(context.Request.Path))
        {
            await _next(context);
            return;
        }

        context.Response.Redirect(PercorsoManutenzione);
    }

    public static bool EUnPercorsoConsentito(PathString percorso)
    {
        return percorso.StartsWithSegments(PercorsoManutenzione) ||
            percorso.StartsWithSegments("/css") ||
            percorso.StartsWithSegments("/js") ||
            percorso.StartsWithSegments("/lib") ||
            percorso.StartsWithSegments("/favicon.ico");
    }
}
