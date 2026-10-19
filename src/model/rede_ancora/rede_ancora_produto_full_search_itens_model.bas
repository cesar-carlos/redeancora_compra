Imports mod_tobject
Imports rede_ancora_produto_full_search_item_model
Imports mod_tlist

Namespace rede_ancora_produto_full_search_itens_model
    Class RedeAncoraProdutoFullSearchItensModel
        Inherits TTList<RedeAncoraProdutoFullSearchItemModel>

        Sub New()
            MyBase.New()
        End Sub

        Function ObterPorCna(pCna As Integer) As RedeAncoraProdutoFullSearchItemModel
            Dim _i As Integer
            Dim _item As RedeAncoraProdutoFullSearchItemModel = NULL

            ObterPorCna = NULL

            For _i = 0 To me.Length - 1
                _item = me.Take(_i)

                If Assigned(_item) Then
                    If Assigned(_item.Cadastro) Then
                        If _item.Cadastro.Cna = pCna Then
                            ObterPorCna = _item
                            Exit Function
                        End If
                    End If
                End If
            Next
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
