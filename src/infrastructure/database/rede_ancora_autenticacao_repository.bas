Imports mod_tobject
Imports rede_ancora_autenticacao_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_autenticacao_repository
    Class RedeAncoraAutenticacaoRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaAutenticacaoQualificada()
        End Function

        Private Function SqlSelectPorCodUsuario() As String
            SqlSelectPorCodUsuario = $"SELECT CodUsuario, " +_
                $"       Email, " +_
                $"       ChaveApi, " +_
                $"       Ativo, " +_
                $"       IdUsuarioApi, " +_
                $"       NomeUsuario, " +_
                $"       CodSeller " +_
                $"FROM {me.Tabela()} " +_
                $"WHERE CodUsuario = :CodUsuario"
        End Function

        Private Function SqlExistePorCodUsuario() As String
            SqlExistePorCodUsuario = "SELECT CASE " +_
                "           WHEN COUNT(CodUsuario) > 0 THEN " + SqlHelper.SqlText("true") + " " +_
                "           ELSE " + SqlHelper.SqlText("false") + " " +_
                "       END result " +_
                "FROM " + me.Tabela() + " " +_
                "WHERE CodUsuario = :CodUsuario"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = $"INSERT INTO {me.Tabela()} (CodUsuario, Email, ChaveApi, Ativo, IdUsuarioApi, NomeUsuario, CodSeller) " +_
                $"VALUES (:CodUsuario, :Email, :ChaveApi, :Ativo, :IdUsuarioApi, :NomeUsuario, :CodSeller)"
        End Function

        Private Function SqlUpdate() As String
            SqlUpdate = $"UPDATE {me.Tabela()} " +_
                $"SET Email = :Email, " +_
                $"    ChaveApi = :ChaveApi, " +_
                $"    Ativo = :Ativo, " +_
                $"    IdUsuarioApi = :IdUsuarioApi, " +_
                $"    NomeUsuario = :NomeUsuario, " +_
                $"    CodSeller = :CodSeller " +_
                $"WHERE CodUsuario = :CodUsuario"
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraAutenticacaoModel)
            pItem.CodUsuario = pQuery.Field("CodUsuario").AsInteger
            pItem.Email = pQuery.Field("Email").AsString
            pItem.ChaveApi = pQuery.Field("ChaveApi").AsString
            pItem.Ativo = pQuery.Field("Ativo").AsString
            pItem.IdUsuarioApi = pQuery.Field("IdUsuarioApi").AsInteger
            pItem.NomeUsuario = pQuery.Field("NomeUsuario").AsString
            pItem.CodSeller = pQuery.Field("CodSeller").AsInteger
        End Sub

        Private Sub BindParams(pQuery As SQL.Command, pModel As RedeAncoraAutenticacaoModel)
            pQuery.Param("CodUsuario").AsInteger = pModel.CodUsuario
            pQuery.Param("Email").AsString = pModel.Email
            pQuery.Param("ChaveApi").AsString = pModel.ChaveApi
            pQuery.Param("Ativo").AsString = pModel.Ativo
            pQuery.Param("IdUsuarioApi").AsInteger = pModel.IdUsuarioApi
            pQuery.Param("NomeUsuario").AsString = pModel.NomeUsuario
            pQuery.Param("CodSeller").AsInteger = pModel.CodSeller
        End Sub

        Function ExistePorCodUsuario(pCodUsuario As Integer) As Boolean
            Dim _query As SQL.Command = Null

            Try
                _query = SqlHelper.OpenQuery(me.SqlExistePorCodUsuario())
                _query.Param("CodUsuario").AsInteger = pCodUsuario
                _query.Open()
                ExistePorCodUsuario = _query.Field("result").AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao verificar Integracao.RedeAncoraAutenticacao", "9201")
            End Try
        End Function

        Function TryObterPorCodUsuario(pCodUsuario As Integer, pItem As RedeAncoraAutenticacaoModel) As Boolean
            Dim _query As SQL.Command = Null

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCodUsuario())
                _query.Param("CodUsuario").AsInteger = pCodUsuario
                _query.Open()

                If _query.EOF Then
                    TryObterPorCodUsuario = False
                Else
                    me.Mapear(_query, pItem)
                    TryObterPorCodUsuario = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar Integracao.RedeAncoraAutenticacao", "9202")
            End Try
        End Function

        Function ObterPorCodUsuario(pCodUsuario As Integer) As RedeAncoraAutenticacaoModel
            Dim _item As New RedeAncoraAutenticacaoModel

            If Not me.TryObterPorCodUsuario(pCodUsuario, _item) Then
                Throw New System.Exception("Integracao.RedeAncoraAutenticacao nao encontrada. Codigo: 9203")
            End If

            ObterPorCodUsuario = _item
        End Function

        Sub Inserir(pModel As RedeAncoraAutenticacaoModel)
            pModel.Validate()

            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = Null

            Try
                _tx.StartTransaction("Integracao.RedeAncoraAutenticacao Insert")
                _query = SqlHelper.OpenQuery(me.SqlInsert())
                me.BindParams(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _tx.Rollback()
                Throw New System.Exception("Erro ao inserir Integracao.RedeAncoraAutenticacao: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub Atualizar(pModel As RedeAncoraAutenticacaoModel)
            pModel.Validate()

            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = Null

            Try
                _tx.StartTransaction("Integracao.RedeAncoraAutenticacao Update")
                _query = SqlHelper.OpenQuery(me.SqlUpdate())
                me.BindParams(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _tx.Rollback()
                Throw New System.Exception("Erro ao atualizar Integracao.RedeAncoraAutenticacao: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub Salvar(pModel As RedeAncoraAutenticacaoModel)
            If me.ExistePorCodUsuario(pModel.CodUsuario) Then
                me.Atualizar(pModel)
            Else
                me.Inserir(pModel)
            End If
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
                Throw New System.Exception("Erro ao liberar RedeAncoraAutenticacaoRepository: " + Char(13) + ex._getMessage())
            End Try
        End Sub
        Sub New()
            MyBase.New()
        End Sub

    End Class
End Namespace
