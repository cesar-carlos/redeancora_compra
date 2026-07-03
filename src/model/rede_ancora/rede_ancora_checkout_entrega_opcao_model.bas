Imports mod_tobject

Namespace rede_ancora_checkout_entrega_opcao_model
    Class RedeAncoraCheckoutEntregaOpcaoModel
        Inherits TTObject

        CodEntrega As Integer
        Nome As String
        ExigeTransportador As String

        Sub New()
            MyBase.New()
            me.Nome = ""
            me.ExigeTransportador = "N"
        End Sub

        Sub Assign(pValue As RedeAncoraCheckoutEntregaOpcaoModel)
            If Assigned(pValue) Then
                me.CodEntrega = pValue.CodEntrega
                me.Nome = pValue.Nome
                me.ExigeTransportador = pValue.ExigeTransportador
            End If
        End Sub

        Function ExigeTransportadorSim() As Boolean
            ExigeTransportadorSim = me.ExigeTransportador = "S"
        End Function

        Overrides Function Clone() As RedeAncoraCheckoutEntregaOpcaoModel
            Dim _clone As New RedeAncoraCheckoutEntregaOpcaoModel()
            _clone.Assign(me)
            Clone = _clone
        End Function

        Overrides Function GetID() As String
            GetID = me.CodEntrega.ToString()
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
