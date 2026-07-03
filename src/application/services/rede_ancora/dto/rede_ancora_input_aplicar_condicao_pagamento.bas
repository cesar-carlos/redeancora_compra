Imports mod_tobject
Imports rede_ancora_carrinho_itens_ids_model

Namespace rede_ancora_input_aplicar_condicao_pagamento
    Class RedeAncoraInputAplicarCondicaoPagamento
        Inherits TTObject

        CodUsuario As Integer
        IdCarrinho As String
        CodCondicaoPagamento As Integer
        CodEstado As Integer
        ItensIds As RedeAncoraCarrinhoItensIdsModel

        Sub New()
            MyBase.New()
            me.IdCarrinho = ""
            me.ItensIds = Null
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.ItensIds = Null
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
