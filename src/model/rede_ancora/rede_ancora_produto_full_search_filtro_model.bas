Imports mod_tobject

Namespace rede_ancora_produto_full_search_filtro_model
    Class RedeAncoraProdutoFullSearchFiltroModel
        Inherits TTObject

        CodUsuario As Integer
        CodCentroDistribuicao As Integer
        Cna As Integer
        Codigo As String
        Query As String
        CodFamilia As Integer
        Pagina As Integer
        TamanhoPagina As Integer
        IncluirPrecos As Boolean
        IncluirEstoques As Boolean
        IncluirDetalhes As Boolean

        Sub New()
            MyBase.New()
            me.Codigo = ""
            me.Query = ""
            me.IncluirPrecos = True
            me.IncluirEstoques = True
            me.IncluirDetalhes = True
        End Sub

        Overrides Function GetID() As String
            GetID = me.Cna.ToString()
        End Function

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
