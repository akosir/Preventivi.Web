/*
    TEC-002 - Tabelle, chiavi, vincoli e indici (senza chiavi esterne)
    Origine: schema installato di PreventiviProduzione
    Contenuto: solo DDL, senza dati, utenti, ruoli, permessi o credenziali
*/
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AlertOperativi](
	[IdAlert] [int] IDENTITY(1,1) NOT NULL,
	[TipoAlert] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Origine] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IdOrigine] [int] NULL,
	[Titolo] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Priorita] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Stato] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[DataAlert] [date] NOT NULL,
	[DataScadenza] [date] NULL,
	[UtenteAssegnato] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_AlertOperativi] PRIMARY KEY CLUSTERED
(
	[IdAlert] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[AlertOperativi] ADD  DEFAULT ('Media') FOR [Priorita]
GO

ALTER TABLE [dbo].[AlertOperativi] ADD  DEFAULT ('Aperto') FOR [Stato]
GO

ALTER TABLE [dbo].[AlertOperativi] ADD  DEFAULT (CONVERT([date],getdate())) FOR [DataAlert]
GO

ALTER TABLE [dbo].[AlertOperativi]  WITH CHECK ADD  CONSTRAINT [CK_AlertOperativi_Priorita] CHECK  (([Priorita]='Urgente' OR [Priorita]='Alta' OR [Priorita]='Media' OR [Priorita]='Bassa'))
GO

ALTER TABLE [dbo].[AlertOperativi] CHECK CONSTRAINT [CK_AlertOperativi_Priorita]
GO

ALTER TABLE [dbo].[AlertOperativi]  WITH CHECK ADD  CONSTRAINT [CK_AlertOperativi_Stato] CHECK  (([Stato]='Annullato' OR [Stato]='Chiuso' OR [Stato]='In lavorazione' OR [Stato]='Aperto'))
GO

ALTER TABLE [dbo].[AlertOperativi] CHECK CONSTRAINT [CK_AlertOperativi_Stato]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Allegati](
	[IdAllegato] [int] IDENTITY(1,1) NOT NULL,
	[Entita] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[IdEntita] [int] NOT NULL,
	[TipoAllegato] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Descrizione] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[NomeFileOriginale] [nvarchar](255) COLLATE Latin1_General_CI_AS NOT NULL,
	[PercorsoFile] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Estensione] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[DataAllegato] [date] NOT NULL,
	[UtenteInserimento] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[NomeFileArchiviato] [nvarchar](255) COLLATE Latin1_General_CI_AS NULL,
	[DimensioneFile] [bigint] NULL,
 CONSTRAINT [PK_Allegati] PRIMARY KEY CLUSTERED
(
	[IdAllegato] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_Allegati_Entita_IdEntita] ON [dbo].[Allegati]
(
	[Entita] ASC,
	[IdEntita] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Allegati] ADD  DEFAULT (CONVERT([date],getdate())) FOR [DataAllegato]
GO

