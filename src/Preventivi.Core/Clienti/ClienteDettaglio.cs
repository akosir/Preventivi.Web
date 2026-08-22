namespace Preventivi.Core.Clienti;

public sealed class ClienteDettaglio
{
    public int IdCliente { get; init; }

    public string CodiceCliente { get; init; } = "";

    public string RagioneSociale { get; init; } = "";

    public string? PartitaIVA { get; init; }

    public string? CodiceFiscale { get; init; }

    public string? Indirizzo { get; init; }

    public string? CAP { get; init; }

    public string? Citta { get; init; }

    public string? Provincia { get; init; }

    public string? Telefono { get; init; }

    public string? Email { get; init; }

    public bool Attivo { get; init; }
}