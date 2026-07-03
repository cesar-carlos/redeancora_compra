Imports mod_tobject

Namespace rede_ancora_input_listar_produtos_pedido_programado
    Class RedeAncoraInputListarProdutosPedidoProgramado
        Inherits TTObject

        CodUsuario As Integer
        IdPedidoProgramado As Integer
        CodCentroDistribuicao As Integer
        CodEstado As Integer
        Pagina As Integer
        ItensPorPagina As Integer
        Query As String
        IdCiclo As Integer
        OrdenarPor As String
        DirecaoOrdenacao As String

        Sub New()
            MyBase.New()
            me.Query = ""
            me.OrdenarPor = ""
            me.DirecaoOrdenacao = ""
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
