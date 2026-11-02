namespace Preventivi.Core.Campionature;

public sealed class CampionaturaStatoUpdateModel
{
    public int IdCampionatura { get; set; }
    public string Stato { get; set; } = string.Empty;
    public DateOnly? DataConsegnaCampione { get; set; }
    public string? Esito { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
    public string Utente { get; set; } = string.Empty;
    public bool Amministratore { get; set; }
    public string? MotivazioneCorrezione { get; set; }
}

public sealed class CampionaturaCorrezioneStatoListItem
{
    public long IdCorrezioneStato { get; set; }
    public string StatoPrecedente { get; set; } = string.Empty;
    public string StatoNuovo { get; set; } = string.Empty;
    public string Motivazione { get; set; } = string.Empty;
    public DateTime DataCorrezione { get; set; }
    public string UtenteCorrezione { get; set; } = string.Empty;
}
