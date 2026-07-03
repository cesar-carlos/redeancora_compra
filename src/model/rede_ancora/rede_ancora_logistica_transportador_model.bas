Imports mod_tobject

Namespace rede_ancora_logistica_transportador_model
    Class RedeAncoraLogisticaTransportadorModel
        Inherits TTObject

        CodTransportador As Integer
        Nome As String

        Sub New()
            MyBase.New()
            me.Nome = ""
        End Sub

        Overrides Function GetID() As String
            GetID = me.CodTransportador.ToString()
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
