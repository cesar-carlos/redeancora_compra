Imports mod_tobject
Imports mod_logger
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_empresa_service
Imports rede_ancora_json_helper
Imports rede_ancora_carrinho_itens_ids_model
Imports rede_ancora_checkout_revisao_model
Imports rede_ancora_checkout_entrega_seller_model
Imports rede_ancora_checkout_entrega_opcao_model
Imports rede_ancora_checkout_pagamentos_model
Imports rede_ancora_checkout_condicao_pagamento_model
Imports rede_ancora_checkout_condicoes_pagamento_model
Imports rede_ancora_checkout_entregas_solicitacao_model
Imports rede_ancora_checkout_entrega_solicitacao_model
Imports rede_ancora_logistica_transportador_model
Imports rede_ancora_logistica_transportadores_model
Imports rede_ancora_pedido_model
Imports rede_ancora_pedidos_model
Imports rede_ancora_pedido_repository
Imports rede_ancora_carrinho_repository
Imports rede_ancora_carrinho_model
Imports rede_ancora_empresa_repository
Imports rede_ancora_empresa_model
Imports rede_ancora_input_consultar_pagamentos
Imports rede_ancora_output_consultar_pagamentos
Imports rede_ancora_input_aplicar_condicao_pagamento
Imports rede_ancora_output_aplicar_condicao_pagamento
Imports rede_ancora_input_consultar_detalhe_condicao_pagamento
Imports rede_ancora_output_consultar_detalhe_condicao_pagamento
Imports rede_ancora_input_confirmar_pedido
Imports rede_ancora_output_confirmar_pedido
Imports rede_ancora_input_criar_transportador
Imports rede_ancora_input_atualizar_transportador
Imports http_response
Imports rede_ancora_http_erro_helper

