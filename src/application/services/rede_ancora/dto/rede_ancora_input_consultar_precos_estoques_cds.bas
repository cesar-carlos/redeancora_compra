Imports mod_tobject
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_codigos_model

Namespace rede_ancora_input_consultar_precos_estoques_cds
    Class RedeAncoraInputConsultarPrecosEstoquesCds
        Inherits TTObject

        CodUsuario As Integer
        CodCentroDistribuicaoPreferencial As Integer
        Cnas As RedeAncoraProdutoCnasModel
        Codes As RedeAncoraProdutoCodigosModel

        Sub New()
            MyBase.New()
            me.Cnas = Null
            me.Codes = Null
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Cnas = Null
                me.Codes = Null
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
