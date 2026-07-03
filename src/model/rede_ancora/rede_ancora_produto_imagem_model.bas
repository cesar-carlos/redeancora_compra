Imports mod_tobject

Namespace rede_ancora_produto_imagem_model
    Class RedeAncoraProdutoImagemModel
        Inherits TTObject

        Cna As Integer
        Item As String
        TipoImagem As String
        DataAtualizacao As TDateTime
        Url As String

        Sub New()
            MyBase.New()
            me.Item = ""
            me.TipoImagem = ""
            me.Url = ""
        End Sub

        Sub New(pValue As RedeAncoraProdutoImagemModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As RedeAncoraProdutoImagemModel)
            If Assigned(pValue) Then
                me.Cna = pValue.Cna
                me.Item = pValue.Item
                me.TipoImagem = pValue.TipoImagem
                me.DataAtualizacao = pValue.DataAtualizacao
                me.Url = pValue.Url
            End If
        End Sub

        Sub Validate()
            If me.Cna <= 0 Then
                Throw New System.Exception("Cna invalido em RedeAncoraProdutoImagemModel")
            End If

            If me.Item.Trim() = "" Then
                Throw New System.Exception("Item invalido em RedeAncoraProdutoImagemModel")
            End If

            If me.TipoImagem.Trim() = "" Then
                Throw New System.Exception("TipoImagem invalido em RedeAncoraProdutoImagemModel")
            End If

            If me.Url.Trim() = "" Then
                Throw New System.Exception("Url invalida em RedeAncoraProdutoImagemModel")
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraProdutoImagemModel
            Clone = New RedeAncoraProdutoImagemModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = me.Cna.ToString() + "-" + me.Item + "-" + me.TipoImagem
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
                Throw New System.Exception("Erro ao liberar RedeAncoraProdutoImagemModel: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
