namespace Preventivi.Core.Anagrafiche;

public class FornitoreCreateModel
{
    public string CodiceFornitore { get; set; } = string.Empty;
    public string RagioneSociale { get; set; } = string.Empty;
    public string? PartitaIVA { get; set; }
    public string? CodiceFiscale { get; set; }
    public string? Indirizzo { get; set; }
    public string? CAP { get; set; }
    public string? Citta { get; set; }
    public string? Provincia { get; set; }
    public string? Telefono { get; set; }
    public string? Email { get; set; }
    public string? Referente { get; set; }
    public string Utente { get; set; } = string.Empty;
}

public sealed class FornitoreUpdateModel : FornitoreCreateModel
{
    public int IdFornitore { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public sealed class FornitoreDettaglio : FornitoreCreateModel
{
    public int IdFornitore { get; set; }
    public bool Attivo { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public sealed class FornitoreDipendenza
{
    public string Tipo { get; set; } = string.Empty;
    public long Numero { get; set; }
}