ALTER TABLE [dbo].[Allegati] ADD  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Articoli](
	[IdArticolo] [int] IDENTITY(1,1) NOT NULL,
	[CodiceArticolo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[Versione] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IdCliente] [int] NULL,
	[Attivo] [bit] NOT NULL,
	[NoteTecniche] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
 CONSTRAINT [PK_Articoli] PRIMARY KEY CLUSTERED
(
	[IdArticolo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Articoli_CodiceArticolo] UNIQUE NONCLUSTERED
(
	[CodiceArticolo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[Articoli] ADD  CONSTRAINT [DF_Articoli_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

ALTER TABLE [dbo].[Articoli] ADD  CONSTRAINT [DF_Articoli_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Campionature](
	[IdCampionatura] [int] IDENTITY(1,1) NOT NULL,
	[NumeroCampionatura] [int] NOT NULL,
	[Anno] [int] NOT NULL,
	[DataCampionatura] [date] NOT NULL,
	[IdRichiestaCliente] [int] NOT NULL,
	[IdPreventivo] [int] NULL,
	[IdVariantePreventivo] [int] NULL,
	[Oggetto] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[DescrizioneCampione] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Stato] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Priorita] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[DataRichiestaCampione] [date] NULL,
	[DataPrevistaConsegna] [date] NULL,
	[DataConsegnaCampione] [date] NULL,
	[DataChiusura] [date] NULL,
	[Esito] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
 CONSTRAINT [PK_Campionature] PRIMARY KEY CLUSTERED
(
	[IdCampionatura] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Campionature_NumeroAnno] UNIQUE NONCLUSTERED
(
	[NumeroCampionatura] ASC,
	[Anno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[Campionature] ADD  DEFAULT ('Aperta') FOR [Stato]
GO

ALTER TABLE [dbo].[Campionature] ADD  DEFAULT ('Media') FOR [Priorita]
GO

ALTER TABLE [dbo].[Campionature] ADD  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

ALTER TABLE [dbo].[Campionature]  WITH CHECK ADD  CONSTRAINT [CK_Campionature_Esito] CHECK  (([Esito] IS NULL OR ([Esito]='Da rifare' OR [Esito]='Negativo' OR [Esito]='Positivo con modifiche' OR [Esito]='Positivo')))
GO

ALTER TABLE [dbo].[Campionature] CHECK CONSTRAINT [CK_Campionature_Esito]
GO

ALTER TABLE [dbo].[Campionature]  WITH CHECK ADD  CONSTRAINT [CK_Campionature_Priorita] CHECK  (([Priorita]='Urgente' OR [Priorita]='Alta' OR [Priorita]='Media' OR [Priorita]='Bassa'))
GO

ALTER TABLE [dbo].[Campionature] CHECK CONSTRAINT [CK_Campionature_Priorita]
GO

ALTER TABLE [dbo].[Campionature]  WITH CHECK ADD  CONSTRAINT [CK_Campionature_Stato] CHECK  (([Stato]='Annullata' OR [Stato]='Chiusa' OR [Stato]='Respinta' OR [Stato]='Approvata' OR [Stato]='Inviata al Cliente' OR [Stato]='In Verifica' OR [Stato]='In Lavorazione' OR [Stato]='Aperta'))
GO

ALTER TABLE [dbo].[Campionature] CHECK CONSTRAINT [CK_Campionature_Stato]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CampionatureAdeguamentiPreventivo](
	[IdAdeguamento] [int] IDENTITY(1,1) NOT NULL,
	[IdCampionatura] [int] NOT NULL,
	[IdRilievoCampionatura] [int] NULL,
	[IdPreventivo] [int] NULL,
	[IdVariantePreventivo] [int] NULL,
	[DescrizioneAdeguamento] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[ImpattoCostoStimato] [decimal](18, 2) NOT NULL,
	[ImpattoVenditaStimato] [decimal](18, 2) NOT NULL,
	[Applicato] [bit] NOT NULL,
	[DataApplicazione] [date] NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_CampionatureAdeguamentiPreventivo] PRIMARY KEY CLUSTERED
(
	[IdAdeguamento] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo] ADD  DEFAULT ((0)) FOR [ImpattoCostoStimato]
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo] ADD  DEFAULT ((0)) FOR [ImpattoVenditaStimato]
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo] ADD  DEFAULT ((0)) FOR [Applicato]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CampionatureRilievi](
	[IdRilievoCampionatura] [int] IDENTITY(1,1) NOT NULL,
	[IdCampionatura] [int] NOT NULL,
	[RigaNr] [int] NOT NULL,
	[IdTipoProblematica] [int] NOT NULL,
	[IdProblematicaStandard] [int] NULL,
	[DescrizioneProblema] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[Gravita] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[CausaPresunta] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[SoluzioneProposta] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[RichiedeAdeguamentoPreventivo] [bit] NOT NULL,
	[RichiedeNuovoCampione] [bit] NOT NULL,
	[Stato] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[EsitoVerifica] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[NoteCliente] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[NoteInterne] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[DataRilevazione] [date] NOT NULL,
	[DataChiusura] [date] NULL,
 CONSTRAINT [PK_CampionatureRilievi] PRIMARY KEY CLUSTERED
(
	[IdRilievoCampionatura] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[CampionatureRilievi] ADD  DEFAULT ('Media') FOR [Gravita]
GO

ALTER TABLE [dbo].[CampionatureRilievi] ADD  DEFAULT ((0)) FOR [RichiedeAdeguamentoPreventivo]
GO

ALTER TABLE [dbo].[CampionatureRilievi] ADD  DEFAULT ((0)) FOR [RichiedeNuovoCampione]
GO

ALTER TABLE [dbo].[CampionatureRilievi] ADD  DEFAULT ('Aperto') FOR [Stato]
GO

ALTER TABLE [dbo].[CampionatureRilievi] ADD  DEFAULT (CONVERT([date],getdate())) FOR [DataRilevazione]
GO

ALTER TABLE [dbo].[CampionatureRilievi]  WITH CHECK ADD  CONSTRAINT [CK_CampionatureRilievi_Gravita] CHECK  (([Gravita]='Critica' OR [Gravita]='Alta' OR [Gravita]='Media' OR [Gravita]='Bassa'))
GO

ALTER TABLE [dbo].[CampionatureRilievi] CHECK CONSTRAINT [CK_CampionatureRilievi_Gravita]
GO

ALTER TABLE [dbo].[CampionatureRilievi]  WITH CHECK ADD  CONSTRAINT [CK_CampionatureRilievi_Stato] CHECK  (([Stato]='Chiuso' OR [Stato]='Respinto' OR [Stato]='Risolto' OR [Stato]='Soluzione Proposta' OR [Stato]='In Analisi' OR [Stato]='Aperto'))
GO

ALTER TABLE [dbo].[CampionatureRilievi] CHECK CONSTRAINT [CK_CampionatureRilievi_Stato]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Clienti](
	[IdCliente] [int] IDENTITY(1,1) NOT NULL,
	[CodiceCliente] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[RagioneSociale] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[PartitaIVA] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[CodiceFiscale] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Indirizzo] [nvarchar](150) COLLATE Latin1_General_CI_AS NULL,
	[CAP] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[Citta] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Provincia] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[Telefono] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Email] [nvarchar](150) COLLATE Latin1_General_CI_AS NULL,
	[Attivo] [bit] NOT NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
 CONSTRAINT [PK_Clienti] PRIMARY KEY CLUSTERED
(
	[IdCliente] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Clienti_CodiceCliente] UNIQUE NONCLUSTERED
(
	[CodiceCliente] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_Clienti_RagioneSociale] ON [dbo].[Clienti]
(
	[RagioneSociale] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Clienti] ADD  CONSTRAINT [DF_Clienti_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

ALTER TABLE [dbo].[Clienti] ADD  CONSTRAINT [DF_Clienti_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DistintaBaseNodi](
	[IdNodoDistinta] [int] IDENTITY(1,1) NOT NULL,
	[IdArticolo] [int] NOT NULL,
	[IdNodoPadre] [int] NULL,
	[IdTipoNodo] [int] NOT NULL,
	[CodiceNodo] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[DescrizioneNodo] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[QuantitaBase] [decimal](18, 4) NOT NULL,
	[Livello] [int] NOT NULL,
	[OrdineVisualizzazione] [int] NOT NULL,
	[Attivo] [bit] NOT NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_DistintaBaseNodi] PRIMARY KEY CLUSTERED
(
	[IdNodoDistinta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_DistintaBaseNodi_IdArticolo] ON [dbo].[DistintaBaseNodi]
(
	[IdArticolo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_DistintaBaseNodi_IdNodoPadre] ON [dbo].[DistintaBaseNodi]
(
	[IdNodoPadre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[DistintaBaseNodi] ADD  CONSTRAINT [DF_DistintaBaseNodi_QuantitaBase]  DEFAULT ((1)) FOR [QuantitaBase]
GO

ALTER TABLE [dbo].[DistintaBaseNodi] ADD  CONSTRAINT [DF_DistintaBaseNodi_Livello]  DEFAULT ((0)) FOR [Livello]
GO

ALTER TABLE [dbo].[DistintaBaseNodi] ADD  CONSTRAINT [DF_DistintaBaseNodi_Ordine]  DEFAULT ((0)) FOR [OrdineVisualizzazione]
GO

ALTER TABLE [dbo].[DistintaBaseNodi] ADD  CONSTRAINT [DF_DistintaBaseNodi_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DistintaLavorazioni](
	[IdDistintaLavorazione] [int] IDENTITY(1,1) NOT NULL,
	[IdNodoDistinta] [int] NOT NULL,
	[IdLavorazione] [int] NOT NULL,
	[Sequenza] [int] NOT NULL,
	[TempoSetupMin] [decimal](18, 2) NOT NULL,
	[TempoPezzoMin] [decimal](18, 4) NOT NULL,
	[CostoOrario] [decimal](18, 4) NOT NULL,
	[CostoFisso] [decimal](18, 4) NOT NULL,
	[IdModelloCiclo] [int] NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_DistintaLavorazioni] PRIMARY KEY CLUSTERED
(
	[IdDistintaLavorazione] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_DistintaLavorazioni_IdNodoDistinta] ON [dbo].[DistintaLavorazioni]
(
	[IdNodoDistinta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[DistintaLavorazioni] ADD  CONSTRAINT [DF_DistintaLavorazioni_Sequenza]  DEFAULT ((1)) FOR [Sequenza]
GO

ALTER TABLE [dbo].[DistintaLavorazioni] ADD  CONSTRAINT [DF_DistintaLavorazioni_TempoSetup]  DEFAULT ((0)) FOR [TempoSetupMin]
GO

ALTER TABLE [dbo].[DistintaLavorazioni] ADD  CONSTRAINT [DF_DistintaLavorazioni_TempoPezzo]  DEFAULT ((0)) FOR [TempoPezzoMin]
GO

ALTER TABLE [dbo].[DistintaLavorazioni] ADD  CONSTRAINT [DF_DistintaLavorazioni_CostoOrario]  DEFAULT ((0)) FOR [CostoOrario]
GO

ALTER TABLE [dbo].[DistintaLavorazioni] ADD  CONSTRAINT [DF_DistintaLavorazioni_CostoFisso]  DEFAULT ((0)) FOR [CostoFisso]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DistintaMateriali](
	[IdDistintaMateriale] [int] IDENTITY(1,1) NOT NULL,
	[IdNodoDistinta] [int] NOT NULL,
	[IdMateriale] [int] NOT NULL,
	[Quantita] [decimal](18, 4) NOT NULL,
	[CoeffScartoPerc] [decimal](9, 2) NOT NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_DistintaMateriali] PRIMARY KEY CLUSTERED
(
	[IdDistintaMateriale] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_DistintaMateriali_IdNodoDistinta] ON [dbo].[DistintaMateriali]
(
	[IdNodoDistinta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[DistintaMateriali] ADD  CONSTRAINT [DF_DistintaMateriali_Quantita]  DEFAULT ((0)) FOR [Quantita]
GO

ALTER TABLE [dbo].[DistintaMateriali] ADD  CONSTRAINT [DF_DistintaMateriali_Scarto]  DEFAULT ((0)) FOR [CoeffScartoPerc]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Fornitori](
	[IdFornitore] [int] IDENTITY(1,1) NOT NULL,
	[CodiceFornitore] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[RagioneSociale] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[PartitaIVA] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[CodiceFiscale] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Indirizzo] [nvarchar](150) COLLATE Latin1_General_CI_AS NULL,
	[CAP] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[Citta] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Provincia] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[Telefono] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Email] [nvarchar](150) COLLATE Latin1_General_CI_AS NULL,
	[Referente] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Attivo] [bit] NOT NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
 CONSTRAINT [PK_Fornitori] PRIMARY KEY CLUSTERED
(
	[IdFornitore] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Fornitori_CodiceFornitore] UNIQUE NONCLUSTERED
(
	[CodiceFornitore] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_Fornitori_RagioneSociale] ON [dbo].[Fornitori]
(
	[RagioneSociale] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Fornitori] ADD  CONSTRAINT [DF_Fornitori_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

ALTER TABLE [dbo].[Fornitori] ADD  CONSTRAINT [DF_Fornitori_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FornitoriLavorazioni](
	[IdFornitoreLavorazione] [int] IDENTITY(1,1) NOT NULL,
	[IdFornitore] [int] NOT NULL,
	[IdLavorazione] [int] NOT NULL,
	[PrezzoUnitario] [decimal](18, 4) NOT NULL,
	[PrezzoOrario] [decimal](18, 4) NOT NULL,
	[LottoMinimo] [decimal](18, 4) NOT NULL,
	[TempoConsegnaGiorni] [int] NOT NULL,
	[FornitorePredefinito] [bit] NOT NULL,
	[Attivo] [bit] NOT NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_FornitoriLavorazioni] PRIMARY KEY CLUSTERED
(
	[IdFornitoreLavorazione] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_FornitoriLavorazioni_IdFornitore] ON [dbo].[FornitoriLavorazioni]
(
	[IdFornitore] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_FornitoriLavorazioni_IdLavorazione] ON [dbo].[FornitoriLavorazioni]
(
	[IdLavorazione] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[FornitoriLavorazioni] ADD  CONSTRAINT [DF_FornitoriLavorazioni_PrezzoUnit]  DEFAULT ((0)) FOR [PrezzoUnitario]
GO

ALTER TABLE [dbo].[FornitoriLavorazioni] ADD  CONSTRAINT [DF_FornitoriLavorazioni_PrezzoOra]  DEFAULT ((0)) FOR [PrezzoOrario]
GO

ALTER TABLE [dbo].[FornitoriLavorazioni] ADD  CONSTRAINT [DF_FornitoriLavorazioni_LottoMin]  DEFAULT ((0)) FOR [LottoMinimo]
GO

ALTER TABLE [dbo].[FornitoriLavorazioni] ADD  CONSTRAINT [DF_FornitoriLavorazioni_TempoConsegna]  DEFAULT ((0)) FOR [TempoConsegnaGiorni]
GO

ALTER TABLE [dbo].[FornitoriLavorazioni] ADD  CONSTRAINT [DF_FornitoriLavorazioni_Predef]  DEFAULT ((0)) FOR [FornitorePredefinito]
GO

ALTER TABLE [dbo].[FornitoriLavorazioni] ADD  CONSTRAINT [DF_FornitoriLavorazioni_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FornitoriMateriali](
	[IdFornitoreMateriale] [int] IDENTITY(1,1) NOT NULL,
	[IdFornitore] [int] NOT NULL,
	[IdMateriale] [int] NOT NULL,
	[CodiceMaterialeFornitore] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[DescrizioneFornitore] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PrezzoUnitario] [decimal](18, 4) NOT NULL,
	[LottoMinimo] [decimal](18, 4) NOT NULL,
	[MultiploOrdine] [decimal](18, 4) NOT NULL,
	[TempoConsegnaGiorni] [int] NOT NULL,
	[FornitorePredefinito] [bit] NOT NULL,
	[Attivo] [bit] NOT NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_FornitoriMateriali] PRIMARY KEY CLUSTERED
(
	[IdFornitoreMateriale] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_FornitoriMateriali_IdFornitore] ON [dbo].[FornitoriMateriali]
(
	[IdFornitore] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_FornitoriMateriali_IdMateriale] ON [dbo].[FornitoriMateriali]
(
	[IdMateriale] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[FornitoriMateriali] ADD  CONSTRAINT [DF_FornitoriMateriali_Prezzo]  DEFAULT ((0)) FOR [PrezzoUnitario]
GO

ALTER TABLE [dbo].[FornitoriMateriali] ADD  CONSTRAINT [DF_FornitoriMateriali_LottoMin]  DEFAULT ((0)) FOR [LottoMinimo]
GO

ALTER TABLE [dbo].[FornitoriMateriali] ADD  CONSTRAINT [DF_FornitoriMateriali_Multiplo]  DEFAULT ((0)) FOR [MultiploOrdine]
GO

ALTER TABLE [dbo].[FornitoriMateriali] ADD  CONSTRAINT [DF_FornitoriMateriali_TempoConsegna]  DEFAULT ((0)) FOR [TempoConsegnaGiorni]
GO

ALTER TABLE [dbo].[FornitoriMateriali] ADD  CONSTRAINT [DF_FornitoriMateriali_Predef]  DEFAULT ((0)) FOR [FornitorePredefinito]
GO

ALTER TABLE [dbo].[FornitoriMateriali] ADD  CONSTRAINT [DF_FornitoriMateriali_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ImportModelliCiclo_Righe](
	[IdImport] [int] IDENTITY(1,1) NOT NULL,
	[BatchId] [uniqueidentifier] NOT NULL,
	[CodiceModelloCiclo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[RigaNr] [int] NOT NULL,
	[CodiceLavorazione] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Sequenza] [int] NOT NULL,
	[TempoSetupMin] [decimal](18, 2) NULL,
	[TempoPezzoMin] [decimal](18, 4) NULL,
	[CostoOrario] [decimal](18, 4) NULL,
	[CostoFisso] [decimal](18, 4) NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[EsitoImport] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[MessaggioImport] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[DataImport] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_ImportModelliCiclo_Righe] PRIMARY KEY CLUSTERED
(
	[IdImport] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ImportModelliCiclo_Righe] ADD  CONSTRAINT [DF_ImportModelliCiclo_Righe_Data]  DEFAULT (sysdatetime()) FOR [DataImport]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ImportModelliCiclo_Testata](
	[IdImport] [int] IDENTITY(1,1) NOT NULL,
	[BatchId] [uniqueidentifier] NOT NULL,
	[CodiceModelloCiclo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[EsitoImport] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[MessaggioImport] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[DataImport] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_ImportModelliCiclo_Testata] PRIMARY KEY CLUSTERED
(
	[IdImport] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ImportModelliCiclo_Testata] ADD  CONSTRAINT [DF_ImportModCicloTest_Batch]  DEFAULT (newid()) FOR [BatchId]
GO

ALTER TABLE [dbo].[ImportModelliCiclo_Testata] ADD  CONSTRAINT [DF_ImportModelliCiclo_Testata_Data]  DEFAULT (sysdatetime()) FOR [DataImport]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ImportModelliPreventivo_Righe](
	[IdImport] [int] IDENTITY(1,1) NOT NULL,
	[BatchId] [uniqueidentifier] NOT NULL,
	[CodiceModelloPreventivo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[RigaNr] [int] NOT NULL,
	[CodiceArticolo] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CodiceModelloCiclo] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[DescrizioneVoce] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Quantita] [decimal](18, 4) NULL,
	[PrezzoUnitarioVendita] [decimal](18, 4) NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[EsitoImport] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[MessaggioImport] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[DataImport] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_ImportModelliPreventivo_Righe] PRIMARY KEY CLUSTERED
(
	[IdImport] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ImportModelliPreventivo_Righe] ADD  CONSTRAINT [DF_ImportModelliPreventivo_Righe_Data]  DEFAULT (sysdatetime()) FOR [DataImport]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ImportModelliPreventivo_Testata](
	[IdImport] [int] IDENTITY(1,1) NOT NULL,
	[BatchId] [uniqueidentifier] NOT NULL,
	[CodiceModelloPreventivo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[CodiceCliente] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[Oggetto] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[EsitoImport] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[MessaggioImport] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[DataImport] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_ImportModelliPreventivo_Testata] PRIMARY KEY CLUSTERED
(
	[IdImport] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ImportModelliPreventivo_Testata] ADD  CONSTRAINT [DF_ImportModPrevTest_Batch]  DEFAULT (newid()) FOR [BatchId]
GO

ALTER TABLE [dbo].[ImportModelliPreventivo_Testata] ADD  CONSTRAINT [DF_ImportModPrevTest_Data]  DEFAULT (sysdatetime()) FOR [DataImport]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Lavorazioni](
	[IdLavorazione] [int] IDENTITY(1,1) NOT NULL,
	[CodiceLavorazione] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[InternaEsterna] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[CostoOrarioStandard] [decimal](18, 4) NOT NULL,
	[TempoSetupMinDefault] [decimal](18, 2) NOT NULL,
	[TempoPezzoMinDefault] [decimal](18, 4) NOT NULL,
	[AcquistabileEsterna] [bit] NOT NULL,
	[IdFornitorePredefinito] [int] NULL,
	[Attiva] [bit] NOT NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_Lavorazioni] PRIMARY KEY CLUSTERED
(
	[IdLavorazione] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Lavorazioni_CodiceLavorazione] UNIQUE NONCLUSTERED
(
	[CodiceLavorazione] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Lavorazioni] ADD  CONSTRAINT [DF_Lavorazioni_CostoOrario]  DEFAULT ((0)) FOR [CostoOrarioStandard]
GO

ALTER TABLE [dbo].[Lavorazioni] ADD  CONSTRAINT [DF_Lavorazioni_TempoSetup]  DEFAULT ((0)) FOR [TempoSetupMinDefault]
GO

ALTER TABLE [dbo].[Lavorazioni] ADD  CONSTRAINT [DF_Lavorazioni_TempoPezzo]  DEFAULT ((0)) FOR [TempoPezzoMinDefault]
GO

ALTER TABLE [dbo].[Lavorazioni] ADD  CONSTRAINT [DF_Lavorazioni_AcquistabileEsterna]  DEFAULT ((0)) FOR [AcquistabileEsterna]
GO

ALTER TABLE [dbo].[Lavorazioni] ADD  CONSTRAINT [DF_Lavorazioni_Attiva]  DEFAULT ((1)) FOR [Attiva]
GO

ALTER TABLE [dbo].[Lavorazioni]  WITH CHECK ADD  CONSTRAINT [CK_Lavorazioni_InternaEsterna] CHECK  (([InternaEsterna]='Esterna' OR [InternaEsterna]='Interna'))
GO

ALTER TABLE [dbo].[Lavorazioni] CHECK CONSTRAINT [CK_Lavorazioni_InternaEsterna]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Materiali](
	[IdMateriale] [int] IDENTITY(1,1) NOT NULL,
	[CodiceMateriale] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[IdUM] [int] NOT NULL,
	[TipoMateriale] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
	[GestitoAAcquisto] [bit] NOT NULL,
	[IdFornitorePredefinito] [int] NULL,
	[Attivo] [bit] NOT NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
 CONSTRAINT [PK_Materiali] PRIMARY KEY CLUSTERED
(
	[IdMateriale] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Materiali_CodiceMateriale] UNIQUE NONCLUSTERED
(
	[CodiceMateriale] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Materiali] ADD  CONSTRAINT [DF_Materiali_CostoUnitario]  DEFAULT ((0)) FOR [CostoUnitario]
GO

ALTER TABLE [dbo].[Materiali] ADD  CONSTRAINT [DF_Materiali_GestitoAAcquisto]  DEFAULT ((1)) FOR [GestitoAAcquisto]
GO

ALTER TABLE [dbo].[Materiali] ADD  CONSTRAINT [DF_Materiali_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

ALTER TABLE [dbo].[Materiali] ADD  CONSTRAINT [DF_Materiali_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

ALTER TABLE [dbo].[Materiali]  WITH CHECK ADD  CONSTRAINT [CK_Materiali_TipoMateriale] CHECK  (([TipoMateriale]='Semilavorato' OR [TipoMateriale]='Accessorio' OR [TipoMateriale]='MateriaPrima'))
GO

ALTER TABLE [dbo].[Materiali] CHECK CONSTRAINT [CK_Materiali_TipoMateriale]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MenuGruppi](
	[IdGruppoMenu] [int] IDENTITY(1,1) NOT NULL,
	[CodiceGruppo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Ordine] [int] NOT NULL,
	[Attivo] [bit] NOT NULL,
 CONSTRAINT [PK_MenuGruppi] PRIMARY KEY CLUSTERED
(
	[IdGruppoMenu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[MenuGruppi] ADD  DEFAULT ((0)) FOR [Ordine]
GO

ALTER TABLE [dbo].[MenuGruppi] ADD  DEFAULT ((1)) FOR [Attivo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MenuPermessiRuoli](
	[IdPermessoMenu] [int] IDENTITY(1,1) NOT NULL,
	[IdRuolo] [int] NOT NULL,
	[IdVoceMenu] [int] NOT NULL,
	[Consenti] [bit] NOT NULL,
 CONSTRAINT [PK_MenuPermessiRuoli] PRIMARY KEY CLUSTERED
(
	[IdPermessoMenu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_MenuPermessiRuoli] UNIQUE NONCLUSTERED
(
	[IdRuolo] ASC,
	[IdVoceMenu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[MenuPermessiRuoli] ADD  DEFAULT ((1)) FOR [Consenti]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MenuVoci](
	[IdVoceMenu] [int] IDENTITY(1,1) NOT NULL,
	[IdGruppoMenu] [int] NOT NULL,
	[Descrizione] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[NomeMaschera] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[TipoApertura] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Ordine] [int] NOT NULL,
	[Attivo] [bit] NOT NULL,
	[Note] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TipoOggetto] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
 CONSTRAINT [PK_MenuVoci] PRIMARY KEY CLUSTERED
(
	[IdVoceMenu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[MenuVoci] ADD  DEFAULT ('Form') FOR [TipoApertura]
GO

ALTER TABLE [dbo].[MenuVoci] ADD  DEFAULT ((0)) FOR [Ordine]
GO

ALTER TABLE [dbo].[MenuVoci] ADD  DEFAULT ((1)) FOR [Attivo]
GO

ALTER TABLE [dbo].[MenuVoci] ADD  CONSTRAINT [DF_MenuVoci_TipoOggetto]  DEFAULT ('Form') FOR [TipoOggetto]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ModelliCiclo](
	[IdModelloCiclo] [int] IDENTITY(1,1) NOT NULL,
	[CodiceModelloCiclo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attivo] [bit] NOT NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
 CONSTRAINT [PK_ModelliCiclo] PRIMARY KEY CLUSTERED
(
	[IdModelloCiclo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ModelliCiclo_Codice] UNIQUE NONCLUSTERED
(
	[CodiceModelloCiclo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ModelliCiclo] ADD  CONSTRAINT [DF_ModelliCiclo_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

ALTER TABLE [dbo].[ModelliCiclo] ADD  CONSTRAINT [DF_ModelliCiclo_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ModelliCicloRighe](
	[IdRigaModelloCiclo] [int] IDENTITY(1,1) NOT NULL,
	[IdModelloCiclo] [int] NOT NULL,
	[RigaNr] [int] NOT NULL,
	[IdLavorazione] [int] NOT NULL,
	[Sequenza] [int] NOT NULL,
	[TempoSetupMin] [decimal](18, 2) NOT NULL,
	[TempoPezzoMin] [decimal](18, 4) NOT NULL,
	[CostoOrario] [decimal](18, 4) NOT NULL,
	[CostoFisso] [decimal](18, 4) NOT NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_ModelliCicloRighe] PRIMARY KEY CLUSTERED
(
	[IdRigaModelloCiclo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ModelliCicloRighe] UNIQUE NONCLUSTERED
(
	[IdModelloCiclo] ASC,
	[RigaNr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ModelliCicloRighe] ADD  CONSTRAINT [DF_ModelliCicloRighe_TempoSetup]  DEFAULT ((0)) FOR [TempoSetupMin]
GO

ALTER TABLE [dbo].[ModelliCicloRighe] ADD  CONSTRAINT [DF_ModelliCicloRighe_TempoPezzo]  DEFAULT ((0)) FOR [TempoPezzoMin]
GO

ALTER TABLE [dbo].[ModelliCicloRighe] ADD  CONSTRAINT [DF_ModelliCicloRighe_CostoOrario]  DEFAULT ((0)) FOR [CostoOrario]
GO

ALTER TABLE [dbo].[ModelliCicloRighe] ADD  CONSTRAINT [DF_ModelliCicloRighe_CostoFisso]  DEFAULT ((0)) FOR [CostoFisso]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ModelliPreventivo](
	[IdModelloPreventivo] [int] IDENTITY(1,1) NOT NULL,
	[CodiceModelloPreventivo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[IdCliente] [int] NULL,
	[Oggetto] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Attivo] [bit] NOT NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
 CONSTRAINT [PK_ModelliPreventivo] PRIMARY KEY CLUSTERED
(
	[IdModelloPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ModelliPreventivo_Codice] UNIQUE NONCLUSTERED
(
	[CodiceModelloPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ModelliPreventivo] ADD  CONSTRAINT [DF_ModelliPreventivo_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

ALTER TABLE [dbo].[ModelliPreventivo] ADD  CONSTRAINT [DF_ModelliPreventivo_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ModelliPreventivoRighe](
	[IdRigaModelloPreventivo] [int] IDENTITY(1,1) NOT NULL,
	[IdModelloPreventivo] [int] NOT NULL,
	[RigaNr] [int] NOT NULL,
	[IdArticolo] [int] NULL,
	[IdModelloCiclo] [int] NULL,
	[DescrizioneVoce] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Quantita] [decimal](18, 4) NOT NULL,
	[PrezzoUnitarioVendita] [decimal](18, 4) NOT NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_ModelliPreventivoRighe] PRIMARY KEY CLUSTERED
(
	[IdRigaModelloPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ModelliPreventivoRighe] UNIQUE NONCLUSTERED
(
	[IdModelloPreventivo] ASC,
	[RigaNr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ModelliPreventivoRighe] ADD  CONSTRAINT [DF_ModelliPreventivoRighe_Quantita]  DEFAULT ((1)) FOR [Quantita]
GO

ALTER TABLE [dbo].[ModelliPreventivoRighe] ADD  CONSTRAINT [DF_ModelliPreventivoRighe_Prezzo]  DEFAULT ((0)) FOR [PrezzoUnitarioVendita]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OrdiniFornitori](
	[IdOrdineFornitore] [int] IDENTITY(1,1) NOT NULL,
	[NumeroOrdine] [int] NOT NULL,
	[Anno] [int] NOT NULL,
	[DataOrdine] [date] NOT NULL,
	[IdFornitore] [int] NOT NULL,
	[Oggetto] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Stato] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[TotaleOrdine] [decimal](18, 2) NOT NULL,
	[DataConsegnaPrevista] [date] NULL,
	[IdPreventivo] [int] NULL,
	[IdRigaPreventivo] [int] NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
 CONSTRAINT [PK_OrdiniFornitori] PRIMARY KEY CLUSTERED
(
	[IdOrdineFornitore] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_OrdiniFornitori_NumeroAnno] UNIQUE NONCLUSTERED
(
	[NumeroOrdine] ASC,
	[Anno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_OrdiniFornitori_DataOrdine] ON [dbo].[OrdiniFornitori]
(
	[DataOrdine] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_OrdiniFornitori_IdFornitore] ON [dbo].[OrdiniFornitori]
(
	[IdFornitore] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[OrdiniFornitori] ADD  CONSTRAINT [DF_OrdiniFornitori_Stato]  DEFAULT ('Bozza') FOR [Stato]
GO

ALTER TABLE [dbo].[OrdiniFornitori] ADD  CONSTRAINT [DF_OrdiniFornitori_Totale]  DEFAULT ((0)) FOR [TotaleOrdine]
GO

ALTER TABLE [dbo].[OrdiniFornitori] ADD  CONSTRAINT [DF_OrdiniFornitori_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

ALTER TABLE [dbo].[OrdiniFornitori]  WITH CHECK ADD  CONSTRAINT [CK_OrdiniFornitori_Stato] CHECK  (([Stato]='Annullato' OR [Stato]='Ricevuto' OR [Stato]='Parziale' OR [Stato]='Inviato' OR [Stato]='Bozza'))
GO

ALTER TABLE [dbo].[OrdiniFornitori] CHECK CONSTRAINT [CK_OrdiniFornitori_Stato]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OrdiniFornitoriRighe](
	[IdRigaOrdineFornitore] [int] IDENTITY(1,1) NOT NULL,
	[IdOrdineFornitore] [int] NOT NULL,
	[RigaNr] [int] NOT NULL,
	[TipoRiga] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IdMateriale] [int] NULL,
	[IdLavorazione] [int] NULL,
	[IdNodoDistinta] [int] NULL,
	[IdRigaPreventivo] [int] NULL,
	[Descrizione] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[UM] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[Quantita] [decimal](18, 4) NOT NULL,
	[PrezzoUnitario] [decimal](18, 4) NOT NULL,
	[TotaleRiga] [decimal](18, 2) NOT NULL,
	[QuantitaRicevuta] [decimal](18, 4) NOT NULL,
	[DataConsegnaPrevista] [date] NULL,
	[Note] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_OrdiniFornitoriRighe] PRIMARY KEY CLUSTERED
(
	[IdRigaOrdineFornitore] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_OrdiniFornitoriRighe_Ordine_Riga] UNIQUE NONCLUSTERED
(
	[IdOrdineFornitore] ASC,
	[RigaNr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_OrdiniFornitoriRighe_IdOrdineFornitore] ON [dbo].[OrdiniFornitoriRighe]
(
	[IdOrdineFornitore] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] ADD  CONSTRAINT [DF_OrdiniFornitoriRighe_Quantita]  DEFAULT ((0)) FOR [Quantita]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] ADD  CONSTRAINT [DF_OrdiniFornitoriRighe_Prezzo]  DEFAULT ((0)) FOR [PrezzoUnitario]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] ADD  CONSTRAINT [DF_OrdiniFornitoriRighe_Totale]  DEFAULT ((0)) FOR [TotaleRiga]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] ADD  CONSTRAINT [DF_OrdiniFornitoriRighe_QtaRicev]  DEFAULT ((0)) FOR [QuantitaRicevuta]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [CK_OrdiniFornitoriRighe_TipoRiga] CHECK  (([TipoRiga]='Nota' OR [TipoRiga]='Lavorazione' OR [TipoRiga]='Materiale'))
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] CHECK CONSTRAINT [CK_OrdiniFornitoriRighe_TipoRiga]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OrigineCosto](
	[IDOrigineCosto] [int] IDENTITY(1,1) NOT NULL,
	[DescrizioneOrigineCosto] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[Attivo] [bit] NOT NULL,
	[OrdineVisualizzazione] [int] NULL,
 CONSTRAINT [PK_OrigineCosto] PRIMARY KEY CLUSTERED
(
	[IDOrigineCosto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[OrigineCosto] ADD  CONSTRAINT [DF_OrigineCosto_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ParametriSistema](
	[Chiave] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Valore] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Descrizione] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TipoDato] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
 CONSTRAINT [PK_ParametriSistema] PRIMARY KEY CLUSTERED
(
	[Chiave] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ParametriSistema] ADD  CONSTRAINT [DF_ParametriSistema_TipoDato]  DEFAULT (N'Stringa') FOR [TipoDato]
GO

ALTER TABLE [dbo].[ParametriSistema]  WITH CHECK ADD  CONSTRAINT [CK_ParametriSistema_TipoDato] CHECK  (([TipoDato]=N'Data' OR [TipoDato]=N'Booleano' OR [TipoDato]=N'Decimale' OR [TipoDato]=N'Intero' OR [TipoDato]=N'Stringa'))
GO

ALTER TABLE [dbo].[ParametriSistema] CHECK CONSTRAINT [CK_ParametriSistema_TipoDato]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Preventivi](
	[IdPreventivo] [int] IDENTITY(1,1) NOT NULL,
	[NumeroPreventivo] [int] NOT NULL,
	[Anno] [int] NOT NULL,
	[DataPreventivo] [date] NOT NULL,
	[IdCliente] [int] NULL,
	[IdModelloPreventivo] [int] NULL,
	[Oggetto] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Stato] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotaleCosti] [decimal](18, 2) NOT NULL,
	[TotaleVendita] [decimal](18, 2) NOT NULL,
	[MargineValore] [decimal](18, 2) NOT NULL,
	[MarginePerc] [decimal](9, 2) NOT NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
	[MarkupPercDefault] [decimal](9, 2) NOT NULL,
	[IdRichiestaCliente] [int] NULL,
 CONSTRAINT [PK_Preventivi] PRIMARY KEY CLUSTERED
(
	[IdPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Preventivi_NumeroAnno] UNIQUE NONCLUSTERED
(
	[NumeroPreventivo] ASC,
	[Anno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_Preventivi_DataPreventivo] ON [dbo].[Preventivi]
(
	[DataPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_Preventivi_IdCliente] ON [dbo].[Preventivi]
(
	[IdCliente] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Preventivi] ADD  CONSTRAINT [DF_Preventivi_Stato]  DEFAULT ('Bozza') FOR [Stato]
GO

ALTER TABLE [dbo].[Preventivi] ADD  CONSTRAINT [DF_Preventivi_TotaleCosti]  DEFAULT ((0)) FOR [TotaleCosti]
GO

ALTER TABLE [dbo].[Preventivi] ADD  CONSTRAINT [DF_Preventivi_TotaleVendita]  DEFAULT ((0)) FOR [TotaleVendita]
GO

ALTER TABLE [dbo].[Preventivi] ADD  CONSTRAINT [DF_Preventivi_MargineValore]  DEFAULT ((0)) FOR [MargineValore]
GO

ALTER TABLE [dbo].[Preventivi] ADD  CONSTRAINT [DF_Preventivi_MarginePerc]  DEFAULT ((0)) FOR [MarginePerc]
GO

ALTER TABLE [dbo].[Preventivi] ADD  CONSTRAINT [DF_Preventivi_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

ALTER TABLE [dbo].[Preventivi] ADD  CONSTRAINT [DF_Preventivi_MarkupPercDefault]  DEFAULT ((60)) FOR [MarkupPercDefault]
GO

ALTER TABLE [dbo].[Preventivi]  WITH CHECK ADD  CONSTRAINT [CK_Preventivi_Stato] CHECK  (([Stato]='Annullato' OR [Stato]='Chiuso' OR [Stato]='In Produzione' OR [Stato]='Respinto' OR [Stato]='Accettato' OR [Stato]='Inviato' OR [Stato]='Pronto da Inviare' OR [Stato]='Da Verificare' OR [Stato]='Bozza'))
GO

ALTER TABLE [dbo].[Preventivi] CHECK CONSTRAINT [CK_Preventivi_Stato]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PreventiviRighe](
	[IdRigaPreventivo] [int] IDENTITY(1,1) NOT NULL,
	[IdPreventivo] [int] NOT NULL,
	[RigaNr] [int] NOT NULL,
	[IdArticolo] [int] NULL,
	[IdModelloCiclo] [int] NULL,
	[DescrizioneVoce] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Quantita] [decimal](18, 4) NOT NULL,
	[PrezzoUnitarioVendita] [decimal](18, 4) NOT NULL,
	[TotaleVendita] [decimal](18, 2) NOT NULL,
	[TotaleCosti] [decimal](18, 2) NOT NULL,
	[MargineValore] [decimal](18, 2) NOT NULL,
	[MarginePerc] [decimal](9, 2) NOT NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
	[MarkupPerc] [decimal](9, 2) NOT NULL,
	[PrezzoManuale] [bit] NOT NULL,
	[IdVariantePreventivo] [int] NULL,
	[CostoUnitarioLibero] [decimal](18, 4) NULL,
	[IdTipoRiga] [int] NOT NULL,
 CONSTRAINT [PK_PreventiviRighe] PRIMARY KEY CLUSTERED
(
	[IdRigaPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_PreventiviRighe_IdPreventivo_RigaNr] UNIQUE NONCLUSTERED
(
	[IdPreventivo] ASC,
	[RigaNr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PreventiviRighe_IdArticolo] ON [dbo].[PreventiviRighe]
(
	[IdArticolo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PreventiviRighe_IdPreventivo] ON [dbo].[PreventiviRighe]
(
	[IdPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PreventiviRighe_IdTipoRiga] ON [dbo].[PreventiviRighe]
(
	[IdTipoRiga] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_Quantita]  DEFAULT ((1)) FOR [Quantita]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_PrezzoUnit]  DEFAULT ((0)) FOR [PrezzoUnitarioVendita]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_TotVend]  DEFAULT ((0)) FOR [TotaleVendita]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_TotCost]  DEFAULT ((0)) FOR [TotaleCosti]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_MargVal]  DEFAULT ((0)) FOR [MargineValore]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_MargPerc]  DEFAULT ((0)) FOR [MarginePerc]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_MarkupPerc]  DEFAULT ((60)) FOR [MarkupPerc]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_PrezzoManuale]  DEFAULT ((0)) FOR [PrezzoManuale]
GO

ALTER TABLE [dbo].[PreventiviRighe] ADD  CONSTRAINT [DF_PreventiviRighe_IdTipoRiga]  DEFAULT ((1)) FOR [IdTipoRiga]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PreventiviRigheComponenti](
	[IdRigaCompPrev] [int] IDENTITY(1,1) NOT NULL,
	[IdRigaPreventivo] [int] NOT NULL,
	[IdNodoDistinta] [int] NULL,
	[IdNodoPadre] [int] NULL,
	[DescrizioneNodo] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[Livello] [int] NOT NULL,
	[QuantitaBase] [decimal](18, 4) NOT NULL,
	[QuantitaCalcolata] [decimal](18, 4) NOT NULL,
	[OrdineVisualizzazione] [int] NOT NULL,
	[IdRigaCompPrevPadre] [int] NULL,
	[TipoOrigineComponente] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IdArticoloOrigine] [int] NULL,
 CONSTRAINT [PK_PreventiviRigheComponenti] PRIMARY KEY CLUSTERED
(
	[IdRigaCompPrev] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PreventiviRigheComponenti_IdRigaPreventivo] ON [dbo].[PreventiviRigheComponenti]
(
	[IdRigaPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PreventiviRigheComponenti_RigaPadre] ON [dbo].[PreventiviRigheComponenti]
(
	[IdRigaPreventivo] ASC,
	[IdRigaCompPrevPadre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_PreventiviRigheComponenti_RigaComponente] ON [dbo].[PreventiviRigheComponenti]
(
	[IdRigaPreventivo] ASC,
	[IdRigaCompPrev] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] ADD  CONSTRAINT [DF_PreventiviRigheComponenti_Livello]  DEFAULT ((0)) FOR [Livello]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] ADD  CONSTRAINT [DF_PreventiviRigheComponenti_QuantitaBase]  DEFAULT ((1)) FOR [QuantitaBase]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] ADD  CONSTRAINT [DF_PreventiviRigheComponenti_QuantitaCalc]  DEFAULT ((1)) FOR [QuantitaCalcolata]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] ADD  CONSTRAINT [DF_PreventiviRigheComponenti_Ordine]  DEFAULT ((0)) FOR [OrdineVisualizzazione]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti]  WITH CHECK ADD  CONSTRAINT [CK_PreventiviRigheComponenti_Origine] CHECK  (([TipoOrigineComponente]=N'Distinta' AND [IdNodoDistinta] IS NOT NULL AND [IdArticoloOrigine] IS NOT NULL OR [TipoOrigineComponente]=N'Articolo' AND [IdNodoDistinta] IS NULL AND [IdArticoloOrigine] IS NOT NULL OR [TipoOrigineComponente]=N'Libero' AND [IdNodoDistinta] IS NULL AND [IdArticoloOrigine] IS NULL))
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] CHECK CONSTRAINT [CK_PreventiviRigheComponenti_Origine]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti]  WITH CHECK ADD  CONSTRAINT [CK_PreventiviRigheComponenti_PadreDiverso] CHECK  (([IdRigaCompPrevPadre] IS NULL OR [IdRigaCompPrevPadre]<>[IdRigaCompPrev]))
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] CHECK CONSTRAINT [CK_PreventiviRigheComponenti_PadreDiverso]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti]  WITH CHECK ADD  CONSTRAINT [CK_PreventiviRigheComponenti_Quantita] CHECK  (([QuantitaBase]>(0) AND [QuantitaCalcolata]>(0)))
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] CHECK CONSTRAINT [CK_PreventiviRigheComponenti_Quantita]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PreventiviRigheLavorazioni](
	[IdRigaLavPrev] [int] IDENTITY(1,1) NOT NULL,
	[IdRigaPreventivo] [int] NOT NULL,
	[IdNodoDistinta] [int] NULL,
	[IdLavorazione] [int] NULL,
	[DescrizioneLavorazione] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[Sequenza] [int] NOT NULL,
	[TempoSetupMin] [decimal](18, 2) NOT NULL,
	[TempoPezzoMin] [decimal](18, 4) NOT NULL,
	[Quantita] [decimal](18, 4) NOT NULL,
	[TempoTotaleMin] [decimal](18, 4) NOT NULL,
	[CostoOrario] [decimal](18, 4) NOT NULL,
	[CostoFisso] [decimal](18, 4) NOT NULL,
	[CostoTotale] [decimal](18, 2) NOT NULL,
	[DaAcquistareEsterno] [bit] NOT NULL,
	[IdFornitoreSuggerito] [int] NULL,
	[IdRigaCompPrev] [int] NULL,
 CONSTRAINT [PK_PreventiviRigheLavorazioni] PRIMARY KEY CLUSTERED
(
	[IdRigaLavPrev] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PreventiviRigheLavorazioni_IdRigaPreventivo] ON [dbo].[PreventiviRigheLavorazioni]
(
	[IdRigaPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PreventiviRigheLavorazioni_RigaComponente] ON [dbo].[PreventiviRigheLavorazioni]
(
	[IdRigaPreventivo] ASC,
	[IdRigaCompPrev] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] ADD  CONSTRAINT [DF_PreventiviRigheLavorazioni_Sequenza]  DEFAULT ((1)) FOR [Sequenza]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] ADD  CONSTRAINT [DF_PreventiviRigheLavorazioni_TempoSetup]  DEFAULT ((0)) FOR [TempoSetupMin]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] ADD  CONSTRAINT [DF_PreventiviRigheLavorazioni_TempoPezzo]  DEFAULT ((0)) FOR [TempoPezzoMin]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] ADD  CONSTRAINT [DF_PreventiviRigheLavorazioni_Quantita]  DEFAULT ((1)) FOR [Quantita]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] ADD  CONSTRAINT [DF_PreventiviRigheLavorazioni_TempoTot]  DEFAULT ((0)) FOR [TempoTotaleMin]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] ADD  CONSTRAINT [DF_PreventiviRigheLavorazioni_CostoOrario]  DEFAULT ((0)) FOR [CostoOrario]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] ADD  CONSTRAINT [DF_PreventiviRigheLavorazioni_CostoFisso]  DEFAULT ((0)) FOR [CostoFisso]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] ADD  CONSTRAINT [DF_PreventiviRigheLavorazioni_CostoTot]  DEFAULT ((0)) FOR [CostoTotale]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] ADD  CONSTRAINT [DF_PreventiviRigheLavorazioni_DaAcq]  DEFAULT ((0)) FOR [DaAcquistareEsterno]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PreventiviRigheMateriali](
	[IdRigaMatPrev] [int] IDENTITY(1,1) NOT NULL,
	[IdRigaPreventivo] [int] NOT NULL,
	[IdNodoDistinta] [int] NULL,
	[IdMateriale] [int] NULL,
	[DescrizioneMateriale] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[TipoMateriale] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[UM] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[Quantita] [decimal](18, 4) NOT NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
	[CostoTotale] [decimal](18, 2) NOT NULL,
	[DaAcquistare] [bit] NOT NULL,
	[IdFornitoreSuggerito] [int] NULL,
	[IdRigaCompPrev] [int] NULL,
 CONSTRAINT [PK_PreventiviRigheMateriali] PRIMARY KEY CLUSTERED
(
	[IdRigaMatPrev] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PreventiviRigheMateriali_IdRigaPreventivo] ON [dbo].[PreventiviRigheMateriali]
(
	[IdRigaPreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PreventiviRigheMateriali_RigaComponente] ON [dbo].[PreventiviRigheMateriali]
(
	[IdRigaPreventivo] ASC,
	[IdRigaCompPrev] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali] ADD  CONSTRAINT [DF_PreventiviRigheMateriali_Quantita]  DEFAULT ((0)) FOR [Quantita]
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali] ADD  CONSTRAINT [DF_PreventiviRigheMateriali_CostoUnit]  DEFAULT ((0)) FOR [CostoUnitario]
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali] ADD  CONSTRAINT [DF_PreventiviRigheMateriali_CostoTot]  DEFAULT ((0)) FOR [CostoTotale]
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali] ADD  CONSTRAINT [DF_PreventiviRigheMateriali_DaAcq]  DEFAULT ((0)) FOR [DaAcquistare]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PreventiviVarianti](
	[IdVariantePreventivo] [int] IDENTITY(1,1) NOT NULL,
	[IdPreventivo] [int] NOT NULL,
	[CodiceVariante] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[DescrizioneVariante] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[VarianteScelta] [bit] NOT NULL,
	[Attiva] [bit] NOT NULL,
	[TotaleCosti] [decimal](18, 2) NOT NULL,
	[TotaleVendita] [decimal](18, 2) NOT NULL,
	[MargineValore] [decimal](18, 2) NOT NULL,
	[MarginePerc] [decimal](9, 2) NOT NULL,
	[DataCreazione] [datetime2](7) NOT NULL,
	[DataModifica] [datetime2](7) NULL,
 CONSTRAINT [PK_PreventiviVarianti] PRIMARY KEY CLUSTERED
(
	[IdVariantePreventivo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_PreventiviVarianti] UNIQUE NONCLUSTERED
(
	[IdPreventivo] ASC,
	[CodiceVariante] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_PreventiviVarianti_UnaSceltaAttiva] ON [dbo].[PreventiviVarianti]
(
	[IdPreventivo] ASC
)
WHERE ([Attiva]=(1) AND [VarianteScelta]=(1))
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PreventiviVarianti] ADD  CONSTRAINT [DF_PreventiviVarianti_Scelta]  DEFAULT ((0)) FOR [VarianteScelta]
GO

ALTER TABLE [dbo].[PreventiviVarianti] ADD  CONSTRAINT [DF_PreventiviVarianti_Attiva]  DEFAULT ((1)) FOR [Attiva]
GO

ALTER TABLE [dbo].[PreventiviVarianti] ADD  CONSTRAINT [DF_PreventiviVarianti_TotCosti]  DEFAULT ((0)) FOR [TotaleCosti]
GO

ALTER TABLE [dbo].[PreventiviVarianti] ADD  CONSTRAINT [DF_PreventiviVarianti_TotVend]  DEFAULT ((0)) FOR [TotaleVendita]
GO

ALTER TABLE [dbo].[PreventiviVarianti] ADD  CONSTRAINT [DF_PreventiviVarianti_MargVal]  DEFAULT ((0)) FOR [MargineValore]
GO

ALTER TABLE [dbo].[PreventiviVarianti] ADD  CONSTRAINT [DF_PreventiviVarianti_MargPerc]  DEFAULT ((0)) FOR [MarginePerc]
GO

ALTER TABLE [dbo].[PreventiviVarianti] ADD  CONSTRAINT [DF_PreventiviVarianti_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProblematicheStandard](
	[IdProblematicaStandard] [int] IDENTITY(1,1) NOT NULL,
	[IdTipoProblematica] [int] NOT NULL,
	[CodiceProblematica] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[DescrizioneProblematica] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[SoluzioneStandard] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[NoteTecniche] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Attiva] [bit] NOT NULL,
 CONSTRAINT [PK_ProblematicheStandard] PRIMARY KEY CLUSTERED
(
	[IdProblematicaStandard] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ProblematicheStandard] UNIQUE NONCLUSTERED
(
	[CodiceProblematica] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProblematicheStandard] ADD  DEFAULT ((1)) FOR [Attiva]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RichiesteClienti](
	[IdRichiestaCliente] [int] IDENTITY(1,1) NOT NULL,
	[NumeroRichiesta] [int] NOT NULL,
	[Anno] [int] NOT NULL,
	[DataRichiesta] [date] NOT NULL,
	[IdCliente] [int] NULL,
	[Oggetto] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[DescrizioneRichiesta] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Stato] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Priorita] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[InteresseCliente] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[DataScadenza] [date] NULL,
	[DataAttivazione] [date] NULL,
	[DataChiusura] [date] NULL,
	[ProbabilitaChiusura] [int] NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
	[DataModifica] [datetime2](0) NULL,
 CONSTRAINT [PK_RichiesteClienti] PRIMARY KEY CLUSTERED
