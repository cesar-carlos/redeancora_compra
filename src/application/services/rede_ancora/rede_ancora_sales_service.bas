Imports mod_tobject
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_url_helper
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_empresa_service
Imports rede_ancora_json_helper
Imports rede_ancora_input_listar_pedidos_api
Imports rede_ancora_input_listar_itens_pedido_api
Imports rede_ancora_input_listar_pendencias_api
Imports rede_ancora_input_listar_pendencias_por_pedido_api
Imports http_response
Imports rede_ancora_http_erro_helper

Namespace rede_ancora_sales_service
    Class RedeAncoraSalesService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _empresaService As RedeAncoraEmpresaService

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._empresaService = New RedeAncoraEmpresaService()
        End Sub

        Function ListarPedidosApi(pInput As RedeAncoraInputListarPedidosApi) As String
            Dim _url As String = ""

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input ListarPedidosApi nao informado")
            End If

            me._empresaService.ValidarPodeOperar(pInput.CodUsuario)

            _url = RedeAncoraApiConfig.IntegrationUrl("/sales/orders")
            _url = me.AnexarQueryInteiroSePositivo(_url, "page", pInput.Pagina)
            _url = me.AnexarQueryInteiroSePositivo(_url, "page_size", pInput.TamanhoPagina)
            _url = me.AnexarQueryTextoSeInformado(_url, "sort_by", pInput.OrdenarPor)
            _url = me.AnexarQueryTextoSeInformado(_url, "sort_dir", pInput.DirecaoOrdenacao)
            _url = me.AnexarQueryInteiroSePositivo(_url, "modality", pInput.CodModalidade)
            _url = me.AnexarQueryInteiroSePositivo(_url, "cond_pag", pInput.CodCondicaoPagamento)
            _url = me.AnexarQueryTextoSeInformado(_url, "created_at", pInput.DataCriacao)
            _url = me.AnexarQueryInteiroSePositivo(_url, "erp_handle", pInput.CodErpHandle)
            _url = me.AnexarQueryInteiroSePositivo(_url, "erp_seller_handle", pInput.CodErpSellerHandle)
            _url = me.AnexarQueryTextoSeInformado(_url, "state", pInput.Estado)
            _url = me.AnexarQueryInteiroSePositivo(_url, "id", pInput.IdPedidoApi)
            _url = me.AnexarQueryTextoSeInformado(_url, "product", pInput.Produto)
            _url = me.AnexarQueryTextoSeInformado(_url, "brand_name", pInput.NomeMarca)
            _url = me.AnexarQueryTextoSeInformado(_url, "product_code", pInput.CodigoProduto)

            ListarPedidosApi = me.ExecutarGetPassThrough(pInput.CodUsuario, _url, "GET /sales/orders")
        End Function

        Function ConsultarPedidoApi(pCodUsuario As Integer, pIdPedidoApi As Integer) As String
            If pIdPedidoApi <= 0 Then
                Throw New System.Exception("IdPedidoApi invalido para consulta de pedido")
            End If

            me._empresaService.ValidarPodeOperar(pCodUsuario)

            ConsultarPedidoApi = me.ExecutarGetPassThrough(pCodUsuario, RedeAncoraApiConfig.IntegrationUrl("/sales/orders/" + Parser.IntegerToString(pIdPedidoApi)), "GET /sales/orders/{orderId}")
        End Function

        Function ListarItensPedidoApi(pInput As RedeAncoraInputListarItensPedidoApi) As String
            Dim _url As String = ""

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input ListarItensPedidoApi nao informado")
            End If

            If pInput.IdPedidoApi <= 0 Then
                Throw New System.Exception("IdPedidoApi invalido para listagem de itens")
            End If

            me._empresaService.ValidarPodeOperar(pInput.CodUsuario)

            _url = RedeAncoraApiConfig.IntegrationUrl("/sales/orders/" + Parser.IntegerToString(pInput.IdPedidoApi) + "/items")
            _url = me.AnexarQueryTextoSeInformado(_url, "sort_by", pInput.OrdenarPor)
            _url = me.AnexarQueryTextoSeInformado(_url, "sort_dir", pInput.DirecaoOrdenacao)
            _url = me.AnexarQueryTextoSeInformado(_url, "query", pInput.Query)
            _url = me.AnexarQueryTextoSeInformado(_url, "brand", pInput.Marca)
            _url = me.AnexarQueryTextoSeInformado(_url, "code", pInput.Codigo)
            _url = me.AnexarQueryInteiroSePositivo(_url, "cna", pInput.Cna)
            _url = me.AnexarQueryTextoSeInformado(_url, "name", pInput.Nome)
            _url = me.AnexarQueryTextoSeInformado(_url, "state", pInput.Estado)
            _url = me.AnexarQueryInteiroSePositivo(_url, "id", pInput.IdItemApi)

            ListarItensPedidoApi = me.ExecutarGetPassThrough(pInput.CodUsuario, _url, "GET /sales/orders/{orderId}/items")
        End Function

        Function ConsultarItemPedidoApi(pCodUsuario As Integer, pIdPedidoApi As Integer, pIdItemApi As Integer) As String
            If pIdPedidoApi <= 0 Then
                Throw New System.Exception("IdPedidoApi invalido para consulta de item")
            End If

            If pIdItemApi <= 0 Then
                Throw New System.Exception("IdItemApi invalido para consulta de item")
            End If

            me._empresaService.ValidarPodeOperar(pCodUsuario)

            ConsultarItemPedidoApi = me.ExecutarGetPassThrough(pCodUsuario, RedeAncoraApiConfig.IntegrationUrl("/sales/orders/" + Parser.IntegerToString(pIdPedidoApi) + "/items/" + Parser.IntegerToString(pIdItemApi)), "GET /sales/orders/{orderId}/items/{itemId}")
        End Function

        Function CancelarPedidoApi(pCodUsuario As Integer, pIdPedidoApi As Integer) As Boolean
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _body As String = ""
            Dim _raw As String = ""

            Try
                If pIdPedidoApi <= 0 Then
                    Throw New System.Exception("IdPedidoApi invalido para cancelamento")
                End If

                me._empresaService.ValidarPodeOperar(pCodUsuario)

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/sales/orders/" + Parser.IntegerToString(pIdPedidoApi) + "/cancel"))

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("GET /sales/orders/{orderId}/cancel", _response))
                End If

                _body = _response.Body
                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET /sales/orders/{orderId}/cancel", _response.StatusCode, _body)

                If Not RedeAncoraJsonHelper.ExisteChaveJsonDeBlob(_body, "result") Then
                    RedeAncoraHttpErroHelper.RegistrarFalha("GET /sales/orders/{orderId}/cancel", _response.StatusCode, _body)
                    Throw New System.Exception("GET /sales/orders/{orderId}/cancel sem campo result")
                End If

                _raw = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(_body, "result").Trim()
                If _raw.ToLower() = "null" Then
                    RedeAncoraHttpErroHelper.RegistrarFalha("GET /sales/orders/{orderId}/cancel", _response.StatusCode, _body)
                    Throw New System.Exception("GET /sales/orders/{orderId}/cancel result=null")
                End If

                CancelarPedidoApi = RedeAncoraJsonHelper.ObterBooleanJsonDeBlob(_body, "result")
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraSalesService.CancelarPedidoApi", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao cancelar pedido Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ListarPendenciasApi(pInput As RedeAncoraInputListarPendenciasApi) As String
            Dim _url As String = ""

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input ListarPendenciasApi nao informado")
            End If

            me._empresaService.ValidarPodeOperar(pInput.CodUsuario)

            _url = RedeAncoraApiConfig.IntegrationUrl("/sales/pendencies")
            _url = me.AnexarQueryInteiroSePositivo(_url, "page", pInput.Pagina)
            _url = me.AnexarQueryInteiroSePositivo(_url, "page_size", pInput.TamanhoPagina)
            _url = me.AnexarQueryTextoSeInformado(_url, "sort_by", pInput.OrdenarPor)
            _url = me.AnexarQueryTextoSeInformado(_url, "sort_dir", pInput.DirecaoOrdenacao)
            _url = me.AnexarQueryInteiroSePositivo(_url, "modality", pInput.CodModalidade)
            _url = me.AnexarQueryInteiroSePositivo(_url, "cond_pag", pInput.CodCondicaoPagamento)
            _url = me.AnexarQueryTextoSeInformado(_url, "created_at", pInput.DataCriacao)
            _url = me.AnexarQueryInteiroSePositivo(_url, "erp_handle", pInput.CodErpHandle)
            _url = me.AnexarQueryInteiroSePositivo(_url, "erp_seller_handle", pInput.CodErpSellerHandle)
            _url = me.AnexarQueryTextoSeInformado(_url, "product", pInput.Produto)
            _url = me.AnexarQueryInteiroSePositivo(_url, "id", pInput.IdPedidoApi)
            _url = me.AnexarQueryTextoSeInformado(_url, "product_code", pInput.CodigoProduto)
            _url = me.AnexarQueryTextoSeInformado(_url, "brand_name", pInput.NomeMarca)
            _url = me.AnexarQueryInteiroSePositivo(_url, "cna", pInput.Cna)

            ListarPendenciasApi = me.ExecutarGetPassThrough(pInput.CodUsuario, _url, "GET /sales/pendencies")
        End Function

        Function ListarPendenciasPorPedidoApi(pInput As RedeAncoraInputListarPendenciasPorPedidoApi) As String
            Dim _url As String = ""

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input ListarPendenciasPorPedidoApi nao informado")
            End If

            me._empresaService.ValidarPodeOperar(pInput.CodUsuario)

            _url = RedeAncoraApiConfig.IntegrationUrl("/sales/pendencies/by-orders")
            _url = me.AnexarQueryInteiroSePositivo(_url, "page", pInput.Pagina)
            _url = me.AnexarQueryInteiroSePositivo(_url, "page_size", pInput.TamanhoPagina)
            _url = me.AnexarQueryTextoSeInformado(_url, "sort_by", pInput.OrdenarPor)
            _url = me.AnexarQueryTextoSeInformado(_url, "sort_dir", pInput.DirecaoOrdenacao)
            _url = me.AnexarQueryInteiroSePositivo(_url, "modality", pInput.CodModalidade)
            _url = me.AnexarQueryInteiroSePositivo(_url, "erp_seller_handle", pInput.CodErpSellerHandle)
            _url = me.AnexarQueryTextoSeInformado(_url, "state", pInput.Estado)

            ListarPendenciasPorPedidoApi = me.ExecutarGetPassThrough(pInput.CodUsuario, _url, "GET /sales/pendencies/by-orders")
        End Function

        Private Function ExecutarGetPassThrough(pCodUsuario As Integer, pUrl As String, pOperacao As String) As String
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(pUrl)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp(pOperacao, _response))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson(pOperacao, _response.StatusCode, _response.Body)

                ExecutarGetPassThrough = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraSalesService." & pOperacao, ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw ex
            End Try
        End Function

        Private Function AnexarQueryInteiroSePositivo(pUrl As String, pNome As String, pValor As Integer) As String
            If pValor > 0 Then
                AnexarQueryInteiroSePositivo = RedeAncoraUrlHelper.AppendQueryParam(pUrl, pNome, Parser.IntegerToString(pValor))
                Exit Function
            End If

            AnexarQueryInteiroSePositivo = pUrl
        End Function

        Private Function AnexarQueryTextoSeInformado(pUrl As String, pNome As String, pValor As String) As String
            If pValor.Trim() <> "" Then
                AnexarQueryTextoSeInformado = RedeAncoraUrlHelper.AppendQueryParam(pUrl, pNome, pValor.Trim())
                Exit Function
            End If

            AnexarQueryTextoSeInformado = pUrl
        End Function

        Private Function MontarErroHttp(pOperacao As String, pResponse As HttpResponse) As String
            RedeAncoraHttpErroHelper.RegistrarFalha(pOperacao, pResponse.StatusCode, pResponse.Body)
            MontarErroHttp = RedeAncoraHttpErroHelper.MontarMensagem(pOperacao, pResponse.StatusCode, pResponse.Body)
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._authService) Then
                    me._authService.Free()
                    me._authService = Null
                End If

                If Assigned(me._empresaService) Then
                    me._empresaService.Free()
                    me._empresaService = Null
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
