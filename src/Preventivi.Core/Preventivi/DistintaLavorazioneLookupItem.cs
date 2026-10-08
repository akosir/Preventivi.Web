namespace Preventivi.Core.Preventivi;

public sealed class DistintaLavorazioneLookupItem
{
    public int IdDistintaLavorazione { get; set; }

    public int IdNodoDistinta { get; set; }

    public int IdLavorazione { get; set; }

    public string CodiceLavorazione { get; set; } = string.Empty;

    public string DescrizioneLavorazione { get; set; } = string.Empty;

    public int? Sequenza { get; set; }

    public decimal TempoSetupMin { get; set; }

    public decimal TempoPezzoMin { get; set; }

    public decimal CostoOrario { get; set; }

    public decimal CostoFisso { get; set; }

    public bool DaAcquistareEsterno { get; set; }

    public int? IdFornitoreSuggerito { get; set; }

    public string Display =>
        $"{Sequenza?.ToString() ?? "-"} - {CodiceLavorazione} - {DescrizioneLavorazione}";
}
