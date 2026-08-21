namespace Preventivi.Web.UI.EmptyState;

public sealed class PFWEmptyStateModel
{
    public string Titolo { get; init; } = "";

    public string? Messaggio { get; init; }

    public string? Icona { get; init; }

    public string? TestoAzione { get; init; }

    public string? UrlAzione { get; init; }

    public string VarianteAzione { get; init; } = "primary";

    public bool MostraAzione =>
        !string.IsNullOrWhiteSpace(TestoAzione);

    public bool Visibile { get; init; } = true;
}