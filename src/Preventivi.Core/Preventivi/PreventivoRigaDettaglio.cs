namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaDettaglio
{
    public int IdRigaPreventivo { get; set; }

    public int IdPreventivo { get; set; }

    public int RigaNr { get; set; }

    public int? IdArticolo { get; set; }

    public int? IdModelloCiclo { get; set; }

    public string DescrizioneVoce { get; set; } = string.Empty;

    public decimal Quantita { get; set; }

    public decimal PrezzoUnitarioVendita { get; set; }

    public decimal TotaleVendita { get; set; }

    public decimal TotaleCosti { get; set; }

    public decimal MargineValore { get; set; }

    public decimal MarginePerc { get; set; }

    public string? Note { get; set; }

    public decimal MarkupPerc { get; set; }

    public bool PrezzoManuale { get; set; }

    public int? IdVariantePreventivo { get; set; }

    public decimal? CostoUnitarioLibero { get; set; }

    public int IdTipoRiga { get; set; }

    public string TipoRiga { get; set; } = string.Empty;
}
