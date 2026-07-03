Imports mod_tobject

Namespace rede_ancora_produto_vinculo_model
    ' Produto Rede Ancora (CNA) com vinculo opcional ao Produto.CodProduto local.
    Class RedeAncoraProdutoVinculoModel
        Inherits TTObject

        Cna As Integer
        CodProduto As Integer
        CodigoAncora As String
        DescricaoAncora As String
        CodMarca As Integer
        CodLinha As Integer
        CodFamilia As Integer
        Ativo As String
        DataVinculo As TDateTime
        DataAtualizacao As TDateTime
        OrigemVinculo As String
        Observacao As String

        Sub New()
            MyBase.New()
            me.CodigoAncora = ""
            me.DescricaoAncora = ""
            me.Ativo = "S"
            me.OrigemVinculo = ""
            me.Observacao = ""
        End Sub

        Sub New(pValue As RedeAncoraProdutoVinculoModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As RedeAncoraProdutoVinculoModel)
            If Assigned(pValue) Then
                me.Cna = pValue.Cna
                me.CodProduto = pValue.CodProduto
                me.CodigoAncora = pValue.CodigoAncora
                me.DescricaoAncora = pValue.DescricaoAncora
                me.CodMarca = pValue.CodMarca
                me.CodLinha = pValue.CodLinha
                me.CodFamilia = pValue.CodFamilia
                me.Ativo = pValue.Ativo
                me.DataVinculo = pValue.DataVinculo
                me.DataAtualizacao = pValue.DataAtualizacao
                me.OrigemVinculo = pValue.OrigemVinculo
                me.Observacao = pValue.Observacao
            End If
        End Sub

        Function IsAtivo() As Boolean
            IsAtivo = me.Ativo = "S"
        End Function

        Function IsVinculado() As Boolean
            IsVinculado = me.CodProduto > 0
        End Function

        Sub Validate()
            If me.Cna <= 0 Then
                Throw New System.Exception("Cna invalido em RedeAncoraProdutoVinculoModel")
            End If

            If me.Ativo <> "S" And me.Ativo <> "N" Then
                Throw New System.Exception("Ativo invalido em RedeAncoraProdutoVinculoModel")
            End If
        End Sub

        Sub ValidateVinculo()
            me.Validate()

            If me.CodProduto <= 0 Then
                Throw New System.Exception("CodProduto invalido para vinculo em RedeAncoraProdutoVinculoModel")
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraProdutoVinculoModel
            Clone = New RedeAncoraProdutoVinculoModel(me)
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
                Throw New System.Exception("Erro ao liberar RedeAncoraProdutoVinculoModel: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
