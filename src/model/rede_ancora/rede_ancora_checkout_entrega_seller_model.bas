Imports mod_tobject
Imports rede_ancora_checkout_entrega_opcoes_model

Namespace rede_ancora_checkout_entrega_seller_model
    Class RedeAncoraCheckoutEntregaSellerModel
        Inherits TTObject

        CodCentroDistribuicao As Integer
        NomeCentroDistribuicao As String
        Opcoes As RedeAncoraCheckoutEntregaOpcoesModel

        Sub New()
            MyBase.New()
            me.NomeCentroDistribuicao = ""
            me.Opcoes = New RedeAncoraCheckoutEntregaOpcoesModel()
        End Sub

        Sub Assign(pValue As RedeAncoraCheckoutEntregaSellerModel)
            Dim _i As Integer

            If Assigned(pValue) Then
                me.CodCentroDistribuicao = pValue.CodCentroDistribuicao
                me.NomeCentroDistribuicao = pValue.NomeCentroDistribuicao

                If Assigned(me.Opcoes) Then
                    me.Opcoes.Free()
                End If

                me.Opcoes = New RedeAncoraCheckoutEntregaOpcoesModel()

                If Assigned(pValue.Opcoes) Then
                    For _i = 0 To pValue.Opcoes.Length - 1
                        me.Opcoes.Push(pValue.Opcoes.Take(_i).Clone())
                    Next
                End If
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraCheckoutEntregaSellerModel
            Dim _clone As New RedeAncoraCheckoutEntregaSellerModel()
            _clone.Assign(me)
            Clone = _clone
        End Function

        Overrides Function GetID() As String
            GetID = me.CodCentroDistribuicao.ToString()
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me.Opcoes) Then
                    me.Opcoes.Free()
                    me.Opcoes = NULL
                End If

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
