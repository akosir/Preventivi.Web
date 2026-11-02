namespace Preventivi.Core.Campionature;

public static class CampionaturaRilievoValori
{
    private static readonly IReadOnlyDictionary<string, IReadOnlyList<string>> TransizioniOrdinarie =
        new Dictionary<string, IReadOnlyList<string>>(StringComparer.Ordinal)
        {
            ["Aperto"] = ["In Analisi", "Respinto"],
            ["In Analisi"] = ["Soluzione Proposta", "Respinto"],
            ["Soluzione Proposta"] = ["In Analisi", "Risolto"],
            ["Risolto"] = ["In Analisi", "Chiuso"],
            ["Respinto"] = [],
            ["Chiuso"] = []
        };

    public static readonly IReadOnlyList<string> Gravita =
    [
        "Bassa",
        "Media",
        "Alta",
        "Critica"
    ];

    public static readonly IReadOnlyList<string> Stati =
    [
        "Aperto",
        "In Analisi",
        "Soluzione Proposta",
        "Risolto",
        "Respinto",
        "Chiuso"
    ];

    public static bool StatoFinale(string stato) =>
        stato is "Respinto" or "Chiuso";

    public static IReadOnlyList<string> StatiDestinazioneOrdinaria(string stato) =>
        TransizioniOrdinarie.TryGetValue(stato, out var destinazioni)
            ? destinazioni
            : [];

    public static bool TransizioneOrdinariaConsentita(string statoCorrente, string nuovoStato) =>
        StatiDestinazioneOrdinaria(statoCorrente).Contains(nuovoStato, StringComparer.Ordinal);
}

public sealed class CampionaturaRilievoListItem
{
    public int IdRilievoCampionatura { get; set; }
    public int IdCampionatura { get; set; }
    public int RigaNr { get; set; }
    public DateOnly DataRilevazione { get; set; }
    public string TipoProblematica { get; set; } = string.Empty;
    public string? ProblematicaStandard { get; set; }
    public string DescrizioneProblema { get; set; } = string.Empty;
    public string Gravita { get; set; } = string.Empty;
    public string Stato { get; set; } = string.Empty;
    public bool RichiedeAdeguamentoPreventivo { get; set; }
    public bool RichiedeNuovoCampione { get; set; }
}

public sealed class CampionaturaRilievoDettaglio
{
    public int IdRilievoCampionatura { get; set; }
    public int IdCampionatura { get; set; }
    public int RigaNr { get; set; }
    public int IdTipoProblematica { get; set; }
    public string TipoProblematica { get; set; } = string.Empty;
    public int? IdProblematicaStandard { get; set; }
    public string? ProblematicaStandard { get; set; }
    public string DescrizioneProblema { get; set; } = string.Empty;
    public string Gravita { get; set; } = string.Empty;
    public string? CausaPresunta { get; set; }
    public string? SoluzioneProposta { get; set; }
    public bool RichiedeAdeguamentoPreventivo { get; set; }
    public bool RichiedeNuovoCampione { get; set; }
    public string Stato { get; set; } = string.Empty;
    public string? EsitoVerifica { get; set; }
    public string? NoteCliente { get; set; }
    public string? NoteInterne { get; set; }
    public DateOnly DataRilevazione { get; set; }
    public DateOnly? DataChiusura { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public sealed class CampionaturaTipoProblematicaLookupItem
{
    public int IdTipoProblematica { get; set; }
    public string CodiceTipo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
}

public sealed class CampionaturaProblematicaStandardLookupItem
{
    public int IdProblematicaStandard { get; set; }
    public int IdTipoProblematica { get; set; }
    public string CodiceProblematica { get; set; } = string.Empty;
    public string DescrizioneProblematica { get; set; } = string.Empty;
    public string? SoluzioneStandard { get; set; }
}

public class CampionaturaRilievoCreateModel
{
    public int IdCampionatura { get; set; }
    public DateOnly DataRilevazione { get; set; }
    public int IdTipoProblematica { get; set; }
    public int? IdProblematicaStandard { get; set; }
    public string DescrizioneProblema { get; set; } = string.Empty;
    public string Gravita { get; set; } = "Media";
    public string? CausaPresunta { get; set; }
    public string? SoluzioneProposta { get; set; }
    public bool RichiedeNuovoCampione { get; set; }
    public string? NoteCliente { get; set; }
    public string? NoteInterne { get; set; }
    public string Utente { get; set; } = string.Empty;
}

public sealed class CampionaturaRilievoStatoUpdateModel
{
    public int IdRilievoCampionatura { get; set; }
    public string Stato { get; set; } = string.Empty;
    public byte[] VersioneRiga { get; set; } = [];
    public string Utente { get; set; } = string.Empty;
    public bool Amministratore { get; set; }
    public string? MotivazioneCorrezione { get; set; }
}

public sealed class CampionaturaRilievoCorrezioneStatoListItem
{
    public long IdCorrezioneStato { get; set; }
    public string StatoPrecedente { get; set; } = string.Empty;
    public string StatoNuovo { get; set; } = string.Empty;
    public string Motivazione { get; set; } = string.Empty;
    public DateTime DataCorrezione { get; set; }
    public string UtenteCorrezione { get; set; } = string.Empty;
}

public sealed class CampionaturaRilievoUpdateModel : CampionaturaRilievoCreateModel
{
    public int IdRilievoCampionatura { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public sealed class CampionaturaRilievoDeleteModel
{
    public int IdRilievoCampionatura { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}
