namespace Preventivi.Web.UI.Common.DataGrid;

public sealed class DataGridModel
{
    public IReadOnlyList<DataGridColumnModel> Colonne { get; init; } = [];

    public IReadOnlyList<DataGridRowModel> Righe { get; init; } = [];

    public string TitoloVuoto { get; init; } = "Nessun dato presente";

    public string MessaggioVuoto { get; init; } =
        "Non sono presenti elementi da visualizzare.";
}

public sealed class DataGridColumnModel
{
    public string Chiave { get; init; } = "";

    public string Titolo { get; init; } = "";

    public string? CssClass { get; init; }
}

public sealed class DataGridRowModel
{
    public string Id { get; init; } = "";

    public IReadOnlyDictionary<string, DataGridCellModel> Celle { get; init; }
        = new Dictionary<string, DataGridCellModel>();

    public IReadOnlyList<DataGridActionModel> Azioni { get; init; } = [];
}

public sealed class DataGridCellModel
{
    public string Testo { get; init; } = "";

    public string? BadgeVariante { get; init; }

    public string? CssClass { get; init; }
}

public sealed class DataGridActionModel
{
    public string Testo { get; init; } = "";

    public string Url { get; init; } = "#";

    public string Variante { get; init; } = "secondary";

    public bool Visibile { get; init; } = true;

    public bool Abilitata { get; init; } = true;
}