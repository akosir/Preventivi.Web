namespace Preventivi.Core.Preventivi;

public sealed class PreventivoMarkupAnteprima
{
    public int IdPreventivo { get; set; }
    public string Stato { get; set; } = string.Empty;
    public decimal MarkupPercDefault { get; set; }
    public string Impronta { get; set; } = string.Empty;
    public int? IdRigaPreventivo { get; set; }
    public int? RigaNr { get; set; }
    public string? DescrizioneVoce { get; set; }
    public string? CodiceVariante { get; set; }
    public bool PrezzoManuale { get; set; }
    public decimal MarkupPerc { get; set; }
    public decimal TotaleCosti { get; set; }
    public decimal TotaleVendita { get; set; }

    public static bool StatoModificabile(string stato) => stato is "Bozza" or "Da Verificare" or "Pronto da Inviare";
}
