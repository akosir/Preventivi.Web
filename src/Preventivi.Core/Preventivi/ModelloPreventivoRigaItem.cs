namespace Preventivi.Core.Preventivi;

public sealed class ModelloPreventivoRigaItem
{
    public int IdRigaModelloPreventivo { get; set; }
    public int IdModelloPreventivo { get; set; }
    public int RigaNr { get; set; }
    public int IdTipoRiga { get; set; }
    public string TipoRiga { get; set; } = string.Empty;
    public int? IdArticolo { get; set; }
    public string Articolo { get; set; } = string.Empty;
    public int? IdModelloCiclo { get; set; }
    public string ModelloCiclo { get; set; } = string.Empty;
    public string DescrizioneVoce { get; set; } = string.Empty;
    public decimal Quantita { get; set; }
    public decimal PrezzoUnitarioVendita { get; set; }
    public string? Note { get; set; }
}
