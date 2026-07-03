Imports mod_tobject
Imports rede_ancora_carrinho_itens_ids_model
Imports rede_ancora_checkout_entregas_solicitacao_model

Namespace rede_ancora_input_confirmar_pedido
    Class RedeAncoraInputConfirmarPedido
        Inherits TTObject

        CodUsuario As Integer
        IdCarrinho As String
        Entregas As RedeAncoraCheckoutEntregasSolicitacaoModel
        ItensIds As RedeAncoraCarrinhoItensIdsModel

        Sub New()
            MyBase.New()
            me.IdCarrinho = ""
            me.Entregas = NULL
            me.ItensIds = NULL
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Entregas = NULL
                me.ItensIds = NULL
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
