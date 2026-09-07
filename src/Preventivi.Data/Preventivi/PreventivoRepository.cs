using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;
using Preventivi.Data.Comune;
using System.Data;

namespace Preventivi.Data.Preventivi;

public sealed class PreventivoRepository : IPreventivoRepository
{
    private readonly DatabaseExecutor _db;

    public PreventivoRepository(DatabaseExecutor db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<PreventivoListItem>> GetElencoAsync(
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<PreventivoListItem>(
            "dbo.Preventivi_Elenco",
            cancellationToken: cancellationToken);
    }

    public async Task<PreventivoDettaglio?> GetDettaglioAsync(
        int idPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<PreventivoDettaglio>(
            "dbo.Preventivi_Dettaglio",
            [new SqlParameter("@IdPreventivo", idPreventivo)],
            cancellationToken);
    }

    public async Task<IReadOnlyList<PreventivoRigaListItem>> GetRigheAsync(
        int idPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<PreventivoRigaListItem>(
            "dbo.Preventivi_Righe_Elenco",
            [new SqlParameter("@IdPreventivo", idPreventivo)],
            cancellationToken);
    }

    public async Task<PreventivoRigaDettaglio?> GetRigaAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<PreventivoRigaDettaglio>(
            "dbo.Preventivi_Righe_Dettaglio",
            [new SqlParameter("@IdRigaPreventivo", idRigaPreventivo)],
            cancellationToken);
    }

    public async Task<int> CreaRigaAsync(
        PreventivoRigaCreateModel riga,
        CancellationToken cancellationToken = default)
    {
        var parameters = new[]
        {
            new SqlParameter("@IdPreventivo", riga.IdPreventivo),
            NullableInt("@RigaNr", riga.RigaNr),
            NullableInt("@IdArticolo", riga.IdArticolo),
            NullableInt("@IdModelloCiclo", riga.IdModelloCiclo),
            Text("@DescrizioneVoce", riga.DescrizioneVoce, 500),
            Decimal("@Quantita", riga.Quantita, 18, 4),
            Decimal("@PrezzoUnitarioVendita", riga.PrezzoUnitarioVendita, 18, 4),
            Decimal("@TotaleCosti", riga.TotaleCosti, 18, 2),
            NullableText("@Note", riga.Note),
            Decimal("@MarkupPerc", riga.MarkupPerc, 9, 2),
            new SqlParameter("@PrezzoManuale", SqlDbType.Bit) { Value = riga.PrezzoManuale },
            NullableInt("@IdVariantePreventivo", riga.IdVariantePreventivo),
            NullableDecimal("@CostoUnitarioLibero", riga.CostoUnitarioLibero, 18, 4),
            new SqlParameter("@IdTipoRiga", riga.IdTipoRiga)
        };

        return await _db.ExecuteScalarAsync<int>(
            "dbo.Preventivi_Righe_Crea",
            parameters,
            cancellationToken);
    }

