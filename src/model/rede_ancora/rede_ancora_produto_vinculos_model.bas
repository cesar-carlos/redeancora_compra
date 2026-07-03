Imports mod_tobject
Imports rede_ancora_produto_vinculo_model
Imports mod_tlist

Namespace rede_ancora_produto_vinculos_model
    Class RedeAncoraProdutoVinculosModel
        Inherits TTList<RedeAncoraProdutoVinculoModel>

        Public Sub New()
            MyBase.New()
        End Sub

        Function ObterPorCna(pCna As Integer) As RedeAncoraProdutoVinculoModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).Cna = pCna Then
                    ObterPorCna = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Function ObterVinculadoPorCodProduto(pCodProduto As Integer) As RedeAncoraProdutoVinculoModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).CodProduto = pCodProduto And me.Take(_i).IsVinculado() Then
                    ObterVinculadoPorCodProduto = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Function ObterPorCodProduto(pCodProduto As Integer) As RedeAncoraProdutoVinculoModel
            ObterPorCodProduto = me.ObterVinculadoPorCodProduto(pCodProduto)
        End Function

        Function ExistePorCodProduto(pCodProduto As Integer) As Boolean
            ExistePorCodProduto = Assigned(me.ObterVinculadoPorCodProduto(pCodProduto))
        End Function

        Function ExistePorCna(pCna As Integer) As Boolean
            ExistePorCna = Assigned(me.ObterPorCna(pCna))
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
