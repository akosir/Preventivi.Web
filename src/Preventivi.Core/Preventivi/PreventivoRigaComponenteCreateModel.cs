using System.ComponentModel.DataAnnotations;

namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaComponenteCreateModel
{
    public int IdRigaPreventivo { get; set; }

    public int? IdRigaCompPrevPadre { get; set; }

    [StringLength(20, ErrorMessage = "L'origine del componente puo contenere al massimo {1} caratteri.")]
    public string TipoOrigineComponente { get; set; } = string.Empty;

    public int? IdArticoloOrigine { get; set; }

    public int? IdNodoDistinta { get; set; }

    public int? IdNodoPadre { get; set; }

    [StringLength(200, ErrorMessage = "La descrizione del componente puo contenere al massimo {1} caratteri.")]
    public string DescrizioneNodo { get; set; } = string.Empty;

    public int Livello { get; set; }

    public decimal QuantitaBase { get; set; }

    public int? OrdineVisualizzazione { get; set; }
}
