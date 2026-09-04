Imports mod_tobject
Imports mod_logger
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_json_helper
Imports rede_ancora_empresa_model
Imports rede_ancora_empresa_repository
Imports rede_ancora_centro_distribuicao_model
Imports rede_ancora_centros_distribuicao_model
Imports rede_ancora_centro_distribuicao_repository
Imports try_parser
Imports http_response

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
            Dim _json As TJSONObject = NULL
            Dim _model As RedeAncoraEmpresaModel = NULL
            Dim _centros As RedeAncoraCentrosDistribuicaoModel = NULL
            Dim _qtdCentros As Integer = 0

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/profile"))

                If Not _response.IsSuccess Then
                    Throw New System.Exception("GET /profile Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                _json = _response.BodyAsJsonObject()
                _model = New RedeAncoraEmpresaModel()
                _centros = New RedeAncoraCentrosDistribuicaoModel()
                me.MapearPerfilResposta(_json, pCodUsuario, _model, _centros)
                mod_logger.Printe("Rede Ancora sync profile :: mapeamento JSON OK")
                me._authService.AtualizarUsuarioDeProfileJson(pCodUsuario, _json)
                mod_logger.Printe("Rede Ancora sync profile :: autenticacao atualizada")
                me._empresaRepository.Salvar(_model)
                mod_logger.Printe("Rede Ancora sync profile :: empresa gravada")
                me._centroDistribuicaoRepository.SubstituirPorCodUsuario(pCodUsuario, _centros)
                mod_logger.Printe("Rede Ancora sync profile :: CDs gravados")

                _qtdCentros = _centros.Length
                mod_logger.Printe("Rede Ancora sync profile concluido. Empresa Ancora: " + Parser.IntegerToString(_model.CodEmpresaAncora) + " | CDs: " + Parser.IntegerToString(_qtdCentros))

                SincronizarPerfil = _model
                _centros.Free()
                _json.Free()
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_centros) Then
                    _centros.Free()
                End If

                If Assigned(_model) Then
                    _model.Free()
                End If

                If Assigned(_json) Then
                    _json.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar profile Rede Ancora: " + ex._getMessage())
            End Try
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

        Private Sub MapearPerfilResposta(pJson As TJSONObject, pCodUsuario As Integer, pModel As RedeAncoraEmpresaModel, pCentros As RedeAncoraCentrosDistribuicaoModel)
            Dim _data As TJSONObject = RedeAncoraJsonHelper.ObterRaizOuDataObjeto(pJson)
            Dim _perfil As TJSONObject = RedeAncoraJsonHelper.UsarRaizOuData(pJson, _data)

            me.MapearPerfil(_perfil, pCodUsuario, pModel, pCentros)

            If Assigned(_data) Then
                _data.Free()
            End If
        End Sub

        Private Sub MapearPerfil(pJson As TJSONObject, pCodUsuario As Integer, pModel As RedeAncoraEmpresaModel, pCentros As RedeAncoraCentrosDistribuicaoModel)
            pModel.CodUsuario = pCodUsuario

            If Not me._empresaRepository.TryObterPorCodUsuario(pCodUsuario, pModel) Then
                pModel.CodUsuario = pCodUsuario
            End If

            me.MapearUsuarioPerfil(pJson, pModel)
            me.MapearEmpresaPerfil(pJson, pModel)
            me.MapearSituacaoPerfil(pJson, pModel)
            me.MapearCentrosDistribuicaoPerfil(pJson, pCodUsuario, pCentros)
        End Sub

        Private Sub MapearUsuarioPerfil(pJson As TJSONObject, pModel As RedeAncoraEmpresaModel)
            Dim _user As TJSONObject = RedeAncoraJsonHelper.ObterFilhoJson(pJson, "user")

            If Not Assigned(_user) Then
                Exit Sub
            End If

            pModel.IdCarrinhoAtual = RedeAncoraJsonHelper.ObterTextoJson(_user, "current_cart_id")
            _user.Free()
        End Sub

        Private Sub MapearEmpresaPerfil(pJson As TJSONObject, pModel As RedeAncoraEmpresaModel)
            Dim _company As TJSONObject = RedeAncoraJsonHelper.ObterFilhoJson(pJson, "company")

            If Not Assigned(_company) Then
                Throw New System.Exception("Profile Rede Ancora sem dados de company")
            End If

            pModel.CodEmpresaAncora = RedeAncoraJsonHelper.ObterInteiroJson(_company, "id")
            pModel.CodInterno = RedeAncoraJsonHelper.ObterInteiroJson(_company, "internal")
            pModel.RazaoSocial = RedeAncoraJsonHelper.ObterTextoJson(_company, "nome")
            pModel.NomeFantasia = RedeAncoraJsonHelper.ObterTextoJson(_company, "apelido")
            pModel.CodEstado = RedeAncoraJsonHelper.ObterInteiroJson(_company, "estado")
            pModel.CodCentroDistribuicaoPreferencial = RedeAncoraJsonHelper.ObterInteiroJson(_company, "warehouse_preferencial")
            pModel.SetCnpj(RedeAncoraJsonHelper.ObterTextoJson(_company, "cgc"))
            _company.Free()
        End Sub

        Private Sub MapearSituacaoPerfil(pJson As TJSONObject, pModel As RedeAncoraEmpresaModel)
            Dim _balance As TJSONObject = NULL

            If RedeAncoraJsonHelper.ObterBooleanJson(pJson, "is_blocked") Then
                pModel.Bloqueado = "S"
            Else
                pModel.Bloqueado = "N"
            End If

            pModel.MotivosBloqueio = me.MontarMotivosBloqueio(pJson)

            If RedeAncoraJsonHelper.ObterBooleanJson(pJson, "marketplace") Then
                pModel.Marketplace = "S"
            Else
                pModel.Marketplace = "N"
            End If

            pModel.Permissoes = me.MontarPermissoes(pJson)

            _balance = me.ObterObjetoJson(pJson, "balance")
            If Assigned(_balance) Then
                pModel.SaldoAtual = RedeAncoraJsonHelper.ObterDecimalJson(_balance, "current_balance")
                pModel.LimiteCredito = RedeAncoraJsonHelper.ObterDecimalJson(_balance, "current_limit_value")
                pModel.LimiteUtilizado = RedeAncoraJsonHelper.ObterDecimalJson(_balance, "total_limit_used")
                _balance.Free()
            End If
        End Sub

        Private Sub MapearCentrosDistribuicaoPerfil(pJson As TJSONObject, pCodUsuario As Integer, pCentros As RedeAncoraCentrosDistribuicaoModel)
            Dim _warehouses As TJSONArray = me.ObterArrayJson(pJson, "warehouses")
            Dim _i As Integer

            If Not Assigned(_warehouses) Then
                Exit Sub
            End If

            For _i = 0 To _warehouses.Length() - 1
                Dim _warehouse As TJSONObject = _warehouses.GetJSONObject(_i)
                Dim _item As New RedeAncoraCentroDistribuicaoModel()

                _item.CodUsuario = pCodUsuario
                _item.CodCentroDistribuicao = RedeAncoraJsonHelper.ObterInteiroJson(_warehouse, "empresa")
                _item.Nome = RedeAncoraJsonHelper.ObterTextoJson(_warehouse, "nome")
                _item.NomeFantasia = RedeAncoraJsonHelper.ObterTextoJson(_warehouse, "nome_fantasia")
                _item.CodEstado = RedeAncoraJsonHelper.ObterInteiroJson(_warehouse, "estado")

                If RedeAncoraJsonHelper.ObterInteiroJson(_warehouse, "preferential") = 1 Then
                    _item.Preferencial = "S"
                Else
                    _item.Preferencial = "N"
                End If

                pCentros.Push(_item)
                _warehouse.Free()
            Next

            _warehouses.Free()
        End Sub

        Private Function MontarMotivosBloqueio(pJson As TJSONObject) As String
            MontarMotivosBloqueio = me.ConcatenarTextosArrayJson(pJson, "blocked_reason", "; ")
        End Function

        Private Function MontarPermissoes(pJson As TJSONObject) As String
            MontarPermissoes = me.ConcatenarTextosArrayJson(pJson, "permissions", ",")
        End Function

        Private Function ConcatenarTextosArrayJson(pJson As TJSONObject, pKey As String, pSeparador As String) As String
            Dim _arr As TJSONArray = Null
            Dim _blob As String = ""
            Dim _elem As String = ""
            Dim _wrapper As TJSONObject = Null
            Dim _texto As String = ""
            Dim _result As String = ""
            Dim _quote As String = CStr(Chr(34))
            Dim _i As Integer

            Try
                _arr = RedeAncoraJsonHelper.ObterArrayJson(pJson, pKey)

                If Assigned(_arr) Then
                    _blob = _arr.ToString()
                    _arr.Free()
                    _arr = Null

                    ' teto de seguranca (10000) contra loop infinito se ExtrairElementoArrayJson nao devolver vazio
                    For _i = 0 To 9999
                        _elem = RedeAncoraJsonHelper.ExtrairElementoArrayJson(_blob, _i)

                        If _elem = "" Then
                            Exit For
                        End If

                        _wrapper = New TJSONObject("{" + _quote + "v" + _quote + ":" + _elem + "}")
                        _texto = RedeAncoraJsonHelper.ObterTextoJson(_wrapper, "v")
                        _wrapper.Free()
                        _wrapper = Null

                        If _texto <> "" Then
                            If _result <> "" Then
                                _result = _result + pSeparador
                            End If

                            _result = _result + CStr(_texto)
                        End If
                    Next
                End If
            Catch ex As Exception
                If Assigned(_wrapper) Then
                    _wrapper.Free()
                    _wrapper = Null
                End If

                If Assigned(_arr) Then
                    _arr.Free()
                    _arr = Null
                End If

                Throw New System.Exception("Erro ao ler array JSON " + pKey + ": " + ex._getMessage())
            End Try

            ConcatenarTextosArrayJson = _result
        End Function

        Private Function ObterArrayJson(pJson As TJSONObject, pKey As String) As TJSONArray
            ObterArrayJson = RedeAncoraJsonHelper.ObterArrayJson(pJson, pKey)
        End Function

        Private Function ObterObjetoJson(pJson As TJSONObject, pKey As String) As TJSONObject
            ObterObjetoJson = RedeAncoraJsonHelper.ObterObjetoJson(pJson, pKey)
        End Function

        Private Function ObterDecimalJson(pJson As TJSONObject, pKey As String) As Double
            ObterDecimalJson = RedeAncoraJsonHelper.ObterDecimalJson(pJson, pKey)
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
