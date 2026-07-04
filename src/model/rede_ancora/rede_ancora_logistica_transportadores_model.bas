Imports mod_tobject
Imports mod_tlist
Imports rede_ancora_logistica_transportador_model

Namespace rede_ancora_logistica_transportadores_model
    Class RedeAncoraLogisticaTransportadoresModel
        Inherits TTList<RedeAncoraLogisticaTransportadorModel>

        Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
