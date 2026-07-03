Imports mod_tobject
Imports rede_ancora_carrinho_itens_ids_model

Namespace rede_ancora_input_consultar_pagamentos
    Class RedeAncoraInputConsultarPagamentos
        Inherits TTObject

        CodUsuario As Integer
        IdCarrinho As String
        CodCentroDistribuicao As Integer
        CodModalidade As Integer
        ItensIds As RedeAncoraCarrinhoItensIdsModel

        Sub New()
            MyBase.New()
            me.IdCarrinho = ""
            me.ItensIds = NULL
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
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
