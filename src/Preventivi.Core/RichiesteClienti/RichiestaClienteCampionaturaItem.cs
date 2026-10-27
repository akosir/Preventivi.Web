namespace Preventivi.Core.RichiesteClienti;

public sealed class RichiestaClienteCampionaturaItem
{
    public int IdCampionatura { get; set; }
    public int NumeroCampionatura { get; set; }
    public int Anno { get; set; }
    public DateOnly DataCampionatura { get; set; }
    public string Stato { get; set; } = string.Empty;
    public string Priorita { get; set; } = string.Empty;

    public string NumeroCompleto => $"{Anno}-{NumeroCampionatura:00000}";
}
