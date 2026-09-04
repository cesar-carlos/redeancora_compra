Imports mod_logger
Imports mod_tobject
Imports try_parser
Imports usuario_service
Imports rede_ancora_json_helper
Imports rede_ancora_empresa_model
Imports rede_ancora_centros_distribuicao_model
Imports rede_ancora_modalidades_model
Imports rede_ancora_produto_vinculos_model
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_codigos_model
Imports rede_ancora_produto_precos_estoque_model
Imports rede_ancora_carrinho_model
Imports rede_ancora_carrinho_itens_solicitacao_model
Imports rede_ancora_carrinho_item_solicitacao_model
Imports rede_ancora_carrinho_itens_ids_model
Imports rede_ancora_checkout_revisao_model
Imports rede_ancora_checkout_pagamentos_model
Imports rede_ancora_checkout_entregas_solicitacao_model
Imports rede_ancora_checkout_entrega_solicitacao_model
Imports rede_ancora_checkout_entrega_seller_model
Imports rede_ancora_checkout_entrega_opcao_model
Imports rede_ancora_checkout_condicoes_pagamento_model
Imports rede_ancora_logistica_transportadores_model
Imports rede_ancora_pedidos_model

Namespace rede_ancora_checkout_bootstrap
    Class RedeAncoraCheckoutBootstrap
        Inherits TTObject

        Private _configurado As String
        Private _habilitado As Boolean
        Private _chaveApi As String
        Private _inicializarRedeAncora As Boolean
        Private _cna As Integer
        Private _quantidade As Integer
        Private _codModalidade As Integer
        Private _confirmarPedido As Boolean
        Private _deletarCarrinhoAoFinal As Boolean
        Private _testarEndpointsProduto As Boolean

        Sub New()
            MyBase.New()
            me._habilitado = True
            me._chaveApi = ""
            me._inicializarRedeAncora = False
            me._cna = 0
            me._quantidade = 1
            me._codModalidade = 1
            me._confirmarPedido = False
            me._deletarCarrinhoAoFinal = False
            me._testarEndpointsProduto = True
        End Sub

        Sub Definir(pHabilitar As Boolean)
            me._configurado = "S"
            me._habilitado = pHabilitar
        End Sub

        Sub DefinirChaveApi(pChaveApi As String)
            me._chaveApi = pChaveApi
        End Sub

        Sub DefinirInicializarRedeAncora(pInicializar As Boolean)
            me._inicializarRedeAncora = pInicializar
        End Sub

        Sub DefinirCna(pCna As Integer)
            me._cna = pCna
        End Sub

        Sub DefinirQuantidade(pQuantidade As Integer)
            me._quantidade = pQuantidade
        End Sub

        Sub DefinirModalidade(pCodModalidade As Integer)
            me._codModalidade = pCodModalidade
        End Sub

        Sub DefinirConfirmarPedido(pConfirmar As Boolean)
            me._confirmarPedido = pConfirmar
        End Sub

        Sub DefinirDeletarCarrinhoAoFinal(pDeletar As Boolean)
            me._deletarCarrinhoAoFinal = pDeletar
        End Sub

        Sub DefinirTestarEndpointsProduto(pTestar As Boolean)
            me._testarEndpointsProduto = pTestar
        End Sub

        Sub Executar()
            me.GarantirConfiguracaoPadrao()

            If Not me._habilitado Then
                mod_logger.Printe("Rede Ancora checkout bootstrap desabilitado.")
                Exit Sub
            End If

            Dim _svc As UsuarioService = Null
            Dim _centros As RedeAncoraCentrosDistribuicaoModel = Null
            Dim _modalidades As RedeAncoraModalidadesModel = Null
            Dim _produtos As RedeAncoraProdutoVinculosModel = Null
            Dim _cna As Integer = 0
            Dim _codCentro As Integer = 0
            Dim _codEstado As Integer = 0
            Dim _codModalidade As Integer = me._codModalidade
            Dim _idCarrinho As String = ""

            Try
                mod_logger.Printe("=== Rede Ancora checkout bootstrap :: inicio ===")

                _svc = New UsuarioService()

                If Not _svc.PingRedeAncora() Then
                    Throw New System.Exception("API Rede Ancora indisponivel (ping falhou)")
                End If

                mod_logger.Printe("Passo 1: ping OK")


                me.GarantirAutenticacao(_svc)
                _svc.ValidarRedeAncoraPodeOperar()

                mod_logger.Printe("Passo 2-3: autenticacao e profile OK")

                _centros = _svc.ListarRedeAncoraCentrosDistribuicao()
                me.ResolverCentroDistribuicao(_centros, _codCentro, _codEstado)

                _modalidades = _svc.GarantirRedeAncoraModalidades()
                me.ResolverModalidade(_modalidades, _codModalidade)

                mod_logger.Printe("Passo 4: modalidades OK | CD " + Parser.IntegerToString(_codCentro) + " | estado " + Parser.IntegerToString(_codEstado) + " | modalidade " + Parser.IntegerToString(_codModalidade))

                _produtos = _svc.ListarRedeAncoraProdutosAtivos()
                _cna = me.ResolverCnaCheckout(_svc, _codCentro, _codModalidade, _produtos)

                mod_logger.Printe("CNA selecionado: " + Parser.IntegerToString(_cna))

                me.ExecutarFluxoCheckout(_svc, _codCentro, _codEstado, _codModalidade, _cna, _idCarrinho)

                If me._testarEndpointsProduto Then
                    me.ExecutarTestesProdutoComplementares(_svc, _codCentro, _codEstado, _cna, _produtos)
                End If

                mod_logger.Printe("=== Rede Ancora checkout bootstrap :: concluido ===")

                _produtos.Free()
                _modalidades.Free()
                _centros.Free()
                _svc.Free()
            Catch ex As Exception
                If Assigned(_produtos) Then
                    _produtos.Free()
                End If

                If Assigned(_modalidades) Then
                    _modalidades.Free()
                End If

                If Assigned(_centros) Then
                    _centros.Free()
                End If

                If Assigned(_svc) Then
                    _svc.Free()
                End If

                Throw ex
            End Try
        End Sub

        Private Sub ExecutarFluxoCheckout(pSvc As UsuarioService, pCodCentro As Integer, pCodEstado As Integer, pCodModalidade As Integer, pCna As Integer, ByRef pIdCarrinho As String)
            Dim _condicoes As String = ""
            Dim _carrinho As RedeAncoraCarrinhoModel = Null
            Dim _solicitacao As RedeAncoraCarrinhoItensSolicitacaoModel = Null
            Dim _itemSol As RedeAncoraCarrinhoItemSolicitacaoModel = Null
            Dim _itensIds As RedeAncoraCarrinhoItensIdsModel = Null
            Dim _revisao As RedeAncoraCheckoutRevisaoModel = Null
            Dim _pagamentos As RedeAncoraCheckoutPagamentosModel = Null
            Dim _entregas As RedeAncoraCheckoutEntregasSolicitacaoModel = Null
            Dim _transportadores As RedeAncoraLogisticaTransportadoresModel = Null
            Dim _pedidos As RedeAncoraPedidosModel = Null
            Dim _codCondicao As Integer = 0
            Dim _detalhePagamento As String = ""
            Dim _entregasLogistica As String = ""
            Dim _i As Integer = 0
            Dim _idCarrinhoSessao As String = ""
            Dim _itensIdsAntes As RedeAncoraCarrinhoItensIdsModel = Null
            Dim _itensIdsTeste As RedeAncoraCarrinhoItensIdsModel = Null
            Dim _itensDepois As RedeAncoraCarrinhoItensIdsModel = Null

            Try
                If me._deletarCarrinhoAoFinal And me._confirmarPedido Then
                    Throw New System.Exception("ConfirmarPedido=True incompativel com DeletarCarrinhoAoFinal em ambiente de producao")
                End If

                If me._deletarCarrinhoAoFinal Then
                    mod_logger.Printe("Limpeza ao final: apenas itens adicionados nesta sessao (nao apaga carrinho inteiro nem carrinho pre-existente)")
                Else
                    mod_logger.Printe("Limpeza ao final desabilitada (DefinirDeletarCarrinhoAoFinal(True) remove somente itens deste teste)")
                End If

                _condicoes = pSvc.ConsultarRedeAncoraProdutoCondicoes(pCna)
                mod_logger.Printe("Passo 5: GET /products/conditions/" + Parser.IntegerToString(pCna) + " OK")
                me.LogTextoTruncado("conditions", _condicoes)

                _carrinho = pSvc.AbrirRedeAncoraCarrinho()
                pIdCarrinho = _carrinho.IdCarrinho
                _idCarrinhoSessao = pIdCarrinho
                _itensIdsAntes = me.ExtrairItensIdsOpcional(_carrinho)
                mod_logger.Printe("Passo 6: GET /checkout OK | cart_id=" + pIdCarrinho + " | itens_pre_existentes=" + Parser.IntegerToString(_itensIdsAntes.Length))

                _solicitacao = New RedeAncoraCarrinhoItensSolicitacaoModel()
                _itemSol = New RedeAncoraCarrinhoItemSolicitacaoModel()
                _itemSol.Cna = pCna
                _itemSol.Quantidade = me._quantidade
                _solicitacao.Push(_itemSol)

                _carrinho.Free()
                _carrinho = Null
                _carrinho = pSvc.AdicionarItensRedeAncoraCarrinho(pIdCarrinho, pCodCentro, pCodModalidade, _solicitacao)
                mod_logger.Printe("Passo 7: POST /checkout/items OK")
                me.ImprimirCarrinho(_carrinho)

                _itensDepois = me.ExtrairItensIdsOpcional(_carrinho)
                _itensIdsTeste = me.FiltrarItensIdsNovos(_itensDepois, _itensIdsAntes)
                _itensDepois.Free()
                _itensDepois = Null
                mod_logger.Printe("Itens desta sessao de teste: " + Parser.IntegerToString(_itensIdsTeste.Length))

                _carrinho.Free()
                _carrinho = Null
                _carrinho = pSvc.ConsultarRedeAncoraCarrinho(pIdCarrinho)
                mod_logger.Printe("Passo 8: GET /checkout/{cartId} OK")

                _itensIds = me.ExtrairItensIds(_carrinho)

                _revisao = pSvc.RevisarRedeAncoraCarrinho(pIdCarrinho, _itensIds)
                mod_logger.Printe("Passo 9: POST /checkout/review OK | total=" + CStr(_revisao.Total))
                me.ImprimirRevisao(_revisao)

                _transportadores = pSvc.ListarRedeAncoraTransportadores()
                mod_logger.Printe("Passo 9a: GET /logistics/haulers OK (" + Parser.IntegerToString(_transportadores.Length) + " transportadores)")

                mod_logger.Printe("Debug: antes de MontarEntregas")
                _entregas = me.MontarEntregas(_revisao, _transportadores)
                mod_logger.Printe("Debug: MontarEntregas OK (" + Parser.IntegerToString(_entregas.Length) + " entregas)")

                mod_logger.Printe("Debug: antes de ConsultarPagamentos")
                _pagamentos = pSvc.ConsultarRedeAncoraPagamentos(pIdCarrinho, pCodCentro, pCodModalidade, _itensIds)
                mod_logger.Printe("Passo 10: POST /checkout/payments OK")
                me.ImprimirPagamentos(_pagamentos)

                _codCondicao = me.ObterPrimeiraCondicaoPagamento(_pagamentos)

                If _codCondicao <= 0 Then
                    Throw New System.Exception("Nenhuma condicao de pagamento retornada pela API")
                End If

                pSvc.AplicarRedeAncoraCondicaoPagamento(pIdCarrinho, _codCondicao, pCodEstado, _itensIds)
                mod_logger.Printe("Passo 11: PATCH /checkout/payments OK | condition_handle=" + Parser.IntegerToString(_codCondicao))

                _detalhePagamento = pSvc.ConsultarRedeAncoraDetalheCondicaoPagamento(pIdCarrinho, pCodCentro, pCodModalidade, _codCondicao)
                mod_logger.Printe("Passo 11a: POST /checkout/payments/condition OK")
                me.LogTextoTruncado("payments/condition", _detalhePagamento)

                _entregasLogistica = pSvc.ConsultarRedeAncoraEntregasLogistica(pIdCarrinho, _itensIds)
                mod_logger.Printe("Passo 11b: POST /logistics/carriers OK")
                me.LogTextoTruncado("logistics/carriers", _entregasLogistica)

                If me._confirmarPedido Then
                    _pedidos = pSvc.ConfirmarRedeAncoraPedido(pIdCarrinho, _entregas, _itensIds)
                    mod_logger.Printe("Passo 12: POST /checkout/order OK")
                    me.ImprimirPedidos(_pedidos)
                    pIdCarrinho = ""
                Else
                    mod_logger.Printe("Passo 12: POST /checkout/order PULADO (DefinirConfirmarPedido(True) para fechar pedido real)")

                    If me._deletarCarrinhoAoFinal Then
                        me.LimparItensTesteAoFinal(pSvc, _idCarrinhoSessao, pIdCarrinho, _itensIdsTeste, False)
                    End If
                End If

                If Assigned(_itensDepois) Then
                    _itensDepois.Free()
                End If

                If Assigned(_itensIdsTeste) Then
                    _itensIdsTeste.Free()
                End If

                If Assigned(_itensIdsAntes) Then
                    _itensIdsAntes.Free()
                End If

                If Assigned(_pedidos) Then
                    _pedidos.Free()
                End If

                If Assigned(_entregas) Then
                    _entregas.Free()
                End If

                If Assigned(_transportadores) Then
                    _transportadores.Free()
                End If

                If Assigned(_pagamentos) Then
                    _pagamentos.Free()
                End If

                If Assigned(_revisao) Then
                    _revisao.Free()
                End If

                If Assigned(_itensIds) Then
                    _itensIds.Free()
                End If

                ' _itemSol pertence a _solicitacao (Push assume a posse); liberar so a lista.
                If Assigned(_solicitacao) Then
                    _solicitacao.Free()
                End If

                If Assigned(_carrinho) Then
                    _carrinho.Free()
                End If
            Catch ex As Exception
                If Assigned(_pedidos) Then
                    _pedidos.Free()
                End If

                If Assigned(_entregas) Then
                    _entregas.Free()
                End If

                If Assigned(_transportadores) Then
                    _transportadores.Free()
                End If

                If Assigned(_pagamentos) Then
                    _pagamentos.Free()
                End If

                If Assigned(_revisao) Then
                    _revisao.Free()
                End If

                If Assigned(_itensIds) Then
                    _itensIds.Free()
                End If

                ' _itemSol pertence a _solicitacao (Push assume a posse); liberar so a lista.
                If Assigned(_solicitacao) Then
                    _solicitacao.Free()
                End If

                If Assigned(_carrinho) Then
                    _carrinho.Free()
                End If

                If Assigned(_itensDepois) Then
                    _itensDepois.Free()
                End If

                If Assigned(_itensIdsTeste) Then
                    If me._deletarCarrinhoAoFinal Then
                        If Not me._confirmarPedido Then
                            me.LimparItensTesteAoFinal(pSvc, _idCarrinhoSessao, pIdCarrinho, _itensIdsTeste, True)
                        End If
                    End If

                    _itensIdsTeste.Free()
                End If

                If Assigned(_itensIdsAntes) Then
                    _itensIdsAntes.Free()
                End If

                Throw ex
            End Try
        End Sub

        Private Sub ExecutarTestesProdutoComplementares(pSvc As UsuarioService, pCodCentro As Integer, pCodEstado As Integer, pCna As Integer, pProdutos As RedeAncoraProdutoVinculosModel)
            Dim _cnas As RedeAncoraProdutoCnasModel = Null
            Dim _precos As RedeAncoraProdutoPrecosEstoqueModel = Null
            Dim _bulk As String = ""
            Dim _full As String = ""
            Dim _warehouses As String = ""
            Dim _i As Integer = 0
            Dim _products As String = ""
            Dim _similares As String = ""
            Dim _bulkLote As String = ""
            Dim _precosCds As String = ""
            Dim _codes As RedeAncoraProdutoCodigosModel = Null

            Try
                mod_logger.Printe("--- Testes complementares de produto ---")

                _cnas = New RedeAncoraProdutoCnasModel()
                _cnas.Push(pCna)

                If Assigned(pProdutos) Then
                    For _i = 0 To pProdutos.Length - 1
                        If pProdutos.Take(_i).Cna <> pCna Then
                            _cnas.PushDistinct(pProdutos.Take(_i).Cna)

                            If _cnas.Length >= 2 Then
                                Exit For
                            End If
                        End If
                    Next
                End If

                _precos = pSvc.ConsultarRedeAncoraProdutoPrecosEstoques(pCodCentro, _cnas)
                mod_logger.Printe("Produto: POST /products/prices-stocks OK (" + Parser.IntegerToString(_precos.Length) + " itens)")
                me.ImprimirPrecosEstoques(_precos)

                _bulk = pSvc.BuscarRedeAncoraProdutoBulkSearch(pCodCentro, pCodEstado, _cnas, 1, 10)
                mod_logger.Printe("Produto: POST /products/bulk-search OK")
                me.LogTextoTruncado("bulk-search", _bulk)

                _full = pSvc.BuscarRedeAncoraProdutoFullSearch(pCodCentro, pCna, "", "")
                mod_logger.Printe("Produto: GET /products/full-search OK (cna=" + Parser.IntegerToString(pCna) + ")")
                me.LogTextoTruncado("full-search", _full)

                _warehouses = pSvc.ConsultarRedeAncoraProdutoCentrosComEstoque(pCna, pCodEstado, pCodCentro)
                mod_logger.Printe("Produto: POST /products/warehouses/" + Parser.IntegerToString(pCna) + " OK")
                me.LogTextoTruncado("warehouses", _warehouses)

                _products = pSvc.BuscarRedeAncoraProdutos(1, 10, "", "", pCna, "", "", 0, "", 0, 0)
                mod_logger.Printe("Produto: GET /products OK")
                me.LogTextoTruncado("products", _products)

                _similares = pSvc.ConsultarRedeAncoraProdutoSimilares(_cnas, pCodEstado, pCodCentro)
                mod_logger.Printe("Produto: POST /products/similares OK")
                me.LogTextoTruncado("similares", _similares)

                _bulkLote = pSvc.BuscarRedeAncoraProdutosPorLote(_cnas, Null, Null, 1, 10)
                mod_logger.Printe("Produto: POST /products/bulk OK")
                me.LogTextoTruncado("bulk", _bulkLote)

                _codes = New RedeAncoraProdutoCodigosModel()
                _precosCds = pSvc.ConsultarRedeAncoraProdutoPrecosEstoquesTodosCds(pCodCentro, _cnas, _codes)
                mod_logger.Printe("Produto: POST /products/prices-stocks-warehouses OK")
                me.LogTextoTruncado("prices-stocks-warehouses", _precosCds)
                _codes.Free()
                _codes = Null

                _precos.Free()
                _cnas.Free()
            Catch ex As Exception
                If Assigned(_codes) Then
                    _codes.Free()
                End If

                If Assigned(_precos) Then
                    _precos.Free()
                End If

                If Assigned(_cnas) Then
                    _cnas.Free()
                End If

                Throw New System.Exception("Erro nos testes complementares de produto: " + ex._getMessage())
            End Try
        End Sub

        Private Sub LimparItensTesteAoFinal(pSvc As UsuarioService, pIdCarrinhoSessao As String, pIdCarrinhoAtual As String, pItensIdsTeste As RedeAncoraCarrinhoItensIdsModel, pSilencioso As Boolean)
            Dim _msg As String = ""
            Dim _i As Integer = 0

            If pIdCarrinhoSessao = "" Then
                Exit Sub
            End If

            If pIdCarrinhoAtual <> pIdCarrinhoSessao Then
                mod_logger.Printe("Aviso: cart_id da sessao (" + pIdCarrinhoSessao + ") difere do atual (" + pIdCarrinhoAtual + "); limpeza ignorada")
                Exit Sub
            End If

            If Not Assigned(pItensIdsTeste) Then
                mod_logger.Printe("Passo 13: nenhum item de teste para remover (cart_id=" + pIdCarrinhoSessao + ")")
                Exit Sub
            End If

            If pItensIdsTeste.Length <= 0 Then
                mod_logger.Printe("Passo 13: nenhum item de teste para remover (cart_id=" + pIdCarrinhoSessao + ")")
                Exit Sub
            End If

            _msg = "Passo 13: removendo " + Parser.IntegerToString(pItensIdsTeste.Length) + " item(ns) de teste"
            _msg = _msg + " | cart_id=" + pIdCarrinhoSessao + " | item_ids="

            For _i = 0 To pItensIdsTeste.Length - 1
                If _i > 0 Then
                    _msg = _msg + ","
                End If

                _msg = _msg + Parser.IntegerToString(pItensIdsTeste.Take(_i))
            Next

            mod_logger.Printe(_msg)

            Try
                pSvc.RemoverItensRedeAncoraCarrinhoEmLote(pIdCarrinhoSessao, pItensIdsTeste)
                mod_logger.Printe("Passo 13: itens de teste removidos (POST /checkout/bulk/items/delete)")
            Catch ex As Exception
                If pSilencioso Then
                    mod_logger.Printe("Aviso: falha ao remover itens de teste do carrinho " + pIdCarrinhoSessao + ": " + ex._getMessage())
                Else
                    Throw New System.Exception("Falha ao remover itens de teste: " + ex._getMessage())
                End If
            End Try
        End Sub

        Private Sub GarantirConfiguracaoPadrao()
            If me._configurado = "S" Then
                Exit Sub
            End If

            me.Definir(True)
        End Sub

        Private Sub GarantirAutenticacao(pSvc As UsuarioService)
            Dim _empresa As RedeAncoraEmpresaModel = Null

            If me._chaveApi = "" Then
                Exit Sub
            End If

            mod_logger.Printe("Preparando chave API Rede Ancora...")

            Try
                pSvc.SalvarChaveApiRedeAncora(me._chaveApi)

                If me._inicializarRedeAncora Then
                    _empresa = pSvc.InicializarRedeAncora()
                    _empresa.Free()
                    _empresa = Null
                    mod_logger.Printe("Inicializacao Rede Ancora concluida.")
                End If
            Catch ex As Exception
                If Assigned(_empresa) Then
                    _empresa.Free()
                End If

                Throw New System.Exception("Falha ao configurar chave API Rede Ancora: " + ex._getMessage())
            End Try
        End Sub

        Private Sub ResolverCentroDistribuicao(pCentros As RedeAncoraCentrosDistribuicaoModel, ByRef pCodCentro As Integer, ByRef pCodEstado As Integer)
            Dim _i As Integer = 0

            If Not Assigned(pCentros) Then
                Throw New System.Exception("Nenhum centro de distribuicao encontrado. Execute InicializarRedeAncora antes do teste.")
            End If

            If pCentros.Length <= 0 Then
                Throw New System.Exception("Nenhum centro de distribuicao encontrado. Execute InicializarRedeAncora antes do teste.")
            End If

            For _i = 0 To pCentros.Length - 1
                If pCentros.Take(_i).Preferencial = "S" Then
                    pCodCentro = pCentros.Take(_i).CodCentroDistribuicao
                    pCodEstado = pCentros.Take(_i).CodEstado
                    Exit Sub
                End If
            Next

            pCodCentro = pCentros.Take(0).CodCentroDistribuicao
            pCodEstado = pCentros.Take(0).CodEstado
        End Sub

        Private Sub ResolverModalidade(pModalidades As RedeAncoraModalidadesModel, ByRef pCodModalidade As Integer)
            If pCodModalidade > 0 Then
                If Assigned(pModalidades) Then
                    If pModalidades.ExistePorCodigo(pCodModalidade) Then
                        Exit Sub
                    End If
                End If
            End If

            If Assigned(pModalidades) Then
                If pModalidades.Length > 0 Then
                    pCodModalidade = pModalidades.Take(0).CodModalidade
                    Exit Sub
                End If
            End If

            pCodModalidade = 1
        End Sub

        Private Function ResolverCnaCheckout(pSvc As UsuarioService, pCodCentro As Integer, pCodModalidade As Integer, pProdutos As RedeAncoraProdutoVinculosModel) As Integer
            Dim _cna As Integer = 0
            Dim _i As Integer = 0

            If me._cna > 0 Then
                ResolverCnaCheckout = me._cna
                Exit Function
            End If

            If Not Assigned(pProdutos) Then
                Throw New System.Exception("Nenhum produto sincronizado em Integracao.RedeAncoraProdutoVinculo. Execute o sync antes ou use DefinirCna.")
            End If

            If pProdutos.Length <= 0 Then
                Throw New System.Exception("Nenhum produto sincronizado em Integracao.RedeAncoraProdutoVinculo. Execute o sync antes ou use DefinirCna.")
            End If

            _cna = me.ObterCnaPreferencialDisponivel(pSvc, pCodCentro, pCodModalidade, pProdutos, 849766)

            If _cna > 0 Then
                ResolverCnaCheckout = _cna
                Exit Function
            End If

            _cna = me.ObterCnaPreferencialDisponivel(pSvc, pCodCentro, pCodModalidade, pProdutos, 880939)

            If _cna > 0 Then
                ResolverCnaCheckout = _cna
                Exit Function
            End If

            For _i = 0 To pProdutos.Length - 1
                _cna = pProdutos.Take(_i).Cna

                If me.CnaDisponivelParaCheckout(pSvc, pCodCentro, pCodModalidade, _cna) Then
                    ResolverCnaCheckout = _cna
                    Exit Function
                End If
            Next

            Throw New System.Exception("Nenhum CNA disponivel para checkout no seller/modalidade atuais. Use DefinirCna com um item nao bloqueado.")
        End Function

        Private Function ObterCnaPreferencialDisponivel(pSvc As UsuarioService, pCodCentro As Integer, pCodModalidade As Integer, pProdutos As RedeAncoraProdutoVinculosModel, pCna As Integer) As Integer
            ObterCnaPreferencialDisponivel = 0

            If me.ObterCnaNaLista(pProdutos, pCna) <= 0 Then
                Exit Function
            End If

            If me.CnaDisponivelParaCheckout(pSvc, pCodCentro, pCodModalidade, pCna) Then
                ObterCnaPreferencialDisponivel = pCna
            End If
        End Function

        Private Function ObterCnaNaLista(pProdutos As RedeAncoraProdutoVinculosModel, pCna As Integer) As Integer
            Dim _i As Integer = 0

            ObterCnaNaLista = 0

            If Not Assigned(pProdutos) Then
                Exit Function
            End If

            For _i = 0 To pProdutos.Length - 1
                If pProdutos.Take(_i).Cna = pCna Then
                    ObterCnaNaLista = pCna
                    Exit Function
                End If
            Next
        End Function

        Private Function CnaDisponivelParaCheckout(pSvc As UsuarioService, pCodCentro As Integer, pCodModalidade As Integer, pCna As Integer) As Boolean
            Dim _condicoes As String = ""
            Dim _json As TJSONObject = Null
            Dim _data As TJSONObject = Null
            Dim _product As TJSONObject = Null
            Dim _companies As TJSONArray = Null
            Dim _company As TJSONObject = Null
            Dim _details As TJSONObject = Null
            Dim _modalities As TJSONArray = Null
            Dim _modality As TJSONObject = Null
            Dim _i As Integer = 0
            Dim _j As Integer = 0
            Dim _bloqueado As Boolean = False
            Dim _descontinuado As Boolean = False
            Dim _disponivel As Boolean = False

            Try
                _condicoes = pSvc.ConsultarRedeAncoraProdutoCondicoes(pCna)
                _json = New TJSONObject(_condicoes)
                _data = RedeAncoraJsonHelper.ObterDataObjeto(_json)

                If Assigned(_data) Then
                    _product = RedeAncoraJsonHelper.ObterObjetoJson(_data, "product")

                    If Assigned(_product) Then
                        _companies = RedeAncoraJsonHelper.ObterArrayJson(_product, "companies")

                        If Assigned(_companies) Then
                            For _i = 0 To _companies.Length() - 1
                                _company = _companies.GetJSONObject(_i)

                                If RedeAncoraJsonHelper.ObterInteiroJson(_company, "empresa") = pCodCentro Then
                                    _details = RedeAncoraJsonHelper.ObterObjetoJson(_company, "details")

                                    If Assigned(_details) Then
                                        _bloqueado = RedeAncoraJsonHelper.ObterBooleanJson(_details, "bloqueado")
                                        _descontinuado = RedeAncoraJsonHelper.ObterBooleanJson(_details, "descontinuado")
                                        _details.Free()
                                        _details = Null
                                    End If

                                    If Not _bloqueado And Not _descontinuado Then
                                        _modalities = RedeAncoraJsonHelper.ObterArrayJson(_company, "modalities")

                                        If Assigned(_modalities) Then
                                            For _j = 0 To _modalities.Length() - 1
                                                _modality = _modalities.GetJSONObject(_j)

                                                If RedeAncoraJsonHelper.ObterInteiroJson(_modality, "modality_id") = pCodModalidade Then
                                                    _disponivel = True
                                                End If

                                                _modality.Free()
                                                _modality = Null

                                                If _disponivel Then
                                                    Exit For
                                                End If
                                            Next

                                            _modalities.Free()
                                            _modalities = Null
                                        End If
                                    End If
                                End If

                                _company.Free()
                                _company = Null

                                If _disponivel Then
                                    Exit For
                                End If
                            Next
                        End If
                    End If
                End If
            Catch ex As Exception
                _disponivel = False
            End Try

            If Assigned(_modality) Then
                _modality.Free()
            End If

            If Assigned(_modalities) Then
                _modalities.Free()
            End If

            If Assigned(_details) Then
                _details.Free()
            End If

            If Assigned(_company) Then
                _company.Free()
            End If

            If Assigned(_companies) Then
                _companies.Free()
            End If

            If Assigned(_product) Then
                _product.Free()
            End If

            If Assigned(_data) Then
                _data.Free()
            End If

            If Assigned(_json) Then
                _json.Free()
            End If

            CnaDisponivelParaCheckout = _disponivel
        End Function

        Private Function ExtrairItensIdsOpcional(pCarrinho As RedeAncoraCarrinhoModel) As RedeAncoraCarrinhoItensIdsModel
            Dim _result As New RedeAncoraCarrinhoItensIdsModel()
            Dim _i As Integer = 0

            If Not Assigned(pCarrinho) Then
                ExtrairItensIdsOpcional = _result
                Exit Function
            End If

            If Not Assigned(pCarrinho.Itens) Then
                ExtrairItensIdsOpcional = _result
                Exit Function
            End If

            If pCarrinho.Itens.Length <= 0 Then
                ExtrairItensIdsOpcional = _result
                Exit Function
            End If

            For _i = 0 To pCarrinho.Itens.Length - 1
                _result.Push(pCarrinho.Itens.Take(_i).IdItemApi)
            Next

            ExtrairItensIdsOpcional = _result
        End Function

        Private Function FiltrarItensIdsNovos(pItensDepois As RedeAncoraCarrinhoItensIdsModel, pItensAntes As RedeAncoraCarrinhoItensIdsModel) As RedeAncoraCarrinhoItensIdsModel
            Dim _result As New RedeAncoraCarrinhoItensIdsModel()
            Dim _i As Integer = 0
            Dim _idItem As Integer = 0

            If Not Assigned(pItensDepois) Then
                FiltrarItensIdsNovos = _result
                Exit Function
            End If

            If pItensDepois.Length <= 0 Then
                FiltrarItensIdsNovos = _result
                Exit Function
            End If

            For _i = 0 To pItensDepois.Length - 1
                _idItem = pItensDepois.Take(_i)

                If Not me.ItensIdsContem(pItensAntes, _idItem) Then
                    _result.Push(_idItem)
                End If
            Next

            FiltrarItensIdsNovos = _result
        End Function

        Private Function ItensIdsContem(pItensIds As RedeAncoraCarrinhoItensIdsModel, pIdItem As Integer) As Boolean
            Dim _i As Integer = 0

            ItensIdsContem = False

            If Not Assigned(pItensIds) Then
                Exit Function
            End If

            For _i = 0 To pItensIds.Length - 1
                If pItensIds.Take(_i) = pIdItem Then
                    ItensIdsContem = True
                    Exit Function
                End If
            Next
        End Function

        Private Function ExtrairItensIds(pCarrinho As RedeAncoraCarrinhoModel) As RedeAncoraCarrinhoItensIdsModel
            Dim _result As RedeAncoraCarrinhoItensIdsModel = Null

            _result = me.ExtrairItensIdsOpcional(pCarrinho)

            If Not Assigned(_result) Then
                Throw New System.Exception("Carrinho sem itens apos adicionar produto")
            End If

            If _result.Length <= 0 Then
                _result.Free()
                Throw New System.Exception("Carrinho sem itens apos adicionar produto")
            End If

            ExtrairItensIds = _result
        End Function

        Private Function MontarEntregas(pRevisao As RedeAncoraCheckoutRevisaoModel, pTransportadores As RedeAncoraLogisticaTransportadoresModel) As RedeAncoraCheckoutEntregasSolicitacaoModel
            Dim _result As New RedeAncoraCheckoutEntregasSolicitacaoModel()
            Dim _i As Integer = 0
            Dim _seller As RedeAncoraCheckoutEntregaSellerModel = Null
            Dim _opcao As RedeAncoraCheckoutEntregaOpcaoModel = Null
            Dim _entrega As RedeAncoraCheckoutEntregaSolicitacaoModel = Null

            If Not Assigned(pRevisao) Then
                Throw New System.Exception("Review sem opcoes de entrega (carriers)")
            End If

            If Not Assigned(pRevisao.EntregasSellers) Then
                Throw New System.Exception("Review sem opcoes de entrega (carriers)")
            End If

            If pRevisao.EntregasSellers.Length <= 0 Then
                Throw New System.Exception("Review sem opcoes de entrega (carriers)")
            End If

            For _i = 0 To pRevisao.EntregasSellers.Length - 1
                _seller = pRevisao.EntregasSellers.Take(_i)

                If Not Assigned(_seller.Opcoes) Then
                    Throw New System.Exception("Seller " + Parser.IntegerToString(_seller.CodCentroDistribuicao) + " sem carrier disponivel")
                End If

                If _seller.Opcoes.Length <= 0 Then
                    Throw New System.Exception("Seller " + Parser.IntegerToString(_seller.CodCentroDistribuicao) + " sem carrier disponivel")
                End If

                _opcao = _seller.Opcoes.Take(0)
                _entrega = New RedeAncoraCheckoutEntregaSolicitacaoModel()
                _entrega.CodCentroDistribuicao = _seller.CodCentroDistribuicao
                _entrega.CodEntrega = _opcao.CodEntrega
                _entrega.ExigeTransportador = _opcao.ExigeTransportador

                If _opcao.ExigeTransportadorSim() Then
                    If Not Assigned(pTransportadores) Then
                        Throw New System.Exception("Carrier exige transportador, mas GET /logistics/haulers nao retornou registros")
                    End If

                    If pTransportadores.Length <= 0 Then
                        Throw New System.Exception("Carrier exige transportador, mas GET /logistics/haulers nao retornou registros")
                    End If

                    _entrega.CodTransportador = pTransportadores.Take(0).CodTransportador
                End If

                _result.Push(_entrega)
            Next

            MontarEntregas = _result
        End Function

        Private Function ObterPrimeiraCondicaoPagamento(pPagamentos As RedeAncoraCheckoutPagamentosModel) As Integer
            Dim _codCondicao As Integer = 0

            _codCondicao = me.ObterPrimeiraCondicaoLista(pPagamentos.Fornecedor)

            If _codCondicao > 0 Then
                ObterPrimeiraCondicaoPagamento = _codCondicao
                Exit Function
            End If

            _codCondicao = me.ObterPrimeiraCondicaoLista(pPagamentos.Livre)

            If _codCondicao > 0 Then
                ObterPrimeiraCondicaoPagamento = _codCondicao
                Exit Function
            End If

            ObterPrimeiraCondicaoPagamento = me.ObterPrimeiraCondicaoLista(pPagamentos.Especial)
        End Function

        Private Function ObterPrimeiraCondicaoLista(pLista As RedeAncoraCheckoutCondicoesPagamentoModel) As Integer
            ObterPrimeiraCondicaoLista = 0

            If Not Assigned(pLista) Then
                Exit Function
            End If

            If pLista.Length <= 0 Then
                Exit Function
            End If

            ObterPrimeiraCondicaoLista = pLista.Take(0).CodCondicaoPagamento
        End Function

        Private Sub ImprimirCarrinho(pCarrinho As RedeAncoraCarrinhoModel)
            Dim _i As Integer = 0
            Dim _msg As String = ""

            If Not Assigned(pCarrinho) Then
                Exit Sub
            End If

            _msg = "  Carrinho: itens=" + Parser.IntegerToString(pCarrinho.QtdItens) + " | qty=" + Parser.IntegerToString(pCarrinho.QtdItensTotal) + " | total=" + CStr(pCarrinho.Total)
            mod_logger.Printe(_msg)

            If Assigned(pCarrinho.Itens) Then
                For _i = 0 To pCarrinho.Itens.Length - 1
                    _msg = "    item_id=" + Parser.IntegerToString(pCarrinho.Itens.Take(_i).IdItemApi)
                    _msg = _msg + " | cna=" + Parser.IntegerToString(pCarrinho.Itens.Take(_i).Cna)
                    _msg = _msg + " | qty=" + Parser.IntegerToString(pCarrinho.Itens.Take(_i).Quantidade)
                    mod_logger.Printe(_msg)
                Next
            End If
        End Sub

        Private Sub ImprimirRevisao(pRevisao As RedeAncoraCheckoutRevisaoModel)
            Dim _i As Integer = 0
            Dim _j As Integer = 0
            Dim _seller As RedeAncoraCheckoutEntregaSellerModel = Null
            Dim _msg As String = ""

            If Not Assigned(pRevisao) Then
                Exit Sub
            End If

            _msg = "  Review: itens=" + Parser.IntegerToString(pRevisao.QtdItens) + " | subtotal=" + CStr(pRevisao.Subtotal) + " | taxes=" + CStr(pRevisao.Impostos)
            mod_logger.Printe(_msg)

            If Assigned(pRevisao.EntregasSellers) Then
                For _i = 0 To pRevisao.EntregasSellers.Length - 1
                    _seller = pRevisao.EntregasSellers.Take(_i)
                    _msg = "    seller " + Parser.IntegerToString(_seller.CodCentroDistribuicao) + " (" + _seller.NomeCentroDistribuicao + ")"
                    mod_logger.Printe(_msg)

                    If Assigned(_seller.Opcoes) Then
                        For _j = 0 To _seller.Opcoes.Length - 1
                            _msg = "      carrier " + Parser.IntegerToString(_seller.Opcoes.Take(_j).CodEntrega) + " | " + _seller.Opcoes.Take(_j).Nome
                            _msg = _msg + " | hauler=" + _seller.Opcoes.Take(_j).ExigeTransportador
                            mod_logger.Printe(_msg)
                        Next
                    End If
                Next
            End If
        End Sub

        Private Sub ImprimirPagamentos(pPagamentos As RedeAncoraCheckoutPagamentosModel)
            me.ImprimirCondicoesGrupo("vendor", pPagamentos.Fornecedor)
            me.ImprimirCondicoesGrupo("free", pPagamentos.Livre)
            me.ImprimirCondicoesGrupo("special", pPagamentos.Especial)
        End Sub

        Private Sub ImprimirCondicoesGrupo(pGrupo As String, pLista As RedeAncoraCheckoutCondicoesPagamentoModel)
            Dim _i As Integer = 0
            Dim _msg As String = ""

            If Not Assigned(pLista) Then
                Exit Sub
            End If

            If pLista.Length <= 0 Then
                Exit Sub
            End If

            For _i = 0 To pLista.Length - 1
                _msg = "  pagamento [" + pGrupo + "] " + Parser.IntegerToString(pLista.Take(_i).CodCondicaoPagamento)
                _msg = _msg + " | " + pLista.Take(_i).Descricao
                mod_logger.Printe(_msg)
            Next
        End Sub

        Private Sub ImprimirPrecosEstoques(pPrecos As RedeAncoraProdutoPrecosEstoqueModel)
            Dim _i As Integer = 0
            Dim _msg As String = ""

            If Not Assigned(pPrecos) Then
                Exit Sub
            End If

            For _i = 0 To pPrecos.Length - 1
                _msg = "  cna=" + Parser.IntegerToString(pPrecos.Take(_i).Cna)
                _msg = _msg + " | qtd=" + Parser.IntegerToString(pPrecos.Take(_i).QtdDisponivel)
                _msg = _msg + " | preco=" + CStr(pPrecos.Take(_i).PrecoTabela)
                mod_logger.Printe(_msg)
            Next
        End Sub

        Private Sub ImprimirPedidos(pPedidos As RedeAncoraPedidosModel)
            Dim _i As Integer = 0
            Dim _msg As String = ""

            If Not Assigned(pPedidos) Then
                Exit Sub
            End If

            For _i = 0 To pPedidos.Length - 1
                _msg = "  Pedido API id=" + Parser.IntegerToString(pPedidos.Take(_i).IdPedidoApi)
                _msg = _msg + " | total=" + CStr(pPedidos.Take(_i).ValorTotal)
                mod_logger.Printe(_msg)
            Next
        End Sub

        Private Sub LogTextoTruncado(pRotulo As String, pTexto As String)
            Dim _texto As String = pTexto
            Dim _limite As Integer = 2000

            If _texto = "" Then
                mod_logger.Printe("  " + pRotulo + ": (vazio)")
                Exit Sub
            End If

            If Len(_texto) > _limite Then
                _texto = Mid(_texto, 1, _limite) + "...[truncado]"
            End If

            mod_logger.Printe("  " + pRotulo + ": " + _texto)
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
