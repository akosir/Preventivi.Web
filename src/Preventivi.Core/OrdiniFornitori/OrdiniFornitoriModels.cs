namespace Preventivi.Core.OrdiniFornitori;

public static class OrdineFornitoreStati
{
    public static readonly IReadOnlyList<string> Tutti = ["Bozza", "Inviato", "Parziale", "Ricevuto", "Annullato"];
}

public sealed class OrdineFornitoreFiltro
{
    public int? Numero { get; set; }
    public int? Anno { get; set; }
    public int? IdFornitore { get; set; }
    public DateTime? Dal { get; set; }
    public DateTime? Al { get; set; }
    public string? Stato { get; set; }
    public string? Oggetto { get; set; }
}

public class OrdineFornitoreSalvataggio
{
    public DateTime DataOrdine { get; set; }
    public int IdFornitore { get; set; }
    public string? Oggetto { get; set; }
    public string? Note { get; set; }
    public DateTime? DataConsegnaPrevista { get; set; }
    public string Utente { get; set; } = string.Empty;
    public byte[] VersioneRiga { get; set; } = [];
}

public sealed class OrdineFornitoreDettaglio : OrdineFornitoreSalvataggio
{
    public int IdOrdineFornitore { get; set; }
    public int NumeroOrdine { get; set; }
    public int Anno { get; set; }
    public string Stato { get; set; } = string.Empty;
    public decimal TotaleOrdine { get; set; }
    public string CodiceFornitore { get; set; } = string.Empty;
    public string RagioneSociale { get; set; } = string.Empty;
    public string? Indirizzo { get; set; }
    public string? CAP { get; set; }
    public string? Citta { get; set; }
    public string? Provincia { get; set; }
    public string? PartitaIVA { get; set; }
    public string? Email { get; set; }
    public int? IdPreventivo { get; set; }
    public int? IdRigaPreventivo { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public DateTime? DataInvio { get; set; }
    public string? UtenteInvio { get; set; }
    public bool Modificabile => string.Equals(Stato, "Bozza", StringComparison.OrdinalIgnoreCase);
    public string NumeroCompleto => $"{Anno}-{NumeroOrdine:00000}";
}

public class OrdineFornitoreRigaSalvataggio
{
    public int RigaNr { get; set; }
    public string TipoRiga { get; set; } = "Materiale";
    public int? IdMateriale { get; set; }
    public int? IdLavorazione { get; set; }
    public string Descrizione { get; set; } = string.Empty;
    public string? UM { get; set; }
    public decimal Quantita { get; set; } = 1;
    public decimal PrezzoUnitario { get; set; }
    public DateTime? DataConsegnaPrevista { get; set; }
    public string? Note { get; set; }
    public string Utente { get; set; } = string.Empty;
    public byte[] VersioneRiga { get; set; } = [];
    public byte[] VersioneOrdine { get; set; } = [];
}

public sealed class OrdineFornitoreRiga : OrdineFornitoreRigaSalvataggio
{
    public int? IdRigaPreventivo { get; set; }
    public int? IdRigaCompPrev { get; set; }
    public int? IdRigaMatPrev { get; set; }
    public int? IdRigaLavPrev { get; set; }
    public bool DaPreventivo => IdRigaMatPrev.HasValue || IdRigaLavPrev.HasValue;
    public int IdRigaOrdineFornitore { get; set; }
    public int IdOrdineFornitore { get; set; }
    public decimal TotaleRiga { get; set; }
    public decimal QuantitaRicevuta { get; set; }
}

public sealed class OrdineFornitoreDipendenza
{
    public string Tipo { get; set; } = string.Empty;
    public long Numero { get; set; }
}

public class OrdineFornitoreDocumento
{
    public int IdDocumento { get; set; }
    public int IdOrdineFornitore { get; set; }
    public int NumeroVersione { get; set; }
    public DateTime ConfermatoIl { get; set; }
    public string ConfermatoDa { get; set; } = string.Empty;
}

public sealed class OrdineFornitoreDocumentoDettaglio : OrdineFornitoreDocumento
{
    public string TestataJson { get; set; } = string.Empty;
    public string RigheJson { get; set; } = string.Empty;
}
