Imports mod_tobject

Namespace rede_ancora_centro_distribuicao_model
    Class RedeAncoraCentroDistribuicaoModel
        Inherits TTObject

        CodUsuario As Integer
        CodCentroDistribuicao As Integer
        Nome As String
        NomeFantasia As String
        CodEstado As Integer
        Preferencial As String

        Sub New()
            MyBase.New()
            me.Nome = ""
            me.NomeFantasia = ""
            me.Preferencial = "N"
        End Sub

        Sub New(pValue As RedeAncoraCentroDistribuicaoModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As RedeAncoraCentroDistribuicaoModel)
            If Assigned(pValue) Then
                me.CodUsuario = pValue.CodUsuario
                me.CodCentroDistribuicao = pValue.CodCentroDistribuicao
                me.Nome = pValue.Nome
                me.NomeFantasia = pValue.NomeFantasia
                me.CodEstado = pValue.CodEstado
                me.Preferencial = pValue.Preferencial
            End If
        End Sub

        Sub Validate()
            If me.CodUsuario <= 0 Then
                Throw New System.Exception("CodUsuario invalido em RedeAncoraCentroDistribuicaoModel")
            End If

            If me.CodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido em RedeAncoraCentroDistribuicaoModel")
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraCentroDistribuicaoModel
            Clone = New RedeAncoraCentroDistribuicaoModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = me.CodCentroDistribuicao.ToString()
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
                Throw New System.Exception("Erro ao liberar RedeAncoraCentroDistribuicaoModel: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
