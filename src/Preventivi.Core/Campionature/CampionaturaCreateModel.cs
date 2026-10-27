namespace Preventivi.Core.Campionature;

public class CampionaturaCreateModel
{
    public DateOnly DataCampionatura { get; set; }
    public int IdRichiestaCliente { get; set; }
    public int? IdPreventivo { get; set; }
    public int? IdVariantePreventivo { get; set; }
    public string Oggetto { get; set; } = string.Empty;
    public string? DescrizioneCampione { get; set; }
    public string Stato { get; set; } = "Aperta";
    public string Priorita { get; set; } = "Media";
    public DateOnly? DataRichiestaCampione { get; set; }
    public DateOnly? DataPrevistaConsegna { get; set; }
    public DateOnly? DataConsegnaCampione { get; set; }
    public DateOnly? DataChiusura { get; set; }
    public string? Esito { get; set; }
    public string? Note { get; set; }
    public string Utente { get; set; } = string.Empty;
}