(
	[IdRichiestaCliente] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_RichiesteClienti_NumeroAnno] UNIQUE NONCLUSTERED
(
	[NumeroRichiesta] ASC,
	[Anno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[RichiesteClienti] ADD  CONSTRAINT [DF_RichiesteClienti_Stato]  DEFAULT ('Nuova') FOR [Stato]
GO

ALTER TABLE [dbo].[RichiesteClienti] ADD  CONSTRAINT [DF_RichiesteClienti_Priorita]  DEFAULT ('Media') FOR [Priorita]
GO

ALTER TABLE [dbo].[RichiesteClienti] ADD  CONSTRAINT [DF_RichiesteClienti_DataCreazione]  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

ALTER TABLE [dbo].[RichiesteClienti]  WITH CHECK ADD  CONSTRAINT [CK_RichiesteClienti_Interesse] CHECK  (([InteresseCliente] IS NULL OR ([InteresseCliente]='Strategico' OR [InteresseCliente]='Alto' OR [InteresseCliente]='Medio' OR [InteresseCliente]='Basso')))
GO

ALTER TABLE [dbo].[RichiesteClienti] CHECK CONSTRAINT [CK_RichiesteClienti_Interesse]
GO

ALTER TABLE [dbo].[RichiesteClienti]  WITH CHECK ADD  CONSTRAINT [CK_RichiesteClienti_Priorita] CHECK  (([Priorita]='Urgente' OR [Priorita]='Alta' OR [Priorita]='Media' OR [Priorita]='Bassa'))
GO

ALTER TABLE [dbo].[RichiesteClienti] CHECK CONSTRAINT [CK_RichiesteClienti_Priorita]
GO

ALTER TABLE [dbo].[RichiesteClienti]  WITH CHECK ADD  CONSTRAINT [CK_RichiesteClienti_Stato] CHECK  (([Stato]='Annullata' OR [Stato]='Persa' OR [Stato]='Confermata' OR [Stato]='Sospesa' OR [Stato]='Preventivata' OR [Stato]='Da Preventivare' OR [Stato]='In Valutazione' OR [Stato]='Nuova'))
GO

ALTER TABLE [dbo].[RichiesteClienti] CHECK CONSTRAINT [CK_RichiesteClienti_Stato]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RichiesteOffertaFornitori](
	[IdRichiestaOfferta] [int] IDENTITY(1,1) NOT NULL,
	[NumeroRichiesta] [int] NOT NULL,
	[Anno] [int] NOT NULL,
	[DataRichiesta] [date] NOT NULL,
	[IdFornitore] [int] NOT NULL,
	[IdPreventivo] [int] NULL,
	[IdRigaPreventivo] [int] NULL,
	[Oggetto] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Stato] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[DataScadenzaRisposta] [date] NULL,
	[DataRisposta] [date] NULL,
	[Note] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[TotaleOfferta] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_RichiesteOffertaFornitori] PRIMARY KEY CLUSTERED
