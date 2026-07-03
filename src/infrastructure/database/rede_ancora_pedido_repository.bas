Imports mod_tobject
Imports rede_ancora_pedido_model
Imports rede_ancora_pedidos_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_pedido_repository
    Class RedeAncoraPedidoRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaPedidoQualificada()
        End Function

        Private Function SqlSelectPorCodUsuario() As String
            SqlSelectPorCodUsuario = $"SELECT CodUsuario, " +_
            $"       IdPedidoApi, " +_
            $"       IdCarrinho, " +_
            $"       DataPedido, " +_
            $"       ValorTotal " +_
            $"FROM {me.Tabela()} " +_
            $"WHERE CodUsuario = :CodUsuario " +_
            $"ORDER BY DataPedido DESC, IdPedidoApi DESC"
        End Function

        Private Function SqlExiste() As String
            SqlExiste = "SELECT CASE " +_
            "           WHEN COUNT(IdPedidoApi) > 0 THEN " + SqlHelper.SqlText("true") + " " +_
            "           ELSE " + SqlHelper.SqlText("false") + " " +_
            "       END result " +_
            "FROM " + me.Tabela() + " " +_
            "WHERE CodUsuario = :CodUsuario AND IdPedidoApi = :IdPedidoApi"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = $"INSERT INTO {me.Tabela()} (CodUsuario, IdPedidoApi, IdCarrinho, DataPedido, ValorTotal) " +_
            $"VALUES (:CodUsuario, :IdPedidoApi, :IdCarrinho, :DataPedido, :ValorTotal)"
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraPedidoModel)
            pItem.CodUsuario = pQuery.Field("CodUsuario").AsInteger
            pItem.IdPedidoApi = pQuery.Field("IdPedidoApi").AsInteger
            pItem.IdCarrinho = pQuery.Field("IdCarrinho").AsString
            pItem.DataPedido = pQuery.Field("DataPedido").AsDateTime
            pItem.ValorTotal = pQuery.Field("ValorTotal").AsFloat
        End Sub

        Private Sub BindParams(pQuery As SQL.Command, pModel As RedeAncoraPedidoModel)
            pQuery.Param("CodUsuario").AsInteger = pModel.CodUsuario
            pQuery.Param("IdPedidoApi").AsInteger = pModel.IdPedidoApi
            pQuery.Param("IdCarrinho").AsString = pModel.IdCarrinho
            pQuery.Param("DataPedido").AsDateTime = pModel.DataPedido
            pQuery.Param("ValorTotal").AsFloat = pModel.ValorTotal
        End Sub

        Function Existe(pCodUsuario As Integer, pIdPedidoApi As Integer) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlExiste())
                _query.Param("CodUsuario").AsInteger = pCodUsuario
                _query.Param("IdPedidoApi").AsInteger = pIdPedidoApi
                _query.Open()
                Existe = _query.Field("result").AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao verificar Integracao.RedeAncoraPedido", "9141")
            End Try
        End Function

        Function ListarPorCodUsuario(pCodUsuario As Integer) As RedeAncoraPedidosModel
            Dim _result As New RedeAncoraPedidosModel()
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCodUsuario())
                _query.Param("CodUsuario").AsInteger = pCodUsuario
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraPedidoModel()
                    me.Mapear(_query, _item)
                    _result.Push(_item)
                    _query.Next()
                Wend

                SqlHelper.ReleaseQuery(_query)
                ListarPorCodUsuario = _result
            Catch ex As Exception
                _result.Free()
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao listar Integracao.RedeAncoraPedido", "9142")
            End Try
        End Function

        Sub Inserir(pModel As RedeAncoraPedidoModel)
            pModel.Validate()

            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL

            Try
                _tx.StartTransaction("Integracao.RedeAncoraPedido Insert")
                _query = SqlHelper.OpenQuery(me.SqlInsert())
                me.BindParams(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _tx.Rollback()
                Throw New System.Exception("Erro ao inserir Integracao.RedeAncoraPedido: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub SalvarVarios(pPedidos As RedeAncoraPedidosModel)
            Dim _i As Integer

            For _i = 0 To pPedidos.Length - 1
                Dim _pedido As RedeAncoraPedidoModel = pPedidos.Take(_i)

                If Not me.Existe(_pedido.CodUsuario, _pedido.IdPedidoApi) Then
                    me.Inserir(_pedido)
                End If
            Next
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
                Throw New System.Exception("Erro ao liberar RedeAncoraPedidoRepository: " + Char(13) + ex._getMessage())
            End Try
        End Sub
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
