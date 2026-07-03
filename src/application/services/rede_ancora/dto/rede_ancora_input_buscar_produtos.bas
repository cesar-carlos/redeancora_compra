Imports mod_tobject

Namespace rede_ancora_input_buscar_produtos
    Class RedeAncoraInputBuscarProdutos
        Inherits TTObject

        CodUsuario As Integer
        Pagina As Integer
        TamanhoPagina As Integer
        Marca As String
        Codigo As String
        Cna As Integer
        Gtin As String
        Cest As String
        Origem As Integer
        Nome As String
        CodLinha As Integer
        CodFamilia As Integer

        Sub New()
            MyBase.New()
            me.Marca = ""
            me.Codigo = ""
            me.Gtin = ""
            me.Cest = ""
            me.Nome = ""
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
