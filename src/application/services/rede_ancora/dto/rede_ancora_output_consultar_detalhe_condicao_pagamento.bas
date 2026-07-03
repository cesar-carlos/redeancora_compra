Imports mod_tobject

Namespace rede_ancora_output_consultar_detalhe_condicao_pagamento
    Class RedeAncoraOutputConsultarDetalheCondicaoPagamento
        Inherits TTObject

        Resultado As String

        Sub New()
            MyBase.New()
            me.Resultado = ""
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
