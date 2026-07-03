Imports mod_tobject

Namespace rede_ancora_input_criar_transportador
    Class RedeAncoraInputCriarTransportador
        Inherits TTObject

        CodUsuario As Integer
        Nome As String
        TipoDocumento As String
        Documento As String
        TipoVeiculo As String
        PlacaVeiculo As String
        PessoaContato As String
        TelefoneContato As String
        Observacoes As String
        Habilitado As Boolean

        Sub New()
            MyBase.New()
            me.Nome = ""
            me.TipoDocumento = ""
            me.Documento = ""
            me.TipoVeiculo = ""
            me.PlacaVeiculo = ""
            me.PessoaContato = ""
            me.TelefoneContato = ""
            me.Observacoes = ""
            me.Habilitado = True
        End Sub

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
