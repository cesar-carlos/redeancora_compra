Imports mod_tobject

Namespace rede_ancora_input_listar_pedidos_programados
    Class RedeAncoraInputListarPedidosProgramados
        Inherits TTObject

        CodUsuario As Integer
        CodCentroDistribuicao As Integer
        CodMarca As Integer
        DataInicial As String
        DataFinal As String

        Sub New()
            MyBase.New()
            me.DataInicial = ""
            me.DataFinal = ""
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
