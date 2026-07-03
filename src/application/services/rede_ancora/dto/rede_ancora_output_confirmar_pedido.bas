Imports mod_tobject
Imports rede_ancora_pedidos_model

Namespace rede_ancora_output_confirmar_pedido
    Class RedeAncoraOutputConfirmarPedido
        Inherits TTObject

        Pedidos As RedeAncoraPedidosModel

        Sub New()
            MyBase.New()
            me.Pedidos = NULL
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Pedidos = NULL
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
