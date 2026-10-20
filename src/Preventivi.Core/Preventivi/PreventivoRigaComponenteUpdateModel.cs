namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaComponenteUpdateModel
{
    public int IdRigaCompPrev { get; set; }
    public string DescrizioneNodo { get; set; } = string.Empty;
    public decimal QuantitaBase { get; set; }
    public int OrdineVisualizzazione { get; set; }
}
