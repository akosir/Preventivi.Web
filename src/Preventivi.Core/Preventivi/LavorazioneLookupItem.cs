namespace Preventivi.Core.Preventivi;

public sealed class LavorazioneLookupItem
{
    public int IdLavorazione { get; set; }

    public string CodiceLavorazione { get; set; } = string.Empty;

    public string Descrizione { get; set; } = string.Empty;

    public string? InternaEsterna { get; set; }

    public decimal CostoOrarioStandard { get; set; }

    public decimal TempoSetupMinDefault { get; set; }

    public decimal TempoPezzoMinDefault { get; set; }

    public bool AcquistabileEsterna { get; set; }

    public int? IdFornitorePredefinito { get; set; }

    public string Display =>
        string.IsNullOrWhiteSpace(CodiceLavorazione)
            ? Descrizione
            : $"{CodiceLavorazione} - {Descrizione}";
}
