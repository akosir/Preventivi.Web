namespace Preventivi.Core.Clienti;

public sealed class ClienteListItem
{
    public int IdCliente { get; init; }

    public string CodiceCliente { get; init; } = "";

    public string RagioneSociale { get; init; } = "";

    public string? PartitaIVA { get; init; }

    public string? Citta { get; init; }

    public string? Telefono { get; init; }

    public string? Email { get; init; }

    public bool Attivo { get; init; }
}
