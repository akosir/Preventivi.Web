using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Data.Comune;

namespace Preventivi.Web.Pages;

public class TestDbModel : PageModel
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly ILogger<TestDbModel> _logger;

    public bool ConnessioneOk { get; private set; }

    public string Server { get; private set; } = string.Empty;

    public string Database { get; private set; } = string.Empty;

    public string Errore { get; private set; } = string.Empty;

    public TestDbModel(
        SqlConnectionFactory connectionFactory,
        ILogger<TestDbModel> logger)
    {
        _connectionFactory = connectionFactory;
        _logger = logger;
    }

    public async Task OnGetAsync()
    {
        try
        {
            await using var connection =
                _connectionFactory.CreateConnection();

            await connection.OpenAsync();

            ConnessioneOk = true;
            Server = connection.DataSource;
            Database = connection.Database;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Verifica della connessione al database non riuscita.");
            ConnessioneOk = false;
            Errore = "Connessione al database non disponibile.";
        }
    }
}
