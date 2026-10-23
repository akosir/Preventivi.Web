namespace Preventivi.Core.Preventivi;

public sealed class ModelloPreventivoRigaCreateModel
{
    public int IdModelloPreventivo { get; set; }
    public int RigaNr { get; set; }
    public int IdTipoRiga { get; set; }
    public int? IdArticolo { get; set; }
    public int? IdModelloCiclo { get; set; }
    public string DescrizioneVoce { get; set; } = string.Empty;
    public decimal Quantita { get; set; }
    public decimal PrezzoUnitarioVendita { get; set; }
    public string? Note { get; set; }
}
