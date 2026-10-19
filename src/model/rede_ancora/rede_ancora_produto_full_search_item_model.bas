Imports mod_tobject
Imports rede_ancora_produto_model
Imports rede_ancora_produto_preco_estoque_model
Imports rede_ancora_produto_imagens_model

Namespace rede_ancora_produto_full_search_item_model
    Class RedeAncoraProdutoFullSearchItemModel
        Inherits TTObject

        Cadastro As RedeAncoraProdutoModel
        PrecoEstoque As RedeAncoraProdutoPrecoEstoqueModel
        Imagens As RedeAncoraProdutoImagensModel

        Sub New()
            MyBase.New()
            me.Cadastro = NULL
            me.PrecoEstoque = NULL
            me.Imagens = NULL
        End Sub

        Overrides Function GetID() As String
            Dim _id As String = ""

            If Assigned(me.Cadastro) Then
                _id = me.Cadastro.Cna.ToString()
            End If

            GetID = _id
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me.Cadastro) Then
                    me.Cadastro.Free()
                    me.Cadastro = NULL
                End If

                If Assigned(me.PrecoEstoque) Then
                    me.PrecoEstoque.Free()
                    me.PrecoEstoque = NULL
                End If

                If Assigned(me.Imagens) Then
                    me.Imagens.Free()
                    me.Imagens = NULL
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
