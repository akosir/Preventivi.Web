namespace AccessSqlExporter
{
    partial class Form1
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            btnTestSqlSorgente = new Button();
            btnElencoTabelle = new Button();
            lstTabelle = new ListBox();
            SuspendLayout();
            // 
            // btnTestSqlSorgente
            // 
            btnTestSqlSorgente.Location = new Point(590, 12);
            btnTestSqlSorgente.Name = "btnTestSqlSorgente";
            btnTestSqlSorgente.Size = new Size(198, 23);
            btnTestSqlSorgente.TabIndex = 0;
            btnTestSqlSorgente.Text = " Test SQL sorgente";
            btnTestSqlSorgente.UseVisualStyleBackColor = true;
            btnTestSqlSorgente.Click += btnTestSqlSorgente_Click;
            // 
            // btnElencoTabelle
            // 
            btnElencoTabelle.Location = new Point(12, 63);
            btnElencoTabelle.Name = "btnElencoTabelle";
            btnElencoTabelle.Size = new Size(167, 23);
            btnElencoTabelle.TabIndex = 1;
            btnElencoTabelle.Text = "Elenco tabelle Access";
            btnElencoTabelle.UseVisualStyleBackColor = true;
            btnElencoTabelle.Click += btnElencoTabelle_Click;
            // 
            // lstTabelle
            // 
            lstTabelle.FormattingEnabled = true;
            lstTabelle.Location = new Point(12, 104);
            lstTabelle.Name = "lstTabelle";
            lstTabelle.Size = new Size(776, 334);
            lstTabelle.TabIndex = 2;
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(800, 450);
            Controls.Add(lstTabelle);
            Controls.Add(btnElencoTabelle);
            Controls.Add(btnTestSqlSorgente);
            Name = "Form1";
            Text = "Form1";
            ResumeLayout(false);
        }

        #endregion

        private Button btnTestSqlSorgente;
        private Button btnElencoTabelle;
        private ListBox lstTabelle;
    }
}
