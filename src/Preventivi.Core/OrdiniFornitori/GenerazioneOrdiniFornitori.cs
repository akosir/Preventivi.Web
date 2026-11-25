namespace Preventivi.Core.OrdiniFornitori;

public sealed class AcquistoPreventivo
{
    public string Tipo { get; set; } = string.Empty;
    public int IdOrigine { get; set; }
    public int IdRigaPreventivo { get; set; }
    public int RigaNr { get; set; }
    public int? IdVariantePreventivo { get; set; }
    public int? IdRigaCompPrev { get; set; }
    public string? Componente { get; set; }
    public string Descrizione { get; set; } = string.Empty;
    public string? UM { get; set; }
    public decimal Quantita { get; set; }
    public decimal GiaOrdinata { get; set; }
    public decimal Residuo { get; set; }
    public decimal PrezzoProposto { get; set; }
    public int? IdFornitoreSuggerito { get; set; }
    public string Impronta { get; set; } = string.Empty;
    public bool DaRiconciliare { get; set; }
}

public sealed record AcquistoSelezionato(string Tipo, int IdOrigine, string Impronta,
    int IdFornitore, decimal Quantita, decimal PrezzoUnitario);

public interface IGenerazioneOrdiniFornitoriRepository
{
    Task<IReadOnlyList<AcquistoPreventivo>> GetAnteprimaAsync(int idPreventivo, int? idRigaPreventivo,
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<OrdineFornitoreDettaglio>> ConfermaAsync(int idPreventivo, int? idRigaPreventivo,
        Guid richiesta, DateTime dataOrdine, IReadOnlyList<AcquistoSelezionato> selezione, string utente,
        CancellationToken cancellationToken = default);
}
