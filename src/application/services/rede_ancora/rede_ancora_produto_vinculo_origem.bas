Imports mod_tobject

Namespace rede_ancora_produto_vinculo_origem
    Class RedeAncoraProdutoVinculoOrigem
        Inherits TTObject

        Shared Function Manual() As String
            Manual = "MANUAL"
        End Function

        Shared Function Busca() As String
            Busca = "BUSCA"
        End Function

        Shared Function Importacao() As String
            Importacao = "IMPORT"
        End Function

        Shared Function Sincronizacao() As String
            Sincronizacao = "SYNC"
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
