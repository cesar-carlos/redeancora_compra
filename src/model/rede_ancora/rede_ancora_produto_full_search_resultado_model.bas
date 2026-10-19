Imports mod_tobject
Imports rede_ancora_produto_full_search_itens_model

Namespace rede_ancora_produto_full_search_resultado_model
    Class RedeAncoraProdutoFullSearchResultadoModel
        Inherits TTObject

        Itens As RedeAncoraProdutoFullSearchItensModel
        Pagina As Integer
        TamanhoPagina As Integer
        UltimaPagina As Integer
        Total As Integer

        Sub New()
            MyBase.New()
            me.Itens = New RedeAncoraProdutoFullSearchItensModel()
        End Sub

        Function TemProximaPagina() As Boolean
            Dim _tem As Boolean = False

            If me.UltimaPagina > 0 Then
                If me.Pagina < me.UltimaPagina Then
                    _tem = True
                End If
            End If

            TemProximaPagina = _tem
        End Function

        Overrides Function GetID() As String
            GetID = me.Pagina.ToString()
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me.Itens) Then
                    me.Itens.Free()
                    me.Itens = NULL
                End If

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
