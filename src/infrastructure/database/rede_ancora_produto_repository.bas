Imports mod_tobject
Imports rede_ancora_produto_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_produto_repository
    Class RedeAncoraProdutoRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaProdutoQualificada()
        End Function

        Private Function ListaColunasSelect() As String
            ListaColunasSelect = "Cna, CatalogoId, Csa, Cnl, CodigoReferencia, CodeEdi, CodeManufacturer, " +_
                "NomeProduto, NomeErp, InformacoesAdicionais, InformacoesComplementares, AdditionalDescription, " +_
                "PontoCriticoAtencao, Dimensoes, CodMarca, CodMarcaErp, NomeMarca, CodLinha, NomeLinha, " +_
                "CodFamilia, NomeFamilia, CodFabricante, Ean, Gtin, Ncm, Cest, Origem, OrigemLabel, Anp, AnpLabel, " +_
                "PesoLiquido, PesoBruto, Volume, Litros, Tamanho, Material, Tipo, MedidaVenda, GarantiaDias, " +_
                "FracaoFabrica, FracaoLoja, Status, ErpHandle, Leadtime, Ativo, Descontinuado, Bloqueado, " +_
                "Confiavel, Sugerido, Lancamento, OnDemand, OnDemandLabel, MotivoDescontinuado, " +_
                "ParcialmenteSimilar, HasRestrictions, PrazoEspecial, DataAtualizacao"
        End Function

        Private Function SqlSelectBase() As String
            SqlSelectBase = "SELECT " & me.ListaColunasSelect() & " FROM " & me.Tabela()
        End Function

        Private Function SqlSelectPorCna() As String
            SqlSelectPorCna = me.SqlSelectBase() & " WHERE Cna = :Cna"
        End Function

        Private Function SqlExistePorCna() As String
            SqlExistePorCna = "SELECT CASE " +_
                "           WHEN COUNT(Cna) > 0 THEN " & SqlHelper.SqlText("true") & " " +_
                "           ELSE " & SqlHelper.SqlText("false") & " " +_
                "       END result " +_
                "FROM " & me.Tabela() & " " +_
                "WHERE Cna = :Cna"
        End Function

        Private Function SqlCampoInteiroOuNull(pParametro As String) As String
            SqlCampoInteiroOuNull = "CASE WHEN :" & pParametro & " = 0 THEN NULL ELSE :" & pParametro & " END"
        End Function

        Private Function SqlCampoDecimalOuNull(pParametro As String) As String
            SqlCampoDecimalOuNull = "CASE WHEN :" & pParametro & " = 0 THEN NULL ELSE :" & pParametro & " END"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = "INSERT INTO " & me.Tabela() & " (" & me.ListaColunasSelect() & ") VALUES (" +_
                ":Cna, " & me.SqlCampoInteiroOuNull("CatalogoId") & ", :Csa, :Cnl, :CodigoReferencia, :CodeEdi, :CodeManufacturer, " +_
                ":NomeProduto, :NomeErp, :InformacoesAdicionais, :InformacoesComplementares, :AdditionalDescription, " +_
                ":PontoCriticoAtencao, :Dimensoes, " & me.SqlCampoInteiroOuNull("CodMarca") & ", " & me.SqlCampoInteiroOuNull("CodMarcaErp") & ", :NomeMarca, " +_
                me.SqlCampoInteiroOuNull("CodLinha") & ", :NomeLinha, " & me.SqlCampoInteiroOuNull("CodFamilia") & ", :NomeFamilia, " +_
                me.SqlCampoInteiroOuNull("CodFabricante") & ", :Ean, :Gtin, :Ncm, :Cest, :Origem, :OrigemLabel, " +_
                me.SqlCampoInteiroOuNull("Anp") & ", :AnpLabel, " +_
                me.SqlCampoDecimalOuNull("PesoLiquido") & ", " & me.SqlCampoDecimalOuNull("PesoBruto") & ", " +_
                me.SqlCampoDecimalOuNull("Volume") & ", " & me.SqlCampoDecimalOuNull("Litros") & ", :Tamanho, :Material, " +_
                me.SqlCampoInteiroOuNull("Tipo") & ", :MedidaVenda, " & me.SqlCampoInteiroOuNull("GarantiaDias") & ", " +_
                me.SqlCampoInteiroOuNull("FracaoFabrica") & ", " & me.SqlCampoInteiroOuNull("FracaoLoja") & ", " +_
                me.SqlCampoInteiroOuNull("Status") & ", " & me.SqlCampoInteiroOuNull("ErpHandle") & ", " +_
                me.SqlCampoInteiroOuNull("Leadtime") & ", :Ativo, :Descontinuado, :Bloqueado, :Confiavel, :Sugerido, " +_
                ":Lancamento, :OnDemand, :OnDemandLabel, :MotivoDescontinuado, :ParcialmenteSimilar, :HasRestrictions, " +_
                ":PrazoEspecial, :DataAtualizacao)"
        End Function

        Private Function SqlUpdate() As String
            SqlUpdate = "UPDATE " & me.Tabela() & " SET " +_
                "CatalogoId = " & me.SqlCampoInteiroOuNull("CatalogoId") & ", " +_
                "Csa = :Csa, Cnl = :Cnl, CodigoReferencia = :CodigoReferencia, CodeEdi = :CodeEdi, " +_
                "CodeManufacturer = :CodeManufacturer, NomeProduto = :NomeProduto, NomeErp = :NomeErp, " +_
                "InformacoesAdicionais = :InformacoesAdicionais, InformacoesComplementares = :InformacoesComplementares, " +_
                "AdditionalDescription = :AdditionalDescription, PontoCriticoAtencao = :PontoCriticoAtencao, " +_
                "Dimensoes = :Dimensoes, CodMarca = " & me.SqlCampoInteiroOuNull("CodMarca") & ", " +_
                "CodMarcaErp = " & me.SqlCampoInteiroOuNull("CodMarcaErp") & ", NomeMarca = :NomeMarca, " +_
                "CodLinha = " & me.SqlCampoInteiroOuNull("CodLinha") & ", NomeLinha = :NomeLinha, " +_
                "CodFamilia = " & me.SqlCampoInteiroOuNull("CodFamilia") & ", NomeFamilia = :NomeFamilia, " +_
                "CodFabricante = " & me.SqlCampoInteiroOuNull("CodFabricante") & ", Ean = :Ean, Gtin = :Gtin, Ncm = :Ncm, " +_
                "Cest = :Cest, Origem = :Origem, OrigemLabel = :OrigemLabel, Anp = " & me.SqlCampoInteiroOuNull("Anp") & ", " +_
                "AnpLabel = :AnpLabel, PesoLiquido = " & me.SqlCampoDecimalOuNull("PesoLiquido") & ", " +_
                "PesoBruto = " & me.SqlCampoDecimalOuNull("PesoBruto") & ", Volume = " & me.SqlCampoDecimalOuNull("Volume") & ", " +_
                "Litros = " & me.SqlCampoDecimalOuNull("Litros") & ", Tamanho = :Tamanho, Material = :Material, " +_
                "Tipo = " & me.SqlCampoInteiroOuNull("Tipo") & ", MedidaVenda = :MedidaVenda, " +_
                "GarantiaDias = " & me.SqlCampoInteiroOuNull("GarantiaDias") & ", " +_
                "FracaoFabrica = " & me.SqlCampoInteiroOuNull("FracaoFabrica") & ", " +_
                "FracaoLoja = " & me.SqlCampoInteiroOuNull("FracaoLoja") & ", Status = " & me.SqlCampoInteiroOuNull("Status") & ", " +_
                "ErpHandle = " & me.SqlCampoInteiroOuNull("ErpHandle") & ", Leadtime = " & me.SqlCampoInteiroOuNull("Leadtime") & ", " +_
                "Ativo = :Ativo, Descontinuado = :Descontinuado, Bloqueado = :Bloqueado, Confiavel = :Confiavel, " +_
                "Sugerido = :Sugerido, Lancamento = :Lancamento, OnDemand = :OnDemand, OnDemandLabel = :OnDemandLabel, " +_
                "MotivoDescontinuado = :MotivoDescontinuado, ParcialmenteSimilar = :ParcialmenteSimilar, " +_
                "HasRestrictions = :HasRestrictions, PrazoEspecial = :PrazoEspecial, DataAtualizacao = :DataAtualizacao " +_
                "WHERE Cna = :Cna"
        End Function

        Private Function SqlDesativarPorCna() As String
            SqlDesativarPorCna = "UPDATE " & me.Tabela() & " SET Ativo = " & SqlHelper.SqlText("N") +_
                ", DataAtualizacao = :DataAtualizacao WHERE Cna = :Cna"
        End Function

        Private Function Truncar(pValor As String, pMax As Integer) As String
            If pMax <= 0 Then
                Truncar = ""
                Exit Function
            End If

            If Len(pValor) <= pMax Then
                Truncar = pValor
            Else
                Truncar = Mid(pValor, 1, pMax)
            End If
        End Function

        Private Function FlagOuVazio(pValor As String) As String
            If pValor = "S" Then
                FlagOuVazio = "S"
            Else
                If pValor = "N" Then
                    FlagOuVazio = "N"
                Else
                    FlagOuVazio = ""
                End If
            End If
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraProdutoModel)
            pItem.Cna = pQuery.Field("Cna").AsInteger
            pItem.CatalogoId = pQuery.Field("CatalogoId").AsInteger
            pItem.Csa = pQuery.Field("Csa").AsString
            pItem.Cnl = pQuery.Field("Cnl").AsString
            pItem.CodigoReferencia = pQuery.Field("CodigoReferencia").AsString
            pItem.CodeEdi = pQuery.Field("CodeEdi").AsString
            pItem.CodeManufacturer = pQuery.Field("CodeManufacturer").AsString
            pItem.NomeProduto = pQuery.Field("NomeProduto").AsString
            pItem.NomeErp = pQuery.Field("NomeErp").AsString
            pItem.InformacoesAdicionais = pQuery.Field("InformacoesAdicionais").AsString
            pItem.InformacoesComplementares = pQuery.Field("InformacoesComplementares").AsString
            pItem.AdditionalDescription = pQuery.Field("AdditionalDescription").AsString
            pItem.PontoCriticoAtencao = pQuery.Field("PontoCriticoAtencao").AsString
            pItem.Dimensoes = pQuery.Field("Dimensoes").AsString
            pItem.CodMarca = pQuery.Field("CodMarca").AsInteger
            pItem.CodMarcaErp = pQuery.Field("CodMarcaErp").AsInteger
            pItem.NomeMarca = pQuery.Field("NomeMarca").AsString
            pItem.CodLinha = pQuery.Field("CodLinha").AsInteger
            pItem.NomeLinha = pQuery.Field("NomeLinha").AsString
            pItem.CodFamilia = pQuery.Field("CodFamilia").AsInteger
            pItem.NomeFamilia = pQuery.Field("NomeFamilia").AsString
            pItem.CodFabricante = pQuery.Field("CodFabricante").AsInteger
            pItem.Ean = pQuery.Field("Ean").AsString
            pItem.Gtin = pQuery.Field("Gtin").AsString
            pItem.Ncm = pQuery.Field("Ncm").AsString
            pItem.Cest = pQuery.Field("Cest").AsString
            pItem.Origem = pQuery.Field("Origem").AsString
            pItem.OrigemLabel = pQuery.Field("OrigemLabel").AsString
            pItem.Anp = pQuery.Field("Anp").AsInteger
            pItem.AnpLabel = pQuery.Field("AnpLabel").AsString
            pItem.PesoLiquido = pQuery.Field("PesoLiquido").AsFloat
            pItem.PesoBruto = pQuery.Field("PesoBruto").AsFloat
            pItem.Volume = pQuery.Field("Volume").AsFloat
            pItem.Litros = pQuery.Field("Litros").AsFloat
            pItem.Tamanho = pQuery.Field("Tamanho").AsString
            pItem.Material = pQuery.Field("Material").AsString
            pItem.Tipo = pQuery.Field("Tipo").AsInteger
            pItem.MedidaVenda = pQuery.Field("MedidaVenda").AsString
            pItem.GarantiaDias = pQuery.Field("GarantiaDias").AsInteger
            pItem.FracaoFabrica = pQuery.Field("FracaoFabrica").AsInteger
            pItem.FracaoLoja = pQuery.Field("FracaoLoja").AsInteger
            pItem.Status = pQuery.Field("Status").AsInteger
            pItem.ErpHandle = pQuery.Field("ErpHandle").AsInteger
            pItem.Leadtime = pQuery.Field("Leadtime").AsInteger
            pItem.Ativo = pQuery.Field("Ativo").AsString
            pItem.Descontinuado = pQuery.Field("Descontinuado").AsString
            pItem.Bloqueado = pQuery.Field("Bloqueado").AsString
            pItem.Confiavel = pQuery.Field("Confiavel").AsString
            pItem.Sugerido = pQuery.Field("Sugerido").AsString
            pItem.Lancamento = pQuery.Field("Lancamento").AsString
            pItem.OnDemand = pQuery.Field("OnDemand").AsString
            pItem.OnDemandLabel = pQuery.Field("OnDemandLabel").AsString
            pItem.MotivoDescontinuado = pQuery.Field("MotivoDescontinuado").AsString
            pItem.ParcialmenteSimilar = pQuery.Field("ParcialmenteSimilar").AsString
            pItem.HasRestrictions = pQuery.Field("HasRestrictions").AsString
            pItem.PrazoEspecial = pQuery.Field("PrazoEspecial").AsString
            pItem.DataAtualizacao = pQuery.Field("DataAtualizacao").AsDateTime
        End Sub

        Private Sub BindParams(pQuery As SQL.Command, pModel As RedeAncoraProdutoModel)
            pQuery.Param("Cna").AsInteger = pModel.Cna
            pQuery.Param("CatalogoId").AsInteger = pModel.CatalogoId
            pQuery.Param("Csa").AsString = me.Truncar(pModel.Csa, 30)
            pQuery.Param("Cnl").AsString = me.Truncar(pModel.Cnl, 30)
            pQuery.Param("CodigoReferencia").AsString = me.Truncar(pModel.CodigoReferencia, 30)
            pQuery.Param("CodeEdi").AsString = me.Truncar(pModel.CodeEdi, 30)
            pQuery.Param("CodeManufacturer").AsString = me.Truncar(pModel.CodeManufacturer, 30)
            pQuery.Param("NomeProduto").AsString = me.Truncar(pModel.NomeProduto, 255)
            pQuery.Param("NomeErp").AsString = me.Truncar(pModel.NomeErp, 255)
            pQuery.Param("InformacoesAdicionais").AsString = me.Truncar(pModel.InformacoesAdicionais, 2000)
            pQuery.Param("InformacoesComplementares").AsString = me.Truncar(pModel.InformacoesComplementares, 2000)
            pQuery.Param("AdditionalDescription").AsString = me.Truncar(pModel.AdditionalDescription, 2000)
            pQuery.Param("PontoCriticoAtencao").AsString = me.Truncar(pModel.PontoCriticoAtencao, 255)
            pQuery.Param("Dimensoes").AsString = me.Truncar(pModel.Dimensoes, 255)
            pQuery.Param("CodMarca").AsInteger = pModel.CodMarca
            pQuery.Param("CodMarcaErp").AsInteger = pModel.CodMarcaErp
            pQuery.Param("NomeMarca").AsString = me.Truncar(pModel.NomeMarca, 120)
            pQuery.Param("CodLinha").AsInteger = pModel.CodLinha
            pQuery.Param("NomeLinha").AsString = me.Truncar(pModel.NomeLinha, 120)
            pQuery.Param("CodFamilia").AsInteger = pModel.CodFamilia
            pQuery.Param("NomeFamilia").AsString = me.Truncar(pModel.NomeFamilia, 120)
            pQuery.Param("CodFabricante").AsInteger = pModel.CodFabricante
            pQuery.Param("Ean").AsString = me.Truncar(pModel.Ean, 20)
            pQuery.Param("Gtin").AsString = me.Truncar(pModel.Gtin, 20)
            pQuery.Param("Ncm").AsString = me.Truncar(pModel.Ncm, 30)
            pQuery.Param("Cest").AsString = me.Truncar(pModel.Cest, 20)
            pQuery.Param("Origem").AsString = me.Truncar(pModel.Origem, 10)
            pQuery.Param("OrigemLabel").AsString = me.Truncar(pModel.OrigemLabel, 200)
            pQuery.Param("Anp").AsInteger = pModel.Anp
            pQuery.Param("AnpLabel").AsString = me.Truncar(pModel.AnpLabel, 200)
            pQuery.Param("PesoLiquido").AsFloat = pModel.PesoLiquido
            pQuery.Param("PesoBruto").AsFloat = pModel.PesoBruto
            pQuery.Param("Volume").AsFloat = pModel.Volume
            pQuery.Param("Litros").AsFloat = pModel.Litros
            pQuery.Param("Tamanho").AsString = me.Truncar(pModel.Tamanho, 60)
            pQuery.Param("Material").AsString = me.Truncar(pModel.Material, 120)
            pQuery.Param("Tipo").AsInteger = pModel.Tipo
            pQuery.Param("MedidaVenda").AsString = me.Truncar(pModel.MedidaVenda, 20)
            pQuery.Param("GarantiaDias").AsInteger = pModel.GarantiaDias
            pQuery.Param("FracaoFabrica").AsInteger = pModel.FracaoFabrica
            pQuery.Param("FracaoLoja").AsInteger = pModel.FracaoLoja
            pQuery.Param("Status").AsInteger = pModel.Status
            pQuery.Param("ErpHandle").AsInteger = pModel.ErpHandle
            pQuery.Param("Leadtime").AsInteger = pModel.Leadtime
            pQuery.Param("Ativo").AsString = me.FlagOuVazio(pModel.Ativo)
            pQuery.Param("Descontinuado").AsString = me.FlagOuVazio(pModel.Descontinuado)
            pQuery.Param("Bloqueado").AsString = me.FlagOuVazio(pModel.Bloqueado)
            pQuery.Param("Confiavel").AsString = me.FlagOuVazio(pModel.Confiavel)
            pQuery.Param("Sugerido").AsString = me.FlagOuVazio(pModel.Sugerido)
            pQuery.Param("Lancamento").AsString = me.FlagOuVazio(pModel.Lancamento)
            pQuery.Param("OnDemand").AsString = me.FlagOuVazio(pModel.OnDemand)
            pQuery.Param("OnDemandLabel").AsString = me.Truncar(pModel.OnDemandLabel, 120)
            pQuery.Param("MotivoDescontinuado").AsString = me.Truncar(pModel.MotivoDescontinuado, 255)
            pQuery.Param("ParcialmenteSimilar").AsString = me.FlagOuVazio(pModel.ParcialmenteSimilar)
            pQuery.Param("HasRestrictions").AsString = me.FlagOuVazio(pModel.HasRestrictions)
            pQuery.Param("PrazoEspecial").AsString = me.FlagOuVazio(pModel.PrazoEspecial)
            pQuery.Param("DataAtualizacao").AsDateTime = pModel.DataAtualizacao
        End Sub

        Function ExistePorCna(pCna As Integer) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlExistePorCna())
                _query.Param("Cna").AsInteger = pCna
                _query.Open()
                ExistePorCna = _query.Field("result").AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao verificar Integracao.RedeAncoraProduto por Cna", "9171")
            End Try
        End Function

        Function TryObterPorCna(pCna As Integer, pItem As RedeAncoraProdutoModel) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCna())
                _query.Param("Cna").AsInteger = pCna
                _query.Open()

                If _query.EOF Then
                    TryObterPorCna = False
                Else
                    me.Mapear(_query, pItem)
                    TryObterPorCna = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar Integracao.RedeAncoraProduto por Cna", "9172")
            End Try
        End Function

        Function ObterPorCna(pCna As Integer) As RedeAncoraProdutoModel
            Dim _item As New RedeAncoraProdutoModel()

            If Not me.TryObterPorCna(pCna, _item) Then
                _item.Free()
                Throw New System.Exception("Integracao.RedeAncoraProduto nao encontrado para CNA " & pCna.ToString() & ". Codigo: 9173")
            End If

            ObterPorCna = _item
        End Function

        Sub Salvar(pModel As RedeAncoraProdutoModel)
            me.SalvarComTransacao(pModel, True)
        End Sub

        Sub SalvarSemTransacao(pModel As RedeAncoraProdutoModel)
            me.SalvarComTransacao(pModel, False)
        End Sub

        Private Sub SalvarComTransacao(pModel As RedeAncoraProdutoModel, pUsarTransacao As Boolean)
            If me.ExistePorCna(pModel.Cna) Then
                me.AtualizarComTransacao(pModel, pUsarTransacao)
            Else
                me.InserirComTransacao(pModel, pUsarTransacao)
            End If
        End Sub

        Private Sub InserirComTransacao(pModel As RedeAncoraProdutoModel, pUsarTransacao As Boolean)
            pModel.Validate()
            pModel.DataAtualizacao = DateTime()

            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraProduto Insert")
                End If

                _query = SqlHelper.OpenQuery(me.SqlInsert())
                me.BindParams(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    _tx.AutoCommit()
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    If Assigned(_tx) Then
                        _tx.Rollback()
                    End If
                End If

                Throw New System.Exception("Erro ao inserir Integracao.RedeAncoraProduto: " & Char(13) & ex._getMessage())
            End Try
        End Sub

        Private Sub AtualizarComTransacao(pModel As RedeAncoraProdutoModel, pUsarTransacao As Boolean)
            pModel.Validate()
            pModel.DataAtualizacao = DateTime()

            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraProduto Update")
                End If

                _query = SqlHelper.OpenQuery(me.SqlUpdate())
                me.BindParams(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    _tx.AutoCommit()
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    If Assigned(_tx) Then
                        _tx.Rollback()
                    End If
                End If

                Throw New System.Exception("Erro ao atualizar Integracao.RedeAncoraProduto: " & Char(13) & ex._getMessage())
            End Try
        End Sub

        Sub DesativarPorCna(pCna As Integer)
            me.DesativarPorCnaComTransacao(pCna, True)
        End Sub

        Sub DesativarPorCnaSemTransacao(pCna As Integer)
            me.DesativarPorCnaComTransacao(pCna, False)
        End Sub

        Private Sub DesativarPorCnaComTransacao(pCna As Integer, pUsarTransacao As Boolean)
            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraProduto Desativar Cna")
                End If

                _query = SqlHelper.OpenQuery(me.SqlDesativarPorCna())
                _query.Param("Cna").AsInteger = pCna
                _query.Param("DataAtualizacao").AsDateTime = DateTime()
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    _tx.AutoCommit()
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    If Assigned(_tx) Then
                        _tx.Rollback()
                    End If
                End If

                Throw New System.Exception("Erro ao desativar Integracao.RedeAncoraProduto por Cna: " & Char(13) & ex._getMessage())
            End Try
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            Try
                If Not me.Disposed Then
                    me.Dispose()
                End If

                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Erro ao liberar RedeAncoraProdutoRepository: " & Char(13) & ex._getMessage())
            End Try
        End Sub

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
