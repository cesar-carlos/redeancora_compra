Imports mod_tobject

Namespace rede_ancora_produto_sincronizacao_modo
    Class RedeAncoraProdutoSincronizacaoModo
        Inherits TTObject

        Shared Function Completa() As String
            Completa = "COMPLETA"
        End Function

        Shared Function SomenteNovos() As String
            SomenteNovos = "NOVOS"
        End Function

        Shared Function IsSomenteNovos(pModo As String) As Boolean
            IsSomenteNovos = pModo.Trim().ToUpper() = RedeAncoraProdutoSincronizacaoModo.SomenteNovos()
        End Function

        Shared Function IsCompleta(pModo As String) As Boolean
            Dim _modo As String = pModo.Trim().ToUpper()

            IsCompleta = _modo = "" Or _modo = RedeAncoraProdutoSincronizacaoModo.Completa()
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
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
