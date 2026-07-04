Imports mod_tobject
Imports mod_tlist
Imports rede_ancora_checkout_entrega_solicitacao_model

Namespace rede_ancora_checkout_entregas_solicitacao_model
    Class RedeAncoraCheckoutEntregasSolicitacaoModel
        Inherits TTList<RedeAncoraCheckoutEntregaSolicitacaoModel>

        Sub New()
            MyBase.New()
        End Sub

        Sub ValidarTodos()
            Dim _i As Integer

            If me.Length <= 0 Then
                Throw New System.Exception("Nenhuma entrega informada em RedeAncoraCheckoutEntregasSolicitacaoModel")
            End If

            For _i = 0 To me.Length - 1
                me.Take(_i).Validate()
            Next
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
