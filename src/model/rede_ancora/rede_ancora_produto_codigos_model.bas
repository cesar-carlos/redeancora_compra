Imports mod_tobject
Imports mod_tlist

Namespace rede_ancora_produto_codigos_model
    Class RedeAncoraProdutoCodigosModel
        Inherits TTList<String>

        Sub New()
            MyBase.New()
        End Sub

        Sub ValidarTodos()
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i).Trim() = "" Then
                    Throw New System.Exception("Codigo invalido em RedeAncoraProdutoCodigosModel")
                End If
            Next
        End Sub

        Function Contem(pCodigo As String) As Boolean
            Dim _i As Integer
            Dim _codigo As String = pCodigo.Trim()

            For _i = 0 To me.Length - 1
                If me.Take(_i).Trim() = _codigo Then
                    Contem = True
                    Exit Function
                End If
            Next
        End Function

        Sub PushDistinct(pCodigo As String)
            Dim _codigo As String = pCodigo.Trim()

            If _codigo = "" Then
                Exit Sub
            End If

            If Not me.Contem(_codigo) Then
                me.Push(_codigo)
            End If
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
