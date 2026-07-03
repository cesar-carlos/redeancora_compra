Imports mod_tobject
Imports mod_tlist
Imports rede_ancora_checkout_entrega_opcao_model

Namespace rede_ancora_checkout_entrega_opcoes_model
    Class RedeAncoraCheckoutEntregaOpcoesModel
        Inherits TTList<RedeAncoraCheckoutEntregaOpcaoModel>

        Public Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
