namespace Preventivi.Core.Anagrafiche;

public sealed class UnitaMisuraLookupItem
{
    public int IdUM { get; set; }
    public string CodiceUM { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public bool Attivo { get; set; }
    public string Display => $"{CodiceUM} - {Descrizione}";
}

public sealed class FornitoreAnagraficaLookupItem
{
    public int IdFornitore { get; set; }
    public string CodiceFornitore { get; set; } = string.Empty;
    public string RagioneSociale { get; set; } = string.Empty;
    public bool Attivo { get; set; }
    public string Display => $"{CodiceFornitore} - {RagioneSociale}";
}

public sealed class MaterialeListItem
{
    public int IdMateriale { get; set; }
    public string CodiceMateriale { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public string TipoMateriale { get; set; } = string.Empty;
    public string CodiceUM { get; set; } = string.Empty;
    public decimal CostoUnitario { get; set; }
    public bool GestitoAAcquisto { get; set; }
    public bool Attivo { get; set; }
}

public sealed class MaterialeDettaglio
{
    public int IdMateriale { get; set; }
    public string CodiceMateriale { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public int IdUM { get; set; }
    public string CodiceUM { get; set; } = string.Empty;
    public string DescrizioneUM { get; set; } = string.Empty;
    public string TipoMateriale { get; set; } = string.Empty;
    public decimal CostoUnitario { get; set; }
    public bool GestitoAAcquisto { get; set; }
    public int? IdFornitorePredefinito { get; set; }
    public string? FornitorePredefinito { get; set; }
    public bool Attivo { get; set; }
    public string? Note { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public class MaterialeCreateModel
{
    public string CodiceMateriale { get; init; } = string.Empty;
    public string Descrizione { get; init; } = string.Empty;
    public int IdUM { get; init; }
    public string TipoMateriale { get; init; } = string.Empty;
    public decimal CostoUnitario { get; init; }
    public bool GestitoAAcquisto { get; init; }
    public int? IdFornitorePredefinito { get; init; }
    public string? Note { get; init; }
    public string Utente { get; init; } = string.Empty;
}

public sealed class MaterialeUpdateModel : MaterialeCreateModel
{
    public int IdMateriale { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class LavorazioneListItem
{
    public int IdLavorazione { get; set; }
    public string CodiceLavorazione { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public string InternaEsterna { get; set; } = string.Empty;
    public decimal CostoOrarioStandard { get; set; }
    public bool AcquistabileEsterna { get; set; }
    public bool Attiva { get; set; }
}

public sealed class LavorazioneDettaglio
{
    public int IdLavorazione { get; set; }
    public string CodiceLavorazione { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public string InternaEsterna { get; set; } = string.Empty;
    public decimal CostoOrarioStandard { get; set; }
    public decimal TempoSetupMinDefault { get; set; }
    public decimal TempoPezzoMinDefault { get; set; }
    public bool AcquistabileEsterna { get; set; }
    public int? IdFornitorePredefinito { get; set; }
    public string? FornitorePredefinito { get; set; }
    public bool Attiva { get; set; }
    public string? Note { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public class LavorazioneCreateModel
{
    public string CodiceLavorazione { get; init; } = string.Empty;
    public string Descrizione { get; init; } = string.Empty;
    public string InternaEsterna { get; init; } = string.Empty;
    public decimal CostoOrarioStandard { get; init; }
    public decimal TempoSetupMinDefault { get; init; }
    public decimal TempoPezzoMinDefault { get; init; }
    public bool AcquistabileEsterna { get; init; }
    public int? IdFornitorePredefinito { get; init; }
    public string? Note { get; init; }
    public string Utente { get; init; } = string.Empty;
}

public sealed class LavorazioneUpdateModel : LavorazioneCreateModel
{
    public int IdLavorazione { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class AnagraficaProduttivaStatoModel
{
    public int Id { get; init; }
    public bool Attivo { get; init; }
    public string Utente { get; init; } = string.Empty;
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class AnagraficaProduttivaDeleteModel
{
    public int Id { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}
