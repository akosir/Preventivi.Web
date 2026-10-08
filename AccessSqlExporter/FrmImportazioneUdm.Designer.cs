namespace AccessSqlExporter
{
    partial class FrmImportazioneUdm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
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
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            txtUdm = new TextBox();
            lblUdm = new Label();
            lblCodicePallet = new Label();
            lblDataDa = new Label();
            lblDataA = new Label();
            txtCodicePallet = new TextBox();
            dtpDataDa = new DateTimePicker();
            dtpDataA = new DateTimePicker();
            btnCerca = new Button();
            SuspendLayout();
            // 
            // txtUdm
            // 
            txtUdm.Location = new Point(283, 39);
            txtUdm.Name = "txtUdm";
            txtUdm.Size = new Size(100, 23);
            txtUdm.TabIndex = 0;
            // 
            // lblUdm
            // 
            lblUdm.AutoSize = true;
            lblUdm.Location = new Point(184, 42);
            lblUdm.Name = "lblUdm";
            lblUdm.Size = new Size(34, 15);
            lblUdm.TabIndex = 1;
            lblUdm.Text = "UDM";
            // 
            // lblCodicePallet
            // 
            lblCodicePallet.AutoSize = true;
            lblCodicePallet.Location = new Point(184, 71);
            lblCodicePallet.Name = "lblCodicePallet";
            lblCodicePallet.Size = new Size(76, 15);
            lblCodicePallet.TabIndex = 2;
            lblCodicePallet.Text = "Codice Pallet";
            // 
            // lblDataDa
            // 
            lblDataDa.AutoSize = true;
            lblDataDa.Location = new Point(184, 97);
            lblDataDa.Name = "lblDataDa";
            lblDataDa.Size = new Size(47, 15);
            lblDataDa.TabIndex = 3;
            lblDataDa.Text = "Data da";
            // 
            // lblDataA
            // 
            lblDataA.AutoSize = true;
            lblDataA.Location = new Point(184, 126);
            lblDataA.Name = "lblDataA";
            lblDataA.Size = new Size(40, 15);
            lblDataA.TabIndex = 4;
            lblDataA.Text = "Data a";
            // 
            // txtCodicePallet
            // 
            txtCodicePallet.Location = new Point(283, 68);
            txtCodicePallet.Name = "txtCodicePallet";
            txtCodicePallet.Size = new Size(100, 23);
            txtCodicePallet.TabIndex = 5;
            // 
            // dtpDataDa
            // 
            dtpDataDa.Checked = false;
            dtpDataDa.Format = DateTimePickerFormat.Short;
            dtpDataDa.Location = new Point(283, 97);
            dtpDataDa.Name = "dtpDataDa";
            dtpDataDa.ShowCheckBox = true;
            dtpDataDa.Size = new Size(125, 23);
            dtpDataDa.TabIndex = 6;
            // 
            // dtpDataA
            // 
            dtpDataA.Checked = false;
            dtpDataA.Format = DateTimePickerFormat.Short;
            dtpDataA.Location = new Point(283, 126);
            dtpDataA.Name = "dtpDataA";
            dtpDataA.ShowCheckBox = true;
            dtpDataA.Size = new Size(125, 23);
            dtpDataA.TabIndex = 7;
            // 
            // btnCerca
            // 
            btnCerca.Location = new Point(425, 128);
            btnCerca.Name = "btnCerca";
            btnCerca.Size = new Size(75, 23);
            btnCerca.TabIndex = 8;
            btnCerca.Text = "Cerca";
            btnCerca.UseVisualStyleBackColor = true;
            // 
            // FrmImportazioneUdm
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(1184, 661);
            Controls.Add(btnCerca);
            Controls.Add(dtpDataA);
            Controls.Add(dtpDataDa);
            Controls.Add(txtCodicePallet);
            Controls.Add(lblDataA);
            Controls.Add(lblDataDa);
            Controls.Add(lblCodicePallet);
            Controls.Add(lblUdm);
            Controls.Add(txtUdm);
            MinimumSize = new Size(1000, 600);
            Name = "FrmImportazioneUdm";
            StartPosition = FormStartPosition.CenterScreen;
            Text = "Importazione UDM";
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private TextBox txtUdm;
        private Label lblUdm;
        private Label lblCodicePallet;
        private Label lblDataDa;
        private Label lblDataA;
        private TextBox txtCodicePallet;
        private DateTimePicker dtpDataDa;
        private DateTimePicker dtpDataA;
        private Button btnCerca;
    }
}