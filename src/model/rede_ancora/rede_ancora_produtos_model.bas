Imports mod_tobject
Imports rede_ancora_produto_model
Imports mod_tlist

Namespace rede_ancora_produtos_model
    Class RedeAncoraProdutosModel
        Inherits TTList<RedeAncoraProdutoModel>

        Sub New()
            MyBase.New()
        End Sub

        Function ObterPorCna(pCna As Integer) As RedeAncoraProdutoModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).Cna = pCna Then
                    ObterPorCna = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Function ExistePorCna(pCna As Integer) As Boolean
            ExistePorCna = Assigned(me.ObterPorCna(pCna))
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
