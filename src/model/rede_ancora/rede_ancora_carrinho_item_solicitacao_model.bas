Imports mod_tobject

Namespace rede_ancora_carrinho_item_solicitacao_model
    Class RedeAncoraCarrinhoItemSolicitacaoModel
        Inherits TTObject

        Cna As Integer
        CodProduto As Integer
        Quantidade As Integer

        Sub New()
            MyBase.New()
        End Sub

        Sub Validate()
            If me.Cna <= 0 Then
                Throw New System.Exception("Cna invalido em RedeAncoraCarrinhoItemSolicitacaoModel")
            End If

            If me.Quantidade <= 0 Then
                Throw New System.Exception("Quantidade invalida em RedeAncoraCarrinhoItemSolicitacaoModel")
            End If
        End Sub

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
