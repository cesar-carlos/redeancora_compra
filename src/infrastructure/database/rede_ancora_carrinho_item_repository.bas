Imports mod_tobject
Imports rede_ancora_carrinho_item_model
Imports rede_ancora_carrinho_itens_model
Imports integracao_schema
Imports sql_helper
Imports transactions
Imports try_parser

Namespace rede_ancora_carrinho_item_repository
    Class RedeAncoraCarrinhoItemRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaCarrinhoItemQualificada()
        End Function

        Private Function DataLancamentoSemAuditoria() As TDateTime
            DataLancamentoSemAuditoria = Parser.StringToDate("01/01/1900")
        End Function

        Private Function SqlCampoInteiroOuNull(pParametro As String) As String
            SqlCampoInteiroOuNull = "CASE WHEN :" + pParametro + " = 0 THEN NULL ELSE :" + pParametro + " END"
        End Function

        Private Function SqlCampoTextoOuNull(pParametro As String) As String
            SqlCampoTextoOuNull = "CASE WHEN LTRIM(RTRIM(:" + pParametro + ")) = '' THEN NULL ELSE :" + pParametro + " END"
        End Function

        Private Function SqlCampoDecimalOuNull(pParametro As String) As String
            SqlCampoDecimalOuNull = "CASE WHEN :" + pParametro + " = 0 THEN NULL ELSE :" + pParametro + " END"
        End Function

        Private Function SqlSelectPorCarrinho() As String
            SqlSelectPorCarrinho = $"SELECT CodCarrinho, " +_
            $"       Item, " +_
            $"       IdItemApi, " +_
            $"       Cna, " +_
            $"       ISNULL(CodCentroDistribuicao, 0) CodCentroDistribuicao, " +_
            $"       ISNULL(CodCondicaoPagamento, 0) CodCondicaoPagamento, " +_
            $"       ISNULL(DescricaoCondicaoPagamento, '') DescricaoCondicaoPagamento, " +_
            $"       ISNULL(CodProduto, 0) CodProduto, " +_
            $"       ISNULL(CodigoReferenciaFabricante, '') CodigoReferenciaFabricante, " +_
            $"       ISNULL(Descricao, '') Descricao, " +_
            $"       ISNULL(CodModalidade, 0) CodModalidade, " +_
            $"       Quantidade, " +_
            $"       ISNULL(PrecoUnitario, 0) PrecoUnitario, " +_
            $"       ISNULL(ImpostoUnitario, 0) ImpostoUnitario, " +_
            $"       ISNULL(CodUsuario, 0) CodUsuario, " +_
            $"       ISNULL(NomeUsuario, '') NomeUsuario, " +_
            $"       DataLancamento, " +_
            $"       ISNULL(HoraLancamento, '') HoraLancamento, " +_
            $"       ISNULL(EstacaoTrabalho, '') EstacaoTrabalho " +_
            $"FROM {me.Tabela()} " +_
            $"WHERE CodCarrinho = :CodCarrinho " +_
            $"ORDER BY Item"
        End Function

        Private Function SqlDeletePorCarrinho() As String
            SqlDeletePorCarrinho = $"DELETE FROM {me.Tabela()} WHERE CodCarrinho = :CodCarrinho"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = $"INSERT INTO {me.Tabela()} (CodCarrinho, Item, IdItemApi, Cna, CodCentroDistribuicao, CodCondicaoPagamento, DescricaoCondicaoPagamento, CodProduto, CodigoReferenciaFabricante, Descricao, CodModalidade, Quantidade, PrecoUnitario, ImpostoUnitario, CodUsuario, NomeUsuario, DataLancamento, HoraLancamento, EstacaoTrabalho) " +_
            $"VALUES (:CodCarrinho, :Item, :IdItemApi, :Cna, " + me.SqlCampoInteiroOuNull("CodCentroDistribuicao") + ", " + me.SqlCampoInteiroOuNull("CodCondicaoPagamento") + ", " + me.SqlCampoTextoOuNull("DescricaoCondicaoPagamento") + ", " + me.SqlCampoInteiroOuNull("CodProduto") + ", " + me.SqlCampoTextoOuNull("CodigoReferenciaFabricante") + ", " + me.SqlCampoTextoOuNull("Descricao") + ", " + me.SqlCampoInteiroOuNull("CodModalidade") + ", :Quantidade, " + me.SqlCampoDecimalOuNull("PrecoUnitario") + ", " + me.SqlCampoDecimalOuNull("ImpostoUnitario") + ", :CodUsuario, :NomeUsuario, :DataLancamento, :HoraLancamento, :EstacaoTrabalho)"
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraCarrinhoItemModel)
            pItem.CodCarrinho = pQuery.Field("CodCarrinho").AsInteger
            pItem.Item = pQuery.Field("Item").AsString
            pItem.IdItemApi = pQuery.Field("IdItemApi").AsInteger
            pItem.Cna = pQuery.Field("Cna").AsInteger
            pItem.CodCentroDistribuicao = pQuery.Field("CodCentroDistribuicao").AsInteger
            pItem.CodCondicaoPagamento = pQuery.Field("CodCondicaoPagamento").AsInteger
            pItem.DescricaoCondicaoPagamento = pQuery.Field("DescricaoCondicaoPagamento").AsString
            pItem.CodProduto = pQuery.Field("CodProduto").AsInteger
            pItem.CodigoReferenciaFabricante = pQuery.Field("CodigoReferenciaFabricante").AsString
            pItem.Descricao = pQuery.Field("Descricao").AsString
            pItem.CodModalidade = pQuery.Field("CodModalidade").AsInteger
            pItem.Quantidade = pQuery.Field("Quantidade").AsInteger
            pItem.PrecoUnitario = pQuery.Field("PrecoUnitario").AsFloat
            pItem.ImpostoUnitario = pQuery.Field("ImpostoUnitario").AsFloat
            pItem.CodUsuario = pQuery.Field("CodUsuario").AsInteger
            pItem.NomeUsuario = pQuery.Field("NomeUsuario").AsString
            pItem.HoraLancamento = pQuery.Field("HoraLancamento").AsString
            pItem.EstacaoTrabalho = pQuery.Field("EstacaoTrabalho").AsString

            If pItem.CodUsuario > 0 Then
                pItem.DataLancamento = pQuery.Field("DataLancamento").AsDateTime
            Else
                pItem.LimparAuditoriaLancamento()
            End If
        End Sub

        Private Sub BindInsertParams(pQuery As SQL.Command, pItem As RedeAncoraCarrinhoItemModel)
            pQuery.Param("CodCarrinho").AsInteger = pItem.CodCarrinho
            pQuery.Param("Item").AsString = pItem.Item
            pQuery.Param("IdItemApi").AsInteger = pItem.IdItemApi
            pQuery.Param("Cna").AsInteger = pItem.Cna
            pQuery.Param("CodCentroDistribuicao").AsInteger = pItem.CodCentroDistribuicao
            pQuery.Param("CodCondicaoPagamento").AsInteger = pItem.CodCondicaoPagamento
            pQuery.Param("DescricaoCondicaoPagamento").AsString = pItem.DescricaoCondicaoPagamento
            pQuery.Param("CodProduto").AsInteger = pItem.CodProduto
            pQuery.Param("CodigoReferenciaFabricante").AsString = pItem.CodigoReferenciaFabricante
            pQuery.Param("Descricao").AsString = pItem.Descricao
            pQuery.Param("CodModalidade").AsInteger = pItem.CodModalidade
            pQuery.Param("Quantidade").AsInteger = pItem.Quantidade
            pQuery.Param("PrecoUnitario").AsFloat = pItem.PrecoUnitario
            pQuery.Param("ImpostoUnitario").AsFloat = pItem.ImpostoUnitario
            pQuery.Param("CodUsuario").AsInteger = pItem.CodUsuario
            pQuery.Param("NomeUsuario").AsString = pItem.NomeUsuario
            pQuery.Param("HoraLancamento").AsString = pItem.HoraLancamento
            pQuery.Param("EstacaoTrabalho").AsString = pItem.EstacaoTrabalho

            If pItem.PossuiAuditoriaLancamento() Then
                pQuery.Param("DataLancamento").AsDateTime = pItem.DataLancamento
            Else
                pQuery.Param("DataLancamento").AsDateTime = me.DataLancamentoSemAuditoria()
            End If
        End Sub

        Function ListarPorCarrinho(pCodCarrinho As Integer) As RedeAncoraCarrinhoItensModel
            Dim _result As New RedeAncoraCarrinhoItensModel()
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCarrinho())
                _query.Param("CodCarrinho").AsInteger = pCodCarrinho
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraCarrinhoItemModel()
                    me.Mapear(_query, _item)
                    _result.Push(_item)
                    _query.Next()
                Wend

                SqlHelper.ReleaseQuery(_query)
                ListarPorCarrinho = _result
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _result.Free()
                SqlHelper.HandleQueryError(ex, "Erro ao listar Integracao.RedeAncoraCarrinhoItem", "9141")
            End Try
        End Function

        Sub SubstituirPorCarrinho(pCodCarrinho As Integer, pItens As RedeAncoraCarrinhoItensModel)
            me.SubstituirPorCarrinhoComTransacao(pCodCarrinho, pItens, True)
        End Sub

        Sub SubstituirPorCarrinhoSemTransacao(pCodCarrinho As Integer, pItens As RedeAncoraCarrinhoItensModel)
            me.SubstituirPorCarrinhoComTransacao(pCodCarrinho, pItens, False)
        End Sub

        Private Sub SubstituirPorCarrinhoComTransacao(pCodCarrinho As Integer, pItens As RedeAncoraCarrinhoItensModel, pUsarTransacao As Boolean)
            Dim _tx As Transaction = NULL
            Dim _deleteQuery As SQL.Command = NULL
            Dim _insertQuery As SQL.Command = NULL
            Dim _i As Integer

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraCarrinhoItem Replace")
                End If

                _deleteQuery = SqlHelper.OpenQuery(me.SqlDeletePorCarrinho())
                _deleteQuery.Param("CodCarrinho").AsInteger = pCodCarrinho
                _deleteQuery.ExecSQL()
                SqlHelper.ReleaseQuery(_deleteQuery)
                _deleteQuery = NULL

                For _i = 0 To pItens.Length - 1
                    Dim _item As RedeAncoraCarrinhoItemModel = pItens.Take(_i)
                    _item.CodCarrinho = pCodCarrinho
                    _item.Validate()

                    _insertQuery = SqlHelper.OpenQuery(me.SqlInsert())
                    me.BindInsertParams(_insertQuery, _item)
                    _insertQuery.ExecSQL()
                    SqlHelper.ReleaseQuery(_insertQuery)
                    _insertQuery = NULL
                Next

                If pUsarTransacao Then
                    _tx.AutoCommit()
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_deleteQuery)
                SqlHelper.ReleaseQuery(_insertQuery)

                If pUsarTransacao And Assigned(_tx) Then
                    _tx.Rollback()
                End If

                Throw New System.Exception("Erro ao substituir Integracao.RedeAncoraCarrinhoItem: " + Char(13) + ex._getMessage())
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
                Throw New System.Exception("Erro ao liberar RedeAncoraCarrinhoItemRepository: " + Char(13) + ex._getMessage())
            End Try
        End Sub
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
