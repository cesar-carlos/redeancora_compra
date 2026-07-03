Imports mod_tobject

Namespace rede_ancora_produto_imagem_tipo
    Class RedeAncoraProdutoImagemTipo
        Inherits TTObject

        Shared Function Real() As String
            Real = "REAL"
        End Function

        Shared Function Ilustrativa() As String
            Ilustrativa = "ILUSTRATIVA"
        End Function

        Shared Function Tecnica() As String
            Tecnica = "TECNICA"
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
