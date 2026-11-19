namespace Preventivi.Core.Preventivi;

public sealed class DistintaSnapshotAnteprimaItem
{
    public bool RevisioneGiaApplicata => Tipo == "RevisioneGiaApplicata";
    public int IdRevisione { get; set; }
    public int NumeroRevisione { get; set; }
    public long VersioneContenuto { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public string Componente { get; set; } = string.Empty;
    public string Elemento { get; set; } = string.Empty;
}
