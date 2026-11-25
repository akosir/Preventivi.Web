using System.ComponentModel.DataAnnotations;

namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaComponenteUpdateModel
{
    public int IdRigaCompPrev { get; set; }
    [StringLength(200, ErrorMessage = "La descrizione del componente puo contenere al massimo {1} caratteri.")]
    public string DescrizioneNodo { get; set; } = string.Empty;
    public decimal QuantitaBase { get; set; }
    public int OrdineVisualizzazione { get; set; }
}
