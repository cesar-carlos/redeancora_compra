Imports mod_tobject
Imports mod_logger
Imports try_parser
Imports usuario_model
Imports usuarios_model
Imports usuario_repository
Imports rede_ancora_integracao_context
Imports rede_ancora_autenticacao_model
Imports rede_ancora_autenticacao_service
Imports rede_ancora_empresa_model
Imports rede_ancora_empresa_service
Imports rede_ancora_centros_distribuicao_model
Imports rede_ancora_centro_distribuicao_model
Imports rede_ancora_modalidade_service
Imports rede_ancora_modalidades_model
Imports rede_ancora_carrinho_service
Imports rede_ancora_carrinho_model
Imports rede_ancora_carrinho_itens_solicitacao_model
Imports rede_ancora_catalogo_service
Imports rede_ancora_marcas_model
Imports rede_ancora_linhas_model
Imports rede_ancora_familias_model
Imports rede_ancora_produto_service
Imports rede_ancora_produto_sincronizacao_service
Imports rede_ancora_produto_sincronizacao_resultado_model
Imports rede_ancora_produto_sincronizacao_modo
Imports rede_ancora_produto_vinculo_model
Imports rede_ancora_produto_vinculos_model
Imports rede_ancora_produto_precos_estoque_model
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_codigos_model
Imports rede_ancora_produto_imagens_model
Imports rede_ancora_produto_imagem_sincronizacao_resultado_model
Imports rede_ancora_carrinho_itens_ids_model
Imports rede_ancora_checkout_service
Imports rede_ancora_checkout_revisao_model
Imports rede_ancora_checkout_pagamentos_model
Imports rede_ancora_checkout_entregas_solicitacao_model
Imports rede_ancora_logistica_transportadores_model
Imports rede_ancora_pedidos_model
Imports rede_ancora_produto_sincronizacao_opcoes_model
Imports rede_ancora_input_consultar_pagamentos
Imports rede_ancora_output_consultar_pagamentos
Imports rede_ancora_input_aplicar_condicao_pagamento
Imports rede_ancora_output_aplicar_condicao_pagamento
Imports rede_ancora_input_consultar_detalhe_condicao_pagamento
Imports rede_ancora_output_consultar_detalhe_condicao_pagamento
Imports rede_ancora_input_confirmar_pedido
Imports rede_ancora_output_confirmar_pedido
Imports rede_ancora_input_buscar_produtos
Imports rede_ancora_input_consultar_similares
Imports rede_ancora_input_buscar_produtos_por_lote
Imports rede_ancora_input_consultar_precos_estoques_cds
Imports rede_ancora_input_listar_pedidos_api
Imports rede_ancora_input_listar_itens_pedido_api
Imports rede_ancora_input_listar_pendencias_api
Imports rede_ancora_input_listar_pendencias_por_pedido_api
Imports rede_ancora_input_listar_pedidos_programados
Imports rede_ancora_input_listar_produtos_pedido_programado
Imports rede_ancora_input_solicitar_relatorio_pedido_programado
Imports rede_ancora_input_criar_transportador
Imports rede_ancora_input_atualizar_transportador
Imports rede_ancora_sales_service
Imports rede_ancora_pedido_programado_service
Imports rede_ancora_agenda_compras_service
Imports rede_ancora_api_config