    public async Task EliminaRigaAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Preventivi_Righe_Elimina",
            [new SqlParameter("@IdRigaPreventivo", idRigaPreventivo)],
            cancellationToken);
    }

    public async Task<IReadOnlyList<TipoRigaPreventivoItem>> GetTipiRigaAsync(
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<TipoRigaPreventivoItem>(
            "dbo.TipiRigaPreventivo_Elenco",
            cancellationToken: cancellationToken);
    }

    public async Task<IReadOnlyList<PreventivoVarianteItem>> GetVariantiAsync(
        int idPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<PreventivoVarianteItem>(
            "dbo.Preventivi_Varianti_Elenco",
            [new SqlParameter("@IdPreventivo", idPreventivo)],
            cancellationToken);
    }

    public async Task<PreventivoVarianteItem?> GetVarianteAsync(
        int idVariantePreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<PreventivoVarianteItem>(
            "dbo.Preventivi_Varianti_Dettaglio",
            [new SqlParameter("@IdVariantePreventivo", idVariantePreventivo)],
            cancellationToken);
    }

    public async Task<int> CreaVarianteAsync(
        PreventivoVarianteCreateModel variante,
        CancellationToken cancellationToken = default)
    {
        var parameters = new[]
        {
            new SqlParameter("@IdPreventivo", variante.IdPreventivo),
            Text("@CodiceVariante", variante.CodiceVariante, 60),
            Text("@DescrizioneVariante", variante.DescrizioneVariante, 500),
            NullableText("@Note", variante.Note),
            new SqlParameter("@VarianteScelta", SqlDbType.Bit) { Value = variante.VarianteScelta }
        };

        return await _db.ExecuteScalarAsync<int>(
            "dbo.Preventivi_Varianti_Crea",
            parameters,
            cancellationToken);
    }

    public async Task EliminaVarianteAsync(
        int idVariantePreventivo,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Preventivi_Varianti_Elimina",
            [new SqlParameter("@IdVariantePreventivo", idVariantePreventivo)],
            cancellationToken);
    }

    public async Task<IReadOnlyList<PreventivoRigaComponenteItem>> GetComponentiAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<PreventivoRigaComponenteItem>(
            "dbo.Preventivi_Righe_Componenti_Elenco",
            [new SqlParameter("@IdRigaPreventivo", idRigaPreventivo)],
            cancellationToken);
    }

    public async Task<PreventivoRigaComponenteItem?> GetComponenteAsync(
        int idRigaCompPrev,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<PreventivoRigaComponenteItem>(
            "dbo.Preventivi_Righe_Componenti_Dettaglio",
            [new SqlParameter("@IdRigaCompPrev", idRigaCompPrev)],
            cancellationToken);
    }

    public async Task<int> CreaComponenteAsync(
        PreventivoRigaComponenteCreateModel componente,
        CancellationToken cancellationToken = default)
    {
        var parameters = new[]
        {
            new SqlParameter("@IdRigaPreventivo", componente.IdRigaPreventivo),
            NullableInt("@IdNodoDistinta", componente.IdNodoDistinta),
            NullableInt("@IdNodoPadre", componente.IdNodoPadre),
            Text("@DescrizioneNodo", componente.DescrizioneNodo, 400),
            new SqlParameter("@Livello", componente.Livello),
            Decimal("@QuantitaBase", componente.QuantitaBase, 18, 4),
            Decimal("@QuantitaCalcolata", componente.QuantitaCalcolata, 18, 4),
            NullableInt("@OrdineVisualizzazione", componente.OrdineVisualizzazione)
        };

        return await _db.ExecuteScalarAsync<int>(
            "dbo.Preventivi_Righe_Componenti_Crea",
            parameters,
            cancellationToken);
    }

    public async Task EliminaComponenteAsync(
        int idRigaCompPrev,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Preventivi_Righe_Componenti_Elimina",
            [new SqlParameter("@IdRigaCompPrev", idRigaCompPrev)],
            cancellationToken);
    }

    public async Task<IReadOnlyList<PreventivoRigaMaterialeItem>> GetMaterialiAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<PreventivoRigaMaterialeItem>(
            "dbo.Preventivi_Righe_Materiali_Elenco",
            [new SqlParameter("@IdRigaPreventivo", idRigaPreventivo)],
            cancellationToken);
    }

    public async Task<PreventivoRigaMaterialeItem?> GetMaterialeAsync(
        int idRigaMatPrev,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<PreventivoRigaMaterialeItem>(
            "dbo.Preventivi_Righe_Materiali_Dettaglio",
            [new SqlParameter("@IdRigaMatPrev", idRigaMatPrev)],
            cancellationToken);
    }

    public async Task<int> CreaMaterialeAsync(
        PreventivoRigaMaterialeCreateModel materiale,
        CancellationToken cancellationToken = default)
    {
        var parameters = new[]
        {
            new SqlParameter("@IdRigaPreventivo", materiale.IdRigaPreventivo),
            NullableInt("@IdNodoDistinta", materiale.IdNodoDistinta),
            NullableInt("@IdMateriale", materiale.IdMateriale),
            Text("@DescrizioneMateriale", materiale.DescrizioneMateriale, 400),
            NullableShortText("@TipoMateriale", materiale.TipoMateriale, 60),
            NullableShortText("@UM", materiale.UM, 20),
            Decimal("@Quantita", materiale.Quantita, 18, 4),
            Decimal("@CostoUnitario", materiale.CostoUnitario, 18, 4),
            new SqlParameter("@DaAcquistare", SqlDbType.Bit) { Value = materiale.DaAcquistare },
            NullableInt("@IdFornitoreSuggerito", materiale.IdFornitoreSuggerito)
        };

        return await _db.ExecuteScalarAsync<int>(
            "dbo.Preventivi_Righe_Materiali_Crea",
            parameters,
            cancellationToken);
    }

    public async Task EliminaMaterialeAsync(
        int idRigaMatPrev,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Preventivi_Righe_Materiali_Elimina",
            [new SqlParameter("@IdRigaMatPrev", idRigaMatPrev)],
            cancellationToken);
    }

    public async Task<IReadOnlyList<PreventivoRigaLavorazioneItem>> GetLavorazioniAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<PreventivoRigaLavorazioneItem>(
            "dbo.Preventivi_Righe_Lavorazioni_Elenco",
            [new SqlParameter("@IdRigaPreventivo", idRigaPreventivo)],
            cancellationToken);
    }

    public async Task<PreventivoRigaLavorazioneItem?> GetLavorazioneAsync(
        int idRigaLavPrev,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<PreventivoRigaLavorazioneItem>(
            "dbo.Preventivi_Righe_Lavorazioni_Dettaglio",
            [new SqlParameter("@IdRigaLavPrev", idRigaLavPrev)],
            cancellationToken);
    }

    public async Task<int> CreaLavorazioneAsync(
        PreventivoRigaLavorazioneCreateModel lavorazione,
        CancellationToken cancellationToken = default)
    {
        var parameters = new[]
        {
            new SqlParameter("@IdRigaPreventivo", lavorazione.IdRigaPreventivo),
            NullableInt("@IdNodoDistinta", lavorazione.IdNodoDistinta),
            NullableInt("@IdLavorazione", lavorazione.IdLavorazione),
            Text("@DescrizioneLavorazione", lavorazione.DescrizioneLavorazione, 300),
            NullableInt("@Sequenza", lavorazione.Sequenza),
            Decimal("@TempoSetupMin", lavorazione.TempoSetupMin, 18, 2),
            Decimal("@TempoPezzoMin", lavorazione.TempoPezzoMin, 18, 4),
            Decimal("@Quantita", lavorazione.Quantita, 18, 4),
            Decimal("@CostoOrario", lavorazione.CostoOrario, 18, 4),
            Decimal("@CostoFisso", lavorazione.CostoFisso, 18, 4),
            new SqlParameter("@DaAcquistareEsterno", SqlDbType.Bit) { Value = lavorazione.DaAcquistareEsterno },
            NullableInt("@IdFornitoreSuggerito", lavorazione.IdFornitoreSuggerito)
        };

        return await _db.ExecuteScalarAsync<int>(
            "dbo.Preventivi_Righe_Lavorazioni_Crea",
            parameters,
            cancellationToken);
    }

    public async Task EliminaLavorazioneAsync(
        int idRigaLavPrev,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Preventivi_Righe_Lavorazioni_Elimina",
            [new SqlParameter("@IdRigaLavPrev", idRigaLavPrev)],
            cancellationToken);
    }

    private static SqlParameter Text(
        string name,
        string value,
        int length)
    {
        return new SqlParameter(name, SqlDbType.NVarChar, length)
        {
            Value = value.Trim()
        };
    }

    private static SqlParameter NullableShortText(
        string name,
        string? value,
        int length)
    {
        return new SqlParameter(name, SqlDbType.NVarChar, length)
        {
            Value = string.IsNullOrWhiteSpace(value)
                ? DBNull.Value
                : value.Trim()
        };
    }

    private static SqlParameter NullableText(
        string name,
        string? value)
    {
        return new SqlParameter(name, SqlDbType.NVarChar)
        {
            Value = string.IsNullOrWhiteSpace(value)
                ? DBNull.Value
                : value.Trim()
        };
    }

    private static SqlParameter NullableInt(
        string name,
        int? value)
    {
        return new SqlParameter(name, SqlDbType.Int)
        {
            Value = value.HasValue ? value.Value : DBNull.Value
        };
    }

    private static SqlParameter Decimal(
        string name,
        decimal value,
        byte precision,
        byte scale)
    {
        return new SqlParameter(name, SqlDbType.Decimal)
        {
            Precision = precision,
            Scale = scale,
            Value = value
        };
    }

    private static SqlParameter NullableDecimal(
        string name,
        decimal? value,
        byte precision,
        byte scale)
    {
        return new SqlParameter(name, SqlDbType.Decimal)
        {
            Precision = precision,
            Scale = scale,
            Value = value.HasValue ? value.Value : DBNull.Value
        };
    }
}
