namespace Preventivi.Core.RichiesteClienti;

public sealed class RichiestaClienteDettaglio
{
    public int IdRichiestaCliente { get; set; }
    public int NumeroRichiesta { get; set; }
    public int Anno { get; set; }
    public DateOnly DataRichiesta { get; set; }
    public int IdCliente { get; set; }
    public string CodiceCliente { get; set; } = string.Empty;
    public string Cliente { get; set; } = string.Empty;
    public bool ClienteAttivo { get; set; }
    public string Oggetto { get; set; } = string.Empty;
    public string? DescrizioneRichiesta { get; set; }
    public string Stato { get; set; } = string.Empty;
    public string Priorita { get; set; } = string.Empty;
    public string? InteresseCliente { get; set; }
    public DateOnly? DataScadenza { get; set; }
    public DateOnly? DataAttivazione { get; set; }
    public DateOnly? DataChiusura { get; set; }
    public int? ProbabilitaChiusura { get; set; }
    public string? Note { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
    public int NumeroPreventivi { get; set; }
    public int NumeroCampionature { get; set; }

    public string NumeroCompleto => $"{Anno}-{NumeroRichiesta:00000}";
}
