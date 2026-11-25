using System.ComponentModel.DataAnnotations;

namespace Preventivi.Core.Preventivi;

public sealed class PreventivoVarianteCreateModel
{
    public int IdPreventivo { get; set; }

    [StringLength(30, ErrorMessage = "Il codice variante puo contenere al massimo {1} caratteri.")]
    public string CodiceVariante { get; set; } = string.Empty;

    [StringLength(250, ErrorMessage = "La descrizione variante puo contenere al massimo {1} caratteri.")]
    public string DescrizioneVariante { get; set; } = string.Empty;

    public string? Note { get; set; }

    public bool VarianteScelta { get; set; }
}
