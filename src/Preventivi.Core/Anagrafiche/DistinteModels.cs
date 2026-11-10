namespace Preventivi.Core.Anagrafiche;

public sealed class DistintaArticoloListItem
{
    public int IdArticolo { get; set; }
    public string CodiceArticolo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public string? Versione { get; set; }
    public bool Attivo { get; set; }
    public int NumeroNodiAttivi { get; set; }
    public int NumeroNodiTotali { get; set; }
}

public sealed class TipoNodoDistintaLookupItem
{
    public int IdTipoNodo { get; set; }
    public string Descrizione { get; set; } = string.Empty;
    public bool Attivo { get; set; }
}

public class DistintaNodoItem
{
    public int IdNodoDistinta { get; set; }
    public int IdArticolo { get; set; }
    public string CodiceArticolo { get; set; } = string.Empty;
    public string DescrizioneArticolo { get; set; } = string.Empty;
    public int? IdNodoPadre { get; set; }
    public int IdTipoNodo { get; set; }
    public string TipoNodo { get; set; } = string.Empty;
    public string? CodiceNodo { get; set; }
    public string DescrizioneNodo { get; set; } = string.Empty;
    public decimal QuantitaBase { get; set; }
    public int Livello { get; set; }
    public int OrdineVisualizzazione { get; set; }
    public bool Attivo { get; set; }
    public string PercorsoCompleto { get; set; } = string.Empty;
    public string Display => $"{new string(' ', Livello * 2)}{(string.IsNullOrWhiteSpace(CodiceNodo) ? string.Empty : $"{CodiceNodo} - ")}{DescrizioneNodo}";
}

public sealed class DistintaNodoDettaglio : DistintaNodoItem
{
    public string? Note { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public class DistintaNodoCreateModel
{
    public int IdArticolo { get; init; }
    public int? IdNodoPadre { get; init; }
    public int IdTipoNodo { get; init; }
    public string? CodiceNodo { get; init; }
    public string DescrizioneNodo { get; init; } = string.Empty;
    public decimal QuantitaBase { get; init; }
    public int OrdineVisualizzazione { get; init; }
    public string? Note { get; init; }
    public string Utente { get; init; } = string.Empty;
}

public sealed class DistintaNodoUpdateModel : DistintaNodoCreateModel
{
    public int IdNodoDistinta { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class DistintaNodoStatoModel
{
    public int IdNodoDistinta { get; init; }
    public bool Attivo { get; init; }
    public string Utente { get; init; } = string.Empty;
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class DistintaElementoDeleteModel
{
    public int Id { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class DistintaMaterialeLookupItem
{
    public int IdMateriale { get; set; }
    public string CodiceMateriale { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public decimal CostoUnitario { get; set; }
    public string CodiceUM { get; set; } = string.Empty;
    public string Display => $"{CodiceMateriale} - {Descrizione}";
}

public sealed class DistintaMaterialeDettaglio
{
    public int IdDistintaMateriale { get; set; }
    public int IdNodoDistinta { get; set; }
    public int IdArticolo { get; set; }
    public int IdMateriale { get; set; }
    public string CodiceMateriale { get; set; } = string.Empty;
    public string DescrizioneMateriale { get; set; } = string.Empty;
    public string CodiceUM { get; set; } = string.Empty;
    public decimal Quantita { get; set; }
    public decimal CoeffScartoPerc { get; set; }
    public decimal CostoUnitario { get; set; }
    public string? Note { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public class DistintaMaterialeCreateModel
{
    public int IdNodoDistinta { get; init; }
    public int IdMateriale { get; init; }
    public decimal Quantita { get; init; }
    public decimal CoeffScartoPerc { get; init; }
    public decimal CostoUnitario { get; init; }
    public string? Note { get; init; }
    public string Utente { get; init; } = string.Empty;
}

public sealed class DistintaMaterialeUpdateModel : DistintaMaterialeCreateModel
{
    public int IdDistintaMateriale { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}

public sealed class DistintaLavorazioneLookupItem
{
    public int IdLavorazione { get; set; }
    public string CodiceLavorazione { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public decimal CostoOrarioStandard { get; set; }
    public decimal TempoSetupMinDefault { get; set; }
    public decimal TempoPezzoMinDefault { get; set; }
    public string Display => $"{CodiceLavorazione} - {Descrizione}";
}

public sealed class DistintaLavorazioneDettaglio
{
    public int IdDistintaLavorazione { get; set; }
    public int IdNodoDistinta { get; set; }
    public int IdArticolo { get; set; }
    public int IdLavorazione { get; set; }
    public string CodiceLavorazione { get; set; } = string.Empty;
    public string DescrizioneLavorazione { get; set; } = string.Empty;
    public int Sequenza { get; set; }
    public decimal TempoSetupMin { get; set; }
    public decimal TempoPezzoMin { get; set; }
    public decimal CostoOrario { get; set; }
    public decimal CostoFisso { get; set; }
    public int? IdModelloCiclo { get; set; }
    public string? Note { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public string UtenteCreazione { get; set; } = string.Empty;
    public string? UtenteModifica { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

public class DistintaLavorazioneCreateModel
{
    public int IdNodoDistinta { get; init; }
    public int IdLavorazione { get; init; }
    public int Sequenza { get; init; }
    public decimal TempoSetupMin { get; init; }
    public decimal TempoPezzoMin { get; init; }
    public decimal CostoOrario { get; init; }
    public decimal CostoFisso { get; init; }
    public string? Note { get; init; }
    public string Utente { get; init; } = string.Empty;
}

public sealed class DistintaLavorazioneUpdateModel : DistintaLavorazioneCreateModel
{
    public int IdDistintaLavorazione { get; init; }
    public byte[] VersioneRiga { get; init; } = [];
}
