namespace Preventivi.Core.Anagrafiche;

public sealed class ClienteAnagraficaLookupItem
{
    public int IdCliente { get; set; }
    public string CodiceCliente { get; set; } = string.Empty;
    public string RagioneSociale { get; set; } = string.Empty;
    public bool Attivo { get; set; }
    public string Display => $"{CodiceCliente} - {RagioneSociale}";
}

public sealed class ArticoloListItem
{
    public int IdArticolo { get; set; }
    public string CodiceArticolo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public string? Versione { get; set; }
    public string? Cliente { get; set; }
    public bool Attivo { get; set; }
}

public sealed class ArticoloDettaglio
{
    public int IdArticolo { get; set; }
    public string CodiceArticolo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public string? Versione { get; set; }
    public int? IdCliente { get; set; }
    public string? Cliente { get; set; }
    public bool Attivo { get; set; }
    public string? NoteTecniche { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public class ArticoloCreateModel
{
    public string CodiceArticolo { get; init; } = string.Empty;
    public string Descrizione { get; init; } = string.Empty;
    public string? Versione { get; init; }
    public int? IdCliente { get; init; }
    public string? NoteTecniche { get; init; }
    public string Utente { get; init; } = string.Empty;
}

public sealed class ArticoloUpdateModel : ArticoloCreateModel
{
    public int IdArticolo { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}
