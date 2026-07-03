Imports mod_tobject
Imports rede_ancora_produto_preco_estoque_model
Imports mod_tlist

Namespace rede_ancora_produto_precos_estoque_model
    Class RedeAncoraProdutoPrecosEstoqueModel
        Inherits TTList<RedeAncoraProdutoPrecoEstoqueModel>

        Public Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
