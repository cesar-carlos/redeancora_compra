Imports mod_tobject
Imports rede_ancora_produto_imagem_model
Imports mod_tlist

Namespace rede_ancora_produto_imagens_model
    Class RedeAncoraProdutoImagensModel
        Inherits TTList<RedeAncoraProdutoImagemModel>

        Public Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
