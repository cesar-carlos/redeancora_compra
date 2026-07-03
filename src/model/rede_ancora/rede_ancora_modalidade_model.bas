Imports mod_tobject

Namespace rede_ancora_modalidade_model
    Class RedeAncoraModalidadeModel
        Inherits TTObject

        CodModalidade As Integer
        Descricao As String

        Sub New()
            MyBase.New()
            me.Descricao = ""
        End Sub

        Sub New(pValue As RedeAncoraModalidadeModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As RedeAncoraModalidadeModel)
            If Assigned(pValue) Then
                me.CodModalidade = pValue.CodModalidade
                me.Descricao = pValue.Descricao
            End If
        End Sub

        Sub Validate()
            If me.CodModalidade <= 0 Then
                Throw New System.Exception("CodModalidade invalido em RedeAncoraModalidadeModel")
            End If

            If me.Descricao.Trim() = "" Then
                Throw New System.Exception("Descricao invalida em RedeAncoraModalidadeModel")
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraModalidadeModel
            Clone = New RedeAncoraModalidadeModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = me.CodModalidade.ToString()
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
                Throw New System.Exception("Erro ao liberar RedeAncoraModalidadeModel: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
