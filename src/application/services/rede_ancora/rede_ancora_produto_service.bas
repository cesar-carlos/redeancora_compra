Imports mod_tobject
Imports rede_ancora_api_config
Imports rede_ancora_url_helper
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_json_helper
Imports rede_ancora_produto_vinculo_model
Imports rede_ancora_produto_vinculo_repository
Imports rede_ancora_produto_model
Imports rede_ancora_produto_repository
Imports rede_ancora_produto_vinculo_origem
Imports rede_ancora_produto_vinculos_model
Imports rede_ancora_produto_preco_estoque_model
Imports rede_ancora_produto_precos_estoque_model
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_codigos_model
Imports rede_ancora_input_buscar_produtos
Imports rede_ancora_input_consultar_similares
Imports rede_ancora_input_buscar_produtos_por_lote
Imports rede_ancora_input_consultar_precos_estoques_cds
Imports rede_ancora_produto_imagem_model
Imports rede_ancora_produto_imagens_model
Imports rede_ancora_produto_imagem_tipo
Imports rede_ancora_produto_imagem_repository
Imports rede_ancora_produto_imagem_sincronizacao_resultado_model
Imports string_helper
Imports try_parser
Imports http_response
Imports mod_logger
Imports diag_stack
Imports rede_ancora_http_erro_helper

