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

                RevisarCarrinho = me.MapearRevisao(_response)
                _response.Free()
                _api.Free()
            Catch ex As Exception
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
                mod_logger.Printe("Debug: POST /checkout/payments payload=" + me.LogTextoTruncadoLocal(_payload))

                _api = New RedeAncoraApiClient(pInput.CodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pInput.IdCarrinho + "/payments"), _payload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("POST /checkout/payments", _response))
                End If

                mod_logger.Printe("Debug: POST /checkout/payments HTTP " + Parser.IntegerToString(_response.StatusCode))
                mod_logger.Printe("Debug: POST /checkout/payments body=" + me.LogTextoTruncadoLocal(_response.Body))

                _output.Pagamentos = me.MapearPagamentos(_response)
                ConsultarPagamentos = _output
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

                _output.Resultado = _response.Body
                AplicarCondicaoPagamento = _output
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

                ListarTransportadores = me.MapearTransportadores(_response)
                _response.Free()
                _api.Free()
            Catch ex As Exception
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
            Dim _json As TJSONObject = NULL
            Dim _data As TJSONObject = NULL

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

                _json = _response.BodyAsJsonObject()

                If Assigned(_json) Then
                    _data = RedeAncoraJsonHelper.ObterDataObjeto(_json)

                    If Assigned(_data) Then
                        ExcluirTransportador = RedeAncoraJsonHelper.ObterBooleanJson(_data, "data")
                        _data.Free()
                    Else
                        ExcluirTransportador = RedeAncoraJsonHelper.ObterBooleanJson(_json, "data")
                    End If

                    _json.Free()
                Else
                    ExcluirTransportador = True
                End If

                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_data) Then
                    _data.Free()
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
            Dim _json As TJSONObject = NULL
            Dim _data As TJSONObject = NULL
            Dim _result As New RedeAncoraCheckoutRevisaoModel()
            Dim _totals As TJSONObject = NULL
            Dim _carriers As TJSONArray = NULL
            Dim _i As Integer

            _json = pResponse.BodyAsJsonObject()
            _data = RedeAncoraJsonHelper.ObterDataObjeto(_json)

            If Not Assigned(_data) Then
                _json.Free()
                Throw New System.Exception("Resposta /checkout/review sem objeto data")
            End If

            _result.QtdItens = RedeAncoraJsonHelper.ObterInteiroJson(_data, "items_count")
            _result.QtdItensTotal = RedeAncoraJsonHelper.ObterInteiroJson(_data, "items_qty")

            _totals = RedeAncoraJsonHelper.ObterObjetoJson(_data, "totals")
            If Assigned(_totals) Then
                _result.Subtotal = RedeAncoraJsonHelper.ObterDecimalJson(_totals, "subtotal")
                _result.Impostos = RedeAncoraJsonHelper.ObterDecimalJson(_totals, "taxes")
                _result.Total = RedeAncoraJsonHelper.ObterDecimalJson(_totals, "total")
                _totals.Free()
            End If

            _carriers = RedeAncoraJsonHelper.ObterArrayJson(_data, "carriers")
            If Assigned(_carriers) Then
                For _i = 0 To _carriers.Length() - 1
                    Dim _sellerJson As TJSONObject = _carriers.GetJSONObject(_i)
                    Dim _seller As New RedeAncoraCheckoutEntregaSellerModel()
                    Dim _carrierOptions As TJSONArray = NULL
                    Dim _j As Integer

                    _seller.CodCentroDistribuicao = RedeAncoraJsonHelper.ObterInteiroJson(_sellerJson, "seller_id")
                    _seller.NomeCentroDistribuicao = RedeAncoraJsonHelper.ObterTextoJson(_sellerJson, "seller_name")
                    _carrierOptions = RedeAncoraJsonHelper.ObterArrayJson(_sellerJson, "carriers")

                    If Assigned(_carrierOptions) Then
                        For _j = 0 To _carrierOptions.Length() - 1
                            Dim _carrierJson As TJSONObject = _carrierOptions.GetJSONObject(_j)
                            Dim _opcao As New RedeAncoraCheckoutEntregaOpcaoModel()

                            _opcao.CodEntrega = RedeAncoraJsonHelper.ObterInteiroJson(_carrierJson, "carrier_id")
                            _opcao.Nome = RedeAncoraJsonHelper.ObterTextoJson(_carrierJson, "name")
                            _opcao.ExigeTransportador = RedeAncoraJsonHelper.SimNao(RedeAncoraJsonHelper.ObterBooleanJson(_carrierJson, "haulers_required"))
                            _seller.Opcoes.Push(_opcao)
                            _carrierJson.Free()
                        Next

                        _carrierOptions.Free()
                    End If

                    _result.EntregasSellers.Push(_seller)
                    _sellerJson.Free()
                Next

                _carriers.Free()
            End If

            _data.Free()
            _json.Free()
            MapearRevisao = _result
        End Function

        Private Function MapearPagamentos(pResponse As HttpResponse) As RedeAncoraCheckoutPagamentosModel
            Dim _json As TJSONObject = NULL
            Dim _dataObj As TJSONObject = NULL
            Dim _dataArray As TJSONArray = NULL
            Dim _result As New RedeAncoraCheckoutPagamentosModel()

            _json = pResponse.BodyAsJsonObject()

            If Not Assigned(_json) Then
                Throw New System.Exception("Resposta /checkout/payments sem JSON valido")
            End If

            _dataObj = RedeAncoraJsonHelper.ObterDataObjeto(_json)

            If Assigned(_dataObj) Then
                me.PreencherCondicoesPagamento(_dataObj, "vendor", _result.Fornecedor)
                me.PreencherCondicoesPagamento(_dataObj, "free", _result.Livre)
                me.PreencherCondicoesPagamento(_dataObj, "special", _result.Especial)
                _dataObj.Free()
            Else
                _dataArray = RedeAncoraJsonHelper.ObterDataArray(_json)

                If Not Assigned(_dataArray) Then
                    _json.Free()
                    Throw New System.Exception("Resposta /checkout/payments sem data objeto ou array")
                End If

                me.MapearPagamentosDataArray(_dataArray.ToString(), _result)
                _dataArray.Free()
            End If

            _json.Free()
            MapearPagamentos = _result
        End Function

        Private Sub MapearPagamentosDataArray(pArrayBlob As String, pResult As RedeAncoraCheckoutPagamentosModel)
            Dim _i As Integer = 0
            Dim _elem As String = ""
            Dim _groupJson As TJSONObject = NULL
            Dim _label As String = ""
            Dim _destino As RedeAncoraCheckoutCondicoesPagamentoModel = NULL

            For _i = 0 To 999
                _elem = RedeAncoraJsonHelper.ExtrairElementoArrayJson(pArrayBlob, _i)

                If _elem = "" Then
                    Exit For
                End If

                If Mid(_elem.Trim(), 1, 1) = "{" Then
                    _groupJson = New TJSONObject(_elem)
                    _label = RedeAncoraJsonHelper.ObterTextoJson(_groupJson, "label")
                    _destino = me.ResolverGrupoPagamentos(pResult, _label)

                    If Assigned(_destino) Then
                        me.PreencherCondicoesDeFilhoJson(_groupJson, _destino)
                    End If

                    _groupJson.Free()
                    _groupJson = NULL
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

        Private Sub PreencherCondicoesPagamento(pData As TJSONObject, pKey As String, pDestino As RedeAncoraCheckoutCondicoesPagamentoModel)
            Dim _items As TJSONArray = RedeAncoraJsonHelper.ObterArrayJson(pData, pKey)
            Dim _objeto As TJSONObject = NULL

            If Assigned(_items) Then
                me.PreencherCondicoesPagamentoArray(_items.ToString(), pDestino)
                _items.Free()
                Exit Sub
            End If

            _objeto = RedeAncoraJsonHelper.ObterObjetoJson(pData, pKey)

            If Assigned(_objeto) Then
                me.PreencherCondicoesPagamentoObjetoMapa(_objeto, pDestino)
                _objeto.Free()
            End If
        End Sub

        Private Sub PreencherCondicoesPagamentoArray(pArrayBlob As String, pDestino As RedeAncoraCheckoutCondicoesPagamentoModel)
            Dim _i As Integer = 0
            Dim _elem As String = ""
            Dim _tipo As String = ""
            Dim _itemJson As TJSONObject = NULL

            For _i = 0 To 999
                _elem = RedeAncoraJsonHelper.ExtrairElementoArrayJson(pArrayBlob, _i)

                If _elem = "" Then
                    Exit For
                End If

                _tipo = Mid(_elem.Trim(), 1, 1)

                If _tipo = "{" Then
                    _itemJson = New TJSONObject(_elem)
                    me.PreencherCondicoesDeFilhoJson(_itemJson, pDestino)
                    _itemJson.Free()
                    _itemJson = NULL
                ElseIf _tipo = "[" Then
                    me.PreencherCondicoesPagamentoArray(_elem, pDestino)
                End If
            Next
        End Sub

        Private Sub PreencherCondicoesPagamentoObjetoMapa(pObj As TJSONObject, pDestino As RedeAncoraCheckoutCondicoesPagamentoModel)
            Dim _blob As String = pObj.ToString()
            Dim _i As Integer = 0
            Dim _childBlob As String = ""
            Dim _child As TJSONObject = NULL

            For _i = 0 To 999
                _childBlob = RedeAncoraJsonHelper.ExtrairObjetoFilhoJson(_blob, _i)

                If _childBlob = "" Then
                    Exit For
                End If

                _child = New TJSONObject(_childBlob)
                me.PreencherCondicoesDeFilhoJson(_child, pDestino)
                _child.Free()
                _child = NULL
            Next
        End Sub

        Private Sub PreencherCondicoesDeFilhoJson(pItemJson As TJSONObject, pDestino As RedeAncoraCheckoutCondicoesPagamentoModel)
            Dim _paymentConditions As TJSONArray = NULL
            Dim _condicoesArray As TJSONArray = NULL
            Dim _condicoes As TJSONObject = NULL
            Dim _handle As Integer = 0
            Dim _item As RedeAncoraCheckoutCondicaoPagamentoModel = NULL

            _paymentConditions = RedeAncoraJsonHelper.ObterArrayJson(pItemJson, "payment_conditions")

            If Assigned(_paymentConditions) Then
                me.PreencherCondicoesPagamentoArray(_paymentConditions.ToString(), pDestino)
                _paymentConditions.Free()
                Exit Sub
            End If

            _condicoesArray = RedeAncoraJsonHelper.ObterArrayJson(pItemJson, "condicoes")

            If Assigned(_condicoesArray) Then
                me.PreencherCondicoesPagamentoArray(_condicoesArray.ToString(), pDestino)
                _condicoesArray.Free()
                Exit Sub
            End If

            _handle = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pItemJson, "condition_handle")

            If _handle <= 0 Then
                _handle = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pItemJson, "handle")
            End If

            If _handle > 0 Then
                _item = New RedeAncoraCheckoutCondicaoPagamentoModel()
                _item.CodCondicaoPagamento = _handle
                _item.Descricao = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "label")

                If _item.Descricao = "" Then
                    _item.Descricao = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "title")
                End If

                _item.Tag = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "tag")
                pDestino.Push(_item)
                Exit Sub
            End If

            _condicoes = RedeAncoraJsonHelper.ObterObjetoJson(pItemJson, "condicoes")

            If Assigned(_condicoes) Then
                me.PreencherCondicoesPagamentoObjetoMapa(_condicoes, pDestino)
                _condicoes.Free()
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
            Dim _json As TJSONObject = NULL
            Dim _data As TJSONArray = NULL
            Dim _result As New RedeAncoraLogisticaTransportadoresModel()
            Dim _i As Integer

            _json = pResponse.BodyAsJsonObject()
            _data = RedeAncoraJsonHelper.ObterDataArray(_json)

            If Not Assigned(_data) Then
                _json.Free()
                Throw New System.Exception("Resposta /logistics/haulers sem array data")
            End If

            For _i = 0 To _data.Length() - 1
                Dim _itemJson As TJSONObject = _data.GetJSONObject(_i)
                Dim _item As New RedeAncoraLogisticaTransportadorModel()

                _item.CodTransportador = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(_itemJson, "id")
                If _item.CodTransportador <= 0 Then
                    _item.CodTransportador = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(_itemJson, "hauler_id")
                End If

                _item.Nome = RedeAncoraJsonHelper.ObterTextoJson(_itemJson, "name")
                If _item.Nome.Trim() = "" Then
                    _item.Nome = RedeAncoraJsonHelper.ObterTextoJson(_itemJson, "nome")
                End If

                _result.Push(_item)
                _itemJson.Free()
            Next

            _data.Free()
            _json.Free()
            MapearTransportadores = _result
        End Function

        Private Function MapearPedidos(pCodUsuario As Integer, pIdCarrinho As String, pResponse As HttpResponse) As RedeAncoraPedidosModel
            Dim _json As TJSONObject = NULL
            Dim _data As TJSONObject = NULL
            Dim _orders As TJSONArray = NULL
            Dim _result As RedeAncoraPedidosModel = NULL
            Dim _orderJson As TJSONObject = NULL
            Dim _items As TJSONArray = NULL
            Dim _itemJson As TJSONObject = NULL
            Dim _pedido As RedeAncoraPedidoModel = NULL
            Dim _i As Integer
            Dim _j As Integer
            Dim _qty As Integer = 0
            Dim _unitPrice As Double = 0
            Dim _unitTaxes As Double = 0

            Try
                _result = New RedeAncoraPedidosModel()
                _json = pResponse.BodyAsJsonObject()
                _data = RedeAncoraJsonHelper.ObterDataObjeto(_json)

                If Not Assigned(_data) Then
                    Throw New System.Exception("Resposta /checkout/order sem objeto data")
                End If

                _orders = RedeAncoraJsonHelper.ObterArrayJson(_data, "orders")

                If Not Assigned(_orders) Then
                    Throw New System.Exception("Resposta /checkout/order sem array orders")
                End If

                For _i = 0 To _orders.Length() - 1
                    _pedido = New RedeAncoraPedidoModel()

                    _orderJson = _orders.GetJSONObject(_i)
                    _pedido.CodUsuario = pCodUsuario
                    _pedido.IdPedidoApi = RedeAncoraJsonHelper.ObterInteiroJson(_orderJson, "id")
                    _pedido.IdCarrinho = pIdCarrinho
                    _pedido.DataPedido = DateTime()
                    _pedido.ValorTotal = 0

                    _items = RedeAncoraJsonHelper.ObterArrayJson(_orderJson, "items")
                    If Assigned(_items) Then
                        For _j = 0 To _items.Length() - 1
                            _itemJson = _items.GetJSONObject(_j)
                            _qty = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "qty")
                            _unitPrice = RedeAncoraJsonHelper.ObterDecimalJson(_itemJson, "unit_price")
                            _unitTaxes = RedeAncoraJsonHelper.ObterDecimalJson(_itemJson, "unit_taxes")

                            _pedido.ValorTotal = _pedido.ValorTotal + ((_unitPrice + _unitTaxes) * _qty)
                            _itemJson.Free()
                            _itemJson = NULL
                        Next

                        _items.Free()
                        _items = NULL
                    End If

                    _result.Push(_pedido)
                    _pedido = NULL
                    _orderJson.Free()
                    _orderJson = NULL
                Next

                _orders.Free()
                _orders = NULL
                _data.Free()
                _data = NULL
                _json.Free()
                _json = NULL
            Catch ex As Exception
                If Assigned(_itemJson) Then
                    _itemJson.Free()
                    _itemJson = NULL
                End If

                If Assigned(_items) Then
                    _items.Free()
                    _items = NULL
                End If

                If Assigned(_orderJson) Then
                    _orderJson.Free()
                    _orderJson = NULL
                End If

                If Assigned(_pedido) Then
                    _pedido.Free()
                    _pedido = NULL
                End If

                If Assigned(_orders) Then
                    _orders.Free()
                    _orders = NULL
                End If

                If Assigned(_data) Then
                    _data.Free()
                    _data = NULL
                End If

                If Assigned(_json) Then
                    _json.Free()
                    _json = NULL
                End If

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                Throw New System.Exception("Erro ao mapear pedidos Rede Ancora: " + ex._getMessage())
            End Try

            MapearPedidos = _result
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
            Dim _msg As String = ""

            _msg = pOperacao + " Rede Ancora falhou. HTTP " + Parser.IntegerToString(pResponse.StatusCode)

            If pResponse.Body <> "" Then
                _msg = _msg + ": " + pResponse.Body
            End If

            MontarErroHttp = _msg
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
