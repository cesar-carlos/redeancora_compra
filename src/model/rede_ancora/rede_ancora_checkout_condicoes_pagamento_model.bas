Imports mod_tobject
Imports mod_tlist
Imports rede_ancora_checkout_condicao_pagamento_model

Namespace rede_ancora_checkout_condicoes_pagamento_model
    Class RedeAncoraCheckoutCondicoesPagamentoModel
        Inherits TTList<RedeAncoraCheckoutCondicaoPagamentoModel>

        Public Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
