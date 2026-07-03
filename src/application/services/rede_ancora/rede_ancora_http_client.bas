Imports mod_tobject
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_model
Imports http_client

Namespace rede_ancora_http_client
    Class RedeAncoraHttpClient
        Inherits TTObject

        Shared Function Criar(pAuth As RedeAncoraAutenticacaoModel) As HttpClient
            Dim _client As New HttpClient(RedeAncoraApiConfig.BaseUrl())
            _client.SetJsonContentType()
            _client.ConfigureTimeouts(5000, 30000, 60000, 180000)

            If Assigned(pAuth) Then
                If pAuth.ChaveApi <> "" Then
                    _client.SetApiKey(pAuth.ChaveApi)
                End If
            End If

            Criar = _client
        End Function

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
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