Namespace usuario_service
    Class UsuarioService
        Inherits TTObject

        Private _repository As UsuarioRepository
        Private _redeAncoraAutenticacaoService As RedeAncoraAutenticacaoService
        Private _redeAncoraEmpresaService As RedeAncoraEmpresaService
        Private _redeAncoraModalidadeService As RedeAncoraModalidadeService
        Private _redeAncoraCarrinhoService As RedeAncoraCarrinhoService
        Private _redeAncoraCatalogoService As RedeAncoraCatalogoService
        Private _redeAncoraProdutoService As RedeAncoraProdutoService
        Private _redeAncoraProdutoSincronizacaoService As RedeAncoraProdutoSincronizacaoService
        Private _redeAncoraCheckoutService As RedeAncoraCheckoutService
        Private _redeAncoraSalesService As RedeAncoraSalesService
        Private _redeAncoraPedidoProgramadoService As RedeAncoraPedidoProgramadoService
        Private _redeAncoraAgendaComprasService As RedeAncoraAgendaComprasService

        Sub New()
            MyBase.New()
            me._repository = New UsuarioRepository()
            me._redeAncoraAutenticacaoService = New RedeAncoraAutenticacaoService()
            me._redeAncoraEmpresaService = New RedeAncoraEmpresaService()
            me._redeAncoraModalidadeService = New RedeAncoraModalidadeService()
            me._redeAncoraCarrinhoService = New RedeAncoraCarrinhoService()
            me._redeAncoraCatalogoService = New RedeAncoraCatalogoService()
            me._redeAncoraProdutoService = New RedeAncoraProdutoService()
            me._redeAncoraProdutoSincronizacaoService = New RedeAncoraProdutoSincronizacaoService()
            me._redeAncoraCheckoutService = New RedeAncoraCheckoutService()
            me._redeAncoraSalesService = New RedeAncoraSalesService()
            me._redeAncoraPedidoProgramadoService = New RedeAncoraPedidoProgramadoService()
            me._redeAncoraAgendaComprasService = New RedeAncoraAgendaComprasService()
        End Sub

        Function GetLoggedUsuario() As UsuarioModel
            GetLoggedUsuario = me._repository.GetLoggedUsuario()
        End Function

        Function GetByUserId(pUserId As Integer) As UsuarioModel
            GetByUserId = me._repository.GetByUserId(pUserId)
        End Function

        Function GetAll() As UsuariosModel
            GetAll = me._repository.GetAll()
        End Function

        Private Function ObterCodUsuarioIntegracao() As Integer
            ObterCodUsuarioIntegracao = RedeAncoraIntegracaoContext.ObterCodUsuarioLogado()
        End Function


        Function PingRedeAncora() As Boolean
            PingRedeAncora = me._redeAncoraAutenticacaoService.Ping()
        End Function

        Function ObterRedeAncoraAutenticacao() As RedeAncoraAutenticacaoModel
            ObterRedeAncoraAutenticacao = me._redeAncoraAutenticacaoService.ObterAutenticacao(me.ObterCodUsuarioIntegracao())
        End Function

        Function TryObterRedeAncoraAutenticacao(pItem As RedeAncoraAutenticacaoModel) As Boolean
            TryObterRedeAncoraAutenticacao = me._redeAncoraAutenticacaoService.TryObterAutenticacao(me.ObterCodUsuarioIntegracao(), pItem)
        End Function

        Function SincronizarRedeAncoraUsuarioApi() As RedeAncoraAutenticacaoModel
            SincronizarRedeAncoraUsuarioApi = me._redeAncoraAutenticacaoService.SincronizarUsuarioApi(me.ObterCodUsuarioIntegracao())
        End Function

        Sub SalvarChaveApiRedeAncora(pChaveApi As String)
            me._redeAncoraAutenticacaoService.SalvarChaveApi(me.ObterCodUsuarioIntegracao(), pChaveApi)
        End Sub

        Function InicializarRedeAncora() As RedeAncoraEmpresaModel
            Dim _empresa As RedeAncoraEmpresaModel = Null
            Dim _modalidades As RedeAncoraModalidadesModel = Null

            Try
                mod_logger.Printe("Rede Ancora inicializacao :: sync profile...")
                _empresa = me.SincronizarRedeAncoraPerfil()
                mod_logger.Printe("Rede Ancora inicializacao :: profile OK")

                mod_logger.Printe("Rede Ancora inicializacao :: sync modalidades...")
                _modalidades = me.SincronizarRedeAncoraModalidades()
                mod_logger.Printe("Rede Ancora inicializacao :: modalidades OK (" + Parser.IntegerToString(_modalidades.Length) + ")")
                _modalidades.Free()
                _modalidades = Null

                mod_logger.Printe("Rede Ancora inicializacao :: sync catalogo...")
                me.GarantirRedeAncoraCatalogo()
                mod_logger.Printe("Rede Ancora inicializacao :: catalogo OK")

                mod_logger.Printe("Rede Ancora inicializacao :: concluida.")
                InicializarRedeAncora = _empresa
            Catch ex As Exception
                If Assigned(_modalidades) Then
                    _modalidades.Free()
                End If

                If Assigned(_empresa) Then
                    _empresa.Free()
                End If

                Throw ex
            End Try
        End Function

        Function SincronizarRedeAncoraPerfil() As RedeAncoraEmpresaModel
            SincronizarRedeAncoraPerfil = me._redeAncoraEmpresaService.SincronizarPerfil(me.ObterCodUsuarioIntegracao())
        End Function

        Function ObterRedeAncoraEmpresa() As RedeAncoraEmpresaModel
            ObterRedeAncoraEmpresa = me._redeAncoraEmpresaService.ObterPerfil(me.ObterCodUsuarioIntegracao())
        End Function

        Function TryObterRedeAncoraEmpresa(pItem As RedeAncoraEmpresaModel) As Boolean
            TryObterRedeAncoraEmpresa = me._redeAncoraEmpresaService.TryObterPerfil(me.ObterCodUsuarioIntegracao(), pItem)
        End Function

        Function ListarRedeAncoraCentrosDistribuicao() As RedeAncoraCentrosDistribuicaoModel
            ListarRedeAncoraCentrosDistribuicao = me._redeAncoraEmpresaService.ListarCentrosDistribuicao(me.ObterCodUsuarioIntegracao())
        End Function

        Sub ValidarRedeAncoraPodeOperar()
            me._redeAncoraEmpresaService.ValidarPodeOperar(me.ObterCodUsuarioIntegracao())
        End Sub

        Sub ValidarRedeAncoraPermissoes(pPermissao As String)
            me._redeAncoraEmpresaService.ValidarPermissoes(me.ObterCodUsuarioIntegracao(), pPermissao)
        End Sub

        Sub SalvarRedeAncoraEmpresa(pModel As RedeAncoraEmpresaModel)
            me._redeAncoraEmpresaService.SalvarPerfilLocal(pModel)
        End Sub

        Function SincronizarRedeAncoraModalidades() As RedeAncoraModalidadesModel
            SincronizarRedeAncoraModalidades = me._redeAncoraModalidadeService.SincronizarModalidades(me.ObterCodUsuarioIntegracao())
        End Function

        Function GarantirRedeAncoraModalidades() As RedeAncoraModalidadesModel
            GarantirRedeAncoraModalidades = me._redeAncoraModalidadeService.GarantirModalidadesSincronizadas(me.ObterCodUsuarioIntegracao())
        End Function

        Function ListarRedeAncoraModalidades() As RedeAncoraModalidadesModel
            ListarRedeAncoraModalidades = me._redeAncoraModalidadeService.ListarModalidades()
        End Function

        Function ObterDescricaoRedeAncoraModalidade(pCodModalidade As Integer) As String
            ObterDescricaoRedeAncoraModalidade = me._redeAncoraModalidadeService.ObterDescricaoModalidade(pCodModalidade)
        End Function

        Sub ValidarRedeAncoraModalidade(pCodModalidade As Integer)
            me._redeAncoraModalidadeService.ValidarModalidade(pCodModalidade)
        End Sub

        Function AbrirRedeAncoraCarrinho() As RedeAncoraCarrinhoModel
            AbrirRedeAncoraCarrinho = me._redeAncoraCarrinhoService.AbrirOuRecuperarCarrinho(me.ObterCodUsuarioIntegracao())
        End Function

        Function ConsultarRedeAncoraCarrinho(pIdCarrinho As String) As RedeAncoraCarrinhoModel
            ConsultarRedeAncoraCarrinho = me._redeAncoraCarrinhoService.ConsultarCarrinho(me.ObterCodUsuarioIntegracao(), pIdCarrinho)
        End Function

        Function ConsultarRedeAncoraCarrinhoComFiltros(pIdCarrinho As String, pBrandId As String, pInStock As String, pQuery As String, pAggregation As String) As RedeAncoraCarrinhoModel
            ConsultarRedeAncoraCarrinhoComFiltros = me._redeAncoraCarrinhoService.ConsultarCarrinhoComFiltros(me.ObterCodUsuarioIntegracao(), pIdCarrinho, pBrandId, pInStock, pQuery, pAggregation)
        End Function

        Function ObterRedeAncoraCarrinhoLocal() As RedeAncoraCarrinhoModel
            ObterRedeAncoraCarrinhoLocal = me._redeAncoraCarrinhoService.ObterCarrinhoLocal(me.ObterCodUsuarioIntegracao())
        End Function

        Function AdicionarItensRedeAncoraCarrinho(pIdCarrinho As String, pCodCentroDistribuicao As Integer, pCodModalidade As Integer, pItens As RedeAncoraCarrinhoItensSolicitacaoModel) As RedeAncoraCarrinhoModel
            me.ValidarRedeAncoraModalidade(pCodModalidade)
            AdicionarItensRedeAncoraCarrinho = me._redeAncoraCarrinhoService.AdicionarItens(me.ObterCodUsuarioIntegracao(), pIdCarrinho, pCodCentroDistribuicao, pCodModalidade, pItens)
        End Function

        Function AtualizarItemRedeAncoraCarrinho(pIdCarrinho As String, pIdItemApi As Integer, pQuantidade As Integer, pCodModalidade As Integer) As RedeAncoraCarrinhoModel
            me.ValidarRedeAncoraModalidade(pCodModalidade)
            AtualizarItemRedeAncoraCarrinho = me._redeAncoraCarrinhoService.AtualizarItem(me.ObterCodUsuarioIntegracao(), pIdCarrinho, pIdItemApi, pQuantidade, pCodModalidade)
        End Function

        Function RemoverItemRedeAncoraCarrinho(pIdCarrinho As String, pIdItemApi As Integer) As RedeAncoraCarrinhoModel
            RemoverItemRedeAncoraCarrinho = me._redeAncoraCarrinhoService.RemoverItem(me.ObterCodUsuarioIntegracao(), pIdCarrinho, pIdItemApi)
        End Function

        Function AtualizarItensRedeAncoraCarrinhoEmLote(pIdCarrinho As String, pItensIds As RedeAncoraCarrinhoItensIdsModel, pQuantidade As Integer, pCodModalidade As Integer, pCodCentroDistribuicao As Integer) As RedeAncoraCarrinhoModel
            me.ValidarRedeAncoraModalidade(pCodModalidade)
            AtualizarItensRedeAncoraCarrinhoEmLote = me._redeAncoraCarrinhoService.AtualizarItensEmLote(me.ObterCodUsuarioIntegracao(), pIdCarrinho, pItensIds, pQuantidade, pCodModalidade, pCodCentroDistribuicao)
        End Function

        Function RemoverItensRedeAncoraCarrinhoEmLote(pIdCarrinho As String, pItensIds As RedeAncoraCarrinhoItensIdsModel) As RedeAncoraCarrinhoModel
            RemoverItensRedeAncoraCarrinhoEmLote = me._redeAncoraCarrinhoService.RemoverItensEmLote(me.ObterCodUsuarioIntegracao(), pIdCarrinho, pItensIds)
        End Function

        Sub DeletarRedeAncoraCarrinho(pIdCarrinho As String)
            me._redeAncoraCarrinhoService.DeletarCarrinho(me.ObterCodUsuarioIntegracao(), pIdCarrinho)
        End Sub

        Function RevisarRedeAncoraCarrinho(pIdCarrinho As String, pItensIds As RedeAncoraCarrinhoItensIdsModel) As RedeAncoraCheckoutRevisaoModel
            RevisarRedeAncoraCarrinho = me._redeAncoraCheckoutService.RevisarCarrinho(me.ObterCodUsuarioIntegracao(), pIdCarrinho, pItensIds)
        End Function

        Function ConsultarRedeAncoraPagamentos(pIdCarrinho As String, pCodCentroDistribuicao As Integer, pCodModalidade As Integer, pItensIds As RedeAncoraCarrinhoItensIdsModel) As RedeAncoraCheckoutPagamentosModel
            Dim _input As New RedeAncoraInputConsultarPagamentos()
            Dim _output As RedeAncoraOutputConsultarPagamentos = Null

            Try
                me.ValidarRedeAncoraModalidade(pCodModalidade)

                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.IdCarrinho = pIdCarrinho
                _input.CodCentroDistribuicao = pCodCentroDistribuicao
                _input.CodModalidade = pCodModalidade
                _input.ItensIds = pItensIds

                _output = me._redeAncoraCheckoutService.ConsultarPagamentos(_input)

                If Not Assigned(_output) Then
                    Throw New System.Exception("ConsultarPagamentos retornou output nulo")
                End If

                ConsultarRedeAncoraPagamentos = _output.Pagamentos
                _input.Free()
                _input = Null
                _output.Free()
                _output = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                If Assigned(_output) Then
                    _output.Free()
                End If

                Throw ex
            End Try
        End Function

        Function AplicarRedeAncoraCondicaoPagamento(pIdCarrinho As String, pCodCondicaoPagamento As Integer, pCodEstado As Integer, pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            Dim _input As New RedeAncoraInputAplicarCondicaoPagamento()
            Dim _output As RedeAncoraOutputAplicarCondicaoPagamento = Null

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.IdCarrinho = pIdCarrinho
                _input.CodCondicaoPagamento = pCodCondicaoPagamento
                _input.CodEstado = pCodEstado
                _input.ItensIds = pItensIds

                _output = me._redeAncoraCheckoutService.AplicarCondicaoPagamento(_input)

                If Not Assigned(_output) Then
                    Throw New System.Exception("AplicarCondicaoPagamento retornou output nulo")
                End If

                AplicarRedeAncoraCondicaoPagamento = _output.Resultado
                _input.Free()
                _input = Null
                _output.Free()
                _output = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                If Assigned(_output) Then
                    _output.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ConsultarRedeAncoraDetalheCondicaoPagamento(pIdCarrinho As String, pCodCentroDistribuicao As Integer, pCodModalidade As Integer, pCodCondicaoPagamento As Integer) As String
            Dim _input As New RedeAncoraInputConsultarDetalheCondicaoPagamento()
            Dim _output As RedeAncoraOutputConsultarDetalheCondicaoPagamento = Null

            Try
                me.ValidarRedeAncoraModalidade(pCodModalidade)

                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.IdCarrinho = pIdCarrinho
                _input.CodCentroDistribuicao = pCodCentroDistribuicao
                _input.CodModalidade = pCodModalidade
                _input.CodCondicaoPagamento = pCodCondicaoPagamento

                _output = me._redeAncoraCheckoutService.ConsultarDetalheCondicaoPagamento(_input)

                If Not Assigned(_output) Then
                    Throw New System.Exception("ConsultarDetalheCondicaoPagamento retornou output nulo")
                End If

                ConsultarRedeAncoraDetalheCondicaoPagamento = _output.Resultado
                _input.Free()
                _input = Null
                _output.Free()
                _output = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                If Assigned(_output) Then
                    _output.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ListarRedeAncoraTransportadores() As RedeAncoraLogisticaTransportadoresModel
            ListarRedeAncoraTransportadores = me._redeAncoraCheckoutService.ListarTransportadores(me.ObterCodUsuarioIntegracao())
        End Function

        Function ConsultarRedeAncoraEntregasLogistica(pIdCarrinho As String, pItensIds As RedeAncoraCarrinhoItensIdsModel) As String
            ConsultarRedeAncoraEntregasLogistica = me._redeAncoraCheckoutService.ConsultarEntregasLogistica(me.ObterCodUsuarioIntegracao(), pIdCarrinho, pItensIds)
        End Function

        Function ConfirmarRedeAncoraPedido(pIdCarrinho As String, pEntregas As RedeAncoraCheckoutEntregasSolicitacaoModel, pItensIds As RedeAncoraCarrinhoItensIdsModel) As RedeAncoraPedidosModel
            Dim _input As New RedeAncoraInputConfirmarPedido()
            Dim _output As RedeAncoraOutputConfirmarPedido = Null

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.IdCarrinho = pIdCarrinho
                _input.Entregas = pEntregas
                _input.ItensIds = pItensIds

                _output = me._redeAncoraCheckoutService.ConfirmarPedido(_input)

                If Not Assigned(_output) Then
                    Throw New System.Exception("ConfirmarPedido retornou output nulo")
                End If

                ConfirmarRedeAncoraPedido = _output.Pedidos
                _input.Free()
                _input = Null
                _output.Free()
                _output = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                If Assigned(_output) Then
                    _output.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ListarRedeAncoraPedidosLocal() As RedeAncoraPedidosModel
            ListarRedeAncoraPedidosLocal = me._redeAncoraCheckoutService.ListarPedidosLocal(me.ObterCodUsuarioIntegracao())
        End Function

        Function ReordenarRedeAncoraCarrinho(pIdPedidoApi As Integer) As RedeAncoraCarrinhoModel
            ReordenarRedeAncoraCarrinho = me._redeAncoraCarrinhoService.Reordenar(me.ObterCodUsuarioIntegracao(), pIdPedidoApi)
        End Function

        Function ListarRedeAncoraPedidosApi(pPagina As Integer, pTamanhoPagina As Integer, pOrdenarPor As String, pDirecaoOrdenacao As String, pCodModalidade As Integer, pCodCondicaoPagamento As Integer, pDataCriacao As String, pCodErpHandle As Integer, pCodErpSellerHandle As Integer, pEstado As String, pIdPedidoApi As Integer, pProduto As String, pNomeMarca As String, pCodigoProduto As String) As String
            Dim _input As New RedeAncoraInputListarPedidosApi()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.Pagina = pPagina
                _input.TamanhoPagina = pTamanhoPagina
                _input.OrdenarPor = pOrdenarPor
                _input.DirecaoOrdenacao = pDirecaoOrdenacao
                _input.CodModalidade = pCodModalidade
                _input.CodCondicaoPagamento = pCodCondicaoPagamento
                _input.DataCriacao = pDataCriacao
                _input.CodErpHandle = pCodErpHandle
                _input.CodErpSellerHandle = pCodErpSellerHandle
                _input.Estado = pEstado
                _input.IdPedidoApi = pIdPedidoApi
                _input.Produto = pProduto
                _input.NomeMarca = pNomeMarca
                _input.CodigoProduto = pCodigoProduto

                ListarRedeAncoraPedidosApi = me._redeAncoraSalesService.ListarPedidosApi(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ConsultarRedeAncoraPedidoApi(pIdPedidoApi As Integer) As String
            ConsultarRedeAncoraPedidoApi = me._redeAncoraSalesService.ConsultarPedidoApi(me.ObterCodUsuarioIntegracao(), pIdPedidoApi)
        End Function

        Function ListarRedeAncoraItensPedidoApi(pIdPedidoApi As Integer, pOrdenarPor As String, pDirecaoOrdenacao As String, pQuery As String, pMarca As String, pCodigo As String, pCna As Integer, pNome As String, pEstado As String, pIdItemApi As Integer) As String
            Dim _input As New RedeAncoraInputListarItensPedidoApi()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.IdPedidoApi = pIdPedidoApi
                _input.OrdenarPor = pOrdenarPor
                _input.DirecaoOrdenacao = pDirecaoOrdenacao
                _input.Query = pQuery
                _input.Marca = pMarca
                _input.Codigo = pCodigo
                _input.Cna = pCna
                _input.Nome = pNome
                _input.Estado = pEstado
                _input.IdItemApi = pIdItemApi

                ListarRedeAncoraItensPedidoApi = me._redeAncoraSalesService.ListarItensPedidoApi(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ConsultarRedeAncoraItemPedidoApi(pIdPedidoApi As Integer, pIdItemApi As Integer) As String
            ConsultarRedeAncoraItemPedidoApi = me._redeAncoraSalesService.ConsultarItemPedidoApi(me.ObterCodUsuarioIntegracao(), pIdPedidoApi, pIdItemApi)
        End Function

        Function CancelarRedeAncoraPedidoApi(pIdPedidoApi As Integer) As Boolean
            CancelarRedeAncoraPedidoApi = me._redeAncoraSalesService.CancelarPedidoApi(me.ObterCodUsuarioIntegracao(), pIdPedidoApi)
        End Function

        Function ListarRedeAncoraPendenciasApi(pPagina As Integer, pTamanhoPagina As Integer, pOrdenarPor As String, pDirecaoOrdenacao As String, pCodModalidade As Integer, pCodCondicaoPagamento As Integer, pDataCriacao As String, pCodErpHandle As Integer, pCodErpSellerHandle As Integer, pProduto As String, pIdPedidoApi As Integer, pCodigoProduto As String, pNomeMarca As String, pCna As Integer) As String
            Dim _input As New RedeAncoraInputListarPendenciasApi()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.Pagina = pPagina
                _input.TamanhoPagina = pTamanhoPagina
                _input.OrdenarPor = pOrdenarPor
                _input.DirecaoOrdenacao = pDirecaoOrdenacao
                _input.CodModalidade = pCodModalidade
                _input.CodCondicaoPagamento = pCodCondicaoPagamento
                _input.DataCriacao = pDataCriacao
                _input.CodErpHandle = pCodErpHandle
                _input.CodErpSellerHandle = pCodErpSellerHandle
                _input.Produto = pProduto
                _input.IdPedidoApi = pIdPedidoApi
                _input.CodigoProduto = pCodigoProduto
                _input.NomeMarca = pNomeMarca
                _input.Cna = pCna

                ListarRedeAncoraPendenciasApi = me._redeAncoraSalesService.ListarPendenciasApi(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ListarRedeAncoraPendenciasPorPedidoApi(pPagina As Integer, pTamanhoPagina As Integer, pOrdenarPor As String, pDirecaoOrdenacao As String, pCodModalidade As Integer, pCodErpSellerHandle As Integer, pEstado As String) As String
            Dim _input As New RedeAncoraInputListarPendenciasPorPedidoApi()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.Pagina = pPagina
                _input.TamanhoPagina = pTamanhoPagina
                _input.OrdenarPor = pOrdenarPor
                _input.DirecaoOrdenacao = pDirecaoOrdenacao
                _input.CodModalidade = pCodModalidade
                _input.CodErpSellerHandle = pCodErpSellerHandle
                _input.Estado = pEstado

                ListarRedeAncoraPendenciasPorPedidoApi = me._redeAncoraSalesService.ListarPendenciasPorPedidoApi(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ConsultarRedeAncoraTransportador(pIdTransportador As Integer) As String
            ConsultarRedeAncoraTransportador = me._redeAncoraCheckoutService.ConsultarTransportador(me.ObterCodUsuarioIntegracao(), pIdTransportador)
        End Function

        Function CriarRedeAncoraTransportador(pNome As String, pTipoDocumento As String, pDocumento As String, pTipoVeiculo As String, pPlacaVeiculo As String, pPessoaContato As String, pTelefoneContato As String, pObservacoes As String, pHabilitado As Boolean) As String
            Dim _input As New RedeAncoraInputCriarTransportador()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.Nome = pNome
                _input.TipoDocumento = pTipoDocumento
                _input.Documento = pDocumento
                _input.TipoVeiculo = pTipoVeiculo
                _input.PlacaVeiculo = pPlacaVeiculo
                _input.PessoaContato = pPessoaContato
                _input.TelefoneContato = pTelefoneContato
                _input.Observacoes = pObservacoes
                _input.Habilitado = pHabilitado

                CriarRedeAncoraTransportador = me._redeAncoraCheckoutService.CriarTransportador(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function AtualizarRedeAncoraTransportador(pIdTransportador As Integer, pNome As String, pTipoDocumento As String, pDocumento As String, pTipoVeiculo As String, pPlacaVeiculo As String, pPessoaContato As String, pTelefoneContato As String, pObservacoes As String, pHabilitado As Boolean) As String
            Dim _input As New RedeAncoraInputAtualizarTransportador()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.IdTransportador = pIdTransportador
                _input.Nome = pNome
                _input.TipoDocumento = pTipoDocumento
                _input.Documento = pDocumento
                _input.TipoVeiculo = pTipoVeiculo
                _input.PlacaVeiculo = pPlacaVeiculo
                _input.PessoaContato = pPessoaContato
                _input.TelefoneContato = pTelefoneContato
                _input.Observacoes = pObservacoes
                _input.Habilitado = pHabilitado

                AtualizarRedeAncoraTransportador = me._redeAncoraCheckoutService.AtualizarTransportador(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ExcluirRedeAncoraTransportador(pIdTransportador As Integer) As Boolean
            ExcluirRedeAncoraTransportador = me._redeAncoraCheckoutService.ExcluirTransportador(me.ObterCodUsuarioIntegracao(), pIdTransportador)
        End Function

        Function ListarRedeAncoraTiposVeiculo() As String
            ListarRedeAncoraTiposVeiculo = me._redeAncoraCheckoutService.ListarTiposVeiculo(me.ObterCodUsuarioIntegracao())
        End Function

        Sub DefinirRedeAncoraTamanhoChunkSincronizacao(pTamanho As Integer)
            RedeAncoraApiConfig.DefinirTamanhoChunkSincronizacaoProdutos(pTamanho)
        End Sub

        Sub DefinirRedeAncoraStaging(pUsarStaging As Boolean)
            RedeAncoraApiConfig.DefinirStaging(pUsarStaging)
        End Sub

        Sub DefinirRedeAncoraLogHttp(pLogarCorpos As Boolean)
            RedeAncoraApiConfig.DefinirLogHttpBodies(pLogarCorpos)
        End Sub

        Sub DefinirRedeAncoraValidarProdutoAntesCarrinho(pValidar As Boolean)
            RedeAncoraApiConfig.DefinirValidarProdutoAntesCarrinho(pValidar)
        End Sub

        Function ConsultarRedeAncoraProdutoCondicoes(pCna As Integer) As String
            ConsultarRedeAncoraProdutoCondicoes = me._redeAncoraProdutoService.ConsultarCondicoes(me.ObterCodUsuarioIntegracao(), pCna)
        End Function

        Function ConsultarRedeAncoraProdutoPrecosEstoques(pCodCentroDistribuicao As Integer, pCnas As RedeAncoraProdutoCnasModel) As RedeAncoraProdutoPrecosEstoqueModel
            ConsultarRedeAncoraProdutoPrecosEstoques = me._redeAncoraProdutoService.ConsultarPrecosEstoques(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pCnas)
        End Function

        Function BuscarRedeAncoraProdutoFullSearch(pCodCentroDistribuicao As Integer, pCna As Integer, pCodigo As String, pQuery As String) As String
            BuscarRedeAncoraProdutoFullSearch = me._redeAncoraProdutoService.BuscarProdutoFullSearch(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pCna, pCodigo, pQuery)
        End Function

        Function BuscarRedeAncoraProdutoBulkSearch(pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pPagina As Integer, pTamanhoPagina As Integer) As String
            BuscarRedeAncoraProdutoBulkSearch = me._redeAncoraProdutoService.BuscarProdutoBulkSearch(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pCodEstado, pCnas, pPagina, pTamanhoPagina)
        End Function

        Function ConsultarRedeAncoraProdutoCentrosComEstoque(pCna As Integer, pCodEstado As Integer, pCodCentroDistribuicao As Integer) As String
            ConsultarRedeAncoraProdutoCentrosComEstoque = me._redeAncoraProdutoService.ConsultarCentrosComEstoque(me.ObterCodUsuarioIntegracao(), pCna, pCodEstado, pCodCentroDistribuicao)
        End Function

        Function BuscarRedeAncoraProdutos(pPagina As Integer, pTamanhoPagina As Integer, pMarca As String, pCodigo As String, pCna As Integer, pGtin As String, pCest As String, pOrigem As Integer, pNome As String, pCodLinha As Integer, pCodFamilia As Integer) As String
            Dim _input As New RedeAncoraInputBuscarProdutos()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.Pagina = pPagina
                _input.TamanhoPagina = pTamanhoPagina
                _input.Marca = pMarca
                _input.Codigo = pCodigo
                _input.Cna = pCna
                _input.Gtin = pGtin
                _input.Cest = pCest
                _input.Origem = pOrigem
                _input.Nome = pNome
                _input.CodLinha = pCodLinha
                _input.CodFamilia = pCodFamilia

                BuscarRedeAncoraProdutos = me._redeAncoraProdutoService.BuscarProdutos(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ConsultarRedeAncoraProdutoSimilares(pCnas As RedeAncoraProdutoCnasModel, pCodEstado As Integer, pCodCentroDistribuicao As Integer) As String
            Dim _input As New RedeAncoraInputConsultarSimilares()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.Cnas = pCnas
                _input.CodEstado = pCodEstado
                _input.CodCentroDistribuicao = pCodCentroDistribuicao

                ConsultarRedeAncoraProdutoSimilares = me._redeAncoraProdutoService.ConsultarSimilares(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function BuscarRedeAncoraProdutosPorLote(pCnaList As RedeAncoraProdutoCnasModel, pCodeList As RedeAncoraProdutoCodigosModel, pGtinList As RedeAncoraProdutoCodigosModel, pPagina As Integer, pTamanhoPagina As Integer) As String
            Dim _input As New RedeAncoraInputBuscarProdutosPorLote()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.CnaList = pCnaList
                _input.CodeList = pCodeList
                _input.GtinList = pGtinList
                _input.Pagina = pPagina
                _input.TamanhoPagina = pTamanhoPagina

                BuscarRedeAncoraProdutosPorLote = me._redeAncoraProdutoService.BuscarProdutosPorLote(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ConsultarRedeAncoraProdutoPrecosEstoquesTodosCds(pCodCentroDistribuicaoPreferencial As Integer, pCnas As RedeAncoraProdutoCnasModel, pCodes As RedeAncoraProdutoCodigosModel) As String
            Dim _input As New RedeAncoraInputConsultarPrecosEstoquesCds()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.CodCentroDistribuicaoPreferencial = pCodCentroDistribuicaoPreferencial
                _input.Cnas = pCnas
                _input.Codes = pCodes

                ConsultarRedeAncoraProdutoPrecosEstoquesTodosCds = me._redeAncoraProdutoService.ConsultarPrecosEstoquesTodosCds(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ResolverRedeAncoraCnaPorCodProduto(pCodProduto As Integer) As Integer
            ResolverRedeAncoraCnaPorCodProduto = me._redeAncoraProdutoService.ResolverCnaParaCompra(pCodProduto)
        End Function

        Function TryObterRedeAncoraVinculoAtivo(pCodProduto As Integer, pItem As RedeAncoraProdutoVinculoModel) As Boolean
            TryObterRedeAncoraVinculoAtivo = me._redeAncoraProdutoService.TryObterVinculoAtivo(pCodProduto, pItem)
        End Function

        Function ObterRedeAncoraVinculoPorCodProduto(pCodProduto As Integer) As RedeAncoraProdutoVinculoModel
            ObterRedeAncoraVinculoPorCodProduto = me._redeAncoraProdutoService.ObterVinculoPorCodProduto(pCodProduto)
        End Function

        Function ListarRedeAncoraVinculosAtivos() As RedeAncoraProdutoVinculosModel
            ListarRedeAncoraVinculosAtivos = me._redeAncoraProdutoService.ListarVinculosAtivos()
        End Function

        Function ListarRedeAncoraProdutosAtivos() As RedeAncoraProdutoVinculosModel
            ListarRedeAncoraProdutosAtivos = me._redeAncoraProdutoService.ListarProdutosAncoraAtivos()
        End Function

        Function ObterRedeAncoraProdutoPorCna(pCna As Integer) As RedeAncoraProdutoVinculoModel
            ObterRedeAncoraProdutoPorCna = me._redeAncoraProdutoService.ObterProdutoAncoraPorCna(pCna)
        End Function

        Function TryObterRedeAncoraProdutoAtivo(pCna As Integer, pItem As RedeAncoraProdutoVinculoModel) As Boolean
            TryObterRedeAncoraProdutoAtivo = me._redeAncoraProdutoService.TryObterProdutoAncoraAtivo(pCna, pItem)
        End Function

        Sub SalvarRedeAncoraProduto(pModel As RedeAncoraProdutoVinculoModel)
            me._redeAncoraProdutoService.SalvarProdutoAncora(pModel)
        End Sub

        Sub SalvarRedeAncoraVinculo(pModel As RedeAncoraProdutoVinculoModel)
            me._redeAncoraProdutoService.SalvarVinculo(pModel)
        End Sub

        Sub DesativarRedeAncoraProduto(pCna As Integer)
            me._redeAncoraProdutoService.DesativarProdutoAncora(pCna)
        End Sub

        Sub DesativarRedeAncoraVinculo(pCodProduto As Integer)
            me._redeAncoraProdutoService.DesativarVinculo(pCodProduto)
        End Sub

        Function CadastrarRedeAncoraProdutoManual(pCna As Integer, pCodigoAncora As String, pDescricaoAncora As String, pCodMarca As Integer, pCodLinha As Integer, pCodFamilia As Integer, pObservacao As String) As RedeAncoraProdutoVinculoModel
            CadastrarRedeAncoraProdutoManual = me._redeAncoraProdutoService.CadastrarProdutoAncoraManual(pCna, pCodigoAncora, pDescricaoAncora, pCodMarca, pCodLinha, pCodFamilia, pObservacao)
        End Function

        Function CadastrarRedeAncoraProdutoPorBusca(pCodCentroDistribuicao As Integer, pCna As Integer, pCodigo As String, pQuery As String) As RedeAncoraProdutoVinculoModel
            CadastrarRedeAncoraProdutoPorBusca = me._redeAncoraProdutoService.CadastrarProdutoAncoraPorBusca(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pCna, pCodigo, pQuery)
        End Function

        Function VincularRedeAncoraComProdutoInterno(pCna As Integer, pCodProduto As Integer) As RedeAncoraProdutoVinculoModel
            VincularRedeAncoraComProdutoInterno = me._redeAncoraProdutoService.VincularComProdutoInterno(pCna, pCodProduto)
        End Function

        Function VincularRedeAncoraProdutoManual(pCodProduto As Integer, pCna As Integer, pCodigoAncora As String, pDescricaoAncora As String, pCodMarca As Integer, pCodLinha As Integer, pCodFamilia As Integer, pObservacao As String) As RedeAncoraProdutoVinculoModel
            VincularRedeAncoraProdutoManual = me._redeAncoraProdutoService.VincularProdutoManual(pCodProduto, pCna, pCodigoAncora, pDescricaoAncora, pCodMarca, pCodLinha, pCodFamilia, pObservacao)
        End Function

        Function VincularRedeAncoraProdutoPorBusca(pCodProduto As Integer, pCodCentroDistribuicao As Integer, pCna As Integer, pCodigo As String, pQuery As String) As RedeAncoraProdutoVinculoModel
            VincularRedeAncoraProdutoPorBusca = me._redeAncoraProdutoService.VincularProdutoPorBusca(me.ObterCodUsuarioIntegracao(), pCodProduto, pCodCentroDistribuicao, pCna, pCodigo, pQuery)
        End Function

        Function SincronizarRedeAncoraProdutosOpcoes(pOpcoes As RedeAncoraProdutoSincronizacaoOpcoesModel) As RedeAncoraProdutoSincronizacaoResultadoModel
            SincronizarRedeAncoraProdutosOpcoes = me._redeAncoraProdutoSincronizacaoService.Sincronizar(pOpcoes)
        End Function

        Function SincronizarRedeAncoraCadastroProdutosCompleto(pReiniciar As Boolean = False) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _codCentro As Integer = 0
            Dim _codEstado As Integer = 0
            Dim _result As RedeAncoraProdutoSincronizacaoResultadoModel = NULL

            Try
                me.ResolverCentroDistribuicaoParaCadastro(_codCentro, _codEstado)
                _result = me._redeAncoraProdutoSincronizacaoService.SincronizarCadastroProdutosCompleto(me.ObterCodUsuarioIntegracao(), _codCentro, _codEstado, 0, pReiniciar)
            Catch ex As Exception
                If Assigned(_result) Then
                    _result.Free()
                    _result = NULL
                End If

                Throw New System.Exception("Erro no cadastro completo de produtos Rede Ancora: " & ex._getMessage())
            End Try

            SincronizarRedeAncoraCadastroProdutosCompleto = _result
        End Function

        Function SincronizarRedeAncoraCadastroProdutosCompletoComCd(pCodCentroDistribuicao As Integer, pCodEstado As Integer, pTamanhoPagina As Integer, pReiniciar As Boolean = False) As RedeAncoraProdutoSincronizacaoResultadoModel
            SincronizarRedeAncoraCadastroProdutosCompletoComCd = me._redeAncoraProdutoSincronizacaoService.SincronizarCadastroProdutosCompleto(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pCodEstado, pTamanhoPagina, pReiniciar)
        End Function

        Private Sub ResolverCentroDistribuicaoParaCadastro(ByRef pCodCentro As Integer, ByRef pCodEstado As Integer)
            Dim _centros As RedeAncoraCentrosDistribuicaoModel = NULL
            Dim _pref As RedeAncoraCentroDistribuicaoModel = NULL
            Dim _item As RedeAncoraCentroDistribuicaoModel = NULL

            Try
                _centros = me.ListarRedeAncoraCentrosDistribuicao()

                If Not Assigned(_centros) Then
                    Throw New System.Exception("Nenhum centro de distribuicao encontrado. Execute InicializarRedeAncora antes do cadastro completo de produtos.")
                End If

                If _centros.Length <= 0 Then
                    Throw New System.Exception("Nenhum centro de distribuicao encontrado. Execute InicializarRedeAncora antes do cadastro completo de produtos.")
                End If

                _pref = _centros.ObterPreferencial()
                If Assigned(_pref) Then
                    pCodCentro = _pref.CodCentroDistribuicao
                    pCodEstado = _pref.CodEstado
                Else
                    _item = _centros.Take(0)
                    pCodCentro = _item.CodCentroDistribuicao
                    pCodEstado = _item.CodEstado
                End If

                _centros.Free()
                _centros = NULL
            Catch ex As Exception
                If Assigned(_centros) Then
                    _centros.Free()
                End If

                Throw ex
            End Try
        End Sub

        Function SincronizarRedeAncoraProdutos(pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pTamanhoChunk As Integer, pDesativarAusentes As Boolean, pModo As String) As RedeAncoraProdutoSincronizacaoResultadoModel
            SincronizarRedeAncoraProdutos = me._redeAncoraProdutoSincronizacaoService.SincronizarProdutos(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pCodEstado, pCnas, pTamanhoChunk, pDesativarAusentes, pModo)
        End Function

        Function SincronizarRedeAncoraProdutosCadastrados(pCodCentroDistribuicao As Integer, pCodEstado As Integer, pTamanhoChunk As Integer, pDesativarAusentes As Boolean, pModo As String) As RedeAncoraProdutoSincronizacaoResultadoModel
            SincronizarRedeAncoraProdutosCadastrados = me._redeAncoraProdutoSincronizacaoService.SincronizarProdutosCadastrados(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pCodEstado, pTamanhoChunk, pDesativarAusentes, pModo)
        End Function

        Function SincronizarRedeAncoraProdutosCompleto(pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pTamanhoChunk As Integer, pDesativarAusentes As Boolean, pSincronizarCatalogo As Boolean, pModo As String) As RedeAncoraProdutoSincronizacaoResultadoModel
            SincronizarRedeAncoraProdutosCompleto = me._redeAncoraProdutoSincronizacaoService.SincronizarCompleto(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pCodEstado, pCnas, pTamanhoChunk, pDesativarAusentes, pSincronizarCatalogo, pModo)
        End Function

        Function SincronizarRedeAncoraImagensProdutos(pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pTamanhoChunk As Integer) As RedeAncoraProdutoImagemSincronizacaoResultadoModel
            SincronizarRedeAncoraImagensProdutos = me._redeAncoraProdutoService.SincronizarImagensProdutosPorCnas(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pCodEstado, pCnas, pTamanhoChunk)
        End Function

        Function ListarRedeAncoraImagensProduto(pCna As Integer) As RedeAncoraProdutoImagensModel
            ListarRedeAncoraImagensProduto = me._redeAncoraProdutoService.ListarImagensProdutoPorCna(pCna)
        End Function

        Sub SincronizarRedeAncoraCatalogo()
            me._redeAncoraCatalogoService.SincronizarCatalogo(me.ObterCodUsuarioIntegracao())
        End Sub

        Sub GarantirRedeAncoraCatalogo()
            me._redeAncoraCatalogoService.GarantirCatalogoSincronizado(me.ObterCodUsuarioIntegracao())
        End Sub

        Function SincronizarRedeAncoraMarcas() As RedeAncoraMarcasModel
            SincronizarRedeAncoraMarcas = me._redeAncoraCatalogoService.SincronizarMarcas(me.ObterCodUsuarioIntegracao())
        End Function

        Function SincronizarRedeAncoraLinhas() As RedeAncoraLinhasModel
            SincronizarRedeAncoraLinhas = me._redeAncoraCatalogoService.SincronizarLinhas(me.ObterCodUsuarioIntegracao())
        End Function

        Function SincronizarRedeAncoraFamilias() As RedeAncoraFamiliasModel
            SincronizarRedeAncoraFamilias = me._redeAncoraCatalogoService.SincronizarFamilias(me.ObterCodUsuarioIntegracao())
        End Function

        Function ListarRedeAncoraMarcas() As RedeAncoraMarcasModel
            ListarRedeAncoraMarcas = me._redeAncoraCatalogoService.ListarMarcas()
        End Function

        Function ListarRedeAncoraLinhas() As RedeAncoraLinhasModel
            ListarRedeAncoraLinhas = me._redeAncoraCatalogoService.ListarLinhas()
        End Function

        Function ListarRedeAncoraFamilias() As RedeAncoraFamiliasModel
            ListarRedeAncoraFamilias = me._redeAncoraCatalogoService.ListarFamilias()
        End Function

        Function ListarRedeAncoraPedidosProgramados(pCodCentroDistribuicao As Integer, pCodMarca As Integer, pDataInicial As String, pDataFinal As String) As String
            Dim _input As New RedeAncoraInputListarPedidosProgramados()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.CodCentroDistribuicao = pCodCentroDistribuicao
                _input.CodMarca = pCodMarca
                _input.DataInicial = pDataInicial
                _input.DataFinal = pDataFinal

                ListarRedeAncoraPedidosProgramados = me._redeAncoraPedidoProgramadoService.ListarPedidosProgramados(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ConsultarRedeAncoraPedidoProgramado(pCodCentroDistribuicao As Integer, pIdPedidoProgramado As Integer) As String
            ConsultarRedeAncoraPedidoProgramado = me._redeAncoraPedidoProgramadoService.ConsultarPedidoProgramado(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pIdPedidoProgramado)
        End Function

        Function ConsultarRedeAncoraResumoPedidoProgramado(pCodCentroDistribuicao As Integer, pIdPedidoProgramado As Integer) As String
            ConsultarRedeAncoraResumoPedidoProgramado = me._redeAncoraPedidoProgramadoService.ConsultarResumoPedidoProgramado(me.ObterCodUsuarioIntegracao(), pCodCentroDistribuicao, pIdPedidoProgramado)
        End Function

        Function ListarRedeAncoraProdutosPedidoProgramado(pIdPedidoProgramado As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pPagina As Integer, pItensPorPagina As Integer, pQuery As String, pIdCiclo As Integer, pOrdenarPor As String, pDirecaoOrdenacao As String) As String
            Dim _input As New RedeAncoraInputListarProdutosPedidoProgramado()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.IdPedidoProgramado = pIdPedidoProgramado
                _input.CodCentroDistribuicao = pCodCentroDistribuicao
                _input.CodEstado = pCodEstado
                _input.Pagina = pPagina
                _input.ItensPorPagina = pItensPorPagina
                _input.Query = pQuery
                _input.IdCiclo = pIdCiclo
                _input.OrdenarPor = pOrdenarPor
                _input.DirecaoOrdenacao = pDirecaoOrdenacao

                ListarRedeAncoraProdutosPedidoProgramado = me._redeAncoraPedidoProgramadoService.ListarProdutosPedidoProgramado(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function SolicitarRedeAncoraRelatorioProdutosPedidoProgramado(pIdPedidoProgramado As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer) As String
            Dim _input As New RedeAncoraInputSolicitarRelatorioPedidoProgramado()

            Try
                _input.CodUsuario = me.ObterCodUsuarioIntegracao()
                _input.IdPedidoProgramado = pIdPedidoProgramado
                _input.CodCentroDistribuicao = pCodCentroDistribuicao
                _input.CodEstado = pCodEstado

                SolicitarRedeAncoraRelatorioProdutosPedidoProgramado = me._redeAncoraPedidoProgramadoService.SolicitarRelatorioProdutosPedidoProgramado(_input)
                _input.Free()
                _input = Null
            Catch ex As Exception
                If Assigned(_input) Then
                    _input.Free()
                End If

                Throw ex
            End Try
        End Function

        Function ListarRedeAncoraOfertasAgenda(pCodMarca As Integer, pCodCentroDistribuicao As Integer) As String
            ListarRedeAncoraOfertasAgenda = me._redeAncoraAgendaComprasService.ListarOfertasAgenda(me.ObterCodUsuarioIntegracao(), pCodMarca, pCodCentroDistribuicao)
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._repository) Then
                    me._repository.Free()
                    me._repository = Null
                End If

                If Assigned(me._redeAncoraAutenticacaoService) Then
                    me._redeAncoraAutenticacaoService.Free()
                    me._redeAncoraAutenticacaoService = Null
                End If

                If Assigned(me._redeAncoraEmpresaService) Then
                    me._redeAncoraEmpresaService.Free()
                    me._redeAncoraEmpresaService = Null
                End If

                If Assigned(me._redeAncoraModalidadeService) Then
                    me._redeAncoraModalidadeService.Free()
                    me._redeAncoraModalidadeService = Null
                End If

                If Assigned(me._redeAncoraCarrinhoService) Then
                    me._redeAncoraCarrinhoService.Free()
                    me._redeAncoraCarrinhoService = Null
                End If

                If Assigned(me._redeAncoraCatalogoService) Then
                    me._redeAncoraCatalogoService.Free()
                    me._redeAncoraCatalogoService = Null
                End If

                If Assigned(me._redeAncoraProdutoService) Then
                    me._redeAncoraProdutoService.Free()
                    me._redeAncoraProdutoService = Null
                End If

                If Assigned(me._redeAncoraProdutoSincronizacaoService) Then
                    me._redeAncoraProdutoSincronizacaoService.Free()
                    me._redeAncoraProdutoSincronizacaoService = Null
                End If

                If Assigned(me._redeAncoraCheckoutService) Then
                    me._redeAncoraCheckoutService.Free()
                    me._redeAncoraCheckoutService = Null
                End If

                If Assigned(me._redeAncoraSalesService) Then
                    me._redeAncoraSalesService.Free()
                    me._redeAncoraSalesService = Null
                End If

                If Assigned(me._redeAncoraPedidoProgramadoService) Then
                    me._redeAncoraPedidoProgramadoService.Free()
                    me._redeAncoraPedidoProgramadoService = Null
                End If

                If Assigned(me._redeAncoraAgendaComprasService) Then
                    me._redeAncoraAgendaComprasService.Free()
                    me._redeAncoraAgendaComprasService = Null
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
