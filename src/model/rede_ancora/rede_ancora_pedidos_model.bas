Imports mod_tobject
Imports mod_tlist
Imports rede_ancora_pedido_model

Namespace rede_ancora_pedidos_model
    Class RedeAncoraPedidosModel
        Inherits TTList<RedeAncoraPedidoModel>

        Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
