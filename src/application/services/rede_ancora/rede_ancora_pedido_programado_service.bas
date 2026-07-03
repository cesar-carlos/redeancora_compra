Imports mod_tobject
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_url_helper
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_empresa_service
Imports rede_ancora_input_listar_pedidos_programados
Imports rede_ancora_input_listar_produtos_pedido_programado
Imports rede_ancora_input_solicitar_relatorio_pedido_programado
Imports http_response

Namespace rede_ancora_pedido_programado_service
    Class RedeAncoraPedidoProgramadoService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _empresaService As RedeAncoraEmpresaService

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._empresaService = New RedeAncoraEmpresaService()
        End Sub

        Function ListarPedidosProgramados(pInput As RedeAncoraInputListarPedidosProgramados) As String
            Dim _url As String = ""

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input ListarPedidosProgramados nao informado")
            End If

            If pInput.CodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido para listagem de pedidos programados")
            End If

            me._empresaService.ValidarPodeOperar(pInput.CodUsuario)

            _url = RedeAncoraApiConfig.IntegrationUrl("/scheduled-order")
            _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "seller", Parser.IntegerToString(pInput.CodCentroDistribuicao))
            _url = me.AnexarQueryInteiroSePositivo(_url, "brand_id", pInput.CodMarca)
            _url = me.AnexarQueryTextoSeInformado(_url, "display_from", pInput.DataInicial)
            _url = me.AnexarQueryTextoSeInformado(_url, "display_to", pInput.DataFinal)

            ListarPedidosProgramados = me.ExecutarGetPassThrough(pInput.CodUsuario, _url, "GET /scheduled-order")
        End Function

        Function ConsultarPedidoProgramado(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pIdPedidoProgramado As Integer) As String
            Dim _url As String = ""

            If pCodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido para consulta de pedido programado")
            End If

            If pIdPedidoProgramado <= 0 Then
                Throw New System.Exception("IdPedidoProgramado invalido para consulta")
            End If

            me._empresaService.ValidarPodeOperar(pCodUsuario)

            _url = RedeAncoraApiConfig.IntegrationUrl("/scheduled-order/" + Parser.IntegerToString(pIdPedidoProgramado))
            _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "seller", Parser.IntegerToString(pCodCentroDistribuicao))

            ConsultarPedidoProgramado = me.ExecutarGetPassThrough(pCodUsuario, _url, "GET /scheduled-order/{scheduledOrderId}")
        End Function

        Function ConsultarResumoPedidoProgramado(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pIdPedidoProgramado As Integer) As String
            Dim _url As String = ""

            If pCodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido para resumo de pedido programado")
            End If

            If pIdPedidoProgramado <= 0 Then
                Throw New System.Exception("IdPedidoProgramado invalido para resumo")
            End If

            me._empresaService.ValidarPodeOperar(pCodUsuario)

            _url = RedeAncoraApiConfig.IntegrationUrl("/scheduled-order/" + Parser.IntegerToString(pIdPedidoProgramado) + "/resume")
            _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "seller", Parser.IntegerToString(pCodCentroDistribuicao))

            ConsultarResumoPedidoProgramado = me.ExecutarGetPassThrough(pCodUsuario, _url, "GET /scheduled-order/{scheduledOrderId}/resume")
        End Function

        Function ListarProdutosPedidoProgramado(pInput As RedeAncoraInputListarProdutosPedidoProgramado) As String
            Dim _url As String = ""

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input ListarProdutosPedidoProgramado nao informado")
            End If

            If pInput.IdPedidoProgramado <= 0 Then
                Throw New System.Exception("IdPedidoProgramado invalido para listagem de produtos")
            End If

            If pInput.CodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido para listagem de produtos programados")
            End If

            If pInput.CodEstado <= 0 Then
                Throw New System.Exception("CodEstado invalido para listagem de produtos programados")
            End If

            If pInput.Pagina <= 0 Then
                Throw New System.Exception("Pagina invalida para listagem de produtos programados")
            End If

            me._empresaService.ValidarPodeOperar(pInput.CodUsuario)

            _url = RedeAncoraApiConfig.IntegrationUrl("/scheduled-order/" + Parser.IntegerToString(pInput.IdPedidoProgramado) + "/products")
            _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "seller", Parser.IntegerToString(pInput.CodCentroDistribuicao))
            _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "estado", Parser.IntegerToString(pInput.CodEstado))
            _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "pagina", Parser.IntegerToString(pInput.Pagina))
            _url = me.AnexarQueryInteiroSePositivo(_url, "itensPorPagina", pInput.ItensPorPagina)
            _url = me.AnexarQueryTextoSeInformado(_url, "query", pInput.Query)
            _url = me.AnexarQueryInteiroSePositivo(_url, "cicle_id", pInput.IdCiclo)
            _url = me.AnexarQueryTextoSeInformado(_url, "sortBy", pInput.OrdenarPor)
            _url = me.AnexarQueryTextoSeInformado(_url, "sortDir", pInput.DirecaoOrdenacao)

            ListarProdutosPedidoProgramado = me.ExecutarGetPassThrough(pInput.CodUsuario, _url, "GET /scheduled-order/{scheduledOrderId}/products")
        End Function

        Function SolicitarRelatorioProdutosPedidoProgramado(pInput As RedeAncoraInputSolicitarRelatorioPedidoProgramado) As String
            Dim _url As String = ""

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input SolicitarRelatorioProdutosPedidoProgramado nao informado")
            End If

            If pInput.IdPedidoProgramado <= 0 Then
                Throw New System.Exception("IdPedidoProgramado invalido para solicitacao de relatorio")
            End If

            If pInput.CodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido para solicitacao de relatorio")
            End If

            me._empresaService.ValidarPodeOperar(pInput.CodUsuario)

            _url = RedeAncoraApiConfig.IntegrationUrl("/scheduled-order/" + Parser.IntegerToString(pInput.IdPedidoProgramado) + "/products/report")
            _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "seller", Parser.IntegerToString(pInput.CodCentroDistribuicao))
            _url = me.AnexarQueryInteiroSePositivo(_url, "estado", pInput.CodEstado)

            SolicitarRelatorioProdutosPedidoProgramado = me.ExecutarGetPassThrough(pInput.CodUsuario, _url, "GET /scheduled-order/{scheduledOrderId}/products/report")
        End Function

        Private Function ExecutarGetPassThrough(pCodUsuario As Integer, pUrl As String, pOperacao As String) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(pUrl)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp(pOperacao, _response))
                End If

                ExecutarGetPassThrough = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
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
            Dim _msg As String = ""

            _msg = pOperacao + " Rede Ancora falhou. HTTP " + Parser.IntegerToString(pResponse.StatusCode) + ": " + pResponse.Body
            MontarErroHttp = _msg
        End Function

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
