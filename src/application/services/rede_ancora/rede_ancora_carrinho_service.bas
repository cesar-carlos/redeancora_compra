Imports mod_tobject
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_empresa_service
Imports rede_ancora_json_helper
Imports rede_ancora_url_helper
Imports rede_ancora_produto_service
Imports rede_ancora_carrinho_model
Imports rede_ancora_carrinho_item_model
Imports rede_ancora_carrinho_itens_model
Imports rede_ancora_carrinho_itens_solicitacao_model
Imports rede_ancora_carrinho_repository
Imports rede_ancora_carrinho_item_repository
Imports rede_ancora_empresa_model
Imports rede_ancora_empresa_repository
Imports rede_ancora_carrinho_item_solicitacao_model
Imports rede_ancora_carrinho_itens_ids_model
Imports rede_ancora_produto_vinculo_model
Imports rede_ancora_produto_vinculo_repository
Imports http_response
Imports string_helper
Imports transactions
Imports rede_ancora_integracao_context
Imports rede_ancora_http_erro_helper
Imports usuario_model
Imports date_helper
Imports mod_logger

Namespace rede_ancora_carrinho_service
    Class RedeAncoraCarrinhoService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _empresaService As RedeAncoraEmpresaService
        Private _carrinhoRepository As RedeAncoraCarrinhoRepository
        Private _itemRepository As RedeAncoraCarrinhoItemRepository
        Private _empresaRepository As RedeAncoraEmpresaRepository
        Private _vinculoRepository As RedeAncoraProdutoVinculoRepository
        Private _produtoService As RedeAncoraProdutoService

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._empresaService = New RedeAncoraEmpresaService()
            me._carrinhoRepository = New RedeAncoraCarrinhoRepository()
            me._itemRepository = New RedeAncoraCarrinhoItemRepository()
            me._empresaRepository = New RedeAncoraEmpresaRepository()
            me._vinculoRepository = New RedeAncoraProdutoVinculoRepository()
            me._produtoService = New RedeAncoraProdutoService()
        End Sub

        Function AbrirOuRecuperarCarrinho(pCodUsuario As Integer) As RedeAncoraCarrinhoModel
            Dim _empresa As RedeAncoraEmpresaModel = Null
            Dim _idCarrinho As String = ""

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _empresa = me._empresaRepository.ObterPorCodUsuario(pCodUsuario)
                _idCarrinho = _empresa.IdCarrinhoAtual
                _empresa.Free()

                If _idCarrinho <> "" Then
                    Dim _carrinho As RedeAncoraCarrinhoModel = me.TryConsultarCarrinho(pCodUsuario, _idCarrinho)

                    If Assigned(_carrinho) Then
                        AbrirOuRecuperarCarrinho = _carrinho
                        Exit Function
                    End If
                End If

                AbrirOuRecuperarCarrinho = me.ConsultarCarrinhoAtivo(pCodUsuario)
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCarrinhoService.AbrirOuRecuperarCarrinho", ex)

                If Assigned(_empresa) Then
                    _empresa.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ConsultarCarrinhoAtivo(pCodUsuario As Integer) As RedeAncoraCarrinhoModel
            ConsultarCarrinhoAtivo = me.ExecutarConsultaCarrinho(pCodUsuario, RedeAncoraApiConfig.IntegrationUrl("/checkout"))
        End Function

        Function ConsultarCarrinho(pCodUsuario As Integer, pIdCarrinho As String) As RedeAncoraCarrinhoModel
            ConsultarCarrinho = me.ConsultarCarrinhoComFiltros(pCodUsuario, pIdCarrinho, "", "", "", "")
        End Function

        Function ConsultarCarrinhoComFiltros(pCodUsuario As Integer, pIdCarrinho As String, pBrandId As String, pInStock As String, pQuery As String, pAggregation As String) As RedeAncoraCarrinhoModel
            Dim _url As String = me.MontarUrlConsultaCarrinho(pIdCarrinho, pBrandId, pInStock, pQuery, pAggregation)
            ConsultarCarrinhoComFiltros = me.ExecutarConsultaCarrinho(pCodUsuario, _url)
        End Function

        Function ObterCarrinhoLocal(pCodUsuario As Integer) As RedeAncoraCarrinhoModel
            Dim _empresa As RedeAncoraEmpresaModel = Null
            Dim _carrinho As RedeAncoraCarrinhoModel = Null
            Dim _itensAntigos As RedeAncoraCarrinhoItensModel = Null

            Try
                _empresa = me._empresaRepository.ObterPorCodUsuario(pCodUsuario)

                If _empresa.IdCarrinhoAtual.Trim() = "" Then
                    _empresa.Free()
                    Throw New System.Exception("Carrinho local nao encontrado para o usuario. Codigo: 9137")
                End If

                _carrinho = me._carrinhoRepository.ObterPorIdCarrinho(_empresa.IdCarrinhoAtual)
                _empresa.Free()
                _itensAntigos = _carrinho.Itens
                _carrinho.Itens = me._itemRepository.ListarPorCarrinho(_carrinho.CodCarrinho)

                If Assigned(_itensAntigos) Then
                    _itensAntigos.Free()
                End If

                ObterCarrinhoLocal = _carrinho
            Catch ex As Exception
                If Assigned(_empresa) Then
                    _empresa.Free()
                End If

                If Assigned(_carrinho) Then
                    _carrinho.Free()
                End If

                Throw ex
            End Try
        End Function

        Function AdicionarItens(pCodUsuario As Integer, pIdCarrinho As String, pCodCentroDistribuicao As Integer, pCodModalidade As Integer, pItens As RedeAncoraCarrinhoItensSolicitacaoModel) As RedeAncoraCarrinhoModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _payloadBody As String = ""

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                pItens.ValidarTodos()
                me.ValidarProdutosAntesAdicionar(pCodUsuario, pItens)

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _payloadBody = me.MontarPayloadAdicionarItens(pCodCentroDistribuicao, pCodModalidade, pItens)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho + "/items"), _payloadBody)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("POST /checkout/items", _response))
                End If

                AdicionarItens = me.ProcessarRespostaCarrinho(pCodUsuario, _response, pItens)
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCarrinhoService.AdicionarItens", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw ex
            End Try
        End Function

        Function AtualizarItem(pCodUsuario As Integer, pIdCarrinho As String, pIdItemApi As Integer, pQuantidade As Integer, pCodModalidade As Integer) As RedeAncoraCarrinhoModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _payload As TJSONObject = Null

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)

                If pQuantidade <= 0 Then
                    Throw New System.Exception("Quantidade invalida para atualizacao de item")
                End If

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _payload = New TJSONObject()
                _payload.PutInteger("qty", pQuantidade)
                _payload.PutInteger("modality", pCodModalidade)
                _response = _api.PatchJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho + "/items/" + pIdItemApi.ToString()), _payload.ToString())

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("PATCH /checkout/items", _response))
                End If

                AtualizarItem = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
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

                Throw New System.Exception("Erro ao atualizar item do carrinho Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function RemoverItem(pCodUsuario As Integer, pIdCarrinho As String, pIdItemApi As Integer) As RedeAncoraCarrinhoModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.DeleteRequest(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho + "/items/" + pIdItemApi.ToString()), "")

                If _response.StatusCode = 404 Then
                    mod_logger.Info("DELETE /checkout/items HTTP 404 (item ja removido). Recarregando carrinho sem wipe.")
                    _response.Free()
                    _response = Null
                    _api.Free()
                    _api = Null
                    RemoverItem = me.ExecutarConsultaCarrinho(pCodUsuario, RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho))
                    Exit Function
                End If

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("DELETE /checkout/items", _response))
                End If

                RemoverItem = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCarrinhoService.RemoverItem", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao remover item do carrinho Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function AtualizarItensEmLote(pCodUsuario As Integer, pIdCarrinho As String, pItensIds As RedeAncoraCarrinhoItensIdsModel, pQuantidade As Integer, pCodModalidade As Integer, pCodCentroDistribuicao As Integer) As RedeAncoraCarrinhoModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _payload As TJSONObject = Null

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                pItensIds.ValidarTodos()

                If pQuantidade <= 0 Then
                    Throw New System.Exception("Quantidade invalida para atualizacao em lote")
                End If

                _payload = New TJSONObject()
                _payload.PutString("items", me.MontarArrayItensIdsJson(pItensIds))
                _payload.PutInteger("qty", pQuantidade)
                _payload.PutInteger("modality", pCodModalidade)
                _payload.PutInteger("seller", pCodCentroDistribuicao)

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.PatchJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho + "/bulk/items"), _payload.ToString())

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("PATCH /checkout/bulk/items", _response))
                End If

                AtualizarItensEmLote = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
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

                Throw New System.Exception("Erro ao atualizar itens em lote no carrinho Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function RemoverItensEmLote(pCodUsuario As Integer, pIdCarrinho As String, pItensIds As RedeAncoraCarrinhoItensIdsModel) As RedeAncoraCarrinhoModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _payload As TJSONObject = Null

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                pItensIds.ValidarTodos()

                _payload = New TJSONObject()
                _payload.PutString("items", me.MontarArrayItensIdsJson(pItensIds))

                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho + "/bulk/items/delete"), _payload.ToString())

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("POST /checkout/bulk/items/delete", _response))
                End If

                RemoverItensEmLote = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
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

                Throw New System.Exception("Erro ao remover itens em lote do carrinho Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Sub DeletarCarrinho(pCodUsuario As Integer, pIdCarrinho As String)
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _itensVazios As New RedeAncoraCarrinhoItensModel()
            Dim _carrinho As RedeAncoraCarrinhoModel = Null

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.DeleteRequest(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho), "")

                If Not _response.IsSuccess And _response.StatusCode <> 204 And _response.StatusCode <> 404 Then
                    Throw New System.Exception(me.MontarErroHttp("DELETE /checkout", _response))
                End If

                _carrinho = New RedeAncoraCarrinhoModel()
                If me._carrinhoRepository.TryObterPorIdCarrinho(pIdCarrinho, _carrinho) Then
                    me._itemRepository.SubstituirPorCarrinho(_carrinho.CodCarrinho, _itensVazios)
                    me._carrinhoRepository.ExcluirPorCodCarrinho(_carrinho.CodCarrinho)
                End If

                If Assigned(_carrinho) Then
                    _carrinho.Free()
                    _carrinho = NULL
                End If

                me.LimparIdCarrinhoEmpresa(pCodUsuario)
                _itensVazios.Free()
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_carrinho) Then
                    _carrinho.Free()
                End If

                If Assigned(_itensVazios) Then
                    _itensVazios.Free()
                End If
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao deletar carrinho Rede Ancora: " + ex._getMessage())
            End Try
        End Sub

        Function Reordenar(pCodUsuario As Integer, pIdPedidoApi As Integer) As RedeAncoraCarrinhoModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null

            Try
                If pIdPedidoApi <= 0 Then
                    Throw New System.Exception("IdPedidoApi invalido para reorder")
                End If

                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.PostJson(RedeAncoraApiConfig.IntegrationUrl("/sales/orders/" + Parser.IntegerToString(pIdPedidoApi) + "/reorder"), "")

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("POST /sales/orders/reorder", _response))
                End If

                Reordenar = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao refazer carrinho por pedido Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Private Function TryConsultarCarrinho(pCodUsuario As Integer, pIdCarrinho As String) As RedeAncoraCarrinhoModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _result As RedeAncoraCarrinhoModel = Null
            Dim _status As Integer = 0

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho))
                _status = _response.StatusCode

                If _response.IsSuccess Then
                    If _response.Body.Trim() <> "" Then
                        _result = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
                    Else
                        RedeAncoraHttpErroHelper.RegistrarFalha("GET /checkout/{cartId}", _status, "")
                        Throw New System.Exception("GET /checkout/{cartId} HTTP 200 com corpo vazio")
                    End If
                Else
                    If _status = 404 Then
                        mod_logger.Info("GET /checkout/{cartId} HTTP 404 — carrinho inexistente ou convertido")
                    Else
                        Throw New System.Exception(me.MontarErroHttp("GET checkout", _response))
                    End If
                End If

                _response.Free()
                _response = Null
                _api.Free()
                _api = Null
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCarrinhoService.TryConsultarCarrinho", ex)

                If Assigned(_result) Then
                    _result.Free()
                    _result = Null
                End If

                If Assigned(_response) Then
                    _response.Free()
                    _response = Null
                End If

                If Assigned(_api) Then
                    _api.Free()
                    _api = Null
                End If

                Throw New System.Exception("Erro ao consultar carrinho Rede Ancora: " + ex._getMessage())
            End Try

            TryConsultarCarrinho = _result
        End Function

        Private Function ExecutarConsultaCarrinho(pCodUsuario As Integer, pUrl As String) As RedeAncoraCarrinhoModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _urlAtivo As String = RedeAncoraApiConfig.IntegrationUrl("/checkout")

            Try
                me._empresaService.ValidarPodeOperar(pCodUsuario)
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(pUrl)

                If _response.StatusCode = 404 And pUrl <> _urlAtivo Then
                    _response.Free()
                    _response = _api.GetRequest(_urlAtivo)
                End If

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("GET checkout", _response))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET checkout", _response.StatusCode, _response.Body)

                ExecutarConsultaCarrinho = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCarrinhoService.ExecutarConsultaCarrinho", ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao consultar carrinho Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Private Function ProcessarRespostaCarrinho(pCodUsuario As Integer, pResponse As HttpResponse, pItensSolicitacao As RedeAncoraCarrinhoItensSolicitacaoModel) As RedeAncoraCarrinhoModel
            Dim _body As String = ""
            Dim _dataStart As Integer = 0
            Dim _dataFim As Integer = 0
            Dim _carrinho As RedeAncoraCarrinhoModel = Null
            Dim _existentes As RedeAncoraCarrinhoItensModel = Null
            Dim _result As RedeAncoraCarrinhoModel = Null
            Dim _i As Integer

            Try
                _body = pResponse.Body

                If _body.Trim() = "" Then
                    Throw New System.Exception("Resposta checkout vazia (sem JSON data)")
                End If

                _dataStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlob(_body, "data")

                If _dataStart <= 0 Then
                    Throw New System.Exception("Resposta checkout sem objeto data")
                End If

                _dataFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(_body, _dataStart)
                _carrinho = New RedeAncoraCarrinhoModel()
                me.MapearCarrinho(_body, _dataStart, _dataFim, _carrinho, _carrinho.Itens, pItensSolicitacao)
                _carrinho.CodCarrinho = me.ResolverCodCarrinhoLocal(_carrinho.IdCarrinho)

                For _i = 0 To _carrinho.Itens.Length - 1
                    _carrinho.Itens.Take(_i).CodCarrinho = _carrinho.CodCarrinho
                Next

                _existentes = me._itemRepository.ListarPorCarrinho(_carrinho.CodCarrinho)
                me.AplicarAuditoriaLancamento(_carrinho.Itens, _existentes, Assigned(pItensSolicitacao))
                _existentes.Free()
                _existentes = Null

                me.PersistirCarrinhoLocal(_carrinho, _carrinho.Itens)
                me.AtualizarIdCarrinhoEmpresa(pCodUsuario, _carrinho.IdCarrinho)

                _result = _carrinho
                _carrinho = Null
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCarrinhoService.ProcessarRespostaCarrinho", ex)

                If Assigned(_existentes) Then
                    _existentes.Free()
                    _existentes = Null
                End If

                If Assigned(_carrinho) Then
                    _carrinho.Free()
                    _carrinho = Null
                End If

                Throw New System.Exception("Erro ao processar resposta checkout Rede Ancora: " + ex._getMessage())
            End Try

            ProcessarRespostaCarrinho = _result
        End Function

        Private Sub PersistirCarrinhoLocal(pCarrinho As RedeAncoraCarrinhoModel, pItens As RedeAncoraCarrinhoItensModel)
            Dim _tx As Transaction = Transaction.Instance()

            Try
                _tx.StartTransaction("Integracao.RedeAncoraCarrinho Persist")
                me._carrinhoRepository.SalvarSemTransacao(pCarrinho)
                me._itemRepository.SubstituirPorCarrinhoSemTransacao(pCarrinho.CodCarrinho, pItens)
                _tx.AutoCommit()
            Catch ex As Exception
                _tx.Rollback()
                Throw New System.Exception("Erro ao persistir Integracao.RedeAncoraCarrinho: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Private Sub MapearCarrinho(pBody As String, pDataStart As Integer, pDataFim As Integer, pCarrinho As RedeAncoraCarrinhoModel, pItens As RedeAncoraCarrinhoItensModel, pItensSolicitacao As RedeAncoraCarrinhoItensSolicitacaoModel)
            Dim _totalsStart As Integer = 0
            Dim _totalsFim As Integer = 0
            Dim _itemsStart As Integer = 0
            Dim _itemsObjStart As Integer = 0
            Dim _itemStart As Integer = 0
            Dim _itemFim As Integer = 0
            Dim _i As Integer
            Dim _sequenciaItem As Integer = 0
            Dim _item As RedeAncoraCarrinhoItemModel = Null
            Dim _ch As String = ""

            Try
                pCarrinho.IdCarrinho = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBody, "cart_id", pDataStart, pDataFim)
                pCarrinho.Convertido = RedeAncoraJsonHelper.SimNao(RedeAncoraJsonHelper.ObterBooleanJsonDeBlobEntre(pBody, "converted", pDataStart, pDataFim))
                pCarrinho.Canal = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBody, "channel", pDataStart, pDataFim)
                pCarrinho.QtdItens = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "items_count", pDataStart, pDataFim)
                pCarrinho.QtdItensTotal = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "items_qty_sum", pDataStart, pDataFim)
                pCarrinho.DataAtualizacao = DateTime()

                _totalsStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlobApos(pBody, "totals", pDataStart)
                If _totalsStart > 0 Then
                    If pDataFim <= 0 Or _totalsStart <= pDataFim Then
                        _totalsFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBody, _totalsStart)
                        pCarrinho.Subtotal = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(pBody, "subtotal", _totalsStart, _totalsFim)
                        pCarrinho.Impostos = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(pBody, "taxes", _totalsStart, _totalsFim)
                        pCarrinho.Total = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(pBody, "total", _totalsStart, _totalsFim)
                    End If
                End If

                _itemsStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlobApos(pBody, "items", pDataStart)
                If _itemsStart > 0 Then
                    If pDataFim <= 0 Or _itemsStart <= pDataFim Then
                        For _i = 0 To 9999
                            _itemStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(pBody, _itemsStart, _i)

                            If _itemStart <= 0 Then
                                Exit For
                            End If

                            If pDataFim > 0 Then
                                If _itemStart > pDataFim Then
                                    Exit For
                                End If
                            End If

                            _ch = Mid(pBody, _itemStart, 1)
                            If _ch = "{" Then
                                Try
                                    _itemFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBody, _itemStart)
                                    _item = me.MapearItemCarrinho(pBody, _itemStart, _itemFim, me.FormatarItemSequencial(_sequenciaItem + 1))

                                    If _item.IdItemApi <= 0 Then
                                        RedeAncoraHttpErroHelper.RegistrarFalha("checkout cart item", 200, "item_id ausente")
                                        _item.Free()
                                        _item = Null
                                    Else
                                        _sequenciaItem = _sequenciaItem + 1
                                        me.AplicarCodProdutoItem(_item, pItensSolicitacao)
                                        pItens.Push(_item)
                                        _item = Null
                                    End If
                                Catch exItem As Exception
                                    RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCarrinhoService.MapearCarrinho.item", exItem)

                                    If Assigned(_item) Then
                                        _item.Free()
                                        _item = Null
                                    End If
                                End Try
                            End If
                        Next
                    End If
                Else
                    _itemsObjStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlobApos(pBody, "items", pDataStart)
                    If _itemsObjStart > 0 Then
                        If pDataFim <= 0 Or _itemsObjStart <= pDataFim Then
                            Throw New System.Exception("Resposta checkout.items veio como objeto, esperado array")
                        End If
                    End If
                End If
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCarrinhoService.MapearCarrinho", ex)

                If Assigned(_item) Then
                    _item.Free()
                    _item = Null
                End If

                Throw New System.Exception("Erro ao mapear carrinho Rede Ancora: " + ex._getMessage())
            End Try
        End Sub

        Private Function MapearItemCarrinho(pBody As String, pStart As Integer, pFim As Integer, pItem As String) As RedeAncoraCarrinhoItemModel
            Dim _item As New RedeAncoraCarrinhoItemModel()
            Dim _sellerStart As Integer = 0
            Dim _sellerFim As Integer = 0

            _item.CodCarrinho = 0
            _item.Item = pItem
            _item.IdItemApi = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "item_id", pStart, pFim)
            _item.Cna = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "cna", pStart, pFim)
            _item.CodCondicaoPagamento = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "cond_pag", pStart, pFim)
            _item.DescricaoCondicaoPagamento = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBody, "cond_pag_label", pStart, pFim)
            _item.CodigoReferenciaFabricante = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBody, "code", pStart, pFim)
            _item.Descricao = RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBody, "description", pStart, pFim)
            _item.CodModalidade = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "modality", pStart, pFim)
            _item.Quantidade = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "qty", pStart, pFim)
            _item.PrecoUnitario = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(pBody, "unit_price", pStart, pFim)
            _item.ImpostoUnitario = RedeAncoraJsonHelper.ObterDecimalJsonDeBlobEntre(pBody, "unit_taxes", pStart, pFim)

            _sellerStart = RedeAncoraJsonHelper.PosicaoInicioObjetoJsonDeBlobApos(pBody, "seller", pStart)
            If _sellerStart > 0 Then
                If pFim <= 0 Or _sellerStart <= pFim Then
                    _sellerFim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBody, _sellerStart)
                    _item.CodCentroDistribuicao = RedeAncoraJsonHelper.ObterInteiroJsonDeBlobEntre(pBody, "seller_id", _sellerStart, _sellerFim)
                End If
            End If

            MapearItemCarrinho = _item
        End Function

        Private Function ResolverCodCarrinhoLocal(pIdCarrinho As String) As Integer
            Dim _existente As RedeAncoraCarrinhoModel = Null

            ResolverCodCarrinhoLocal = me._carrinhoRepository.GerarProximoCodCarrinho()

            _existente = New RedeAncoraCarrinhoModel()
            If me._carrinhoRepository.TryObterPorIdCarrinho(pIdCarrinho, _existente) Then
                If _existente.CodCarrinho > 0 Then
                    ResolverCodCarrinhoLocal = _existente.CodCarrinho
                End If
            End If

            _existente.Free()
        End Function

        Private Function FormatarItemSequencial(pSequencia As Integer) As String
            FormatarItemSequencial = StringHelper.FillCharacterLeft(Parser.IntegerToString(pSequencia), "0", 5)
        End Function

        Private Sub AplicarCodProdutoItem(pItem As RedeAncoraCarrinhoItemModel, pItensSolicitacao As RedeAncoraCarrinhoItensSolicitacaoModel)
            Dim _i As Integer
            Dim _vinculo As RedeAncoraProdutoVinculoModel = Null

            If Assigned(pItensSolicitacao) Then
                For _i = 0 To pItensSolicitacao.Length - 1
                    Dim _solicitacao As RedeAncoraCarrinhoItemSolicitacaoModel = pItensSolicitacao.Take(_i)

                    If _solicitacao.Cna = pItem.Cna And _solicitacao.CodProduto > 0 Then
                        pItem.CodProduto = _solicitacao.CodProduto
                        Exit Sub
                    End If
                Next
            End If

            If pItem.CodProduto > 0 Then
                Exit Sub
            End If

            _vinculo = New RedeAncoraProdutoVinculoModel()
            If me._vinculoRepository.TryObterAtivoPorCna(pItem.Cna, _vinculo) Then
                pItem.CodProduto = _vinculo.CodProduto
            End If

            _vinculo.Free()
        End Sub

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

        Private Function MontarPayloadAdicionarItens(pCodCentroDistribuicao As Integer, pCodModalidade As Integer, pItens As RedeAncoraCarrinhoItensSolicitacaoModel) As String
            Dim _itemsJson As String = ""
            Dim _itemJson As String = ""
            Dim _payloadJson As String = ""
            Dim _i As Integer

            _itemsJson = "["

            For _i = 0 To pItens.Length - 1
                Dim _solicitacao As RedeAncoraCarrinhoItemSolicitacaoModel = pItens.Take(_i)

                If _i > 0 Then
                    _itemsJson = _itemsJson + ","
                End If

                _itemJson = "{""cna"":" + Parser.IntegerToString(_solicitacao.Cna)
                _itemJson = _itemJson + ",""qty"":" + Parser.IntegerToString(_solicitacao.Quantidade)
                _itemJson = _itemJson + "}"
                _itemsJson = _itemsJson + _itemJson
            Next

            _itemsJson = _itemsJson + "]"

            _payloadJson = "{""seller"":" + Parser.IntegerToString(pCodCentroDistribuicao)
            _payloadJson = _payloadJson + ",""modality"":" + Parser.IntegerToString(pCodModalidade)
            _payloadJson = _payloadJson + ",""items"":" + _itemsJson + "}"
            MontarPayloadAdicionarItens = _payloadJson
        End Function

        Private Sub AplicarAuditoriaLancamento(pItens As RedeAncoraCarrinhoItensModel, pItensExistentes As RedeAncoraCarrinhoItensModel, pStamparNovos As Boolean)
            Dim _usuario As UsuarioModel = Null
            Dim _i As Integer = 0
            Dim _item As RedeAncoraCarrinhoItemModel = Null
            Dim _existente As RedeAncoraCarrinhoItemModel = Null

            If Not Assigned(pItens) Then
                Exit Sub
            End If

            If pStamparNovos Then
                _usuario = RedeAncoraIntegracaoContext.ObterUsuarioLogado()
            End If

            For _i = 0 To pItens.Length - 1
                _item = pItens.Take(_i)
                _existente = me.ObterItemPorIdItemApi(pItensExistentes, _item.IdItemApi)

                If Assigned(_existente) Then
                    If _existente.PossuiAuditoriaLancamento() Then
                        _item.CopiarAuditoriaLancamento(_existente)
                    Else
                        _item.LimparAuditoriaLancamento()
                    End If
                ElseIf pStamparNovos Then
                    me.StamparAuditoriaItem(_item, _usuario)
                Else
                    _item.LimparAuditoriaLancamento()
                End If
            Next

            If Assigned(_usuario) Then
                _usuario.Free()
            End If
        End Sub

        Private Function ObterItemPorIdItemApi(pItens As RedeAncoraCarrinhoItensModel, pIdItemApi As Integer) As RedeAncoraCarrinhoItemModel
            ObterItemPorIdItemApi = Null

            If Not Assigned(pItens) Then
                Exit Function
            End If

            If pIdItemApi <= 0 Then
                Exit Function
            End If

            ObterItemPorIdItemApi = pItens.ObterPorIdItemApi(pIdItemApi)
        End Function

        Private Sub StamparAuditoriaItem(pItem As RedeAncoraCarrinhoItemModel, pUsuario As UsuarioModel)
            Dim _nome As String = ""

            If Not Assigned(pItem) Then
                Exit Sub
            End If

            If Not Assigned(pUsuario) Then
                pItem.LimparAuditoriaLancamento()
                Exit Sub
            End If

            _nome = pUsuario.UserName.Trim()

            If Len(_nome) > 30 Then
                _nome = Mid(_nome, 1, 30)
            End If

            pItem.CodUsuario = pUsuario.UserId
            pItem.NomeUsuario = _nome
            pItem.DataLancamento = DateHelper.TodayAsDateTime()
            pItem.HoraLancamento = DateHelper.TimeAsString()
            pItem.EstacaoTrabalho = pUsuario.ComputerName.Trim()
        End Sub

        Private Sub ValidarProdutosAntesAdicionar(pCodUsuario As Integer, pItens As RedeAncoraCarrinhoItensSolicitacaoModel)
            Dim _i As Integer

            For _i = 0 To pItens.Length - 1
                me._produtoService.ValidarProdutoParaCarrinho(pCodUsuario, pItens.Take(_i).Cna)
            Next
        End Sub

        Private Function MontarUrlConsultaCarrinho(pIdCarrinho As String, pBrandId As String, pInStock As String, pQuery As String, pAggregation As String) As String
            Dim _url As String = RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho)

            If pBrandId.Trim() <> "" Then
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "brand_id", pBrandId.Trim())
            End If

            If pInStock.Trim() <> "" Then
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "in_stock", pInStock.Trim())
            End If

            If pQuery.Trim() <> "" Then
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "query", pQuery.Trim())
            End If

            If pAggregation.Trim() <> "" Then
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "aggregation", pAggregation.Trim())
            End If

            MontarUrlConsultaCarrinho = _url
        End Function

        Private Sub AtualizarIdCarrinhoEmpresa(pCodUsuario As Integer, pIdCarrinho As String)
            Dim _empresa As RedeAncoraEmpresaModel = Null

            Try
                _empresa = me._empresaRepository.ObterPorCodUsuario(pCodUsuario)
                _empresa.IdCarrinhoAtual = pIdCarrinho
                me._empresaRepository.Salvar(_empresa)
                _empresa.Free()
            Catch ex As Exception
                If Assigned(_empresa) Then
                    _empresa.Free()
                End If

                Throw ex
            End Try
        End Sub

        Private Sub LimparIdCarrinhoEmpresa(pCodUsuario As Integer)
            Dim _empresa As RedeAncoraEmpresaModel = Null

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

                If Assigned(me._carrinhoRepository) Then
                    me._carrinhoRepository.Free()
                    me._carrinhoRepository = Null
                End If

                If Assigned(me._itemRepository) Then
                    me._itemRepository.Free()
                    me._itemRepository = Null
                End If

                If Assigned(me._empresaRepository) Then
                    me._empresaRepository.Free()
                    me._empresaRepository = Null
                End If

                If Assigned(me._vinculoRepository) Then
                    me._vinculoRepository.Free()
                    me._vinculoRepository = Null
                End If

                If Assigned(me._produtoService) Then
                    me._produtoService.Free()
                    me._produtoService = Null
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
