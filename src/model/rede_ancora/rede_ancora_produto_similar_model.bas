Imports mod_tobject

Namespace rede_ancora_produto_similar_model
    Class RedeAncoraProdutoSimilarModel
        Inherits TTObject

        Cna As Integer
        CodCentroDistribuicao As Integer
        CodEstado As Integer
        CnaSimilar As Integer
        CodigoReferencia As String
        Nome As String
        NomeMarca As String
        CodMarca As Integer
        DataAtualizacao As TDateTime

        Sub New()
            MyBase.New()
            me.CodigoReferencia = ""
            me.Nome = ""
            me.NomeMarca = ""
        End Sub

        Overrides Function GetID() As String
            GetID = me.Cna.ToString() + "-" + me.CnaSimilar.ToString()
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
