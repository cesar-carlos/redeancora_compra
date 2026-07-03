Imports mod_tobject

Namespace rede_ancora_produto_preco_estoque_model
    Class RedeAncoraProdutoPrecoEstoqueModel
        Inherits TTObject

        Cna As Integer
        CodCentroDistribuicao As Integer
        CodEstado As Integer
        QtdDisponivel As Integer
        QtdProjetada As Integer
        PrecoTabela As Double
        StTabela As Double
        PrecoCrossDocking As Double
        PrecoCompraJunto As Double

        Sub New()
            MyBase.New()
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
