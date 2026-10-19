Imports mod_tobject
Imports rede_ancora_familia_model
Imports mod_tlist

Namespace rede_ancora_familias_model
    Class RedeAncoraFamiliasModel
        Inherits TTList<RedeAncoraFamiliaModel>

        Sub New()
            MyBase.New()
        End Sub

        Function ObterPorCodigo(pCodFamilia As Integer) As RedeAncoraFamiliaModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).CodFamilia = pCodFamilia Then
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