Namespace rede_ancora_checkout_service
    Class RedeAncoraCheckoutService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _empresaService As RedeAncoraEmpresaService
        Private _pedidoRepository As RedeAncoraPedidoRepository
        Private _carrinhoRepository As RedeAncoraCarrinhoRepository
        Private _empresaRepository As RedeAncoraEmpresaRepository

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._empresaService = New RedeAncoraEmpresaService()
            me._pedidoRepository = New RedeAncoraPedidoRepository()
            me._carrinhoRepository = New RedeAncoraCarrinhoRepository()
            me._empresaRepository = New RedeAncoraEmpresaRepository()
        End Sub

        Function RevisarCarrinho(pCodUsuario As Integer, pIdCarrinho As String, pItensIds As RedeAncoraCarrinhoItensIdsModel) As RedeAncoraCheckoutRevisaoModel
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As String = ""

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _payload = me.MontarPayloadItensOpcional(pItensIds)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho + "/review"), _payload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("POST /checkout/review", _response))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("POST /checkout/review", _response.StatusCode, _response.Body)

                RevisarCarrinho = me.MapearRevisao(_response)
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.RevisarCarrinho", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao revisar carrinho Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ConsultarPagamentos(pInput As RedeAncoraInputConsultarPagamentos) As RedeAncoraOutputConsultarPagamentos
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As String = ""
            Dim _output As New RedeAncoraOutputConsultarPagamentos()

            Try
                If Not Assigned(pInput) Then
                    Throw New System.Exception("Input ConsultarPagamentos nao informado")
                End If

                me._empresaService.ValidarPodeOperar(pInput.CodUsuario)

                If pInput.CodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("CodCentroDistribuicao invalido para consulta de pagamentos")
                End If

                If pInput.CodModalidade <= 0 Then
                    Throw New System.Exception("CodModalidade invalido para consulta de pagamentos")
                End If

                _payload = me.MontarPayloadPagamentos(pInput.CodCentroDistribuicao, pInput.CodModalidade, pInput.ItensIds)
                mod_logger.Info("POST /checkout/payments payload=" & me.LogTextoTruncadoLocal(_payload))

                _api = New RedeAncoraApiClient(pInput.CodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pInput.IdCarrinho + "/payments"), _payload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("POST /checkout/payments", _response))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("POST /checkout/payments", _response.StatusCode, _response.Body)

                mod_logger.Info("POST /checkout/payments HTTP " & Parser.IntegerToString(_response.StatusCode))

                _output.Pagamentos = me.MapearPagamentos(_response)
                ConsultarPagamentos = _output
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.ConsultarPagamentos", ex)

                If Assigned(_output) Then
                    _output.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw ex
            End Try
        End Function

        Function AplicarCondicaoPagamento(pInput As RedeAncoraInputAplicarCondicaoPagamento) As RedeAncoraOutputAplicarCondicaoPagamento
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As String = ""
            Dim _output As New RedeAncoraOutputAplicarCondicaoPagamento()

            Try
                me._empresaService.ValidarPodeOperar(pInput.CodUsuario)

                If pInput.CodCondicaoPagamento <= 0 Then
                    Throw New System.Exception("CodCondicaoPagamento invalido para aplicacao de pagamento")
                End If

                If pInput.CodEstado <= 0 Then
                    Throw New System.Exception("CodEstado invalido para aplicacao de pagamento")
                End If

                _payload = me.MontarPayloadAplicarCondicaoPagamento(pInput.CodCondicaoPagamento, pInput.CodEstado, pInput.ItensIds)

                _api = New RedeAncoraApiClient(pInput.CodUsuario, me._authService)
                _response = _api.PatchJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pInput.IdCarrinho + "/payments"), _payload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("PATCH /checkout/payments", _response))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("PATCH /checkout/payments", _response.StatusCode, _response.Body)

                _output.Resultado = _response.Body
                AplicarCondicaoPagamento = _output
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.AplicarCondicaoPagamento", ex)

                If Assigned(_output) Then
                    _output.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao aplicar condicao de pagamento Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ConsultarDetalheCondicaoPagamento(pInput As RedeAncoraInputConsultarDetalheCondicaoPagamento) As RedeAncoraOutputConsultarDetalheCondicaoPagamento
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As String = ""
            Dim _output As New RedeAncoraOutputConsultarDetalheCondicaoPagamento()

            Try
                me._empresaService.ValidarPodeOperar(pInput.CodUsuario)
                _payload = me.MontarPayloadDetalheCondicaoPagamento(pInput.CodCentroDistribuicao, pInput.CodModalidade, pInput.CodCondicaoPagamento)

                _api = New RedeAncoraApiClient(pInput.CodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pInput.IdCarrinho + "/payments/condition"), _payload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("POST /checkout/payments/condition", _response))
                End If

                _output.Resultado = _response.Body
                ConsultarDetalheCondicaoPagamento = _output
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_output) Then
                    _output.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao consultar detalhe de condicao de pagamento Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ListarTransportadores(pCodUsuario As Integer) As RedeAncoraLogisticaTransportadoresModel
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/logistics/haulers"))

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("GET /logistics/haulers", _response))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET /logistics/haulers", _response.StatusCode, _response.Body)

                ListarTransportadores = me.MapearTransportadores(_response)
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.ListarTransportadores", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao listar transportadores Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ConsultarTransportador(pCodUsuario As Integer, pIdTransportador As Integer) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                If pIdTransportador <= 0 Then
                    Throw New System.Exception("IdTransportador invalido para consulta")
                End If

                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/logistics/haulers/" + Parser.IntegerToString(pIdTransportador)))

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("GET /logistics/haulers/{id}", _response))
                End If

                ConsultarTransportador = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao consultar transportador Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function CriarTransportador(pInput As RedeAncoraInputCriarTransportador) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As String = ""

            Try
                If Not Assigned(pInput) Then
                    Throw New System.Exception("Input CriarTransportador nao informado")
                End If

                me._empresaService.ValidarPodeOperar(pInput.CodUsuario)
                _payload = me.MontarPayloadHauler(pInput.Nome, pInput.TipoDocumento, pInput.Documento, pInput.TipoVeiculo, pInput.PlacaVeiculo, pInput.PessoaContato, pInput.TelefoneContato, pInput.Observacoes, pInput.Habilitado)

                _api = New RedeAncoraApiClient(pInput.CodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/logistics/haulers"), _payload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("POST /logistics/haulers", _response))
                End If

                CriarTransportador = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao criar transportador Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function AtualizarTransportador(pInput As RedeAncoraInputAtualizarTransportador) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As String = ""

            Try
                If Not Assigned(pInput) Then
                    Throw New System.Exception("Input AtualizarTransportador nao informado")
                End If

                If pInput.IdTransportador <= 0 Then
                    Throw New System.Exception("IdTransportador invalido para atualizacao")
                End If

                me._empresaService.ValidarPodeOperar(pInput.CodUsuario)
                _payload = me.MontarPayloadHauler(pInput.Nome, pInput.TipoDocumento, pInput.Documento, pInput.TipoVeiculo, pInput.PlacaVeiculo, pInput.PessoaContato, pInput.TelefoneContato, pInput.Observacoes, pInput.Habilitado)

                _api = New RedeAncoraApiClient(pInput.CodUsuario, me._authService)
                _response = _api.PatchJson(RedeAncoraApiConfig.IntegrationUrl("/logistics/haulers/" + Parser.IntegerToString(pInput.IdTransportador)), _payload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("PATCH /logistics/haulers/{id}", _response))
                End If

                AtualizarTransportador = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao atualizar transportador Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ExcluirTransportador(pCodUsuario As Integer, pIdTransportador As Integer) As Boolean
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _body As String = ""
            Dim _raw As String = ""

            Try
                If pIdTransportador <= 0 Then
                    Throw New System.Exception("IdTransportador invalido para exclusao")
                End If

                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.DeleteRequest(RedeAncoraApiConfig.IntegrationUrl("/logistics/haulers/" + Parser.IntegerToString(pIdTransportador)), "")

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("DELETE /logistics/haulers/{id}", _response))
                End If

                _body = _response.Body
                RedeAncoraHttpErroHelper.ExigirCorpoJson("DELETE /logistics/haulers/{id}", _response.StatusCode, _body)

                If Not RedeAncoraJsonHelper.ExisteChaveJsonDeBlob(_body, "data") Then
                    RedeAncoraHttpErroHelper.RegistrarFalha("DELETE /logistics/haulers/{id}", _response.StatusCode, _body)
                    Throw New System.Exception("DELETE /logistics/haulers/{id} sem campo data boolean")
                End If

                _raw = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(_body, "data").Trim()
                If _raw = "" Then
                    RedeAncoraHttpErroHelper.RegistrarFalha("DELETE /logistics/haulers/{id}", _response.StatusCode, _body)
                    Throw New System.Exception("DELETE /logistics/haulers/{id} data vazio ou objeto (esperado boolean)")
                End If

                ExcluirTransportador = RedeAncoraJsonHelper.ObterBooleanJsonDeBlob(_body, "data")
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.ExcluirTransportador", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao excluir transportador Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ListarTiposVeiculo(pCodUsuario As Integer) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/logistics/haulers/vehicleTypes"))

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("GET /logistics/haulers/vehicleTypes", _response))
                End If

                ListarTiposVeiculo = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao listar tipos de veiculo Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ConsultarEntregasLogistica(pCodUsuario As Integer, pIdCarrinho As String, pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As String = ""

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _payload = me.MontarPayloadEntregasLogistica(pIdCarrinho, pItensIds)

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/logistics/carriers"), _payload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("POST /logistics/carriers", _response))
                End If

                ConsultarEntregasLogistica = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao consultar entregas logisticas Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ConfirmarPedido(pInput As RedeAncoraInputConfirmarPedido) As RedeAncoraOutputConfirmarPedido
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As String = ""
            Dim _pedidos As RedeAncoraPedidosModel = NULL
            Dim _output As New RedeAncoraOutputConfirmarPedido()
            Dim _result As RedeAncoraOutputConfirmarPedido = NULL

            Try
                me._empresaService.ValidarPodeOperar(pInput.CodUsuario)
                me._empresaService.ValidarPermissoes(pInput.CodUsuario, "orders")

                If me.CarrinhoLocalJaConvertido(pInput.IdCarrinho) Then
                    _pedidos = me._pedidoRepository.ListarPorIdCarrinho(pInput.CodUsuario, pInput.IdCarrinho)
                    _output.Pedidos = _pedidos
                    _result = _output
                    _output = NULL
                    _pedidos = NULL
                Else
                    pInput.Entregas.ValidarTodos()

                    _payload = me.MontarPayloadConfirmarPedido(pInput.Entregas, pInput.ItensIds)

                    _api = New RedeAncoraApiClient(pInput.CodUsuario, me._authService)
                    _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pInput.IdCarrinho + "/order"), _payload)

                    If Not _response.IsSuccess Then
                        Throw New System.Exception(me.MontarErroHttp("POST /checkout/order", _response))
                    End If

                    RedeAncoraHttpErroHelper.ExigirCorpoJson("POST /checkout/order", _response.StatusCode, _response.Body)

                    _pedidos = me.MapearPedidos(pInput.CodUsuario, pInput.IdCarrinho, _response)
                    me._pedidoRepository.SalvarVarios(_pedidos)
                    me.MarcarCarrinhoConvertido(pInput.IdCarrinho)
                    me.LimparIdCarrinhoEmpresa(pInput.CodUsuario)

                    _output.Pedidos = _pedidos
                    _result = _output
                    _output = NULL
                    _pedidos = NULL
                    _response.Free()
                    _response = NULL
                    _api.Free()
                    _api = NULL
                End If
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.ConfirmarPedido", ex)

                If Assigned(_output) Then
                    _output.Free()
                    _output = NULL
                End If

                If Assigned(_pedidos) Then
                    _pedidos.Free()
                    _pedidos = NULL
                End If

                If Assigned(_response) Then
                    _response.Free()
                    _response = NULL
                End If

                If Assigned(_api) Then
                    _api.Free()
                    _api = NULL
                End If

                Throw New System.Exception("Erro ao confirmar pedido Rede Ancora: " + ex._getMessage())
            End Try

            ConfirmarPedido = _result
        End Function

        Function ListarPedidosLocal(pCodUsuario As Integer) As RedeAncoraPedidosModel
            ListarPedidosLocal = me._pedidoRepository.ListarPorCodUsuario(pCodUsuario)
        End Function

        Private Function MapearRevisao(pResponse As HttpResponse) As RedeAncoraCheckoutRevisaoModel
            Dim _body As String = ""
            Dim _result As RedeAncoraCheckoutRevisaoModel = NULL
            Dim _ok As RedeAncoraCheckoutRevisaoModel = NULL
            Dim _seller As RedeAncoraCheckoutEntregaSellerModel = NULL
            Dim _opcao As RedeAncoraCheckoutEntregaOpcaoModel = NULL
            Dim _dataStart As Integer = 0
            Dim _dataFim As Integer = 0
            Dim _totalsStart As Integer = 0
            Dim _totalsFim As Integer = 0
            Dim _carriersStart As Integer = 0
            Dim _sellerStart As Integer = 0
            Dim _sellerFim As Integer = 0
            Dim _innerStart As Integer = 0
            Dim _opStart As Integer = 0
            Dim _opFim As Integer = 0
            Dim _i As Integer = 0
            Dim _j As Integer = 0

            Try
                _body = pResponse.Body

                If _body.Trim() = "" Then
                    Throw New System.Exception("Resposta /checkout/review vazia")
                End If

                _dataStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlob(_body, "data")

                If _dataStart <= 0 Then
                    Throw New System.Exception("Resposta /checkout/review sem objeto data")
                End If

                _dataFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _dataStart)
                _result = New RedeAncoraCheckoutRevisaoModel()
                _result.QtdItens = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "items_count", _dataStart, _dataFim)
                _result.QtdItensTotal = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "items_qty", _dataStart, _dataFim)

                _totalsStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlobApos(_body, "totals", _dataStart)
                If _totalsStart > 0 Then
                    If _dataFim <= 0 Or _totalsStart <= _dataFim Then
                        _totalsFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _totalsStart)
                        _result.Subtotal = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(_body, "subtotal", _totalsStart, _totalsFim)
                        _result.Impostos = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(_body, "taxes", _totalsStart, _totalsFim)
                        _result.Total = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(_body, "total", _totalsStart, _totalsFim)
                    End If
                End If

                _carriersStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlobApos(_body, "carriers", _dataStart)
                If _carriersStart > 0 Then
                    If _dataFim <= 0 Or _carriersStart <= _dataFim Then
                        For _i = 0 To 999
                            _sellerStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(_body, _carriersStart, _i)

                            If _sellerStart <= 0 Then
                                Exit For
                            End If

                            If _dataFim > 0 Then
                                If _sellerStart > _dataFim Then
                                    Exit For
                                End If
                            End If

                            Try
                                _sellerFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _sellerStart)
                                _seller = New RedeAncoraCheckoutEntregaSellerModel()
                                _seller.CodCentroDistribuicao = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "seller_id", _sellerStart, _sellerFim)
                                _seller.NomeCentroDistribuicao = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(_body, "seller_name", _sellerStart, _sellerFim)

                                _innerStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlobApos(_body, "carriers", _sellerStart)
                                If _innerStart > 0 Then
                                    If _sellerFim <= 0 Or _innerStart <= _sellerFim Then
                                        For _j = 0 To 999
                                            _opStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(_body, _innerStart, _j)

                                            If _opStart <= 0 Then
                                                Exit For
                                            End If

                                            If _sellerFim > 0 Then
                                                If _opStart > _sellerFim Then
                                                    Exit For
                                                End If
                                            End If

                                            Try
                                                _opFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _opStart)
                                                _opcao = New RedeAncoraCheckoutEntregaOpcaoModel()
                                                _opcao.CodEntrega = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "carrier_id", _opStart, _opFim)
                                                _opcao.Nome = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(_body, "name", _opStart, _opFim)
                                                _opcao.ExigeTransportador = RedeAncoraJsonHelper.SimNao(RedeAncoraJsonHelper.ObterBooleanJsonDeBlobEntre(_body, "haulers_required", _opStart, _opFim))
                                                _seller.Opcoes.Push(_opcao)
                                                _opcao = NULL
                                            Catch exOpcao As Exception
                                                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearRevisao.carrier", exOpcao)

                                                If Assigned(_opcao) Then
                                                    _opcao.Free()
                                                    _opcao = NULL
                                                End If
                                            End Try
                                        Next
                                    End If
                                End If

                                _result.EntregasSellers.Push(_seller)
                                _seller = NULL
                            Catch exSeller As Exception
                                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearRevisao.seller", exSeller)

                                If Assigned(_seller) Then
                                    _seller.Free()
                                    _seller = NULL
                                End If
                            End Try
                        Next
                    End If
                End If

                _ok = _result
                _result = NULL
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearRevisao", ex)

                If Assigned(_opcao) Then
                    _opcao.Free()
                    _opcao = NULL
                End If

                If Assigned(_seller) Then
                    _seller.Free()
                    _seller = NULL
                End If

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                Throw New System.Exception("Erro ao mapear /checkout/review: " & ex._getMessage())
            End Try

            MapearRevisao = _ok
        End Function

        Private Function MapearPagamentos(pResponse As HttpResponse) As RedeAncoraCheckoutPagamentosModel
            Dim _body As String = ""
            Dim _dataStart As Integer = 0
            Dim _dataFim As Integer = 0
            Dim _arrStart As Integer = 0
            Dim _itemsStart As Integer = 0
            Dim _itemsFim As Integer = 0
            Dim _result As RedeAncoraCheckoutPagamentosModel = NULL
            Dim _ok As RedeAncoraCheckoutPagamentosModel = NULL

            Try
                _body = pResponse.Body

                If _body.Trim() = "" Then
                    Throw New System.Exception("Resposta /checkout/payments vazia")
                End If

                _result = New RedeAncoraCheckoutPagamentosModel()
                _dataStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlob(_body, "data")

                If _dataStart > 0 Then
                    _dataFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _dataStart)
                    me.PreencherCondicoesPagamento(_body, _dataStart, _dataFim, "vendor", _result.Fornecedor)
                    me.PreencherCondicoesPagamento(_body, _dataStart, _dataFim, "free", _result.Livre)
                    me.PreencherCondicoesPagamento(_body, _dataStart, _dataFim, "special", _result.Especial)
                Else
                    _arrStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlob(_body, "data")

                    If _arrStart <= 0 Then
                        _arrStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlob(_body, "items")
                    End If

                    If _arrStart > 0 Then
                        me.MapearPagamentosDataArray(_body, _arrStart, _result)
                    Else
                        _itemsStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlob(_body, "items")

                        If _itemsStart <= 0 Then
                            Throw New System.Exception("Resposta /checkout/payments sem data/items objeto ou array")
                        End If

                        _itemsFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _itemsStart)
                        me.PreencherCondicoesPagamento(_body, _itemsStart, _itemsFim, "vendor", _result.Fornecedor)
                        me.PreencherCondicoesPagamento(_body, _itemsStart, _itemsFim, "free", _result.Livre)
                        me.PreencherCondicoesPagamento(_body, _itemsStart, _itemsFim, "special", _result.Especial)
                    End If
                End If

                _ok = _result
                _result = NULL
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearPagamentos", ex)

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                Throw New System.Exception("Erro ao mapear /checkout/payments: " & ex._getMessage())
            End Try

            MapearPagamentos = _ok
        End Function

        Private Sub MapearPagamentosDataArray(pBody As String, pArrayStart As Integer, pResult As RedeAncoraCheckoutPagamentosModel)
            Dim _i As Integer = 0
            Dim _elemStart As Integer = 0
            Dim _elemFim As Integer = 0
            Dim _arrFim As Integer = 0
            Dim _label As String = ""
            Dim _destino As RedeAncoraCheckoutCondicoesPagamentoModel = NULL
            Dim _ch As String = ""

            _arrFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBody, pArrayStart)

            For _i = 0 To 999
                _elemStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(pBody, pArrayStart, _i)

                If _elemStart <= 0 Then
                    Exit For
                End If

                If _arrFim > 0 Then
                    If _elemStart > _arrFim Then
                        Exit For
                    End If
                End If

                _ch = Mid(pBody, _elemStart, 1)
                If _ch = "{" Then
                    Try
                        _elemFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBody, _elemStart)
                        _label = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBody, "label", _elemStart, _elemFim)
                        _destino = me.ResolverGrupoPagamentos(pResult, _label)

                        If Assigned(_destino) Then
                            me.PreencherCondicoesDeFilhoJson(pBody, _elemStart, _elemFim, _destino)
                        End If
                    Catch exItem As Exception
                        RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearPagamentos.item", exItem)
                    End Try
                End If
            Next
        End Sub

        Private Function ResolverGrupoPagamentos(pResult As RedeAncoraCheckoutPagamentosModel, pLabel As String) As RedeAncoraCheckoutCondicoesPagamentoModel
            Dim _labelNorm As String = LCase(pLabel.Trim())

            ResolverGrupoPagamentos = pResult.Livre

            If _labelNorm = "vendor" Or _labelNorm = "fornecedor" Then
                ResolverGrupoPagamentos = pResult.Fornecedor
            ElseIf _labelNorm = "especial" Or _labelNorm = "special" Then
                ResolverGrupoPagamentos = pResult.Especial
            ElseIf _labelNorm = "normal" Or _labelNorm = "free" Or _labelNorm = "livre" Then
                ResolverGrupoPagamentos = pResult.Livre
            End If
        End Function

        Private Sub PreencherCondicoesPagamento(pBody As String, pFromPos As Integer, pToPos As Integer, pKey As String, pDestino As RedeAncoraCheckoutCondicoesPagamentoModel)
            Dim _arrStart As Integer = 0
            Dim _objStart As Integer = 0

            _arrStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlobApos(pBody, pKey, pFromPos)
            If _arrStart > 0 Then
                If pToPos <= 0 Or _arrStart <= pToPos Then
                    me.PreencherCondicoesPagamentoArray(pBody, _arrStart, pDestino)
                    Exit Sub
                End If
            End If

            _objStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlobApos(pBody, pKey, pFromPos)
            If _objStart > 0 Then
                If pToPos <= 0 Or _objStart <= pToPos Then
                    me.PreencherCondicoesPagamentoObjetoMapa(pBody, _objStart, pDestino)
                End If
            End If
        End Sub

        Private Sub PreencherCondicoesPagamentoArray(pBody As String, pArrayStart As Integer, pDestino As RedeAncoraCheckoutCondicoesPagamentoModel)
            Dim _i As Integer = 0
            Dim _elemStart As Integer = 0
            Dim _elemFim As Integer = 0
            Dim _arrFim As Integer = 0
            Dim _ch As String = ""

            _arrFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBody, pArrayStart)

            For _i = 0 To 999
                _elemStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(pBody, pArrayStart, _i)

                If _elemStart <= 0 Then
                    Exit For
                End If

                If _arrFim > 0 Then
                    If _elemStart > _arrFim Then
                        Exit For
                    End If
                End If

                _ch = Mid(pBody, _elemStart, 1)

                If _ch = "{" Then
                    Try
                        _elemFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBody, _elemStart)
                        me.PreencherCondicoesDeFilhoJson(pBody, _elemStart, _elemFim, pDestino)
                    Catch exItem As Exception
                        RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearPagamentos.condicao", exItem)
                    End Try
                ElseIf _ch = "[" Then
                    me.PreencherCondicoesPagamentoArray(pBody, _elemStart, pDestino)
                End If
            Next
        End Sub

        Private Sub PreencherCondicoesPagamentoObjetoMapa(pBody As String, pObjStart As Integer, pDestino As RedeAncoraCheckoutCondicoesPagamentoModel)
            Dim _i As Integer = 0
            Dim _childStart As Integer = 0
            Dim _childFim As Integer = 0
            Dim _objFim As Integer = 0

            _objFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBody, pObjStart)

            For _i = 0 To 999
                _childStart = RedeAncoraJsonHelper.PosicaoObjetoFilhoJsonDeBlob(pBody, pObjStart, _i)

                If _childStart <= 0 Then
                    Exit For
                End If

                If _objFim > 0 Then
                    If _childStart > _objFim Then
                        Exit For
                    End If
                End If

                Try
                    _childFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBody, _childStart)
                    me.PreencherCondicoesDeFilhoJson(pBody, _childStart, _childFim, pDestino)
                Catch exItem As Exception
                    RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearPagamentos.mapa", exItem)
                End Try
            Next
        End Sub

        Private Sub PreencherCondicoesDeFilhoJson(pBody As String, pStart As Integer, pFim As Integer, pDestino As RedeAncoraCheckoutCondicoesPagamentoModel)
            Dim _paymentStart As Integer = 0
            Dim _condicoesArrStart As Integer = 0
            Dim _condicoesObjStart As Integer = 0
            Dim _handle As Integer = 0
            Dim _item As RedeAncoraCheckoutCondicaoPagamentoModel = NULL

            _paymentStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlobApos(pBody, "payment_conditions", pStart)
            If _paymentStart > 0 Then
                If pFim <= 0 Or _paymentStart <= pFim Then
                    me.PreencherCondicoesPagamentoArray(pBody, _paymentStart, pDestino)
                    Exit Sub
                End If
            End If

            _condicoesArrStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlobApos(pBody, "condicoes", pStart)
            If _condicoesArrStart > 0 Then
                If pFim <= 0 Or _condicoesArrStart <= pFim Then
                    me.PreencherCondicoesPagamentoArray(pBody, _condicoesArrStart, pDestino)
                    Exit Sub
                End If
            End If

            _handle = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "condition_handle", pStart, pFim)

            If _handle <= 0 Then
                _handle = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "handle", pStart, pFim)
            End If

            If _handle > 0 Then
                Try
                    _item = New RedeAncoraCheckoutCondicaoPagamentoModel()
                    _item.CodCondicaoPagamento = _handle
                    _item.Descricao = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBody, "label", pStart, pFim)

                    If _item.Descricao = "" Then
                        _item.Descricao = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBody, "title", pStart, pFim)
                    End If

                    _item.Tag = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBody, "tag", pStart, pFim)
                    pDestino.Push(_item)
                    _item = NULL
                Catch exItem As Exception
                    RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearPagamentos.condicao", exItem)

                    If Assigned(_item) Then
                        _item.Free()
                        _item = NULL
                    End If
                End Try

                Exit Sub
            End If

            _condicoesObjStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlobApos(pBody, "condicoes", pStart)
            If _condicoesObjStart > 0 Then
                If pFim <= 0 Or _condicoesObjStart <= pFim Then
                    me.PreencherCondicoesPagamentoObjetoMapa(pBody, _condicoesObjStart, pDestino)
                End If
            End If
        End Sub

        Private Function MontarPayloadHauler(pNome As String, pTipoDocumento As String, pDocumento As String, pTipoVeiculo As String, pPlacaVeiculo As String, pPessoaContato As String, pTelefoneContato As String, pObservacoes As String, pHabilitado As Boolean) As String
            Dim _payload As TJSONObject = NULL

            _payload = New TJSONObject()
            _payload.PutBoolean("enable", pHabilitado)
            _payload.PutString("name", pNome.Trim())
            _payload.PutString("document_type", pTipoDocumento.Trim())
            _payload.PutString("document", pDocumento.Trim())
            _payload.PutString("vehicle_type", pTipoVeiculo.Trim())
            _payload.PutString("vehicle_plate", pPlacaVeiculo.Trim())
            _payload.PutString("contact_person", pPessoaContato.Trim())
            _payload.PutString("contact_phone", pTelefoneContato.Trim())
            _payload.PutString("notes", pObservacoes.Trim())
            MontarPayloadHauler = _payload.ToString()
            _payload.Free()
        End Function

        Private Function LogTextoTruncadoLocal(pTexto As String) As String
            Dim _limite As Integer = 2000

            LogTextoTruncadoLocal = pTexto

            If Len(pTexto) > _limite Then
                LogTextoTruncadoLocal = Left(pTexto, _limite) + "...[truncado]"
            End If
        End Function

        Private Function MapearTransportadores(pResponse As HttpResponse) As RedeAncoraLogisticaTransportadoresModel
            Dim _body As String = ""
            Dim _result As RedeAncoraLogisticaTransportadoresModel = NULL
            Dim _ok As RedeAncoraLogisticaTransportadoresModel = NULL
            Dim _item As RedeAncoraLogisticaTransportadorModel = NULL
            Dim _arrStart As Integer = 0
            Dim _elemStart As Integer = 0
            Dim _elemFim As Integer = 0
            Dim _i As Integer = 0
            Dim _id As Integer = 0

            Try
                _body = pResponse.Body
                _arrStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlob(_body, "data")

                If _arrStart <= 0 Then
                    Throw New System.Exception("Resposta /logistics/haulers sem array data")
                End If

                _result = New RedeAncoraLogisticaTransportadoresModel()

                For _i = 0 To 9999
                    _elemStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(_body, _arrStart, _i)

                    If _elemStart <= 0 Then
                        Exit For
                    End If

                    _elemFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _elemStart)

                    Try
                        _item = New RedeAncoraLogisticaTransportadorModel()
                        _id = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "id", _elemStart, _elemFim)

                        If _id <= 0 Then
                            _id = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "hauler_id", _elemStart, _elemFim)
                        End If

                        _item.CodTransportador = _id
                        _item.Nome = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(_body, "name", _elemStart, _elemFim)

                        If _item.Nome.Trim() = "" Then
                            _item.Nome = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(_body, "nome", _elemStart, _elemFim)
                        End If

                        If _item.CodTransportador <= 0 Then
                            RedeAncoraHttpErroHelper.RegistrarFalha("GET /logistics/haulers item", 200, "id ausente")
                            _item.Free()
                            _item = NULL
                        Else
                            _result.Push(_item)
                            _item = NULL
                        End If
                    Catch exItem As Exception
                        RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearTransportadores.item", exItem)

                        If Assigned(_item) Then
                            _item.Free()
                            _item = NULL
                        End If
                    End Try
                Next

                _ok = _result
                _result = NULL
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearTransportadores", ex)

                If Assigned(_item) Then
                    _item.Free()
                    _item = NULL
                End If

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                Throw New System.Exception("Erro ao mapear /logistics/haulers: " & ex._getMessage())
            End Try

            MapearTransportadores = _ok
        End Function

        Private Function MapearPedidos(pCodUsuario As Integer, pIdCarrinho As String, pResponse As HttpResponse) As RedeAncoraPedidosModel
            Dim _body As String = ""
            Dim _result As RedeAncoraPedidosModel = NULL
            Dim _ok As RedeAncoraPedidosModel = NULL
            Dim _pedido As RedeAncoraPedidoModel = NULL
            Dim _dataStart As Integer = 0
            Dim _dataFim As Integer = 0
            Dim _ordersStart As Integer = 0
            Dim _orderStart As Integer = 0
            Dim _orderFim As Integer = 0
            Dim _itemsStart As Integer = 0
            Dim _itemStart As Integer = 0
            Dim _itemFim As Integer = 0
            Dim _i As Integer = 0
            Dim _j As Integer = 0
            Dim _qty As Integer = 0
            Dim _unitPrice As Double = 0
            Dim _unitTaxes As Double = 0
            Dim _msg As String = ""

            Try
                _body = pResponse.Body
                _dataStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlob(_body, "data")

                If _dataStart <= 0 Then
                    Throw New System.Exception("Resposta /checkout/order sem objeto data")
                End If

                _dataFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _dataStart)

                If RedeAncoraJsonHelper.ExisteChaveJsonDeBlobEntre(_body, "success", _dataStart, _dataFim) Then
                    If Not RedeAncoraJsonHelper.ObterBooleanJsonDeBlobEntre(_body, "success", _dataStart, _dataFim) Then
                        _msg = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(_body, "message", _dataStart, _dataFim)
                        RedeAncoraHttpErroHelper.RegistrarFalha("POST /checkout/order", 200, _body)
                        Throw New System.Exception("POST /checkout/order data.success=false: " & _msg)
                    End If
                End If

                _ordersStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlobApos(_body, "orders", _dataStart)

                If _ordersStart <= 0 Then
                    Throw New System.Exception("Resposta /checkout/order sem array orders")
                End If

                If _dataFim > 0 Then
                    If _ordersStart > _dataFim Then
                        Throw New System.Exception("Resposta /checkout/order sem array orders")
                    End If
                End If

                _result = New RedeAncoraPedidosModel()

                For _i = 0 To 999
                    _orderStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(_body, _ordersStart, _i)

                    If _orderStart <= 0 Then
                        Exit For
                    End If

                    If _dataFim > 0 Then
                        If _orderStart > _dataFim Then
                            Exit For
                        End If
                    End If

                    Try
                        _orderFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _orderStart)
                        _pedido = New RedeAncoraPedidoModel()
                        _pedido.CodUsuario = pCodUsuario
                        _pedido.IdPedidoApi = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "id", _orderStart, _orderFim)
                        _pedido.IdCarrinho = pIdCarrinho
                        _pedido.DataPedido = DateTime()
                        _pedido.ValorTotal = 0

                        If _pedido.IdPedidoApi <= 0 Then
                            Throw New System.Exception("pedido sem id")
                        End If

                        _itemsStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlobApos(_body, "items", _orderStart)
                        If _itemsStart > 0 Then
                            If _orderFim <= 0 Or _itemsStart <= _orderFim Then
                                For _j = 0 To 999
                                    _itemStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(_body, _itemsStart, _j)

                                    If _itemStart <= 0 Then
                                        Exit For
                                    End If

                                    If _orderFim > 0 Then
                                        If _itemStart > _orderFim Then
                                            Exit For
                                        End If
                                    End If

                                    Try
                                        _itemFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _itemStart)
                                        _qty = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "qty", _itemStart, _itemFim)
                                        _unitPrice = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(_body, "unit_price", _itemStart, _itemFim)
                                        _unitTaxes = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(_body, "unit_taxes", _itemStart, _itemFim)
                                        _pedido.ValorTotal = _pedido.ValorTotal + ((_unitPrice + _unitTaxes) * _qty)
                                    Catch exItem As Exception
                                        RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearPedidos.item", exItem)
                                    End Try
                                Next
                            End If
                        End If

                        _result.Push(_pedido)
                        _pedido = NULL
                    Catch exPedido As Exception
                        RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearPedidos.order", exPedido)

                        If Assigned(_pedido) Then
                            _pedido.Free()
                            _pedido = NULL
                        End If
                    End Try
                Next

                _ok = _result
                _result = NULL
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCheckoutService.MapearPedidos", ex)

                If Assigned(_pedido) Then
                    _pedido.Free()
                    _pedido = NULL
                End If

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                Throw New System.Exception("Erro ao mapear pedidos Rede Ancora: " + ex._getMessage())
            End Try

            MapearPedidos = _ok
        End Function

        Private Function MontarPayloadItensOpcional(pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            MontarPayloadItensOpcional = me.AdicionarItensAoPayloadJson("{}", pItensIds)
        End Function

        Private Function MontarPayloadPagamentos(pCodCentroDistribuicao As Integer, pCodModalidade As Integer, pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            Dim _payloadJson As String = "{""seller_id"":" + Parser.IntegerToString(pCodCentroDistribuicao)
            _payloadJson = _payloadJson + ",""modality"":" + Parser.IntegerToString(pCodModalidade) + "}"

            MontarPayloadPagamentos = me.AdicionarItensAoPayloadJson(_payloadJson, pItensIds)
        End Function

        Private Function MontarPayloadAplicarCondicaoPagamento(pCodCondicaoPagamento As Integer, pCodEstado As Integer, pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            Dim _payloadJson As String = "{""condition_handle"":" + Parser.IntegerToString(pCodCondicaoPagamento)
            _payloadJson = _payloadJson + ",""estado"":" + Parser.IntegerToString(pCodEstado) + "}"

            MontarPayloadAplicarCondicaoPagamento = me.AdicionarItensAoPayloadJson(_payloadJson, pItensIds)
        End Function

        Private Function MontarPayloadEntregasLogistica(pIdCarrinho As String, pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            Dim _payloadJson As String = "{""cart_id"":""" + pIdCarrinho + """}"

            MontarPayloadEntregasLogistica = me.AdicionarItensAoPayloadJson(_payloadJson, pItensIds)
        End Function

        Private Function MontarPayloadDetalheCondicaoPagamento(pCodCentroDistribuicao As Integer, pCodModalidade As Integer, pCodCondicaoPagamento As Integer) As String
            Dim _payloadJson As String = "{""seller_id"":" + Parser.IntegerToString(pCodCentroDistribuicao)
            _payloadJson = _payloadJson + ",""modality"":" + Parser.IntegerToString(pCodModalidade)
            _payloadJson = _payloadJson + ",""condition"":" + Parser.IntegerToString(pCodCondicaoPagamento) + "}"
            MontarPayloadDetalheCondicaoPagamento = _payloadJson
        End Function

        Private Function MontarPayloadConfirmarPedido(pEntregas As RedeAncoraCheckoutEntregasSolicitacaoModel, pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            Dim _payloadJson As String = "{}"

            _payloadJson = me.AdicionarCampoJsonBruto(_payloadJson, "carriers", me.MontarArrayEntregasJson(pEntregas))
            MontarPayloadConfirmarPedido = me.AdicionarItensAoPayloadJson(_payloadJson, pItensIds)
        End Function

        Private Function AdicionarItensAoPayloadJson(pPayloadJson As String, pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            AdicionarItensAoPayloadJson = pPayloadJson

            If Assigned(pItensIds) Then
                If pItensIds.Length > 0 Then
                    pItensIds.ValidarTodos()
                    AdicionarItensAoPayloadJson = me.AdicionarCampoJsonBruto(pPayloadJson, "items", me.MontarArrayItensIdsJson(pItensIds))
                End If
            End If
        End Function

        Private Function AdicionarCampoJsonBruto(pPayloadJson As String, pCampo As String, pValorJson As String) As String
            Dim _quote As String = CStr(Chr(34))
            Dim _payload As String = pPayloadJson.Trim()
            Dim _result As String = ""

            If _payload = "" Then
                _payload = "{}"
            End If

            If _payload = "{}" Then
                AdicionarCampoJsonBruto = "{" + _quote + pCampo + _quote + ":" + pValorJson + "}"
                Exit Function
            End If

            _result = Left(_payload, Len(_payload) - 1)
            _result = _result + "," + _quote + pCampo + _quote + ":" + pValorJson + "}"
            AdicionarCampoJsonBruto = _result
        End Function

        Private Function MontarErroHttp(pOperacao As String, pResponse As HttpResponse) As String
            RedeAncoraHttpErroHelper.RegistrarFalha(pOperacao, pResponse.StatusCode, pResponse.Body)
            MontarErroHttp = RedeAncoraHttpErroHelper.MontarMensagem(pOperacao, pResponse.StatusCode, pResponse.Body)
        End Function

        Private Function MontarArrayItensIdsJson(pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            Dim _itemsJson As String = ""
            Dim _i As Integer

            _itemsJson = "["
            For _i = 0 To pItensIds.Length - 1
                If _i > 0 Then
                    _itemsJson = _itemsJson + ","
                End If

                _itemsJson = _itemsJson + Parser.IntegerToString(pItensIds.Take(_i))
            Next

            _itemsJson = _itemsJson + "]"
            MontarArrayItensIdsJson = _itemsJson
        End Function

        Private Function MontarArrayEntregasJson(pEntregas As RedeAncoraCheckoutEntregasSolicitacaoModel) As String
            Dim _itemsJson As String = ""
            Dim _i As Integer

            _itemsJson = "["
            For _i = 0 To pEntregas.Length - 1
                Dim _entrega As RedeAncoraCheckoutEntregaSolicitacaoModel = pEntregas.Take(_i)
                Dim _itemJson As String = ""

                If _i > 0 Then
                    _itemsJson = _itemsJson + ","
                End If

                _itemJson = "{""seller_id"":" + Parser.IntegerToString(_entrega.CodCentroDistribuicao) + ",""carrier_id"":" + Parser.IntegerToString(_entrega.CodEntrega)

                If _entrega.CodTransportador > 0 Then
                    _itemJson = _itemJson + ",""hauler_id"":" + Parser.IntegerToString(_entrega.CodTransportador)
                Else
                    _itemJson = _itemJson + ",""hauler_id"":null"
                End If

                _itemJson = _itemJson + "}"
                _itemsJson = _itemsJson + _itemJson
            Next

            _itemsJson = _itemsJson + "]"
            MontarArrayEntregasJson = _itemsJson
        End Function

        Private Function CarrinhoLocalJaConvertido(pIdCarrinho As String) As Boolean
            Dim _carrinho As RedeAncoraCarrinhoModel = NULL
            Dim _convertido As Boolean = False

            If pIdCarrinho.Trim() = "" Then
                CarrinhoLocalJaConvertido = False
                Exit Function
            End If

            Try
                _carrinho = New RedeAncoraCarrinhoModel()
                If me._carrinhoRepository.TryObterPorIdCarrinho(pIdCarrinho, _carrinho) Then
                    If _carrinho.Convertido = "S" Then
                        _convertido = True
                    End If
                End If

                _carrinho.Free()
                _carrinho = NULL
            Catch ex As Exception
                If Assigned(_carrinho) Then
                    _carrinho.Free()
                    _carrinho = NULL
                End If

                Throw ex
            End Try

            CarrinhoLocalJaConvertido = _convertido
        End Function

        Private Sub MarcarCarrinhoConvertido(pIdCarrinho As String)
            Dim _carrinho As RedeAncoraCarrinhoModel = NULL

            Try
                If pIdCarrinho.Trim() <> "" Then
                    _carrinho = New RedeAncoraCarrinhoModel()
                    If me._carrinhoRepository.TryObterPorIdCarrinho(pIdCarrinho, _carrinho) Then
                        _carrinho.Convertido = "S"
                        _carrinho.DataAtualizacao = DateTime()
                        me._carrinhoRepository.Salvar(_carrinho)
                    End If

                    If Assigned(_carrinho) Then
                        _carrinho.Free()
                        _carrinho = NULL
                    End If
                End If
            Catch ex As Exception
                If Assigned(_carrinho) Then
                    _carrinho.Free()
                End If

                Throw ex
            End Try
        End Sub

        Private Sub LimparIdCarrinhoEmpresa(pCodUsuario As Integer)
            Dim _empresa As RedeAncoraEmpresaModel = NULL

            Try
                _empresa = me._empresaRepository.ObterPorCodUsuario(pCodUsuario)
                _empresa.IdCarrinhoAtual = ""
                me._empresaRepository.Salvar(_empresa)
                _empresa.Free()
            Catch ex As Exception
                If Assigned(_empresa) Then
                    _empresa.Free()
                End If

                Throw ex
            End Try
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._authService) Then
                    me._authService.Free()
                    me._authService = NULL
                End If

                If Assigned(me._empresaService) Then
                    me._empresaService.Free()
                    me._empresaService = NULL
                End If

                If Assigned(me._pedidoRepository) Then
                    me._pedidoRepository.Free()
                    me._pedidoRepository = NULL
                End If

                If Assigned(me._carrinhoRepository) Then
                    me._carrinhoRepository.Free()
                    me._carrinhoRepository = NULL
                End If

                If Assigned(me._empresaRepository) Then
                    me._empresaRepository.Free()
                    me._empresaRepository = NULL
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
