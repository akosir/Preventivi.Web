namespace Preventivi.Core.RichiesteClienti;

public sealed class RichiestaClienteUpdateModel
{
    public int IdRichiestaCliente { get; set; }
    public DateOnly DataRichiesta { get; set; }
    public int IdCliente { get; set; }
    public string Oggetto { get; set; } = string.Empty;
    public string? DescrizioneRichiesta { get; set; }
    public string Stato { get; set; } = string.Empty;
    public string Priorita { get; set; } = string.Empty;
    public string? InteresseCliente { get; set; }
    public DateOnly? DataScadenza { get; set; }
    public int? ProbabilitaChiusura { get; set; }
    public string? Note { get; set; }
    public string Utente { get; set; } = string.Empty;
    public byte[] VersioneRiga { get; set; } = [];
}
