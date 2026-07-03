Imports mod_tobject
Imports mod_tlist

Namespace rede_ancora_produto_cnas_model
    Class RedeAncoraProdutoCnasModel
        Inherits TTList<Integer>

        Public Sub New()
            MyBase.New()
        End Sub

        Sub ValidarTodos()
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i) <= 0 Then
                    Throw New System.Exception("Cna invalido em RedeAncoraProdutoCnasModel")
                End If
            Next
        End Sub

        Function Contem(pCna As Integer) As Boolean
            Dim _i As Integer

            For _i = 0 To me.Length - 1
                If me.Take(_i) = pCna Then
                    Contem = True
                    Exit Function
                End If
            Next
        End Function

        Sub PushDistinct(pCna As Integer)
            If pCna <= 0 Then
                Exit Sub
            End If

            If Not me.Contem(pCna) Then
                me.Push(pCna)
            End If
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
