Imports mod_tobject

Namespace rede_ancora_input_listar_pendencias_por_pedido_api
    Class RedeAncoraInputListarPendenciasPorPedidoApi
        Inherits TTObject

        CodUsuario As Integer
        Pagina As Integer
        TamanhoPagina As Integer
        OrdenarPor As String
        DirecaoOrdenacao As String
        CodModalidade As Integer
        CodErpSellerHandle As Integer
        Estado As String

        Sub New()
            MyBase.New()
            me.OrdenarPor = ""
            me.DirecaoOrdenacao = ""
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
