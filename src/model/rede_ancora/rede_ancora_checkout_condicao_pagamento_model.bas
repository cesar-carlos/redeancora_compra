Imports mod_tobject
Imports try_parser

Namespace rede_ancora_checkout_condicao_pagamento_model
    Class RedeAncoraCheckoutCondicaoPagamentoModel
        Inherits TTObject

        CodCondicaoPagamento As Integer
        Descricao As String
        Tag As String

        Sub New()
            MyBase.New()
            me.Descricao = ""
            me.Tag = ""
        End Sub

        Overrides Function GetID() As String
            GetID = Parser.IntegerToString(me.CodCondicaoPagamento)
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
