namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaMaterialeItem
{
    public int IdRigaMatPrev { get; set; }

    public int IdRigaPreventivo { get; set; }

    public int? IdNodoDistinta { get; set; }

    public int? IdMateriale { get; set; }

    public string DescrizioneMateriale { get; set; } = string.Empty;

    public string? TipoMateriale { get; set; }

    public string? UM { get; set; }

    public decimal Quantita { get; set; }

    public decimal CostoUnitario { get; set; }

    public decimal CostoTotale { get; set; }

    public bool DaAcquistare { get; set; }

    public int? IdFornitoreSuggerito { get; set; }
}
