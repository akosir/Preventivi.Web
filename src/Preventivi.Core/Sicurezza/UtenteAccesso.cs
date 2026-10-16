namespace Preventivi.Core.Sicurezza;

public sealed class UtenteAccesso
{
    public int IdUtente { get; init; }
    public string Username { get; init; } = "";
    public string? NomeCompleto { get; init; }
    public string? PasswordHash { get; init; }
    public bool Attivo { get; init; }
    public IReadOnlyList<string> Ruoli { get; init; } = [];
    public IReadOnlyList<string> Permessi { get; init; } = [];
}
