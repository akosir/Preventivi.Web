namespace Preventivi.Core.Allegati;

public static class AllegatoEntita
{
    public const string Clienti = "Clienti";
    public const string Preventivi = "Preventivi";
    public const string RichiesteClienti = "RichiesteClienti";
    public const string Campionature = "Campionature";
    public const string CampionatureRilievi = "CampionatureRilievi";
    public const string CampionatureAdeguamenti = "CampionatureAdeguamenti";
    public const string Articoli = "Articoli";
    public const string DistintaBaseNodi = "DistintaBaseNodi";
    public const string DistintaMateriali = "DistintaMateriali";
    public const string DistintaLavorazioni = "DistintaLavorazioni";
    public const string PreventiviRigheComponenti = "PreventiviRigheComponenti";
    public const string PreventiviRigheMateriali = "PreventiviRigheMateriali";
    public const string PreventiviRigheLavorazioni = "PreventiviRigheLavorazioni";

    private static readonly HashSet<string> ValoriConsentiti =
    [
        Clienti,
        Preventivi,
        RichiesteClienti,
        Campionature,
        CampionatureRilievi,
        CampionatureAdeguamenti,
        Articoli,
        DistintaBaseNodi,
        DistintaMateriali,
        DistintaLavorazioni,
        PreventiviRigheComponenti,
        PreventiviRigheMateriali,
        PreventiviRigheLavorazioni
    ];

    public static bool IsValida(string? entita)
    {
        return entita is not null && ValoriConsentiti.Contains(entita);
    }
}
