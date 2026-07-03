Imports mod_tobject
Imports try_parser

Namespace rede_ancora_carrinho_item_model
    Class RedeAncoraCarrinhoItemModel
        Inherits TTObject

        CodCarrinho As Integer
        Item As String
        IdItemApi As Integer
        Cna As Integer
        CodCentroDistribuicao As Integer
        CodCondicaoPagamento As Integer
        DescricaoCondicaoPagamento As String
        CodProduto As Integer
        CodigoReferenciaFabricante As String
        Descricao As String
        CodModalidade As Integer
        Quantidade As Integer
        PrecoUnitario As Double
        ImpostoUnitario As Double
        CodUsuario As Integer
        NomeUsuario As String
        DataLancamento As TDateTime
        HoraLancamento As String
        EstacaoTrabalho As String

        Sub New()
            MyBase.New()
            me.CodCarrinho = 0
            me.Item = ""
            me.CodigoReferenciaFabricante = ""
            me.Descricao = ""
            me.DescricaoCondicaoPagamento = ""
            me.NomeUsuario = ""
            me.HoraLancamento = ""
            me.EstacaoTrabalho = ""
            me.CodUsuario = 0
            me.DataLancamento = Parser.StringToDate("01/01/1900")
        End Sub

        Sub New(pValue As RedeAncoraCarrinhoItemModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As RedeAncoraCarrinhoItemModel)
            If Assigned(pValue) Then
                me.CodCarrinho = pValue.CodCarrinho
                me.Item = pValue.Item
                me.IdItemApi = pValue.IdItemApi
                me.Cna = pValue.Cna
                me.CodCentroDistribuicao = pValue.CodCentroDistribuicao
                me.CodCondicaoPagamento = pValue.CodCondicaoPagamento
                me.DescricaoCondicaoPagamento = pValue.DescricaoCondicaoPagamento
                me.CodProduto = pValue.CodProduto
                me.CodigoReferenciaFabricante = pValue.CodigoReferenciaFabricante
                me.Descricao = pValue.Descricao
                me.CodModalidade = pValue.CodModalidade
                me.Quantidade = pValue.Quantidade
                me.PrecoUnitario = pValue.PrecoUnitario
                me.ImpostoUnitario = pValue.ImpostoUnitario
                me.CodUsuario = pValue.CodUsuario
                me.NomeUsuario = pValue.NomeUsuario
                me.DataLancamento = pValue.DataLancamento
                me.HoraLancamento = pValue.HoraLancamento
                me.EstacaoTrabalho = pValue.EstacaoTrabalho
            End If
        End Sub

        Function PossuiAuditoriaLancamento() As Boolean
            PossuiAuditoriaLancamento = me.CodUsuario > 0
        End Function

        Sub LimparAuditoriaLancamento()
            me.CodUsuario = 0
            me.NomeUsuario = ""
            me.DataLancamento = Parser.StringToDate("01/01/1900")
            me.HoraLancamento = ""
            me.EstacaoTrabalho = ""
        End Sub

        Sub CopiarAuditoriaLancamento(pOrigem As RedeAncoraCarrinhoItemModel)
            If Not Assigned(pOrigem) Then
                me.LimparAuditoriaLancamento()
                Exit Sub
            End If

            If Not pOrigem.PossuiAuditoriaLancamento() Then
                me.LimparAuditoriaLancamento()
                Exit Sub
            End If

            me.CodUsuario = pOrigem.CodUsuario
            me.NomeUsuario = pOrigem.NomeUsuario
            me.DataLancamento = pOrigem.DataLancamento
            me.HoraLancamento = pOrigem.HoraLancamento
            me.EstacaoTrabalho = pOrigem.EstacaoTrabalho
        End Sub

        Sub Validate()
            If me.CodCarrinho <= 0 Then
                Throw New System.Exception("CodCarrinho invalido em RedeAncoraCarrinhoItemModel")
            End If

            If me.Item.Trim() = "" Then
                Throw New System.Exception("Item invalido em RedeAncoraCarrinhoItemModel")
            End If

            If me.IdItemApi <= 0 Then
                Throw New System.Exception("IdItemApi invalido em RedeAncoraCarrinhoItemModel")
            End If

            If me.Cna <= 0 Then
                Throw New System.Exception("Cna invalido em RedeAncoraCarrinhoItemModel")
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraCarrinhoItemModel
            Clone = New RedeAncoraCarrinhoItemModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = Parser.IntegerToString(me.CodCarrinho) + "-" + me.Item
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
                Throw New System.Exception("Erro ao liberar RedeAncoraCarrinhoItemModel: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
