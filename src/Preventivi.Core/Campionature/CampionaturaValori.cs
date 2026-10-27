namespace Preventivi.Core.Campionature;

public static class CampionaturaValori
{
    public static readonly IReadOnlyList<string> Stati =
    [
        "Aperta",
        "In Lavorazione",
        "In Verifica",
        "Inviata al Cliente",
        "Approvata",
        "Respinta",
        "Chiusa",
        "Annullata"
    ];

    public static readonly IReadOnlyList<string> Priorita =
    [
        "Bassa",
        "Media",
        "Alta",
        "Urgente"
    ];

    public static readonly IReadOnlyList<string> Esiti =
    [
        "Positivo",
        "Positivo con modifiche",
        "Negativo",
        "Da rifare"
    ];

    public static bool StatoFinale(string stato) =>
        stato is "Approvata" or "Respinta" or "Chiusa" or "Annullata";
}
