Imports mod_tobject

Namespace rede_ancora_produto_sync_progresso_model
    ' Checkpoint local do cadastro completo: PK = CodFamilia da API (nao indice da lista).
    Class RedeAncoraProdutoSyncProgressoModel
        Inherits TTObject

        CodFamilia As Integer
        UltimaPaginaOk As Integer
        LastPage As Integer
        Status As String
        DataAtualizacao As TDateTime

        Shared Function StatusPendente() As String
            StatusPendente = "PENDENTE"
        End Function

        Shared Function StatusPagina() As String
            StatusPagina = "PAGINA"
        End Function

        Shared Function StatusDone() As String
            StatusDone = "DONE"
        End Function

        ' Linha sentinela (nao e familia da API). Status=COMPLETA = carga de produtos ja obtida.
        Shared Function CodMarcadorCargaCompleta() As Integer
            CodMarcadorCargaCompleta = 0
        End Function

        Shared Function StatusCompleta() As String
            StatusCompleta = "COMPLETA"
        End Function

        Sub New()
            MyBase.New()
            me.CodFamilia = 0
            me.UltimaPaginaOk = 0
            me.LastPage = 0
            me.Status = RedeAncoraProdutoSyncProgressoModel.StatusPendente()
        End Sub

        Function EstaDone() As Boolean
            EstaDone = me.Status.Trim().ToUpper() = RedeAncoraProdutoSyncProgressoModel.StatusDone()
        End Function

        Function EstaCargaCompleta() As Boolean
            Dim _ok As Boolean = False

            If me.CodFamilia = RedeAncoraProdutoSyncProgressoModel.CodMarcadorCargaCompleta() Then
                If me.Status.Trim().ToUpper() = RedeAncoraProdutoSyncProgressoModel.StatusCompleta() Then
                    _ok = True
                End If
            End If

            EstaCargaCompleta = _ok
        End Function

        Function ProximaPagina() As Integer
            Dim _pagina As Integer = me.UltimaPaginaOk + 1

            If _pagina < 1 Then
                _pagina = 1
            End If

            ProximaPagina = _pagina
        End Function

        Overrides Function GetID() As String
            GetID = me.CodFamilia.ToString()
        End Function

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
    End Class
End Namespace
