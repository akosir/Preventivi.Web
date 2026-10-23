namespace Preventivi.Core.Preventivi;

public sealed class TipoRigaPreventivoItem
{
    public int IdTipoRiga { get; set; }

    public string Codice { get; set; } = string.Empty;

    public string Descrizione { get; set; } = string.Empty;

    public bool RigaArticolo { get; set; }

    public bool RigaLibera { get; set; }

    public bool MostraArticolo { get; set; }

    public bool ObbligaArticolo { get; set; }
}
