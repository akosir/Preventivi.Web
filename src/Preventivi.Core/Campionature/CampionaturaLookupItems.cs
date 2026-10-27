namespace Preventivi.Core.Campionature;

public sealed class CampionaturaRichiestaLookupItem
{
    public int IdRichiestaCliente { get; set; }
    public string NumeroRichiesta { get; set; } = string.Empty;
    public int IdCliente { get; set; }
    public string CodiceCliente { get; set; } = string.Empty;
    public string Cliente { get; set; } = string.Empty;
    public string Oggetto { get; set; } = string.Empty;
    public string Priorita { get; set; } = string.Empty;
    public string Stato { get; set; } = string.Empty;
}

public sealed class CampionaturaPreventivoLookupItem
{
    public int IdPreventivo { get; set; }
    public int IdRichiestaCliente { get; set; }
    public string NumeroPreventivo { get; set; } = string.Empty;
    public string Oggetto { get; set; } = string.Empty;
    public string Stato { get; set; } = string.Empty;
}

public sealed class CampionaturaVarianteLookupItem
{
    public int IdVariantePreventivo { get; set; }
    public int IdPreventivo { get; set; }
    public string CodiceVariante { get; set; } = string.Empty;
    public string DescrizioneVariante { get; set; } = string.Empty;
}
