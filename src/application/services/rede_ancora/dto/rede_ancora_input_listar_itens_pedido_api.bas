Imports mod_tobject

Namespace rede_ancora_input_listar_itens_pedido_api
    Class RedeAncoraInputListarItensPedidoApi
        Inherits TTObject

        CodUsuario As Integer
        IdPedidoApi As Integer
        OrdenarPor As String
        DirecaoOrdenacao As String
        Query As String
        Marca As String
        Codigo As String
        Cna As Integer
        Nome As String
        Estado As String
        IdItemApi As Integer

        Sub New()
            MyBase.New()
            me.OrdenarPor = ""
            me.DirecaoOrdenacao = ""
            me.Query = ""
            me.Marca = ""
            me.Codigo = ""
            me.Nome = ""
            me.Estado = ""
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
