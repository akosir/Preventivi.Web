namespace Preventivi.Core.Preventivi;

public sealed class DistintaNodoLookupItem
{
    public int IdNodoDistinta { get; set; }

    public int IdArticolo { get; set; }

    public int? IdNodoPadre { get; set; }

    public string CodiceNodo { get; set; } = string.Empty;

    public string DescrizioneNodo { get; set; } = string.Empty;

    public int Livello { get; set; }

    public decimal QuantitaBase { get; set; }

    public int OrdineVisualizzazione { get; set; }

    public string TipoNodo { get; set; } = string.Empty;

    public string Display =>
        string.IsNullOrWhiteSpace(CodiceNodo)
            ? $"{DescrizioneNodo} - livello {Livello}"
            : $"{CodiceNodo} - {DescrizioneNodo} - livello {Livello}";
}
