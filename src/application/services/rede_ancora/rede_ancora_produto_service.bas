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
Imports rede_ancora_produto_full_search_filtro_model
Imports rede_ancora_produto_full_search_item_model
Imports rede_ancora_produto_full_search_itens_model
Imports rede_ancora_produto_full_search_resultado_model
Imports string_helper
Imports try_parser
Imports transactions
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
        ' Estado da leitura interativa. Nao e dono de _parsePreco.
        Private _parsePricesInicio As Integer
        Private _parsePricesFim As Integer
        Private _parseStocksInicio As Integer
        Private _parseStocksFim As Integer
        Private _parseTemPreco As Boolean
        Private _parseRegistrarBlocos As Boolean
        Private _parseAplicarCadastro As Boolean
        Private _parseCapturarPreco As Boolean
        Private _parsePreco As RedeAncoraProdutoPrecoEstoqueModel

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._vinculoRepository = New RedeAncoraProdutoVinculoRepository()
            me._produtoRepository = New RedeAncoraProdutoRepository()
            me._imagemRepository = New RedeAncoraProdutoImagemRepository()
            me._parsePricesInicio = 0
            me._parsePricesFim = 0
            me._parseStocksInicio = 0
            me._parseStocksFim = 0
            me._parseTemPreco = False
            me._parseRegistrarBlocos = False
            me._parseAplicarCadastro = False
            me._parseCapturarPreco = False
            me._parsePreco = NULL
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
            Dim _body As String = ""
            Dim _ok As String = ""

            Try
                If pCna <= 0 Then
                    Throw New System.Exception("Cna invalido para consulta de condicoes")
                End If

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                DiagStack.Push("conditions.GetRequest")
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/products/conditions/" + Parser.IntegerToString(pCna)))
                DiagStack.Pop()

                If Not Assigned(_response) Then
                    Throw New System.Exception("GET /products/conditions resposta nula")
                End If

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("GET /products/conditions", _response.StatusCode, _response.Body))
                End If

                _body = _response.Body
                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET /products/conditions", _response.StatusCode, _body)
                me.ExigirCorpoJsonContrato("GET /products/conditions", _body)
                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _ok = _body
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.ConsultarCondicoes", ex)

                If Assigned(_response) Then
                    _response.Free()
                    _response = NULL
                End If

                If Assigned(_api) Then
                    _api.Free()
                    _api = NULL
                End If

                Throw New System.Exception("Erro ao consultar condicoes do produto Rede Ancora: " + ex._getMessage())
            End Try

            ExecutarConsultaCondicoes = _ok
        End Function

        Function ConsultarPrecosEstoques(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCnas As RedeAncoraProdutoCnasModel) As RedeAncoraProdutoPrecosEstoqueModel
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _result As RedeAncoraProdutoPrecosEstoqueModel = NULL
            Dim _ok As RedeAncoraProdutoPrecosEstoqueModel = NULL

            Try
                pCnas.ValidarTodos()

                If pCodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("Centro de distribuicao invalido para prices-stocks")
                End If

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                DiagStack.Push("prices-stocks.PostJson")
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/products/prices-stocks"), me.MontarPayloadPrecosEstoques(pCodCentroDistribuicao, pCnas))
                DiagStack.Pop()

                If Not Assigned(_response) Then
                    Throw New System.Exception("POST /products/prices-stocks resposta nula")
                End If

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("POST /products/prices-stocks", _response.StatusCode, _response.Body))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("POST /products/prices-stocks", _response.StatusCode, _response.Body)
                me.ExigirCorpoJsonContrato("POST /products/prices-stocks", _response.Body)
                _result = me.MapearPrecosEstoques(_response)
                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _ok = _result
                _result = NULL
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.ConsultarPrecosEstoques", ex)

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                If Assigned(_response) Then
                    _response.Free()
                    _response = NULL
                End If

                If Assigned(_api) Then
                    _api.Free()
                    _api = NULL
                End If

                Throw New System.Exception("Erro ao consultar precos e estoques Rede Ancora: " + ex._getMessage())
            End Try

            ConsultarPrecosEstoques = _ok
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

        Function BuscarProdutoFullSearch(pFiltro As RedeAncoraProdutoFullSearchFiltroModel) As RedeAncoraProdutoFullSearchResultadoModel
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _url As String = ""
            Dim _body As String = ""
            Dim _fields As String = ""
            Dim _pagina As Integer = 0
            Dim _tamanho As Integer = 0
            Dim _result As RedeAncoraProdutoFullSearchResultadoModel = NULL
            Dim _ok As RedeAncoraProdutoFullSearchResultadoModel = NULL

            Try
                me.ValidarFiltroFullSearch(pFiltro)
                _pagina = me.ResolverPaginaFullSearch(pFiltro.Pagina)
                _tamanho = me.ResolverTamanhoPaginaFullSearch(pFiltro.TamanhoPagina)
                _fields = me.MontarFieldsFullSearch(pFiltro)
                _url = RedeAncoraApiConfig.IntegrationUrl("/products/full-search?empresa=" & Parser.IntegerToString(pFiltro.CodCentroDistribuicao))
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "fields", _fields)
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "page", Parser.IntegerToString(_pagina))
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "page_size", Parser.IntegerToString(_tamanho))

                If pFiltro.Cna > 0 Then
                    _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "cna", Parser.IntegerToString(pFiltro.Cna))
                End If

                If pFiltro.Codigo.Trim() <> "" Then
                    _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "code", pFiltro.Codigo.Trim())
                End If

                If pFiltro.Query.Trim() <> "" Then
                    _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "query", pFiltro.Query.Trim())
                End If

                If pFiltro.CodFamilia > 0 Then
                    _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "family", Parser.IntegerToString(pFiltro.CodFamilia))
                End If

                _api = New RedeAncoraApiClient(pFiltro.CodUsuario, me._authService)
                DiagStack.Push("full-search.GetRequest")
                _response = _api.GetRequest(_url)
                DiagStack.Pop()

                If Not Assigned(_response) Then
                    Throw New System.Exception("GET /products/full-search resposta nula")
                End If

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("GET /products/full-search", _response.StatusCode, _response.Body))
                End If

                _body = _response.Body
                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET /products/full-search", _response.StatusCode, _body)
                me.ExigirCorpoJsonContrato("GET /products/full-search", _body)
                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _result = me.MapearFullSearch(_body, _pagina, _tamanho)
                _ok = _result
                _result = NULL
            Catch ex As Exception
                DiagStack.DumpOnError(ex)
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.BuscarProdutoFullSearch", ex)

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                If Assigned(_response) Then
                    _response.Free()
                    _response = NULL
                End If

                If Assigned(_api) Then
                    _api.Free()
                    _api = NULL
                End If

                Throw New System.Exception("Erro na busca full-search Rede Ancora: " & DiagStack.FormatException(ex))
            End Try

            BuscarProdutoFullSearch = _ok
        End Function

        Private Sub ValidarFiltroFullSearch(pFiltro As RedeAncoraProdutoFullSearchFiltroModel)
            Dim _temFiltro As Boolean = False

            If Not Assigned(pFiltro) Then
                Throw New System.Exception("Filtro de full-search nao informado")
            End If

            If pFiltro.CodCentroDistribuicao <= 0 Then
                Throw New System.Exception("Centro de distribuicao invalido para full-search")
            End If

            If pFiltro.Cna > 0 Then
                _temFiltro = True
            End If

            If pFiltro.Codigo.Trim() <> "" Then
                _temFiltro = True
            End If

            If pFiltro.Query.Trim() <> "" Then
                _temFiltro = True
            End If

            If pFiltro.CodFamilia > 0 Then
                _temFiltro = True
            End If

            If Not _temFiltro Then
                Throw New System.Exception("Informe cna, codigo, query ou familia para full-search")
            End If

            If Not pFiltro.IncluirPrecos Then
                If Not pFiltro.IncluirEstoques Then
                    If Not pFiltro.IncluirDetalhes Then
                        Throw New System.Exception("Informe ao menos um bloco de fields para full-search")
                    End If
                End If
            End If
        End Sub

        Private Function ResolverPaginaFullSearch(pPagina As Integer) As Integer
            If pPagina <= 0 Then
                ResolverPaginaFullSearch = 1
            Else
                ResolverPaginaFullSearch = pPagina
            End If
        End Function

        Private Function ResolverTamanhoPaginaFullSearch(pTamanho As Integer) As Integer
            Dim _tamanho As Integer = 0

            If pTamanho <= 0 Then
                _tamanho = RedeAncoraApiConfig.TamanhoChunkSincronizacaoProdutos()

                If _tamanho <= 0 Then
                    _tamanho = 100
                End If

                If _tamanho > 100 Then
                    _tamanho = 100
                End If
            Else
                If pTamanho > 100 Then
                    Throw New System.Exception("Tamanho de pagina acima de 100 para full-search")
                End If

                _tamanho = pTamanho
            End If

            ResolverTamanhoPaginaFullSearch = _tamanho
        End Function

        Private Function MontarFieldsFullSearch(pFiltro As RedeAncoraProdutoFullSearchFiltroModel) As String
            Dim _fields As String = ""

            If pFiltro.IncluirPrecos Then
                _fields = "prices"
            End If

            If pFiltro.IncluirEstoques Then
                If _fields <> "" Then
                    _fields = _fields & ","
                End If

                _fields = _fields & "stocks"
            End If

            If pFiltro.IncluirDetalhes Then
                If _fields <> "" Then
                    _fields = _fields & ","
                End If

                _fields = _fields & "details"
            End If

            MontarFieldsFullSearch = _fields
        End Function

        Private Sub ExigirCorpoJsonContrato(pOperacao As String, pBody As String)
            Dim _texto As String = ""
            Dim _ch As String = ""
            Dim _ok As Boolean = False

            _texto = pBody.Trim()

            If _texto <> "" Then
                _ch = Mid(_texto, 1, 1)

                If _ch = "{" Then
                    _ok = True
                End If

                If _ch = "[" Then
                    _ok = True
                End If
            End If

            If Not _ok Then
                Throw New System.Exception(pOperacao & " resposta sem JSON")
            End If
        End Sub

        ' Uma passagem em janelas de 200 no body original. Nao copia o produto com Mid.
        Private Function MapearFullSearch(pBody As String, pPagina As Integer, pTamanhoPagina As Integer) As RedeAncoraProdutoFullSearchResultadoModel
            Dim _result As RedeAncoraProdutoFullSearchResultadoModel = NULL
            Dim _ok As RedeAncoraProdutoFullSearchResultadoModel = NULL
            Dim _item As RedeAncoraProdutoFullSearchItemModel = NULL
            Dim _arrStart As Integer = 0
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _janela As String = ""
            Dim _idxAbre As Integer = 0
            Dim _objStart As Integer = 0
            Dim _objFim As Integer = 0
            Dim _passos As Integer = 0
            Dim _acabou As Boolean = False
            Dim _n As Integer = 0

            Try
                _arrStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlob(pBody, "data")

                If _arrStart <= 0 Then
                    Throw New System.Exception("Resposta /products/full-search sem array data")
                End If

                _result = New RedeAncoraProdutoFullSearchResultadoModel()
                _bodyLen = Len(pBody)
                _pos = _arrStart + 1

                While _pos <= _bodyLen
                    If _acabou Then
                        _pos = _bodyLen + 1
                    Else
                        If _passos >= 10000 Then
                            _acabou = True
                        Else
                            _janela = me.CopiarJanelaAscii(pBody, _pos, 200)

                            If _janela = "" Then
                                _acabou = True
                            Else
                                _idxAbre = me.PosicaoAbreObjetoNaJanela(_janela)

                                If _idxAbre < 0 Then
                                    _acabou = True
                                Else
                                    If _idxAbre = 0 Then
                                        _pos = _pos + Len(_janela)
                                    Else
                                        _objStart = _pos + _idxAbre - 1
                                        _objFim = 0
                                        _item = NULL
                                        _passos = _passos + 1

                                        Try
                                            _item = me.MapearItemFullSearchDeBlob(pBody, _objStart, _objFim)

                                            If _objFim <= 0 Then
                                                RedeAncoraHttpErroHelper.RegistrarFalha("GET /products/full-search item", 200, "objeto de produto incompleto")
                                                If Assigned(_item) Then
                                                    _item.Free()
                                                    _item = NULL
                                                End If
                                                _acabou = True
                                            Else
                                                If Assigned(_item) Then
                                                    If Assigned(_item.Cadastro) Then
                                                        If _item.Cadastro.Cna > 0 Then
                                                            _result.Itens.Push(_item)
                                                            _item = NULL
                                                        Else
                                                            RedeAncoraHttpErroHelper.RegistrarFalha("GET /products/full-search item", 200, "cna ausente ou invalido")
                                                            _item.Free()
                                                            _item = NULL
                                                        End If
                                                    Else
                                                        _item.Free()
                                                        _item = NULL
                                                    End If
                                                End If
                                            End If
                                        Catch exItem As Exception
                                            RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.MapearFullSearch.item", exItem)

                                            If Assigned(_item) Then
                                                _item.Free()
                                                _item = NULL
                                            End If

                                            If _objFim <= 0 Then
                                                _objFim = me.AvancarFimObjetoProduto(pBody, _objStart)
                                            End If

                                            If _objFim <= 0 Then
                                                _acabou = True
                                            End If
                                        End Try

                                        If Not _acabou Then
                                            If _objFim <= 0 Then
                                                _acabou = True
                                            Else
                                                _pos = _objFim + 1
                                            End If
                                        End If
                                    End If
                                End If
                            End If
                        End If
                    End If
                Wend

                _n = RedeAncoraJsonHelper.ObterInteiroNoSufixo(pBody, "current_page")

                If _n > 0 Then
                    _result.Pagina = _n
                Else
                    _result.Pagina = pPagina
                End If

                _n = RedeAncoraJsonHelper.ObterInteiroNoSufixo(pBody, "per_page")

                If _n > 0 Then
                    _result.TamanhoPagina = _n
                Else
                    _result.TamanhoPagina = pTamanhoPagina
                End If

                _result.UltimaPagina = RedeAncoraJsonHelper.ObterInteiroNoSufixo(pBody, "last_page")
                _result.Total = RedeAncoraJsonHelper.ObterInteiroNoSufixo(pBody, "total")

                If _result.UltimaPagina <= 0 Then
                    If _result.Itens.Length < pTamanhoPagina Then
                        _result.UltimaPagina = _result.Pagina
                    Else
                        _result.UltimaPagina = _result.Pagina + 1
                    End If
                End If

                _ok = _result
                _result = NULL
            Catch ex As Exception
                If Assigned(_item) Then
                    _item.Free()
                    _item = NULL
                End If

                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                Throw New System.Exception("Erro ao mapear /products/full-search: " & ex._getMessage())
            End Try

            MapearFullSearch = _ok
        End Function

        Private Function MapearItemFullSearchDeBlob(pBody As String, pStart As Integer, ByRef pFim As Integer) As RedeAncoraProdutoFullSearchItemModel
            Dim _item As RedeAncoraProdutoFullSearchItemModel = NULL
            Dim _ok As RedeAncoraProdutoFullSearchItemModel = NULL
            Dim _preco As RedeAncoraProdutoPrecoEstoqueModel = NULL
            Dim _imagens As RedeAncoraProdutoImagensModel = NULL
            Dim _urlReal As String = ""
            Dim _urlIlustrativa As String = ""
            Dim _tecnicas As String = ""
            Dim _img1 As String = ""
            Dim _img2 As String = ""
            Dim _tecIgnorar As String = ""
            Dim _ignorar As Integer = 0
            Dim _seqReal As Integer = 0
            Dim _seqIlustrativa As Integer = 0
            Dim _seqTecnica As Integer = 0

            pFim = 0

            Try
                _item = New RedeAncoraProdutoFullSearchItemModel()
                _item.Cadastro = New RedeAncoraProdutoModel()
                _item.Cadastro.Ativo = ""
                _preco = New RedeAncoraProdutoPrecoEstoqueModel()
                me._parsePricesInicio = 0
                me._parsePricesFim = 0
                me._parseStocksInicio = 0
                me._parseStocksFim = 0
                me._parseTemPreco = False
                me._parsePreco = _preco
                pFim = me.ExtrairProdutoNoBody(pBody, pStart, _item.Cadastro, _urlReal, _urlIlustrativa, _tecnicas, True, True, True, True, _preco)

                If _item.Cadastro.Ativo.Trim() = "" Then
                    _item.Cadastro.Ativo = "S"
                End If

                If _item.Cadastro.NomeProduto.Trim() = "" Then
                    _item.Cadastro.NomeProduto = _item.Cadastro.NomeErp
                End If

                If me._parseTemPreco Then
                    _preco.Cna = _item.Cadastro.Cna

                    If me._parsePricesInicio > 0 Then
                        If me._parsePricesFim >= me._parsePricesInicio Then
                            _img1 = ""
                            _img2 = ""
                            _tecIgnorar = ""
                            _ignorar = me.ExtrairProdutoNoBody(pBody, me._parsePricesInicio, _item.Cadastro, _img1, _img2, _tecIgnorar, False, False, True, False, _preco)
                        End If
                    End If

                    If me._parseStocksInicio > 0 Then
                        If me._parseStocksFim >= me._parseStocksInicio Then
                            _img1 = ""
                            _img2 = ""
                            _tecIgnorar = ""
                            _ignorar = me.ExtrairProdutoNoBody(pBody, me._parseStocksInicio, _item.Cadastro, _img1, _img2, _tecIgnorar, False, False, True, False, _preco)
                        End If
                    End If

                    _item.PrecoEstoque = _preco
                    _preco = NULL
                Else
                    _preco.Free()
                    _preco = NULL
                End If

                me._parsePreco = NULL
                _imagens = New RedeAncoraProdutoImagensModel()
                me.AdicionarImagemUrl(_imagens, _item.Cadastro.Cna, RedeAncoraProdutoImagemTipo.Real(), _seqReal, _urlReal)
                me.AdicionarImagemUrl(_imagens, _item.Cadastro.Cna, RedeAncoraProdutoImagemTipo.Ilustrativa(), _seqIlustrativa, _urlIlustrativa)
                me.AdicionarImagensTecnicasDeBlob(_imagens, _item.Cadastro.Cna, _tecnicas, _seqTecnica)
                _item.Imagens = _imagens
                _imagens = NULL
                _ok = _item
                _item = NULL
            Catch ex As Exception
                me._parsePreco = NULL

                If Assigned(_preco) Then
                    _preco.Free()
                    _preco = NULL
                End If

                If Assigned(_imagens) Then
                    _imagens.Free()
                    _imagens = NULL
                End If

                If Assigned(_item) Then
                    _item.Free()
                    _item = NULL
                End If

                Throw ex
            End Try

            MapearItemFullSearchDeBlob = _ok
        End Function


        Function BuscarProdutoBulkSearch(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pPagina As Integer, pTamanhoPagina As Integer) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _body As String = ""
            Dim _ok As String = ""

            Try
                pCnas.ValidarTodos()

                If pCodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("Centro de distribuicao invalido para bulk-search")
                End If

                If pCodEstado <= 0 Then
                    Throw New System.Exception("CodEstado invalido para bulk-search")
                End If

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                DiagStack.Push("bulk-search.PostJson")
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/products/bulk-search"), me.MontarPayloadBulkSearch(pCodCentroDistribuicao, pCodEstado, pCnas, pPagina, pTamanhoPagina))
                DiagStack.Pop()

                If Not Assigned(_response) Then
                    Throw New System.Exception("POST /products/bulk-search resposta nula")
                End If

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("POST /products/bulk-search", _response.StatusCode, _response.Body))
                End If

                _body = _response.Body
                RedeAncoraHttpErroHelper.ExigirCorpoJson("POST /products/bulk-search", _response.StatusCode, _body)
                me.ExigirCorpoJsonContrato("POST /products/bulk-search", _body)
                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _ok = _body
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.BuscarProdutoBulkSearch", ex)

                If Assigned(_response) Then
                    _response.Free()
                    _response = NULL
                End If

                If Assigned(_api) Then
                    _api.Free()
                    _api = NULL
                End If

                Throw New System.Exception("Erro na busca bulk-search Rede Ancora: " + ex._getMessage())
            End Try

            BuscarProdutoBulkSearch = _ok
        End Function

        Function ConsultarCentrosComEstoque(pCodUsuario As Integer, pCna As Integer, pCodEstado As Integer, pCodCentroDistribuicao As Integer) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _payload As TJSONObject = NULL
            Dim _body As String = ""
            Dim _ok As String = ""

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
                DiagStack.Push("warehouses.PostJson")
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/products/warehouses/" + Parser.IntegerToString(pCna)), _payload.ToString())
                DiagStack.Pop()
                _payload.Free()
                _payload = NULL

                If Not Assigned(_response) Then
                    Throw New System.Exception("POST /products/warehouses resposta nula")
                End If

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("POST /products/warehouses", _response.StatusCode, _response.Body))
                End If

                _body = _response.Body
                RedeAncoraHttpErroHelper.ExigirCorpoJson("POST /products/warehouses", _response.StatusCode, _body)
                me.ExigirCorpoJsonContrato("POST /products/warehouses", _body)
                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _ok = _body
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService.ConsultarCentrosComEstoque", ex)

                If Assigned(_payload) Then
                    _payload.Free()
                    _payload = NULL
                End If

                If Assigned(_response) Then
                    _response.Free()
                    _response = NULL
                End If

                If Assigned(_api) Then
                    _api.Free()
                    _api = NULL
                End If

                Throw New System.Exception("Erro ao consultar centros com estoque Rede Ancora: " + ex._getMessage())
            End Try

            ConsultarCentrosComEstoque = _ok
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
            Dim _tx As Transaction = Transaction.Instance()

            Try
                _tx.OffAutoCommit()
                _tx.StartTransaction("Integracao.RedeAncoraProduto Desativar Cna")
                me.DesativarProdutoAncoraSemTransacao(pCna)
                _tx.OnAutoCommit()
                _tx.AutoCommit()
            Catch ex As Exception
                If Assigned(_tx) Then
                    _tx.Rollback()
                    _tx.OnAutoCommit()
                End If

                Throw New System.Exception("Erro ao desativar produto Rede Ancora: " & ex._getMessage())
            End Try
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
            Dim _ok As RedeAncoraProdutoVinculoModel = NULL

            Try
                _model = me._vinculoRepository.ObterPorCna(pCna)
                _model.CodProduto = pCodProduto
                _model.Ativo = "S"
                _model.DataVinculo = DateTime()
                me.SalvarVinculo(_model)
                _ok = _model
                _model = NULL
            Catch ex As Exception
                If Assigned(_model) Then
                    _model.Free()
                End If

                Throw New System.Exception("Erro ao vincular CNA " + pCna.ToString() + " com Produto.CodProduto " + pCodProduto.ToString() + ": " + ex._getMessage())
            End Try

            VincularComProdutoInterno = _ok
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
                _statusCadastro = me.UpsertProdutoCadastro(pCadastro, pUsarTransacao, True)

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
                me.UpsertProdutoCadastro(_cadastro, pUsarTransacao, False)
                _cadastro.Free()
                _cadastro = NULL
            Catch ex As Exception
                If Assigned(_cadastro) Then
                    _cadastro.Free()
                End If

                Throw New System.Exception("Erro ao espelhar vinculo no cadastro Ancora: " & ex._getMessage())
            End Try
        End Sub

        Private Function UpsertProdutoCadastro(pCadastro As RedeAncoraProdutoModel, pUsarTransacao As Boolean, pPreservarAtivoManual As Boolean) As Integer
            Dim _existente As RedeAncoraProdutoModel = NULL
            Dim _result As Integer = 0

            Try
                If pCadastro.Ativo.Trim() = "" Then
                    pCadastro.Ativo = "S"
                End If

                _existente = New RedeAncoraProdutoModel()

                If me._produtoRepository.TryObterPorCna(pCadastro.Cna, _existente) Then
                    me.MesclarCadastroExistente(_existente, pCadastro)

                    If pPreservarAtivoManual Then
                        If me._vinculoRepository.PossuiVinculoManual(pCadastro.Cna) Then
                            If _existente.Ativo = "S" Or _existente.Ativo = "N" Then
                                pCadastro.Ativo = _existente.Ativo
                            End If
                        End If
                    End If

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
                            me._imagemRepository.MesclarPorCna(pCna, _imagens)
                        Else
                            me._imagemRepository.MesclarPorCnaSemTransacao(pCna, _imagens)
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
                    If me.PreservarAtivoManual(_existente) Then
                        pApiModel.Ativo = _existente.Ativo
                        If pApiModel.Ativo <> "S" And pApiModel.Ativo <> "N" Then
                            pApiModel.Ativo = "N"
                        End If
                    Else
                        pApiModel.Ativo = "S"
                    End If

                    If me.ProdutoTemAlteracao(_existente, pApiModel) Then

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

            If pExistente.Ativo <> pApi.Ativo Then
                ProdutoTemAlteracao = True
                Exit Function
            End If
        End Function

        Private Function PreservarAtivoManual(pExistente As RedeAncoraProdutoVinculoModel) As Boolean
            Dim _result As Boolean = False

            If pExistente.CodProduto > 0 Then
                _result = True
            Else
                If pExistente.OrigemVinculo = RedeAncoraProdutoVinculoOrigem.Manual() Then
                    _result = True
                End If
            End If

            PreservarAtivoManual = _result
        End Function

        Private Function ProcessarProdutoAncoraPorBusca(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCna As Integer, pCodigo As String, pQuery As String, pCodProduto As Integer, pOrigem As String) As RedeAncoraProdutoVinculoModel
            Dim _filtro As RedeAncoraProdutoFullSearchFiltroModel = NULL
            Dim _resultado As RedeAncoraProdutoFullSearchResultadoModel = NULL
            Dim _item As RedeAncoraProdutoFullSearchItemModel = NULL
            Dim _model As RedeAncoraProdutoVinculoModel = NULL
            Dim _cnaSalvo As Integer = 0

            Try
                _filtro = New RedeAncoraProdutoFullSearchFiltroModel()
                _filtro.CodUsuario = pCodUsuario
                _filtro.CodCentroDistribuicao = pCodCentroDistribuicao
                _filtro.Cna = pCna
                _filtro.Codigo = pCodigo
                _filtro.Query = pQuery
                _filtro.Pagina = 1
                _filtro.TamanhoPagina = 100
                _filtro.IncluirDetalhes = True
                _resultado = me.BuscarProdutoFullSearch(_filtro)
                _item = me.SelecionarItemFullSearchParaCadastro(_resultado, pCna)

                If pCodProduto > 0 Then
                    me.UpsertProdutoCadastro(_item.Cadastro, True, True)
                    _model = me.MontarVinculoDeCadastroFullSearch(_item.Cadastro, pCodProduto, pOrigem)
                    me.SalvarVinculo(_model)
                Else
                    _cnaSalvo = _item.Cadastro.Cna
                    me.UpsertCadastroProdutoEVinculo(_item.Cadastro, pOrigem, True)
                    _model = me._vinculoRepository.ObterPorCna(_cnaSalvo)
                End If

                If Assigned(_model) Then
                    If _model.Cna > 0 Then
                        If Assigned(_item.Imagens) Then
                            If _item.Imagens.Length > 0 Then
                                me._imagemRepository.MesclarPorCna(_model.Cna, _item.Imagens)
                            End If
                        End If
                    End If
                End If

                _resultado.Free()
                _resultado = NULL
                _filtro.Free()
                _filtro = NULL
            Catch ex As Exception
                If Assigned(_model) Then
                    _model.Free()
                    _model = NULL
                End If

                If Assigned(_resultado) Then
                    _resultado.Free()
                    _resultado = NULL
                End If

                If Assigned(_filtro) Then
                    _filtro.Free()
                    _filtro = NULL
                End If

                Throw New System.Exception("Erro ao processar produto Ancora por busca: " + ex._getMessage())
            End Try

            ProcessarProdutoAncoraPorBusca = _model
        End Function

        Private Function SelecionarItemFullSearchParaCadastro(pResultado As RedeAncoraProdutoFullSearchResultadoModel, pCna As Integer) As RedeAncoraProdutoFullSearchItemModel
            Dim _item As RedeAncoraProdutoFullSearchItemModel = NULL

            If Not Assigned(pResultado) Then
                Throw New System.Exception("Nenhum produto encontrado na Rede Ancora para cadastro")
            End If

            If Not Assigned(pResultado.Itens) Then
                Throw New System.Exception("Nenhum produto encontrado na Rede Ancora para cadastro")
            End If

            If pResultado.Itens.Length <= 0 Then
                Throw New System.Exception("Nenhum produto encontrado na Rede Ancora para cadastro")
            End If

            If pCna > 0 Then
                _item = pResultado.Itens.ObterPorCna(pCna)

                If Not Assigned(_item) Then
                    Throw New System.Exception("Produto nao encontrado na pagina. Informe um filtro mais especifico")
                End If
            Else
                If pResultado.Itens.Length <> 1 Then
                    Throw New System.Exception("A busca retornou varios produtos. Informe um filtro mais especifico")
                End If

                If pResultado.TemProximaPagina() Then
                    Throw New System.Exception("A busca tem mais paginas. Informe um filtro mais especifico")
                End If

                _item = pResultado.Itens.Take(0)
            End If

            SelecionarItemFullSearchParaCadastro = _item
        End Function

        Private Function MontarVinculoDeCadastroFullSearch(pCadastro As RedeAncoraProdutoModel, pCodProduto As Integer, pOrigem As String) As RedeAncoraProdutoVinculoModel
            Dim _model As New RedeAncoraProdutoVinculoModel()

            _model.Cna = pCadastro.Cna
            _model.CodigoAncora = pCadastro.CodigoReferencia
            _model.DescricaoAncora = pCadastro.NomeProduto
            _model.CodMarca = pCadastro.CodMarcaParaVinculo()
            _model.CodLinha = pCadastro.CodLinha
            _model.CodFamilia = pCadastro.CodFamilia
            _model.CodProduto = pCodProduto
            _model.Ativo = "S"
            _model.OrigemVinculo = pOrigem
            MontarVinculoDeCadastroFullSearch = _model
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

        Private Function FlagDeTextoJson(pTexto As String) As String
            Dim _tok As String = LCase(pTexto.Trim())

            FlagDeTextoJson = ""

            If _tok <> "" Then
                If _tok = "true" Then
                    FlagDeTextoJson = "S"
                Else
                    If _tok = "1" Then
                        FlagDeTextoJson = "S"
                    Else
                        If _tok = "s" Then
                            FlagDeTextoJson = "S"
                        Else
                            If _tok = "sim" Then
                                FlagDeTextoJson = "S"
                            Else
                                FlagDeTextoJson = "N"
                            End If
                        End If
                    End If
                End If
            End If
        End Function

        ' Janelas Mid 200 no blob. Cadastro e URLs nesta passagem. prices/stocks so no trecho do objeto.
        ' details numa segunda leitura, so no que ficou vazio. Sem Exit Function: PaxExitException vaza.
        Private Function ExtrairProdutoNoBody(pBody As String, pStart As Integer, pCadastro As RedeAncoraProdutoModel, ByRef pImagemReal As String, ByRef pImagemIlustrativa As String, ByRef pTecnicas As String, pAplicarDetails As Boolean, pAplicarCadastro As Boolean, pCapturarPreco As Boolean, pRegistrarBlocos As Boolean, pPreco As RedeAncoraProdutoPrecoEstoqueModel) As Integer
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _janela As String = ""
            Dim _janelaLen As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _depth As Integer = 0
            Dim _arrDepth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escape As Boolean = False
            Dim _esperandoChave As Boolean = False
            Dim _lendoChave As Boolean = False
            Dim _depoisDeChave As Boolean = False
            Dim _lendoValor As Boolean = False
            Dim _valorString As Boolean = False
            Dim _chave As String = ""
            Dim _valor As String = ""
            Dim _chaveDepth As Integer = 0
            Dim _chaveObjeto As String = ""
            Dim _capturandoTecnicas As Boolean = False
            Dim _tecnicasArrAlvo As Integer = 0
            Dim _tecInicio As Integer = 0
            Dim _tecFim As Integer = 0
            Dim _spanTipo As Integer = 0
            Dim _spanInicio As Integer = 0
            Dim _spanFim As Integer = 0
            Dim _spanTeto As Integer = 0
            Dim _fim As Integer = 0
            Dim _result As Integer = 0
            Dim _detInicio As Integer = 0
            Dim _detFim As Integer = 0
            Dim _abs As Integer = 0
            Dim _ignorar As Integer = 0
            Dim _img1 As String = ""
            Dim _img2 As String = ""
            Dim _tecIgnorar As String = ""

            me._parseAplicarCadastro = pAplicarCadastro
            me._parseCapturarPreco = pCapturarPreco
            me._parseRegistrarBlocos = pRegistrarBlocos
            me._parsePreco = pPreco

            If pStart >= 1 Then
                _bodyLen = Len(pBody)
                If pStart <= _bodyLen Then
                    _pos = pStart
                    While _pos <= _bodyLen
                        If _fim = 0 Then
                            _janela = me.CopiarJanelaAscii(pBody, _pos, 200)
                            _janelaLen = Len(_janela)
                            If _janelaLen <= 0 Then
                                _fim = -1
                            Else
                                _i = 1
                                _tecInicio = 0
                                _tecFim = 0
                                _spanTipo = 0
                                _spanInicio = 0
                                _spanFim = 0
                                _spanTeto = 0
                                While _i <= _janelaLen
                                    If _fim = 0 Then
                                        _ch = Mid(_janela, _i, 1)
                                        _abs = _pos + _i - 1
                                        me.ConsumirCharFullSearch(_ch, _q, _depth, _arrDepth, _inQuotes, _escape, _esperandoChave, _lendoChave, _depoisDeChave, _lendoValor, _valorString, _chave, _valor, _chaveDepth, pCadastro, pImagemReal, pImagemIlustrativa, pTecnicas, _capturandoTecnicas, _tecnicasArrAlvo, _janela, _i, _tecInicio, _tecFim, _spanTipo, _spanInicio, _spanFim, _spanTeto, _chaveObjeto, _abs, _detInicio, _detFim)
                                        If _depth = 0 Then
                                            If Not _inQuotes Then
                                                If _ch = "}" Then
                                                    _fim = _pos + _i - 1
                                                End If
                                            End If
                                        End If
                                    End If
                                    _i = _i + 1
                                Wend
                                me.FlushSpanChaveValor(_janela, _spanTipo, _spanInicio, _spanFim, _spanTeto, _chave, _valor)
                                me.FlushSpanTecnicas(_janela, _tecInicio, _tecFim, pTecnicas)
                                If _fim = 0 Then
                                    _pos = _pos + _janelaLen
                                End If
                            End If
                        Else
                            _pos = _bodyLen + 1
                        End If
                    Wend
                End If
            End If

            If _fim > 0 Then
                _result = _fim
            End If

            If pAplicarDetails Then
                If _detInicio > 0 Then
                    If _detFim >= _detInicio Then
                        _img1 = ""
                        _img2 = ""
                        _tecIgnorar = ""
                        _ignorar = me.ExtrairProdutoNoBody(pBody, _detInicio, pCadastro, _img1, _img2, _tecIgnorar, False, True, False, False, NULL)
                    End If
                End If
            End If

            ExtrairProdutoNoBody = _result
        End Function

        Private Sub ConsumirCharFullSearch(pCh As String, pQ As String, ByRef pDepth As Integer, ByRef pArrDepth As Integer, ByRef pInQuotes As Boolean, ByRef pEscape As Boolean, ByRef pEsperandoChave As Boolean, ByRef pLendoChave As Boolean, ByRef pDepoisDeChave As Boolean, ByRef pLendoValor As Boolean, ByRef pValorString As Boolean, ByRef pChave As String, ByRef pValor As String, ByRef pChaveDepth As Integer, pCadastro As RedeAncoraProdutoModel, ByRef pImagemReal As String, ByRef pImagemIlustrativa As String, ByRef pTecnicas As String, ByRef pCapturandoTecnicas As Boolean, ByRef pTecnicasArrAlvo As Integer, pJanela As String, pIndex As Integer, ByRef pTecInicio As Integer, ByRef pTecFim As Integer, ByRef pSpanTipo As Integer, ByRef pSpanInicio As Integer, ByRef pSpanFim As Integer, ByRef pSpanTeto As Integer, ByRef pChaveObjeto As String, pAbs As Integer, ByRef pDetInicio As Integer, ByRef pDetFim As Integer)
            Dim _ehBranco As Boolean = False
            Dim _tetoValor As Integer = 0
            Dim _queroTecnicas As Boolean = False
            Dim _queroChave As Boolean = False
            Dim _queroValor As Boolean = False
            Dim _naRaizCampo As Boolean = False

            If pCapturandoTecnicas Then
                _queroTecnicas = True
            End If

            If pChaveDepth = 1 Then
                _naRaizCampo = True
            End If

            If pEscape Then
                If pLendoChave Then
                    If _naRaizCampo Then
                        _queroChave = True
                    End If
                Else
                    If pLendoValor Then
                        If pValorString Then
                            If _naRaizCampo Then
                                _queroValor = True
                                _tetoValor = me.TetoValorTextoJson(pChave)
                            End If
                        End If
                    End If
                End If
            Else
                If pInQuotes Then
                    If pCh <> pQ Then
                        If pCh <> "\" Then
                            If pLendoChave Then
                                If _naRaizCampo Then
                                    _queroChave = True
                                End If
                            Else
                                If pLendoValor Then
                                    If pValorString Then
                                        If _naRaizCampo Then
                                            _queroValor = True
                                            _tetoValor = me.TetoValorTextoJson(pChave)
                                        End If
                                    End If
                                End If
                            End If
                        Else
                            If pLendoValor Then
                                If pValorString Then
                                    If _naRaizCampo Then
                                        _queroValor = True
                                        _tetoValor = me.TetoValorTextoJson(pChave)
                                    End If
                                End If
                            End If
                        End If
                    End If
                Else
                    _ehBranco = me.EhBrancoJsonChar(pCh)

                    If Not _ehBranco Then
                        If pLendoValor Then
                            If Not pValorString Then
                                If _naRaizCampo Then
                                    If pCh <> "{" Then
                                        If pCh <> "}" Then
                                            If pCh <> "[" Then
                                                If pCh <> "]" Then
                                                    If pCh <> ":" Then
                                                        If pCh <> "," Then
                                                            If pCh <> pQ Then
                                                                _queroValor = True
                                                                _tetoValor = 40
                                                            End If
                                                        End If
                                                    End If
                                                End If
                                            End If
                                        End If
                                    End If
                                End If
                            End If
                        End If
                    End If
                End If
            End If

            me.AtualizarSpanTecnicas(_queroTecnicas, pIndex, pJanela, pTecInicio, pTecFim, pTecnicas)

            If _queroChave Then
                me.AtualizarSpanChaveValor(True, 1, 40, pIndex, pJanela, pSpanTipo, pSpanInicio, pSpanFim, pSpanTeto, pChave, pValor)
            Else
                If _queroValor Then
                    me.AtualizarSpanChaveValor(True, 2, _tetoValor, pIndex, pJanela, pSpanTipo, pSpanInicio, pSpanFim, pSpanTeto, pChave, pValor)
                Else
                    me.AtualizarSpanChaveValor(False, 0, 0, pIndex, pJanela, pSpanTipo, pSpanInicio, pSpanFim, pSpanTeto, pChave, pValor)
                End If
            End If

            If pEscape Then
                pEscape = False
            Else
                If pInQuotes Then
                    If pCh = "\" Then
                        pEscape = True
                    Else
                        If pCh = pQ Then
                            pInQuotes = False
                            If pLendoChave Then
                                pLendoChave = False
                                pDepoisDeChave = True
                            Else
                                If pLendoValor Then
                                    If pValorString Then
                                        pLendoValor = False
                                        me.AplicarCampoFullSearch(pChaveDepth, pCadastro, pChave, pValor, pImagemReal, pImagemIlustrativa)
                                    End If
                                End If
                            End If
                        End If
                    End If
                Else
                    If pCh = pQ Then
                        pInQuotes = True
                        If pEsperandoChave Then
                            pLendoChave = True
                            pChave = ""
                            pChaveDepth = pDepth
                            pEsperandoChave = False
                        Else
                            If pLendoValor Then
                                pValorString = True
                                pValor = ""
                            End If
                        End If
                    Else
                        If pCh = "{" Then
                            If pDepth = 1 Then
                                If pLendoValor Then
                                    If pChaveDepth = 1 Then
                                        pChaveObjeto = pChave

                                        If pChave = "details" Then
                                            If pDetInicio <= 0 Then
                                                pDetInicio = pAbs
                                            End If
                                        End If

                                        me.MarcarInicioBlocoPreco(pChave, pAbs)
                                    End If
                                End If
                            End If
                            pDepth = pDepth + 1
                            pEsperandoChave = True
                            If pLendoValor Then
                                pLendoValor = False
                            End If
                        Else
                            If pCh = "}" Then
                                If pLendoValor Then
                                    me.AplicarCampoFullSearch(pChaveDepth, pCadastro, pChave, pValor, pImagemReal, pImagemIlustrativa)
                                    pLendoValor = False
                                End If
                                pDepth = pDepth - 1
                                If pDepth = 1 Then
                                    If pChaveObjeto = "details" Then
                                        If pDetFim <= 0 Then
                                            pDetFim = pAbs
                                        End If
                                    End If
                                    me.MarcarFimBlocoPreco(pChaveObjeto, pAbs)
                                End If
                                If pDepth <= 1 Then
                                    pChaveObjeto = ""
                                End If
                                pEsperandoChave = False
                            Else
                                If pCh = "[" Then
                                    If pLendoValor Then
                                        If pChaveDepth = 1 Then
                                            If pChave = "imagensTecnicas" Then
                                                If pTecnicas = "" Then
                                                    If Not pCapturandoTecnicas Then
                                                        pCapturandoTecnicas = True
                                                        pTecnicas = "["
                                                        pTecnicasArrAlvo = pArrDepth
                                                    End If
                                                End If
                                            End If
                                        End If
                                        pLendoValor = False
                                    End If
                                    pArrDepth = pArrDepth + 1
                                Else
                                    If pCh = "]" Then
                                        If pArrDepth > 0 Then
                                            pArrDepth = pArrDepth - 1
                                        End If
                                        If pCapturandoTecnicas Then
                                            If pArrDepth = pTecnicasArrAlvo Then
                                                pCapturandoTecnicas = False
                                            End If
                                        End If
                                    Else
                                        If pCh = ":" Then
                                            If pDepoisDeChave Then
                                                pDepoisDeChave = False
                                                pLendoValor = True
                                                pValor = ""
                                                pValorString = False
                                            End If
                                        Else
                                            If pCh = "," Then
                                                If pLendoValor Then
                                                    me.AplicarCampoFullSearch(pChaveDepth, pCadastro, pChave, pValor, pImagemReal, pImagemIlustrativa)
                                                    pLendoValor = False
                                                End If
                                                If pArrDepth = 0 Then
                                                    pEsperandoChave = True
                                                Else
                                                    pEsperandoChave = False
                                                End If
                                            End If
                                        End If
                                    End If
                                End If
                            End If
                        End If
                    End If
                End If
            End If
        End Sub

        Private Sub MarcarInicioBlocoPreco(pChave As String, pAbs As Integer)
            If me._parseRegistrarBlocos Then
                If pChave = "prices" Then
                    If me._parsePricesInicio <= 0 Then
                        me._parsePricesInicio = pAbs
                        me._parseTemPreco = True
                    End If
                End If

                If pChave = "stocks" Then
                    If me._parseStocksInicio <= 0 Then
                        me._parseStocksInicio = pAbs
                        me._parseTemPreco = True
                    End If
                End If
            End If
        End Sub

        Private Sub MarcarFimBlocoPreco(pChaveObjeto As String, pAbs As Integer)
            If me._parseRegistrarBlocos Then
                If pChaveObjeto = "prices" Then
                    If me._parsePricesFim <= 0 Then
                        me._parsePricesFim = pAbs
                    End If
                End If

                If pChaveObjeto = "stocks" Then
                    If me._parseStocksFim <= 0 Then
                        me._parseStocksFim = pAbs
                    End If
                End If
            End If
        End Sub

        Private Sub AplicarCampoFullSearch(pChaveDepth As Integer, pCadastro As RedeAncoraProdutoModel, pChave As String, pValor As String, ByRef pImagemReal As String, ByRef pImagemIlustrativa As String)
            Dim _tok As String = ""

            If pChaveDepth = 1 Then
                _tok = pValor.Trim()
                If LCase(_tok) <> "null" Then
                    If _tok <> "" Then
                        If me._parseAplicarCadastro Then
                            If Assigned(pCadastro) Then
                                me.AplicarCadastroFullSearch(pCadastro, pChave, _tok, pImagemReal, pImagemIlustrativa)
                            End If
                        End If

                        If me._parseCapturarPreco Then
                            If Assigned(me._parsePreco) Then
                                me.AplicarPrecoRaizFullSearch(pChave, _tok)
                            End If
                        End If
                    End If
                End If
            End If
        End Sub

        Private Sub AplicarCadastroFullSearch(pCadastro As RedeAncoraProdutoModel, pChave As String, pValor As String, ByRef pImagemReal As String, ByRef pImagemIlustrativa As String)
            If pChave = "cna" Then
                pCadastro.Cna = me.CoalesceInteiro(pCadastro.Cna, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "catalogo_id" Then
                pCadastro.CatalogoId = me.CoalesceInteiro(pCadastro.CatalogoId, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "csa" Then
                pCadastro.Csa = me.CoalesceTexto(pCadastro.Csa, pValor)
            End If
            If pChave = "cnl" Then
                pCadastro.Cnl = me.CoalesceTexto(pCadastro.Cnl, pValor)
            End If
            If pChave = "codigoReferencia" Then
                pCadastro.CodigoReferencia = me.CoalesceTexto(pCadastro.CodigoReferencia, pValor)
            End If
            If pChave = "code" Then
                pCadastro.CodigoReferencia = me.CoalesceTexto(pCadastro.CodigoReferencia, pValor)
            End If
            If pChave = "code_edi" Then
                pCadastro.CodeEdi = me.CoalesceTexto(pCadastro.CodeEdi, pValor)
            End If
            If pChave = "code_manufacturer" Then
                pCadastro.CodeManufacturer = me.CoalesceTexto(pCadastro.CodeManufacturer, pValor)
            End If
            If pChave = "nomeProduto" Then
                pCadastro.NomeProduto = me.CoalesceTexto(pCadastro.NomeProduto, pValor)
            End If
            If pChave = "description" Then
                pCadastro.NomeProduto = me.CoalesceTexto(pCadastro.NomeProduto, pValor)
            End If
            If pChave = "nome" Then
                pCadastro.NomeErp = me.CoalesceTexto(pCadastro.NomeErp, pValor)
            End If
            If pChave = "name" Then
                pCadastro.NomeErp = me.CoalesceTexto(pCadastro.NomeErp, pValor)
            End If
            If pChave = "informacoesAdicionais" Then
                pCadastro.InformacoesAdicionais = me.CoalesceTexto(pCadastro.InformacoesAdicionais, pValor)
            End If
            If pChave = "informacoesComplementares" Then
                pCadastro.InformacoesComplementares = me.CoalesceTexto(pCadastro.InformacoesComplementares, pValor)
            End If
            If pChave = "additional_description" Then
                pCadastro.AdditionalDescription = me.CoalesceTexto(pCadastro.AdditionalDescription, pValor)
            End If
            If pChave = "pontoCriticoAtencao" Then
                pCadastro.PontoCriticoAtencao = me.CoalesceTexto(pCadastro.PontoCriticoAtencao, pValor)
            End If
            If pChave = "dimensoes" Then
                pCadastro.Dimensoes = me.CoalesceTexto(pCadastro.Dimensoes, pValor)
            End If
            If pChave = "marcaId" Then
                pCadastro.CodMarca = me.CoalesceInteiro(pCadastro.CodMarca, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "brand_id" Then
                pCadastro.CodMarcaErp = me.CoalesceInteiro(pCadastro.CodMarcaErp, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "marca" Then
                pCadastro.NomeMarca = me.CoalesceTexto(pCadastro.NomeMarca, pValor)
            End If
            If pChave = "brand" Then
                pCadastro.NomeMarca = me.CoalesceTexto(pCadastro.NomeMarca, pValor)
            End If
            If pChave = "line" Then
                pCadastro.CodLinha = me.CoalesceInteiro(pCadastro.CodLinha, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "line_id" Then
                pCadastro.CodLinha = me.CoalesceInteiro(pCadastro.CodLinha, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "line_name" Then
                pCadastro.NomeLinha = me.CoalesceTexto(pCadastro.NomeLinha, pValor)
            End If
            If pChave = "family" Then
                pCadastro.CodFamilia = me.CoalesceInteiro(pCadastro.CodFamilia, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "family_id" Then
                pCadastro.CodFamilia = me.CoalesceInteiro(pCadastro.CodFamilia, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "family_name" Then
                pCadastro.NomeFamilia = me.CoalesceTexto(pCadastro.NomeFamilia, pValor)
            End If
            If pChave = "manufacturer_id" Then
                pCadastro.CodFabricante = me.CoalesceInteiro(pCadastro.CodFabricante, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "fabricante" Then
                pCadastro.CodFabricante = me.CoalesceInteiro(pCadastro.CodFabricante, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "ean" Then
                pCadastro.Ean = me.CoalesceTexto(pCadastro.Ean, pValor)
            End If
            If pChave = "gtin" Then
                pCadastro.Gtin = me.CoalesceTexto(pCadastro.Gtin, pValor)
            End If
            If pChave = "ncm" Then
                pCadastro.Ncm = me.CoalesceTexto(pCadastro.Ncm, pValor)
            End If
            If pChave = "cest" Then
                pCadastro.Cest = me.CoalesceTexto(pCadastro.Cest, pValor)
            End If
            If pChave = "origem" Then
                pCadastro.Origem = me.CoalesceTexto(pCadastro.Origem, pValor)
            End If
            If pChave = "origem_label" Then
                pCadastro.OrigemLabel = me.CoalesceTexto(pCadastro.OrigemLabel, pValor)
            End If
            If pChave = "anp" Then
                pCadastro.Anp = me.CoalesceInteiro(pCadastro.Anp, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "anp_label" Then
                pCadastro.AnpLabel = me.CoalesceTexto(pCadastro.AnpLabel, pValor)
            End If
            If pChave = "peso_liquido" Then
                pCadastro.PesoLiquido = me.CoalesceDecimal(pCadastro.PesoLiquido, Parser.StringToDouble(pValor))
            End If
            If pChave = "net_weight" Then
                pCadastro.PesoLiquido = me.CoalesceDecimal(pCadastro.PesoLiquido, Parser.StringToDouble(pValor))
            End If
            If pChave = "peso_bruto" Then
                pCadastro.PesoBruto = me.CoalesceDecimal(pCadastro.PesoBruto, Parser.StringToDouble(pValor))
            End If
            If pChave = "gross_weight" Then
                pCadastro.PesoBruto = me.CoalesceDecimal(pCadastro.PesoBruto, Parser.StringToDouble(pValor))
            End If
            If pChave = "volume" Then
                pCadastro.Volume = me.CoalesceDecimal(pCadastro.Volume, Parser.StringToDouble(pValor))
            End If
            If pChave = "liters" Then
                pCadastro.Litros = me.CoalesceDecimal(pCadastro.Litros, Parser.StringToDouble(pValor))
            End If
            If pChave = "tamanho" Then
                pCadastro.Tamanho = me.CoalesceTexto(pCadastro.Tamanho, pValor)
            End If
            If pChave = "material" Then
                pCadastro.Material = me.CoalesceTexto(pCadastro.Material, pValor)
            End If
            If pChave = "tipo" Then
                pCadastro.Tipo = me.CoalesceInteiro(pCadastro.Tipo, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "medida_venda" Then
                pCadastro.MedidaVenda = me.CoalesceTexto(pCadastro.MedidaVenda, pValor)
            End If
            If pChave = "garantia_dias" Then
                pCadastro.GarantiaDias = me.CoalesceInteiro(pCadastro.GarantiaDias, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "warranty" Then
                pCadastro.GarantiaDias = me.CoalesceInteiro(pCadastro.GarantiaDias, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "fracao_fabrica" Then
                pCadastro.FracaoFabrica = me.CoalesceInteiro(pCadastro.FracaoFabrica, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "fracao_loja" Then
                pCadastro.FracaoLoja = me.CoalesceInteiro(pCadastro.FracaoLoja, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "status" Then
                pCadastro.Status = me.CoalesceInteiro(pCadastro.Status, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "erp_handle" Then
                pCadastro.ErpHandle = me.CoalesceInteiro(pCadastro.ErpHandle, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "handle" Then
                pCadastro.ErpHandle = me.CoalesceInteiro(pCadastro.ErpHandle, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "leadtime" Then
                pCadastro.Leadtime = me.CoalesceInteiro(pCadastro.Leadtime, me.TextoParaInteiroToken(pValor))
            End If
            If pChave = "on_demand_label" Then
                pCadastro.OnDemandLabel = me.CoalesceTexto(pCadastro.OnDemandLabel, pValor)
            End If
            If pChave = "motivo_descontinuado" Then
                pCadastro.MotivoDescontinuado = me.CoalesceTexto(pCadastro.MotivoDescontinuado, pValor)
            End If
            If pChave = "imagemReal" Then
                If pImagemReal = "" Then
                    pImagemReal = pValor
                End If
            End If
            If pChave = "imagemIlustrativa" Then
                If pImagemIlustrativa = "" Then
                    pImagemIlustrativa = pValor
                End If
            End If
            If pChave = "ativo" Then
                If pCadastro.Ativo = "" Then
                    pCadastro.Ativo = me.FlagDeTextoJson(pValor)
                End If
            End If
            If pChave = "descontinuado" Then
                If pCadastro.Descontinuado = "" Then
                    pCadastro.Descontinuado = me.FlagDeTextoJson(pValor)
                End If
            End If
            If pChave = "bloqueado" Then
                If pCadastro.Bloqueado = "" Then
                    pCadastro.Bloqueado = me.FlagDeTextoJson(pValor)
                End If
            End If
            If pChave = "confiavel" Then
                If pCadastro.Confiavel = "" Then
                    pCadastro.Confiavel = me.FlagDeTextoJson(pValor)
                End If
            End If
            If pChave = "sugerido" Then
                If pCadastro.Sugerido = "" Then
                    pCadastro.Sugerido = me.FlagDeTextoJson(pValor)
                End If
            End If
            If pChave = "lancamento" Then
                If pCadastro.Lancamento = "" Then
                    pCadastro.Lancamento = me.FlagDeTextoJson(pValor)
                End If
            End If
            If pChave = "on_demand" Then
                If pCadastro.OnDemand = "" Then
                    pCadastro.OnDemand = me.FlagDeTextoJson(pValor)
                End If
            End If
            If pChave = "parcialmente_similar" Then
                If pCadastro.ParcialmenteSimilar = "" Then
                    pCadastro.ParcialmenteSimilar = me.FlagDeTextoJson(pValor)
                End If
            End If
            If pChave = "has_restrictions" Then
                If pCadastro.HasRestrictions = "" Then
                    pCadastro.HasRestrictions = me.FlagDeTextoJson(pValor)
                End If
            End If
            If pChave = "prazo_especial" Then
                If pCadastro.PrazoEspecial = "" Then
                    pCadastro.PrazoEspecial = me.FlagDeTextoJson(pValor)
                End If
            End If
        End Sub

        Private Sub AplicarPrecoRaizFullSearch(pChave As String, pValor As String)
            Dim _n As Integer = 0

            If pChave = "empresa" Then
                _n = me.TextoParaInteiroToken(pValor)
                If _n > 0 Then
                    me._parsePreco.CodCentroDistribuicao = _n
                End If
            End If
            If pChave = "estado" Then
                _n = me.TextoParaInteiroToken(pValor)
                If _n > 0 Then
                    me._parsePreco.CodEstado = _n
                End If
            End If
            If pChave = "qtd_disponivel" Then
                me._parsePreco.QtdDisponivel = me.TextoParaInteiroToken(pValor)
                me._parseTemPreco = True
            End If
            If pChave = "qtd_projetada" Then
                me._parsePreco.QtdProjetada = me.TextoParaInteiroToken(pValor)
            End If
            If pChave = "preco_tabela" Then
                me._parsePreco.PrecoTabela = Parser.StringToDouble(pValor)
                me._parseTemPreco = True
            End If
            If pChave = "st_tabela" Then
                me._parsePreco.StTabela = Parser.StringToDouble(pValor)
            End If
            If pChave = "preco_cross_docking" Then
                me._parsePreco.PrecoCrossDocking = Parser.StringToDouble(pValor)
            End If
            If pChave = "preco_compra_junto" Then
                me._parsePreco.PrecoCompraJunto = Parser.StringToDouble(pValor)
            End If
        End Sub

        Private Function TextoParaInteiroToken(pRaw As String) As Integer
            Dim _text As String = pRaw.Trim()
            Dim _len As Integer = Len(_text)
            Dim _i As Integer = 1
            Dim _sign As Integer = 1
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _ch As String = ""
            Dim _seguir As Boolean = True
            Dim _digits As String = "0123456789"
            Dim _j As Integer = 0

            If _len > 0 Then
                _ch = Mid(_text, 1, 1)
                If _ch = "-" Then
                    _sign = -1
                    _i = 2
                Else
                    If _ch = "+" Then
                        _i = 2
                    End If
                End If
            Else
                _seguir = False
            End If

            While _seguir
                If _i > _len Then
                    _seguir = False
                Else
                    _ch = Mid(_text, _i, 1)
                    _d = -1
                    For _j = 1 To 10
                        If Mid(_digits, _j, 1) = _ch Then
                            _d = _j - 1
                        End If
                    Next
                    If _d < 0 Then
                        _seguir = False
                    Else
                        _n = (_n * 10) + _d
                        _i = _i + 1
                    End If
                End If
            Wend

            TextoParaInteiroToken = _sign * _n
        End Function

        Private Function TetoValorTextoJson(pChave As String) As Integer
            If Len(pChave) > 0 Then
                TetoValorTextoJson = 2000
            Else
                TetoValorTextoJson = 40
            End If
        End Function

        Private Function EhBrancoJsonChar(pCh As String) As Boolean
            Dim _result As Boolean = False

            If pCh = " " Then
                _result = True
            Else
                If pCh = Chr(9) Then
                    _result = True
                Else
                    If pCh = Chr(10) Then
                        _result = True
                    Else
                        If pCh = Chr(13) Then
                            _result = True
                        End If
                    End If
                End If
            End If
            EhBrancoJsonChar = _result
        End Function

        Private Sub AnexarTrechoLimitado(ByRef pDest As String, pJanela As String, pInicio As Integer, pFim As Integer, pTeto As Integer)
            Dim _lenDest As Integer = 0
            Dim _n As Integer = 0
            Dim _restante As Integer = 0

            If pInicio >= 1 Then
                If pFim >= pInicio Then
                    _lenDest = Len(pDest)

                    If _lenDest < pTeto Then
                        _n = pFim - pInicio + 1
                        _restante = pTeto - _lenDest

                        If _n > _restante Then
                            _n = _restante
                        End If

                        If _n > 200 Then
                            _n = 200
                        End If

                        If _n > 0 Then
                            pDest = pDest & Mid(pJanela, pInicio, _n)
                        End If
                    End If
                End If
            End If
        End Sub

        Private Sub FlushSpanChaveValor(pJanela As String, ByRef pSpanTipo As Integer, ByRef pSpanInicio As Integer, ByRef pSpanFim As Integer, ByRef pSpanTeto As Integer, ByRef pChave As String, ByRef pValor As String)
            If pSpanTipo = 1 Then
                me.AnexarTrechoLimitado(pChave, pJanela, pSpanInicio, pSpanFim, pSpanTeto)
            End If

            If pSpanTipo = 2 Then
                me.AnexarTrechoLimitado(pValor, pJanela, pSpanInicio, pSpanFim, pSpanTeto)
            End If

            pSpanTipo = 0
            pSpanInicio = 0
            pSpanFim = 0
            pSpanTeto = 0
        End Sub

        Private Sub FlushSpanTecnicas(pJanela As String, ByRef pTecInicio As Integer, ByRef pTecFim As Integer, ByRef pTecnicas As String)
            If pTecInicio >= 1 Then
                If pTecFim >= pTecInicio Then
                    me.AnexarTrechoLimitado(pTecnicas, pJanela, pTecInicio, pTecFim, 40000)
                End If
            End If

            pTecInicio = 0
            pTecFim = 0
        End Sub

        Private Sub AtualizarSpanChaveValor(pQuer As Boolean, pTipo As Integer, pTeto As Integer, pIndex As Integer, pJanela As String, ByRef pSpanTipo As Integer, ByRef pSpanInicio As Integer, ByRef pSpanFim As Integer, ByRef pSpanTeto As Integer, ByRef pChave As String, ByRef pValor As String)
            Dim _contiguo As Boolean = False

            If pQuer Then
                If pSpanTipo = pTipo Then
                    If pSpanTeto = pTeto Then
                        If pSpanFim + 1 = pIndex Then
                            _contiguo = True
                        End If
                    End If
                End If

                If _contiguo Then
                    pSpanFim = pIndex
                Else
                    me.FlushSpanChaveValor(pJanela, pSpanTipo, pSpanInicio, pSpanFim, pSpanTeto, pChave, pValor)
                    pSpanTipo = pTipo
                    pSpanInicio = pIndex
                    pSpanFim = pIndex
                    pSpanTeto = pTeto
                End If
            Else
                If pSpanTipo <> 0 Then
                    me.FlushSpanChaveValor(pJanela, pSpanTipo, pSpanInicio, pSpanFim, pSpanTeto, pChave, pValor)
                End If
            End If
        End Sub

        Private Sub AtualizarSpanTecnicas(pQuer As Boolean, pIndex As Integer, pJanela As String, ByRef pTecInicio As Integer, ByRef pTecFim As Integer, ByRef pTecnicas As String)
            Dim _contiguo As Boolean = False

            If pQuer Then
                If pTecInicio >= 1 Then
                    If pTecFim + 1 = pIndex Then
                        _contiguo = True
                    End If
                End If

                If _contiguo Then
                    pTecFim = pIndex
                Else
                    me.FlushSpanTecnicas(pJanela, pTecInicio, pTecFim, pTecnicas)
                    pTecInicio = pIndex
                    pTecFim = pIndex
                End If
            Else
                If pTecInicio >= 1 Then
                    me.FlushSpanTecnicas(pJanela, pTecInicio, pTecFim, pTecnicas)
                End If
            End If
        End Sub

        Private Function CopiarJanelaAscii(pSrc As String, pStart As Integer, pLen As Integer) As String
            Dim _bodyLen As Integer = 0
            Dim _n As Integer = 0
            Dim _result As String = ""

            If pStart >= 1 Then
                If pLen > 0 Then
                    _bodyLen = Len(pSrc)
                    If pStart <= _bodyLen Then
                        _n = pLen
                        If _n > 200 Then
                            _n = 200
                        End If
                        If (pStart + _n - 1) > _bodyLen Then
                            _n = _bodyLen - pStart + 1
                        End If
                        If _n > 0 Then
                            _result = Mid(pSrc, pStart, _n)
                        End If
                    End If
                End If
            End If
            CopiarJanelaAscii = _result
        End Function

        Private Function PosicaoAbreObjetoNaJanela(pJanela As String) As Integer
            Dim _len As Integer = Len(pJanela)
            Dim _i As Integer = 1
            Dim _ch As String = ""
            Dim _idx As Integer = 0
            Dim _result As Integer = 0

            While _i <= _len
                If _idx = 0 Then
                    _ch = Mid(pJanela, _i, 1)
                    If _ch = " " Then
                        _i = _i + 1
                    Else
                        If _ch = "," Then
                            _i = _i + 1
                        Else
                            If _ch = Chr(9) Then
                                _i = _i + 1
                            Else
                                If _ch = Chr(10) Then
                                    _i = _i + 1
                                Else
                                    If _ch = Chr(13) Then
                                        _i = _i + 1
                                    Else
                                        _idx = _i
                                    End If
                                End If
                            End If
                        End If
                    End If
                Else
                    _i = _len + 1
                End If
            Wend

            If _idx > 0 Then
                _ch = Mid(pJanela, _idx, 1)
                If _ch = "]" Then
                    _result = -1
                Else
                    If _ch = "{" Then
                        _result = _idx
                    Else
                        _result = -2
                    End If
                End If
            End If
            PosicaoAbreObjetoNaJanela = _result
        End Function

        Private Function AvancarFimObjetoProduto(pBody As String, pStart As Integer) As Integer
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _janela As String = ""
            Dim _janelaLen As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escape As Boolean = False
            Dim _fim As Integer = 0
            Dim _result As Integer = 0

            If pStart >= 1 Then
                _bodyLen = Len(pBody)
                If pStart <= _bodyLen Then
                    _pos = pStart
                    While _pos <= _bodyLen
                        If _fim = 0 Then
                            _janela = me.CopiarJanelaAscii(pBody, _pos, 200)
                            _janelaLen = Len(_janela)
                            If _janelaLen <= 0 Then
                                _fim = -1
                            Else
                                _i = 1
                                While _i <= _janelaLen
                                    If _fim = 0 Then
                                        _ch = Mid(_janela, _i, 1)
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
                                                                _fim = _pos + _i - 1
                                                            End If
                                                        End If
                                                    End If
                                                End If
                                            End If
                                        End If
                                    End If
                                    _i = _i + 1
                                Wend
                                If _fim = 0 Then
                                    _pos = _pos + _janelaLen
                                End If
                            End If
                        Else
                            _pos = _bodyLen + 1
                        End If
                    Wend
                End If
            End If

            If _fim > 0 Then
                _result = _fim
            End If
            AvancarFimObjetoProduto = _result
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
            Dim _ok As RedeAncoraProdutoModel = NULL

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

                _ok = _cadastro
                _cadastro = NULL
            Catch ex As Exception
                If Assigned(_details) Then
                    _details.Free()
                End If

                If Assigned(_cadastro) Then
                    _cadastro.Free()
                End If

                Throw ex
            End Try

            MapearProdutoCadastroDeJson = _ok
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
            Dim _body As String = ""
            Dim _ok As String = ""

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                DiagStack.Push("pass-through.GetRequest")
                _response = _api.GetRequest(pUrl)
                DiagStack.Pop()

                If Not Assigned(_response) Then
                    Throw New System.Exception(pOperacao & " resposta nula")
                End If

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem(pOperacao, _response.StatusCode, _response.Body))
                End If

                _body = _response.Body
                RedeAncoraHttpErroHelper.ExigirCorpoJson(pOperacao, _response.StatusCode, _body)
                me.ExigirCorpoJsonContrato(pOperacao, _body)
                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _ok = _body
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService." & pOperacao, ex)

                If Assigned(_response) Then
                    _response.Free()
                    _response = NULL
                End If

                If Assigned(_api) Then
                    _api.Free()
                    _api = NULL
                End If

                Throw ex
            End Try

            ExecutarGetPassThrough = _ok
        End Function

        Private Function ExecutarPostPassThrough(pCodUsuario As Integer, pUrl As String, pPayload As String, pOperacao As String) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _body As String = ""
            Dim _ok As String = ""

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                DiagStack.Push("pass-through.PostJson")
                _response = _api.PostJson(pUrl, pPayload)
                DiagStack.Pop()

                If Not Assigned(_response) Then
                    Throw New System.Exception(pOperacao & " resposta nula")
                End If

                If Not _response.IsSuccess Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem(pOperacao, _response.StatusCode, _response.Body))
                End If

                _body = _response.Body
                RedeAncoraHttpErroHelper.ExigirCorpoJson(pOperacao, _response.StatusCode, _body)
                me.ExigirCorpoJsonContrato(pOperacao, _body)
                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _ok = _body
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraProdutoService." & pOperacao, ex)

                If Assigned(_response) Then
                    _response.Free()
                    _response = NULL
                End If

                If Assigned(_api) Then
                    _api.Free()
                    _api = NULL
                End If

                Throw ex
            End Try

            ExecutarPostPassThrough = _ok
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

                If _imagens.Length > 0 Then
                    If pUsarTransacao Then
                        me._imagemRepository.MesclarPorCna(pCna, _imagens)
                    Else
                        me._imagemRepository.MesclarPorCnaSemTransacao(pCna, _imagens)
                    End If
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
            Dim _pagina As Integer = 1
            Dim _ultima As Integer = 1
            Dim _continuar As Boolean = True
            Dim _achados As RedeAncoraProdutoCnasModel = NULL
            Dim _i As Integer
            Dim _cna As Integer

            Try
                pChunk.ValidarTodos()
                _achados = New RedeAncoraProdutoCnasModel()

                While _continuar
                    _body = me.BuscarProdutoBulkSearch(pCodUsuario, pCodCentroDistribuicao, pCodEstado, pChunk, _pagina, pChunk.Length)
                    pResultado.QtdChunksApi = pResultado.QtdChunksApi + 1
                    me.PersistirImagensBulkDeBlob(_body, _achados, pResultado)
                    _ultima = RedeAncoraJsonHelper.ObterInteiroNoSufixo(_body, "last_page")

                    If _ultima <= 0 Then
                        _ultima = 1
                    End If

                    If _ultima <= _pagina Then
                        _continuar = False
                    Else
                        _pagina = _pagina + 1
                        If _pagina > 20 Then
                            _continuar = False
                        End If
                    End If
                Wend

                For _i = 0 To pChunk.Length - 1
                    _cna = pChunk.Take(_i)
                    If Not _achados.Contem(_cna) Then
                        pResultado.QtdNaoEncontrados = pResultado.QtdNaoEncontrados + 1
                    End If
                Next

                _achados.Free()
                _achados = NULL
            Catch ex As Exception
                If Assigned(_achados) Then
                    _achados.Free()
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

        ' Bulk-search de imagens: janela de 200 no blob. Sem TJSONObject na pagina inteira.
        Private Sub PersistirImagensBulkDeBlob(pBody As String, pAchados As RedeAncoraProdutoCnasModel, pResultado As RedeAncoraProdutoImagemSincronizacaoResultadoModel)
            Dim _arrayStart As Integer = 0
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _janela As String = ""
            Dim _idxAbre As Integer = 0
            Dim _objStart As Integer = 0
            Dim _objFim As Integer = 0
            Dim _cna As Integer = 0
            Dim _urlReal As String = ""
            Dim _urlIlustrativa As String = ""
            Dim _tecnicas As String = ""
            Dim _comImagem As Boolean = False
            Dim _acabou As Boolean = False

            _arrayStart = me.PosicaoArrayDataImagens(pBody)
            If _arrayStart <= 0 Then
                Throw New System.Exception("Resposta /products/bulk-search sem array data")
            End If

            _bodyLen = Len(pBody)
            _pos = _arrayStart + 1

            While _pos <= _bodyLen
                If _acabou Then
                    _pos = _bodyLen + 1
                Else
                    _janela = me.CopiarJanelaImagens(pBody, _pos, 200)
                    If _janela = "" Then
                        _acabou = True
                    Else
                        _idxAbre = me.PosicaoAbreObjetoImagens(_janela)
                        If _idxAbre < 0 Then
                            _acabou = True
                        Else
                            If _idxAbre = 0 Then
                                _pos = _pos + Len(_janela)
                            Else
                                _objStart = _pos + _idxAbre - 1
                                _objFim = me.AvancarFimObjetoImagens(pBody, _objStart)
                                If _objFim <= _objStart Then
                                    _acabou = True
                                Else
                                    _cna = me.ExtrairInteiroNoIntervaloImagens(pBody, _objStart, _objFim, "cna")
                                    If _cna > 0 Then
                                        If Not pAchados.Contem(_cna) Then
                                            pAchados.PushDistinct(_cna)
                                            _urlReal = me.ExtrairTextoNoIntervaloImagens(pBody, _objStart, _objFim, "imagemReal", 2000)
                                            _urlIlustrativa = me.ExtrairTextoNoIntervaloImagens(pBody, _objStart, _objFim, "imagemIlustrativa", 2000)
                                            _tecnicas = me.ExtrairArrayNoIntervaloImagens(pBody, _objStart, _objFim, "imagensTecnicas", 8000)
                                            _comImagem = me.PersistirImagensProdutoDeCampos(_cna, _urlReal, _urlIlustrativa, _tecnicas, True)
                                            pResultado.QtdProcessados = pResultado.QtdProcessados + 1
                                            If _comImagem Then
                                                pResultado.QtdComImagem = pResultado.QtdComImagem + 1
                                            Else
                                                pResultado.QtdSemImagem = pResultado.QtdSemImagem + 1
                                            End If
                                        End If
                                    End If
                                    _pos = _objFim + 1
                                End If
                            End If
                        End If
                    End If
                End If
            Wend
        End Sub

        Private Function CopiarJanelaImagens(pSrc As String, pStart As Integer, pLen As Integer) As String
            Dim _bodyLen As Integer = 0
            Dim _n As Integer = 0
            Dim _result As String = ""

            If pStart >= 1 Then
                If pLen > 0 Then
                    _bodyLen = Len(pSrc)
                    If pStart <= _bodyLen Then
                        _n = pLen
                        If _n > 200 Then
                            _n = 200
                        End If
                        If (pStart + _n - 1) > _bodyLen Then
                            _n = _bodyLen - pStart + 1
                        End If
                        If _n > 0 Then
                            _result = Mid(pSrc, pStart, _n)
                        End If
                    End If
                End If
            End If
            CopiarJanelaImagens = _result
        End Function

        Private Function PosicaoArrayDataImagens(pBody As String) As Integer
            Dim _base As Integer = 1
            Dim _tentativa As Integer = 0
            Dim _prefix As String = ""
            Dim _q As String = Chr(34)
            Dim _needle As String = ""
            Dim _idx As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _achou As Boolean = False

            PosicaoArrayDataImagens = 0
            _needle = _q & "data" & _q

            While _tentativa < 3
                If _achou Then
                    _tentativa = 3
                Else
                    _prefix = me.CopiarJanelaImagens(pBody, _base, 200)
                    _idx = InStr(_prefix, _needle)
                    If _idx > 0 Then
                        _i = _idx + Len(_needle)
                        While _i <= Len(_prefix)
                            _ch = Mid(_prefix, _i, 1)
                            If _ch = " " Or _ch = ":" Then
                                _i = _i + 1
                            Else
                                Exit While
                            End If
                        Wend
                        If _i <= Len(_prefix) Then
                            If Mid(_prefix, _i, 1) = "[" Then
                                PosicaoArrayDataImagens = _base + _i - 1
                                _achou = True
                            End If
                        End If
                    End If
                    _tentativa = _tentativa + 1
                    _base = _base + 160
                End If
            Wend
        End Function

        Private Function PosicaoAbreObjetoImagens(pJanela As String) As Integer
            Dim _len As Integer = Len(pJanela)
            Dim _i As Integer = 1
            Dim _ch As String = ""
            Dim _idx As Integer = 0
            Dim _result As Integer = 0

            While _i <= _len
                If _idx = 0 Then
                    _ch = Mid(pJanela, _i, 1)
                    If _ch = " " Or _ch = "," Or _ch = Chr(9) Or _ch = Chr(10) Or _ch = Chr(13) Then
                        _i = _i + 1
                    Else
                        _idx = _i
                    End If
                Else
                    _i = _len + 1
                End If
            Wend

            If _idx > 0 Then
                _ch = Mid(pJanela, _idx, 1)
                If _ch = "]" Then
                    _result = -1
                Else
                    If _ch = "{" Then
                        _result = _idx
                    End If
                End If
            End If
            PosicaoAbreObjetoImagens = _result
        End Function

        Private Function AvancarFimObjetoImagens(pBody As String, pStart As Integer) As Integer
            Dim _bodyLen As Integer = Len(pBody)
            Dim _pos As Integer = pStart
            Dim _janela As String = ""
            Dim _janelaLen As Integer = 0
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escape As Boolean = False
            Dim _fim As Integer = 0
            Dim _result As Integer = 0

            If pStart >= 1 Then
                If pStart <= _bodyLen Then
                    While _pos <= _bodyLen
                        If _fim = 0 Then
                            _janela = me.CopiarJanelaImagens(pBody, _pos, 200)
                            _janelaLen = Len(_janela)
                            If _janelaLen <= 0 Then
                                _fim = -1
                            Else
                                _i = 1
                                While _i <= _janelaLen
                                    If _fim = 0 Then
                                        _ch = Mid(_janela, _i, 1)
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
                                                                _fim = _pos + _i - 1
                                                            End If
                                                        End If
                                                    End If
                                                End If
                                            End If
                                        End If
                                    End If
                                    _i = _i + 1
                                Wend
                                If _fim = 0 Then
                                    _pos = _pos + _janelaLen
                                End If
                            End If
                        Else
                            _pos = _bodyLen + 1
                        End If
                    Wend
                End If
            End If

            If _fim > 0 Then
                _result = _fim
            End If
            AvancarFimObjetoImagens = _result
        End Function

        Private Function ExtrairInteiroNoIntervaloImagens(pBody As String, pInicio As Integer, pFim As Integer, pChave As String) As Integer
            Dim _pos As Integer = 0
            Dim _fatia As String = ""
            Dim _i As Integer = 1
            Dim _ch As String = ""
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _j As Integer = 0
            Dim _digits As String = "0123456789"
            Dim _tem As Boolean = False
            Dim _q As String = Chr(34)

            ExtrairInteiroNoIntervaloImagens = 0
            _pos = me.PosicaoChaveNoIntervaloImagens(pBody, pInicio, pFim, pChave)
            If _pos <= 0 Then
                Exit Function
            End If

            _fatia = me.CopiarJanelaImagens(pBody, _pos, 24)
            If Mid(_fatia, 1, 1) = _q Then
                _i = 2
            End If

            While _i <= Len(_fatia)
                _ch = Mid(_fatia, _i, 1)
                _d = -1
                For _j = 1 To 10
                    If Mid(_digits, _j, 1) = _ch Then
                        _d = _j - 1
                    End If
                Next
                If _d < 0 Then
                    If _tem Then
                        _i = Len(_fatia) + 1
                    Else
                        If _ch = " " Then
                            _i = _i + 1
                        Else
                            _i = Len(_fatia) + 1
                        End If
                    End If
                Else
                    _tem = True
                    _n = (_n * 10) + _d
                    _i = _i + 1
                End If
            Wend

            If _tem Then
                ExtrairInteiroNoIntervaloImagens = _n
            End If
        End Function

        Private Function ExtrairTextoNoIntervaloImagens(pBody As String, pInicio As Integer, pFim As Integer, pChave As String, pMax As Integer) As String
            Dim _pos As Integer = 0
            Dim _q As String = Chr(34)
            Dim _result As String = ""
            Dim _n As Integer = 0
            Dim _abs As Integer = 0
            Dim _janela As String = ""
            Dim _k As Integer = 1
            Dim _ch As String = ""
            Dim _escape As Boolean = False
            Dim _fechou As Boolean = False

            ExtrairTextoNoIntervaloImagens = ""
            _pos = me.PosicaoChaveNoIntervaloImagens(pBody, pInicio, pFim, pChave)
            If _pos <= 0 Then
                Exit Function
            End If

            If _pos > pFim Then
                Exit Function
            End If

            _abs = _pos
            While _abs <= pFim
                _ch = Mid(me.CopiarJanelaImagens(pBody, _abs, 1), 1, 1)
                If _ch = " " Or _ch = Chr(9) Then
                    _abs = _abs + 1
                Else
                    Exit While
                End If
            Wend

            If _abs > pFim Then
                Exit Function
            End If

            If Mid(me.CopiarJanelaImagens(pBody, _abs, 1), 1, 1) <> _q Then
                Exit Function
            End If

            _abs = _abs + 1
            While _abs <= pFim
                If _fechou Then
                    _abs = pFim + 1
                Else
                    If _n >= pMax Then
                        _fechou = True
                    Else
                        _janela = me.CopiarJanelaImagens(pBody, _abs, 200)
                        If _janela = "" Then
                            _fechou = True
                        Else
                            _k = 1
                            While _k <= Len(_janela)
                                If _fechou Then
                                    _k = Len(_janela) + 1
                                Else
                                    If _n >= pMax Then
                                        _fechou = True
                                    Else
                                        _ch = Mid(_janela, _k, 1)
                                        If _escape Then
                                            _result = _result & _ch
                                            _n = _n + 1
                                            _escape = False
                                        Else
                                            If _ch = "\" Then
                                                _escape = True
                                            Else
                                                If _ch = _q Then
                                                    _fechou = True
                                                Else
                                                    _result = _result & _ch
                                                    _n = _n + 1
                                                End If
                                            End If
                                        End If
                                        _k = _k + 1
                                        _abs = _abs + 1
                                    End If
                                End If
                            Wend
                        End If
                    End If
                End If
            Wend

            ExtrairTextoNoIntervaloImagens = _result
        End Function

        Private Function ExtrairArrayNoIntervaloImagens(pBody As String, pInicio As Integer, pFim As Integer, pChave As String, pMax As Integer) As String
            Dim _pos As Integer = 0
            Dim _q As String = Chr(34)
            Dim _result As String = ""
            Dim _n As Integer = 0
            Dim _abs As Integer = 0
            Dim _janela As String = ""
            Dim _k As Integer = 0
            Dim _ch As String = ""
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escape As Boolean = False
            Dim _fechou As Boolean = False
            Dim _comecou As Boolean = False

            ExtrairArrayNoIntervaloImagens = ""
            _pos = me.PosicaoChaveNoIntervaloImagens(pBody, pInicio, pFim, pChave)
            If _pos <= 0 Then
                Exit Function
            End If

            _abs = _pos
            While _abs <= pFim
                If _fechou Then
                    _abs = pFim + 1
                Else
                    If _n >= pMax Then
                        _fechou = True
                    Else
                        _janela = me.CopiarJanelaImagens(pBody, _abs, 200)
                        If _janela = "" Then
                            _fechou = True
                        Else
                            _k = 1
                            While _k <= Len(_janela)
                                If _fechou Or _n >= pMax Then
                                    _k = Len(_janela) + 1
                                    If _n >= pMax Then
                                        _fechou = True
                                    End If
                                Else
                                    _ch = Mid(_janela, _k, 1)
                                    If Not _comecou Then
                                        If _ch = " " Or _ch = ":" Then
                                            _k = _k + 1
                                            _abs = _abs + 1
                                        Else
                                            If _ch = "[" Then
                                                _comecou = True
                                                _depth = 1
                                                _result = _result & _ch
                                                _n = _n + 1
                                                _k = _k + 1
                                                _abs = _abs + 1
                                            Else
                                                _fechou = True
                                            End If
                                        End If
                                    Else
                                        _result = _result & _ch
                                        _n = _n + 1
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
                                                    If _ch = "[" Then
                                                        _depth = _depth + 1
                                                    Else
                                                        If _ch = "]" Then
                                                            _depth = _depth - 1
                                                            If _depth = 0 Then
                                                                _fechou = True
                                                            End If
                                                        End If
                                                    End If
                                                End If
                                            End If
                                        End If
                                        _k = _k + 1
                                        _abs = _abs + 1
                                    End If
                                End If
                            Wend
                        End If
                    End If
                End If
            Wend

            ExtrairArrayNoIntervaloImagens = _result
        End Function

        Private Function PosicaoChaveNoIntervaloImagens(pBody As String, pInicio As Integer, pFim As Integer, pChave As String) As Integer
            Dim _pos As Integer = pInicio
            Dim _q As String = Chr(34)
            Dim _needle As String = _q & pChave & _q & ":"
            Dim _needleLen As Integer = Len(_needle)
            Dim _janela As String = ""
            Dim _idx As Integer = 0
            Dim _achou As Boolean = False
            Dim _overlap As Integer = _needleLen + 2

            PosicaoChaveNoIntervaloImagens = 0
            If _overlap < 16 Then
                _overlap = 16
            End If

            While _pos <= pFim
                If _achou Then
                    _pos = pFim + 1
                Else
                    _janela = me.CopiarJanelaImagens(pBody, _pos, 200)
                    If _janela = "" Then
                        _pos = pFim + 1
                    Else
                        _idx = InStr(_janela, _needle)
                        If _idx > 0 Then
                            PosicaoChaveNoIntervaloImagens = _pos + _idx + _needleLen - 1
                            _achou = True
                        Else
                            If Len(_janela) < 200 Then
                                _pos = pFim + 1
                            Else
                                _pos = _pos + 200 - _overlap
                                If _pos > pFim Then
                                    _pos = pFim + 1
                                End If
                            End If
                        End If
                    End If
                End If
            Wend
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
