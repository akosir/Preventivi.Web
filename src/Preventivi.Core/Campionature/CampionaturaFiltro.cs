namespace Preventivi.Core.Campionature;

public sealed class CampionaturaFiltro
{
    public string? Ricerca { get; set; }
    public int? IdCliente { get; set; }
    public int? IdRichiestaCliente { get; set; }
    public string? Stato { get; set; }
    public string? Priorita { get; set; }
    public DateOnly? ConsegnaDa { get; set; }
    public DateOnly? ConsegnaA { get; set; }
}
