Imports mod_tobject
Imports rede_ancora_carrinho_item_solicitacao_model
Imports mod_tlist

Namespace rede_ancora_carrinho_itens_solicitacao_model
    Class RedeAncoraCarrinhoItensSolicitacaoModel
        Inherits TTList<RedeAncoraCarrinhoItemSolicitacaoModel>

        Sub New()
            MyBase.New()
        End Sub

        Sub ValidarTodos()
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                me.Take(_i).Validate()
            Next
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
