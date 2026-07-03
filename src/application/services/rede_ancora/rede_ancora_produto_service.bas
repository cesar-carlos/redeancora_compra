Imports mod_tobject
Imports rede_ancora_api_config
Imports rede_ancora_url_helper
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_json_helper
Imports rede_ancora_produto_vinculo_model
Imports rede_ancora_produto_vinculo_repository
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

Namespace rede_ancora_produto_service
    Class RedeAncoraProdutoService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _vinculoRepository As RedeAncoraProdutoVinculoRepository
        Private _imagemRepository As RedeAncoraProdutoImagemRepository

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._vinculoRepository = New RedeAncoraProdutoVinculoRepository()
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
                    Throw New System.Exception("GET /products/conditions Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                ExecutarConsultaCondicoes = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
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
                    Throw New System.Exception("POST /products/prices-stocks Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                _result = me.MapearPrecosEstoques(_response)
                _response.Free()
                _api.Free()
                ConsultarPrecosEstoques = _result
            Catch ex As Exception
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

                _url = RedeAncoraApiConfig.IntegrationUrl("/products/full-search?empresa=" + Parser.IntegerToString(pCodCentroDistribuicao) + "&fields=details")
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "family", Parser.IntegerToString(pCodFamilia))
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "page", Parser.IntegerToString(pPagina))
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "page_size", Parser.IntegerToString(pTamanhoPagina))

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(_url)

                If Not _response.IsSuccess Then
                    Throw New System.Exception("GET /products/full-search Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                BuscarProdutoFullSearchPorFamilia = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro na busca full-search por familia Rede Ancora: " + ex._getMessage())
            End Try
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
                    Throw New System.Exception("GET /products/full-search Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                BuscarProdutoFullSearch = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
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
                    Throw New System.Exception("POST /products/bulk-search Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                BuscarProdutoBulkSearch = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
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
                    Throw New System.Exception("POST /products/warehouses Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                ConsultarCentrosComEstoque = _response.Body
                _payload.Free()
                _response.Free()
                _api.Free()
            Catch ex As Exception
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
        End Sub

        Sub SalvarVinculo(pModel As RedeAncoraProdutoVinculoModel)
            pModel.ValidateVinculo()
            me.SalvarProdutoAncora(pModel)
        End Sub

        Sub DesativarProdutoAncora(pCna As Integer)
            me._vinculoRepository.DesativarPorCna(pCna)
            me._imagemRepository.ExcluirPorCna(pCna)
        End Sub

        Sub DesativarProdutoAncoraSemTransacao(pCna As Integer)
            me._vinculoRepository.DesativarPorCnaSemTransacao(pCna)
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
            Dim _apiModel As RedeAncoraProdutoVinculoModel = NULL
            Dim _existente As RedeAncoraProdutoVinculoModel = NULL

            Try
                _apiModel = me.MapearProdutoAncoraDeJson(pItemJson, 0)
                _existente = New RedeAncoraProdutoVinculoModel()

                If me._vinculoRepository.TryObterPorCna(_apiModel.Cna, _existente) Then
                    If me.ProdutoTemAlteracao(_existente, _apiModel) Then
                        _apiModel.Ativo = "S"

                        If pUsarTransacao Then
                            me._vinculoRepository.AtualizarMetadadosApi(_apiModel)
                        Else
                            me._vinculoRepository.AtualizarMetadadosApiSemTransacao(_apiModel)
                        End If

                        UpsertProdutoAncoraDeApiComTransacao = 2
                    Else
                        UpsertProdutoAncoraDeApiComTransacao = 3
                    End If
                Else
                    _apiModel.Ativo = "S"
                    _apiModel.OrigemVinculo = pOrigem

                    If pUsarTransacao Then
                        me._vinculoRepository.Salvar(_apiModel)
                    Else
                        me._vinculoRepository.SalvarSemTransacao(_apiModel)
                    End If

                    UpsertProdutoAncoraDeApiComTransacao = 1
                End If

                _existente.Free()
                _apiModel.Free()
            Catch ex As Exception
                If Assigned(_existente) Then
                    _existente.Free()
                End If

                If Assigned(_apiModel) Then
                    _apiModel.Free()
                End If

                Throw New System.Exception("Erro ao persistir produto Ancora da API: " + ex._getMessage())
            End Try
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

                If Not Assigned(_data) Or _data.Length() <= 0 Then
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
            Dim _json As TJSONObject = NULL
            Dim _data As TJSONArray = NULL
            Dim _result As New RedeAncoraProdutoPrecosEstoqueModel()
            Dim _i As Integer

            _json = pResponse.BodyAsJsonObject()
            _data = RedeAncoraJsonHelper.ObterDataArray(_json)

            If Not Assigned(_data) Then
                _json.Free()
                Throw New System.Exception("Resposta /products/prices-stocks sem array data")
            End If

            For _i = 0 To _data.Length() - 1
                Dim _itemJson As TJSONObject = _data.GetJSONObject(_i)
                Dim _item As New RedeAncoraProdutoPrecoEstoqueModel()

                _item.Cna = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "cna")
                _item.CodCentroDistribuicao = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "empresa")
                _item.CodEstado = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "estado")
                _item.QtdDisponivel = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "qtd_disponivel")
                _item.QtdProjetada = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "qtd_projetada")
                _item.PrecoTabela = RedeAncoraJsonHelper.ObterDecimalJson(_itemJson, "preco_tabela")
                _item.StTabela = RedeAncoraJsonHelper.ObterDecimalJson(_itemJson, "st_tabela")
                _item.PrecoCrossDocking = RedeAncoraJsonHelper.ObterDecimalJson(_itemJson, "preco_cross_docking")
                _item.PrecoCompraJunto = RedeAncoraJsonHelper.ObterDecimalJson(_itemJson, "preco_compra_junto")
                _result.Push(_item)
                _itemJson.Free()
            Next

            _data.Free()
            _json.Free()
            MapearPrecosEstoques = _result
        End Function

        Private Function ExecutarGetPassThrough(pCodUsuario As Integer, pUrl As String, pOperacao As String) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(pUrl)

                If Not _response.IsSuccess Then
                    Throw New System.Exception("Erro HTTP " + pOperacao + ". HTTP " + Parser.IntegerToString(_response.StatusCode) + ": " + _response.Body)
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

        Private Function ExecutarPostPassThrough(pCodUsuario As Integer, pUrl As String, pPayload As String, pOperacao As String) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.PostJson(pUrl, pPayload)

                If Not _response.IsSuccess Then
                    Throw New System.Exception("Erro HTTP " + pOperacao + ". HTTP " + Parser.IntegerToString(_response.StatusCode) + ": " + _response.Body)
                End If

                ExecutarPostPassThrough = _response.Body
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
            Dim _i As Integer

            Try
                _url = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "imagemReal")
                me.AdicionarImagemUrl(_result, pCna, RedeAncoraProdutoImagemTipo.Real(), _sequenciaReal, _url)

                _url = RedeAncoraJsonHelper.ObterTextoJson(pItemJson, "imagemIlustrativa")
                me.AdicionarImagemUrl(_result, pCna, RedeAncoraProdutoImagemTipo.Ilustrativa(), _sequenciaIlustrativa, _url)

                _tecnicas = RedeAncoraJsonHelper.ObterArrayJson(pItemJson, "imagensTecnicas")
                If Assigned(_tecnicas) Then
                    For _i = 0 To _tecnicas.Length() - 1
                        _url = _tecnicas.GetString(_i)
                        me.AdicionarImagemUrl(_result, pCna, RedeAncoraProdutoImagemTipo.Tecnica(), _sequenciaTecnica, _url)
                    Next

                    _tecnicas.Free()
                    _tecnicas = NULL
                End If

                MapearImagensProdutoDeJson = _result
            Catch ex As Exception
                If Assigned(_tecnicas) Then
                    _tecnicas.Free()
                End If

                _result.Free()
                Throw New System.Exception("Erro ao mapear imagens do produto Rede Ancora: " + ex._getMessage())
            End Try
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