Namespace rede_ancora_produto_service
    Class RedeAncoraProdutoService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _vinculoRepository As RedeAncoraProdutoVinculoRepository
        Private _produtoRepository As RedeAncoraProdutoRepository
        Private _imagemRepository As RedeAncoraProdutoImagemRepository

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._vinculoRepository = New RedeAncoraProdutoVinculoRepository()
            me._produtoRepository = New RedeAncoraProdutoRepository()
            me._imagemRepository = New RedeAncoraProdutoImagemRepository()
        End Sub

        Function ConsultarCondicoes(pCodUsuario As Integer, pCna As Integer) As String
            ConsultarCondicoes = me.ExecutarConsultaCondicoes(pCodUsuario, pCna)
        End Function

        Sub ValidarProdutoParaCarrinho(pCodUsuario As Integer, pCna As Integer)
            If Not RedeAncoraApiConfig.ValidarProdutoAntesCarrinho() Then
                Exit Sub
            End If

            me.ExecutarConsultaCondicoes(pCodUsuario, pCna)
        End Sub

        Private Function ExecutarConsultaCondicoes(pCodUsuario As Integer, pCna As Integer) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                If pCna <= 0 Then
                    Throw New System.Exception("Cna invalido para consulta de condicoes")
                End If

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/products/conditions/" + pCna.ToString()))

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("GET /products/conditions", _response.StatusCode, _response.Body))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET /products/conditions", _response.StatusCode, _response.Body)

                ExecutarConsultaCondicoes = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.ConsultarCondicoes", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao consultar condicoes do produto Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ConsultarPrecosEstoques(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCnas As RedeAncoraProdutoCnasModel) As RedeAncoraProdutoPrecosEstoqueModel
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _result As RedeAncoraProdutoPrecosEstoqueModel = NULL

            Try
                pCnas.ValidarTodos()

                If pCodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("Centro de distribuicao invalido para prices-stocks")
                End If

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/products/prices-stocks"), me.MontarPayloadPrecosEstoques(pCodCentroDistribuicao, pCnas))

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("POST /products/prices-stocks", _response.StatusCode, _response.Body))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("POST /products/prices-stocks", _response.StatusCode, _response.Body)

                _result = me.MapearPrecosEstoques(_response)
                _response.Free()
                _api.Free()
                ConsultarPrecosEstoques = _result
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.ConsultarPrecosEstoques", ex)

                If Assigned(_result) Then
                    _result.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao consultar precos e estoques Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function BuscarProdutoFullSearchPorFamilia(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodFamilia As Integer, pPagina As Integer, pTamanhoPagina As Integer) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _url As String = ""
            Dim _body As String = ""
            Dim _status As Integer = 0
            Dim _bytes As Integer = 0
            Dim _snippet As String = ""
            Dim _ok As Boolean = False
            Dim _result As String = ""

            Try
                If pCodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("Centro de distribuicao invalido para full-search")
                End If

                If pCodFamilia <= 0 Then
                    Throw New System.Exception("CodFamilia invalido para full-search")
                End If

                If pPagina <= 0 Then
                    Throw New System.Exception("Pagina invalida para full-search")
                End If

                If pTamanhoPagina <= 0 Then
                    Throw New System.Exception("Tamanho de pagina invalido para full-search")
                End If

                _url = RedeAncoraApiConfig.IntegrationUrl("/products/full-search?empresa=" & Parser.IntegerToString(pCodCentroDistribuicao) & "&fields=details")
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "family", Parser.IntegerToString(pCodFamilia))
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "page", Parser.IntegerToString(pPagina))
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "page_size", Parser.IntegerToString(pTamanhoPagina))

                mod_logger.Info("sync-full: before HTTP familia=" & Parser.IntegerToString(pCodFamilia) & " pagina=" & Parser.IntegerToString(pPagina) & " page_size=" & Parser.IntegerToString(pTamanhoPagina))
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                DiagStack.Push("full-search.GetRequest")
                _response = _api.GetRequest(_url)
                DiagStack.Pop()

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

                mod_logger.Info("GET /products/full-search HTTP " & Parser.IntegerToString(_status) & " bytes=" & Parser.IntegerToString(_bytes) & " body=" & _snippet)
                mod_logger.Info("sync-full: after HTTP familia=" & Parser.IntegerToString(pCodFamilia) & " pagina=" & Parser.IntegerToString(pPagina))

                If Not Assigned(_response) Then
                    Throw New System.Exception("GET /products/full-search resposta nula")
                End If

                _ok = _response.IsSuccess
                If Not _ok Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("GET /products/full-search", _status, _body))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET /products/full-search", _status, _body)

                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _result = _body
            Catch ex As Exception
                DiagStack.DumpOnError(ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro na busca full-search por familia Rede Ancora: " & DiagStack.FormatException(ex))
            End Try

            BuscarProdutoFullSearchPorFamilia = _result
        End Function

        Function BuscarProdutoFullSearch(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCna As Integer, pCodigo As String, pQuery As String) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _url As String = ""

            Try
                If pCodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("Centro de distribuicao invalido para full-search")
                End If

                _url = RedeAncoraApiConfig.IntegrationUrl("/products/full-search?empresa=" + pCodCentroDistribuicao.ToString() + "&fields=prices,stocks,details")

                If pCna > 0 Then
                    _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "cna", pCna.ToString())
                End If

                If pCodigo.Trim() <> "" Then
                    _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "code", pCodigo.Trim())
                End If

                If pQuery.Trim() <> "" Then
                    _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "query", pQuery.Trim())
                End If

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(_url)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("GET /products/full-search", _response.StatusCode, _response.Body))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET /products/full-search", _response.StatusCode, _response.Body)

                BuscarProdutoFullSearch = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.BuscarProdutoFullSearch", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro na busca full-search Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function BuscarProdutoBulkSearch(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pPagina As Integer, pTamanhoPagina As Integer) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                pCnas.ValidarTodos()

                If pCodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("Centro de distribuicao invalido para bulk-search")
                End If

                If pCodEstado <= 0 Then
                    Throw New System.Exception("CodEstado invalido para bulk-search")
                End If

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/products/bulk-search"), me.MontarPayloadBulkSearch(pCodCentroDistribuicao, pCodEstado, pCnas, pPagina, pTamanhoPagina))

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("POST /products/bulk-search", _response.StatusCode, _response.Body))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("POST /products/bulk-search", _response.StatusCode, _response.Body)

                BuscarProdutoBulkSearch = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.BuscarProdutoBulkSearch", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro na busca bulk-search Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ConsultarCentrosComEstoque(pCodUsuario As Integer, pCna As Integer, pCodEstado As Integer, pCodCentroDistribuicao As Integer) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As TJSONObject = NULL

            Try
                If pCna <= 0 Then
                    Throw New System.Exception("Cna invalido para consulta de warehouses")
                End If

                If pCodEstado <= 0 Then
                    Throw New System.Exception("CodEstado invalido para consulta de warehouses")
                End If

                If pCodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("Centro de distribuicao invalido para consulta de warehouses")
                End If

                _payload = New TJSONObject()
                _payload.PutInteger("estado", pCodEstado)
                _payload.PutInteger("empresa", pCodCentroDistribuicao)

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/products/warehouses/" + pCna.ToString()), _payload.ToString())

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("POST /products/warehouses", _response.StatusCode, _response.Body))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("POST /products/warehouses", _response.StatusCode, _response.Body)

                ConsultarCentrosComEstoque = _response.Body
                _payload.Free()
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.ConsultarCentrosComEstoque", ex)

                If Assigned(_payload) Then
                    _payload.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao consultar centros com estoque Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function BuscarProdutos(pInput As RedeAncoraInputBuscarProdutos) As String
            Dim _url As String = ""

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input BuscarProdutos nao informado")
            End If

            _url = RedeAncoraApiConfig.IntegrationUrl("/products")
            _url = me.AnexarQueryInteiroSePositivo(_url, "page", pInput.Pagina)
            _url = me.AnexarQueryInteiroSePositivo(_url, "page_size", pInput.TamanhoPagina)
            _url = me.AnexarQueryTextoSeInformado(_url, "brand", pInput.Marca)
            _url = me.AnexarQueryTextoSeInformado(_url, "code", pInput.Codigo)
            _url = me.AnexarQueryInteiroSePositivo(_url, "cna", pInput.Cna)
            _url = me.AnexarQueryTextoSeInformado(_url, "gtin", pInput.Gtin)
            _url = me.AnexarQueryTextoSeInformado(_url, "cest", pInput.Cest)
            _url = me.AnexarQueryInteiroSePositivo(_url, "origem", pInput.Origem)
            _url = me.AnexarQueryTextoSeInformado(_url, "name", pInput.Nome)
            _url = me.AnexarQueryInteiroSePositivo(_url, "line", pInput.CodLinha)
            _url = me.AnexarQueryInteiroSePositivo(_url, "family", pInput.CodFamilia)

            BuscarProdutos = me.ExecutarGetPassThrough(pInput.CodUsuario, _url, "GET /products")
        End Function

        Function ConsultarSimilares(pInput As RedeAncoraInputConsultarSimilares) As String
            Dim _payload As String = ""

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input ConsultarSimilares nao informado")
            End If

            If Not Assigned(pInput.Cnas) Then
                Throw New System.Exception("Lista de CNAs nao informada para consulta de similares")
            End If

            pInput.Cnas.ValidarTodos()

            If pInput.CodEstado <= 0 Then
                Throw New System.Exception("CodEstado invalido para consulta de similares")
            End If

            If pInput.CodCentroDistribuicao <= 0 Then
                Throw New System.Exception("Centro de distribuicao invalido para consulta de similares")
            End If

            _payload = "{" +_
                """cna"":" + me.MontarArrayCnasJson(pInput.Cnas) + "," +_
                """estado"":" + Parser.IntegerToString(pInput.CodEstado) + "," +_
                """empresa"":" + Parser.IntegerToString(pInput.CodCentroDistribuicao) + "}"

            ConsultarSimilares = me.ExecutarPostPassThrough(pInput.CodUsuario, RedeAncoraApiConfig.IntegrationUrl("/products/similares"), _payload, "POST /products/similares")
        End Function

        Function BuscarProdutosPorLote(pInput As RedeAncoraInputBuscarProdutosPorLote) As String
            Dim _payload As String = ""
            Dim _temLista As Boolean = False

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input BuscarProdutosPorLote nao informado")
            End If

            _payload = "{"

            If Assigned(pInput.CnaList) Then
                If pInput.CnaList.Length > 0 Then
                    pInput.CnaList.ValidarTodos()
                    _payload = _payload + """cna_list"":" + me.MontarArrayCnasJson(pInput.CnaList)
                    _temLista = True
                End If
            End If

            If Assigned(pInput.CodeList) Then
                If pInput.CodeList.Length > 0 Then
                    pInput.CodeList.ValidarTodos()

                    If _temLista Then
                        _payload = _payload + ","
                    End If

                    _payload = _payload + """code_list"":" + me.MontarArrayCodigosJson(pInput.CodeList)
                    _temLista = True
                End If
            End If

            If Assigned(pInput.GtinList) Then
                If pInput.GtinList.Length > 0 Then
                    pInput.GtinList.ValidarTodos()

                    If _temLista Then
                        _payload = _payload + ","
                    End If

                    _payload = _payload + """gtin_list"":" + me.MontarArrayCodigosJson(pInput.GtinList)
                    _temLista = True
                End If
            End If

            If Not _temLista Then
                Throw New System.Exception("Informe ao menos uma lista (cna_list, code_list ou gtin_list) para busca em lote")
            End If

            If pInput.Pagina > 0 Then
                _payload = _payload + ",""page"":" + Parser.IntegerToString(pInput.Pagina)
            End If

            If pInput.TamanhoPagina > 0 Then
                _payload = _payload + ",""page_size"":" + Parser.IntegerToString(pInput.TamanhoPagina)
            End If

            _payload = _payload + "}"

            BuscarProdutosPorLote = me.ExecutarPostPassThrough(pInput.CodUsuario, RedeAncoraApiConfig.IntegrationUrl("/products/bulk"), _payload, "POST /products/bulk")
        End Function

        Function ConsultarPrecosEstoquesTodosCds(pInput As RedeAncoraInputConsultarPrecosEstoquesCds) As String
            Dim _payload As String = ""
            Dim _temCna As Boolean = False
            Dim _temCode As Boolean = False

            If Not Assigned(pInput) Then
                Throw New System.Exception("Input ConsultarPrecosEstoquesTodosCds nao informado")
            End If

            _payload = "{"

            If pInput.CodCentroDistribuicaoPreferencial > 0 Then
                _payload = _payload + """empresa"":" + Parser.IntegerToString(pInput.CodCentroDistribuicaoPreferencial)
            End If

            If Assigned(pInput.Cnas) Then
                If pInput.Cnas.Length > 0 Then
                    pInput.Cnas.ValidarTodos()

                    If pInput.CodCentroDistribuicaoPreferencial > 0 Then
                        _payload = _payload + ","
                    End If

                    _payload = _payload + """cnas"":" + me.MontarArrayCnasJson(pInput.Cnas)
                    _temCna = True
                End If
            End If

            If Assigned(pInput.Codes) Then
                If pInput.Codes.Length > 0 Then
                    pInput.Codes.ValidarTodos()

                    If pInput.CodCentroDistribuicaoPreferencial > 0 Or _temCna Then
                        _payload = _payload + ","
                    End If

                    _payload = _payload + """codes"":" + me.MontarArrayCodigosJson(pInput.Codes)
                    _temCode = True
                End If
            End If

            If Not _temCna And Not _temCode Then
                Throw New System.Exception("Informe ao menos um CNA ou codigo para prices-stocks-warehouses")
            End If

            _payload = _payload + "}"

            ConsultarPrecosEstoquesTodosCds = me.ExecutarPostPassThrough(pInput.CodUsuario, RedeAncoraApiConfig.IntegrationUrl("/products/prices-stocks-warehouses"), _payload, "POST /products/prices-stocks-warehouses")
        End Function

        Function ResolverCnaParaCompra(pCodProduto As Integer) As Integer
            Dim _vinculo As RedeAncoraProdutoVinculoModel = NULL

            Try
                _vinculo = me._vinculoRepository.ObterAtivoPorCodProduto(pCodProduto)
                ResolverCnaParaCompra = _vinculo.Cna
                _vinculo.Free()
            Catch ex As Exception
                If Assigned(_vinculo) Then
                    _vinculo.Free()
                End If

                Throw New System.Exception("Produto.CodProduto " + pCodProduto.ToString() + " sem vinculo ativo com Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function TryObterVinculoAtivo(pCodProduto As Integer, pItem As RedeAncoraProdutoVinculoModel) As Boolean
            TryObterVinculoAtivo = me._vinculoRepository.TryObterAtivoPorCodProduto(pCodProduto, pItem)
        End Function

        Function TryObterProdutoAncoraAtivo(pCna As Integer, pItem As RedeAncoraProdutoVinculoModel) As Boolean
            TryObterProdutoAncoraAtivo = me._vinculoRepository.TryObterAtivoPorCna(pCna, pItem)
        End Function

        Function ObterVinculoPorCodProduto(pCodProduto As Integer) As RedeAncoraProdutoVinculoModel
            ObterVinculoPorCodProduto = me._vinculoRepository.ObterAtivoPorCodProduto(pCodProduto)
        End Function

        Function ObterProdutoAncoraPorCna(pCna As Integer) As RedeAncoraProdutoVinculoModel
            ObterProdutoAncoraPorCna = me._vinculoRepository.ObterPorCna(pCna)
        End Function

        Function ListarProdutosAncoraAtivos() As RedeAncoraProdutoVinculosModel
            ListarProdutosAncoraAtivos = me._vinculoRepository.ListarAtivos()
        End Function

        Function ListarVinculosAtivos() As RedeAncoraProdutoVinculosModel
            ListarVinculosAtivos = me._vinculoRepository.ListarVinculadosAtivos()
        End Function

        Sub SalvarProdutoAncora(pModel As RedeAncoraProdutoVinculoModel)
            If pModel.OrigemVinculo.Trim() = "" Then
                pModel.OrigemVinculo = RedeAncoraProdutoVinculoOrigem.Manual()
            End If

            me._vinculoRepository.Salvar(pModel)
            me.EspelharVinculoNoCadastro(pModel, True)
        End Sub

        Sub SalvarVinculo(pModel As RedeAncoraProdutoVinculoModel)
            pModel.ValidateVinculo()
            me.SalvarProdutoAncora(pModel)
        End Sub

        Sub DesativarProdutoAncora(pCna As Integer)
            me._vinculoRepository.DesativarPorCna(pCna)
            me._produtoRepository.DesativarPorCna(pCna)
            me._imagemRepository.ExcluirPorCna(pCna)
        End Sub

        Sub DesativarProdutoAncoraSemTransacao(pCna As Integer)
            me._vinculoRepository.DesativarPorCnaSemTransacao(pCna)
            me._produtoRepository.DesativarPorCnaSemTransacao(pCna)
            me._imagemRepository.ExcluirPorCnaSemTransacao(pCna)
        End Sub

        Sub DesativarVinculo(pCodProduto As Integer)
            me._vinculoRepository.DesativarPorCodProduto(pCodProduto)
        End Sub

        Function CadastrarProdutoAncoraManual(pCna As Integer, pCodigoAncora As String, pDescricaoAncora As String, pCodMarca As Integer, pCodLinha As Integer, pCodFamilia As Integer, pObservacao As String) As RedeAncoraProdutoVinculoModel
            Dim _model As New RedeAncoraProdutoVinculoModel()

            _model.Cna = pCna
            _model.CodigoAncora = pCodigoAncora
            _model.DescricaoAncora = pDescricaoAncora
            _model.CodMarca = pCodMarca
            _model.CodLinha = pCodLinha
            _model.CodFamilia = pCodFamilia
            _model.Ativo = "S"
            _model.OrigemVinculo = RedeAncoraProdutoVinculoOrigem.Manual()
            _model.Observacao = pObservacao
            me.SalvarProdutoAncora(_model)
            CadastrarProdutoAncoraManual = _model
        End Function

        Function CadastrarProdutoAncoraPorBusca(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCna As Integer, pCodigo As String, pQuery As String) As RedeAncoraProdutoVinculoModel
            CadastrarProdutoAncoraPorBusca = me.ProcessarProdutoAncoraPorBusca(pCodUsuario, pCodCentroDistribuicao, pCna, pCodigo, pQuery, 0, RedeAncoraProdutoVinculoOrigem.Busca())
        End Function

        Function VincularComProdutoInterno(pCna As Integer, pCodProduto As Integer) As RedeAncoraProdutoVinculoModel
            Dim _model As RedeAncoraProdutoVinculoModel = NULL

            Try
                _model = me._vinculoRepository.ObterPorCna(pCna)
                _model.CodProduto = pCodProduto
                _model.Ativo = "S"
                me.SalvarVinculo(_model)
                VincularComProdutoInterno = _model
            Catch ex As Exception
                If Assigned(_model) Then
                    _model.Free()
                End If

                Throw New System.Exception("Erro ao vincular CNA " + pCna.ToString() + " com Produto.CodProduto " + pCodProduto.ToString() + ": " + ex._getMessage())
            End Try
        End Function

        Function VincularProdutoManual(pCodProduto As Integer, pCna As Integer, pCodigoAncora As String, pDescricaoAncora As String, pCodMarca As Integer, pCodLinha As Integer, pCodFamilia As Integer, pObservacao As String) As RedeAncoraProdutoVinculoModel
            Dim _model As New RedeAncoraProdutoVinculoModel()

            _model.Cna = pCna
            _model.CodProduto = pCodProduto
            _model.CodigoAncora = pCodigoAncora
            _model.DescricaoAncora = pDescricaoAncora
            _model.CodMarca = pCodMarca
            _model.CodLinha = pCodLinha
            _model.CodFamilia = pCodFamilia
            _model.Ativo = "S"
            _model.OrigemVinculo = RedeAncoraProdutoVinculoOrigem.Manual()
            _model.Observacao = pObservacao
            me.SalvarVinculo(_model)
            VincularProdutoManual = _model
        End Function

        Function VincularProdutoPorBusca(pCodUsuario As Integer, pCodProduto As Integer, pCodCentroDistribuicao As Integer, pCna As Integer, pCodigo As String, pQuery As String) As RedeAncoraProdutoVinculoModel
            VincularProdutoPorBusca = me.ProcessarProdutoAncoraPorBusca(pCodUsuario, pCodCentroDistribuicao, pCna, pCodigo, pQuery, pCodProduto, RedeAncoraProdutoVinculoOrigem.Busca())
        End Function

        ' Retorna 1=inserido, 2=atualizado, 3=sem alteracao.
        Function UpsertProdutoAncoraDeApi(pItemJson As TJSONObject, pOrigem As String) As Integer
            UpsertProdutoAncoraDeApi = me.UpsertProdutoAncoraDeApiComTransacao(pItemJson, pOrigem, True)
        End Function

        Function UpsertProdutoAncoraDeApiComTransacao(pItemJson As TJSONObject, pOrigem As String, pUsarTransacao As Boolean) As Integer
            Dim _cadastro As RedeAncoraProdutoModel = NULL
            Dim _result As Integer = 0

            Try
                _cadastro = me.MapearProdutoCadastroDeJson(pItemJson, 0)
                _result = me.UpsertCadastroProdutoEVinculo(_cadastro, pOrigem, pUsarTransacao)
                _cadastro.Free()
                _cadastro = NULL
            Catch ex As Exception
                If Assigned(_cadastro) Then
                    _cadastro.Free()
                End If

                Throw New System.Exception("Erro ao persistir produto Ancora da API: " & ex._getMessage())
            End Try

            UpsertProdutoAncoraDeApiComTransacao = _result
        End Function

        ' Full-search / janela ASCII: nao usa TJSONObject (body de familia pode ter centenas de KB).
        Function UpsertProdutoAncoraDeCampos(pCna As Integer, pCodigoAncora As String, pDescricaoAncora As String, pCodMarca As Integer, pCodLinha As Integer, pCodFamilia As Integer, pOrigem As String, pUsarTransacao As Boolean) As Integer
            Dim _cadastro As RedeAncoraProdutoModel = NULL
            Dim _result As Integer = 0

            Try
                If pCna <= 0 Then
                    Throw New System.Exception("CNA nao encontrado na resposta de produto da Rede Ancora")
                End If

                _cadastro = New RedeAncoraProdutoModel()
                _cadastro.Cna = pCna
                _cadastro.CodigoReferencia = pCodigoAncora
                _cadastro.NomeProduto = pDescricaoAncora
                _cadastro.CodMarcaErp = pCodMarca
                _cadastro.CodLinha = pCodLinha
                _cadastro.CodFamilia = pCodFamilia
                _result = me.UpsertCadastroProdutoEVinculo(_cadastro, pOrigem, pUsarTransacao)
                _cadastro.Free()
                _cadastro = NULL
            Catch ex As Exception
                If Assigned(_cadastro) Then
                    _cadastro.Free()
                End If

                Throw New System.Exception("Erro ao persistir produto Ancora da API: " & ex._getMessage())
            End Try

            UpsertProdutoAncoraDeCampos = _result
        End Function

        Function UpsertCadastroProdutoEVinculo(pCadastro As RedeAncoraProdutoModel, pOrigem As String, pUsarTransacao As Boolean) As Integer
            Dim _vinculo As RedeAncoraProdutoVinculoModel = NULL
            Dim _statusCadastro As Integer = 0
            Dim _statusVinculo As Integer = 0
            Dim _result As Integer = 3

            Try
                _statusCadastro = me.UpsertProdutoCadastro(pCadastro, pUsarTransacao)

                _vinculo = New RedeAncoraProdutoVinculoModel()
                _vinculo.Cna = pCadastro.Cna
                _vinculo.CodigoAncora = pCadastro.CodigoReferencia
                _vinculo.DescricaoAncora = pCadastro.NomeProduto
                _vinculo.CodMarca = pCadastro.CodMarcaParaVinculo()
                _vinculo.CodLinha = pCadastro.CodLinha
                _vinculo.CodFamilia = pCadastro.CodFamilia
                _statusVinculo = me.UpsertProdutoAncoraDeModelo(_vinculo, pOrigem, pUsarTransacao)
                _vinculo.Free()
                _vinculo = NULL

                If _statusCadastro = 1 Then
                    _result = 1
                Else
                    If _statusVinculo = 1 Then
                        _result = 1
                    Else
                        If _statusCadastro = 2 Then
                            _result = 2
                        Else
                            If _statusVinculo = 2 Then
                                _result = 2
                            End If
                        End If
                    End If
                End If
            Catch ex As Exception
                If Assigned(_vinculo) Then
                    _vinculo.Free()
                End If

                Throw New System.Exception("Erro ao persistir cadastro e vinculo Ancora: " & ex._getMessage())
            End Try

            UpsertCadastroProdutoEVinculo = _result
        End Function

        Private Sub EspelharVinculoNoCadastro(pVinculo As RedeAncoraProdutoVinculoModel, pUsarTransacao As Boolean)
            Dim _cadastro As RedeAncoraProdutoModel = NULL

            If Not Assigned(pVinculo) Then
                Exit Sub
            End If

            If pVinculo.Cna <= 0 Then
                Exit Sub
            End If

            Try
                _cadastro = New RedeAncoraProdutoModel()
                _cadastro.Cna = pVinculo.Cna
                _cadastro.CodigoReferencia = pVinculo.CodigoAncora
                _cadastro.NomeProduto = pVinculo.DescricaoAncora
                _cadastro.CodMarcaErp = pVinculo.CodMarca
                _cadastro.CodLinha = pVinculo.CodLinha
                _cadastro.CodFamilia = pVinculo.CodFamilia
                _cadastro.Ativo = pVinculo.Ativo
                me.UpsertProdutoCadastro(_cadastro, pUsarTransacao)
                _cadastro.Free()
                _cadastro = NULL
            Catch ex As Exception
                If Assigned(_cadastro) Then
                    _cadastro.Free()
                End If

                Throw New System.Exception("Erro ao espelhar vinculo no cadastro Ancora: " & ex._getMessage())
            End Try
        End Sub

        Private Function UpsertProdutoCadastro(pCadastro As RedeAncoraProdutoModel, pUsarTransacao As Boolean) As Integer
            Dim _existente As RedeAncoraProdutoModel = NULL
            Dim _result As Integer = 0

            Try
                If pCadastro.Ativo.Trim() = "" Then
                    pCadastro.Ativo = "S"
                End If

                _existente = New RedeAncoraProdutoModel()

                If me._produtoRepository.TryObterPorCna(pCadastro.Cna, _existente) Then
                    me.MesclarCadastroExistente(_existente, pCadastro)

                    If me.CadastroTemAlteracao(_existente, pCadastro) Then
                        If pUsarTransacao Then
                            me._produtoRepository.Salvar(pCadastro)
                        Else
                            me._produtoRepository.SalvarSemTransacao(pCadastro)
                        End If

                        _result = 2
                    Else
                        _result = 3
                    End If
                Else
                    If pUsarTransacao Then
                        me._produtoRepository.Salvar(pCadastro)
                    Else
                        me._produtoRepository.SalvarSemTransacao(pCadastro)
                    End If

                    _result = 1
                End If

                _existente.Free()
                _existente = NULL
            Catch ex As Exception
                If Assigned(_existente) Then
                    _existente.Free()
                End If

                Throw ex
            End Try

            UpsertProdutoCadastro = _result
        End Function

        Private Sub MesclarCadastroExistente(pExistente As RedeAncoraProdutoModel, pApi As RedeAncoraProdutoModel)
            If pApi.CatalogoId <= 0 Then
                pApi.CatalogoId = pExistente.CatalogoId
            End If
            If pApi.Csa.Trim() = "" Then
                pApi.Csa = pExistente.Csa
            End If
            If pApi.Cnl.Trim() = "" Then
                pApi.Cnl = pExistente.Cnl
            End If
            If pApi.CodigoReferencia.Trim() = "" Then
                pApi.CodigoReferencia = pExistente.CodigoReferencia
            End If
            If pApi.CodeEdi.Trim() = "" Then
                pApi.CodeEdi = pExistente.CodeEdi
            End If
            If pApi.CodeManufacturer.Trim() = "" Then
                pApi.CodeManufacturer = pExistente.CodeManufacturer
            End If
            If pApi.NomeProduto.Trim() = "" Then
                pApi.NomeProduto = pExistente.NomeProduto
            End If
            If pApi.NomeErp.Trim() = "" Then
                pApi.NomeErp = pExistente.NomeErp
            End If
            If pApi.InformacoesAdicionais.Trim() = "" Then
                pApi.InformacoesAdicionais = pExistente.InformacoesAdicionais
            End If
            If pApi.InformacoesComplementares.Trim() = "" Then
                pApi.InformacoesComplementares = pExistente.InformacoesComplementares
            End If
            If pApi.AdditionalDescription.Trim() = "" Then
                pApi.AdditionalDescription = pExistente.AdditionalDescription
            End If
            If pApi.PontoCriticoAtencao.Trim() = "" Then
                pApi.PontoCriticoAtencao = pExistente.PontoCriticoAtencao
            End If
            If pApi.Dimensoes.Trim() = "" Then
                pApi.Dimensoes = pExistente.Dimensoes
            End If
            If pApi.CodMarca <= 0 Then
                pApi.CodMarca = pExistente.CodMarca
            End If
            If pApi.CodMarcaErp <= 0 Then
                pApi.CodMarcaErp = pExistente.CodMarcaErp
            End If
            If pApi.NomeMarca.Trim() = "" Then
                pApi.NomeMarca = pExistente.NomeMarca
            End If
            If pApi.CodLinha <= 0 Then
                pApi.CodLinha = pExistente.CodLinha
            End If
            If pApi.NomeLinha.Trim() = "" Then
                pApi.NomeLinha = pExistente.NomeLinha
            End If
            If pApi.CodFamilia <= 0 Then
                pApi.CodFamilia = pExistente.CodFamilia
            End If
            If pApi.NomeFamilia.Trim() = "" Then
                pApi.NomeFamilia = pExistente.NomeFamilia
            End If
            If pApi.CodFabricante <= 0 Then
                pApi.CodFabricante = pExistente.CodFabricante
            End If
            If pApi.Ean.Trim() = "" Then
                pApi.Ean = pExistente.Ean
            End If
            If pApi.Gtin.Trim() = "" Then
                pApi.Gtin = pExistente.Gtin
            End If
            If pApi.Ncm.Trim() = "" Then
                pApi.Ncm = pExistente.Ncm
            End If
            If pApi.Cest.Trim() = "" Then
                pApi.Cest = pExistente.Cest
            End If
            If pApi.Origem.Trim() = "" Then
                pApi.Origem = pExistente.Origem
            End If
            If pApi.OrigemLabel.Trim() = "" Then
                pApi.OrigemLabel = pExistente.OrigemLabel
            End If
            If pApi.Anp <= 0 Then
                pApi.Anp = pExistente.Anp
            End If
            If pApi.AnpLabel.Trim() = "" Then
                pApi.AnpLabel = pExistente.AnpLabel
            End If
            If pApi.PesoLiquido = 0 Then
                pApi.PesoLiquido = pExistente.PesoLiquido
            End If
            If pApi.PesoBruto = 0 Then
                pApi.PesoBruto = pExistente.PesoBruto
            End If
            If pApi.Volume = 0 Then
                pApi.Volume = pExistente.Volume
            End If
            If pApi.Litros = 0 Then
                pApi.Litros = pExistente.Litros
            End If
            If pApi.Tamanho.Trim() = "" Then
                pApi.Tamanho = pExistente.Tamanho
            End If
            If pApi.Material.Trim() = "" Then
                pApi.Material = pExistente.Material
            End If
            If pApi.Tipo <= 0 Then
                pApi.Tipo = pExistente.Tipo
            End If
            If pApi.MedidaVenda.Trim() = "" Then
                pApi.MedidaVenda = pExistente.MedidaVenda
            End If
            If pApi.GarantiaDias <= 0 Then
                pApi.GarantiaDias = pExistente.GarantiaDias
            End If
            If pApi.FracaoFabrica <= 0 Then
                pApi.FracaoFabrica = pExistente.FracaoFabrica
            End If
            If pApi.FracaoLoja <= 0 Then
                pApi.FracaoLoja = pExistente.FracaoLoja
            End If
            If pApi.Status <= 0 Then
                pApi.Status = pExistente.Status
            End If
            If pApi.ErpHandle <= 0 Then
                pApi.ErpHandle = pExistente.ErpHandle
            End If
            If pApi.Leadtime <= 0 Then
                pApi.Leadtime = pExistente.Leadtime
            End If
            If pApi.Descontinuado.Trim() = "" Then
                pApi.Descontinuado = pExistente.Descontinuado
            End If
            If pApi.Bloqueado.Trim() = "" Then
                pApi.Bloqueado = pExistente.Bloqueado
            End If
            If pApi.Confiavel.Trim() = "" Then
                pApi.Confiavel = pExistente.Confiavel
            End If
            If pApi.Sugerido.Trim() = "" Then
                pApi.Sugerido = pExistente.Sugerido
            End If
            If pApi.Lancamento.Trim() = "" Then
                pApi.Lancamento = pExistente.Lancamento
            End If
            If pApi.OnDemand.Trim() = "" Then
                pApi.OnDemand = pExistente.OnDemand
            End If
            If pApi.OnDemandLabel.Trim() = "" Then
                pApi.OnDemandLabel = pExistente.OnDemandLabel
            End If
            If pApi.MotivoDescontinuado.Trim() = "" Then
                pApi.MotivoDescontinuado = pExistente.MotivoDescontinuado
            End If
            If pApi.ParcialmenteSimilar.Trim() = "" Then
                pApi.ParcialmenteSimilar = pExistente.ParcialmenteSimilar
            End If
            If pApi.HasRestrictions.Trim() = "" Then
                pApi.HasRestrictions = pExistente.HasRestrictions
            End If
            If pApi.PrazoEspecial.Trim() = "" Then
                pApi.PrazoEspecial = pExistente.PrazoEspecial
            End If
        End Sub

        Private Function CadastroTemAlteracao(pExistente As RedeAncoraProdutoModel, pApi As RedeAncoraProdutoModel) As Boolean
            CadastroTemAlteracao = True

            If pExistente.CatalogoId <> pApi.CatalogoId Then
                Exit Function
            End If
            If pExistente.Csa <> pApi.Csa Then
                Exit Function
            End If
            If pExistente.Cnl <> pApi.Cnl Then
                Exit Function
            End If
            If pExistente.CodigoReferencia <> pApi.CodigoReferencia Then
                Exit Function
            End If
            If pExistente.CodeEdi <> pApi.CodeEdi Then
                Exit Function
            End If
            If pExistente.CodeManufacturer <> pApi.CodeManufacturer Then
                Exit Function
            End If
            If pExistente.NomeProduto <> pApi.NomeProduto Then
                Exit Function
            End If
            If pExistente.NomeErp <> pApi.NomeErp Then
                Exit Function
            End If
            If pExistente.InformacoesAdicionais <> pApi.InformacoesAdicionais Then
                Exit Function
            End If
            If pExistente.InformacoesComplementares <> pApi.InformacoesComplementares Then
                Exit Function
            End If
            If pExistente.AdditionalDescription <> pApi.AdditionalDescription Then
                Exit Function
            End If
            If pExistente.PontoCriticoAtencao <> pApi.PontoCriticoAtencao Then
                Exit Function
            End If
            If pExistente.Dimensoes <> pApi.Dimensoes Then
                Exit Function
            End If
            If pExistente.CodMarca <> pApi.CodMarca Then
                Exit Function
            End If
            If pExistente.CodMarcaErp <> pApi.CodMarcaErp Then
                Exit Function
            End If
            If pExistente.NomeMarca <> pApi.NomeMarca Then
                Exit Function
            End If
            If pExistente.CodLinha <> pApi.CodLinha Then
                Exit Function
            End If
            If pExistente.NomeLinha <> pApi.NomeLinha Then
                Exit Function
            End If
            If pExistente.CodFamilia <> pApi.CodFamilia Then
                Exit Function
            End If
            If pExistente.NomeFamilia <> pApi.NomeFamilia Then
                Exit Function
            End If
            If pExistente.CodFabricante <> pApi.CodFabricante Then
                Exit Function
            End If
            If pExistente.Ean <> pApi.Ean Then
                Exit Function
            End If
            If pExistente.Gtin <> pApi.Gtin Then
                Exit Function
            End If
            If pExistente.Ncm <> pApi.Ncm Then
                Exit Function
            End If
            If pExistente.Cest <> pApi.Cest Then
                Exit Function
            End If
            If pExistente.Origem <> pApi.Origem Then
                Exit Function
            End If
            If pExistente.OrigemLabel <> pApi.OrigemLabel Then
                Exit Function
            End If
            If pExistente.Anp <> pApi.Anp Then
                Exit Function
            End If
            If pExistente.AnpLabel <> pApi.AnpLabel Then
                Exit Function
            End If
            If pExistente.PesoLiquido <> pApi.PesoLiquido Then
                Exit Function
            End If
            If pExistente.PesoBruto <> pApi.PesoBruto Then
                Exit Function
            End If
            If pExistente.Volume <> pApi.Volume Then
                Exit Function
            End If
            If pExistente.Litros <> pApi.Litros Then
                Exit Function
            End If
            If pExistente.Tamanho <> pApi.Tamanho Then
                Exit Function
            End If
            If pExistente.Material <> pApi.Material Then
                Exit Function
            End If
            If pExistente.Tipo <> pApi.Tipo Then
                Exit Function
            End If
            If pExistente.MedidaVenda <> pApi.MedidaVenda Then
                Exit Function
            End If
            If pExistente.GarantiaDias <> pApi.GarantiaDias Then
                Exit Function
            End If
            If pExistente.FracaoFabrica <> pApi.FracaoFabrica Then
                Exit Function
            End If
            If pExistente.FracaoLoja <> pApi.FracaoLoja Then
                Exit Function
            End If
            If pExistente.Status <> pApi.Status Then
                Exit Function
            End If
            If pExistente.ErpHandle <> pApi.ErpHandle Then
                Exit Function
            End If
            If pExistente.Leadtime <> pApi.Leadtime Then
                Exit Function
            End If
            If pExistente.Ativo <> pApi.Ativo Then
                Exit Function
            End If
            If pExistente.Descontinuado <> pApi.Descontinuado Then
                Exit Function
            End If
            If pExistente.Bloqueado <> pApi.Bloqueado Then
                Exit Function
            End If
            If pExistente.Confiavel <> pApi.Confiavel Then
                Exit Function
            End If
            If pExistente.Sugerido <> pApi.Sugerido Then
                Exit Function
            End If
            If pExistente.Lancamento <> pApi.Lancamento Then
                Exit Function
            End If
            If pExistente.OnDemand <> pApi.OnDemand Then
                Exit Function
            End If
            If pExistente.OnDemandLabel <> pApi.OnDemandLabel Then
                Exit Function
            End If
            If pExistente.MotivoDescontinuado <> pApi.MotivoDescontinuado Then
                Exit Function
            End If
            If pExistente.ParcialmenteSimilar <> pApi.ParcialmenteSimilar Then
                Exit Function
            End If
            If pExistente.HasRestrictions <> pApi.HasRestrictions Then
                Exit Function
            End If
            If pExistente.PrazoEspecial <> pApi.PrazoEspecial Then
                Exit Function
            End If

            CadastroTemAlteracao = False
        End Function

        Function PersistirImagensProdutoDeCampos(pCna As Integer, pUrlReal As String, pUrlIlustrativa As String, pTecnicasBlob As String, pUsarTransacao As Boolean) As Boolean
            Dim _imagens As RedeAncoraProdutoImagensModel = NULL
            Dim _seqReal As Integer = 0
            Dim _seqIlustrativa As Integer = 0
            Dim _seqTecnica As Integer = 0
            Dim _result As Boolean = False

            Try
                If pCna > 0 Then
                    _imagens = New RedeAncoraProdutoImagensModel()
                    me.AdicionarImagemUrl(_imagens, pCna, RedeAncoraProdutoImagemTipo.Real(), _seqReal, pUrlReal)
                    me.AdicionarImagemUrl(_imagens, pCna, RedeAncoraProdutoImagemTipo.Ilustrativa(), _seqIlustrativa, pUrlIlustrativa)
                    me.AdicionarImagensTecnicasDeBlob(_imagens, pCna, pTecnicasBlob, _seqTecnica)

                    If _imagens.Length <= 0 Then
                        _imagens.Free()
                        _imagens = NULL
                        _result = False
                    Else
                        If pUsarTransacao Then
                            me._imagemRepository.SubstituirPorCna(pCna, _imagens)
                        Else
                            me._imagemRepository.SubstituirPorCnaSemTransacao(pCna, _imagens)
                        End If

                        _imagens.Free()
                        _imagens = NULL
                        _result = True
                    End If
                End If
            Catch ex As Exception
                If Assigned(_imagens) Then
                    _imagens.Free()
                End If

                Throw New System.Exception("Erro ao persistir imagens do produto Rede Ancora: " & ex._getMessage())
            End Try

            PersistirImagensProdutoDeCampos = _result
        End Function

        Private Sub AdicionarImagensTecnicasDeBlob(pImagens As RedeAncoraProdutoImagensModel, pCna As Integer, pBlob As String, ByRef pSequencia As Integer)
            Dim _len As Integer = 0
            Dim _i As Integer = 1
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _url As String = ""
            Dim _escape As Boolean = False
            Dim _inUrl As Boolean = False
            Dim _qtd As Integer = 0

            If pBlob.Trim() = "" Then
                Exit Sub
            End If

            _len = Len(pBlob)

            While _i <= _len
                If _qtd >= 20 Then
                    Exit Sub
                End If

                _ch = Mid(pBlob, _i, 1)

                If _inUrl Then
                    If _escape Then
                        _url = _url & _ch
                        _escape = False
                    Else
                        If _ch = "\" Then
                            _escape = True
                        Else
                            If _ch = _q Then
                                me.AdicionarImagemUrl(pImagens, pCna, RedeAncoraProdutoImagemTipo.Tecnica(), pSequencia, _url)
                                _qtd = _qtd + 1
                                _inUrl = False
                                _url = ""
                            Else
                                _url = _url & _ch
                            End If
                        End If
                    End If
                Else
                    If _ch = _q Then
                        _inUrl = True
                        _url = ""
                        _escape = False
                    End If
                End If

                _i = _i + 1
            Wend
        End Sub

        Private Function UpsertProdutoAncoraDeModelo(pApiModel As RedeAncoraProdutoVinculoModel, pOrigem As String, pUsarTransacao As Boolean) As Integer
            Dim _existente As RedeAncoraProdutoVinculoModel = NULL
            Dim _result As Integer = 0

            Try
                _existente = New RedeAncoraProdutoVinculoModel()

                If me._vinculoRepository.TryObterPorCna(pApiModel.Cna, _existente) Then
                    If me.ProdutoTemAlteracao(_existente, pApiModel) Then
                        pApiModel.Ativo = "S"

                        If pUsarTransacao Then
                            me._vinculoRepository.AtualizarMetadadosApi(pApiModel)
                        Else
                            me._vinculoRepository.AtualizarMetadadosApiSemTransacao(pApiModel)
                        End If

                        _result = 2
                    Else
                        _result = 3
                    End If
                Else
                    pApiModel.Ativo = "S"
                    pApiModel.OrigemVinculo = pOrigem

                    If pUsarTransacao Then
                        me._vinculoRepository.Salvar(pApiModel)
                    Else
                        me._vinculoRepository.SalvarSemTransacao(pApiModel)
                    End If

                    _result = 1
                End If

                _existente.Free()
                _existente = NULL
            Catch ex As Exception
                If Assigned(_existente) Then
                    _existente.Free()
                End If

                Throw ex
            End Try

            UpsertProdutoAncoraDeModelo = _result
        End Function

        Private Function ProdutoTemAlteracao(pExistente As RedeAncoraProdutoVinculoModel, pApi As RedeAncoraProdutoVinculoModel) As Boolean
            If pExistente.CodigoAncora <> pApi.CodigoAncora Then
                ProdutoTemAlteracao = True
                Exit Function
            End If

            If pExistente.DescricaoAncora <> pApi.DescricaoAncora Then
                ProdutoTemAlteracao = True
                Exit Function
            End If

            If pExistente.CodMarca <> pApi.CodMarca Then
                ProdutoTemAlteracao = True
                Exit Function
            End If

            If pExistente.CodLinha <> pApi.CodLinha Then
                ProdutoTemAlteracao = True
                Exit Function
            End If

            If pExistente.CodFamilia <> pApi.CodFamilia Then
                ProdutoTemAlteracao = True
                Exit Function
            End If

            If pExistente.Ativo <> "S" Then
                ProdutoTemAlteracao = True
                Exit Function
            End If
        End Function

        Private Function ProcessarProdutoAncoraPorBusca(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCna As Integer, pCodigo As String, pQuery As String, pCodProduto As Integer, pOrigem As String) As RedeAncoraProdutoVinculoModel
            Dim _body As String = ""
            Dim _json As TJSONObject = NULL
            Dim _data As TJSONArray = NULL
            Dim _itemJson As TJSONObject = NULL
            Dim _model As RedeAncoraProdutoVinculoModel = NULL

            Try
                _body = me.BuscarProdutoFullSearch(pCodUsuario, pCodCentroDistribuicao, pCna, pCodigo, pQuery)
                _json = New TJSONObject(_body)
                _data = RedeAncoraJsonHelper.ObterDataArray(_json)

                If Not Assigned(_data) Then
                    Throw New System.Exception("Nenhum produto encontrado na Rede Ancora para cadastro")
                End If

                If _data.Length() <= 0 Then
                    Throw New System.Exception("Nenhum produto encontrado na Rede Ancora para cadastro")
                End If

                _itemJson = _data.GetJSONObject(0)
                _model = me.MapearProdutoAncoraDeJson(_itemJson, pCna)

                If pCodProduto > 0 Then
                    _model.CodProduto = pCodProduto
                    _model.Ativo = "S"
                    _model.OrigemVinculo = pOrigem
                    me.SalvarVinculo(_model)
                Else
                    Dim _cnaSalvo As Integer = _model.Cna

                    me.UpsertProdutoAncoraDeApiComTransacao(_itemJson, pOrigem, True)
                    _model.Free()
                    _model = me._vinculoRepository.ObterPorCna(_cnaSalvo)
                End If

                If _model.Cna > 0 Then
                    me.PersistirImagensProdutoDeApiComTransacao(_itemJson, _model.Cna, True)
                End If

                _itemJson.Free()
                _data.Free()
                _json.Free()
                ProcessarProdutoAncoraPorBusca = _model
            Catch ex As Exception
                If Assigned(_model) Then
                    _model.Free()
                End If

                If Assigned(_itemJson) Then
                    _itemJson.Free()
                End If

                If Assigned(_data) Then
                    _data.Free()
                End If

                If Assigned(_json) Then
                    _json.Free()
                End If

                Throw New System.Exception("Erro ao processar produto Ancora por busca: " + ex._getMessage())
            End Try
        End Function

        Private Function FlagDeBooleanJson(pJson As TJSONObject, pKey As String) As String
            Dim _texto As String = RedeAncoraJsonHelper.ObterTextoJson(pJson, pKey)

            If _texto.Trim() = "" Then
                FlagDeBooleanJson = ""
            Else
                If RedeAncoraJsonHelper.ObterBooleanJson(pJson, pKey) Then
                    FlagDeBooleanJson = "S"
                Else
                    FlagDeBooleanJson = "N"
                End If
            End If
        End Function

        Private Function CoalesceTexto(pAtual As String, pNovo As String) As String
            If pAtual.Trim() <> "" Then
                CoalesceTexto = pAtual
            Else
                CoalesceTexto = pNovo
            End If
        End Function

        Private Function CoalesceInteiro(pAtual As Integer, pNovo As Integer) As Integer
            If pAtual > 0 Then
                CoalesceInteiro = pAtual
            Else
                CoalesceInteiro = pNovo
            End If
        End Function

        Private Function CoalesceDecimal(pAtual As Double, pNovo As Double) As Double
            If pAtual <> 0 Then
                CoalesceDecimal = pAtual
            Else
                CoalesceDecimal = pNovo
            End If
        End Function

        Private Sub PreencherCadastroDeObjetoJson(pJson As TJSONObject, pCadastro As RedeAncoraProdutoModel)
            pCadastro.Cna = me.CoalesceInteiro(pCadastro.Cna, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "cna"))
            pCadastro.CatalogoId = me.CoalesceInteiro(pCadastro.CatalogoId, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "catalogo_id"))
            pCadastro.Csa = me.CoalesceTexto(pCadastro.Csa, RedeAncoraJsonHelper.ObterTextoJson(pJson, "csa"))
            pCadastro.Cnl = me.CoalesceTexto(pCadastro.Cnl, RedeAncoraJsonHelper.ObterTextoJson(pJson, "cnl"))
            pCadastro.CodigoReferencia = me.CoalesceTexto(pCadastro.CodigoReferencia, RedeAncoraJsonHelper.ObterTextoJson(pJson, "codigoReferencia"))
            pCadastro.CodigoReferencia = me.CoalesceTexto(pCadastro.CodigoReferencia, RedeAncoraJsonHelper.ObterTextoJson(pJson, "code"))
            pCadastro.CodeEdi = me.CoalesceTexto(pCadastro.CodeEdi, RedeAncoraJsonHelper.ObterTextoJson(pJson, "code_edi"))
            pCadastro.CodeManufacturer = me.CoalesceTexto(pCadastro.CodeManufacturer, RedeAncoraJsonHelper.ObterTextoJson(pJson, "code_manufacturer"))
            pCadastro.NomeProduto = me.CoalesceTexto(pCadastro.NomeProduto, RedeAncoraJsonHelper.ObterTextoJson(pJson, "nomeProduto"))
            pCadastro.NomeProduto = me.CoalesceTexto(pCadastro.NomeProduto, RedeAncoraJsonHelper.ObterTextoJson(pJson, "description"))
            pCadastro.NomeErp = me.CoalesceTexto(pCadastro.NomeErp, RedeAncoraJsonHelper.ObterTextoJson(pJson, "nome"))
            pCadastro.NomeErp = me.CoalesceTexto(pCadastro.NomeErp, RedeAncoraJsonHelper.ObterTextoJson(pJson, "name"))
            pCadastro.InformacoesAdicionais = me.CoalesceTexto(pCadastro.InformacoesAdicionais, RedeAncoraJsonHelper.ObterTextoJson(pJson, "informacoesAdicionais"))
            pCadastro.InformacoesComplementares = me.CoalesceTexto(pCadastro.InformacoesComplementares, RedeAncoraJsonHelper.ObterTextoJson(pJson, "informacoesComplementares"))
            pCadastro.AdditionalDescription = me.CoalesceTexto(pCadastro.AdditionalDescription, RedeAncoraJsonHelper.ObterTextoJson(pJson, "additional_description"))
            pCadastro.PontoCriticoAtencao = me.CoalesceTexto(pCadastro.PontoCriticoAtencao, RedeAncoraJsonHelper.ObterTextoJson(pJson, "pontoCriticoAtencao"))
            pCadastro.Dimensoes = me.CoalesceTexto(pCadastro.Dimensoes, RedeAncoraJsonHelper.ObterTextoJson(pJson, "dimensoes"))
            pCadastro.CodMarca = me.CoalesceInteiro(pCadastro.CodMarca, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "marcaId"))
            pCadastro.CodMarcaErp = me.CoalesceInteiro(pCadastro.CodMarcaErp, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "brand_id"))
            pCadastro.NomeMarca = me.CoalesceTexto(pCadastro.NomeMarca, RedeAncoraJsonHelper.ObterTextoJson(pJson, "marca"))
            pCadastro.NomeMarca = me.CoalesceTexto(pCadastro.NomeMarca, RedeAncoraJsonHelper.ObterTextoJson(pJson, "brand"))
            pCadastro.CodLinha = me.CoalesceInteiro(pCadastro.CodLinha, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "line"))
            pCadastro.CodLinha = me.CoalesceInteiro(pCadastro.CodLinha, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "line_id"))
            pCadastro.NomeLinha = me.CoalesceTexto(pCadastro.NomeLinha, RedeAncoraJsonHelper.ObterTextoJson(pJson, "line_name"))
            pCadastro.CodFamilia = me.CoalesceInteiro(pCadastro.CodFamilia, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "family"))
            pCadastro.CodFamilia = me.CoalesceInteiro(pCadastro.CodFamilia, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "family_id"))
            pCadastro.NomeFamilia = me.CoalesceTexto(pCadastro.NomeFamilia, RedeAncoraJsonHelper.ObterTextoJson(pJson, "family_name"))
            pCadastro.CodFabricante = me.CoalesceInteiro(pCadastro.CodFabricante, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "manufacturer_id"))
            pCadastro.CodFabricante = me.CoalesceInteiro(pCadastro.CodFabricante, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "fabricante"))
            pCadastro.Ean = me.CoalesceTexto(pCadastro.Ean, RedeAncoraJsonHelper.ObterTextoJson(pJson, "ean"))
            pCadastro.Gtin = me.CoalesceTexto(pCadastro.Gtin, RedeAncoraJsonHelper.ObterTextoJson(pJson, "gtin"))
            pCadastro.Ncm = me.CoalesceTexto(pCadastro.Ncm, RedeAncoraJsonHelper.ObterTextoJson(pJson, "ncm"))
            pCadastro.Cest = me.CoalesceTexto(pCadastro.Cest, RedeAncoraJsonHelper.ObterTextoJson(pJson, "cest"))
            pCadastro.Origem = me.CoalesceTexto(pCadastro.Origem, RedeAncoraJsonHelper.ObterTextoJson(pJson, "origem"))
            pCadastro.OrigemLabel = me.CoalesceTexto(pCadastro.OrigemLabel, RedeAncoraJsonHelper.ObterTextoJson(pJson, "origem_label"))
            pCadastro.Anp = me.CoalesceInteiro(pCadastro.Anp, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "anp"))
            pCadastro.AnpLabel = me.CoalesceTexto(pCadastro.AnpLabel, RedeAncoraJsonHelper.ObterTextoJson(pJson, "anp_label"))
            pCadastro.PesoLiquido = me.CoalesceDecimal(pCadastro.PesoLiquido, RedeAncoraJsonHelper.ObterDecimalJson(pJson, "peso_liquido"))
            pCadastro.PesoLiquido = me.CoalesceDecimal(pCadastro.PesoLiquido, RedeAncoraJsonHelper.ObterDecimalJson(pJson, "net_weight"))
            pCadastro.PesoBruto = me.CoalesceDecimal(pCadastro.PesoBruto, RedeAncoraJsonHelper.ObterDecimalJson(pJson, "peso_bruto"))
            pCadastro.PesoBruto = me.CoalesceDecimal(pCadastro.PesoBruto, RedeAncoraJsonHelper.ObterDecimalJson(pJson, "gross_weight"))
            pCadastro.Volume = me.CoalesceDecimal(pCadastro.Volume, RedeAncoraJsonHelper.ObterDecimalJson(pJson, "volume"))
            pCadastro.Litros = me.CoalesceDecimal(pCadastro.Litros, RedeAncoraJsonHelper.ObterDecimalJson(pJson, "liters"))
            pCadastro.Tamanho = me.CoalesceTexto(pCadastro.Tamanho, RedeAncoraJsonHelper.ObterTextoJson(pJson, "tamanho"))
            pCadastro.Material = me.CoalesceTexto(pCadastro.Material, RedeAncoraJsonHelper.ObterTextoJson(pJson, "material"))
            pCadastro.Tipo = me.CoalesceInteiro(pCadastro.Tipo, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "tipo"))
            pCadastro.MedidaVenda = me.CoalesceTexto(pCadastro.MedidaVenda, RedeAncoraJsonHelper.ObterTextoJson(pJson, "medida_venda"))
            pCadastro.GarantiaDias = me.CoalesceInteiro(pCadastro.GarantiaDias, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "garantia_dias"))
            pCadastro.GarantiaDias = me.CoalesceInteiro(pCadastro.GarantiaDias, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "warranty"))
            pCadastro.FracaoFabrica = me.CoalesceInteiro(pCadastro.FracaoFabrica, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "fracao_fabrica"))
            pCadastro.FracaoLoja = me.CoalesceInteiro(pCadastro.FracaoLoja, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "fracao_loja"))
            pCadastro.Status = me.CoalesceInteiro(pCadastro.Status, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "status"))
            pCadastro.ErpHandle = me.CoalesceInteiro(pCadastro.ErpHandle, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "erp_handle"))
            pCadastro.ErpHandle = me.CoalesceInteiro(pCadastro.ErpHandle, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "handle"))
            pCadastro.Leadtime = me.CoalesceInteiro(pCadastro.Leadtime, RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pJson, "leadtime"))
            pCadastro.OnDemandLabel = me.CoalesceTexto(pCadastro.OnDemandLabel, RedeAncoraJsonHelper.ObterTextoJson(pJson, "on_demand_label"))
            pCadastro.MotivoDescontinuado = me.CoalesceTexto(pCadastro.MotivoDescontinuado, RedeAncoraJsonHelper.ObterTextoJson(pJson, "motivo_descontinuado"))

            If pCadastro.Descontinuado = "" Then
                pCadastro.Descontinuado = me.FlagDeBooleanJson(pJson, "descontinuado")
            End If
            If pCadastro.Bloqueado = "" Then
                pCadastro.Bloqueado = me.FlagDeBooleanJson(pJson, "bloqueado")
            End If
            If pCadastro.Confiavel = "" Then
                pCadastro.Confiavel = me.FlagDeBooleanJson(pJson, "confiavel")
            End If
            If pCadastro.Sugerido = "" Then
                pCadastro.Sugerido = me.FlagDeBooleanJson(pJson, "sugerido")
            End If
            If pCadastro.Lancamento = "" Then
                pCadastro.Lancamento = me.FlagDeBooleanJson(pJson, "lancamento")
            End If
            If pCadastro.OnDemand = "" Then
                pCadastro.OnDemand = me.FlagDeBooleanJson(pJson, "on_demand")
            End If
            If pCadastro.ParcialmenteSimilar = "" Then
                pCadastro.ParcialmenteSimilar = me.FlagDeBooleanJson(pJson, "parcialmente_similar")
            End If
            If pCadastro.HasRestrictions = "" Then
                pCadastro.HasRestrictions = me.FlagDeBooleanJson(pJson, "has_restrictions")
            End If
            If pCadastro.PrazoEspecial = "" Then
                pCadastro.PrazoEspecial = me.FlagDeBooleanJson(pJson, "prazo_especial")
            End If
            If pCadastro.Ativo = "" Then
                pCadastro.Ativo = me.FlagDeBooleanJson(pJson, "ativo")
            End If
        End Sub

        Private Function MapearProdutoCadastroDeJson(pItemJson As TJSONObject, pCna As Integer) As RedeAncoraProdutoModel
            Dim _cadastro As New RedeAncoraProdutoModel()
            Dim _details As TJSONObject = NULL

            Try
                _cadastro.Cna = pCna
                _cadastro.Ativo = ""
                me.PreencherCadastroDeObjetoJson(pItemJson, _cadastro)
                _details = RedeAncoraJsonHelper.ObterFilhoJson(pItemJson, "details")

                If Assigned(_details) Then
                    me.PreencherCadastroDeObjetoJson(_details, _cadastro)
                    _details.Free()
                    _details = NULL
                End If

                If _cadastro.Ativo.Trim() = "" Then
                    _cadastro.Ativo = "S"
                End If

                If _cadastro.Cna <= 0 Then
                    Throw New System.Exception("CNA nao encontrado na resposta de produto da Rede Ancora")
                End If

                If _cadastro.NomeProduto.Trim() = "" Then
                    _cadastro.NomeProduto = _cadastro.NomeErp
                End If

                MapearProdutoCadastroDeJson = _cadastro
            Catch ex As Exception
                If Assigned(_details) Then
                    _details.Free()
                End If

                If Assigned(_cadastro) Then
                    _cadastro.Free()
                End If

                Throw ex
            End Try
        End Function

        Private Function MapearProdutoAncoraDeJson(pItemJson As TJSONObject, pCna As Integer) As RedeAncoraProdutoVinculoModel
            Dim _model As New RedeAncoraProdutoVinculoModel()
            Dim _details As TJSONObject = NULL
            Dim _cnaResolvido As Integer = pCna

            If _cnaResolvido <= 0 Then
                _cnaResolvido = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pItemJson, "cna")
            End If

            _details = RedeAncoraJsonHelper.ObterFilhoJson(pItemJson, "details")

            If _cnaResolvido <= 0 Then
                If Assigned(_details) Then
                    _cnaResolvido = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(_details, "cna")
                End If
            End If

            If _cnaResolvido <= 0 Then
                If Assigned(_details) Then
                    _details.Free()
                End If

                Throw New System.Exception("CNA nao encontrado na resposta de produto da Rede Ancora")
            End If

            _model.Cna = _cnaResolvido
            _model.CodigoAncora = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "code")

            If _model.CodigoAncora = "" Then
                _model.CodigoAncora = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "codigoReferencia")
            End If

            _model.DescricaoAncora = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "description")

            If _model.DescricaoAncora = "" Then
                _model.DescricaoAncora = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "nomeProduto")
            End If

            _model.CodMarca = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pItemJson, "brand_id")

            If _model.CodMarca <= 0 Then
                _model.CodMarca = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pItemJson, "marcaId")
            End If

            _model.CodLinha = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pItemJson, "line_id")
            _model.CodFamilia = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pItemJson, "family_id")

            If Assigned(_details) Then
                If _model.CodigoAncora = "" Then
                    _model.CodigoAncora = RedeAncoraJsonHelper.ObterTextoJson(_details, "code")
                End If

                If _model.DescricaoAncora = "" Then
                    _model.DescricaoAncora = RedeAncoraJsonHelper.ObterTextoJson(_details, "description")

                    If _model.DescricaoAncora = "" Then
                        _model.DescricaoAncora = RedeAncoraJsonHelper.ObterTextoJson(_details, "name")
                    End If

                    If _model.DescricaoAncora = "" Then
                        _model.DescricaoAncora = RedeAncoraJsonHelper.ObterTextoJson(_details, "nome")
                    End If
                End If

                If _model.CodMarca <= 0 Then
                    _model.CodMarca = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(_details, "brand_id")
                End If

                If _model.CodLinha <= 0 Then
                    _model.CodLinha = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(_details, "line")
                End If

                If _model.CodFamilia <= 0 Then
                    _model.CodFamilia = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(_details, "family")
                End If

                _details.Free()
            End If

            MapearProdutoAncoraDeJson = _model
        End Function

        Private Function MontarPayloadPrecosEstoques(pCodCentroDistribuicao As Integer, pCnas As RedeAncoraProdutoCnasModel) As String
            MontarPayloadPrecosEstoques = "{" +_
                """empresa"":" + Parser.IntegerToString(pCodCentroDistribuicao) + "," +_
                """cnas"":" + me.MontarArrayCnasJson(pCnas) + "}"
        End Function

        Private Function MontarPayloadBulkSearch(pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pPagina As Integer, pTamanhoPagina As Integer) As String
            Dim _payload As String = ""

            _payload = "{" +_
                """empresa"":" + Parser.IntegerToString(pCodCentroDistribuicao) + "," +_
                """estado"":" + Parser.IntegerToString(pCodEstado) + "," +_
                """cnas"":" + me.MontarArrayCnasJson(pCnas)

            If pPagina > 0 Then
                _payload = _payload + ",""page"":" + Parser.IntegerToString(pPagina)
            End If

            If pTamanhoPagina > 0 Then
                _payload = _payload + ",""page_size"":" + Parser.IntegerToString(pTamanhoPagina)
            End If

            _payload = _payload + "}"
            MontarPayloadBulkSearch = _payload
        End Function

        Private Function MontarArrayCnasJson(pCnas As RedeAncoraProdutoCnasModel) As String
            Dim _itemsJson As String = ""
            Dim _i As Integer

            _itemsJson = "["
            For _i = 0 To pCnas.Length - 1
                If _i > 0 Then
                    _itemsJson = _itemsJson + ","
                End If

                _itemsJson = _itemsJson + """" + pCnas.Take(_i).ToString() + """"
            Next

            _itemsJson = _itemsJson + "]"
            MontarArrayCnasJson = _itemsJson
        End Function

        Private Function MapearPrecosEstoques(pResponse As HttpResponse) As RedeAncoraProdutoPrecosEstoqueModel
            Dim _body As String = ""
            Dim _result As RedeAncoraProdutoPrecosEstoqueModel = NULL
            Dim _ok As RedeAncoraProdutoPrecosEstoqueModel = NULL
            Dim _item As RedeAncoraProdutoPrecoEstoqueModel = NULL
            Dim _arrStart As Integer = 0
            Dim _elemStart As Integer = 0
            Dim _elemFim As Integer = 0
            Dim _i As Integer = 0
            Dim _cna As Integer = 0

            Try
                _body = pResponse.Body
                _arrStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlob(_body, "data")

                If _arrStart <= 0 Then
                    Throw New System.Exception("Resposta /products/prices-stocks sem array data")
                End If

                _result = New RedeAncoraProdutoPrecosEstoqueModel()

                For _i = 0 To 9999
                    _elemStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(_body, _arrStart, _i)

                    If _elemStart <= 0 Then
                        Exit For
                    End If

                    _elemFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _elemStart)

                    Try
                        _cna = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "cna", _elemStart, _elemFim)

                        If _cna <= 0 Then
                            RedeAncoraHttpErroHelper.RegistrarFalha("POST /products/prices-stocks item", 200, "cna ausente ou invalido")
                        Else
                            _item = New RedeAncoraProdutoPrecoEstoqueModel()
                            _item.Cna = _cna
                            _item.CodCentroDistribuicao = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "empresa", _elemStart, _elemFim)
                            _item.CodEstado = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "estado", _elemStart, _elemFim)
                            _item.QtdDisponivel = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "qtd_disponivel", _elemStart, _elemFim)
                            _item.QtdProjetada = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(_body, "qtd_projetada", _elemStart, _elemFim)
                            _item.PrecoTabela = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(_body, "preco_tabela", _elemStart, _elemFim)
                            _item.StTabela = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(_body, "st_tabela", _elemStart, _elemFim)
                            _item.PrecoCrossDocking = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(_body, "preco_cross_docking", _elemStart, _elemFim)
                            _item.PrecoCompraJunto = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(_body, "preco_compra_junto", _elemStart, _elemFim)
                            _result.Push(_item)
                            _item = NULL
                        End If
                    Catch exItem As Exception
                        RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.MapearPrecosEstoques.item", exItem)

                        If Assigned(_item) Then
                            _item.Free()
                            _item = NULL
                        End If
                    End Try
                Next

                _ok = _result
                _result = NULL
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.MapearPrecosEstoques", ex)

                If Assigned(_item) Then
                    _item.Free()
                    _item = NULL
                End If

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                Throw New System.Exception("Erro ao mapear /products/prices-stocks: " & ex._getMessage())
            End Try

            MapearPrecosEstoques = _ok
        End Function

        Private Function ExecutarGetPassThrough(pCodUsuario As Integer, pUrl As String, pOperacao As String) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(pUrl)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem(pOperacao, _response.StatusCode, _response.Body))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson(pOperacao, _response.StatusCode, _response.Body)

                ExecutarGetPassThrough = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService." & pOperacao, ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw ex
            End Try
        End Function

        Private Function ExecutarPostPassThrough(pCodUsuario As Integer, pUrl As String, pPayload As String, pOperacao As String) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.PostJson(pUrl, pPayload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem(pOperacao, _response.StatusCode, _response.Body))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson(pOperacao, _response.StatusCode, _response.Body)

                ExecutarPostPassThrough = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService." & pOperacao, ex)

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

        Private Function MontarArrayCodigosJson(pCodigos As RedeAncoraProdutoCodigosModel) As String
            Dim _itemsJson As String = ""
            Dim _i As Integer

            _itemsJson = "["
            For _i = 0 To pCodigos.Length - 1
                If _i > 0 Then
                    _itemsJson = _itemsJson + ","
                End If

                _itemsJson = _itemsJson + """" + pCodigos.Take(_i) + """"
            Next

            _itemsJson = _itemsJson + "]"
            MontarArrayCodigosJson = _itemsJson
        End Function

        Function ListarImagensProdutoPorCna(pCna As Integer) As RedeAncoraProdutoImagensModel
            ListarImagensProdutoPorCna = me._imagemRepository.ListarPorCna(pCna)
        End Function

        Sub PersistirImagensProdutoDeApiSemTransacao(pItemJson As TJSONObject, pCna As Integer)
            me.PersistirImagensProdutoDeApiComTransacao(pItemJson, pCna, False)
        End Sub

        Function PersistirImagensProdutoDeApiComTransacao(pItemJson As TJSONObject, pCna As Integer, pUsarTransacao As Boolean) As Boolean
            Dim _imagens As RedeAncoraProdutoImagensModel = NULL

            Try
                If pCna <= 0 Then
                    PersistirImagensProdutoDeApiComTransacao = False
                    Exit Function
                End If

                _imagens = me.MapearImagensProdutoDeJson(pItemJson, pCna)

                If pUsarTransacao Then
                    me._imagemRepository.SubstituirPorCna(pCna, _imagens)
                Else
                    me._imagemRepository.SubstituirPorCnaSemTransacao(pCna, _imagens)
                End If

                PersistirImagensProdutoDeApiComTransacao = _imagens.Length > 0
                _imagens.Free()
            Catch ex As Exception
                If Assigned(_imagens) Then
                    _imagens.Free()
                End If

                Throw New System.Exception("Erro ao persistir imagens do produto Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function SincronizarImagensProdutosPorCnas(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pTamanhoChunk As Integer) As RedeAncoraProdutoImagemSincronizacaoResultadoModel
            Dim _resultado As New RedeAncoraProdutoImagemSincronizacaoResultadoModel()
            Dim _tamanhoChunk As Integer = pTamanhoChunk
            Dim _totalChunks As Integer = 0
            Dim _inicio As Integer = 0
            Dim _numeroChunk As Integer = 0
            Dim _chunk As RedeAncoraProdutoCnasModel = NULL

            Try
                pCnas.ValidarTodos()

                If pCodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("Centro de distribuicao invalido para sync de imagens")
                End If

                If pCodEstado <= 0 Then
                    Throw New System.Exception("CodEstado invalido para sync de imagens")
                End If

                If _tamanhoChunk <= 0 Then
                    _tamanhoChunk = RedeAncoraApiConfig.TamanhoChunkSincronizacaoProdutos()
                End If

                _resultado.DataInicio = DateTime()
                _resultado.QtdCnasSolicitados = pCnas.Length
                _totalChunks = me.CalcularTotalChunksImagens(pCnas.Length, _tamanhoChunk)
                _resultado.QtdChunks = _totalChunks

                While _inicio < pCnas.Length
                    _numeroChunk = _numeroChunk + 1
                    _chunk = me.ExtrairChunkImagens(pCnas, _inicio, _tamanhoChunk)

                    Try
                        me.ProcessarChunkImagens(pCodUsuario, pCodCentroDistribuicao, pCodEstado, _chunk, _numeroChunk, _resultado)
                    Catch exChunk As Exception
                        _resultado.RegistrarErroChunk(_numeroChunk, exChunk._getMessage())
                    End Try

                    _chunk.Free()
                    _chunk = NULL
                    _inicio = _inicio + _tamanhoChunk
                Wend

                _resultado.Finalizar()
                SincronizarImagensProdutosPorCnas = _resultado
            Catch ex As Exception
                If Assigned(_chunk) Then
                    _chunk.Free()
                End If

                If Assigned(_resultado) Then
                    _resultado.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar imagens de produtos Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Private Sub ProcessarChunkImagens(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pChunk As RedeAncoraProdutoCnasModel, pNumeroChunk As Integer, pResultado As RedeAncoraProdutoImagemSincronizacaoResultadoModel)
            Dim _body As String = ""
            Dim _json As TJSONObject = NULL
            Dim _data As TJSONArray = NULL
            Dim _i As Integer
            Dim _itemJson As TJSONObject = NULL
            Dim _cna As Integer
            Dim _comImagem As Boolean = False

            Try
                pChunk.ValidarTodos()
                _body = me.BuscarProdutoBulkSearch(pCodUsuario, pCodCentroDistribuicao, pCodEstado, pChunk, 1, pChunk.Length)
                pResultado.QtdChunksApi = pResultado.QtdChunksApi + 1
                _json = New TJSONObject(_body)
                _data = RedeAncoraJsonHelper.ObterDataArray(_json)

                If Assigned(_data) Then
                    For _i = 0 To _data.Length() - 1
                        _itemJson = _data.GetJSONObject(_i)
                        _cna = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(_itemJson, "cna")

                        If _cna > 0 Then
                            _comImagem = me.PersistirImagensProdutoDeApiComTransacao(_itemJson, _cna, True)
                            pResultado.QtdProcessados = pResultado.QtdProcessados + 1

                            If _comImagem Then
                                pResultado.QtdComImagem = pResultado.QtdComImagem + 1
                            Else
                                pResultado.QtdSemImagem = pResultado.QtdSemImagem + 1
                            End If
                        End If

                        _itemJson.Free()
                        _itemJson = NULL
                    Next

                    _data.Free()
                    _data = NULL
                End If

                _json.Free()
                _json = NULL
            Catch ex As Exception
                If Assigned(_itemJson) Then
                    _itemJson.Free()
                End If

                If Assigned(_data) Then
                    _data.Free()
                End If

                If Assigned(_json) Then
                    _json.Free()
                End If

                Throw New System.Exception("Chunk " + Parser.IntegerToString(pNumeroChunk) + ": " + ex._getMessage())
            End Try
        End Sub

        Private Function ExtrairChunkImagens(pCnas As RedeAncoraProdutoCnasModel, pInicio As Integer, pTamanho As Integer) As RedeAncoraProdutoCnasModel
            Dim _chunk As New RedeAncoraProdutoCnasModel()
            Dim _fim As Integer = pInicio + pTamanho - 1
            Dim _i As Integer

            If _fim > pCnas.Length - 1 Then
                _fim = pCnas.Length - 1
            End If

            For _i = pInicio To _fim
                _chunk.Push(pCnas.Take(_i))
            Next

            ExtrairChunkImagens = _chunk
        End Function

        Private Function CalcularTotalChunksImagens(pTotalCnas As Integer, pTamanhoChunk As Integer) As Integer
            If pTamanhoChunk <= 0 Then
                CalcularTotalChunksImagens = 0
                Exit Function
            End If

            CalcularTotalChunksImagens = Int((pTotalCnas + pTamanhoChunk - 1) / pTamanhoChunk)
        End Function

        Private Function MapearImagensProdutoDeJson(pItemJson As TJSONObject, pCna As Integer) As RedeAncoraProdutoImagensModel
            Dim _result As New RedeAncoraProdutoImagensModel()
            Dim _sequenciaReal As Integer = 0
            Dim _sequenciaIlustrativa As Integer = 0
            Dim _sequenciaTecnica As Integer = 0
            Dim _url As String = ""
            Dim _tecnicas As TJSONArray = NULL
            Dim _wrapper As TJSONObject = NULL
            Dim _tecnicasBlob As String = ""
            Dim _elem As String = ""
            Dim _quote As String = CStr(Chr(34))
            Dim _i As Integer
            Dim _mapped As RedeAncoraProdutoImagensModel = NULL

            Try
                _url = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "imagemReal")
                me.AdicionarImagemUrl(_result, pCna, RedeAncoraProdutoImagemTipo.Real(), _sequenciaReal, _url)

                _url = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "imagemIlustrativa")
                me.AdicionarImagemUrl(_result, pCna, RedeAncoraProdutoImagemTipo.Ilustrativa(), _sequenciaIlustrativa, _url)

                _tecnicas = RedeAncoraJsonHelper.ObterArrayJson(pItemJson, "imagensTecnicas")
                If Assigned(_tecnicas) Then
                    _tecnicasBlob = _tecnicas.ToString()
                    _tecnicas.Free()
                    _tecnicas = NULL

                    ' teto de seguranca (10000) contra loop infinito se ExtrairElementoArrayJson nao devolver vazio
                    For _i = 0 To 9999
                        _elem = RedeAncoraJsonHelper.ExtrairElementoArrayJson(_tecnicasBlob, _i)

                        If _elem = "" Then
                            Exit For
                        End If

                        _wrapper = New TJSONObject("{" + _quote + "v" + _quote + ":" + _elem + "}")
                        _url = RedeAncoraJsonHelper.ObterTextoJson(_wrapper, "v")
                        _wrapper.Free()
                        _wrapper = NULL
                        me.AdicionarImagemUrl(_result, pCna, RedeAncoraProdutoImagemTipo.Tecnica(), _sequenciaTecnica, _url)
                    Next
                End If

                _mapped = _result
                _result = NULL
            Catch ex As Exception
                If Assigned(_wrapper) Then
                    _wrapper.Free()
                    _wrapper = NULL
                End If

                If Assigned(_tecnicas) Then
                    _tecnicas.Free()
                    _tecnicas = NULL
                End If

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                Throw New System.Exception("Erro ao mapear imagens do produto Rede Ancora: " + ex._getMessage())
            End Try

            MapearImagensProdutoDeJson = _mapped
        End Function

        Private Sub AdicionarImagemUrl(pImagens As RedeAncoraProdutoImagensModel, pCna As Integer, pTipoImagem As String, ByRef pSequencia As Integer, pUrl As String)
            Dim _item As RedeAncoraProdutoImagemModel = NULL

            If Not me.UrlImagemValida(pUrl) Then
                Exit Sub
            End If

            pSequencia = pSequencia + 1
            _item = New RedeAncoraProdutoImagemModel()
            _item.Cna = pCna
            _item.Item = me.FormatarItemImagem(pSequencia)
            _item.TipoImagem = pTipoImagem
            _item.DataAtualizacao = DateTime()
            _item.Url = pUrl.Trim()
            pImagens.Push(_item)
        End Sub

        Private Function FormatarItemImagem(pSequencia As Integer) As String
            FormatarItemImagem = StringHelper.FillCharacterLeft(Parser.IntegerToString(pSequencia), "0", 5)
        End Function

        Private Function UrlImagemValida(pUrl As String) As Boolean
            Dim _url As String = pUrl.Trim().ToLower()

            If _url = "" Then
                UrlImagemValida = False
                Exit Function
            End If

            If _url.Contains("default.png") Then
                UrlImagemValida = False
                Exit Function
            End If

            UrlImagemValida = True
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._authService) Then
                    me._authService.Free()
                    me._authService = NULL
                End If

                If Assigned(me._vinculoRepository) Then
                    me._vinculoRepository.Free()
                    me._vinculoRepository = NULL
                End If

                If Assigned(me._produtoRepository) Then
                    me._produtoRepository.Free()
                    me._produtoRepository = NULL
                End If

                If Assigned(me._imagemRepository) Then
                    me._imagemRepository.Free()
                    me._imagemRepository = NULL
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
