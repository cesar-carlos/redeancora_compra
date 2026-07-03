Imports mod_tobject
Imports rede_ancora_centro_distribuicao_model
Imports rede_ancora_centros_distribuicao_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_centro_distribuicao_repository
    Class RedeAncoraCentroDistribuicaoRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaCentroDistribuicaoQualificada()
        End Function

        Private Function SqlSelectPorCodUsuario() As String
            SqlSelectPorCodUsuario = $"SELECT CodUsuario, " +_
            $"       CodCentroDistribuicao, " +_
            $"       Nome, " +_
            $"       NomeFantasia, " +_
            $"       CodEstado, " +_
            $"       Preferencial " +_
            $"FROM {me.Tabela()} " +_
            $"WHERE CodUsuario = :CodUsuario " +_
            $"ORDER BY Preferencial DESC, CodCentroDistribuicao"
        End Function

        Private Function SqlDeletePorCodUsuario() As String
            SqlDeletePorCodUsuario = $"DELETE FROM {me.Tabela()} WHERE CodUsuario = :CodUsuario"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = $"INSERT INTO {me.Tabela()} (CodUsuario, CodCentroDistribuicao, Nome, NomeFantasia, CodEstado, Preferencial) " +_
            $"VALUES (:CodUsuario, :CodCentroDistribuicao, :Nome, :NomeFantasia, :CodEstado, :Preferencial)"
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraCentroDistribuicaoModel)
            pItem.CodUsuario = pQuery.Field("CodUsuario").AsInteger
            pItem.CodCentroDistribuicao = pQuery.Field("CodCentroDistribuicao").AsInteger
            pItem.Nome = pQuery.Field("Nome").AsString
            pItem.NomeFantasia = pQuery.Field("NomeFantasia").AsString
            pItem.CodEstado = pQuery.Field("CodEstado").AsInteger
            pItem.Preferencial = pQuery.Field("Preferencial").AsString
        End Sub

        Function ListarPorCodUsuario(pCodUsuario As Integer) As RedeAncoraCentrosDistribuicaoModel
            Dim _result As New RedeAncoraCentrosDistribuicaoModel()
            Dim _query As SQL.Command = Null

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCodUsuario())
                _query.Param("CodUsuario").AsInteger = pCodUsuario
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraCentroDistribuicaoModel()
                    me.Mapear(_query, _item)
                    _result.Push(_item)
                    _query.Next()
                    Wend

                    SqlHelper.ReleaseQuery(_query)
                    ListarPorCodUsuario = _result
                Catch ex As Exception
                    SqlHelper.ReleaseQuery(_query)
                    _result.Free()
                    SqlHelper.HandleQueryError(ex, "Erro ao listar Integracao.RedeAncoraCentroDistribuicao", "9111")
                End Try
            End Function

            Sub SubstituirPorCodUsuario(pCodUsuario As Integer, pItens As RedeAncoraCentrosDistribuicaoModel)
                Dim _tx As Transaction = Transaction.Instance()
                Dim _deleteQuery As SQL.Command = Null
                Dim _insertQuery As SQL.Command = Null
                Dim _i As Integer

                Try
                    _tx.StartTransaction("Integracao.RedeAncoraCentroDistribuicao Replace")
                    _deleteQuery = SqlHelper.OpenQuery(me.SqlDeletePorCodUsuario())
                    _deleteQuery.Param("CodUsuario").AsInteger = pCodUsuario
                    _deleteQuery.ExecSQL()
                    SqlHelper.ReleaseQuery(_deleteQuery)
                    _deleteQuery = Null

                    For _i = 0 To pItens.Length - 1
                        Dim _item As RedeAncoraCentroDistribuicaoModel = pItens.Take(_i)
                        _item.CodUsuario = pCodUsuario
                        _item.Validate()

                        _insertQuery = SqlHelper.OpenQuery(me.SqlInsert())
                        _insertQuery.Param("CodUsuario").AsInteger = _item.CodUsuario
                        _insertQuery.Param("CodCentroDistribuicao").AsInteger = _item.CodCentroDistribuicao
                        _insertQuery.Param("Nome").AsString = _item.Nome
                        _insertQuery.Param("NomeFantasia").AsString = _item.NomeFantasia
                        _insertQuery.Param("CodEstado").AsInteger = _item.CodEstado
                        _insertQuery.Param("Preferencial").AsString = _item.Preferencial
                        _insertQuery.ExecSQL()
                        SqlHelper.ReleaseQuery(_insertQuery)
                        _insertQuery = Null
                    Next

                    _tx.AutoCommit()
                Catch ex As Exception
                    SqlHelper.ReleaseQuery(_deleteQuery)
                    SqlHelper.ReleaseQuery(_insertQuery)
                    _tx.Rollback()
                    Throw New System.Exception("Erro ao substituir Integracao.RedeAncoraCentroDistribuicao: " + Char(13) + ex._getMessage())
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
                    Throw New System.Exception("Erro ao liberar RedeAncoraCentroDistribuicaoRepository: " + Char(13) + ex._getMessage())
                End Try
            End Sub
            Sub New()
                MyBase.New()
            End Sub

        End Class
    End Namespace
