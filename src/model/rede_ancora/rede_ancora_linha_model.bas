Imports mod_tobject

Namespace rede_ancora_linha_model
    Class RedeAncoraLinhaModel
        Inherits TTObject

        CodLinha As Integer
        Nome As String

        Sub New()
            MyBase.New()
            me.Nome = ""
        End Sub

        Sub Validate()
            If me.CodLinha <= 0 Then
                Throw New System.Exception("CodLinha invalido em RedeAncoraLinhaModel")
            End If

            If me.Nome.Trim() = "" Then
                Throw New System.Exception("Nome invalido em RedeAncoraLinhaModel")
            End If
        End Sub

        Overrides Function GetID() As String
            GetID = me.CodLinha.ToString()
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
