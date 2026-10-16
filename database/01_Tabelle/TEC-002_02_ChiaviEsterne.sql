/*
    TEC-002 - Chiavi esterne
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

ALTER TABLE [dbo].[Articoli]  WITH CHECK ADD  CONSTRAINT [FK_Articoli_Clienti] FOREIGN KEY([IdCliente])
REFERENCES [dbo].[Clienti] ([IdCliente])
GO

ALTER TABLE [dbo].[Articoli] CHECK CONSTRAINT [FK_Articoli_Clienti]
GO

ALTER TABLE [dbo].[Campionature]  WITH CHECK ADD  CONSTRAINT [FK_Campionature_Preventivi] FOREIGN KEY([IdPreventivo])
REFERENCES [dbo].[Preventivi] ([IdPreventivo])
GO

ALTER TABLE [dbo].[Campionature] CHECK CONSTRAINT [FK_Campionature_Preventivi]
GO

ALTER TABLE [dbo].[Campionature]  WITH CHECK ADD  CONSTRAINT [FK_Campionature_Richieste] FOREIGN KEY([IdRichiestaCliente])
REFERENCES [dbo].[RichiesteClienti] ([IdRichiestaCliente])
GO

ALTER TABLE [dbo].[Campionature] CHECK CONSTRAINT [FK_Campionature_Richieste]
GO

ALTER TABLE [dbo].[Campionature]  WITH CHECK ADD  CONSTRAINT [FK_Campionature_Varianti] FOREIGN KEY([IdVariantePreventivo])
REFERENCES [dbo].[PreventiviVarianti] ([IdVariantePreventivo])
GO

ALTER TABLE [dbo].[Campionature] CHECK CONSTRAINT [FK_Campionature_Varianti]
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo]  WITH CHECK ADD  CONSTRAINT [FK_CampAdeguamenti_Campionature] FOREIGN KEY([IdCampionatura])
REFERENCES [dbo].[Campionature] ([IdCampionatura])
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo] CHECK CONSTRAINT [FK_CampAdeguamenti_Campionature]
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo]  WITH CHECK ADD  CONSTRAINT [FK_CampAdeguamenti_Preventivi] FOREIGN KEY([IdPreventivo])
REFERENCES [dbo].[Preventivi] ([IdPreventivo])
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo] CHECK CONSTRAINT [FK_CampAdeguamenti_Preventivi]
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo]  WITH CHECK ADD  CONSTRAINT [FK_CampAdeguamenti_Rilievi] FOREIGN KEY([IdRilievoCampionatura])
REFERENCES [dbo].[CampionatureRilievi] ([IdRilievoCampionatura])
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo] CHECK CONSTRAINT [FK_CampAdeguamenti_Rilievi]
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo]  WITH CHECK ADD  CONSTRAINT [FK_CampAdeguamenti_Varianti] FOREIGN KEY([IdVariantePreventivo])
REFERENCES [dbo].[PreventiviVarianti] ([IdVariantePreventivo])
GO

ALTER TABLE [dbo].[CampionatureAdeguamentiPreventivo] CHECK CONSTRAINT [FK_CampAdeguamenti_Varianti]
GO

ALTER TABLE [dbo].[CampionatureRilievi]  WITH CHECK ADD  CONSTRAINT [FK_CampionatureRilievi_Campionature] FOREIGN KEY([IdCampionatura])
REFERENCES [dbo].[Campionature] ([IdCampionatura])
GO

ALTER TABLE [dbo].[CampionatureRilievi] CHECK CONSTRAINT [FK_CampionatureRilievi_Campionature]
GO

ALTER TABLE [dbo].[CampionatureRilievi]  WITH CHECK ADD  CONSTRAINT [FK_CampionatureRilievi_Standard] FOREIGN KEY([IdProblematicaStandard])
REFERENCES [dbo].[ProblematicheStandard] ([IdProblematicaStandard])
GO

ALTER TABLE [dbo].[CampionatureRilievi] CHECK CONSTRAINT [FK_CampionatureRilievi_Standard]
GO

ALTER TABLE [dbo].[CampionatureRilievi]  WITH CHECK ADD  CONSTRAINT [FK_CampionatureRilievi_Tipi] FOREIGN KEY([IdTipoProblematica])
REFERENCES [dbo].[TipiProblematicheQualita] ([IdTipoProblematica])
GO

ALTER TABLE [dbo].[CampionatureRilievi] CHECK CONSTRAINT [FK_CampionatureRilievi_Tipi]
GO

ALTER TABLE [dbo].[DistintaBaseNodi]  WITH CHECK ADD  CONSTRAINT [FK_DistintaBaseNodi_Articoli] FOREIGN KEY([IdArticolo])
REFERENCES [dbo].[Articoli] ([IdArticolo])
GO

ALTER TABLE [dbo].[DistintaBaseNodi] CHECK CONSTRAINT [FK_DistintaBaseNodi_Articoli]
GO

ALTER TABLE [dbo].[DistintaBaseNodi]  WITH CHECK ADD  CONSTRAINT [FK_DistintaBaseNodi_Padre] FOREIGN KEY([IdNodoPadre])
REFERENCES [dbo].[DistintaBaseNodi] ([IdNodoDistinta])
GO

ALTER TABLE [dbo].[DistintaBaseNodi] CHECK CONSTRAINT [FK_DistintaBaseNodi_Padre]
GO

ALTER TABLE [dbo].[DistintaBaseNodi]  WITH CHECK ADD  CONSTRAINT [FK_DistintaBaseNodi_TipiNodoDistinta] FOREIGN KEY([IdTipoNodo])
REFERENCES [dbo].[TipiNodoDistinta] ([IdTipoNodo])
GO

ALTER TABLE [dbo].[DistintaBaseNodi] CHECK CONSTRAINT [FK_DistintaBaseNodi_TipiNodoDistinta]
GO

ALTER TABLE [dbo].[DistintaLavorazioni]  WITH CHECK ADD  CONSTRAINT [FK_DistintaLavorazioni_DistintaBaseNodi] FOREIGN KEY([IdNodoDistinta])
REFERENCES [dbo].[DistintaBaseNodi] ([IdNodoDistinta])
GO

ALTER TABLE [dbo].[DistintaLavorazioni] CHECK CONSTRAINT [FK_DistintaLavorazioni_DistintaBaseNodi]
GO

ALTER TABLE [dbo].[DistintaLavorazioni]  WITH CHECK ADD  CONSTRAINT [FK_DistintaLavorazioni_Lavorazioni] FOREIGN KEY([IdLavorazione])
REFERENCES [dbo].[Lavorazioni] ([IdLavorazione])
GO

ALTER TABLE [dbo].[DistintaLavorazioni] CHECK CONSTRAINT [FK_DistintaLavorazioni_Lavorazioni]
GO

ALTER TABLE [dbo].[DistintaLavorazioni]  WITH CHECK ADD  CONSTRAINT [FK_DistintaLavorazioni_ModelliCiclo] FOREIGN KEY([IdModelloCiclo])
REFERENCES [dbo].[ModelliCiclo] ([IdModelloCiclo])
GO

ALTER TABLE [dbo].[DistintaLavorazioni] CHECK CONSTRAINT [FK_DistintaLavorazioni_ModelliCiclo]
GO

ALTER TABLE [dbo].[DistintaMateriali]  WITH CHECK ADD  CONSTRAINT [FK_DistintaMateriali_DistintaBaseNodi] FOREIGN KEY([IdNodoDistinta])
REFERENCES [dbo].[DistintaBaseNodi] ([IdNodoDistinta])
GO

ALTER TABLE [dbo].[DistintaMateriali] CHECK CONSTRAINT [FK_DistintaMateriali_DistintaBaseNodi]
GO

ALTER TABLE [dbo].[DistintaMateriali]  WITH CHECK ADD  CONSTRAINT [FK_DistintaMateriali_Materiali] FOREIGN KEY([IdMateriale])
REFERENCES [dbo].[Materiali] ([IdMateriale])
GO

ALTER TABLE [dbo].[DistintaMateriali] CHECK CONSTRAINT [FK_DistintaMateriali_Materiali]
GO

ALTER TABLE [dbo].[FornitoriLavorazioni]  WITH CHECK ADD  CONSTRAINT [FK_FornitoriLavorazioni_Fornitori] FOREIGN KEY([IdFornitore])
REFERENCES [dbo].[Fornitori] ([IdFornitore])
GO

ALTER TABLE [dbo].[FornitoriLavorazioni] CHECK CONSTRAINT [FK_FornitoriLavorazioni_Fornitori]
GO

ALTER TABLE [dbo].[FornitoriLavorazioni]  WITH CHECK ADD  CONSTRAINT [FK_FornitoriLavorazioni_Lavorazioni] FOREIGN KEY([IdLavorazione])
REFERENCES [dbo].[Lavorazioni] ([IdLavorazione])
GO

ALTER TABLE [dbo].[FornitoriLavorazioni] CHECK CONSTRAINT [FK_FornitoriLavorazioni_Lavorazioni]
GO

ALTER TABLE [dbo].[FornitoriMateriali]  WITH CHECK ADD  CONSTRAINT [FK_FornitoriMateriali_Fornitori] FOREIGN KEY([IdFornitore])
REFERENCES [dbo].[Fornitori] ([IdFornitore])
GO

ALTER TABLE [dbo].[FornitoriMateriali] CHECK CONSTRAINT [FK_FornitoriMateriali_Fornitori]
GO

ALTER TABLE [dbo].[FornitoriMateriali]  WITH CHECK ADD  CONSTRAINT [FK_FornitoriMateriali_Materiali] FOREIGN KEY([IdMateriale])
REFERENCES [dbo].[Materiali] ([IdMateriale])
GO

ALTER TABLE [dbo].[FornitoriMateriali] CHECK CONSTRAINT [FK_FornitoriMateriali_Materiali]
GO

ALTER TABLE [dbo].[Lavorazioni]  WITH CHECK ADD  CONSTRAINT [FK_Lavorazioni_FornitorePredefinito] FOREIGN KEY([IdFornitorePredefinito])
REFERENCES [dbo].[Fornitori] ([IdFornitore])
GO

ALTER TABLE [dbo].[Lavorazioni] CHECK CONSTRAINT [FK_Lavorazioni_FornitorePredefinito]
GO

ALTER TABLE [dbo].[Materiali]  WITH CHECK ADD  CONSTRAINT [FK_Materiali_FornitorePredefinito] FOREIGN KEY([IdFornitorePredefinito])
REFERENCES [dbo].[Fornitori] ([IdFornitore])
GO

ALTER TABLE [dbo].[Materiali] CHECK CONSTRAINT [FK_Materiali_FornitorePredefinito]
GO

ALTER TABLE [dbo].[Materiali]  WITH CHECK ADD  CONSTRAINT [FK_Materiali_UnitaMisura] FOREIGN KEY([IdUM])
REFERENCES [dbo].[UnitaMisura] ([IdUM])
GO

ALTER TABLE [dbo].[Materiali] CHECK CONSTRAINT [FK_Materiali_UnitaMisura]
GO

ALTER TABLE [dbo].[MenuPermessiRuoli]  WITH CHECK ADD  CONSTRAINT [FK_MenuPermessiRuoli_MenuVoci] FOREIGN KEY([IdVoceMenu])
REFERENCES [dbo].[MenuVoci] ([IdVoceMenu])
GO

ALTER TABLE [dbo].[MenuPermessiRuoli] CHECK CONSTRAINT [FK_MenuPermessiRuoli_MenuVoci]
GO

ALTER TABLE [dbo].[MenuPermessiRuoli]  WITH CHECK ADD  CONSTRAINT [FK_MenuPermessiRuoli_RuoliApplicazione] FOREIGN KEY([IdRuolo])
REFERENCES [dbo].[RuoliApplicazione] ([IdRuolo])
GO

ALTER TABLE [dbo].[MenuPermessiRuoli] CHECK CONSTRAINT [FK_MenuPermessiRuoli_RuoliApplicazione]
GO

ALTER TABLE [dbo].[MenuVoci]  WITH CHECK ADD  CONSTRAINT [FK_MenuVoci_MenuGruppi] FOREIGN KEY([IdGruppoMenu])
REFERENCES [dbo].[MenuGruppi] ([IdGruppoMenu])
GO

ALTER TABLE [dbo].[MenuVoci] CHECK CONSTRAINT [FK_MenuVoci_MenuGruppi]
GO

ALTER TABLE [dbo].[ModelliCicloRighe]  WITH CHECK ADD  CONSTRAINT [FK_ModelliCicloRighe_Lavorazioni] FOREIGN KEY([IdLavorazione])
REFERENCES [dbo].[Lavorazioni] ([IdLavorazione])
GO

ALTER TABLE [dbo].[ModelliCicloRighe] CHECK CONSTRAINT [FK_ModelliCicloRighe_Lavorazioni]
GO

ALTER TABLE [dbo].[ModelliCicloRighe]  WITH CHECK ADD  CONSTRAINT [FK_ModelliCicloRighe_ModelliCiclo] FOREIGN KEY([IdModelloCiclo])
REFERENCES [dbo].[ModelliCiclo] ([IdModelloCiclo])
GO

ALTER TABLE [dbo].[ModelliCicloRighe] CHECK CONSTRAINT [FK_ModelliCicloRighe_ModelliCiclo]
GO

ALTER TABLE [dbo].[ModelliPreventivo]  WITH CHECK ADD  CONSTRAINT [FK_ModelliPreventivo_Clienti] FOREIGN KEY([IdCliente])
REFERENCES [dbo].[Clienti] ([IdCliente])
GO

ALTER TABLE [dbo].[ModelliPreventivo] CHECK CONSTRAINT [FK_ModelliPreventivo_Clienti]
GO

ALTER TABLE [dbo].[ModelliPreventivoRighe]  WITH CHECK ADD  CONSTRAINT [FK_ModelliPreventivoRighe_Articoli] FOREIGN KEY([IdArticolo])
REFERENCES [dbo].[Articoli] ([IdArticolo])
GO

ALTER TABLE [dbo].[ModelliPreventivoRighe] CHECK CONSTRAINT [FK_ModelliPreventivoRighe_Articoli]
GO

ALTER TABLE [dbo].[ModelliPreventivoRighe]  WITH CHECK ADD  CONSTRAINT [FK_ModelliPreventivoRighe_ModelliCiclo] FOREIGN KEY([IdModelloCiclo])
REFERENCES [dbo].[ModelliCiclo] ([IdModelloCiclo])
GO

ALTER TABLE [dbo].[ModelliPreventivoRighe] CHECK CONSTRAINT [FK_ModelliPreventivoRighe_ModelliCiclo]
GO

ALTER TABLE [dbo].[ModelliPreventivoRighe]  WITH CHECK ADD  CONSTRAINT [FK_ModelliPreventivoRighe_ModelliPreventivo] FOREIGN KEY([IdModelloPreventivo])
REFERENCES [dbo].[ModelliPreventivo] ([IdModelloPreventivo])
GO

ALTER TABLE [dbo].[ModelliPreventivoRighe] CHECK CONSTRAINT [FK_ModelliPreventivoRighe_ModelliPreventivo]
GO

ALTER TABLE [dbo].[OrdiniFornitori]  WITH CHECK ADD  CONSTRAINT [FK_OrdiniFornitori_Fornitori] FOREIGN KEY([IdFornitore])
REFERENCES [dbo].[Fornitori] ([IdFornitore])
GO

ALTER TABLE [dbo].[OrdiniFornitori] CHECK CONSTRAINT [FK_OrdiniFornitori_Fornitori]
GO

ALTER TABLE [dbo].[OrdiniFornitori]  WITH CHECK ADD  CONSTRAINT [FK_OrdiniFornitori_Preventivi] FOREIGN KEY([IdPreventivo])
REFERENCES [dbo].[Preventivi] ([IdPreventivo])
GO

ALTER TABLE [dbo].[OrdiniFornitori] CHECK CONSTRAINT [FK_OrdiniFornitori_Preventivi]
GO

ALTER TABLE [dbo].[OrdiniFornitori]  WITH CHECK ADD  CONSTRAINT [FK_OrdiniFornitori_PreventiviRighe] FOREIGN KEY([IdRigaPreventivo])
REFERENCES [dbo].[PreventiviRighe] ([IdRigaPreventivo])
GO

ALTER TABLE [dbo].[OrdiniFornitori] CHECK CONSTRAINT [FK_OrdiniFornitori_PreventiviRighe]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [FK_OrdiniFornitoriRighe_DistintaBaseNodi] FOREIGN KEY([IdNodoDistinta])
REFERENCES [dbo].[DistintaBaseNodi] ([IdNodoDistinta])
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] CHECK CONSTRAINT [FK_OrdiniFornitoriRighe_DistintaBaseNodi]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [FK_OrdiniFornitoriRighe_Lavorazioni] FOREIGN KEY([IdLavorazione])
REFERENCES [dbo].[Lavorazioni] ([IdLavorazione])
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] CHECK CONSTRAINT [FK_OrdiniFornitoriRighe_Lavorazioni]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [FK_OrdiniFornitoriRighe_Materiali] FOREIGN KEY([IdMateriale])
REFERENCES [dbo].[Materiali] ([IdMateriale])
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] CHECK CONSTRAINT [FK_OrdiniFornitoriRighe_Materiali]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [FK_OrdiniFornitoriRighe_OrdiniFornitori] FOREIGN KEY([IdOrdineFornitore])
REFERENCES [dbo].[OrdiniFornitori] ([IdOrdineFornitore])
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] CHECK CONSTRAINT [FK_OrdiniFornitoriRighe_OrdiniFornitori]
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [FK_OrdiniFornitoriRighe_PreventiviRighe] FOREIGN KEY([IdRigaPreventivo])
REFERENCES [dbo].[PreventiviRighe] ([IdRigaPreventivo])
GO

ALTER TABLE [dbo].[OrdiniFornitoriRighe] CHECK CONSTRAINT [FK_OrdiniFornitoriRighe_PreventiviRighe]
GO

ALTER TABLE [dbo].[Preventivi]  WITH CHECK ADD  CONSTRAINT [FK_Preventivi_Clienti] FOREIGN KEY([IdCliente])
REFERENCES [dbo].[Clienti] ([IdCliente])
GO

ALTER TABLE [dbo].[Preventivi] CHECK CONSTRAINT [FK_Preventivi_Clienti]
GO

ALTER TABLE [dbo].[Preventivi]  WITH CHECK ADD  CONSTRAINT [FK_Preventivi_ModelliPreventivo] FOREIGN KEY([IdModelloPreventivo])
REFERENCES [dbo].[ModelliPreventivo] ([IdModelloPreventivo])
GO

ALTER TABLE [dbo].[Preventivi] CHECK CONSTRAINT [FK_Preventivi_ModelliPreventivo]
GO

ALTER TABLE [dbo].[Preventivi]  WITH CHECK ADD  CONSTRAINT [FK_Preventivi_Richieste] FOREIGN KEY([IdRichiestaCliente])
REFERENCES [dbo].[RichiesteClienti] ([IdRichiestaCliente])
GO

ALTER TABLE [dbo].[Preventivi] CHECK CONSTRAINT [FK_Preventivi_Richieste]
GO

ALTER TABLE [dbo].[Preventivi]  WITH CHECK ADD  CONSTRAINT [FK_Preventivi_RichiesteClienti] FOREIGN KEY([IdRichiestaCliente])
REFERENCES [dbo].[RichiesteClienti] ([IdRichiestaCliente])
GO

ALTER TABLE [dbo].[Preventivi] CHECK CONSTRAINT [FK_Preventivi_RichiesteClienti]
GO

ALTER TABLE [dbo].[PreventiviRighe]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRighe_Articoli] FOREIGN KEY([IdArticolo])
REFERENCES [dbo].[Articoli] ([IdArticolo])
GO

ALTER TABLE [dbo].[PreventiviRighe] CHECK CONSTRAINT [FK_PreventiviRighe_Articoli]
GO

ALTER TABLE [dbo].[PreventiviRighe]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRighe_ModelliCiclo] FOREIGN KEY([IdModelloCiclo])
REFERENCES [dbo].[ModelliCiclo] ([IdModelloCiclo])
GO

ALTER TABLE [dbo].[PreventiviRighe] CHECK CONSTRAINT [FK_PreventiviRighe_ModelliCiclo]
GO

ALTER TABLE [dbo].[PreventiviRighe]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRighe_Preventivi] FOREIGN KEY([IdPreventivo])
REFERENCES [dbo].[Preventivi] ([IdPreventivo])
GO

ALTER TABLE [dbo].[PreventiviRighe] CHECK CONSTRAINT [FK_PreventiviRighe_Preventivi]
GO

ALTER TABLE [dbo].[PreventiviRighe]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRighe_PreventiviVarianti] FOREIGN KEY([IdVariantePreventivo])
REFERENCES [dbo].[PreventiviVarianti] ([IdVariantePreventivo])
GO

ALTER TABLE [dbo].[PreventiviRighe] CHECK CONSTRAINT [FK_PreventiviRighe_PreventiviVarianti]
GO

ALTER TABLE [dbo].[PreventiviRighe]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRighe_TipiRigaPreventivo] FOREIGN KEY([IdTipoRiga])
REFERENCES [dbo].[TipiRigaPreventivo] ([IdTipoRiga])
GO

ALTER TABLE [dbo].[PreventiviRighe] CHECK CONSTRAINT [FK_PreventiviRighe_TipiRigaPreventivo]
GO

ALTER TABLE [dbo].[PreventiviRighe]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRighe_Varianti] FOREIGN KEY([IdVariantePreventivo])
REFERENCES [dbo].[PreventiviVarianti] ([IdVariantePreventivo])
GO

ALTER TABLE [dbo].[PreventiviRighe] CHECK CONSTRAINT [FK_PreventiviRighe_Varianti]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheComponenti_ArticoloOrigine] FOREIGN KEY([IdArticoloOrigine])
REFERENCES [dbo].[Articoli] ([IdArticolo])
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] CHECK CONSTRAINT [FK_PreventiviRigheComponenti_ArticoloOrigine]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheComponenti_NodoDistintaOrigine] FOREIGN KEY([IdNodoDistinta])
REFERENCES [dbo].[DistintaBaseNodi] ([IdNodoDistinta])
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] CHECK CONSTRAINT [FK_PreventiviRigheComponenti_NodoDistintaOrigine]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheComponenti_PadreOperativo] FOREIGN KEY([IdRigaPreventivo], [IdRigaCompPrevPadre])
REFERENCES [dbo].[PreventiviRigheComponenti] ([IdRigaPreventivo], [IdRigaCompPrev])
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] CHECK CONSTRAINT [FK_PreventiviRigheComponenti_PadreOperativo]
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheComponenti_PreventiviRighe] FOREIGN KEY([IdRigaPreventivo])
REFERENCES [dbo].[PreventiviRighe] ([IdRigaPreventivo])
GO

ALTER TABLE [dbo].[PreventiviRigheComponenti] CHECK CONSTRAINT [FK_PreventiviRigheComponenti_PreventiviRighe]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheLavorazioni_Componente] FOREIGN KEY([IdRigaPreventivo], [IdRigaCompPrev])
REFERENCES [dbo].[PreventiviRigheComponenti] ([IdRigaPreventivo], [IdRigaCompPrev])
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] CHECK CONSTRAINT [FK_PreventiviRigheLavorazioni_Componente]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheLavorazioni_Fornitori] FOREIGN KEY([IdFornitoreSuggerito])
REFERENCES [dbo].[Fornitori] ([IdFornitore])
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] CHECK CONSTRAINT [FK_PreventiviRigheLavorazioni_Fornitori]
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheLavorazioni_PreventiviRighe] FOREIGN KEY([IdRigaPreventivo])
REFERENCES [dbo].[PreventiviRighe] ([IdRigaPreventivo])
GO

ALTER TABLE [dbo].[PreventiviRigheLavorazioni] CHECK CONSTRAINT [FK_PreventiviRigheLavorazioni_PreventiviRighe]
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheMateriali_Componente] FOREIGN KEY([IdRigaPreventivo], [IdRigaCompPrev])
REFERENCES [dbo].[PreventiviRigheComponenti] ([IdRigaPreventivo], [IdRigaCompPrev])
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali] CHECK CONSTRAINT [FK_PreventiviRigheMateriali_Componente]
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheMateriali_Fornitori] FOREIGN KEY([IdFornitoreSuggerito])
REFERENCES [dbo].[Fornitori] ([IdFornitore])
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali] CHECK CONSTRAINT [FK_PreventiviRigheMateriali_Fornitori]
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviRigheMateriali_PreventiviRighe] FOREIGN KEY([IdRigaPreventivo])
REFERENCES [dbo].[PreventiviRighe] ([IdRigaPreventivo])
GO

ALTER TABLE [dbo].[PreventiviRigheMateriali] CHECK CONSTRAINT [FK_PreventiviRigheMateriali_PreventiviRighe]
GO

ALTER TABLE [dbo].[PreventiviVarianti]  WITH CHECK ADD  CONSTRAINT [FK_PreventiviVarianti_Preventivi] FOREIGN KEY([IdPreventivo])
REFERENCES [dbo].[Preventivi] ([IdPreventivo])
GO

ALTER TABLE [dbo].[PreventiviVarianti] CHECK CONSTRAINT [FK_PreventiviVarianti_Preventivi]
GO

ALTER TABLE [dbo].[ProblematicheStandard]  WITH CHECK ADD  CONSTRAINT [FK_ProblematicheStandard_Tipi] FOREIGN KEY([IdTipoProblematica])
REFERENCES [dbo].[TipiProblematicheQualita] ([IdTipoProblematica])
GO

ALTER TABLE [dbo].[ProblematicheStandard] CHECK CONSTRAINT [FK_ProblematicheStandard_Tipi]
GO

ALTER TABLE [dbo].[RichiesteClienti]  WITH CHECK ADD  CONSTRAINT [FK_RichiesteClienti_Clienti] FOREIGN KEY([IdCliente])
REFERENCES [dbo].[Clienti] ([IdCliente])
GO

ALTER TABLE [dbo].[RichiesteClienti] CHECK CONSTRAINT [FK_RichiesteClienti_Clienti]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori]  WITH CHECK ADD  CONSTRAINT [FK_RichiesteOffertaFornitori_Fornitori] FOREIGN KEY([IdFornitore])
REFERENCES [dbo].[Fornitori] ([IdFornitore])
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori] CHECK CONSTRAINT [FK_RichiesteOffertaFornitori_Fornitori]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori]  WITH CHECK ADD  CONSTRAINT [FK_RichiesteOffertaFornitori_Preventivi] FOREIGN KEY([IdPreventivo])
REFERENCES [dbo].[Preventivi] ([IdPreventivo])
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori] CHECK CONSTRAINT [FK_RichiesteOffertaFornitori_Preventivi]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori]  WITH CHECK ADD  CONSTRAINT [FK_RichiesteOffertaFornitori_RighePreventivo] FOREIGN KEY([IdRigaPreventivo])
REFERENCES [dbo].[PreventiviRighe] ([IdRigaPreventivo])
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitori] CHECK CONSTRAINT [FK_RichiesteOffertaFornitori_RighePreventivo]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [FK_RichiesteOffertaFornitoriRighe_MaterialePreventivo] FOREIGN KEY([IdRigaMatPrev])
REFERENCES [dbo].[PreventiviRigheMateriali] ([IdRigaMatPrev])
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe] CHECK CONSTRAINT [FK_RichiesteOffertaFornitoriRighe_MaterialePreventivo]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [FK_RichiesteOffertaFornitoriRighe_Materiali] FOREIGN KEY([IdMateriale])
REFERENCES [dbo].[Materiali] ([IdMateriale])
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe] CHECK CONSTRAINT [FK_RichiesteOffertaFornitoriRighe_Materiali]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [FK_RichiesteOffertaFornitoriRighe_RigaPreventivo] FOREIGN KEY([IdRigaPreventivo])
REFERENCES [dbo].[PreventiviRighe] ([IdRigaPreventivo])
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe] CHECK CONSTRAINT [FK_RichiesteOffertaFornitoriRighe_RigaPreventivo]
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe]  WITH CHECK ADD  CONSTRAINT [FK_RichiesteOffertaFornitoriRighe_Testata] FOREIGN KEY([IdRichiestaOfferta])
REFERENCES [dbo].[RichiesteOffertaFornitori] ([IdRichiestaOfferta])
GO

ALTER TABLE [dbo].[RichiesteOffertaFornitoriRighe] CHECK CONSTRAINT [FK_RichiesteOffertaFornitoriRighe_Testata]
GO

ALTER TABLE [dbo].[UtentiRuoli]  WITH CHECK ADD  CONSTRAINT [FK_UtentiRuoli_RuoliApplicazione] FOREIGN KEY([IdRuolo])
REFERENCES [dbo].[RuoliApplicazione] ([IdRuolo])
GO

ALTER TABLE [dbo].[UtentiRuoli] CHECK CONSTRAINT [FK_UtentiRuoli_RuoliApplicazione]
GO

ALTER TABLE [dbo].[UtentiRuoli]  WITH CHECK ADD  CONSTRAINT [FK_UtentiRuoli_UtentiApplicazione] FOREIGN KEY([IdUtente])
REFERENCES [dbo].[UtentiApplicazione] ([IdUtente])
GO

ALTER TABLE [dbo].[UtentiRuoli] CHECK CONSTRAINT [FK_UtentiRuoli_UtentiApplicazione]
GO
