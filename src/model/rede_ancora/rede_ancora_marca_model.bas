Imports mod_tobject

Namespace rede_ancora_marca_model
    Class RedeAncoraMarcaModel
        Inherits TTObject

        CodMarca As Integer
        Nome As String
        CodCatalogo As Integer
        CodErp As Integer

        Sub New()
            MyBase.New()
            me.Nome = ""
        End Sub

        Sub Validate()
            If me.CodMarca <= 0 Then
                Throw New System.Exception("CodMarca invalido em RedeAncoraMarcaModel")
            End If

            If me.Nome.Trim() = "" Then
                Throw New System.Exception("Nome invalido em RedeAncoraMarcaModel")
            End If
        End Sub

        Overrides Function GetID() As String
            GetID = me.CodMarca.ToString()
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
