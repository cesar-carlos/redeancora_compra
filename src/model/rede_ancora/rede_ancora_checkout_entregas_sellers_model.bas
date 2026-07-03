Imports mod_tobject
Imports mod_tlist
Imports rede_ancora_checkout_entrega_seller_model

Namespace rede_ancora_checkout_entregas_sellers_model
    Class RedeAncoraCheckoutEntregasSellersModel
        Inherits TTList<RedeAncoraCheckoutEntregaSellerModel>

        Public Sub New()
            MyBase.New()
        End Sub

        Function ObterPorCentroDistribuicao(pCodCentroDistribuicao As Integer) As RedeAncoraCheckoutEntregaSellerModel
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).CodCentroDistribuicao = pCodCentroDistribuicao Then
                    ObterPorCentroDistribuicao = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
