Imports mod_tobject

Namespace rede_ancora_input_consultar_detalhe_condicao_pagamento
    Class RedeAncoraInputConsultarDetalheCondicaoPagamento
        Inherits TTObject

        CodUsuario As Integer
        IdCarrinho As String
        CodCentroDistribuicao As Integer
        CodModalidade As Integer
        CodCondicaoPagamento As Integer

        Sub New()
            MyBase.New()
            me.IdCarrinho = ""
        End Sub

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
