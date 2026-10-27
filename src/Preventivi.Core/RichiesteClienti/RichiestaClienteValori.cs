namespace Preventivi.Core.RichiesteClienti;

public static class RichiestaClienteValori
{
    public static readonly IReadOnlyList<string> Stati =
    [
        "Nuova",
        "In Valutazione",
        "Da Preventivare",
        "Preventivata",
        "Confermata",
        "Sospesa",
        "Persa",
        "Annullata"
    ];

    public static readonly IReadOnlyList<string> Priorita =
    [
        "Bassa",
        "Media",
        "Alta",
        "Urgente"
    ];

    public static readonly IReadOnlyList<string> Interessi =
    [
        "Basso",
        "Medio",
        "Alto",
        "Strategico"
    ];

    public static bool StatoFinale(string stato) =>
        stato is "Confermata" or "Persa" or "Annullata";

    public static bool ConsenteNuovoPreventivo(string stato) =>
        stato is "Nuova" or "In Valutazione" or "Da Preventivare" or "Preventivata";
}
