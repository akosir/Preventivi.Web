namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaMaterialeUpdateModel
{
    public int IdRigaMatPrev { get; set; }
    public string DescrizioneMateriale { get; set; } = string.Empty;
    public string? TipoMateriale { get; set; }
    public string? UM { get; set; }
    public decimal Quantita { get; set; }
    public decimal CostoUnitario { get; set; }
    public bool DaAcquistare { get; set; }
    public int? IdFornitoreSuggerito { get; set; }
}
