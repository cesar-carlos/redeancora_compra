Imports mod_tobject

Namespace rede_ancora_checkout_entrega_solicitacao_model
    Class RedeAncoraCheckoutEntregaSolicitacaoModel
        Inherits TTObject

        CodCentroDistribuicao As Integer
        CodEntrega As Integer
        CodTransportador As Integer
        ExigeTransportador As String

        Sub New()
            MyBase.New()
            me.ExigeTransportador = "N"
        End Sub

        Sub Validate()
            If me.CodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido em RedeAncoraCheckoutEntregaSolicitacaoModel")
            End If

            If me.CodEntrega <= 0 Then
                Throw New System.Exception("CodEntrega invalido em RedeAncoraCheckoutEntregaSolicitacaoModel")
            End If

            If me.ExigeTransportador = "S" And me.CodTransportador <= 0 Then
                Throw New System.Exception("CodTransportador obrigatorio para entrega Rede Ancora (seller " + me.CodCentroDistribuicao.ToString() + ")")
            End If
        End Sub

        Overrides Function GetID() As String
            GetID = me.CodCentroDistribuicao.ToString() + "-" + me.CodEntrega.ToString()
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            If Not me.Disposed Then
                me.Dispose()
            End If

            MyBase.Free()
        End Sub
    End Class
End Namespace
