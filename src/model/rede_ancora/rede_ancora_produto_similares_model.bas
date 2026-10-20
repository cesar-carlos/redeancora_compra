Imports mod_tobject
Imports mod_tlist
Imports rede_ancora_produto_similar_model

Namespace rede_ancora_produto_similares_model
    Class RedeAncoraProdutoSimilaresModel
        Inherits TTList<RedeAncoraProdutoSimilarModel>

        Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
