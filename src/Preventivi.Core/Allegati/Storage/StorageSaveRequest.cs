namespace Preventivi.Core.Allegati.Storage;

public sealed class StorageSaveRequest
{
    public string Entita { get; set; } = "";

    public int IdEntita { get; set; }

    public string FileOrigine { get; set; } = "";

    public string NomeFileOriginale { get; set; } = "";

    public string? Utente { get; set; }
}
