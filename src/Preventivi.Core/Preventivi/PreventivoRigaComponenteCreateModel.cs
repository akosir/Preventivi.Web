namespace Preventivi.Core.Preventivi;

public sealed class PreventivoRigaComponenteCreateModel
{
    public int IdRigaPreventivo { get; set; }

    public int? IdNodoDistinta { get; set; }

    public int? IdNodoPadre { get; set; }

    public string DescrizioneNodo { get; set; } = string.Empty;

    public int Livello { get; set; }

    public decimal QuantitaBase { get; set; }

    public decimal QuantitaCalcolata { get; set; }

    public int? OrdineVisualizzazione { get; set; }
}
