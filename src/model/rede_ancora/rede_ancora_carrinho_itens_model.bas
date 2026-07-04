Imports mod_tobject
Imports rede_ancora_carrinho_item_model
Imports mod_tlist

Namespace rede_ancora_carrinho_itens_model
    Class RedeAncoraCarrinhoItensModel
        Inherits TTList<RedeAncoraCarrinhoItemModel>

        Sub New()
            MyBase.New()
        End Sub

        Function ObterPorIdItemApi(pIdItemApi As Integer) As RedeAncoraCarrinhoItemModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).IdItemApi = pIdItemApi Then
                    ObterPorIdItemApi = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Function ObterPorCna(pCna As Integer, pCodModalidade As Integer, pCodCentroDistribuicao As Integer) As RedeAncoraCarrinhoItemModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                Dim _item As RedeAncoraCarrinhoItemModel = me.Take(_i)

                If _item.Cna = pCna And _item.CodModalidade = pCodModalidade And _item.CodCentroDistribuicao = pCodCentroDistribuicao Then
                    ObterPorCna = _item
                    Exit Function
                End If
            Next
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
