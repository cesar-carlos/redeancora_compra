Imports mod_logger
Imports mod_tobject
Imports try_parser
Imports usuario_service
Imports rede_ancora_json_helper
Imports rede_ancora_centros_distribuicao_model
Imports rede_ancora_empresa_model
Imports rede_ancora_marcas_model
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_codigos_model
Imports rede_ancora_produto_vinculos_model
Imports rede_ancora_logistica_transportadores_model
Imports rede_ancora_carrinho_model
Imports rede_ancora_carrinho_itens_ids_model

Namespace rede_ancora_api_novos_bootstrap
    Class RedeAncoraApiNovosBootstrap
        Inherits TTObject

        Private _configurado As String
        Private _habilitado As Boolean
        Private _chaveApi As String
        Private _inicializarRedeAncora As Boolean
        Private _cna As Integer
        Private _testarHaulersCrud As Boolean
        Private _testarReorder As Boolean

        Sub New()
            MyBase.New()
            me._habilitado = True
            me._chaveApi = ""
            me._inicializarRedeAncora = True
            me._cna = 0
            me._testarHaulersCrud = False
            me._testarReorder = False
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

        Sub DefinirTestarHaulersCrud(pTestar As Boolean)
            me._testarHaulersCrud = pTestar
        End Sub

        Sub DefinirTestarReorder(pTestar As Boolean)
            me._testarReorder = pTestar
        End Sub

        Sub Executar()
            me.GarantirConfiguracaoPadrao()

            If Not me._habilitado Then
                mod_logger.Printe("Rede Ancora API novos bootstrap desabilitado.")
                Exit Sub
            End If

            Dim _svc As UsuarioService = Null
            Dim _centros As RedeAncoraCentrosDistribuicaoModel = Null
            Dim _produtos As RedeAncoraProdutoVinculosModel = Null
            Dim _marcas As RedeAncoraMarcasModel = Null
            Dim _codCentro As Integer = 0
            Dim _codEstado As Integer = 0
            Dim _cna As Integer = 0
            Dim _codMarca As Integer = 0

            Try
                mod_logger.Printe("=== Rede Ancora API novos bootstrap :: inicio ===")

                _svc = New UsuarioService()

                If Not _svc.PingRedeAncora() Then
                    Throw New System.Exception("API Rede Ancora indisponivel (ping falhou)")
                End If

                mod_logger.Printe("Passo 1: ping OK")


                me.GarantirAutenticacao(_svc)
                _svc.ValidarRedeAncoraPodeOperar()

                mod_logger.Printe("Passo 2: autenticacao e profile OK")

                _centros = _svc.ListarRedeAncoraCentrosDistribuicao()
                me.ResolverCentroDistribuicao(_centros, _codCentro, _codEstado)

                _produtos = _svc.ListarRedeAncoraProdutosAtivos()
                _cna = me.ResolverCna(_produtos)

                _marcas = _svc.ListarRedeAncoraMarcas()

                If Assigned(_marcas) Then
                    If _marcas.Length > 0 Then
                        _codMarca = _marcas.Take(0).CodMarca
                    End If
                End If

                mod_logger.Printe("Contexto: CD=" + Parser.IntegerToString(_codCentro) + " | estado=" + Parser.IntegerToString(_codEstado) + " | cna=" + Parser.IntegerToString(_cna) + " | marca=" + Parser.IntegerToString(_codMarca))

                me.ExecutarTestesProdutosNovos(_svc, _codCentro, _codEstado, _cna)
                me.ExecutarTestesSales(_svc, _cna)
                me.ExecutarTestesScheduledOrder(_svc, _codCentro, _codEstado, _codMarca)
                me.ExecutarTestesAgenda(_svc, _codCentro, _codMarca)
                me.ExecutarTestesHaulers(_svc)

                mod_logger.Printe("=== Rede Ancora API novos bootstrap :: concluido ===")

                If Assigned(_marcas) Then
                    _marcas.Free()
                End If

                _produtos.Free()
                _centros.Free()
                _svc.Free()
            Catch ex As Exception
                If Assigned(_marcas) Then
                    _marcas.Free()
                End If

                If Assigned(_produtos) Then
                    _produtos.Free()
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

        Private Sub ExecutarTestesProdutosNovos(pSvc As UsuarioService, pCodCentro As Integer, pCodEstado As Integer, pCna As Integer)
            Dim _cnas As RedeAncoraProdutoCnasModel = Null
            Dim _codes As RedeAncoraProdutoCodigosModel = Null
            Dim _resposta As String = ""

            Try
                mod_logger.Printe("--- Produtos complementares (novos) ---")

                _resposta = pSvc.BuscarRedeAncoraProdutos(1, 10, "", "", pCna, "", "", 0, "", 0, 0)
                mod_logger.Printe("GET /products OK (filtro cna)")
                me.LogTextoTruncado("products", _resposta)

                _cnas = New RedeAncoraProdutoCnasModel()
                _cnas.Push(pCna)

                _resposta = pSvc.ConsultarRedeAncoraProdutoSimilares(_cnas, pCodEstado, pCodCentro)
                mod_logger.Printe("POST /products/similares OK")
                me.LogTextoTruncado("similares", _resposta)

                _resposta = pSvc.BuscarRedeAncoraProdutosPorLote(_cnas, Null, Null, 1, 10)
                mod_logger.Printe("POST /products/bulk OK (cna_list)")
                me.LogTextoTruncado("bulk", _resposta)

                _codes = New RedeAncoraProdutoCodigosModel()

                _resposta = pSvc.ConsultarRedeAncoraProdutoPrecosEstoquesTodosCds(pCodCentro, _cnas, _codes)
                mod_logger.Printe("POST /products/prices-stocks-warehouses OK")
                me.LogTextoTruncado("prices-stocks-warehouses", _resposta)

                _codes.Free()
                _cnas.Free()
            Catch ex As Exception
                If Assigned(_codes) Then
                    _codes.Free()
                End If

                If Assigned(_cnas) Then
                    _cnas.Free()
                End If

                Throw New System.Exception("Erro nos testes de produtos complementares: " + ex._getMessage())
            End Try
        End Sub

        Private Sub ExecutarTestesSales(pSvc As UsuarioService, pCna As Integer)
            Dim _pedidos As String = ""
            Dim _idPedido As Integer = 0
            Dim _itens As String = ""
            Dim _idItem As Integer = 0
            Dim _detalhe As String = ""
            Dim _pendencias As String = ""
            Dim _pendenciasPorPedido As String = ""
            Dim _carrinhoId As String = ""

            Try
                mod_logger.Printe("--- Sales (somente leitura; cancel/reorder desabilitados por padrao) ---")

                _pedidos = pSvc.ListarRedeAncoraPedidosApi(1, 5, "", "", 0, 0, "", 0, 0, "", 0, "", "", "")
                mod_logger.Printe("GET /sales/orders OK")
                me.LogTextoTruncado("sales/orders", _pedidos)

                _idPedido = me.ObterPrimeiroInteiroData(_pedidos, "id")

                If _idPedido > 0 Then
                    _detalhe = pSvc.ConsultarRedeAncoraPedidoApi(_idPedido)
                    mod_logger.Printe("GET /sales/orders/{id} OK | id=" + Parser.IntegerToString(_idPedido))
                    me.LogTextoTruncado("sales/order", _detalhe)

                    _itens = pSvc.ListarRedeAncoraItensPedidoApi(_idPedido, "", "", "", "", "", pCna, "", "", 0)
                    mod_logger.Printe("GET /sales/orders/{id}/items OK")
                    me.LogTextoTruncado("sales/items", _itens)

                    _idItem = me.ObterPrimeiroInteiroData(_itens, "id")

                    If _idItem > 0 Then
                        _detalhe = pSvc.ConsultarRedeAncoraItemPedidoApi(_idPedido, _idItem)
                        mod_logger.Printe("GET /sales/orders/{id}/items/{itemId} OK | item=" + Parser.IntegerToString(_idItem))
                        me.LogTextoTruncado("sales/item", _detalhe)
                    Else
                        mod_logger.Printe("Aviso: nenhum item retornado para pedido " + Parser.IntegerToString(_idPedido))
                    End If

                    If me._testarReorder Then
                        Dim _carrinho As RedeAncoraCarrinhoModel = Null
                        Dim _itensReorder As RedeAncoraCarrinhoItensIdsModel = Null
                        Dim _j As Integer = 0

                        _carrinho = pSvc.ReordenarRedeAncoraCarrinho(_idPedido)
                        mod_logger.Printe("POST /sales/orders/{id}/reorder OK | cart_id=" + _carrinho.IdCarrinho)
                        _carrinhoId = _carrinho.IdCarrinho

                        If Assigned(_carrinho.Itens) Then
                            _itensReorder = New RedeAncoraCarrinhoItensIdsModel()

                            For _j = 0 To _carrinho.Itens.Length - 1
                                _itensReorder.Push(_carrinho.Itens.Take(_j).IdItemApi)
                            Next
                        End If

                        _carrinho.Free()
                        _carrinho = Null

                        If _carrinhoId <> "" And Assigned(_itensReorder) And _itensReorder.Length > 0 Then
                            mod_logger.Printe("Limpeza reorder: removendo " + Parser.IntegerToString(_itensReorder.Length) + " item(ns) | cart_id=" + _carrinhoId)
                            pSvc.RemoverItensRedeAncoraCarrinhoEmLote(_carrinhoId, _itensReorder)
                            mod_logger.Printe("Limpeza reorder: itens removidos (POST /checkout/bulk/items/delete)")
                        End If

                        If Assigned(_itensReorder) Then
                            _itensReorder.Free()
                        End If
                    Else
                        mod_logger.Printe("POST /sales/orders/{id}/reorder PULADO (DefinirTestarReorder(True) para testar)")
                    End If
                Else
                    mod_logger.Printe("Aviso: nenhum pedido retornado; detalhe/itens/reorder pulados")
                End If
            Catch ex As Exception
                Throw New System.Exception("Erro nos testes Sales: " + ex._getMessage())
            End Try

            Try
                _pendencias = pSvc.ListarRedeAncoraPendenciasApi(1, 5, "", "", 0, 0, "", 0, 0, "", 0, "", "", 0)
                mod_logger.Printe("GET /sales/pendencies OK")
                me.LogTextoTruncado("sales/pendencies", _pendencias)

                _pendenciasPorPedido = pSvc.ListarRedeAncoraPendenciasPorPedidoApi(1, 5, "", "", 0, 0, "")
                mod_logger.Printe("GET /sales/pendencies/by-orders OK")
                me.LogTextoTruncado("sales/pendencies-by-orders", _pendenciasPorPedido)
            Catch exPendencias As Exception
                mod_logger.Printe("Aviso: pendencias indisponiveis (API lenta ou timeout): " + exPendencias._getMessage())
            End Try

            mod_logger.Printe("GET /sales/orders/{id}/cancel PULADO (operacao destrutiva; nao testada no harness)")
        End Sub

        Private Sub ExecutarTestesScheduledOrder(pSvc As UsuarioService, pCodCentro As Integer, pCodEstado As Integer, pCodMarca As Integer)
            Dim _lista As String = ""
            Dim _idProgramado As Integer = 0
            Dim _detalhe As String = ""

            Try
                mod_logger.Printe("--- ScheduledOrder (somente leitura) ---")

                _lista = pSvc.ListarRedeAncoraPedidosProgramados(pCodCentro, pCodMarca, "", "")
                mod_logger.Printe("GET /scheduled-order OK")
                me.LogTextoTruncado("scheduled-order", _lista)

                _idProgramado = me.ObterPrimeiroInteiroData(_lista, "id")

                If _idProgramado > 0 Then
                    _detalhe = pSvc.ConsultarRedeAncoraPedidoProgramado(pCodCentro, _idProgramado)
                    mod_logger.Printe("GET /scheduled-order/{id} OK | id=" + Parser.IntegerToString(_idProgramado))
                    me.LogTextoTruncado("scheduled-order/detail", _detalhe)

                    _detalhe = pSvc.ConsultarRedeAncoraResumoPedidoProgramado(pCodCentro, _idProgramado)
                    mod_logger.Printe("GET /scheduled-order/{id}/resume OK")
                    me.LogTextoTruncado("scheduled-order/resume", _detalhe)

                    _detalhe = pSvc.ListarRedeAncoraProdutosPedidoProgramado(_idProgramado, pCodCentro, pCodEstado, 1, 10, "", 0, "", "")
                    mod_logger.Printe("GET /scheduled-order/{id}/products OK")
                    me.LogTextoTruncado("scheduled-order/products", _detalhe)

                    _detalhe = pSvc.SolicitarRedeAncoraRelatorioProdutosPedidoProgramado(_idProgramado, pCodCentro, pCodEstado)
                    mod_logger.Printe("GET /scheduled-order/{id}/products/report OK")
                    me.LogTextoTruncado("scheduled-order/report", _detalhe)
                Else
                    mod_logger.Printe("Aviso: nenhum pedido programado retornado; endpoints de detalhe pulados")
                End If
            Catch ex As Exception
                Throw New System.Exception("Erro nos testes ScheduledOrder: " + ex._getMessage())
            End Try
        End Sub

        Private Sub ExecutarTestesAgenda(pSvc As UsuarioService, pCodCentro As Integer, pCodMarca As Integer)
            Dim _ofertas As String = ""

            Try
                mod_logger.Printe("--- Agenda de compras ---")

                _ofertas = pSvc.ListarRedeAncoraOfertasAgenda(pCodMarca, pCodCentro)
                mod_logger.Printe("GET /sale-offers/brands OK")
                me.LogTextoTruncado("sale-offers/brands", _ofertas)
            Catch ex As Exception
                Throw New System.Exception("Erro nos testes Agenda: " + ex._getMessage())
            End Try
        End Sub

        Private Sub ExecutarTestesHaulers(pSvc As UsuarioService)
            Dim _tipos As String = ""
            Dim _transportadores As RedeAncoraLogisticaTransportadoresModel = Null
            Dim _idTransportador As Integer = 0
            Dim _detalhe As String = ""
            Dim _idCriado As Integer = 0

            Try
                mod_logger.Printe("--- Logistica Haulers ---")

                _tipos = pSvc.ListarRedeAncoraTiposVeiculo()
                mod_logger.Printe("GET /logistics/haulers/vehicleTypes OK")
                me.LogTextoTruncado("vehicleTypes", _tipos)

                _transportadores = pSvc.ListarRedeAncoraTransportadores()
                mod_logger.Printe("GET /logistics/haulers OK (" + Parser.IntegerToString(_transportadores.Length) + " cadastrados)")

                If Assigned(_transportadores) Then
                    If _transportadores.Length > 0 Then
                        _idTransportador = _transportadores.Take(0).CodTransportador

                        If _idTransportador > 0 Then
                            _detalhe = pSvc.ConsultarRedeAncoraTransportador(_idTransportador)
                            mod_logger.Printe("GET /logistics/haulers/{id} OK | id=" + Parser.IntegerToString(_idTransportador))
                            me.LogTextoTruncado("hauler", _detalhe)
                        End If
                    End If
                End If

                If me._testarHaulersCrud Then
                    _detalhe = pSvc.CriarRedeAncoraTransportador("Harness Teste API", "cpf", "00000000191", "Van", "TST1A23", "Contato Harness", "27999999999", "Criado pelo dev harness", False)
                    mod_logger.Printe("POST /logistics/haulers OK")
                    me.LogTextoTruncado("hauler/criado", _detalhe)

                    _idCriado = me.ObterInteiroIdResposta(_detalhe)

                    If _idCriado > 0 Then
                        _detalhe = pSvc.AtualizarRedeAncoraTransportador(_idCriado, "Harness Teste API Alt", "cpf", "00000000191", "Van", "TST1A23", "Contato Harness", "27999999999", "Atualizado pelo harness", False)
                        mod_logger.Printe("PATCH /logistics/haulers/{id} OK")
                        me.LogTextoTruncado("hauler/atualizado", _detalhe)

                        If pSvc.ExcluirRedeAncoraTransportador(_idCriado) Then
                            mod_logger.Printe("DELETE /logistics/haulers/{id} OK | id=" + Parser.IntegerToString(_idCriado))
                        Else
                            mod_logger.Printe("Aviso: DELETE /logistics/haulers/{id} retornou false")
                        End If
                    Else
                        mod_logger.Printe("Aviso: nao foi possivel obter id do transportador criado; PATCH/DELETE pulados")
                    End If
                Else
                    mod_logger.Printe("POST/PATCH/DELETE /logistics/haulers PULADOS (DefinirTestarHaulersCrud(True) para testar CRUD)")
                End If

                If Assigned(_transportadores) Then
                    _transportadores.Free()
                End If
            Catch ex As Exception
                If Assigned(_transportadores) Then
                    _transportadores.Free()
                End If

                Throw New System.Exception("Erro nos testes Haulers: " + ex._getMessage())
            End Try
        End Sub

        Private Function ResolverCna(pProdutos As RedeAncoraProdutoVinculosModel) As Integer
            Dim _i As Integer = 0

            If me._cna > 0 Then
                ResolverCna = me._cna
                Exit Function
            End If

            If Assigned(pProdutos) Then
                If pProdutos.Length > 0 Then
                    ResolverCna = pProdutos.Take(0).Cna
                    Exit Function
                End If
            End If

            ResolverCna = 849766
        End Function

        Private Sub ResolverCentroDistribuicao(pCentros As RedeAncoraCentrosDistribuicaoModel, ByRef pCodCentro As Integer, ByRef pCodEstado As Integer)
            Dim _i As Integer = 0

            If Not Assigned(pCentros) Then
                Throw New System.Exception("Nenhum centro de distribuicao encontrado")
            End If

            If pCentros.Length <= 0 Then
                Throw New System.Exception("Nenhum centro de distribuicao encontrado")
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

        Private Sub GarantirAutenticacao(pSvc As UsuarioService)
            Dim _empresa As RedeAncoraEmpresaModel = Null

            If me._chaveApi = "" Then
                Exit Sub
            End If

            pSvc.SalvarChaveApiRedeAncora(me._chaveApi)

            If me._inicializarRedeAncora Then
                _empresa = pSvc.InicializarRedeAncora()
                _empresa.Free()
                _empresa = Null
            End If
        End Sub

        Private Sub GarantirConfiguracaoPadrao()
            If me._configurado = "S" Then
                Exit Sub
            End If

            me.Definir(True)
        End Sub

        Private Function ObterPrimeiroInteiroData(pJsonTexto As String, pCampoId As String) As Integer
            Dim _json As TJSONObject = Null
            Dim _data As TJSONArray = Null
            Dim _item As TJSONObject = Null

            ObterPrimeiroInteiroData = 0

            If pJsonTexto = "" Then
                Exit Function
            End If

            _json = New TJSONObject(pJsonTexto)

            If Not Assigned(_json) Then
                Exit Function
            End If

            _data = RedeAncoraJsonHelper.ObterDataArray(_json)

            If Not Assigned(_data) Then
                _json.Free()
                Exit Function
            End If

            If _data.Length() <= 0 Then
                _data.Free()
                _json.Free()
                Exit Function
            End If

            _item = _data.GetJSONObject(0)
            ObterPrimeiroInteiroData = RedeAncoraJsonHelper.ObterInteiroJson(_item, pCampoId)
            _item.Free()
            _data.Free()
            _json.Free()
        End Function

        Private Function ObterInteiroIdResposta(pJsonTexto As String) As Integer
            Dim _json As TJSONObject = Null
            Dim _data As TJSONObject = Null

            ObterInteiroIdResposta = 0

            If pJsonTexto = "" Then
                Exit Function
            End If

            _json = New TJSONObject(pJsonTexto)

            If Not Assigned(_json) Then
                Exit Function
            End If

            _data = RedeAncoraJsonHelper.ObterDataObjeto(_json)

            If Assigned(_data) Then
                ObterInteiroIdResposta = RedeAncoraJsonHelper.ObterInteiroJson(_data, "id")
                _data.Free()
            Else
                ObterInteiroIdResposta = RedeAncoraJsonHelper.ObterInteiroJson(_json, "id")
            End If

            _json.Free()
        End Function

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
