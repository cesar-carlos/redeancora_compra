Imports mod_tobject
Imports rede_ancora_autenticacao_model
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_config
Imports rede_ancora_http_client
Imports mod_logger
Imports http_response
Imports http_client

Namespace rede_ancora_api_client
    Class RedeAncoraApiClient
        Inherits TTObject

        Private _codUsuario As Integer
        Private _authService As RedeAncoraAutenticacaoService
        Private _authServiceExterno As Boolean
        Private _auth As RedeAncoraAutenticacaoModel

        Sub New(pCodUsuario As Integer)
            MyBase.New()
            me._codUsuario = pCodUsuario
            me._authService = New RedeAncoraAutenticacaoService()
            me._authServiceExterno = False
        End Sub

        Sub New(pCodUsuario As Integer, pAuthService As RedeAncoraAutenticacaoService)
            MyBase.New()
            me._codUsuario = pCodUsuario
            me._authService = pAuthService
            me._authServiceExterno = True
        End Sub

        Function GetRequest(pUrl As String) As HttpResponse
            GetRequest = me.Executar("GET", pUrl, "")
        End Function

        Function PostJson(pUrl As String, pBody As String) As HttpResponse
            PostJson = me.Executar("POST", pUrl, pBody)
        End Function

        Function PatchJson(pUrl As String, pBody As String) As HttpResponse
            PatchJson = me.Executar("PATCH", pUrl, pBody)
        End Function

        Function DeleteRequest(pUrl As String, pBody As String) As HttpResponse
            DeleteRequest = me.Executar("DELETE", pUrl, pBody)
        End Function

        Private Function Executar(pMethod As String, pUrl As String, pBody As String) As HttpResponse
            Dim _client As HttpClient = Null
            Dim _response As HttpResponse = Null
            Dim _result As HttpResponse = Null
            Dim _tentativa429 As Integer = 0
            Dim _tentativa500 As Integer = 0
            Dim _tentativa504 As Integer = 0
            Dim _tentarNovamente As Boolean = True

            Try
                me.GarantirAutenticacao()

                While _tentarNovamente
                    _tentarNovamente = False
                    _client = RedeAncoraHttpClient.Criar(me._auth)
                    me.LogarRequisicao(pMethod, pUrl, pBody)
                    _response = me.Enviar(_client, pMethod, pUrl, pBody)
                    _client.Free()
                    _client = Null
                    me.LogarResposta(pMethod, pUrl, _response)

                    If _response.StatusCode = 401 Then
                        Dim _mensagem As String = "Chave API Rede Ancora invalida ou sem permissao (HTTP 401)."
                        _response.Free()
                        _response = Null
                        Throw New System.Exception(_mensagem)
                    ElseIf _response.StatusCode = 429 And _tentativa429 < 3 Then
                        me.AguardarBackoff429(_tentativa429)
                        _tentativa429 = _tentativa429 + 1
                        _response.Free()
                        _response = Null
                        _tentarNovamente = True
                    ElseIf _response.StatusCode = 500 And _tentativa500 < 1 Then
                        me.AguardarSegundos(30)
                        _tentativa500 = _tentativa500 + 1
                        _response.Free()
                        _response = Null
                        _tentarNovamente = True
                    ElseIf _response.StatusCode = 504 And _tentativa504 < 2 Then
                        me.AguardarSegundos(30)
                        _tentativa504 = _tentativa504 + 1
                        _response.Free()
                        _response = Null
                        _tentarNovamente = True
                    End If
                Wend

                _result = _response
                _response = Null
            Catch ex As Exception
                If Assigned(_client) Then
                    _client.Free()
                    _client = Null
                End If

                If Assigned(_response) Then
                    _response.Free()
                    _response = Null
                End If

                Throw ex
            End Try

            Executar = _result
        End Function

        Private Sub LogarRequisicao(pMethod As String, pUrl As String, pBody As String)
            Dim _mensagem As String = "REQ " + pMethod + " " + pUrl

            If RedeAncoraApiConfig.LogHttpBodies() And pBody <> "" Then
                _mensagem = _mensagem + " body=" + me.TruncarLog(pBody)
            End If

            mod_logger.Log(mod_logger.LogLevel.HttpValue(), _mensagem)
        End Sub

        Private Sub LogarResposta(pMethod As String, pUrl As String, pResponse As HttpResponse)
            Dim _mensagem As String = "RES " + pMethod + " " + pUrl + " -> " + pResponse.StatusCode.ToString()

            If RedeAncoraApiConfig.LogHttpBodies() And pResponse.Body <> "" Then
                _mensagem = _mensagem + " body=" + me.TruncarLog(pResponse.Body)
            End If

            mod_logger.Log(mod_logger.LogLevel.HttpValue(), _mensagem)
        End Sub

        Private Function TruncarLog(pTexto As String) As String
            If Len(pTexto) <= 2000 Then
                TruncarLog = pTexto
                Exit Function
            End If

            TruncarLog = Mid(pTexto, 1, 2000) + "...[truncado]"
        End Function

        Private Sub AguardarBackoff429(pTentativa As Integer)
            If pTentativa = 0 Then
                me.AguardarSegundos(60)
                Exit Sub
            End If

            If pTentativa = 1 Then
                me.AguardarSegundos(120)
                Exit Sub
            End If

            me.AguardarSegundos(300)
        End Sub

        Private Sub AguardarSegundos(pSegundos As Integer)
            Dim _fim As TDateTime = DateTime()

            _fim = _fim.AddSeconds(pSegundos)

            While DateTime() < _fim
            Wend
        End Sub

        Private Sub GarantirAutenticacao()
            If Assigned(me._auth) Then
                Exit Sub
            End If

            me._auth = me._authService.GarantirChaveApi(me._codUsuario)
        End Sub

        Private Function Enviar(pClient As HttpClient, pMethod As String, pUrl As String, pBody As String) As HttpResponse
            If pMethod = "GET" Then
                Enviar = pClient.GetRequest(pUrl)
                Exit Function
            End If

            If pMethod = "POST" Then
                Enviar = pClient.PostJson(pUrl, pBody)
                Exit Function
            End If

            If pMethod = "PATCH" Then
                Enviar = pClient.PatchJson(pUrl, pBody)
                Exit Function
            End If

            If pMethod = "DELETE" Then
                Enviar = pClient.DeleteRequest(pUrl, pBody)
                Exit Function
            End If

            Throw New System.Exception("Metodo HTTP nao suportado em RedeAncoraApiClient: " + pMethod)
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._auth) Then
                    me._auth.Free()
                    me._auth = Null
                End If

                If Assigned(me._authService) Then
                    If Not me._authServiceExterno Then
                        me._authService.Free()
                        me._authService = Null
                    End If
                End If

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
