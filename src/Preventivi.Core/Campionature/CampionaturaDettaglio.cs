namespace Preventivi.Core.Campionature;

public sealed class CampionaturaDettaglio
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
    public int? IdPreventivo { get; set; }
    public string? NumeroPreventivo { get; set; }
    public int? IdVariantePreventivo { get; set; }
    public string? VariantePreventivo { get; set; }
    public string Oggetto { get; set; } = string.Empty;
    public string? DescrizioneCampione { get; set; }
    public string Stato { get; set; } = string.Empty;
    public string Priorita { get; set; } = string.Empty;
    public DateOnly? DataRichiestaCampione { get; set; }
    public DateOnly? DataPrevistaConsegna { get; set; }
    public DateOnly? DataConsegnaCampione { get; set; }
    public DateOnly? DataChiusura { get; set; }
    public string? Esito { get; set; }
    public string? Note { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];

    public string NumeroCompleto => $"{Anno}-{NumeroCampionatura:00000}";
}
