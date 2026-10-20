Imports mod_tobject
Imports mod_logger
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_empresa_model
Imports rede_ancora_empresa_repository
Imports rede_ancora_centro_distribuicao_model
Imports rede_ancora_centros_distribuicao_model
Imports rede_ancora_centro_distribuicao_repository
Imports try_parser
Imports http_response
Imports rede_ancora_http_erro_helper

Namespace rede_ancora_empresa_service
    Class RedeAncoraEmpresaService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _empresaRepository As RedeAncoraEmpresaRepository
        Private _centroDistribuicaoRepository As RedeAncoraCentroDistribuicaoRepository

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._empresaRepository = New RedeAncoraEmpresaRepository()
            me._centroDistribuicaoRepository = New RedeAncoraCentroDistribuicaoRepository()
        End Sub

        Function SincronizarPerfil(pCodUsuario As Integer) As RedeAncoraEmpresaModel
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _model As RedeAncoraEmpresaModel = NULL
            Dim _centros As RedeAncoraCentrosDistribuicaoModel = NULL
            Dim _result As RedeAncoraEmpresaModel = NULL
            Dim _qtdCentros As Integer = 0
            Dim _body As String = ""
            Dim _status As Integer = 0
            Dim _bytes As Integer = 0
            Dim _snippet As String = ""
            Dim _ok As Boolean = False

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/profile"))

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
                mod_logger.Info("sync-profile: after HTTP log")

                If Not Assigned(_response) Then
                    Throw New System.Exception("GET /profile resposta nula")
                End If
                mod_logger.Info("sync-profile: response assigned")

                _ok = _response.IsSuccess
                mod_logger.Info("sync-profile: after IsSuccess")

                If Not _ok Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("GET /profile", _status, _body))
                End If
                mod_logger.Info("sync-profile: response success")
                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET /profile", _status, _body)

                _model = New RedeAncoraEmpresaModel()
                _centros = New RedeAncoraCentrosDistribuicaoModel()
                mod_logger.Info("sync-profile: before MapearPerfilDeBlob")
                me.MapearPerfilDeBlob(_body, pCodUsuario, _model, _centros)
                mod_logger.Info("sync-profile: after MapearPerfilDeBlob empresa=" & Parser.IntegerToString(_model.CodEmpresaAncora) & " cds=" & Parser.IntegerToString(_centros.Length))
                mod_logger.Printe("Rede Ancora sync profile :: mapeamento JSON OK")

                me._authService.AtualizarUsuarioDeProfileJson(pCodUsuario, _body)
                mod_logger.Info("sync-profile: autenticacao atualizada")
                mod_logger.Printe("Rede Ancora sync profile :: autenticacao atualizada")

                me._empresaRepository.Salvar(_model)
                mod_logger.Info("sync-profile: empresa gravada")
                mod_logger.Printe("Rede Ancora sync profile :: empresa gravada")

                me._centroDistribuicaoRepository.SubstituirPorCodUsuario(pCodUsuario, _centros)
                mod_logger.Info("sync-profile: CDs gravados")
                mod_logger.Printe("Rede Ancora sync profile :: CDs gravados")

                _qtdCentros = _centros.Length
                mod_logger.Printe("Rede Ancora sync profile concluido. Empresa Ancora: " & Parser.IntegerToString(_model.CodEmpresaAncora) & " | CDs: " & Parser.IntegerToString(_qtdCentros))

                _centros.Free()
                _centros = NULL
                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _result = _model
                _model = NULL
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraEmpresaService.SincronizarPerfil", ex)

                If Assigned(_centros) Then
                    _centros.Free()
                End If

                If Assigned(_model) Then
                    _model.Free()
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

                Throw New System.Exception("Erro ao sincronizar profile Rede Ancora: " & ex._getMessage())
            End Try

            SincronizarPerfil = _result
        End Function

        Function ObterPerfil(pCodUsuario As Integer) As RedeAncoraEmpresaModel
            ObterPerfil = me._empresaRepository.ObterPorCodUsuario(pCodUsuario)
        End Function

        Function TryObterPerfil(pCodUsuario As Integer, pItem As RedeAncoraEmpresaModel) As Boolean
            TryObterPerfil = me._empresaRepository.TryObterPorCodUsuario(pCodUsuario, pItem)
        End Function

        Function ListarCentrosDistribuicao(pCodUsuario As Integer) As RedeAncoraCentrosDistribuicaoModel
            ListarCentrosDistribuicao = me._centroDistribuicaoRepository.ListarPorCodUsuario(pCodUsuario)
        End Function

        Sub SalvarPerfilLocal(pModel As RedeAncoraEmpresaModel)
            pModel.Validate()
            me._empresaRepository.Salvar(pModel)
        End Sub

        Sub ValidarPodeOperar(pCodUsuario As Integer)
            me.ValidarPermissoes(pCodUsuario, "checkout")
        End Sub

        Sub ValidarPermissoes(pCodUsuario As Integer, pPermissao As String)
            Dim _model As RedeAncoraEmpresaModel = NULL

            Try
                _model = me.ObterPerfil(pCodUsuario)

                If _model.IsBloqueado() Then
                    Throw New System.Exception("Franqueado bloqueado na Rede Ancora: " + me.MontarMensagemBloqueio(_model))
                End If

                If pPermissao.Trim() <> "" Then
                    If pPermissao.Trim().ToLower() = "checkout" Then
                        If Not _model.TemPermissaoCarrinho() Then
                            Throw New System.Exception("Usuario sem permissao de carrinho/checkout na Rede Ancora")
                        End If
                    ElseIf pPermissao.Trim().ToLower() = "orders" Then
                        If Not _model.TemPermissaoPedido() Then
                            Throw New System.Exception("Usuario sem permissao de pedido na Rede Ancora")
                        End If
                    ElseIf Not _model.TemPermissao(pPermissao) Then
                        Throw New System.Exception("Usuario sem permissao " + pPermissao + " na Rede Ancora")
                    End If
                End If

                _model.Free()
            Catch ex As Exception
                If Assigned(_model) Then
                    _model.Free()
                End If

                Throw ex
            End Try
        End Sub

        ' InStr/Contains/ObterTextoJsonDeBlob/PosicaoFimBloco no body ~3.4KB = AV 00220000.
        ' Mesmo padrao de PreencherUsuarioDeProfile: Mid curto no prefixo; chave longa so a partir do fim.
        Private Sub MapearPerfilDeBlob(pBody As String, pCodUsuario As Integer, pModel As RedeAncoraEmpresaModel, pCentros As RedeAncoraCentrosDistribuicaoModel)
            Dim _bodyLen As Integer = 0
            Dim _prefixUserLen As Integer = 200
            Dim _prefixUser As String = ""
            Dim _cgc As String = ""
            Dim _cgcPos As Integer = 0
            Dim _companyPos As Integer = 0
            Dim _prefixCompanyLen As Integer = 64
            Dim _prefixCompany As String = ""

            mod_logger.Info("sync-profile: MapearPerfilDeBlob start")

            If Not Assigned(pModel) Then
                Throw New System.Exception("MapearPerfilDeBlob: model nulo")
            End If

            If Not Assigned(pCentros) Then
                Throw New System.Exception("MapearPerfilDeBlob: centros nulo")
            End If

            pModel.CodUsuario = pCodUsuario

            If Not me._empresaRepository.TryObterPorCodUsuario(pCodUsuario, pModel) Then
                pModel.CodUsuario = pCodUsuario
            End If
            mod_logger.Info("sync-profile: after TryObter")

            _bodyLen = Len(pBody)

            If _prefixUserLen > _bodyLen Then
                _prefixUserLen = _bodyLen
            End If
            If _prefixUserLen > 0 Then
                _prefixUser = Mid(pBody, 1, _prefixUserLen)
                pModel.IdCarrinhoAtual = me.ExtrairTextoJsonDoPrefixoAscii(_prefixUser, "current_cart_id")
                pModel.CodEmpresaAncora = me.ExtrairInteiroDoPrefixoAscii(_prefixUser, "company")
            End If
            mod_logger.Info("sync-profile: current_cart_id len=" & Parser.IntegerToString(Len(pModel.IdCarrinhoAtual)))

            pModel.CodCentroDistribuicaoPreferencial = me.ExtrairInteiroChaveDoFim(pBody, "warehouse_preferencial")
            mod_logger.Info("sync-profile: warehouse=" & Parser.IntegerToString(pModel.CodCentroDistribuicaoPreferencial))

            _cgcPos = me.PosicaoValorChaveDoFim(pBody, "cgc")
            If _cgcPos > 0 Then
                _cgc = me.ExtrairTextoQuotedNaPosicao(pBody, _cgcPos)
            End If
            mod_logger.Info("sync-profile: cgc len=" & Parser.IntegerToString(Len(_cgc)))

            If Len(_cgc) > 0 Then
                pModel.SetCnpj(_cgc)
            End If

            ' estado da empresa fica no objeto company. O ultimo "estado" do JSON e de um CD.
            _companyPos = me.PosicaoAbreCompanyDoFim(pBody)
            me.ExtrairEstadoEUfDaCompany(pBody, _companyPos, pModel)
            mod_logger.Info("sync-profile: estado=" & Parser.IntegerToString(pModel.CodEstado) & " uf=" & pModel.Uf)

            If pModel.CodEmpresaAncora <= 0 Then
                If _companyPos <= 0 Then
                    Throw New System.Exception("Profile Rede Ancora sem dados de company")
                End If

                If _prefixCompanyLen > (_bodyLen - _companyPos + 1) Then
                    _prefixCompanyLen = _bodyLen - _companyPos + 1
                End If
                _prefixCompany = Mid(pBody, _companyPos, _prefixCompanyLen)
                pModel.CodEmpresaAncora = me.ExtrairInteiroDoPrefixoAscii(_prefixCompany, "id")
                pModel.CodInterno = me.ExtrairInteiroDoPrefixoAscii(_prefixCompany, "internal")
            End If
            mod_logger.Info("sync-profile: company bloco pos=" & Parser.IntegerToString(_companyPos))
            mod_logger.Info("sync-profile: id=" & Parser.IntegerToString(pModel.CodEmpresaAncora))

            me.PreencherCentrosDoPerfil(pBody, pCodUsuario, pModel.CodEstado, pModel.CodCentroDistribuicaoPreferencial, pCentros)
            mod_logger.Info("sync-profile: warehouses qtd=" & Parser.IntegerToString(pCentros.Length))
        End Sub

        ' Objeto company isolado: o primeiro "estado" e da empresa; "uf" e endereco.uf.
        Private Sub ExtrairEstadoEUfDaCompany(pBody As String, pAbre As Integer, pModel As RedeAncoraEmpresaModel)
            Dim _obj As String = ""
            Dim _estado As Integer = 0
            Dim _uf As String = ""

            If Not Assigned(pModel) Then
                Exit Sub
            End If

            If pAbre <= 0 Then
                Exit Sub
            End If

            _obj = me.CopiarObjetoJson(pBody, pAbre, 2500)
            _estado = me.ExtrairInteiroChaveCurta(_obj, "estado")
            _uf = me.NormalizarUf(me.ExtrairTextoChaveCurta(_obj, "uf", 8))

            If _estado > 0 Then
                pModel.CodEstado = _estado
            End If

            If Len(_uf) = 2 Then
                pModel.Uf = _uf
            End If
        End Sub

        Private Sub PreencherCentrosDoPerfil(pBody As String, pCodUsuario As Integer, pCodEstadoEmpresa As Integer, pCodPreferencial As Integer, pCentros As RedeAncoraCentrosDistribuicaoModel)
            Dim _abre As Integer = 0
            Dim _len As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _obj As String = ""
            Dim _fimObj As Integer = 0
            Dim _qtd As Integer = 0
            Dim _acabou As Boolean = False

            _abre = me.PosicaoArrayWarehouses(pBody)
            If _abre <= 0 Then
                me.AdicionarCentroPreferencialFallback(pCodUsuario, pCodEstadoEmpresa, pCodPreferencial, pCentros)
                Exit Sub
            End If

            _len = Len(pBody)
            _i = _abre + 1

            While _i <= _len
                If _acabou Then
                    _i = _len + 1
                Else
                    If _qtd >= 40 Then
                        _acabou = True
                    Else
                        _ch = Mid(pBody, _i, 1)
                        If _ch = " " Or _ch = "," Or _ch = Chr(9) Or _ch = Chr(10) Or _ch = Chr(13) Then
                            _i = _i + 1
                        Else
                            If _ch = "]" Then
                                _acabou = True
                            Else
                                If _ch = "{" Then
                                    _obj = me.CopiarObjetoJson(pBody, _i, 900)
                                    _fimObj = _i + Len(_obj) - 1
                                    me.AdicionarCentroDoObjeto(_obj, pCodUsuario, pCodPreferencial, pCentros)
                                    _qtd = _qtd + 1
                                    If _fimObj < _i Then
                                        _acabou = True
                                    Else
                                        _i = _fimObj + 1
                                    End If
                                Else
                                    _acabou = True
                                End If
                            End If
                        End If
                    End If
                End If
            Wend

            If pCentros.Length <= 0 Then
                me.AdicionarCentroPreferencialFallback(pCodUsuario, pCodEstadoEmpresa, pCodPreferencial, pCentros)
            End If
        End Sub

        Private Sub AdicionarCentroPreferencialFallback(pCodUsuario As Integer, pCodEstadoEmpresa As Integer, pCodPreferencial As Integer, pCentros As RedeAncoraCentrosDistribuicaoModel)
            Dim _item As RedeAncoraCentroDistribuicaoModel = NULL

            If pCodPreferencial <= 0 Then
                Exit Sub
            End If

            If Assigned(pCentros.ObterPorCodigo(pCodPreferencial)) Then
                Exit Sub
            End If

            _item = New RedeAncoraCentroDistribuicaoModel()
            _item.CodUsuario = pCodUsuario
            _item.CodCentroDistribuicao = pCodPreferencial
            _item.CodEstado = pCodEstadoEmpresa
            _item.Preferencial = "S"
            pCentros.Push(_item)
        End Sub

        Private Sub AdicionarCentroDoObjeto(pObj As String, pCodUsuario As Integer, pCodPreferencial As Integer, pCentros As RedeAncoraCentrosDistribuicaoModel)
            Dim _item As RedeAncoraCentroDistribuicaoModel = NULL
            Dim _empresa As Integer = 0
            Dim _estado As Integer = 0
            Dim _pref As Integer = 0
            Dim _prefTexto As String = ""
            Dim _flag As String = "N"

            _empresa = me.ExtrairInteiroChaveCurta(pObj, "empresa")
            If _empresa <= 0 Then
                Exit Sub
            End If

            If Assigned(pCentros.ObterPorCodigo(_empresa)) Then
                Exit Sub
            End If

            _estado = me.ExtrairInteiroChaveCurta(pObj, "estado")
            _pref = me.ExtrairInteiroChaveCurta(pObj, "preferential")
            _prefTexto = me.ExtrairTextoChaveCurta(pObj, "preferential", 8)

            If _pref = 1 Then
                _flag = "S"
            Else
                If LCase(_prefTexto) = "true" Then
                    _flag = "S"
                Else
                    If _empresa = pCodPreferencial Then
                        If pCodPreferencial > 0 Then
                            _flag = "S"
                        End If
                    End If
                End If
            End If

            _item = New RedeAncoraCentroDistribuicaoModel()
            _item.CodUsuario = pCodUsuario
            _item.CodCentroDistribuicao = _empresa
            _item.Nome = me.ExtrairTextoChaveCurta(pObj, "nome", 120)
            _item.NomeFantasia = me.ExtrairTextoChaveCurta(pObj, "nome_fantasia", 120)
            _item.CodEstado = _estado
            _item.Preferencial = _flag
            pCentros.Push(_item)
        End Sub

        Private Function PosicaoArrayWarehouses(pBody As String) As Integer
            Dim _len As Integer = Len(pBody)
            Dim _q As String = Chr(34)
            Dim _needle As String = ""
            Dim _needleLen As Integer = 0
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _achou As Boolean = False

            PosicaoArrayWarehouses = 0
            _needle = _q & "warehouses" & _q
            _needleLen = Len(_needle)

            If _len < _needleLen Then
                Exit Function
            End If

            While _i <= (_len - _needleLen + 1)
                If _achou Then
                    _i = _len + 1
                Else
                    If Mid(pBody, _i, _needleLen) = _needle Then
                        _j = _i + _needleLen
                        While _j <= _len
                            _ch = Mid(pBody, _j, 1)
                            If _ch = " " Or _ch = ":" Then
                                _j = _j + 1
                            Else
                                Exit While
                            End If
                        Wend
                        If _j <= _len Then
                            If Mid(pBody, _j, 1) = "[" Then
                                PosicaoArrayWarehouses = _j
                                _achou = True
                            End If
                        End If
                    End If
                    _i = _i + 1
                End If
            Wend
        End Function

        Private Function CopiarObjetoJson(pBody As String, pAbre As Integer, pMax As Integer) As String
            Dim _len As Integer = Len(pBody)
            Dim _i As Integer = pAbre
            Dim _limite As Integer = 0
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escape As Boolean = False
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _result As String = ""
            Dim _n As Integer = 0
            Dim _fechou As Boolean = False

            If pAbre < 1 Then
                CopiarObjetoJson = ""
                Exit Function
            End If

            If pAbre > _len Then
                CopiarObjetoJson = ""
                Exit Function
            End If

            _limite = pAbre + pMax - 1
            If _limite > _len Then
                _limite = _len
            End If

            While _i <= _limite
                If _fechou Then
                    _i = _limite + 1
                Else
                    _ch = Mid(pBody, _i, 1)
                    If _n < pMax Then
                        _result = _result & _ch
                        _n = _n + 1
                    End If

                    If _escape Then
                        _escape = False
                    Else
                        If _inQuotes Then
                            If _ch = "\" Then
                                _escape = True
                            Else
                                If _ch = _q Then
                                    _inQuotes = False
                                End If
                            End If
                        Else
                            If _ch = _q Then
                                _inQuotes = True
                            Else
                                If _ch = "{" Then
                                    _depth = _depth + 1
                                Else
                                    If _ch = "}" Then
                                        _depth = _depth - 1
                                        If _depth = 0 Then
                                            _fechou = True
                                        End If
                                    End If
                                End If
                            End If
                        End If
                    End If
                    _i = _i + 1
                End If
            Wend

            CopiarObjetoJson = _result
        End Function

        Private Function ExtrairInteiroChaveCurta(pObj As String, pChave As String) As Integer
            Dim _pos As Integer = 0
            Dim _len As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _j As Integer = 0
            Dim _digits As String = "0123456789"
            Dim _tem As Boolean = False

            ExtrairInteiroChaveCurta = 0
            _pos = me.PosicaoValorChaveCurta(pObj, pChave)
            If _pos <= 0 Then
                Exit Function
            End If

            _len = Len(pObj)
            _i = _pos
            If _i <= _len Then
                If Mid(pObj, _i, 1) = Chr(34) Then
                    _i = _i + 1
                End If
            End If

            While _i <= _len
                If _tem Then
                    _ch = Mid(pObj, _i, 1)
                    _d = -1
                    For _j = 1 To 10
                        If Mid(_digits, _j, 1) = _ch Then
                            _d = _j - 1
                        End If
                    Next
                    If _d < 0 Then
                        _i = _len + 1
                    Else
                        If Parser.PodeAcumularDigito(_n, _d) Then
                            _n = (_n * 10) + _d
                            _i = _i + 1
                        Else
                            _n = 0
                            _tem = False
                            _i = _len + 1
                        End If
                    End If
                Else
                    _ch = Mid(pObj, _i, 1)
                    _d = -1
                    For _j = 1 To 10
                        If Mid(_digits, _j, 1) = _ch Then
                            _d = _j - 1
                        End If
                    Next
                    If _d < 0 Then
                        If _ch = " " Or _ch = Chr(9) Then
                            _i = _i + 1
                        Else
                            _i = _len + 1
                        End If
                    Else
                        _tem = True
                        _n = _d
                        _i = _i + 1
                    End If
                End If
            Wend

            If _tem Then
                ExtrairInteiroChaveCurta = _n
            End If
        End Function

        Private Function ExtrairTextoChaveCurta(pObj As String, pChave As String, pMax As Integer) As String
            Dim _pos As Integer = 0
            Dim _len As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _result As String = ""
            Dim _n As Integer = 0
            Dim _escape As Boolean = False

            ExtrairTextoChaveCurta = ""
            _pos = me.PosicaoValorChaveCurta(pObj, pChave)
            If _pos <= 0 Then
                Exit Function
            End If

            _len = Len(pObj)
            If _pos > _len Then
                Exit Function
            End If

            If Mid(pObj, _pos, 1) <> _q Then
                Exit Function
            End If

            _i = _pos + 1
            While _i <= _len
                If _n >= pMax Then
                    _i = _len + 1
                Else
                    _ch = Mid(pObj, _i, 1)
                    If _escape Then
                        _result = _result & _ch
                        _n = _n + 1
                        _escape = False
                    Else
                        If _ch = "\" Then
                            _escape = True
                        Else
                            If _ch = _q Then
                                _i = _len + 1
                            Else
                                _result = _result & _ch
                                _n = _n + 1
                            End If
                        End If
                    End If
                    If _i <= _len Then
                        _i = _i + 1
                    End If
                End If
            Wend

            ExtrairTextoChaveCurta = _result
        End Function

        Private Function PosicaoValorChaveCurta(pObj As String, pChave As String) As Integer
            Dim _len As Integer = Len(pObj)
            Dim _q As String = Chr(34)
            Dim _needle As String = ""
            Dim _needleLen As Integer = 0
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _achou As Boolean = False

            PosicaoValorChaveCurta = 0
            _needle = _q & pChave & _q
            _needleLen = Len(_needle)
            If _needleLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _needleLen + 1)
                If _achou Then
                    _i = _len + 1
                Else
                    If Mid(pObj, _i, _needleLen) = _needle Then
                        _j = _i + _needleLen
                        If _j <= _len Then
                            _ch = Mid(pObj, _j, 1)
                            If _ch <> "_" Then
                                While _j <= _len
                                    _ch = Mid(pObj, _j, 1)
                                    If _ch = " " Then
                                        _j = _j + 1
                                    Else
                                        Exit While
                                    End If
                                Wend
                                If _j <= _len Then
                                    If Mid(pObj, _j, 1) = ":" Then
                                        _j = _j + 1
                                        While _j <= _len
                                            _ch = Mid(pObj, _j, 1)
                                            If _ch = " " Then
                                                _j = _j + 1
                                            Else
                                                Exit While
                                            End If
                                        Wend
                                        PosicaoValorChaveCurta = _j
                                        _achou = True
                                    End If
                                End If
                            End If
                        End If
                    End If
                    _i = _i + 1
                End If
            Wend
        End Function

        Private Function NormalizarUf(pUf As String) As String
            Dim _uf As String = pUf.Trim()
            Dim _result As String = ""
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _ok As Boolean = True

            If Len(_uf) <> 2 Then
                NormalizarUf = ""
                Exit Function
            End If

            _uf = UCase(_uf)
            For _i = 1 To 2
                _ch = Mid(_uf, _i, 1)
                If _ch < "A" Then
                    _ok = False
                Else
                    If _ch > "Z" Then
                        _ok = False
                    End If
                End If
            Next

            If _ok Then
                _result = _uf
            End If
            NormalizarUf = _result
        End Function

        ' Mid de 24 a partir do fim — mesmo padrao de ExtrairWarehouseDoBlob (sync user).
        Private Function PosicaoValorChaveDoFim(pBody As String, pChave As String) As Integer
            Dim _len As Integer = Len(pBody)
            Dim _q As String = Chr(34)
            Dim _needle As String = ""
            Dim _needleLen As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _achou As Boolean = False

            PosicaoValorChaveDoFim = 0

            If Len(pChave) <= 0 Then
                Exit Function
            End If

            _needle = _q & pChave & _q
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

            If _i > _len Then
                Exit Function
            End If

            PosicaoValorChaveDoFim = _i
        End Function

        Private Function ExtrairInteiroNaPosicao(pBody As String, pPos As Integer) As Integer
            Dim _len As Integer = Len(pBody)
            Dim _i As Integer = pPos
            Dim _max As Integer = 0
            Dim _ch As String = ""
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _j As Integer = 0
            Dim _digits As String = "0123456789"

            ExtrairInteiroNaPosicao = 0

            If pPos < 1 Then
                Exit Function
            End If

            If pPos > _len Then
                Exit Function
            End If

            _max = pPos + 11
            If _max > _len Then
                _max = _len
            End If

            While _i <= _max
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
                If Not Parser.PodeAcumularDigito(_n, _d) Then
                    _n = 0
                    Exit While
                End If
                _n = (_n * 10) + _d
                _i = _i + 1
            Wend

            ExtrairInteiroNaPosicao = _n
        End Function

        Private Function ExtrairInteiroChaveDoFim(pBody As String, pChave As String) As Integer
            Dim _pos As Integer = 0

            ExtrairInteiroChaveDoFim = 0
            _pos = me.PosicaoValorChaveDoFim(pBody, pChave)
            If _pos <= 0 Then
                Exit Function
            End If

            ExtrairInteiroChaveDoFim = me.ExtrairInteiroNaPosicao(pBody, _pos)
        End Function

        Private Function ExtrairTextoQuotedNaPosicao(pBody As String, pPos As Integer) As String
            Dim _len As Integer = Len(pBody)
            Dim _q As String = Chr(34)
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _result As String = ""
            Dim _nValor As Integer = 0
            Dim _maxValor As Integer = 20

            ExtrairTextoQuotedNaPosicao = ""

            If pPos < 1 Then
                Exit Function
            End If

            If pPos > _len Then
                Exit Function
            End If

            If Mid(pBody, pPos, 1) <> _q Then
                Exit Function
            End If

            _i = pPos + 1
            While _i <= _len
                If _nValor >= _maxValor Then
                    Exit While
                End If

                _ch = Mid(pBody, _i, 1)
                If _ch = _q Then
                    Exit While
                End If

                _result = _result & _ch
                _nValor = _nValor + 1
                _i = _i + 1
            Wend

            ExtrairTextoQuotedNaPosicao = _result
        End Function

        ' user.company e numero; o objeto company da raiz e o primeiro `"company":{` a partir do fim.
        Private Function PosicaoAbreCompanyDoFim(pBody As String) As Integer
            Dim _len As Integer = Len(pBody)
            Dim _q As String = Chr(34)
            Dim _needle As String = ""
            Dim _needleLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""

            PosicaoAbreCompanyDoFim = 0

            _needle = _q & "company" & _q
            _needleLen = Len(_needle)
            If _needleLen <= 0 Then
                Exit Function
            End If

            If _len < _needleLen Then
                Exit Function
            End If

            _pos = _len - _needleLen + 1
            While _pos >= 1
                If Mid(pBody, _pos, _needleLen) = _needle Then
                    _i = _pos + _needleLen

                    While _i <= _len
                        _ch = Mid(pBody, _i, 1)
                        If _ch = " " Then
                            _i = _i + 1
                        Else
                            Exit While
                        End If
                    Wend

                    If _i <= _len Then
                        If Mid(pBody, _i, 1) = ":" Then
                            _i = _i + 1
                        End If
                    End If

                    While _i <= _len
                        _ch = Mid(pBody, _i, 1)
                        If _ch = " " Then
                            _i = _i + 1
                        Else
                            Exit While
                        End If
                    Wend

                    If _i <= _len Then
                        If Mid(pBody, _i, 1) = "{" Then
                            PosicaoAbreCompanyDoFim = _i
                            Exit Function
                        End If
                    End If
                End If
                _pos = _pos - 1
            Wend
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
                If Not Parser.PodeAcumularDigito(_n, _d) Then
                    _n = 0
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

        Private Function MontarMensagemBloqueio(pModel As RedeAncoraEmpresaModel) As String
            If pModel.MotivosBloqueio = "" Then
                MontarMensagemBloqueio = "sem motivo informado"
                Exit Function
            End If

            MontarMensagemBloqueio = pModel.MotivosBloqueio
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._authService) Then
                    me._authService.Free()
                    me._authService = NULL
                End If

                If Assigned(me._empresaRepository) Then
                    me._empresaRepository.Free()
                    me._empresaRepository = NULL
                End If

                If Assigned(me._centroDistribuicaoRepository) Then
                    me._centroDistribuicaoRepository.Free()
                    me._centroDistribuicaoRepository = NULL
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
