Imports mod_tobject
Imports rede_ancora_checkout_entregas_sellers_model

Namespace rede_ancora_checkout_revisao_model
    Class RedeAncoraCheckoutRevisaoModel
        Inherits TTObject

        QtdItens As Integer
        QtdItensTotal As Integer
        Subtotal As Double
        Impostos As Double
        Total As Double
        EntregasSellers As RedeAncoraCheckoutEntregasSellersModel

        Sub New()
            MyBase.New()
            me.EntregasSellers = New RedeAncoraCheckoutEntregasSellersModel()
        End Sub

        Sub Assign(pValue As RedeAncoraCheckoutRevisaoModel)
            Dim _i As Integer

            If Assigned(pValue) Then
                me.QtdItens = pValue.QtdItens
                me.QtdItensTotal = pValue.QtdItensTotal
                me.Subtotal = pValue.Subtotal
                me.Impostos = pValue.Impostos
                me.Total = pValue.Total

                If Assigned(me.EntregasSellers) Then
                    me.EntregasSellers.Free()
                End If

                me.EntregasSellers = New RedeAncoraCheckoutEntregasSellersModel()

                If Assigned(pValue.EntregasSellers) Then
                    For _i = 0 To pValue.EntregasSellers.Length - 1
                        me.EntregasSellers.Push(pValue.EntregasSellers.Take(_i).Clone())
                    Next
                End If
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraCheckoutRevisaoModel
            Dim _clone As New RedeAncoraCheckoutRevisaoModel()
            _clone.Assign(me)
            Clone = _clone
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me.EntregasSellers) Then
                    me.EntregasSellers.Free()
                    me.EntregasSellers = NULL
                End If

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
