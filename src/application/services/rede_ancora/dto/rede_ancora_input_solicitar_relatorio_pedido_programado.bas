Imports mod_tobject

Namespace rede_ancora_input_solicitar_relatorio_pedido_programado
    Class RedeAncoraInputSolicitarRelatorioPedidoProgramado
        Inherits TTObject

        CodUsuario As Integer
        IdPedidoProgramado As Integer
        CodCentroDistribuicao As Integer
        CodEstado As Integer

        Sub New()
            MyBase.New()
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
    End Class
End Namespace