(
	[IdRichiestaOfferta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori] ADD  DEFAULT ('Bozza') FOR [Stato]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori] ADD  DEFAULT ((0)) FOR [TotaleOfferta]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori]  WITH CHECK ADD  CONSTRAINT [CK_RichiesteOffertaFornitori_Stato] CHECK  (([Stato]='Annullata' OR [Stato]='Scartata' OR [Stato]='Accettata' OR [Stato]='Risposta ricevuta' OR [Stato]='Inviata' OR [Stato]='Bozza'))
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori] CHECK CONSTRAINT [CK_RichiesteOffertaFornitori_Stato]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RichiesteOffertaFornitoriRighe](
	[IdRigaRichiestaOfferta] [int] IDENTITY(1,1) NOT NULL,
	[IdRichiestaOfferta] [int] NOT NULL,
	[RigaNr] [int] NOT NULL,
	[IdRigaPreventivo] [int] NULL,
	[IdRigaMatPrev] [int] NULL,
	[IdMateriale] [int] NULL,
	[DescrizioneMateriale] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[UM] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[Quantita] [decimal](18, 4) NOT NULL,
	[PrezzoRichiesto] [decimal](18, 4) NOT NULL,
	[PrezzoOfferto] [decimal](18, 4) NOT NULL,
	[TotaleOfferto] [decimal](18, 2) NOT NULL,
	[TempiConsegnaGg] [int] NULL,
	[NoteFornitore] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Accettata] [bit] NOT NULL,
 CONSTRAINT [PK_RichiesteOffertaFornitoriRighe] PRIMARY KEY CLUSTERED
