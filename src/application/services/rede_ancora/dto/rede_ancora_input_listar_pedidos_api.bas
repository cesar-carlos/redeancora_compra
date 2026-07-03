Imports mod_tobject

Namespace rede_ancora_input_listar_pedidos_api
    Class RedeAncoraInputListarPedidosApi
        Inherits TTObject

        CodUsuario As Integer
        Pagina As Integer
        TamanhoPagina As Integer
        OrdenarPor As String
        DirecaoOrdenacao As String
        CodModalidade As Integer
        CodCondicaoPagamento As Integer
        DataCriacao As String
        CodErpHandle As Integer
        CodErpSellerHandle As Integer
        Estado As String
        IdPedidoApi As Integer
        Produto As String
        NomeMarca As String
        CodigoProduto As String

        Sub New()
            MyBase.New()
            me.OrdenarPor = ""
            me.DirecaoOrdenacao = ""
            me.DataCriacao = ""
            me.Estado = ""
            me.Produto = ""
            me.NomeMarca = ""
            me.CodigoProduto = ""
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
