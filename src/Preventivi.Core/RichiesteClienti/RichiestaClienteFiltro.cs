namespace Preventivi.Core.RichiesteClienti;

public sealed class RichiestaClienteFiltro
{
    public string? Ricerca { get; set; }
    public int? IdCliente { get; set; }
    public string? Stato { get; set; }
    public string? Priorita { get; set; }
    public string? InteresseCliente { get; set; }
    public DateOnly? ScadenzaDa { get; set; }
    public DateOnly? ScadenzaA { get; set; }
}
