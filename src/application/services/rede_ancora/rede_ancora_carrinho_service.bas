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
Imports usuario_model
Imports date_helper

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

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp("DELETE /checkout/items", _response))
                End If

                RemoverItem = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
                _response.Free()
                _api.Free()
            Catch ex As Exception
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

            TryConsultarCarrinho = Null

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/checkout/" + pIdCarrinho))

                If _response.IsSuccess Then
                    TryConsultarCarrinho = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
                End If

                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If
            End Try
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

                ExecutarConsultaCarrinho = me.ProcessarRespostaCarrinho(pCodUsuario, _response, Null)
                _response.Free()
                _api.Free()
            Catch ex As Exception
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
            Dim _json As TJSONObject = Null
            Dim _data As TJSONObject = Null
            Dim _carrinho As RedeAncoraCarrinhoModel = Null
            Dim _existentes As RedeAncoraCarrinhoItensModel = Null
            Dim _i As Integer

            _json = pResponse.BodyAsJsonObject()

            If Not Assigned(_json) Then
                Throw New System.Exception("Resposta checkout sem JSON valido")
            End If

            _data = RedeAncoraJsonHelper.ObterDataObjeto(_json)

            If Not Assigned(_data) Then
                _json.Free()
                Throw New System.Exception("Resposta checkout sem objeto data")
            End If

            _carrinho = New RedeAncoraCarrinhoModel()
            me.MapearCarrinho(_data, _carrinho, _carrinho.Itens, pItensSolicitacao)
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

            _data.Free()
            _json.Free()
            ProcessarRespostaCarrinho = _carrinho
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

        Private Sub MapearCarrinho(pData As TJSONObject, pCarrinho As RedeAncoraCarrinhoModel, pItens As RedeAncoraCarrinhoItensModel, pItensSolicitacao As RedeAncoraCarrinhoItensSolicitacaoModel)
            Dim _totals As TJSONObject = Null
            Dim _items As TJSONArray = Null
            Dim _i As Integer
            Dim _sequenciaItem As Integer = 0

            pCarrinho.IdCarrinho = RedeAncoraJsonHelper.ObterTextoJson(pData, "cart_id")
            pCarrinho.Convertido = RedeAncoraJsonHelper.SimNao(RedeAncoraJsonHelper.ObterBooleanJson(pData, "converted"))
            pCarrinho.Canal = RedeAncoraJsonHelper.ObterTextoJson(pData, "channel")
            pCarrinho.QtdItens = RedeAncoraJsonHelper.ObterInteiroJson(pData, "items_count")
            pCarrinho.QtdItensTotal = RedeAncoraJsonHelper.ObterInteiroJson(pData, "items_qty_sum")
            pCarrinho.DataAtualizacao = DateTime()

            _totals = RedeAncoraJsonHelper.ObterObjetoJson(pData, "totals")
            If Assigned(_totals) Then
                pCarrinho.Subtotal = RedeAncoraJsonHelper.ObterDecimalJson(_totals, "subtotal")
                pCarrinho.Impostos = RedeAncoraJsonHelper.ObterDecimalJson(_totals, "taxes")
                pCarrinho.Total = RedeAncoraJsonHelper.ObterDecimalJson(_totals, "total")
                _totals.Free()
            End If

            _items = RedeAncoraJsonHelper.ObterArrayJson(pData, "items")
            If Assigned(_items) Then
                Dim _itemsBlob As String = _items.ToString()
                Dim _elem As String = ""
                Dim _itemJson As TJSONObject = Null

                _items.Free()
                _items = Null

                For _i = 0 To 999
                    _elem = RedeAncoraJsonHelper.ExtrairElementoArrayJson(_itemsBlob, _i)

                    If _elem = "" Then
                        Exit For
                    End If

                    If Mid(_elem.Trim(), 1, 1) = "{" Then
                        _itemJson = New TJSONObject(_elem)
                        _sequenciaItem = _sequenciaItem + 1
                        Dim _item As RedeAncoraCarrinhoItemModel = me.MapearItemCarrinho(_itemJson, me.FormatarItemSequencial(_sequenciaItem))
                        me.AplicarCodProdutoItem(_item, pItensSolicitacao)
                        pItens.Push(_item)
                        _itemJson.Free()
                        _itemJson = Null
                    End If
                Next
            End If
        End Sub

        Private Function MapearItemCarrinho(pJson As TJSONObject, pItem As String) As RedeAncoraCarrinhoItemModel
            Dim _seller As TJSONObject = Null
            Dim _item As New RedeAncoraCarrinhoItemModel()

            _item.CodCarrinho = 0
            _item.Item = pItem
            _item.IdItemApi = RedeAncoraJsonHelper.ObterInteiroJson(pJson, "item_id")
            _item.Cna = RedeAncoraJsonHelper.ObterInteiroJson(pJson, "cna")
            _item.CodCondicaoPagamento = RedeAncoraJsonHelper.ObterInteiroJson(pJson, "cond_pag")
            _item.DescricaoCondicaoPagamento = RedeAncoraJsonHelper.ObterTextoJson(pJson, "cond_pag_label")
            _item.CodigoReferenciaFabricante = RedeAncoraJsonHelper.ObterTextoJson(pJson, "code")
            _item.Descricao = RedeAncoraJsonHelper.ObterTextoJson(pJson, "description")
            _item.CodModalidade = RedeAncoraJsonHelper.ObterInteiroJson(pJson, "modality")
            _item.Quantidade = RedeAncoraJsonHelper.ObterInteiroJson(pJson, "qty")
            _item.PrecoUnitario = RedeAncoraJsonHelper.ObterDecimalJson(pJson, "unit_price")
            _item.ImpostoUnitario = RedeAncoraJsonHelper.ObterDecimalJson(pJson, "unit_taxes")

            _seller = RedeAncoraJsonHelper.ObterObjetoJson(pJson, "seller")
            If Assigned(_seller) Then
                _item.CodCentroDistribuicao = RedeAncoraJsonHelper.ObterInteiroJson(_seller, "seller_id")
                _seller.Free()
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
            Dim _msg As String = ""

            _msg = pOperacao + " Rede Ancora falhou. HTTP " + Parser.IntegerToString(pResponse.StatusCode)

            If pResponse.Body <> "" Then
                _msg = _msg + ": " + pResponse.Body
            End If

            MontarErroHttp = _msg
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
