using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class DistintaRevisioneFormModel
{
    [StringLength(500)]
    public string? Note { get; set; }
}

public sealed class DistintaRevisioneDuplicazioneFormModel
{
    [Required(ErrorMessage = "Selezionare l'articolo di destinazione.")]
    public int? IdArticoloDestinazione { get; set; }

    [StringLength(500)]
    public string? Note { get; set; }
}

public sealed class DistintaRevisionePubblicazioneFormModel
{
    [Required(ErrorMessage = "La motivazione amministrativa e obbligatoria.")]
    [StringLength(500, MinimumLength = 3)]
    public string Motivazione { get; set; } = string.Empty;

    [Required]
    public string VersioneRigaBase64 { get; set; } = string.Empty;
}
