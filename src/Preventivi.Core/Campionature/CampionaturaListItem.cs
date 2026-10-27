namespace Preventivi.Core.Campionature;

public sealed class CampionaturaListItem
{
    public int IdCampionatura { get; set; }
    public int NumeroCampionatura { get; set; }
    public int Anno { get; set; }
    public DateOnly DataCampionatura { get; set; }
    public int IdRichiestaCliente { get; set; }
    public string NumeroRichiesta { get; set; } = string.Empty;
    public int IdCliente { get; set; }
    public string CodiceCliente { get; set; } = string.Empty;
    public string Cliente { get; set; } = string.Empty;
    public string Oggetto { get; set; } = string.Empty;
    public string Stato { get; set; } = string.Empty;
    public string Priorita { get; set; } = string.Empty;
    public DateOnly? DataPrevistaConsegna { get; set; }
    public string? Esito { get; set; }

    public string NumeroCompleto => $"{Anno}-{NumeroCampionatura:00000}";
}
