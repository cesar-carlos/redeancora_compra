Imports mod_tobject
Imports rede_ancora_familia_model
Imports mod_tlist

Namespace rede_ancora_familias_model
    Class RedeAncoraFamiliasModel
        Inherits TTList<RedeAncoraFamiliaModel>

        Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
