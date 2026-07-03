Imports mod_tobject
Imports rede_ancora_centro_distribuicao_model
Imports mod_tlist

Namespace rede_ancora_centros_distribuicao_model
    Class RedeAncoraCentrosDistribuicaoModel
        Inherits TTList<RedeAncoraCentroDistribuicaoModel>

        Public Sub New()
            MyBase.New()
        End Sub

        Function ObterPreferencial() As RedeAncoraCentroDistribuicaoModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).Preferencial = "S" Then
                    ObterPreferencial = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Function ObterPorCodigo(pCodCentroDistribuicao As Integer) As RedeAncoraCentroDistribuicaoModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).CodCentroDistribuicao = pCodCentroDistribuicao Then
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
