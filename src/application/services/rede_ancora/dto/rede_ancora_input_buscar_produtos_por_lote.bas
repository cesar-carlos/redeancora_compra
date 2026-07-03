Imports mod_tobject
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_codigos_model

Namespace rede_ancora_input_buscar_produtos_por_lote
    Class RedeAncoraInputBuscarProdutosPorLote
        Inherits TTObject

        CodUsuario As Integer
        CnaList As RedeAncoraProdutoCnasModel
        CodeList As RedeAncoraProdutoCodigosModel
        GtinList As RedeAncoraProdutoCodigosModel
        Pagina As Integer
        TamanhoPagina As Integer

        Sub New()
            MyBase.New()
            me.CnaList = Null
            me.CodeList = Null
            me.GtinList = Null
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.CnaList = Null
                me.CodeList = Null
                me.GtinList = Null
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
