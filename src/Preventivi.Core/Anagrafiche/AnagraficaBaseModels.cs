namespace Preventivi.Core.Anagrafiche;

public sealed class AnagraficaBaseListItem
{
    public int Id { get; set; }
    public string? Codice { get; set; }
    public string Descrizione { get; set; } = string.Empty;
    public bool Attivo { get; set; }
}

public sealed class AnagraficaBaseDettaglio
{
    public int Id { get; set; }
    public string? Codice { get; set; }
    public string Descrizione { get; set; } = string.Empty;
    public bool Attivo { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public sealed class AnagraficaBaseCreateModel
{
    public string? Codice { get; init; }
    public string Descrizione { get; init; } = string.Empty;
    public string Utente { get; init; } = string.Empty;
}

public sealed class AnagraficaBaseUpdateModel
{
    public int Id { get; init; }
    public string? Codice { get; init; }
    public string Descrizione { get; init; } = string.Empty;
    public string Utente { get; init; } = string.Empty;
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class AnagraficaBaseStatoModel
{
    public int Id { get; init; }
    public bool Attivo { get; init; }
    public string Utente { get; init; } = string.Empty;
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class AnagraficaBaseDeleteModel
{
    public int Id { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}
