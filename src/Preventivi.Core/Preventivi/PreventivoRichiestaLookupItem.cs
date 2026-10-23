namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRichiestaLookupItem
{
    public int IdRichiestaCliente { get; set; }

    public int NumeroRichiesta { get; set; }

    public int Anno { get; set; }

    public int? IdCliente { get; set; }

    public string Cliente { get; set; } = string.Empty;

    public bool ClienteAttivo { get; set; }

    public string Oggetto { get; set; } = string.Empty;

    public string Stato { get; set; } = string.Empty;

    public string NumeroCompleto => $"{Anno}-{NumeroRichiesta:00000}";
}
