namespace Preventivi.Core.Anagrafiche;

public sealed class ModelloCicloListItem
{
    public int IdModelloCiclo { get; set; }
    public string CodiceModelloCiclo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public int NumeroRighe { get; set; }
    public bool Attivo { get; set; }
}

public sealed class ModelloCicloDettaglio
{
    public int IdModelloCiclo { get; set; }
    public string CodiceModelloCiclo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public bool Attivo { get; set; }
    public string? Note { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public class ModelloCicloCreateModel
{
    public string CodiceModelloCiclo { get; init; } = string.Empty;
    public string Descrizione { get; init; } = string.Empty;
    public string? Note { get; init; }
    public string Utente { get; init; } = string.Empty;
}

public sealed class ModelloCicloUpdateModel : ModelloCicloCreateModel
{
    public int IdModelloCiclo { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}

public class ModelloCicloRigaListItem
{
    public int IdRigaModelloCiclo { get; set; }
    public int RigaNr { get; set; }
    public int Sequenza { get; set; }
    public int IdLavorazione { get; set; }
    public string CodiceLavorazione { get; set; } = string.Empty;
    public string DescrizioneLavorazione { get; set; } = string.Empty;
    public decimal TempoSetupMin { get; set; }
    public decimal TempoPezzoMin { get; set; }
    public decimal CostoOrario { get; set; }
    public decimal CostoFisso { get; set; }
}

public sealed class ModelloCicloRigaDettaglio : ModelloCicloRigaListItem
{
    public int IdModelloCiclo { get; set; }
    public string? Note { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public sealed class ModelloCicloLavorazioneLookupItem
{
    public int IdLavorazione { get; set; }
    public string CodiceLavorazione { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public decimal CostoOrarioStandard { get; set; }
    public decimal TempoSetupMinDefault { get; set; }
    public decimal TempoPezzoMinDefault { get; set; }
    public bool Attiva { get; set; }
    public string Display => $"{CodiceLavorazione} - {Descrizione}";
}

public class ModelloCicloRigaCreateModel
{
    public int IdModelloCiclo { get; init; }
    public int RigaNr { get; init; }
    public int Sequenza { get; init; }
    public int IdLavorazione { get; init; }
    public decimal TempoSetupMin { get; init; }
    public decimal TempoPezzoMin { get; init; }
    public decimal CostoOrario { get; init; }
    public decimal CostoFisso { get; init; }
    public string? Note { get; init; }
    public string Utente { get; init; } = string.Empty;
}

public sealed class ModelloCicloRigaUpdateModel : ModelloCicloRigaCreateModel
{
    public int IdRigaModelloCiclo { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class ModelloCicloRigaDeleteModel
{
    public int IdRigaModelloCiclo { get; init; }
    public int IdModelloCiclo { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}
