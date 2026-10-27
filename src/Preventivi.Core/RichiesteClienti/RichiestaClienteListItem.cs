namespace Preventivi.Core.RichiesteClienti;

public sealed class RichiestaClienteListItem
{
    public int IdRichiestaCliente { get; set; }
    public int NumeroRichiesta { get; set; }
    public int Anno { get; set; }
    public DateOnly DataRichiesta { get; set; }
    public int IdCliente { get; set; }
    public string Cliente { get; set; } = string.Empty;
    public string Oggetto { get; set; } = string.Empty;
    public string Stato { get; set; } = string.Empty;
    public string Priorita { get; set; } = string.Empty;
    public string? InteresseCliente { get; set; }
    public DateOnly? DataScadenza { get; set; }
    public int? ProbabilitaChiusura { get; set; }
    public int NumeroPreventivi { get; set; }
    public int NumeroCampionature { get; set; }

    public string NumeroCompleto => $"{Anno}-{NumeroRichiesta:00000}";
}
