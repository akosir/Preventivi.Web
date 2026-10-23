namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaUpdateModel
{
    public int IdRigaPreventivo { get; set; }
    public int IdTipoRiga { get; set; }
    public int? IdArticolo { get; set; }
    public int? IdModelloCiclo { get; set; }
    public int RigaNr { get; set; }
    public string DescrizioneVoce { get; set; } = string.Empty;
    public decimal Quantita { get; set; }
    public decimal PrezzoUnitarioVendita { get; set; }
    public string? Note { get; set; }
    public decimal MarkupPerc { get; set; }
    public bool PrezzoManuale { get; set; }
    public decimal? CostoUnitarioLibero { get; set; }
}
