Imports mod_tobject

Namespace rede_ancora_pedido_model
    Class RedeAncoraPedidoModel
        Inherits TTObject

        CodUsuario As Integer
        IdPedidoApi As Integer
        IdCarrinho As String
        DataPedido As TDateTime
        ValorTotal As Double

        Sub New()
            MyBase.New()
            me.IdCarrinho = ""
        End Sub

        Sub Validate()
            If me.CodUsuario <= 0 Then
                Throw New System.Exception("CodUsuario invalido em RedeAncoraPedidoModel")
            End If

            If me.IdPedidoApi <= 0 Then
                Throw New System.Exception("IdPedidoApi invalido em RedeAncoraPedidoModel")
            End If
        End Sub

        Overrides Function GetID() As String
            GetID = me.IdPedidoApi.ToString()
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
    End Class
End Namespace
