' WinHttp.WinHttpRequest.5.1 COM wrapper.
'
' IMPORTANT: Do NOT use the Option(n) = value indexed property setter.
' In Data7/Delphi Variant late-binding, indexed COM property setters
' (put-dispatch with parameters) cause access violations.
' All other WinHTTP calls (Open, SetRequestHeader, SetTimeouts, Send,
' Status, StatusText, ResponseText work correctly via Variant.
' GetAllResponseHeaders returns UnicodeString — not convertible to String at compile time in Data7.
'
' Mandatory call order inside each request:
'   SetProxy  →  SetTimeouts  →  Open  →  SetRequestHeader  →  SetCredentials  →  Send

Imports mod_tobject
Imports mod_logger
Imports try_parser
Imports http_header
Imports http_response

Namespace http_client
    Class HttpClient
        Inherits TTObject

        Private _baseUrl As String

        ' Proxy — modes: 0=system, 1=direct, 2=custom
        Private _proxyMode As Integer
        Private _proxyServer As String
        Private _proxyBypass As String

        ' HTTP authentication
        Private _serverUser As String
        Private _serverPassword As String
        Private _proxyUser As String
        Private _proxyPassword As String

        ' Timeouts in milliseconds
        Private _resolveTimeout As Integer
        Private _connectTimeout As Integer
        Private _sendTimeout As Integer
        Private _receiveTimeout As Integer

        ' Request headers
        Private _headers As HttpHeader

        ' ------------------------------------------------------------------
        ' Construction
        ' ------------------------------------------------------------------

        Sub New()
            MyBase.New()
            me.InitDefaults("")
        End Sub

        Sub New(pBaseUrl As String)
            MyBase.New()
            me.InitDefaults(pBaseUrl)
        End Sub

        Private Sub InitDefaults(pBaseUrl As String)
            me._baseUrl = pBaseUrl
            me._proxyMode = 0
            me._proxyServer = ""
            me._proxyBypass = ""
            me._serverUser = ""
            me._serverPassword = ""
            me._proxyUser = ""
            me._proxyPassword = ""
            me._resolveTimeout = 5000
            me._connectTimeout = 30000
            me._sendTimeout = 30000
            me._receiveTimeout = 60000
            me._headers = New HttpHeader()
        End Sub

        ' ------------------------------------------------------------------
        ' Connection configuration (no-ops kept for API compatibility)
        ' ------------------------------------------------------------------

        Sub SetBaseUrl(pBaseUrl As String)
            me._baseUrl = pBaseUrl
        End Sub

        ' Implementado via header (SetRequestHeader e seguro no WinHttp/Data7),
        ' ao contrario dos calls abaixo que dependiam do indexed setter Option(n).
        Sub SetUserAgent(pValue As String)
            me.AddHeader("User-Agent", pValue)
        End Sub

        ' Send() sempre abre a requisicao em modo sincrono (Open(..., False)).
        ' Nao ha suporte a async nesta implementacao; avisamos em vez de aceitar
        ' silenciosamente um pedido que nao sera atendido.
        Sub SetAsync(pValue As Boolean)
            If pValue Then
                mod_logger.Warn("HttpClient.SetAsync(True): nao suportado, requisicoes permanecem sincronas.")
            End If
        End Sub

        Sub ConfigureTimeouts(pResolve As Integer, pConnect As Integer, pSend As Integer, pReceive As Integer)
            me._resolveTimeout = pResolve
            me._connectTimeout = pConnect
            me._sendTimeout = pSend
            me._receiveTimeout = pReceive
        End Sub

        Sub SetReceiveTimeout(pMs As Integer)
            me._receiveTimeout = pMs
        End Sub

        ' SSL Option calls are intentionally omitted — see file header (WinHttp.Option
        ' indexed setter causes Access Violation no Data7). Chamar aqui avisa no log
        ' em vez de deixar o chamador crer, silenciosamente, que erros de SSL serao
        ' ignorados: a validacao padrao do WinHTTP permanece sempre ativa.
        Sub IgnoreSslErrors()
            mod_logger.Warn("HttpClient.IgnoreSslErrors: nao suportado (WinHttp.Option indexado quebra no Data7). Validacao de SSL padrao permanece ativa.")
        End Sub

        Sub SetSslIgnoreFlags(pFlags As Integer)
            mod_logger.Warn("HttpClient.SetSslIgnoreFlags: nao suportado (WinHttp.Option indexado quebra no Data7). Validacao de SSL padrao permanece ativa.")
        End Sub

        ' No-op consistente com o padrao: o WinHTTP ja exige SSL valido por padrao.
        Sub RequireValidSsl()
        End Sub

        ' No-op consistente com o padrao: o WinHTTP ja segue redirects por padrao.
        Sub EnableRedirects()
        End Sub

        ' Ao contrario de EnableRedirects, desabilitar redirects mudaria o
        ' comportamento padrao — como nao e suportado, avisamos no log.
        Sub DisableRedirects()
            mod_logger.Warn("HttpClient.DisableRedirects: nao suportado (WinHttp.Option indexado quebra no Data7). Redirects continuam habilitados.")
        End Sub

        Sub UseSystemProxy()
            me._proxyMode = 0
        End Sub

        Sub UseDirectConnection()
            me._proxyMode = 1
        End Sub

        Sub SetProxyServer(pServer As String, pBypass As String)
            me._proxyMode = 2
            me._proxyServer = pServer
            me._proxyBypass = pBypass
        End Sub

        Sub SetProxyCredentials(pUser As String, pPassword As String)
            me._proxyUser = pUser
            me._proxyPassword = pPassword
        End Sub

        Sub SetServerCredentials(pUser As String, pPassword As String)
            me._serverUser = pUser
            me._serverPassword = pPassword
        End Sub

        ' ------------------------------------------------------------------
        ' Request headers
        ' ------------------------------------------------------------------

        Sub AddHeader(pKey As String, pValue As String)
            me._headers.Add(pKey, pValue)
        End Sub

        Sub RemoveHeader(pKey As String)
            me._headers.Remove(pKey)
        End Sub

        Sub ClearHeaders()
            me._headers.Clear()
        End Sub

        Sub SetBearerToken(pToken As String)
            me.AddHeader("Authorization", "Bearer " + pToken)
        End Sub

        Sub SetApiKey(pApiKey As String)
            me.AddHeader("X-API-KEY", pApiKey)
        End Sub

        Sub SetJsonContentType()
            me.AddHeader("Content-Type", "application/json")
            me.AddHeader("Accept", "application/json")
        End Sub

        ' ------------------------------------------------------------------
        ' HTTP verbs
        ' ------------------------------------------------------------------

        Function GetRequest(pEndpoint As String) As HttpResponse
            GetRequest = me.Send("GET", pEndpoint, "")
        End Function

        Function PostJson(pEndpoint As String, pBody As String) As HttpResponse
            PostJson = me.Send("POST", pEndpoint, pBody)
        End Function

        Function PutJson(pEndpoint As String, pBody As String) As HttpResponse
            PutJson = me.Send("PUT", pEndpoint, pBody)
        End Function

        Function PatchJson(pEndpoint As String, pBody As String) As HttpResponse
            PatchJson = me.Send("PATCH", pEndpoint, pBody)
        End Function

        Function DeleteRequest(pEndpoint As String, pBody As String) As HttpResponse
            DeleteRequest = me.Send("DELETE", pEndpoint, pBody)
        End Function

        Sub Abort()
            ' No-op: WinHTTP abort requires a reference to the active request object,
            ' que e local a Send() (nao persistida na instancia). Avisamos para o
            ' chamador nao presumir que a requisicao em curso foi cancelada.
            mod_logger.Warn("HttpClient.Abort: nao suportado (requisicao ativa nao e referenciada pela instancia).")
        End Sub

        ' ------------------------------------------------------------------
        ' Core Send — WinHTTP without Option indexed property calls
        ' ------------------------------------------------------------------

        Function Send(pMethod As String, pEndpoint As String, pBody As String) As HttpResponse
            Dim _http As Variant
            Dim _response As New HttpResponse()
            Dim _uri As String = me.BuildUri(pEndpoint)

            Try
                _http = CreateObject("WinHttp.WinHttpRequest.5.1")

                ' Proxy (before Open)
                If me._proxyMode = 1 Then
                    _http.SetProxy(1)
                ElseIf me._proxyMode = 2 Then
                    _http.SetProxy(2, me._proxyServer, me._proxyBypass)
                End If

                ' Timeouts (before Open)
                _http.SetTimeouts(me._resolveTimeout, me._connectTimeout, me._sendTimeout, me._receiveTimeout)

                ' Open (synchronous)
                _http.Open(pMethod, _uri, False)

                ' Request headers (after Open)
                me._headers.ApplyToWinHttp(_http)

                ' HTTP credentials (after Open)
                If me._serverUser <> "" Then
                    _http.SetCredentials(me._serverUser, me._serverPassword, 0)
                End If

                If me._proxyUser <> "" Then
                    _http.SetCredentials(me._proxyUser, me._proxyPassword, 1)
                End If

                ' Send
                If pBody = "" Then
                    _http.Send()
                Else
                    _http.Send(pBody)
                End If

                ' Read response
                _response.StatusCode = _http.Status
                _response.StatusText = "" + _http.StatusText
                _response.Body = "" + _http.ResponseText
                _response.IsSuccess = _response.StatusCode >= 200 And _response.StatusCode <= 299
                ' GetAllResponseHeaders retorna UnicodeString; conversao para String
                ' nao compila no Data7 (CStr, Variant, atribuicao direta). Headers de
                ' resposta nao sao usados pela integracao Rede Ancora (so Status/Body).

                mod_logger.Log(mod_logger.LogLevel.HttpValue(), pMethod + " " + _uri + " -> " + Parser.IntegerToString(_response.StatusCode))

                Send = _response
            Catch ex As Exception
                ' _response foi criado no Try (Dim ... As New) e nao chegou a ser
                ' retornado: libera aqui para nao vazar o HttpHeader interno.
                _response.Free()
                Throw New System.Exception("HTTP request failed [" + pMethod + " " + _uri + "]: " + Char(13) + ex._getMessage())
            End Try
        End Function

        ' ------------------------------------------------------------------
        ' Private helpers
        ' ------------------------------------------------------------------

        Private Function BuildUri(pEndpoint As String) As String
            If pEndpoint.Contains("://") Then
                BuildUri = pEndpoint
                Exit Function
            End If

            BuildUri = me._baseUrl + pEndpoint
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._headers) Then
                    me._headers.Free()
                    me._headers = NULL
                End If

                me.Disposed = True
            End If
        End Sub

        Sub Free()
            Try
                If Not me.Disposed Then
                    me.Dispose()
                End If

                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Error freeing HttpClient: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
