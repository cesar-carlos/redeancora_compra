Imports mod_tobject

Namespace rede_ancora_api_config
    Private Dim _usarStaging As Boolean = False
    Private Dim _logarHttpCorpos As Boolean = False
    Private Dim _desabilitarValidarProdutoAntesCarrinho As Boolean = False
    Private Dim _tamanhoChunkSincronizacaoProdutos As Integer = 100

    Class RedeAncoraApiConfig
        Inherits TTObject

        Shared Function TamanhoChunkSincronizacaoProdutos() As Integer
            If _tamanhoChunkSincronizacaoProdutos <= 0 Then
                TamanhoChunkSincronizacaoProdutos = 100
            Else
                TamanhoChunkSincronizacaoProdutos = _tamanhoChunkSincronizacaoProdutos
            End If
        End Function

        Shared Sub DefinirTamanhoChunkSincronizacaoProdutos(pTamanho As Integer)
            If pTamanho <= 0 Then
                _tamanhoChunkSincronizacaoProdutos = 100
            Else
                _tamanhoChunkSincronizacaoProdutos = pTamanho
            End If
        End Sub

        Shared Function UsarStaging() As Boolean
            UsarStaging = _usarStaging
        End Function

        Shared Sub DefinirStaging(pUsarStaging As Boolean)
            _usarStaging = pUsarStaging
        End Sub

        Shared Function LogHttpBodies() As Boolean
            LogHttpBodies = _logarHttpCorpos
        End Function

        Shared Sub DefinirLogHttpBodies(pLogarCorpos As Boolean)
            _logarHttpCorpos = pLogarCorpos
        End Sub

        Shared Function ValidarProdutoAntesCarrinho() As Boolean
            ValidarProdutoAntesCarrinho = Not _desabilitarValidarProdutoAntesCarrinho
        End Function

        Shared Sub DefinirValidarProdutoAntesCarrinho(pValidar As Boolean)
            If pValidar Then
                _desabilitarValidarProdutoAntesCarrinho = False
            Else
                _desabilitarValidarProdutoAntesCarrinho = True
            End If
        End Sub

        Shared Function BaseUrl() As String
            If RedeAncoraApiConfig.UsarStaging() Then
                BaseUrl = RedeAncoraApiConfig.StagingBaseUrl()
                Exit Function
            End If

            BaseUrl = "https://app.redeancora.com.br/b2b"
        End Function

        Shared Function StagingBaseUrl() As String
            StagingBaseUrl = "https://app.stg.redeancora.com.br/b2b"
        End Function

        Shared Function IntegrationPath() As String
            ' Swagger: BaseUrl (/b2b) + /api/api/integration/v1 + /endpoint
            IntegrationPath = "/api/api/integration/v1"
        End Function

        Shared Function IntegrationUrl(pPath As String) As String
            Dim _path As String = pPath

            If _path <> "" And Mid(_path, 1, 1) <> "/" Then
                _path = "/" + _path
            End If

            IntegrationUrl = RedeAncoraApiConfig.BaseUrl() + RedeAncoraApiConfig.IntegrationPath() + _path
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
