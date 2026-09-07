namespace Preventivi.Core.Preventivi;

public sealed class PreventivoVarianteCreateModel
{
    public int IdPreventivo { get; set; }

    public string CodiceVariante { get; set; } = string.Empty;

    public string DescrizioneVariante { get; set; } = string.Empty;

    public string? Note { get; set; }

    public bool VarianteScelta { get; set; }
}
