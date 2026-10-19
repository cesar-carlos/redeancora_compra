Imports mod_tobject
Imports rede_ancora_linha_model
Imports mod_tlist

Namespace rede_ancora_linhas_model
    Class RedeAncoraLinhasModel
        Inherits TTList<RedeAncoraLinhaModel>

        Sub New()
            MyBase.New()
        End Sub

        Function ObterPorCodigo(pCodLinha As Integer) As RedeAncoraLinhaModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).CodLinha = pCodLinha Then
                    ObterPorCodigo = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
