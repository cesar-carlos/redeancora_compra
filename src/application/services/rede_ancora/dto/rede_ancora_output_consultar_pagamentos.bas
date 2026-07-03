Imports mod_tobject
Imports rede_ancora_checkout_pagamentos_model

Namespace rede_ancora_output_consultar_pagamentos
    Class RedeAncoraOutputConsultarPagamentos
        Inherits TTObject

        Pagamentos As RedeAncoraCheckoutPagamentosModel

        Sub New()
            MyBase.New()
            me.Pagamentos = NULL
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Pagamentos = NULL
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
