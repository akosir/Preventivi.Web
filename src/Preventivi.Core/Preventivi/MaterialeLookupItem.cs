namespace Preventivi.Core.Preventivi;

public sealed class MaterialeLookupItem
{
    public int IdMateriale { get; set; }

    public string CodiceMateriale { get; set; } = string.Empty;

    public string Descrizione { get; set; } = string.Empty;

    public string? TipoMateriale { get; set; }

    public string? UM { get; set; }

    public decimal CostoUnitario { get; set; }

    public bool GestitoAAcquisto { get; set; }

    public int? IdFornitorePredefinito { get; set; }

    public string Display =>
        string.IsNullOrWhiteSpace(CodiceMateriale)
            ? Descrizione
            : $"{CodiceMateriale} - {Descrizione}";
}
