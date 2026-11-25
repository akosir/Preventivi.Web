namespace Preventivi.Core.Preventivi;

public sealed class PreventivoVarianteItem
{
    public int IdVariantePreventivo { get; set; }

    public int IdPreventivo { get; set; }

    public string CodiceVariante { get; set; } = string.Empty;

    public string DescrizioneVariante { get; set; } = string.Empty;
    public string? Note { get; set; }
    public bool Attiva { get; set; } = true;
    public string Impronta { get; set; } = string.Empty;

    public bool VarianteScelta { get; set; }

    public decimal TotaleCosti { get; set; }

    public decimal TotaleVendita { get; set; }

    public decimal MargineValore { get; set; }

    public decimal MarginePerc { get; set; }
}
