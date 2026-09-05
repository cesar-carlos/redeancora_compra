Imports mod_tobject
Imports sql_helper

Namespace integracao_schema
    ' Nomes do esquema e tabelas de integração Rede Âncora B2B.
    Class IntegracaoSchema
        Inherits TTObject

        Shared Function Nome() As String
            Nome = "Integracao"
        End Function

        Shared Function TabelaAutenticacao() As String
            TabelaAutenticacao = "RedeAncoraAutenticacao"
        End Function

        Shared Function TabelaEmpresa() As String
            TabelaEmpresa = "RedeAncoraEmpresa"
        End Function

        Shared Function TabelaCarrinho() As String
            TabelaCarrinho = "RedeAncoraCarrinho"
        End Function

        Shared Function TabelaCarrinhoItem() As String
            TabelaCarrinhoItem = "RedeAncoraCarrinhoItem"
        End Function

        Shared Function TabelaPedido() As String
            TabelaPedido = "RedeAncoraPedido"
        End Function

        Shared Function TabelaCentroDistribuicao() As String
            TabelaCentroDistribuicao = "RedeAncoraCentroDistribuicao"
        End Function

        Shared Function TabelaModalidade() As String
            TabelaModalidade = "RedeAncoraModalidade"
        End Function

        Shared Function TabelaMarca() As String
            TabelaMarca = "RedeAncoraMarca"
        End Function

        Shared Function TabelaLinha() As String
            TabelaLinha = "RedeAncoraLinha"
        End Function

        Shared Function TabelaFamilia() As String
            TabelaFamilia = "RedeAncoraFamilia"
        End Function

        Shared Function TabelaProduto() As String
            TabelaProduto = "RedeAncoraProduto"
        End Function

        Shared Function TabelaProdutoVinculo() As String
            TabelaProdutoVinculo = "RedeAncoraProdutoVinculo"
        End Function

        Shared Function TabelaProdutoImagem() As String
            TabelaProdutoImagem = "RedeAncoraProdutoImagem"
        End Function

        Shared Function TabelaProdutoSyncProgresso() As String
            TabelaProdutoSyncProgresso = "RedeAncoraProdutoSyncProgresso"
        End Function

        Shared Function NomeQualificado(pTabela As String) As String
            NomeQualificado = SqlHelper.QualifiedTable(IntegracaoSchema.Nome(), pTabela)
        End Function

        Shared Function TabelaAutenticacaoQualificada() As String
            TabelaAutenticacaoQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaAutenticacao())
        End Function

        Shared Function TabelaEmpresaQualificada() As String
            TabelaEmpresaQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaEmpresa())
        End Function

        Shared Function TabelaCarrinhoQualificada() As String
            TabelaCarrinhoQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaCarrinho())
        End Function

        Shared Function TabelaCarrinhoItemQualificada() As String
            TabelaCarrinhoItemQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaCarrinhoItem())
        End Function

        Shared Function TabelaPedidoQualificada() As String
            TabelaPedidoQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaPedido())
        End Function

        Shared Function TabelaCentroDistribuicaoQualificada() As String
            TabelaCentroDistribuicaoQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaCentroDistribuicao())
        End Function

        Shared Function TabelaModalidadeQualificada() As String
            TabelaModalidadeQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaModalidade())
        End Function

        Shared Function TabelaMarcaQualificada() As String
            TabelaMarcaQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaMarca())
        End Function

        Shared Function TabelaLinhaQualificada() As String
            TabelaLinhaQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaLinha())
        End Function

        Shared Function TabelaFamiliaQualificada() As String
            TabelaFamiliaQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaFamilia())
        End Function

        Shared Function TabelaProdutoQualificada() As String
            TabelaProdutoQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaProduto())
        End Function

        Shared Function TabelaProdutoVinculoQualificada() As String
            TabelaProdutoVinculoQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaProdutoVinculo())
        End Function

        Shared Function TabelaProdutoImagemQualificada() As String
            TabelaProdutoImagemQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaProdutoImagem())
        End Function

        Shared Function TabelaProdutoSyncProgressoQualificada() As String
            TabelaProdutoSyncProgressoQualificada = IntegracaoSchema.NomeQualificado(IntegracaoSchema.TabelaProdutoSyncProgresso())
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
        Sub New()
            MyBase.New()
        End Sub

    End Class
End Namespace
