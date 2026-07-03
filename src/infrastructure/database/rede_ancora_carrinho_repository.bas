Imports mod_tobject
Imports rede_ancora_carrinho_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_carrinho_repository
    Class RedeAncoraCarrinhoRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaCarrinhoQualificada()
        End Function

        Private Function SqlSelectPorCodCarrinho() As String
            SqlSelectPorCodCarrinho = $"SELECT CodCarrinho, " +_
            $"       IdCarrinho, " +_
            $"       Convertido, " +_
            $"       Canal, " +_
            $"       QtdItens, " +_
            $"       QtdItensTotal, " +_
            $"       Subtotal, " +_
            $"       Impostos, " +_
            $"       Total, " +_
            $"       DataAtualizacao " +_
            $"FROM {me.Tabela()} " +_
            $"WHERE CodCarrinho = :CodCarrinho"
        End Function

        Private Function SqlSelectPorIdCarrinho() As String
            SqlSelectPorIdCarrinho = $"SELECT CodCarrinho, " +_
            $"       IdCarrinho, " +_
            $"       Convertido, " +_
            $"       Canal, " +_
            $"       QtdItens, " +_
            $"       QtdItensTotal, " +_
            $"       Subtotal, " +_
            $"       Impostos, " +_
            $"       Total, " +_
            $"       DataAtualizacao " +_
            $"FROM {me.Tabela()} " +_
            $"WHERE IdCarrinho = :IdCarrinho"
        End Function

        Private Function SqlExistePorCodCarrinho() As String
            SqlExistePorCodCarrinho = "SELECT CASE " +_
            "           WHEN COUNT(CodCarrinho) > 0 THEN " + SqlHelper.SqlText("true") + " " +_
            "           ELSE " + SqlHelper.SqlText("false") + " " +_
            "       END result " +_
            "FROM " + me.Tabela() + " " +_
            "WHERE CodCarrinho = :CodCarrinho"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = $"INSERT INTO {me.Tabela()} (CodCarrinho, IdCarrinho, Convertido, Canal, QtdItens, QtdItensTotal, Subtotal, Impostos, Total, DataAtualizacao) " +_
            $"VALUES (:CodCarrinho, :IdCarrinho, :Convertido, :Canal, :QtdItens, :QtdItensTotal, :Subtotal, :Impostos, :Total, :DataAtualizacao)"
        End Function

        Private Function SqlUpdate() As String
            SqlUpdate = $"UPDATE {me.Tabela()} " +_
            $"SET IdCarrinho = :IdCarrinho, " +_
            $"    Convertido = :Convertido, " +_
            $"    Canal = :Canal, " +_
            $"    QtdItens = :QtdItens, " +_
            $"    QtdItensTotal = :QtdItensTotal, " +_
            $"    Subtotal = :Subtotal, " +_
            $"    Impostos = :Impostos, " +_
            $"    Total = :Total, " +_
            $"    DataAtualizacao = :DataAtualizacao " +_
            $"WHERE CodCarrinho = :CodCarrinho"
        End Function

        Private Function SqlDeletePorCodCarrinho() As String
            SqlDeletePorCodCarrinho = $"DELETE FROM {me.Tabela()} WHERE CodCarrinho = :CodCarrinho"
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraCarrinhoModel)
            pItem.CodCarrinho = pQuery.Field("CodCarrinho").AsInteger
            pItem.IdCarrinho = pQuery.Field("IdCarrinho").AsString
            pItem.Convertido = pQuery.Field("Convertido").AsString
            pItem.Canal = pQuery.Field("Canal").AsString
            pItem.QtdItens = pQuery.Field("QtdItens").AsInteger
            pItem.QtdItensTotal = pQuery.Field("QtdItensTotal").AsInteger
            pItem.Subtotal = pQuery.Field("Subtotal").AsFloat
            pItem.Impostos = pQuery.Field("Impostos").AsFloat
            pItem.Total = pQuery.Field("Total").AsFloat
            pItem.DataAtualizacao = pQuery.Field("DataAtualizacao").AsDateTime
        End Sub

        Private Sub BindParams(pQuery As SQL.Command, pModel As RedeAncoraCarrinhoModel)
            pQuery.Param("CodCarrinho").AsInteger = pModel.CodCarrinho
            pQuery.Param("IdCarrinho").AsString = pModel.IdCarrinho
            pQuery.Param("Convertido").AsString = pModel.Convertido
            pQuery.Param("Canal").AsString = pModel.Canal
            pQuery.Param("QtdItens").AsInteger = pModel.QtdItens
            pQuery.Param("QtdItensTotal").AsInteger = pModel.QtdItensTotal
            pQuery.Param("Subtotal").AsFloat = pModel.Subtotal
            pQuery.Param("Impostos").AsFloat = pModel.Impostos
            pQuery.Param("Total").AsFloat = pModel.Total
            pQuery.Param("DataAtualizacao").AsDateTime = pModel.DataAtualizacao
        End Sub

        Function GerarProximoCodCarrinho() As Integer
            Dim _query As SQL.Command = NULL
            Dim _proximo As Integer = 0

            GerarProximoCodCarrinho = 1

            Try
                _query = SqlHelper.OpenQuery("SELECT ISNULL(MAX(CodCarrinho), 0) AS Proximo FROM " + me.Tabela())
                _query.Open()
                _proximo = _query.Field("Proximo").AsInteger + 1
                SqlHelper.ReleaseQuery(_query)
                GerarProximoCodCarrinho = _proximo
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao gerar CodCarrinho Integracao.RedeAncoraCarrinho", "9134")
            End Try
        End Function

        Function ExistePorCodCarrinho(pCodCarrinho As Integer) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlExistePorCodCarrinho())
                _query.Param("CodCarrinho").AsInteger = pCodCarrinho
                _query.Open()
                ExistePorCodCarrinho = _query.Field("result").AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao verificar Integracao.RedeAncoraCarrinho", "9131")
            End Try
        End Function

        Function TryObterPorCodCarrinho(pCodCarrinho As Integer, pItem As RedeAncoraCarrinhoModel) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCodCarrinho())
                _query.Param("CodCarrinho").AsInteger = pCodCarrinho
                _query.Open()

                If _query.EOF Then
                    TryObterPorCodCarrinho = False
                Else
                    me.Mapear(_query, pItem)
                    TryObterPorCodCarrinho = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar Integracao.RedeAncoraCarrinho", "9132")
            End Try
        End Function

        Function ObterPorCodCarrinho(pCodCarrinho As Integer) As RedeAncoraCarrinhoModel
            Dim _item As New RedeAncoraCarrinhoModel()

            If Not me.TryObterPorCodCarrinho(pCodCarrinho, _item) Then
                Throw New System.Exception("Integracao.RedeAncoraCarrinho nao encontrado. Codigo: 9133")
            End If

            ObterPorCodCarrinho = _item
        End Function

        Function TryObterPorIdCarrinho(pIdCarrinho As String, pItem As RedeAncoraCarrinhoModel) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorIdCarrinho())
                _query.Param("IdCarrinho").AsString = pIdCarrinho
                _query.Open()

                If _query.EOF Then
                    TryObterPorIdCarrinho = False
                Else
                    me.Mapear(_query, pItem)
                    TryObterPorIdCarrinho = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar Integracao.RedeAncoraCarrinho por IdCarrinho", "9135")
            End Try
        End Function

        Function ObterPorIdCarrinho(pIdCarrinho As String) As RedeAncoraCarrinhoModel
            Dim _item As New RedeAncoraCarrinhoModel()

            If Not me.TryObterPorIdCarrinho(pIdCarrinho, _item) Then
                Throw New System.Exception("Integracao.RedeAncoraCarrinho nao encontrado por IdCarrinho. Codigo: 9136")
            End If

            ObterPorIdCarrinho = _item
        End Function

        Sub Inserir(pModel As RedeAncoraCarrinhoModel)
            me.InserirComTransacao(pModel, True)
        End Sub

        Sub InserirSemTransacao(pModel As RedeAncoraCarrinhoModel)
            me.InserirComTransacao(pModel, False)
        End Sub

        Private Sub InserirComTransacao(pModel As RedeAncoraCarrinhoModel, pUsarTransacao As Boolean)
            pModel.Validate()

            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraCarrinho Insert")
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

                If pUsarTransacao And Assigned(_tx) Then
                    _tx.Rollback()
                End If

                Throw New System.Exception("Erro ao inserir Integracao.RedeAncoraCarrinho: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub Atualizar(pModel As RedeAncoraCarrinhoModel)
            me.AtualizarComTransacao(pModel, True)
        End Sub

        Sub AtualizarSemTransacao(pModel As RedeAncoraCarrinhoModel)
            me.AtualizarComTransacao(pModel, False)
        End Sub

        Private Sub AtualizarComTransacao(pModel As RedeAncoraCarrinhoModel, pUsarTransacao As Boolean)
            pModel.Validate()

            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraCarrinho Update")
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

                If pUsarTransacao And Assigned(_tx) Then
                    _tx.Rollback()
                End If

                Throw New System.Exception("Erro ao atualizar Integracao.RedeAncoraCarrinho: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub Salvar(pModel As RedeAncoraCarrinhoModel)
            me.SalvarComTransacao(pModel, True)
        End Sub

        Sub SalvarSemTransacao(pModel As RedeAncoraCarrinhoModel)
            me.SalvarComTransacao(pModel, False)
        End Sub

        Private Sub SalvarComTransacao(pModel As RedeAncoraCarrinhoModel, pUsarTransacao As Boolean)
            If me.ExistePorCodCarrinho(pModel.CodCarrinho) Then
                me.AtualizarComTransacao(pModel, pUsarTransacao)
            Else
                me.InserirComTransacao(pModel, pUsarTransacao)
            End If
        End Sub

        Sub ExcluirPorCodCarrinho(pCodCarrinho As Integer)
            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL

            Try
                _tx.StartTransaction("Integracao.RedeAncoraCarrinho Delete")
                _query = SqlHelper.OpenQuery(me.SqlDeletePorCodCarrinho())
                _query.Param("CodCarrinho").AsInteger = pCodCarrinho
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _tx.Rollback()
                Throw New System.Exception("Erro ao excluir Integracao.RedeAncoraCarrinho: " + Char(13) + ex._getMessage())
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
                Throw New System.Exception("Erro ao liberar RedeAncoraCarrinhoRepository: " + Char(13) + ex._getMessage())
            End Try
        End Sub
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
