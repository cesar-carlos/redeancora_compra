Imports mod_tobject
Imports rede_ancora_marca_model
Imports mod_tlist

Namespace rede_ancora_marcas_model
    Class RedeAncoraMarcasModel
        Inherits TTList<RedeAncoraMarcaModel>

        Public Sub New()
            MyBase.New()
        End Sub

        Function ObterPorCodigo(pCodMarca As Integer) As RedeAncoraMarcaModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).CodMarca = pCodMarca Then
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
