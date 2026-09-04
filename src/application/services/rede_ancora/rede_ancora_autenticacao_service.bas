Imports mod_tobject
Imports mod_logger
Imports diag_stack
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_model
Imports rede_ancora_autenticacao_repository
Imports rede_ancora_http_client
Imports http_response
Imports http_client
Imports rede_ancora_json_helper

Namespace rede_ancora_autenticacao_service
    Class RedeAncoraAutenticacaoService
        Inherits TTObject

        Private _repository As RedeAncoraAutenticacaoRepository

        Sub New()
            MyBase.New()
            me._repository = New RedeAncoraAutenticacaoRepository()
        End Sub

        Private Function CreateClient(pAuth As RedeAncoraAutenticacaoModel) As HttpClient
            CreateClient = RedeAncoraHttpClient.Criar(pAuth)
        End Function

        Private Function RespostaPingValida(pBody As String) As Boolean
            Dim _body As String = pBody.Trim()
            Dim _json As TJSONObject = NULL
            Dim _data As String = ""

            RespostaPingValida = False

            If _body = "" Then
                Exit Function
            End If

            If Mid(_body, 1, 1) = "{" Then
                Try
                    _json = New TJSONObject(_body)
                    _data = RedeAncoraJsonHelper.ObterTextoJson(_json, "data").Trim()

                    If _data.ToUpper() = "PONG" Then
                        RespostaPingValida = True
                    End If

                    _json.Free()
                    Exit Function
                Catch ex As Exception
                    If Assigned(_json) Then
                        _json.Free()
                    End If
                End Try
            End If

            RespostaPingValida = _body.ToUpper().Contains("PONG")
        End Function

        Function Ping() As Boolean
            Dim _client As HttpClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _url As String = RedeAncoraApiConfig.IntegrationUrl("/ping")

            Try
                mod_logger.Printe("Ping URL: " + _url)
                _client = me.CreateClient(NULL)
                _response = _client.GetRequest(_url)
                mod_logger.Printe("Ping HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)

                If Not _response.IsSuccess Then
                    Throw New System.Exception("GET /ping HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                If Not me.RespostaPingValida(_response.Body) Then
                    Throw New System.Exception("GET /ping resposta inesperada: " + _response.Body)
                End If

                Ping = True
                _response.Free()
                _client.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_client) Then
                    _client.Free()
                End If

                Throw ex
            End Try
        End Function

        Function GarantirChaveApi(pCodUsuario As Integer) As RedeAncoraAutenticacaoModel
            Dim _model As RedeAncoraAutenticacaoModel = me._repository.ObterPorCodUsuario(pCodUsuario)

            If Not _model.TemChaveApi() Then
                _model.Free()
                Throw New System.Exception("Chave API Rede Ancora nao configurada para CodUsuario " + pCodUsuario.ToString() + ". Grave X-API-KEY em Integracao.RedeAncoraAutenticacao.")
            End If

            GarantirChaveApi = _model
        End Function

        Function ObterAutenticacao(pCodUsuario As Integer) As RedeAncoraAutenticacaoModel
            ObterAutenticacao = me._repository.ObterPorCodUsuario(pCodUsuario)
        End Function

        Function TryObterAutenticacao(pCodUsuario As Integer, pItem As RedeAncoraAutenticacaoModel) As Boolean
            TryObterAutenticacao = me._repository.TryObterPorCodUsuario(pCodUsuario, pItem)
        End Function

        Sub SalvarChaveApi(pCodUsuario As Integer, pChaveApi As String)
            Dim _auth As RedeAncoraAutenticacaoModel = New RedeAncoraAutenticacaoModel()

            Try
                If Not me._repository.TryObterPorCodUsuario(pCodUsuario, _auth) Then
                    _auth.CodUsuario = pCodUsuario
                    _auth.SetEmail("integracao@data7.local")
                End If

                _auth.ChaveApi = pChaveApi
                _auth.Ativo = "S"
                me._repository.Salvar(_auth)
                _auth.Free()
            Catch ex As Exception
                If Assigned(_auth) Then
                    _auth.Free()
                End If

                DiagStack.DumpOnError(ex)
                mod_logger.Erro("SalvarChaveApi Catch: " + DiagStack.FormatException(ex))
                Throw New System.Exception("Erro ao salvar chave API Rede Ancora: " + DiagStack.FormatException(ex))
            End Try
        End Sub

        Sub AtualizarUsuarioDeProfileJson(pCodUsuario As Integer, pBody As String)
            Dim _model As RedeAncoraAutenticacaoModel = NULL

            Try
                _model = me._repository.ObterPorCodUsuario(pCodUsuario)
                me.PreencherUsuarioDeProfile(pBody, _model)
                me._repository.Salvar(_model)
                _model.Free()
            Catch ex As Exception
                If Assigned(_model) Then
                    _model.Free()
                End If

                DiagStack.DumpOnError(ex)
                mod_logger.Erro("AtualizarUsuarioDeProfileJson Catch: " + DiagStack.FormatException(ex))
                Throw New System.Exception("Erro ao atualizar usuario Rede Ancora a partir do profile: " + DiagStack.FormatException(ex))
            End Try
        End Sub

        Function SincronizarUsuarioApi(pCodUsuario As Integer) As RedeAncoraAutenticacaoModel
            Dim _auth As RedeAncoraAutenticacaoModel = NULL
            Dim _client As HttpClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _result As RedeAncoraAutenticacaoModel = NULL
            Dim _status As Integer = 0
            Dim _bytes As Integer = 0
            Dim _snippet As String = ""
            Dim _detalhe As String = ""
            Dim _body As String = ""
            Dim _ok As Boolean = False

            Try
                DiagStack.Push("SincronizarUsuarioApi.GarantirChaveApi")
                _auth = me.GarantirChaveApi(pCodUsuario)
                DiagStack.Pop()

                DiagStack.Push("SincronizarUsuarioApi.CreateClient")
                _client = me.CreateClient(_auth)
                DiagStack.Pop()

                DiagStack.Push("SincronizarUsuarioApi.GetProfile")
                _response = _client.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/profile"))

                If Assigned(_response) Then
                    _status = _response.StatusCode
                    _body = _response.Body
                    _bytes = Len(_body)
                    If _bytes <= 80 Then
                        _snippet = _body
                    Else
                        _snippet = Mid(_body, 1, 80) & "..."
                    End If
                End If

                mod_logger.Info("GET /profile HTTP " & Parser.IntegerToString(_status) & " bytes=" & Parser.IntegerToString(_bytes) & " body=" & _snippet)
                mod_logger.Info("sync-user: after HTTP log")

                If Not Assigned(_response) Then
                    Throw New System.Exception("GET /profile resposta nula")
                End If
                mod_logger.Info("sync-user: response assigned")

                _ok = _response.IsSuccess
                mod_logger.Info("sync-user: after IsSuccess")

                If Not _ok Then
                    mod_logger.Erro("GET /profile falhou. HTTP " & Parser.IntegerToString(_status) & ": " & _snippet)
                    Throw New System.Exception("GET /profile Rede Ancora falhou. HTTP " & Parser.IntegerToString(_status) & ": " & _snippet)
                End If
                mod_logger.Info("sync-user: response success")

                DiagStack.Push("SincronizarUsuarioApi.PreencherUsuarioDeProfile")
                mod_logger.Info("sync-user: before PreencherUsuarioDeProfile")
                me.PreencherUsuarioDeProfile(_body, _auth)
                mod_logger.Info("sync-user: after PreencherUsuarioDeProfile")
                DiagStack.Pop()
                DiagStack.Pop()

                DiagStack.Push("SincronizarUsuarioApi.Salvar")
                mod_logger.Info("sync-user: before Salvar")
                me._repository.Salvar(_auth)
                mod_logger.Info("sync-user: after Salvar")
                DiagStack.Pop()

                mod_logger.Info("sync-user: before free")
                _result = _auth
                _auth = NULL
                _response.Free()
                mod_logger.Info("sync-user: after response.Free")
                _response = NULL
                _client.Free()
                mod_logger.Info("sync-user: after client.Free")
                _client = NULL
            Catch ex As Exception
                _detalhe = DiagStack.FormatException(ex)
                DiagStack.DumpOnError(ex)
                mod_logger.Erro("SincronizarUsuarioApi Catch: " & _detalhe)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_client) Then
                    _client.Free()
                End If

                If Assigned(_auth) Then
                    _auth.Free()
                End If

                If Assigned(_result) Then
                    _result.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar usuario Rede Ancora: " & _detalhe)
            End Try

            SincronizarUsuarioApi = _result
        End Function

        ' Profile comeca {"user":{"id":N, — Mid de 1 char so no prefixo ASCII.
        ' Nao usar ObterInteiroJsonDeBlob na janela 800 (unicode no name = AV 00220000).
        Private Function ExtrairIdDoPrefixoAscii(pPrefixo As String) As Integer
            Dim _len As Integer = Len(pPrefixo)
            Dim _i As Integer = 1
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _digits As String = "0123456789"
            Dim _achou As Boolean = False

            ExtrairIdDoPrefixoAscii = 0

            If _len <= 0 Then
                Exit Function
            End If

            While _i <= (_len - 4)
                If Mid(pPrefixo, _i, 1) = _q Then
                    If Mid(pPrefixo, _i + 1, 1) = "i" Then
                        If Mid(pPrefixo, _i + 2, 1) = "d" Then
                            If Mid(pPrefixo, _i + 3, 1) = _q Then
                                If Mid(pPrefixo, _i + 4, 1) = ":" Then
                                    _achou = True
                                    _i = _i + 5
                                    Exit While
                                End If
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                _d = -1
                For _j = 1 To 10
                    If Mid(_digits, _j, 1) = _ch Then
                        _d = _j - 1
                        Exit For
                    End If
                Next
                If _d < 0 Then
                    Exit While
                End If
                _n = (_n * 10) + _d
                _i = _i + 1
            Wend

            ExtrairIdDoPrefixoAscii = _n
        End Function

        ' Copia "chave":"valor" no prefixo ASCII (ate ~200). Nao decodifica \uXXXX.
        ' Proximo " nao escapado encerra. Sem InStr/Contains/CStr/janela 800.
        Private Function ExtrairTextoJsonDoPrefixoAscii(pPrefixo As String, pChave As String) As String
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False
            Dim _escape As Boolean = False
            Dim _result As String = ""
            Dim _maxValor As Integer = 160
            Dim _nValor As Integer = 0

            ExtrairTextoJsonDoPrefixoAscii = ""

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pPrefixo, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pPrefixo, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pPrefixo, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pPrefixo, _i + _keyLen + 2, 1) = ":" Then
                                _achou = True
                                _i = _i + _keyLen + 3
                                Exit While
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            If Mid(pPrefixo, _i, 1) <> _q Then
                Exit Function
            End If

            _i = _i + 1
            _escape = False

            While _i <= _len
                If _nValor >= _maxValor Then
                    Exit While
                End If

                _ch = Mid(pPrefixo, _i, 1)

                If _escape Then
                    _result = _result & _ch
                    _nValor = _nValor + 1
                    _escape = False
                Else
                    If _ch = "\" Then
                        _result = _result & _ch
                        _nValor = _nValor + 1
                        _escape = True
                    Else
                        If _ch = _q Then
                            Exit While
                        End If
                        _result = _result & _ch
                        _nValor = _nValor + 1
                    End If
                End If

                _i = _i + 1
            Wend

            ExtrairTextoJsonDoPrefixoAscii = _result
        End Function

        ' warehouse_preferencial fica no company da raiz (fim do doc ~3.4KB).
        ' Mid de 24 no blob inteiro a partir do fim — PosicaoTexto em unicode AV.
        Private Function ExtrairWarehouseDoBlob(pBody As String) As Integer
            Dim _len As Integer = Len(pBody)
            Dim _q As String = Chr(34)
            Dim _needle As String = ""
            Dim _needleLen As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _j As Integer = 0
            Dim _digits As String = "0123456789"
            Dim _achou As Boolean = False

            ExtrairWarehouseDoBlob = 0

            _needle = _q & "warehouse_preferencial" & _q
            _needleLen = Len(_needle)
            If _needleLen <= 0 Then
                Exit Function
            End If

            If _len < _needleLen Then
                Exit Function
            End If

            _i = _len - _needleLen + 1
            While _i >= 1
                If Mid(pBody, _i, _needleLen) = _needle Then
                    _achou = True
                    _i = _i + _needleLen
                    Exit While
                End If
                _i = _i - 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pBody, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            If Mid(pBody, _i, 1) = ":" Then
                _i = _i + 1
            End If

            While _i <= _len
                _ch = Mid(pBody, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            While _i <= _len
                _ch = Mid(pBody, _i, 1)
                _d = -1
                For _j = 1 To 10
                    If Mid(_digits, _j, 1) = _ch Then
                        _d = _j - 1
                        Exit For
                    End If
                Next
                If _d < 0 Then
                    Exit While
                End If
                _n = (_n * 10) + _d
                _i = _i + 1
            Wend

            ExtrairWarehouseDoBlob = _n
        End Function

        ' Le id/name/email no prefixo ASCII; warehouse com janela 24 a partir do fim.
        ' InStr/Contains/CStr/janela 800 no blob unicode = AV 00220000.
        ' user.company e numero; warehouse_preferencial fica no objeto company da raiz.
        Private Sub PreencherUsuarioDeProfile(pBody As String, pModel As RedeAncoraAutenticacaoModel)
            Dim _emailApi As String = ""
            Dim _nome As String = ""
            Dim _idApi As Integer = 0
            Dim _seller As Integer = 0
            Dim _bodyLen As Integer = 0
            Dim _idPrefixLen As Integer = 64
            Dim _userPrefixLen As Integer = 200
            Dim _prefixId As String = ""
            Dim _prefixUser As String = ""

            If Not Assigned(pModel) Then
                Throw New System.Exception("PreencherUsuarioDeProfile: model nulo")
            End If

            _bodyLen = Len(pBody)
            mod_logger.Info("sync-user: preencher start len=" & Parser.IntegerToString(_bodyLen))

            If _idPrefixLen > _bodyLen Then
                _idPrefixLen = _bodyLen
            End If
            _prefixId = Mid(pBody, 1, _idPrefixLen)

            _idApi = me.ExtrairIdDoPrefixoAscii(_prefixId)
            mod_logger.Info("sync-user: preencher id=" & Parser.IntegerToString(_idApi))

            If _userPrefixLen > _bodyLen Then
                _userPrefixLen = _bodyLen
            End If
            _prefixUser = Mid(pBody, 1, _userPrefixLen)

            _nome = me.ExtrairTextoJsonDoPrefixoAscii(_prefixUser, "name")
            mod_logger.Info("sync-user: preencher nameLen=" & Parser.IntegerToString(Len(_nome)))

            _emailApi = me.ExtrairTextoJsonDoPrefixoAscii(_prefixUser, "email")
            mod_logger.Info("sync-user: preencher emailLen=" & Parser.IntegerToString(Len(_emailApi)))

            _seller = me.ExtrairWarehouseDoBlob(pBody)
            mod_logger.Info("sync-user: preencher warehouse=" & Parser.IntegerToString(_seller))

            pModel.IdUsuarioApi = _idApi
            mod_logger.Info("sync-user: preencher set id")

            pModel.NomeUsuario = _nome
            mod_logger.Info("sync-user: preencher set name")

            pModel.CodSeller = _seller
            mod_logger.Info("sync-user: preencher set seller")

            If Len(_emailApi) > 0 Then
                pModel.SetEmail(_emailApi)
                mod_logger.Info("sync-user: preencher set email")
            End If

            mod_logger.Info("sync-user: preencher done")
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._repository) Then
                    me._repository.Free()
                    me._repository = NULL
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
