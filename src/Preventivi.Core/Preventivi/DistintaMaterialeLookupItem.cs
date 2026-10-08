namespace Preventivi.Core.Preventivi;

public sealed class DistintaMaterialeLookupItem
{
    public int IdDistintaMateriale { get; set; }

    public int IdNodoDistinta { get; set; }

    public int IdMateriale { get; set; }

    public string CodiceMateriale { get; set; } = string.Empty;

    public string DescrizioneMateriale { get; set; } = string.Empty;

    public string? TipoMateriale { get; set; }

    public string? UM { get; set; }

    public decimal Quantita { get; set; }

    public decimal CostoUnitario { get; set; }

    public bool DaAcquistare { get; set; }

    public int? IdFornitoreSuggerito { get; set; }

    public string Display =>
        $"{CodiceMateriale} - {DescrizioneMateriale} ({Quantita:N2})";
}
