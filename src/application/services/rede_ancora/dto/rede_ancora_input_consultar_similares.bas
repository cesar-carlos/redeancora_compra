Imports mod_tobject
Imports rede_ancora_produto_cnas_model

Namespace rede_ancora_input_consultar_similares
    Class RedeAncoraInputConsultarSimilares
        Inherits TTObject

        CodUsuario As Integer
        Cnas As RedeAncoraProdutoCnasModel
        CodEstado As Integer
        CodCentroDistribuicao As Integer

        Sub New()
            MyBase.New()
            me.Cnas = NULL
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Cnas = NULL
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
