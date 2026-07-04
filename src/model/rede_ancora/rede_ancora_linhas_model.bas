Imports mod_tobject
Imports rede_ancora_linha_model
Imports mod_tlist

Namespace rede_ancora_linhas_model
    Class RedeAncoraLinhasModel
        Inherits TTList<RedeAncoraLinhaModel>

        Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
