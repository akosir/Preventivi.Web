namespace Preventivi.Core.Sicurezza;

public sealed record AmministratoreOperante(int IdUtente, Guid VersioneSessione);

public sealed class UtenteGestione
{
    public int IdUtente { get; set; }
    public string Username { get; set; } = string.Empty;
    public string? NomeCompleto { get; set; }
    public bool Attivo { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
    public bool PasswordImpostata { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
    public string RuoliJson { get; set; } = "[]";
    public string Ruoli { get; set; } = string.Empty;
}

public sealed class RuoloGestione
{
    public int IdRuolo { get; set; }
    public string CodiceRuolo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public bool Attivo { get; set; }
}

public sealed class UtenteAudit
{
    public DateTime DataOperazione { get; set; }
    public string Operazione { get; set; } = string.Empty;
    public string Operatore { get; set; } = string.Empty;
    public string? PrimaJson { get; set; }
    public string? DopoJson { get; set; }
}

public sealed class UtenteSalvataggio
{
    public string Username { get; set; } = string.Empty;
    public string? NomeCompleto { get; set; }
    public bool Attivo { get; set; } = true;
    public int[] Ruoli { get; set; } = [];
    public byte[] VersioneRiga { get; set; } = [];
}

public interface IGestioneUtentiRepository
{
    Task<IReadOnlyList<UtenteGestione>> GetElencoAsync(AmministratoreOperante attore, string? ricerca, bool? attivo, CancellationToken cancellationToken = default);
    Task<UtenteGestione?> GetDettaglioAsync(AmministratoreOperante attore, int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RuoloGestione>> GetRuoliAsync(AmministratoreOperante attore, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<UtenteAudit>> GetAuditAsync(AmministratoreOperante attore, int id, CancellationToken cancellationToken = default);
    Task<int> SalvaAsync(AmministratoreOperante attore, int? id, UtenteSalvataggio dati, string? passwordHash, CancellationToken cancellationToken = default);
    Task ReimpostaPasswordAsync(AmministratoreOperante attore, int id, byte[] versione, string passwordHash, CancellationToken cancellationToken = default);
}
