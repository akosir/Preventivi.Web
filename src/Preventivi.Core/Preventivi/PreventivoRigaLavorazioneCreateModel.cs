namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaLavorazioneCreateModel
{
    public int IdRigaPreventivo { get; set; }

    public int? IdNodoDistinta { get; set; }

    public int? IdLavorazione { get; set; }

    public string DescrizioneLavorazione { get; set; } = string.Empty;

    public int? Sequenza { get; set; }

    public decimal TempoSetupMin { get; set; }

    public decimal TempoPezzoMin { get; set; }

    public decimal Quantita { get; set; }

    public decimal CostoOrario { get; set; }

    public decimal CostoFisso { get; set; }

    public bool DaAcquistareEsterno { get; set; }

    public int? IdFornitoreSuggerito { get; set; }
}
