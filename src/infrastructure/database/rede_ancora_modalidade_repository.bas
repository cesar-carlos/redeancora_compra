Imports mod_tobject
Imports rede_ancora_modalidade_model
Imports rede_ancora_modalidades_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_modalidade_repository
    Class RedeAncoraModalidadeRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaModalidadeQualificada()
        End Function

        Private Function SqlSelectTodos() As String
            SqlSelectTodos = $"SELECT CodModalidade, Descricao " +_
            $"FROM {me.Tabela()} " +_
            $"ORDER BY CodModalidade"
        End Function

        Private Function SqlDeleteTodos() As String
            SqlDeleteTodos = $"DELETE FROM {me.Tabela()}"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = $"INSERT INTO {me.Tabela()} (CodModalidade, Descricao) " +_
            $"VALUES (:CodModalidade, :Descricao)"
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraModalidadeModel)
            pItem.CodModalidade = pQuery.Field("CodModalidade").AsInteger
            pItem.Descricao = pQuery.Field("Descricao").AsString
        End Sub

        Function ListarTodos() As RedeAncoraModalidadesModel
            Dim _result As New RedeAncoraModalidadesModel()
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectTodos())
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraModalidadeModel()
                    me.Mapear(_query, _item)
                    _result.Push(_item)
                    _query.Next()
                Wend

                SqlHelper.ReleaseQuery(_query)
                ListarTodos = _result
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _result.Free()
                SqlHelper.HandleQueryError(ex, "Erro ao listar Integracao.RedeAncoraModalidade", "9121")
            End Try
        End Function

        Sub SubstituirTodos(pItens As RedeAncoraModalidadesModel)
            Dim _tx As Transaction = Transaction.Instance()
            Dim _deleteQuery As SQL.Command = NULL
            Dim _insertQuery As SQL.Command = NULL
            Dim _i As Integer

            Try
                _tx.StartTransaction("Integracao.RedeAncoraModalidade Replace")
                _deleteQuery = SqlHelper.OpenQuery(me.SqlDeleteTodos())
                _deleteQuery.ExecSQL()
                SqlHelper.ReleaseQuery(_deleteQuery)
                _deleteQuery = NULL

                For _i = 0 To pItens.Length - 1
                    Dim _item As RedeAncoraModalidadeModel = pItens.Take(_i)
                    _item.Validate()

                    _insertQuery = SqlHelper.OpenQuery(me.SqlInsert())
                    _insertQuery.Param("CodModalidade").AsInteger = _item.CodModalidade
                    _insertQuery.Param("Descricao").AsString = _item.Descricao
                    _insertQuery.ExecSQL()
                    SqlHelper.ReleaseQuery(_insertQuery)
                    _insertQuery = NULL
                Next

                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_deleteQuery)
                SqlHelper.ReleaseQuery(_insertQuery)
                _tx.Rollback()
                Throw New System.Exception("Erro ao substituir Integracao.RedeAncoraModalidade: " + Char(13) + ex._getMessage())
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
                Throw New System.Exception("Erro ao liberar RedeAncoraModalidadeRepository: " + Char(13) + ex._getMessage())
            End Try
        End Sub
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
