namespace Preventivi.Core.Allegati;

public static class AllegatoEntita
{
    public const string Clienti = "Clienti";
    public const string Preventivi = "Preventivi";
    public const string RichiesteClienti = "RichiesteClienti";
    public const string PreventiviRigheComponenti = "PreventiviRigheComponenti";
    public const string PreventiviRigheMateriali = "PreventiviRigheMateriali";
    public const string PreventiviRigheLavorazioni = "PreventiviRigheLavorazioni";

    private static readonly HashSet<string> ValoriConsentiti =
    [
        Clienti,
        Preventivi,
        RichiesteClienti,
        PreventiviRigheComponenti,
        PreventiviRigheMateriali,
        PreventiviRigheLavorazioni
    ];

    public static bool IsValida(string? entita)
    {
        return entita is not null && ValoriConsentiti.Contains(entita);
    }
}