(
	[IdRigaRichiestaOfferta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe] ADD  DEFAULT ((0)) FOR [Quantita]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe] ADD  DEFAULT ((0)) FOR [PrezzoRichiesto]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe] ADD  DEFAULT ((0)) FOR [PrezzoOfferto]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe] ADD  DEFAULT ((0)) FOR [TotaleOfferto]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe] ADD  DEFAULT ((0)) FOR [Accettata]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RuoliApplicazione](
	[IdRuolo] [int] IDENTITY(1,1) NOT NULL,
	[CodiceRuolo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attivo] [bit] NOT NULL,
 CONSTRAINT [PK_RuoliApplicazione] PRIMARY KEY CLUSTERED
(
	[IdRuolo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_RuoliApplicazione_Codice] UNIQUE NONCLUSTERED
(
	[CodiceRuolo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RuoliApplicazione] ADD  DEFAULT ((1)) FOR [Attivo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TipiAllegato](
	[IdTipoAllegato] [int] IDENTITY(1,1) NOT NULL,
	[CodiceTipo] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attivo] [bit] NOT NULL,
 CONSTRAINT [PK_TipiAllegato] PRIMARY KEY CLUSTERED
(
	[IdTipoAllegato] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_TipiAllegato_CodiceTipo] UNIQUE NONCLUSTERED
(
	[CodiceTipo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TipiAllegato] ADD  CONSTRAINT [DF_TipiAllegato_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TipiNodoDistinta](
	[IdTipoNodo] [int] IDENTITY(1,1) NOT NULL,
	[Descrizione] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attivo] [bit] NOT NULL,
 CONSTRAINT [PK_TipiNodoDistinta] PRIMARY KEY CLUSTERED
(
	[IdTipoNodo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_TipiNodoDistinta_Descrizione] UNIQUE NONCLUSTERED
(
	[Descrizione] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TipiNodoDistinta] ADD  CONSTRAINT [DF_TipiNodoDistinta_Attivo]  DEFAULT ((1)) FOR [Attivo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TipiProblematicheQualita](
	[IdTipoProblematica] [int] IDENTITY(1,1) NOT NULL,
	[CodiceTipo] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](150) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attivo] [bit] NOT NULL,
 CONSTRAINT [PK_TipiProblematicheQualita] PRIMARY KEY CLUSTERED
(
	[IdTipoProblematica] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_TipiProblematicheQualita] UNIQUE NONCLUSTERED
(
	[CodiceTipo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TipiProblematicheQualita] ADD  DEFAULT ((1)) FOR [Attivo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TipiRigaPreventivo](
	[IdTipoRiga] [int] IDENTITY(1,1) NOT NULL,
	[Codice] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[RigaArticolo] [bit] NOT NULL,
	[RigaLibera] [bit] NOT NULL,
	[Attiva] [bit] NOT NULL,
	[DataCreazione] [datetime2](7) NOT NULL,
	[GeneraOrdineFornitore] [bit] NOT NULL,
	[ConcorreAlMargine] [bit] NOT NULL,
	[StampaSuPreventivo] [bit] NOT NULL,
	[Ordinabile] [bit] NOT NULL,
	[Ordinamento] [int] NOT NULL,
	[DataModifica] [datetime2](0) NULL,
	[UsaDistinta] [bit] NOT NULL,
	[ConsenteCostoLibero] [bit] NOT NULL,
	[ConsentePrezzoManuale] [bit] NOT NULL,
	[MostraMateriali] [bit] NOT NULL,
	[MostraLavorazioni] [bit] NOT NULL,
	[MostraComponenti] [bit] NOT NULL,
	[MostraArticolo] [bit] NOT NULL,
	[ObbligaArticolo] [bit] NOT NULL,
PRIMARY KEY CLUSTERED
(
	[IdTipoRiga] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED
(
	[Codice] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((0)) FOR [RigaArticolo]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((0)) FOR [RigaLibera]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((1)) FOR [Attiva]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  CONSTRAINT [DF_TipiRigaPreventivo_GeneraOrdineFornitore]  DEFAULT ((0)) FOR [GeneraOrdineFornitore]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  CONSTRAINT [DF_TipiRigaPreventivo_ConcorreAlMargine]  DEFAULT ((1)) FOR [ConcorreAlMargine]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  CONSTRAINT [DF_TipiRigaPreventivo_StampaSuPreventivo]  DEFAULT ((1)) FOR [StampaSuPreventivo]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  CONSTRAINT [DF_TipiRigaPreventivo_Ordinabile]  DEFAULT ((0)) FOR [Ordinabile]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  CONSTRAINT [DF_TipiRigaPreventivo_Ordinamento]  DEFAULT ((0)) FOR [Ordinamento]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((1)) FOR [UsaDistinta]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((0)) FOR [ConsenteCostoLibero]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((1)) FOR [ConsentePrezzoManuale]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((1)) FOR [MostraMateriali]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((1)) FOR [MostraLavorazioni]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((1)) FOR [MostraComponenti]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((1)) FOR [MostraArticolo]
GO

ALTER TABLE [dbo].[TipiRigaPreventivo] ADD  DEFAULT ((0)) FOR [ObbligaArticolo]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TmpImportModelloPreventivoExcel](
	[RigaNr] [int] NULL,
	[CodiceArticolo] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[DescrizioneVoce] [nvarchar](255) COLLATE Latin1_General_CI_AS NULL,
	[Quantita] [decimal](18, 4) NULL,
	[PrezzoUnitarioVendita] [decimal](18, 4) NULL,
	[CodiceModelloCiclo] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Note] [nvarchar](255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UnitaMisura](
	[IdUM] [int] IDENTITY(1,1) NOT NULL,
	[CodiceUM] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Descrizione] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
 CONSTRAINT [PK_UnitaMisura] PRIMARY KEY CLUSTERED
(
	[IdUM] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_UnitaMisura_CodiceUM] UNIQUE NONCLUSTERED
(
	[CodiceUM] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UtentiApplicazione](
	[IdUtente] [int] IDENTITY(1,1) NOT NULL,
	[Username] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[NomeCompleto] [nvarchar](150) COLLATE Latin1_General_CI_AS NULL,
	[PasswordHash] [nvarchar](255) COLLATE Latin1_General_CI_AS NULL,
	[Attivo] [bit] NOT NULL,
	[DataCreazione] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_UtentiApplicazione] PRIMARY KEY CLUSTERED
(
	[IdUtente] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_UtentiApplicazione_Username] UNIQUE NONCLUSTERED
(
	[Username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[UtentiApplicazione] ADD  DEFAULT ((1)) FOR [Attivo]
GO

ALTER TABLE [dbo].[UtentiApplicazione] ADD  DEFAULT (sysdatetime()) FOR [DataCreazione]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UtentiRuoli](
	[IdUtenteRuolo] [int] IDENTITY(1,1) NOT NULL,
	[IdUtente] [int] NOT NULL,
	[IdRuolo] [int] NOT NULL,
 CONSTRAINT [PK_UtentiRuoli] PRIMARY KEY CLUSTERED
(
	[IdUtenteRuolo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_UtentiRuoli] UNIQUE NONCLUSTERED
(
	[IdUtente] ASC,
	[IdRuolo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
