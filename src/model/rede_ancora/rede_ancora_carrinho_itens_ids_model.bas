Imports mod_tobject
Imports mod_tlist

Namespace rede_ancora_carrinho_itens_ids_model
    Class RedeAncoraCarrinhoItensIdsModel
        Inherits TTList<Integer>

        Sub New()
            MyBase.New()
        End Sub

        Sub ValidarTodos()
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i) <= 0 Then
                    Throw New System.Exception("IdItemApi invalido em RedeAncoraCarrinhoItensIdsModel")
                End If
            Next
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
