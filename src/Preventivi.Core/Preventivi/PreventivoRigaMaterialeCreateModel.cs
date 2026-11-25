using System.ComponentModel.DataAnnotations;

namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaMaterialeCreateModel
{
    public int IdRigaPreventivo { get; set; }

    public int? IdRigaCompPrev { get; set; }

    public int? IdNodoDistinta { get; set; }

    public int? IdMateriale { get; set; }

    [StringLength(200, ErrorMessage = "La descrizione del materiale puo contenere al massimo {1} caratteri.")]
    public string DescrizioneMateriale { get; set; } = string.Empty;

    [StringLength(30, ErrorMessage = "Il tipo materiale puo contenere al massimo {1} caratteri.")]
    public string? TipoMateriale { get; set; }

    [StringLength(10, ErrorMessage = "L'unita di misura puo contenere al massimo {1} caratteri.")]
    public string? UM { get; set; }

    public decimal Quantita { get; set; }

    public decimal CostoUnitario { get; set; }

    public bool DaAcquistare { get; set; }

    public int? IdFornitoreSuggerito { get; set; }
}
