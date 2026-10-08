using System.Data;
using System.Data.OleDb;
using Microsoft.Data.SqlClient;

namespace AccessSqlExporter
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void btnTestSqlSorgente_Click(object sender, EventArgs e)
        {
            string stringaConnessione =
                "Server=192.168.1.13;" +
                "Database=gestione;" +
                "User Id=sa;" +
                "Password=Rx23cp01;" +
                "TrustServerCertificate=True;";

            try
            {
                using SqlConnection connessione =
                    new SqlConnection(stringaConnessione);

                connessione.Open();

                MessageBox.Show(
                    "Connessione al database SQL Server 'gestione' riuscita.",
                    "Test SQL sorgente",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Errore durante la connessione a SQL Server:\n\n{ex.Message}",
                    "Errore SQL Server",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        private void btnElencoTabelle_Click(object sender, EventArgs e)
        {
            string percorsoAccess = @"Z:\Magazzino 6822\magazzino.accdb";

            string stringaConnessione =
                $@"Provider=Microsoft.ACE.OLEDB.12.0;Data Source={percorsoAccess};Persist Security Info=False;";

            try
            {
                lstTabelle.Items.Clear();

                using OleDbConnection connessione =
                    new OleDbConnection(stringaConnessione);

                connessione.Open();

                DataTable schemaTabelle =
                    connessione.GetSchema("Tables");

                foreach (DataRow riga in schemaTabelle.Rows)
                {
                    string? nomeTabella = riga["TABLE_NAME"]?.ToString();
                    string? tipoTabella = riga["TABLE_TYPE"]?.ToString();

                    if (tipoTabella == "TABLE" && !string.IsNullOrWhiteSpace(nomeTabella))
                    {
                        lstTabelle.Items.Add(nomeTabella);
                    }
                }

                MessageBox.Show(
                    $"Trovate {lstTabelle.Items.Count} tabelle.",
                    "Tabelle Access",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Errore durante la lettura delle tabelle:\n\n{ex.Message}",
                    "Errore Access",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }
    }
}
