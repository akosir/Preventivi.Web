namespace Preventivi.Core.RichiesteClienti;

public sealed class RichiestaClienteCreateModel
{
    public DateOnly DataRichiesta { get; set; }
    public int IdCliente { get; set; }
    public string Oggetto { get; set; } = string.Empty;
    public string? DescrizioneRichiesta { get; set; }
    public string Stato { get; set; } = "Nuova";
    public string Priorita { get; set; } = "Media";
    public string? InteresseCliente { get; set; }
    public DateOnly? DataScadenza { get; set; }
    public int? ProbabilitaChiusura { get; set; }
    public string? Note { get; set; }
    public string Utente { get; set; } = string.Empty;
}
