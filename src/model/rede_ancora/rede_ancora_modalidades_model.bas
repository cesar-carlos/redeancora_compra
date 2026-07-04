Imports mod_tobject
Imports rede_ancora_modalidade_model
Imports mod_tlist

Namespace rede_ancora_modalidades_model
    Class RedeAncoraModalidadesModel
        Inherits TTList<RedeAncoraModalidadeModel>

        Sub New()
            MyBase.New()
        End Sub

        Function ObterPorCodigo(pCodModalidade As Integer) As RedeAncoraModalidadeModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).CodModalidade = pCodModalidade Then
                    ObterPorCodigo = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Function ExistePorCodigo(pCodModalidade As Integer) As Boolean
            ExistePorCodigo = Assigned(me.ObterPorCodigo(pCodModalidade))
        End Function

        Function ObterDescricao(pCodModalidade As Integer) As String
            Dim _item As RedeAncoraModalidadeModel = me.ObterPorCodigo(pCodModalidade)

            ObterDescricao = ""

            If Assigned(_item) Then
                ObterDescricao = _item.Descricao
            End If
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
