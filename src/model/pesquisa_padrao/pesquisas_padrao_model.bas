Imports pesquisa_padrao_model
Imports mod_tlist

Namespace pesquisas_padrao_model
    Class PesquisasPadraoModel
        Inherits TTList<PesquisaPadraoModel>

        Public Sub New()
            MyBase.New()
        End Sub

        Function FindByTableCode(pTableCode As Integer) As PesquisaPadraoModel
            Dim _i As Integer
            For _i = 0 To me.Length - 1
                If me.Take(_i).TableCode = pTableCode Then
                    FindByTableCode = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
