Imports mod_tobject

Namespace rede_ancora_produto_model
    ' Cadastro de produto Rede Ancora (CNA). Nao e vinculo ERP.
    Class RedeAncoraProdutoModel
        Inherits TTObject

        Cna As Integer
        CatalogoId As Integer
        Csa As String
        Cnl As String
        CodigoReferencia As String
        CodeEdi As String
        CodeManufacturer As String
        NomeProduto As String
        NomeErp As String
        InformacoesAdicionais As String
        InformacoesComplementares As String
        AdditionalDescription As String
        PontoCriticoAtencao As String
        Dimensoes As String
        CodMarca As Integer
        CodMarcaErp As Integer
        NomeMarca As String
        CodLinha As Integer
        NomeLinha As String
        CodFamilia As Integer
        NomeFamilia As String
        CodFabricante As Integer
        Ean As String
        Gtin As String
        Ncm As String
        Cest As String
        Origem As String
        OrigemLabel As String
        Anp As Integer
        AnpLabel As String
        PesoLiquido As Double
        PesoBruto As Double
        Volume As Double
        Litros As Double
        Tamanho As String
        Material As String
        Tipo As Integer
        MedidaVenda As String
        GarantiaDias As Integer
        FracaoFabrica As Integer
        FracaoLoja As Integer
        Status As Integer
        ErpHandle As Integer
        Leadtime As Integer
        Ativo As String
        Descontinuado As String
        Bloqueado As String
        Confiavel As String
        Sugerido As String
        Lancamento As String
        OnDemand As String
        OnDemandLabel As String
        MotivoDescontinuado As String
        ParcialmenteSimilar As String
        HasRestrictions As String
        PrazoEspecial As String
        DataAtualizacao As TDateTime

        Sub New()
            MyBase.New()
            me.Csa = ""
            me.Cnl = ""
            me.CodigoReferencia = ""
            me.CodeEdi = ""
            me.CodeManufacturer = ""
            me.NomeProduto = ""
            me.NomeErp = ""
            me.InformacoesAdicionais = ""
            me.InformacoesComplementares = ""
            me.AdditionalDescription = ""
            me.PontoCriticoAtencao = ""
            me.Dimensoes = ""
            me.NomeMarca = ""
            me.NomeLinha = ""
            me.NomeFamilia = ""
            me.Ean = ""
            me.Gtin = ""
            me.Ncm = ""
            me.Cest = ""
            me.Origem = ""
            me.OrigemLabel = ""
            me.AnpLabel = ""
            me.Tamanho = ""
            me.Material = ""
            me.MedidaVenda = ""
            me.Ativo = "S"
            me.Descontinuado = ""
            me.Bloqueado = ""
            me.Confiavel = ""
            me.Sugerido = ""
            me.Lancamento = ""
            me.OnDemand = ""
            me.OnDemandLabel = ""
            me.MotivoDescontinuado = ""
            me.ParcialmenteSimilar = ""
            me.HasRestrictions = ""
            me.PrazoEspecial = ""
        End Sub

        Sub New(pValue As RedeAncoraProdutoModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As RedeAncoraProdutoModel)
            If Assigned(pValue) Then
                me.Cna = pValue.Cna
                me.CatalogoId = pValue.CatalogoId
                me.Csa = pValue.Csa
                me.Cnl = pValue.Cnl
                me.CodigoReferencia = pValue.CodigoReferencia
                me.CodeEdi = pValue.CodeEdi
                me.CodeManufacturer = pValue.CodeManufacturer
                me.NomeProduto = pValue.NomeProduto
                me.NomeErp = pValue.NomeErp
                me.InformacoesAdicionais = pValue.InformacoesAdicionais
                me.InformacoesComplementares = pValue.InformacoesComplementares
                me.AdditionalDescription = pValue.AdditionalDescription
                me.PontoCriticoAtencao = pValue.PontoCriticoAtencao
                me.Dimensoes = pValue.Dimensoes
                me.CodMarca = pValue.CodMarca
                me.CodMarcaErp = pValue.CodMarcaErp
                me.NomeMarca = pValue.NomeMarca
                me.CodLinha = pValue.CodLinha
                me.NomeLinha = pValue.NomeLinha
                me.CodFamilia = pValue.CodFamilia
                me.NomeFamilia = pValue.NomeFamilia
                me.CodFabricante = pValue.CodFabricante
                me.Ean = pValue.Ean
                me.Gtin = pValue.Gtin
                me.Ncm = pValue.Ncm
                me.Cest = pValue.Cest
                me.Origem = pValue.Origem
                me.OrigemLabel = pValue.OrigemLabel
                me.Anp = pValue.Anp
                me.AnpLabel = pValue.AnpLabel
                me.PesoLiquido = pValue.PesoLiquido
                me.PesoBruto = pValue.PesoBruto
                me.Volume = pValue.Volume
                me.Litros = pValue.Litros
                me.Tamanho = pValue.Tamanho
                me.Material = pValue.Material
                me.Tipo = pValue.Tipo
                me.MedidaVenda = pValue.MedidaVenda
                me.GarantiaDias = pValue.GarantiaDias
                me.FracaoFabrica = pValue.FracaoFabrica
                me.FracaoLoja = pValue.FracaoLoja
                me.Status = pValue.Status
                me.ErpHandle = pValue.ErpHandle
                me.Leadtime = pValue.Leadtime
                me.Ativo = pValue.Ativo
                me.Descontinuado = pValue.Descontinuado
                me.Bloqueado = pValue.Bloqueado
                me.Confiavel = pValue.Confiavel
                me.Sugerido = pValue.Sugerido
                me.Lancamento = pValue.Lancamento
                me.OnDemand = pValue.OnDemand
                me.OnDemandLabel = pValue.OnDemandLabel
                me.MotivoDescontinuado = pValue.MotivoDescontinuado
                me.ParcialmenteSimilar = pValue.ParcialmenteSimilar
                me.HasRestrictions = pValue.HasRestrictions
                me.PrazoEspecial = pValue.PrazoEspecial
                me.DataAtualizacao = pValue.DataAtualizacao
            End If
        End Sub

        Function IsAtivo() As Boolean
            IsAtivo = me.Ativo = "S"
        End Function

        Function CodMarcaParaVinculo() As Integer
            If me.CodMarcaErp > 0 Then
                CodMarcaParaVinculo = me.CodMarcaErp
            Else
                CodMarcaParaVinculo = me.CodMarca
            End If
        End Function

        Sub Validate()
            If me.Cna <= 0 Then
                Throw New System.Exception("Cna invalido em RedeAncoraProdutoModel")
            End If

            If me.Ativo <> "S" Then
                If me.Ativo <> "N" Then
                    Throw New System.Exception("Ativo invalido em RedeAncoraProdutoModel")
                End If
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraProdutoModel
            Clone = New RedeAncoraProdutoModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = me.Cna.ToString()
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            Try
                If Not me.Disposed Then
                    me.Dispose()
                End If

                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Erro ao liberar RedeAncoraProdutoModel: " & Char(13) & ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
