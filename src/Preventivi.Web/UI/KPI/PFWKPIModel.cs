namespace Preventivi.Web.UI.KPI;

public sealed class PFWKPIModel
{
    public string Titolo { get; init; } = "";

    public string Valore { get; init; } = "";

    public string? Sottotitolo { get; init; }

    public string? Icona { get; init; }

    public string Variante { get; init; } = "neutro";

    public bool Evidenziato { get; init; }

    public bool Visibile { get; init; } = true;
}