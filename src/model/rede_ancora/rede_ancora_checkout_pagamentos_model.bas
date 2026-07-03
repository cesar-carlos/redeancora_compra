Imports mod_tobject
Imports rede_ancora_checkout_condicoes_pagamento_model

Namespace rede_ancora_checkout_pagamentos_model
    Class RedeAncoraCheckoutPagamentosModel
        Inherits TTObject

        Fornecedor As RedeAncoraCheckoutCondicoesPagamentoModel
        Livre As RedeAncoraCheckoutCondicoesPagamentoModel
        Especial As RedeAncoraCheckoutCondicoesPagamentoModel

        Sub New()
            MyBase.New()
            me.Fornecedor = New RedeAncoraCheckoutCondicoesPagamentoModel()
            me.Livre = New RedeAncoraCheckoutCondicoesPagamentoModel()
            me.Especial = New RedeAncoraCheckoutCondicoesPagamentoModel()
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me.Fornecedor) Then
                    me.Fornecedor.Free()
                    me.Fornecedor = Null
                End If

                If Assigned(me.Livre) Then
                    me.Livre.Free()
                    me.Livre = Null
                End If

                If Assigned(me.Especial) Then
                    me.Especial.Free()
                    me.Especial = Null
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
