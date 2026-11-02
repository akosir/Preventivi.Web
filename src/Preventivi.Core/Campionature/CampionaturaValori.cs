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
        stato is "Chiusa" or "Annullata";

    public static IReadOnlyList<string> StatiDestinazioneOrdinaria(string stato) =>
        stato switch
        {
            "Aperta" => ["In Lavorazione", "Annullata"],
            "In Lavorazione" => ["In Verifica", "Annullata"],
            "In Verifica" => ["In Lavorazione", "Inviata al Cliente", "Annullata"],
            "Inviata al Cliente" => ["In Verifica", "In Lavorazione", "Approvata", "Respinta"],
            "Approvata" => ["Chiusa"],
            "Respinta" => ["Chiusa"],
            _ => []
        };

    public static bool TransizioneOrdinariaConsentita(string statoCorrente, string nuovoStato) =>
        StatiDestinazioneOrdinaria(statoCorrente).Contains(nuovoStato, StringComparer.Ordinal);
}
