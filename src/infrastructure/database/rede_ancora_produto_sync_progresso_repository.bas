Imports mod_tobject
Imports mod_logger
Imports rede_ancora_produto_sync_progresso_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_produto_sync_progresso_repository
    Class RedeAncoraProdutoSyncProgressoRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaProdutoSyncProgressoQualificada()
        End Function

        Private Function SqlCampoInteiroOuNull(pParametro As String) As String
            SqlCampoInteiroOuNull = "CASE WHEN :" & pParametro & " = 0 THEN NULL ELSE :" & pParametro & " END"
        End Function

        Private Function SqlSelectPorFamilia() As String
            SqlSelectPorFamilia = "SELECT CodFamilia, UltimaPaginaOk, LastPage, Status, DataAtualizacao " &_
                "FROM " & me.Tabela() & " WHERE CodFamilia = :CodFamilia"
        End Function

        Private Function SqlExistePorFamilia() As String
            SqlExistePorFamilia = "SELECT CASE " &_
                "           WHEN COUNT(CodFamilia) > 0 THEN " & SqlHelper.SqlText("true") & " " &_
                "           ELSE " & SqlHelper.SqlText("false") & " " &_
                "       END result " &_
                "FROM " & me.Tabela() & " " &_
                "WHERE CodFamilia = :CodFamilia"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = "INSERT INTO " & me.Tabela() & " (CodFamilia, UltimaPaginaOk, LastPage, Status, DataAtualizacao) " &_
                "VALUES (:CodFamilia, :UltimaPaginaOk, " & me.SqlCampoInteiroOuNull("LastPage") & ", :Status, :DataAtualizacao)"
        End Function

        Private Function SqlUpdate() As String
            SqlUpdate = "UPDATE " & me.Tabela() & " " &_
                "SET UltimaPaginaOk = :UltimaPaginaOk, " &_
                "    LastPage = CASE WHEN :LastPage = 0 THEN LastPage ELSE :LastPage END, " &_
                "    Status = :Status, " &_
                "    DataAtualizacao = :DataAtualizacao " &_
                "WHERE CodFamilia = :CodFamilia"
        End Function

        Private Function SqlDeleteTodos() As String
            SqlDeleteTodos = "DELETE FROM " & me.Tabela()
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraProdutoSyncProgressoModel)
            pItem.CodFamilia = pQuery.Field("CodFamilia").AsInteger
            pItem.UltimaPaginaOk = pQuery.Field("UltimaPaginaOk").AsInteger
            pItem.LastPage = pQuery.Field("LastPage").AsInteger
            pItem.Status = pQuery.Field("Status").AsString
            pItem.DataAtualizacao = pQuery.Field("DataAtualizacao").AsDateTime
        End Sub

        Private Sub BindProgresso(pQuery As SQL.Command, pCodFamilia As Integer, pUltimaPaginaOk As Integer, pLastPage As Integer, pStatus As String)
            pQuery.Param("CodFamilia").AsInteger = pCodFamilia
            pQuery.Param("UltimaPaginaOk").AsInteger = pUltimaPaginaOk
            pQuery.Param("LastPage").AsInteger = pLastPage
            pQuery.Param("Status").AsString = pStatus
            pQuery.Param("DataAtualizacao").AsDateTime = DateTime()
        End Sub

        Function TryObterPorCodFamilia(pCodFamilia As Integer, pItem As RedeAncoraProdutoSyncProgressoModel) As Boolean
            Dim _query As SQL.Command = NULL
            Dim _ok As Boolean = False

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorFamilia())
                _query.Param("CodFamilia").AsInteger = pCodFamilia
                _query.Open()

                If _query.EOF Then
                    _ok = False
                Else
                    me.Mapear(_query, pItem)
                    _ok = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar Integracao.RedeAncoraProdutoSyncProgresso", "9181")
            End Try

            TryObterPorCodFamilia = _ok
        End Function

        Private Function ExistePorCodFamilia(pCodFamilia As Integer) As Boolean
            Dim _query As SQL.Command = NULL
            Dim _ok As Boolean = False

            Try
                _query = SqlHelper.OpenQuery(me.SqlExistePorFamilia())
                _query.Param("CodFamilia").AsInteger = pCodFamilia
                _query.Open()
                _ok = _query.Field("result").AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao verificar Integracao.RedeAncoraProdutoSyncProgresso", "9182")
            End Try

            ExistePorCodFamilia = _ok
        End Function

        ' Checkpoint apos Commit da pagina de produtos (mesma conexao). Nao engole erro.
        Sub Upsert(pCodFamilia As Integer, pUltimaPaginaOk As Integer, pLastPage As Integer, pStatus As String)
            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL
            Dim _status As String = pStatus.Trim().ToUpper()

            If pCodFamilia < 0 Then
                Throw New System.Exception("CodFamilia invalido no checkpoint Integracao.RedeAncoraProdutoSyncProgresso")
            End If

            If _status = "" Then
                _status = RedeAncoraProdutoSyncProgressoModel.StatusPagina()
            End If

            Try
                _tx = Transaction.Instance()
                _tx.StartTransaction("Integracao.RedeAncoraProdutoSyncProgresso Upsert")

                If me.ExistePorCodFamilia(pCodFamilia) Then
                    _query = SqlHelper.OpenQuery(me.SqlUpdate())
                Else
                    _query = SqlHelper.OpenQuery(me.SqlInsert())
                End If

                me.BindProgresso(_query, pCodFamilia, pUltimaPaginaOk, pLastPage, _status)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _query = NULL
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                If Assigned(_tx) Then
                    _tx.Rollback()
                End If
                mod_logger.Erro("Falha no checkpoint Integracao.RedeAncoraProdutoSyncProgresso familia=" & pCodFamilia.ToString() & " pagina=" & pUltimaPaginaOk.ToString() & ": " & ex._getMessage())
                Throw New System.Exception("Erro ao gravar checkpoint Integracao.RedeAncoraProdutoSyncProgresso familia " & pCodFamilia.ToString() & ": " & Char(13) & ex._getMessage())
            End Try
        End Sub

        Function CargaCompletaObtida() As Boolean
            Dim _item As RedeAncoraProdutoSyncProgressoModel = NULL
            Dim _ok As Boolean = False

            Try
                _item = New RedeAncoraProdutoSyncProgressoModel()
                If me.TryObterPorCodFamilia(RedeAncoraProdutoSyncProgressoModel.CodMarcadorCargaCompleta(), _item) Then
                    _ok = _item.EstaCargaCompleta()
                End If

                If Assigned(_item) Then
                    _item.Free()
                End If
            Catch ex As Exception
                If Assigned(_item) Then
                    _item.Free()
                End If
                Throw New System.Exception("Erro ao ler marcador COMPLETA em Integracao.RedeAncoraProdutoSyncProgresso: " & Char(13) & ex._getMessage())
            End Try

            CargaCompletaObtida = _ok
        End Function

        Sub MarcarCargaCompleta()
            me.Upsert(RedeAncoraProdutoSyncProgressoModel.CodMarcadorCargaCompleta(), 0, 0, RedeAncoraProdutoSyncProgressoModel.StatusCompleta())
        End Sub

        Sub LimparTodos()
            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                _tx = Transaction.Instance()
                _tx.StartTransaction("Integracao.RedeAncoraProdutoSyncProgresso Limpar")
                _query = SqlHelper.OpenQuery(me.SqlDeleteTodos())
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _query = NULL
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                If Assigned(_tx) Then
                    _tx.Rollback()
                End If
                Throw New System.Exception("Erro ao limpar Integracao.RedeAncoraProdutoSyncProgresso: " & Char(13) & ex._getMessage())
            End Try
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            If Not me.Disposed Then
                me.Dispose()
            End If

            MyBase.Free()
        End Sub

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
