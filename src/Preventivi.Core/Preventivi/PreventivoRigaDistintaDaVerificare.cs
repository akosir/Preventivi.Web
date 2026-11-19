namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaDistintaDaVerificare
{
    public int IdRigaPreventivo { get; set; }
    public int RigaNr { get; set; }
    public string DescrizioneVoce { get; set; } = string.Empty;
    public string CodiceArticolo { get; set; } = string.Empty;
    public string? CodiceVariante { get; set; }
    public bool VersioneNota { get; set; }
}
