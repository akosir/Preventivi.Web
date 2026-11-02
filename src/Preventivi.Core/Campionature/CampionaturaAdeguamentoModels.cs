namespace Preventivi.Core.Campionature;

public sealed class CampionaturaAdeguamentoListItem
{
    public int IdAdeguamento { get; set; }
    public int IdCampionatura { get; set; }
    public int IdRilievoCampionatura { get; set; }
    public int RigaNrRilievo { get; set; }
    public string DescrizioneAdeguamento { get; set; } = string.Empty;
    public decimal ImpattoCostoStimato { get; set; }
    public decimal ImpattoVenditaStimato { get; set; }
    public bool Applicato { get; set; }
    public DateOnly? DataApplicazione { get; set; }
    public int? IdVarianteGenerata { get; set; }
    public string? CodiceVarianteGenerata { get; set; }
}

public sealed class CampionaturaAdeguamentoCreateModel
{
    public int IdRilievoCampionatura { get; set; }
    public string DescrizioneAdeguamento { get; set; } = string.Empty;
    public decimal ImpattoCostoStimato { get; set; }
    public decimal ImpattoVenditaStimato { get; set; }
    public string? Note { get; set; }
    public byte[] VersioneRilievo { get; set; } = [];
    public string Utente { get; set; } = string.Empty;
}

public sealed class CampionaturaAdeguamentoDettaglio
{
    public int IdAdeguamento { get; set; }
    public int IdCampionatura { get; set; }
    public int IdRilievoCampionatura { get; set; }
    public int RigaNrRilievo { get; set; }
    public string DescrizioneProblema { get; set; } = string.Empty;
    public int? IdPreventivo { get; set; }
    public int? IdVariantePreventivo { get; set; }
    public int? IdVarianteGenerata { get; set; }
    public string? CodiceVarianteGenerata { get; set; }
    public string? DescrizioneVarianteGenerata { get; set; }
    public string DescrizioneAdeguamento { get; set; } = string.Empty;
    public decimal ImpattoCostoStimato { get; set; }
    public decimal ImpattoVenditaStimato { get; set; }
    public bool Applicato { get; set; }
    public DateOnly? DataApplicazione { get; set; }
    public DateTime? DataPreparazione { get; set; }
    public string? UtentePreparazione { get; set; }
    public string? UtenteApplicazione { get; set; }
    public string? Note { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
    public byte[] VersioneRilievo { get; set; } = [];
}

public sealed class CampionaturaAdeguamentoUpdateModel
{
    public int IdAdeguamento { get; set; }
    public string DescrizioneAdeguamento { get; set; } = string.Empty;
    public decimal ImpattoCostoStimato { get; set; }
    public decimal ImpattoVenditaStimato { get; set; }
    public string? Note { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
    public string Utente { get; set; } = string.Empty;
}

public sealed class CampionaturaAdeguamentoDeleteModel
{
    public int IdAdeguamento { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
    public byte[] VersioneRilievo { get; set; } = [];
    public string Utente { get; set; } = string.Empty;
}

public sealed class CampionaturaAdeguamentoPreparaModel
{
    public int IdAdeguamento { get; set; }
    public string CodiceVariante { get; set; } = string.Empty;
    public string DescrizioneVariante { get; set; } = string.Empty;
    public byte[] VersioneRiga { get; set; } = [];
    public string Utente { get; set; } = string.Empty;
}

public sealed class CampionaturaAdeguamentoAnnullaPreparazioneModel
{
    public int IdAdeguamento { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
    public string Utente { get; set; } = string.Empty;
}

public sealed class CampionaturaAdeguamentoConfermaModel
{
    public int IdAdeguamento { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
    public byte[] VersioneRilievo { get; set; } = [];
    public string Utente { get; set; } = string.Empty;
}
