namespace Preventivi.Core.Clienti;

public sealed class ClienteUpdateModel
{
    public int IdCliente { get; set; }

    public string CodiceCliente { get; set; } = "";

    public string RagioneSociale { get; set; } = "";

    public string? PartitaIVA { get; set; }

    public string? CodiceFiscale { get; set; }

    public string? Indirizzo { get; set; }

    public string? CAP { get; set; }

    public string? Citta { get; set; }

    public string? Provincia { get; set; }

    public string? Telefono { get; set; }

    public string? Email { get; set; }

    public bool Attivo { get; set; }
}