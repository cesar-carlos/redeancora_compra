Imports mod_tobject

Namespace rede_ancora_familia_model
    Class RedeAncoraFamiliaModel
        Inherits TTObject

        CodFamilia As Integer
        Nome As String

        Sub New()
            MyBase.New()
            me.Nome = ""
        End Sub

        Sub Validate()
            If me.CodFamilia <= 0 Then
                Throw New System.Exception("CodFamilia invalido em RedeAncoraFamiliaModel")
            End If

            If me.Nome.Trim() = "" Then
                Throw New System.Exception("Nome invalido em RedeAncoraFamiliaModel")
            End If
        End Sub

        Overrides Function GetID() As String
            GetID = me.CodFamilia.ToString()
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
