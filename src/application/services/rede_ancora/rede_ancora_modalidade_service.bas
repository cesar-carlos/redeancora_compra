Imports mod_tobject
Imports mod_logger
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_modalidade_model
Imports rede_ancora_modalidades_model
Imports rede_ancora_modalidade_repository
Imports http_response
Imports rede_ancora_http_erro_helper

Namespace rede_ancora_modalidade_service
    Class RedeAncoraModalidadeService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _repository As RedeAncoraModalidadeRepository

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._repository = New RedeAncoraModalidadeRepository()
        End Sub

        Function SincronizarModalidades(pCodUsuario As Integer) As RedeAncoraModalidadesModel
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _modalidades As RedeAncoraModalidadesModel = NULL
            Dim _result As RedeAncoraModalidadesModel = NULL
            Dim _body As String = ""
            Dim _status As Integer = 0
            Dim _bytes As Integer = 0
            Dim _snippet As String = ""
            Dim _ok As Boolean = False

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/modalities"))

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

                mod_logger.Info("GET /modalities HTTP " & Parser.IntegerToString(_status) & " bytes=" & Parser.IntegerToString(_bytes) & " body=" & _snippet)
                mod_logger.Info("sync-modalidades: after HTTP log")

                If Not Assigned(_response) Then
                    Throw New System.Exception("GET /modalities resposta nula")
                End If
                mod_logger.Info("sync-modalidades: response assigned")

                _ok = _response.IsSuccess
                mod_logger.Info("sync-modalidades: after IsSuccess")

                If Not _ok Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("GET /modalities", _status, _body))
                End If
                mod_logger.Info("sync-modalidades: response success")
                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET /modalities", _status, _body)

                mod_logger.Info("sync-modalidades: before MapearModalidadesDeBlob")
                _modalidades = me.MapearModalidadesDeBlob(_body)
                mod_logger.Info("sync-modalidades: after MapearModalidadesDeBlob qtd=" & Parser.IntegerToString(_modalidades.Length))
                mod_logger.Printe("Rede Ancora sync modalidades :: mapeamento JSON OK")

                me._repository.SubstituirTodos(_modalidades)
                mod_logger.Info("sync-modalidades: gravadas")
                mod_logger.Printe("Rede Ancora sync modalidades concluido. Registros: " & Parser.IntegerToString(_modalidades.Length))

                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _result = _modalidades
                _modalidades = NULL
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraModalidadeService.Sincronizar", ex)

                If Assigned(_modalidades) Then
                    _modalidades.Free()
                End If

                If Assigned(_result) Then
                    _result.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar modalidades Rede Ancora: " & ex._getMessage())
            End Try

            SincronizarModalidades = _result
        End Function

        Function ListarModalidades() As RedeAncoraModalidadesModel
            ListarModalidades = me._repository.ListarTodos()
        End Function

        Function ObterDescricaoModalidade(pCodModalidade As Integer) As String
            Dim _modalidades As RedeAncoraModalidadesModel = NULL

            Try
                _modalidades = me.ListarModalidades()
                ObterDescricaoModalidade = _modalidades.ObterDescricao(pCodModalidade)
                _modalidades.Free()
            Catch ex As Exception
                If Assigned(_modalidades) Then
                    _modalidades.Free()
                End If

                Throw ex
            End Try
        End Function

        Sub ValidarModalidade(pCodModalidade As Integer)
            Dim _modalidades As RedeAncoraModalidadesModel = NULL

            Try
                _modalidades = me.ListarModalidades()

                If _modalidades.Length <= 0 Then
                    Throw New System.Exception("Modalidades Rede Ancora nao sincronizadas")
                End If

                If Not _modalidades.ExistePorCodigo(pCodModalidade) Then
                    Throw New System.Exception("Modalidade invalida na Rede Ancora: " + pCodModalidade.ToString())
                End If

                _modalidades.Free()
            Catch ex As Exception
                If Assigned(_modalidades) Then
                    _modalidades.Free()
                End If

                Throw ex
            End Try
        End Sub

        Function GarantirModalidadesSincronizadas(pCodUsuario As Integer) As RedeAncoraModalidadesModel
            Dim _modalidades As RedeAncoraModalidadesModel = me.ListarModalidades()

            If _modalidades.Length <= 0 Then
                _modalidades.Free()
                GarantirModalidadesSincronizadas = me.SincronizarModalidades(pCodUsuario)
                Exit Function
            End If

            GarantirModalidadesSincronizadas = _modalidades
        End Function

        ' BodyAsJsonObject / TJSONArray.GetJSONObject / ObterInteiroJson = AV 00220000.
        ' Mesmo padrao de MapearPerfilDeBlob: Mid curto no prefixo de cada item; so value+label.
        Private Function MapearModalidadesDeBlob(pBody As String) As RedeAncoraModalidadesModel
            Dim _result As New RedeAncoraModalidadesModel()
            Dim _arrayStart As Integer = 0
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _objStart As Integer = 0
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escape As Boolean = False
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _prefix As String = ""
            Dim _prefixLen As Integer = 0
            Dim _qtd As Integer = 0

            mod_logger.Info("sync-modalidades: MapearModalidadesDeBlob start")

            _arrayStart = me.PosicaoArrayDataAscii(pBody)
            If _arrayStart <= 0 Then
                _result.Free()
                Throw New System.Exception("Resposta /modalities sem array data")
            End If
            mod_logger.Info("sync-modalidades: array pos=" & Parser.IntegerToString(_arrayStart))

            _bodyLen = Len(pBody)
            _pos = _arrayStart + 1

            While _pos <= _bodyLen
                _ch = Mid(pBody, _pos, 1)

                If _escape Then
                    _escape = False
                ElseIf _inQuotes Then
                    If _ch = "\" Then
                        _escape = True
                    ElseIf _ch = _q Then
                        _inQuotes = False
                    End If
                Else
                    If _ch = _q Then
                        _inQuotes = True
                    ElseIf _ch = "{" Then
                        If _depth = 0 Then
                            _objStart = _pos
                        End If
                        _depth = _depth + 1
                    ElseIf _ch = "}" Then
                        If _depth = 1 Then
                            If _objStart > 0 Then
                                _prefixLen = _pos - _objStart + 1
                                If _prefixLen > 160 Then
                                    _prefixLen = 160
                                End If
                                _prefix = Mid(pBody, _objStart, _prefixLen)
                                me.AdicionarModalidadeDoPrefixo(_result, _prefix)
                                _qtd = _qtd + 1
                                _objStart = 0
                            End If
                        End If
                        If _depth > 0 Then
                            _depth = _depth - 1
                        End If
                    ElseIf _ch = "]" Then
                        If _depth = 0 Then
                            Exit While
                        End If
                    End If
                End If

                _pos = _pos + 1

                If _qtd >= 64 Then
                    Exit While
                End If
            Wend

            mod_logger.Info("sync-modalidades: itens=" & Parser.IntegerToString(_result.Length))

            If _result.Length <= 0 Then
                _result.Free()
                Throw New System.Exception("Resposta /modalities sem modalidades (value/label)")
            End If

            MapearModalidadesDeBlob = _result
        End Function

        Private Sub AdicionarModalidadeDoPrefixo(pLista As RedeAncoraModalidadesModel, pPrefixo As String)
            Dim _item As RedeAncoraModalidadeModel = NULL
            Dim _cod As Integer = 0
            Dim _desc As String = ""

            _cod = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "value")
            _desc = me.ExtrairTextoJsonDoPrefixoAscii(pPrefixo, "label")

            If _cod <= 0 Then
                Exit Sub
            End If

            If _desc.Trim() = "" Then
                Exit Sub
            End If

            _item = New RedeAncoraModalidadeModel()
            _item.CodModalidade = _cod
            _item.Descricao = _desc
            pLista.Push(_item)
        End Sub

        Private Function PosicaoArrayDataAscii(pBody As String) As Integer
            Dim _len As Integer = Len(pBody)
            Dim _i As Integer = 1
            Dim _ch As String = ""
            Dim _posValor As Integer = 0

            PosicaoArrayDataAscii = 0

            While _i <= _len
                _ch = Mid(pBody, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i <= _len Then
                If Mid(pBody, _i, 1) = "[" Then
                    PosicaoArrayDataAscii = _i
                    Exit Function
                End If
            End If

            _posValor = me.PosicaoValorChaveAscii(pBody, "data")
            If _posValor <= 0 Then
                Exit Function
            End If

            If Mid(pBody, _posValor, 1) = "[" Then
                PosicaoArrayDataAscii = _posValor
            End If
        End Function

        Private Function PosicaoValorChaveAscii(pBlob As String, pChave As String) As Integer
            Dim _len As Integer = Len(pBlob)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False

            PosicaoValorChaveAscii = 0

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pBlob, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pBlob, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pBlob, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pBlob, _i + _keyLen + 2, 1) = ":" Then
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
                _ch = Mid(pBlob, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            PosicaoValorChaveAscii = _i
        End Function

        Private Function ExtrairInteiroDoPrefixoAscii(pPrefixo As String, pChave As String) As Integer
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _digits As String = "0123456789"

            ExtrairInteiroDoPrefixoAscii = 0

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

            If Mid(pPrefixo, _i, 1) = _q Then
                _i = _i + 1
            End If

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

            ExtrairInteiroDoPrefixoAscii = _n
        End Function

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
            Dim _maxValor As Integer = 40
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

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._authService) Then
                    me._authService.Free()
                    me._authService = NULL
                End If

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
