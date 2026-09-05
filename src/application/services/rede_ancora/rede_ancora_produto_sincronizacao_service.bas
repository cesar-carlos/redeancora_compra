Imports mod_tobject
Imports mod_logger
Imports try_parser
Imports rede_ancora_produto_service
Imports rede_ancora_produto_model
Imports rede_ancora_produto_vinculo_repository
Imports rede_ancora_produto_vinculo_origem
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_vinculos_model
Imports rede_ancora_produto_sincronizacao_resultado_model
Imports rede_ancora_produto_sincronizacao_opcoes_model
Imports rede_ancora_produto_sync_progresso_model
Imports rede_ancora_produto_sync_progresso_repository
Imports rede_ancora_catalogo_service
Imports rede_ancora_familias_model
Imports rede_ancora_json_helper
Imports rede_ancora_produto_sincronizacao_modo
Imports rede_ancora_api_config
Imports transactions
Imports diag_stack
Imports rede_ancora_http_erro_helper

Namespace rede_ancora_produto_sincronizacao_service
    Class RedeAncoraProdutoSincronizacaoService
        Inherits TTObject

        Private _produtoService As RedeAncoraProdutoService
        Private _vinculoRepository As RedeAncoraProdutoVinculoRepository
        Private _catalogoService As RedeAncoraCatalogoService
        Private _progressoRepository As RedeAncoraProdutoSyncProgressoRepository
        Private _cnasExistentes As RedeAncoraProdutoCnasModel

        Sub New()
            MyBase.New()
            me.InicializarDependencias(NULL, NULL, NULL)
        End Sub

        Sub New(pProdutoService As RedeAncoraProdutoService, pVinculoRepository As RedeAncoraProdutoVinculoRepository, pCatalogoService As RedeAncoraCatalogoService)
            MyBase.New()
            me.InicializarDependencias(pProdutoService, pVinculoRepository, pCatalogoService)
        End Sub

        Private Sub InicializarDependencias(pProdutoService As RedeAncoraProdutoService, pVinculoRepository As RedeAncoraProdutoVinculoRepository, pCatalogoService As RedeAncoraCatalogoService)
            If Assigned(pProdutoService) Then
                me._produtoService = pProdutoService
            Else
                me._produtoService = New RedeAncoraProdutoService()
            End If

            If Assigned(pVinculoRepository) Then
                me._vinculoRepository = pVinculoRepository
            Else
                me._vinculoRepository = New RedeAncoraProdutoVinculoRepository()
            End If

            If Assigned(pCatalogoService) Then
                me._catalogoService = pCatalogoService
            Else
                me._catalogoService = New RedeAncoraCatalogoService()
            End If

            me._progressoRepository = New RedeAncoraProdutoSyncProgressoRepository()
        End Sub

        Function Sincronizar(pOpcoes As RedeAncoraProdutoSincronizacaoOpcoesModel) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _cnas As RedeAncoraProdutoCnasModel = NULL
            Dim _resultadoSync As RedeAncoraProdutoSincronizacaoResultadoModel = NULL
            Dim _result As RedeAncoraProdutoSincronizacaoResultadoModel = NULL

            pOpcoes.Validate()

            Try
                If pOpcoes.SincronizarCatalogo Then
                    me._catalogoService.SincronizarCatalogo(pOpcoes.CodUsuario)
                End If

                If pOpcoes.BaixarCatalogoCompleto Then
                    If pOpcoes.ReiniciarProgresso Then
                        mod_logger.Printe("Rede Ancora sync :: iniciando catalogo completo...")
                        _resultadoSync = me.ExecutarSincronizacaoCatalogoCompleto(pOpcoes)
                    Else
                        If me._progressoRepository.CargaCompletaObtida() Then
                            mod_logger.Printe("Rede Ancora sync :: carga completa ja obtida (CodFamilia=0 Status=COMPLETA). GET /products/full-search pulado. Para refazer: pReiniciar=True ou DELETE Integracao.RedeAncoraProdutoSyncProgresso.")
                            _resultadoSync = me.CriarResultadoCargaJaObtida(pOpcoes)
                        Else
                            mod_logger.Printe("Rede Ancora sync :: iniciando catalogo completo...")
                            _resultadoSync = me.ExecutarSincronizacaoCatalogoCompleto(pOpcoes)
                        End If
                    End If
                Else
                    _cnas = me.ResolverListaCnas(pOpcoes)
                    _resultadoSync = me.ExecutarSincronizacaoCnas(pOpcoes, _cnas)
                    _cnas.Free()
                    _cnas = NULL
                End If

                _result = _resultadoSync
                _resultadoSync = NULL
            Catch ex As Exception
                If Assigned(_cnas) Then
                    _cnas.Free()
                End If

                If Assigned(_resultadoSync) Then
                    _resultadoSync.Free()
                End If

                Throw New System.Exception("Erro na sincronizacao de produtos Rede Ancora: " & me.MensagemExcecaoSegura(ex))
            End Try

            Sincronizar = _result
        End Function

        ' Carga completa do cadastro de produtos (API sem delta): dimensoes, depois
        ' GET /products/full-search por familia. Upsert local; nunca DELETE /checkout.
        ' Resume: Integracao.RedeAncoraProdutoSyncProgresso (PK CodFamilia). Default retoma
        ' pagina seguinte a UltimaPaginaOk. pReiniciar=True (ou DELETE na tabela) zera e refaz.
        Function SincronizarCadastroProdutosCompleto(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pTamanhoPagina As Integer, pReiniciar As Boolean = False) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _opcoes As RedeAncoraProdutoSincronizacaoOpcoesModel = NULL
            Dim _resultado As RedeAncoraProdutoSincronizacaoResultadoModel = NULL
            Dim _result As RedeAncoraProdutoSincronizacaoResultadoModel = NULL

            Try
                If pCodUsuario <= 0 Then
                    Throw New System.Exception("CodUsuario invalido para cadastro completo de produtos Rede Ancora")
                End If

                If pCodCentroDistribuicao <= 0 Then
                    Throw New System.Exception("Centro de distribuicao invalido para cadastro completo de produtos Rede Ancora")
                End If

                If pCodEstado <= 0 Then
                    Throw New System.Exception("CodEstado invalido para cadastro completo de produtos Rede Ancora")
                End If

                mod_logger.Printe("=== Cadastro completo de produtos Rede Ancora :: inicio ===")
                mod_logger.Printe("Ordem: 1) marcas 2) linhas 3) familias 4) produtos full-search por familia (upsert). Sem DELETE /checkout.")
                mod_logger.Printe("Usuario: " & Parser.IntegerToString(pCodUsuario) & " | CD: " & Parser.IntegerToString(pCodCentroDistribuicao) & " | Estado: " & Parser.IntegerToString(pCodEstado))
                If pReiniciar Then
                    me._progressoRepository.LimparTodos()
                    mod_logger.Printe("Progresso local zerado (pReiniciar=True). Recarrega todas as familias do zero.")
                Else
                    If me._progressoRepository.CargaCompletaObtida() Then
                        mod_logger.Printe("Carga completa ja registrada (Status=COMPLETA). Nao inicia novo full-search. Para refazer: pReiniciar=True ou DELETE Integracao.RedeAncoraProdutoSyncProgresso.")
                    Else
                        mod_logger.Printe("Retoma Integracao.RedeAncoraProdutoSyncProgresso (familias DONE puladas; demais na UltimaPaginaOk+1). Para refazer do zero: pReiniciar=True ou DELETE na tabela.")
                    End If
                End If

                _opcoes = New RedeAncoraProdutoSincronizacaoOpcoesModel()
                _opcoes.CodUsuario = pCodUsuario
                _opcoes.CodCentroDistribuicao = pCodCentroDistribuicao
                _opcoes.CodEstado = pCodEstado
                _opcoes.TamanhoChunk = pTamanhoPagina
                _opcoes.DesativarAusentes = False
                _opcoes.SincronizarCatalogo = True
                _opcoes.Modo = RedeAncoraProdutoSincronizacaoModo.Completa()
                _opcoes.UsarProdutosCadastrados = False
                _opcoes.BaixarCatalogoCompleto = True
                _opcoes.ReiniciarProgresso = False
                _opcoes.Cnas = NULL

                _resultado = me.Sincronizar(_opcoes)
                _opcoes.Free()
                _opcoes = NULL
                _result = _resultado
                _resultado = NULL

                mod_logger.Printe("=== Cadastro completo de produtos Rede Ancora :: concluido ===")
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("SincronizarCadastroProdutosCompleto", ex)

                If Assigned(_resultado) Then
                    _resultado.Free()
                End If

                If Assigned(_opcoes) Then
                    _opcoes.Free()
                End If

                Throw New System.Exception("Erro no cadastro completo de produtos Rede Ancora: " & DiagStack.FormatException(ex))
            End Try

            SincronizarCadastroProdutosCompleto = _result
        End Function

        Function SincronizarCompleto(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pTamanhoChunk As Integer, pDesativarAusentes As Boolean, pSincronizarCatalogo As Boolean, pModo As String) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _opcoes As RedeAncoraProdutoSincronizacaoOpcoesModel = me.CriarOpcoesLegado(pCodUsuario, pCodCentroDistribuicao, pCodEstado, pCnas, pTamanhoChunk, pDesativarAusentes, pModo)

            _opcoes.SincronizarCatalogo = pSincronizarCatalogo
            SincronizarCompleto = me.Sincronizar(_opcoes)
            _opcoes.Free()
        End Function

        Function SincronizarProdutosCadastrados(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pTamanhoChunk As Integer, pDesativarAusentes As Boolean, pModo As String) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _opcoes As RedeAncoraProdutoSincronizacaoOpcoesModel = me.CriarOpcoesLegado(pCodUsuario, pCodCentroDistribuicao, pCodEstado, NULL, pTamanhoChunk, pDesativarAusentes, pModo)

            _opcoes.UsarProdutosCadastrados = True
            _opcoes.SincronizarCatalogo = False
            SincronizarProdutosCadastrados = me.Sincronizar(_opcoes)
            _opcoes.Free()
        End Function

        Function SincronizarProdutos(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pTamanhoChunk As Integer, pDesativarAusentes As Boolean, pModo As String) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _opcoes As RedeAncoraProdutoSincronizacaoOpcoesModel = me.CriarOpcoesLegado(pCodUsuario, pCodCentroDistribuicao, pCodEstado, pCnas, pTamanhoChunk, pDesativarAusentes, pModo)

            _opcoes.SincronizarCatalogo = False
            SincronizarProdutos = me.Sincronizar(_opcoes)
            _opcoes.Free()
        End Function

        Private Function CriarOpcoesLegado(pCodUsuario As Integer, pCodCentroDistribuicao As Integer, pCodEstado As Integer, pCnas As RedeAncoraProdutoCnasModel, pTamanhoChunk As Integer, pDesativarAusentes As Boolean, pModo As String) As RedeAncoraProdutoSincronizacaoOpcoesModel
            Dim _opcoes As New RedeAncoraProdutoSincronizacaoOpcoesModel()

            _opcoes.CodUsuario = pCodUsuario
            _opcoes.CodCentroDistribuicao = pCodCentroDistribuicao
            _opcoes.CodEstado = pCodEstado
            _opcoes.Cnas = pCnas
            _opcoes.TamanhoChunk = pTamanhoChunk
            _opcoes.DesativarAusentes = pDesativarAusentes
            _opcoes.Modo = pModo
            _opcoes.UsarProdutosCadastrados = True
            If Assigned(pCnas) Then
                If pCnas.Length > 0 Then
                    _opcoes.UsarProdutosCadastrados = False
                End If
            End If
            CriarOpcoesLegado = _opcoes
        End Function

        Private Function CriarResultadoCargaJaObtida(pOpcoes As RedeAncoraProdutoSincronizacaoOpcoesModel) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _resultado As New RedeAncoraProdutoSincronizacaoResultadoModel()

            _resultado.DataInicio = DateTime()
            _resultado.Modo = me.ResolverModo(pOpcoes.Modo)
            _resultado.Sucesso = True
            _resultado.Finalizar()
            _resultado.MensagemResumo = "Carga completa ja obtida (Integracao.RedeAncoraProdutoSyncProgresso CodFamilia=0 Status=COMPLETA). GET /products/full-search pulado."
            CriarResultadoCargaJaObtida = _resultado
        End Function

        Private Function ExecutarSincronizacaoCatalogoCompleto(pOpcoes As RedeAncoraProdutoSincronizacaoOpcoesModel) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _resultado As New RedeAncoraProdutoSincronizacaoResultadoModel()
            Dim _familias As RedeAncoraFamiliasModel = NULL
            Dim _progresso As RedeAncoraProdutoSyncProgressoModel = NULL
            Dim _tamanhoPagina As Integer = me.ResolverTamanhoChunk(pOpcoes.TamanhoChunk)
            Dim _modo As String = me.ResolverModo(pOpcoes.Modo)
            Dim _i As Integer
            Dim _codFamilia As Integer
            Dim _pagina As Integer
            Dim _ultimaPagina As Integer
            Dim _qtdItens As Integer
            Dim _statusProgresso As String = ""
            Dim _pularFamilia As Boolean = False
            Dim _body As String = ""
            Dim _result As RedeAncoraProdutoSincronizacaoResultadoModel = NULL

            Try
                me._cnasExistentes = me._vinculoRepository.ListarTodosCnas()
                _resultado.DataInicio = DateTime()
                _resultado.Modo = _modo
                _familias = me._catalogoService.ListarFamilias()

                If _familias.Length <= 0 Then
                    _familias.Free()
                    me._catalogoService.SincronizarCatalogo(pOpcoes.CodUsuario)
                    _familias = me._catalogoService.ListarFamilias()
                End If

                If _familias.Length <= 0 Then
                    Throw New System.Exception("Familias Rede Ancora nao sincronizadas. Execute SincronizarCatalogo antes do download completo.")
                End If

                If pOpcoes.ReiniciarProgresso Then
                    me._progressoRepository.LimparTodos()
                    mod_logger.Printe("Rede Ancora sync catalogo completo :: progresso zerado (ReiniciarProgresso)")
                End If

                mod_logger.Printe("Rede Ancora sync catalogo completo :: familias: " & Parser.IntegerToString(_familias.Length) & " | pagina: " & Parser.IntegerToString(_tamanhoPagina))
                mod_logger.Info("sync-full: imagens extraidas do blob se presentes (sem TJSONObject)")

                For _i = 0 To _familias.Length - 1
                    _codFamilia = _familias.Take(_i).CodFamilia
                    mod_logger.Info("sync-full: familia CodFamilia=" & Parser.IntegerToString(_codFamilia) & " lista=" & Parser.IntegerToString(_i) & "/" & Parser.IntegerToString(_familias.Length))
                    _pagina = 1
                    _ultimaPagina = 1
                    _pularFamilia = False

                    If Assigned(_progresso) Then
                        _progresso.Free()
                        _progresso = NULL
                    End If

                    _progresso = New RedeAncoraProdutoSyncProgressoModel()
                    If me._progressoRepository.TryObterPorCodFamilia(_codFamilia, _progresso) Then
                        If _progresso.EstaDone() Then
                            _pularFamilia = True
                            mod_logger.Printe("Rede Ancora sync familia " & Parser.IntegerToString(_codFamilia) & " Status=DONE - HTTP pulado")
                        Else
                            _pagina = _progresso.ProximaPagina()
                            If _progresso.LastPage > 0 Then
                                _ultimaPagina = _progresso.LastPage
                            Else
                                _ultimaPagina = _pagina
                            End If
                            mod_logger.Printe("Rede Ancora sync familia " & Parser.IntegerToString(_codFamilia) & " retoma pagina " & Parser.IntegerToString(_pagina) & " (UltimaPaginaOk=" & Parser.IntegerToString(_progresso.UltimaPaginaOk) & ")")
                        End If
                    End If

                    If Not _pularFamilia Then
                        While _pagina <= _ultimaPagina
                            _resultado.QtdChunks = _resultado.QtdChunks + 1
                            _qtdItens = 0
                            _body = ""

                            _body = me._produtoService.BuscarProdutoFullSearchPorFamilia(pOpcoes.CodUsuario, pOpcoes.CodCentroDistribuicao, _codFamilia, _pagina, _tamanhoPagina)
                            _resultado.QtdChunksApi = _resultado.QtdChunksApi + 1

                            mod_logger.Info("sync-full: before parse familia=" & Parser.IntegerToString(_codFamilia) & " pagina=" & Parser.IntegerToString(_pagina) & " bytes=" & Parser.IntegerToString(Len(_body)))
                            DiagStack.Push("sync-full.PersistirBlob")

                            Try
                                _qtdItens = me.PersistirProdutosFullSearchDeBlob(_body, RedeAncoraProdutoSincronizacaoModo.IsSomenteNovos(_modo), _resultado, _codFamilia)
                                DiagStack.Pop()
                            Catch exPersistir As Exception
                                DiagStack.DumpOnError(exPersistir)
                                DiagStack.Pop()
                                Throw New System.Exception("Erro ao persistir pagina full-search familia=" & Parser.IntegerToString(_codFamilia) & " pagina=" & Parser.IntegerToString(_pagina) & ": " & me.MensagemExcecaoSegura(exPersistir))
                            End Try

                            _ultimaPagina = me.ObterLastPageDoSufixo(_body)
                            If _ultimaPagina <= 0 Then
                                If _qtdItens < _tamanhoPagina Then
                                    _ultimaPagina = _pagina
                                Else
                                    _ultimaPagina = _pagina + 1
                                End If
                            End If

                            If _pagina >= _ultimaPagina Then
                                _statusProgresso = RedeAncoraProdutoSyncProgressoModel.StatusDone()
                            Else
                                _statusProgresso = RedeAncoraProdutoSyncProgressoModel.StatusPagina()
                            End If

                            Try
                                me._progressoRepository.Upsert(_codFamilia, _pagina, _ultimaPagina, _statusProgresso)
                            Catch exCk As Exception
                                RedeAncoraHttpErroHelper.RegistrarExcecao("sync-full.checkpoint familia=" & Parser.IntegerToString(_codFamilia) & " pagina=" & Parser.IntegerToString(_pagina), exCk)
                                Throw New System.Exception("Falha ao gravar checkpoint Integracao.RedeAncoraProdutoSyncProgresso familia=" & Parser.IntegerToString(_codFamilia) & " pagina=" & Parser.IntegerToString(_pagina) & ": " & me.MensagemExcecaoSegura(exCk))
                            End Try

                            mod_logger.Info("sync-full: after parse familia=" & Parser.IntegerToString(_codFamilia) & " itens=" & Parser.IntegerToString(_qtdItens) & " last_page=" & Parser.IntegerToString(_ultimaPagina) & " status=" & _statusProgresso)
                            mod_logger.Printe("Rede Ancora sync familia " & Parser.IntegerToString(_codFamilia) & " pagina " & Parser.IntegerToString(_pagina) & "/" & Parser.IntegerToString(_ultimaPagina) & " | inseridos: " & Parser.IntegerToString(_resultado.QtdInseridos) & " | atualizados: " & Parser.IntegerToString(_resultado.QtdAtualizados))

                            _pagina = _pagina + 1
                            If _pagina > 10000 Then
                                Throw New System.Exception("Limite de paginas full-search excedido na familia " & Parser.IntegerToString(_codFamilia))
                            End If
                        Wend
                    End If
                Next

                If Assigned(_progresso) Then
                    _progresso.Free()
                    _progresso = NULL
                End If

                Try
                    me._progressoRepository.MarcarCargaCompleta()
                    mod_logger.Printe("Carga completa obtida: Integracao.RedeAncoraProdutoSyncProgresso CodFamilia=0 Status=COMPLETA. Proxima execucao nao refaz o full-search.")
                Catch exMarca As Exception
                    RedeAncoraHttpErroHelper.RegistrarExcecao("sync-full.marcar COMPLETA", exMarca)
                    Throw New System.Exception("Falha ao gravar marcador COMPLETA em Integracao.RedeAncoraProdutoSyncProgresso: " & me.MensagemExcecaoSegura(exMarca))
                End Try

                _resultado.Finalizar()
                me._cnasExistentes.Free()
                me._cnasExistentes = NULL
                _familias.Free()
                _familias = NULL
                _result = _resultado
                _resultado = NULL
            Catch ex As Exception
                DiagStack.DumpOnError(ex)

                If Assigned(_progresso) Then
                    _progresso.Free()
                End If

                If Assigned(_familias) Then
                    _familias.Free()
                End If

                If Assigned(me._cnasExistentes) Then
                    me._cnasExistentes.Free()
                    me._cnasExistentes = NULL
                End If

                If Assigned(_resultado) Then
                    _resultado.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar catalogo completo Rede Ancora: " & me.MensagemExcecaoSegura(ex))
            End Try

            ExecutarSincronizacaoCatalogoCompleto = _result
        End Function

        Private Function ExecutarSincronizacaoCnas(pOpcoes As RedeAncoraProdutoSincronizacaoOpcoesModel, pCnas As RedeAncoraProdutoCnasModel) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _resultado As New RedeAncoraProdutoSincronizacaoResultadoModel()
            Dim _tamanhoChunk As Integer = me.ResolverTamanhoChunk(pOpcoes.TamanhoChunk)
            Dim _offset As Integer = 0
            Dim _modo As String = me.ResolverModo(pOpcoes.Modo)
            Dim _numeroChunk As Integer = 0
            Dim _totalChunks As Integer = 0
            Dim _result As RedeAncoraProdutoSincronizacaoResultadoModel = NULL

            Try
                If pCnas.Length <= 0 Then
                    Throw New System.Exception("Nenhum CNA informado para sincronizacao de produtos Rede Ancora")
                End If

                me._cnasExistentes = me._vinculoRepository.ListarTodosCnas()
                _resultado.DataInicio = DateTime()
                _resultado.Modo = _modo
                _resultado.QtdCnasSolicitados = pCnas.Length
                _totalChunks = me.CalcularTotalChunks(pCnas.Length, _tamanhoChunk)

                While _offset < pCnas.Length
                    Dim _chunk As RedeAncoraProdutoCnasModel = NULL

                    _numeroChunk = _numeroChunk + 1
                    _resultado.QtdChunks = _resultado.QtdChunks + 1
                    _chunk = me.ExtrairChunk(pCnas, _offset, _tamanhoChunk)

                    Try
                        me.ProcessarChunk(pOpcoes, _chunk, _modo, _numeroChunk, _totalChunks, _resultado)
                    Catch exChunk As Exception
                        If me.IsErroAutenticacao(exChunk) Then
                            Throw exChunk
                        End If

                        _resultado.RegistrarErroChunk(_numeroChunk, exChunk._getMessage())
                    End Try

                    _chunk.Free()
                    _offset = _offset + _tamanhoChunk
                Wend

                _resultado.Finalizar()
                me._cnasExistentes.Free()
                me._cnasExistentes = NULL
                _result = _resultado
                _resultado = NULL
            Catch ex As Exception
                If Assigned(me._cnasExistentes) Then
                    me._cnasExistentes.Free()
                    me._cnasExistentes = NULL
                End If

                If Assigned(_resultado) Then
                    _resultado.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar produtos Rede Ancora: " & ex._getMessage())
            End Try

            ExecutarSincronizacaoCnas = _result
        End Function

        Private Function ResolverTamanhoChunk(pTamanhoChunk As Integer) As Integer
            If pTamanhoChunk > 0 Then
                ResolverTamanhoChunk = pTamanhoChunk
            Else
                ResolverTamanhoChunk = RedeAncoraApiConfig.TamanhoChunkSincronizacaoProdutos()
            End If
        End Function

        Private Function ResolverModo(pModo As String) As String
            If RedeAncoraProdutoSincronizacaoModo.IsSomenteNovos(pModo) Then
                ResolverModo = RedeAncoraProdutoSincronizacaoModo.SomenteNovos()
            Else
                ResolverModo = RedeAncoraProdutoSincronizacaoModo.Completa()
            End If
        End Function

        Private Function ResolverListaCnas(pOpcoes As RedeAncoraProdutoSincronizacaoOpcoesModel) As RedeAncoraProdutoCnasModel
            If pOpcoes.UsarProdutosCadastrados Then
                ResolverListaCnas = me.MontarCnasDosProdutosCadastrados()
                Exit Function
            End If

            If pOpcoes.TemListaCnas() Then
                ResolverListaCnas = me.NormalizarCnas(pOpcoes.Cnas)
                Exit Function
            End If

            If RedeAncoraProdutoSincronizacaoModo.IsCompleta(pOpcoes.Modo) Then
                ResolverListaCnas = me.MontarCnasDosProdutosCadastrados()
                Exit Function
            End If

            Throw New System.Exception("Nenhum CNA informado para sincronizacao de produtos Rede Ancora")
        End Function

        Private Function NormalizarCnas(pCnas As RedeAncoraProdutoCnasModel) As RedeAncoraProdutoCnasModel
            Dim _normalizado As New RedeAncoraProdutoCnasModel()
            Dim _i As Integer

            For _i = 0 To pCnas.Length - 1
                _normalizado.PushDistinct(pCnas.Take(_i))
            Next

            NormalizarCnas = _normalizado
        End Function

        Private Function MontarCnasDosProdutosCadastrados() As RedeAncoraProdutoCnasModel
            Dim _produtos As RedeAncoraProdutoVinculosModel = NULL
            Dim _cnas As New RedeAncoraProdutoCnasModel()
            Dim _i As Integer

            Try
                _produtos = me._vinculoRepository.ListarAtivos()

                For _i = 0 To _produtos.Length - 1
                    _cnas.PushDistinct(_produtos.Take(_i).Cna)
                Next

                _produtos.Free()
                MontarCnasDosProdutosCadastrados = _cnas
            Catch ex As Exception
                If Assigned(_produtos) Then
                    _produtos.Free()
                End If

                _cnas.Free()
                Throw ex
            End Try
        End Function

        Private Function ExtrairChunk(pCnas As RedeAncoraProdutoCnasModel, pInicio As Integer, pTamanho As Integer) As RedeAncoraProdutoCnasModel
            Dim _chunk As New RedeAncoraProdutoCnasModel()
            Dim _fim As Integer = pInicio + pTamanho - 1
            Dim _i As Integer

            If _fim > pCnas.Length - 1 Then
                _fim = pCnas.Length - 1
            End If

            For _i = pInicio To _fim
                _chunk.Push(pCnas.Take(_i))
            Next

            ExtrairChunk = _chunk
        End Function

        Private Function CalcularTotalChunks(pTotalCnas As Integer, pTamanhoChunk As Integer) As Integer
            If pTamanhoChunk <= 0 Then
                CalcularTotalChunks = 0
                Exit Function
            End If

            CalcularTotalChunks = Int((pTotalCnas + pTamanhoChunk - 1) / pTamanhoChunk)
        End Function

        Private Sub ProcessarChunk(pOpcoes As RedeAncoraProdutoSincronizacaoOpcoesModel, pChunk As RedeAncoraProdutoCnasModel, pModo As String, pNumeroChunk As Integer, pTotalChunks As Integer, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel)
            Dim _body As String = ""
            Dim _json As TJSONObject = NULL
            Dim _data As TJSONArray = NULL
            Dim _cnasEncontrados As RedeAncoraProdutoCnasModel = New RedeAncoraProdutoCnasModel()
            Dim _chunkApi As RedeAncoraProdutoCnasModel = NULL
            Dim _tx As Transaction = NULL
            Dim _somenteNovos As Boolean = RedeAncoraProdutoSincronizacaoModo.IsSomenteNovos(pModo)
            Dim _itemJson As TJSONObject = NULL

            Try
                pChunk.ValidarTodos()
                _chunkApi = me.PrepararChunkParaApi(pChunk, _somenteNovos, pResultado)

                If _chunkApi.Length <= 0 Then
                    _chunkApi.Free()
                    _chunkApi = NULL
                    _cnasEncontrados.Free()
                    _cnasEncontrados = NULL
                    Exit Sub
                End If

                _body = me._produtoService.BuscarProdutoBulkSearch(pOpcoes.CodUsuario, pOpcoes.CodCentroDistribuicao, pOpcoes.CodEstado, _chunkApi, 1, _chunkApi.Length)
                pResultado.QtdChunksApi = pResultado.QtdChunksApi + 1
                _json = New TJSONObject(_body)
                _data = RedeAncoraJsonHelper.ObterDataArray(_json)

                _tx = Transaction.Instance()
                _tx.OffAutoCommit()
                _tx.StartTransaction("Integracao.RedeAncoraProdutoVinculo Sync chunk " + pNumeroChunk.ToString())

                me.PersistirItensProdutoApi(_data, _somenteNovos, pResultado, False, _cnasEncontrados)

                If RedeAncoraProdutoSincronizacaoModo.IsCompleta(pModo) Then
                    me.ProcessarCnasAusentes(_chunkApi, _cnasEncontrados, pOpcoes.DesativarAusentes, pResultado, False)
                Else
                    me.ProcessarCnasAusentesSomenteNovos(_chunkApi, _cnasEncontrados, pResultado)
                End If

                _tx.OnAutoCommit()
                _tx.Commit()
                me.LogProgressoChunk(pNumeroChunk, pTotalChunks, pResultado)
                _chunkApi.Free()
                _chunkApi = NULL
                _cnasEncontrados.Free()
                _cnasEncontrados = NULL

                If Assigned(_data) Then
                    _data.Free()
                    _data = NULL
                End If

                If Assigned(_json) Then
                    _json.Free()
                    _json = NULL
                End If
            Catch ex As Exception
                If Assigned(_itemJson) Then
                    _itemJson.Free()
                End If

                If Assigned(_tx) Then
                    _tx.Rollback()
                    _tx.OnAutoCommit()
                End If

                If Assigned(_chunkApi) Then
                    _chunkApi.Free()
                End If

                If Assigned(_cnasEncontrados) Then
                    _cnasEncontrados.Free()
                End If

                If Assigned(_data) Then
                    _data.Free()
                End If

                If Assigned(_json) Then
                    _json.Free()
                End If

                Throw ex
            End Try
        End Sub

        ' Full-search: nunca TJSONObject no body. Marcas 370KB sobreviveram com Mid 200 no blob
        ' + ASCII na fatia. Mid 800 / Mid 1-char no OleStr da pagina = Invalid pointer.
        Private Function PersistirProdutosFullSearchDeBlob(pBody As String, pSomenteNovos As Boolean, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel, pCodFamilia As Integer) As Integer
            Dim _tx As Transaction = NULL
            Dim _arrayStart As Integer = 0
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _janela As String = ""
            Dim _idxAbre As Integer = 0
            Dim _objStart As Integer = 0
            Dim _objFim As Integer = 0
            Dim _prox As Integer = 0
            Dim _qtd As Integer = 0
            Dim _result As Integer = 0
            Dim _itemOk As Boolean = False
            Dim _janelaOk As Boolean = False
            Dim _acabou As Boolean = False
            Dim _msg As String = ""
            Dim _tipoWalk As String = ""
            Dim _cadastro As RedeAncoraProdutoModel = NULL
            Dim _urlReal As String = ""
            Dim _urlIlustrativa As String = ""
            Dim _tecnicasBlob As String = ""

            Try
                _arrayStart = me.PosicaoArrayDataAscii(pBody)
                If _arrayStart <= 0 Then
                    Throw New System.Exception("Resposta /products/full-search sem array data")
                End If
                mod_logger.Info("sync-full: array pos=" & Parser.IntegerToString(_arrayStart))
                DiagStack.Trace("sync-full: after array pos")

                _bodyLen = Len(pBody)
                _pos = _arrayStart + 1
                DiagStack.Trace("sync-full: before walk")

                While _pos <= _bodyLen
                    If _acabou Then
                        _pos = _bodyLen + 1
                    Else
                        _janela = me.CopiarJanelaAscii(pBody, _pos, 200)
                        If _janela = "" Then
                            _acabou = True
                        Else
                            If Not _janelaOk Then
                                _janelaOk = True
                                DiagStack.Trace("sync-full: first window ok")
                                mod_logger.Info("sync-full: first window ok len=" & Parser.IntegerToString(Len(_janela)))
                            End If

                            _idxAbre = me.PosicaoAbreObjetoNaJanela(_janela)

                            If _idxAbre < 0 Then
                                _acabou = True
                            Else
                                If _idxAbre = 0 Then
                                    _pos = _pos + Len(_janela)
                                Else
                                    _objStart = _pos + _idxAbre - 1
                                    _urlReal = ""
                                    _urlIlustrativa = ""
                                    _tecnicasBlob = ""
                                    _itemOk = False
                                    _objFim = 0

                                    If Assigned(_cadastro) Then
                                        _cadastro.Free()
                                        _cadastro = NULL
                                    End If

                                    If Not Assigned(_tx) Then
                                        DiagStack.Trace("sync-full: before tx")
                                        mod_logger.Info("sync-full: before tx")
                                        _tx = Transaction.Instance()
                                        _tx.OffAutoCommit()
                                        _tx.StartTransaction("Integracao.RedeAncoraProduto Sync full-search")
                                        DiagStack.Trace("sync-full: after tx")
                                        mod_logger.Info("sync-full: after tx")
                                    End If

                                    _cadastro = New RedeAncoraProdutoModel()
                                    _cadastro.Ativo = ""

                                    If _qtd = 0 Then
                                        DiagStack.Trace("sync-full: first item walk")
                                        mod_logger.Info("sync-full: first item walk objStart=" & Parser.IntegerToString(_objStart))
                                    End If

                                    Try
                                        _objFim = me.AvancarFimObjetoEExtrair(pBody, _objStart, _cadastro, _urlReal, _urlIlustrativa, _tecnicasBlob)
                                        _itemOk = True

                                        If _qtd = 0 Then
                                            DiagStack.Trace("sync-full: first item walk ok")
                                            mod_logger.Info("sync-full: first item walk ok objFim=" & Parser.IntegerToString(_objFim))
                                        End If
                                    Catch exWalk As Exception
                                        _tipoWalk = me.NomeTipoExcecao(exWalk)
                                        _msg = me.MensagemExcecaoSegura(exWalk)
                                        RedeAncoraHttpErroHelper.RegistrarExcecao("sync-full.walk familia=" & Parser.IntegerToString(pCodFamilia), exWalk)
                                        pResultado.RegistrarErroChunk(pResultado.QtdChunks, "item ignorado familia " & Parser.IntegerToString(pCodFamilia) & ": " & _tipoWalk & " " & _msg)
                                        If me.EhExcecaoPaxExit(_tipoWalk) Then
                                            mod_logger.Info("sync-full: PaxExitException no walk, pulando item objStart=" & Parser.IntegerToString(_objStart))
                                        End If
                                    End Try

                                    If _itemOk Then
                                        If _cadastro.Cna <= 0 Then
                                            _cadastro.Cna = me.ExtrairCnaDoObjeto(pBody, _objStart, _objFim)
                                        End If
                                        If _cadastro.Cna <= 0 Then
                                            mod_logger.Info("sync-full: item ignorado cna<=0 objStart=" & Parser.IntegerToString(_objStart) & " objFim=" & Parser.IntegerToString(_objFim))
                                            pResultado.QtdIgnorados = pResultado.QtdIgnorados + 1
                                        Else
                                            Try
                                                me.PersistirProdutoDoCadastro(_cadastro, pCodFamilia, pSomenteNovos, pResultado, _urlReal, _urlIlustrativa, _tecnicasBlob)
                                                _qtd = _qtd + 1

                                                If _qtd = 1 Then
                                                    mod_logger.Info("sync-full: primeiro item ok cna=" & Parser.IntegerToString(_cadastro.Cna))
                                                End If
                                            Catch exItem As Exception
                                                _tipoWalk = me.NomeTipoExcecao(exItem)
                                                RedeAncoraHttpErroHelper.RegistrarExcecao("sync-full.item familia=" & Parser.IntegerToString(pCodFamilia), exItem)
                                                pResultado.RegistrarErroChunk(pResultado.QtdChunks, "item malformado familia " & Parser.IntegerToString(pCodFamilia) & ": " & _tipoWalk & " " & me.MensagemExcecaoSegura(exItem))
                                            End Try
                                        End If
                                    End If

                                    If Assigned(_cadastro) Then
                                        _cadastro.Free()
                                        _cadastro = NULL
                                    End If

                                    If _itemOk Then
                                        If _objFim <= 0 Then
                                            _acabou = True
                                        Else
                                            _pos = _objFim + 1
                                        End If
                                    Else
                                        Try
                                            _prox = me.AvancarFimObjeto(pBody, _objStart)
                                        Catch exPular As Exception
                                            _tipoWalk = me.NomeTipoExcecao(exPular)
                                            RedeAncoraHttpErroHelper.RegistrarExcecao("sync-full.pular familia=" & Parser.IntegerToString(pCodFamilia), exPular)
                                            Throw New System.Exception("Erro de ponteiro no parse full-search familia=" & Parser.IntegerToString(pCodFamilia) & ": " & _tipoWalk & " " & me.MensagemExcecaoSegura(exPular))
                                        End Try

                                        If _prox <= 0 Then
                                            _acabou = True
                                        Else
                                            _pos = _prox + 1
                                        End If
                                    End If
                                End If
                            End If
                        End If
                    End If
                Wend

                If Assigned(_tx) Then
                    _tx.OnAutoCommit()
                    _tx.Commit()
                    _tx = NULL
                End If
                _result = _qtd
            Catch ex As Exception
                If Assigned(_cadastro) Then
                    _cadastro.Free()
                    _cadastro = NULL
                End If

                If Assigned(_tx) Then
                    _tx.Rollback()
                    _tx.OnAutoCommit()
                End If

                Throw New System.Exception("Erro no parse full-search familia=" & Parser.IntegerToString(pCodFamilia) & ": " & me.MensagemExcecaoSegura(ex))
            End Try

            PersistirProdutosFullSearchDeBlob = _result
        End Function

        Private Sub PersistirProdutoDoCadastro(pCadastro As RedeAncoraProdutoModel, pCodFamilia As Integer, pSomenteNovos As Boolean, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel, pUrlReal As String, pUrlIlustrativa As String, pTecnicasBlob As String)
            Dim _cna As Integer = 0
            Dim _upsert As Integer = 0
            Dim _seguir As Boolean = False

            If Assigned(pCadastro) Then
                _cna = pCadastro.Cna
                If _cna <= 0 Then
                    mod_logger.Info("sync-full: item ignorado cna<=0")
                    pResultado.QtdIgnorados = pResultado.QtdIgnorados + 1
                Else
                    _seguir = True
                    If pSomenteNovos Then
                        If me.CnaJaCadastrado(_cna) Then
                            pResultado.QtdIgnorados = pResultado.QtdIgnorados + 1
                            _seguir = False
                        End If
                    End If
                End If
            End If

            If _seguir Then
                If pCadastro.CodFamilia <= 0 Then
                    pCadastro.CodFamilia = pCodFamilia
                End If

                If pCadastro.NomeProduto.Trim() = "" Then
                    pCadastro.NomeProduto = pCadastro.NomeErp
                End If

                If pCadastro.Ativo.Trim() = "" Then
                    pCadastro.Ativo = "S"
                End If

                _upsert = me._produtoService.UpsertCadastroProdutoEVinculo(pCadastro, RedeAncoraProdutoVinculoOrigem.Sincronizacao(), False)
                me.RegistrarResultadoUpsert(_upsert, pResultado)

                Try
                    me._produtoService.PersistirImagensProdutoDeCampos(_cna, pUrlReal, pUrlIlustrativa, pTecnicasBlob, False)
                Catch exImg As Exception
                    RedeAncoraHttpErroHelper.RegistrarExcecao("sync-full.imagens cna=" & Parser.IntegerToString(_cna), exImg)
                End Try

                If _upsert = 1 Then
                    If Assigned(me._cnasExistentes) Then
                        me._cnasExistentes.PushDistinct(_cna)
                    End If
                End If
            End If
        End Sub

        Private Function CoalesceTextoFatia(pAtual As String, pFatia As String, pChave As String, pTeto As Integer) As String
            Dim _valor As String = ""

            If pAtual.Trim() <> "" Then
                CoalesceTextoFatia = pAtual
                Exit Function
            End If

            If pTeto > 80 Then
                _valor = me.ExtrairTextoJsonDoPrefixoAsciiComTeto(pFatia, pChave, pTeto)
            Else
                _valor = me.ExtrairTextoJsonDoPrefixoAscii(pFatia, pChave)
            End If

            If _valor.Trim() = "" Then
                _valor = me.ExtrairLiteralJsonDoPrefixoAscii(pFatia, pChave)
            End If

            CoalesceTextoFatia = _valor
        End Function

        Private Function CoalesceInteiroFatia(pAtual As Integer, pFatia As String, pChave As String) As Integer
            If pAtual > 0 Then
                CoalesceInteiroFatia = pAtual
            Else
                CoalesceInteiroFatia = me.ExtrairInteiroDoPrefixoAscii(pFatia, pChave)
            End If
        End Function

        Private Function CoalesceDecimalFatia(pAtual As Double, pFatia As String, pChave As String) As Double
            Dim _tok As String = ""

            If pAtual <> 0 Then
                CoalesceDecimalFatia = pAtual
                Exit Function
            End If

            _tok = me.ExtrairLiteralJsonDoPrefixoAscii(pFatia, pChave)
            If _tok = "" Then
                CoalesceDecimalFatia = 0
            Else
                CoalesceDecimalFatia = Parser.StringToDouble(_tok)
            End If
        End Function

        Private Function CoalesceFlagFatia(pAtual As String, pFatia As String, pChave As String) As String
            Dim _tri As Integer = 0

            If pAtual.Trim() <> "" Then
                CoalesceFlagFatia = pAtual
                Exit Function
            End If

            _tri = me.ExtrairBooleanTriDoPrefixoAscii(pFatia, pChave)
            If _tri < 0 Then
                CoalesceFlagFatia = ""
            Else
                If _tri > 0 Then
                    CoalesceFlagFatia = "S"
                Else
                    CoalesceFlagFatia = "N"
                End If
            End If
        End Function

        Private Sub PreencherCadastroDaFatia(pFatia As String, pCadastro As RedeAncoraProdutoModel)
            pCadastro.Cna = me.CoalesceInteiroFatia(pCadastro.Cna, pFatia, "cna")
            pCadastro.CatalogoId = me.CoalesceInteiroFatia(pCadastro.CatalogoId, pFatia, "catalogo_id")
            pCadastro.Csa = me.CoalesceTextoFatia(pCadastro.Csa, pFatia, "csa", 30)
            pCadastro.Cnl = me.CoalesceTextoFatia(pCadastro.Cnl, pFatia, "cnl", 30)
            pCadastro.CodigoReferencia = me.CoalesceTextoFatia(pCadastro.CodigoReferencia, pFatia, "codigoReferencia", 30)
            pCadastro.CodigoReferencia = me.CoalesceTextoFatia(pCadastro.CodigoReferencia, pFatia, "code", 30)
            pCadastro.CodeEdi = me.CoalesceTextoFatia(pCadastro.CodeEdi, pFatia, "code_edi", 30)
            pCadastro.CodeManufacturer = me.CoalesceTextoFatia(pCadastro.CodeManufacturer, pFatia, "code_manufacturer", 30)
            pCadastro.NomeProduto = me.CoalesceTextoFatia(pCadastro.NomeProduto, pFatia, "nomeProduto", 255)
            pCadastro.NomeProduto = me.CoalesceTextoFatia(pCadastro.NomeProduto, pFatia, "description", 255)
            pCadastro.NomeErp = me.CoalesceTextoFatia(pCadastro.NomeErp, pFatia, "nome", 255)
            pCadastro.NomeErp = me.CoalesceTextoFatia(pCadastro.NomeErp, pFatia, "name", 255)
            pCadastro.InformacoesAdicionais = me.CoalesceTextoFatia(pCadastro.InformacoesAdicionais, pFatia, "informacoesAdicionais", 500)
            pCadastro.InformacoesComplementares = me.CoalesceTextoFatia(pCadastro.InformacoesComplementares, pFatia, "informacoesComplementares", 500)
            pCadastro.AdditionalDescription = me.CoalesceTextoFatia(pCadastro.AdditionalDescription, pFatia, "additional_description", 500)
            pCadastro.PontoCriticoAtencao = me.CoalesceTextoFatia(pCadastro.PontoCriticoAtencao, pFatia, "pontoCriticoAtencao", 255)
            pCadastro.Dimensoes = me.CoalesceTextoFatia(pCadastro.Dimensoes, pFatia, "dimensoes", 255)
            pCadastro.CodMarca = me.CoalesceInteiroFatia(pCadastro.CodMarca, pFatia, "marcaId")
            pCadastro.CodMarcaErp = me.CoalesceInteiroFatia(pCadastro.CodMarcaErp, pFatia, "brand_id")
            pCadastro.NomeMarca = me.CoalesceTextoFatia(pCadastro.NomeMarca, pFatia, "marca", 120)
            pCadastro.NomeMarca = me.CoalesceTextoFatia(pCadastro.NomeMarca, pFatia, "brand", 120)
            pCadastro.CodLinha = me.CoalesceInteiroFatia(pCadastro.CodLinha, pFatia, "line")
            pCadastro.CodLinha = me.CoalesceInteiroFatia(pCadastro.CodLinha, pFatia, "line_id")
            pCadastro.NomeLinha = me.CoalesceTextoFatia(pCadastro.NomeLinha, pFatia, "line_name", 120)
            pCadastro.CodFamilia = me.CoalesceInteiroFatia(pCadastro.CodFamilia, pFatia, "family")
            pCadastro.CodFamilia = me.CoalesceInteiroFatia(pCadastro.CodFamilia, pFatia, "family_id")
            pCadastro.NomeFamilia = me.CoalesceTextoFatia(pCadastro.NomeFamilia, pFatia, "family_name", 120)
            pCadastro.CodFabricante = me.CoalesceInteiroFatia(pCadastro.CodFabricante, pFatia, "manufacturer_id")
            pCadastro.CodFabricante = me.CoalesceInteiroFatia(pCadastro.CodFabricante, pFatia, "fabricante")
            pCadastro.Ean = me.CoalesceTextoFatia(pCadastro.Ean, pFatia, "ean", 20)
            pCadastro.Gtin = me.CoalesceTextoFatia(pCadastro.Gtin, pFatia, "gtin", 20)
            pCadastro.Ncm = me.CoalesceTextoFatia(pCadastro.Ncm, pFatia, "ncm", 30)
            pCadastro.Cest = me.CoalesceTextoFatia(pCadastro.Cest, pFatia, "cest", 20)
            pCadastro.Origem = me.CoalesceTextoFatia(pCadastro.Origem, pFatia, "origem", 10)
            pCadastro.OrigemLabel = me.CoalesceTextoFatia(pCadastro.OrigemLabel, pFatia, "origem_label", 200)
            pCadastro.Anp = me.CoalesceInteiroFatia(pCadastro.Anp, pFatia, "anp")
            pCadastro.AnpLabel = me.CoalesceTextoFatia(pCadastro.AnpLabel, pFatia, "anp_label", 200)
            pCadastro.PesoLiquido = me.CoalesceDecimalFatia(pCadastro.PesoLiquido, pFatia, "peso_liquido")
            pCadastro.PesoLiquido = me.CoalesceDecimalFatia(pCadastro.PesoLiquido, pFatia, "net_weight")
            pCadastro.PesoBruto = me.CoalesceDecimalFatia(pCadastro.PesoBruto, pFatia, "peso_bruto")
            pCadastro.PesoBruto = me.CoalesceDecimalFatia(pCadastro.PesoBruto, pFatia, "gross_weight")
            pCadastro.Volume = me.CoalesceDecimalFatia(pCadastro.Volume, pFatia, "volume")
            pCadastro.Litros = me.CoalesceDecimalFatia(pCadastro.Litros, pFatia, "liters")
            pCadastro.Tamanho = me.CoalesceTextoFatia(pCadastro.Tamanho, pFatia, "tamanho", 60)
            pCadastro.Material = me.CoalesceTextoFatia(pCadastro.Material, pFatia, "material", 120)
            pCadastro.Tipo = me.CoalesceInteiroFatia(pCadastro.Tipo, pFatia, "tipo")
            pCadastro.MedidaVenda = me.CoalesceTextoFatia(pCadastro.MedidaVenda, pFatia, "medida_venda", 20)
            pCadastro.GarantiaDias = me.CoalesceInteiroFatia(pCadastro.GarantiaDias, pFatia, "garantia_dias")
            pCadastro.GarantiaDias = me.CoalesceInteiroFatia(pCadastro.GarantiaDias, pFatia, "warranty")
            pCadastro.FracaoFabrica = me.CoalesceInteiroFatia(pCadastro.FracaoFabrica, pFatia, "fracao_fabrica")
            pCadastro.FracaoLoja = me.CoalesceInteiroFatia(pCadastro.FracaoLoja, pFatia, "fracao_loja")
            pCadastro.Status = me.CoalesceInteiroFatia(pCadastro.Status, pFatia, "status")
            pCadastro.ErpHandle = me.CoalesceInteiroFatia(pCadastro.ErpHandle, pFatia, "erp_handle")
            pCadastro.ErpHandle = me.CoalesceInteiroFatia(pCadastro.ErpHandle, pFatia, "handle")
            pCadastro.Leadtime = me.CoalesceInteiroFatia(pCadastro.Leadtime, pFatia, "leadtime")
            pCadastro.OnDemandLabel = me.CoalesceTextoFatia(pCadastro.OnDemandLabel, pFatia, "on_demand_label", 120)
            pCadastro.MotivoDescontinuado = me.CoalesceTextoFatia(pCadastro.MotivoDescontinuado, pFatia, "motivo_descontinuado", 255)
            pCadastro.Ativo = me.CoalesceFlagFatia(pCadastro.Ativo, pFatia, "ativo")
            pCadastro.Descontinuado = me.CoalesceFlagFatia(pCadastro.Descontinuado, pFatia, "descontinuado")
            pCadastro.Bloqueado = me.CoalesceFlagFatia(pCadastro.Bloqueado, pFatia, "bloqueado")
            pCadastro.Confiavel = me.CoalesceFlagFatia(pCadastro.Confiavel, pFatia, "confiavel")
            pCadastro.Sugerido = me.CoalesceFlagFatia(pCadastro.Sugerido, pFatia, "sugerido")
            pCadastro.Lancamento = me.CoalesceFlagFatia(pCadastro.Lancamento, pFatia, "lancamento")
            pCadastro.OnDemand = me.CoalesceFlagFatia(pCadastro.OnDemand, pFatia, "on_demand")
            pCadastro.ParcialmenteSimilar = me.CoalesceFlagFatia(pCadastro.ParcialmenteSimilar, pFatia, "parcialmente_similar")
            pCadastro.HasRestrictions = me.CoalesceFlagFatia(pCadastro.HasRestrictions, pFatia, "has_restrictions")
            pCadastro.PrazoEspecial = me.CoalesceFlagFatia(pCadastro.PrazoEspecial, pFatia, "prazo_especial")
        End Sub

        ' Janelas Mid 200 no blob (padrao marcas). Tokenizer no slice ASCII.
        ' Sem Exit Function/Exit While: PaxExitException vaza para o Catch do caller.
        ' Campos so no objeto raiz (depth=1). Similares/imagens aninhados nao viram CNA.
        Private Function AvancarFimObjetoEExtrair(pBody As String, pStart As Integer, pCadastro As RedeAncoraProdutoModel, ByRef pImagemReal As String, ByRef pImagemIlustrativa As String, ByRef pTecnicasBlob As String) As Integer
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
                                        me.ConsumirCharJsonObjeto(_ch, _q, _depth, _arrDepth, _inQuotes, _escape, _esperandoChave, _lendoChave, _depoisDeChave, _lendoValor, _valorString, _chave, _valor, _chaveDepth, pCadastro, pImagemReal, pImagemIlustrativa)
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
            AvancarFimObjetoEExtrair = _result
        End Function

        Private Sub ConsumirCharJsonObjeto(pCh As String, pQ As String, ByRef pDepth As Integer, ByRef pArrDepth As Integer, ByRef pInQuotes As Boolean, ByRef pEscape As Boolean, ByRef pEsperandoChave As Boolean, ByRef pLendoChave As Boolean, ByRef pDepoisDeChave As Boolean, ByRef pLendoValor As Boolean, ByRef pValorString As Boolean, ByRef pChave As String, ByRef pValor As String, ByRef pChaveDepth As Integer, pCadastro As RedeAncoraProdutoModel, ByRef pImagemReal As String, ByRef pImagemIlustrativa As String)
            Dim _ehBranco As Boolean = False

            If pEscape Then
                If pLendoChave Then
                    If Len(pChave) < 40 Then
                        pChave = pChave & pCh
                    End If
                Else
                    If pLendoValor Then
                        If pValorString Then
                            If Len(pValor) < 500 Then
                                pValor = pValor & pCh
                            End If
                        End If
                    End If
                End If
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
                                        If pChaveDepth = 1 Then
                                            me.AplicarCampoRaizProduto(pCadastro, pChave, pValor, pImagemReal, pImagemIlustrativa)
                                        End If
                                    End If
                                End If
                            End If
                        Else
                            If pLendoChave Then
                                If Len(pChave) < 40 Then
                                    pChave = pChave & pCh
                                End If
                            Else
                                If pLendoValor Then
                                    If pValorString Then
                                        If Len(pValor) < 500 Then
                                            pValor = pValor & pCh
                                        End If
                                    End If
                                End If
                            End If
                        End If
                    End If
                Else
                    _ehBranco = me.EhBrancoJsonChar(pCh)
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
                            pDepth = pDepth + 1
                            pEsperandoChave = True
                            If pLendoValor Then
                                pLendoValor = False
                            End If
                        Else
                            If pCh = "}" Then
                                If pLendoValor Then
                                    If pChaveDepth = 1 Then
                                        me.AplicarCampoRaizProduto(pCadastro, pChave, pValor, pImagemReal, pImagemIlustrativa)
                                    End If
                                    pLendoValor = False
                                End If
                                pDepth = pDepth - 1
                                pEsperandoChave = False
                            Else
                                If pCh = "[" Then
                                    If pLendoValor Then
                                        pLendoValor = False
                                    End If
                                    pArrDepth = pArrDepth + 1
                                Else
                                    If pCh = "]" Then
                                        If pArrDepth > 0 Then
                                            pArrDepth = pArrDepth - 1
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
                                                    If pChaveDepth = 1 Then
                                                        me.AplicarCampoRaizProduto(pCadastro, pChave, pValor, pImagemReal, pImagemIlustrativa)
                                                    End If
                                                    pLendoValor = False
                                                End If
                                                If pArrDepth = 0 Then
                                                    pEsperandoChave = True
                                                Else
                                                    pEsperandoChave = False
                                                End If
                                            Else
                                                If Not _ehBranco Then
                                                    If pLendoValor Then
                                                        If Not pValorString Then
                                                            If Len(pValor) < 40 Then
                                                                pValor = pValor & pCh
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
        End Sub

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

        Private Sub AplicarCampoRaizProduto(pCadastro As RedeAncoraProdutoModel, pChave As String, pValor As String, ByRef pImagemReal As String, ByRef pImagemIlustrativa As String)
            Dim _tok As String = ""

            If Assigned(pCadastro) Then
                _tok = pValor.Trim()
                If _tok <> "null" Then
                    If pChave = "cna" Then
                        If pCadastro.Cna <= 0 Then
                            pCadastro.Cna = Parser.StringToInteger(_tok)
                        End If
                    Else
                        If pChave = "catalogo_id" Then
                            If pCadastro.CatalogoId <= 0 Then
                                pCadastro.CatalogoId = Parser.StringToInteger(_tok)
                            End If
                        Else
                            If pChave = "csa" Then
                                If pCadastro.Csa.Trim() = "" Then
                                    pCadastro.Csa = _tok
                                End If
                            Else
                                If pChave = "cnl" Then
                                    If pCadastro.Cnl.Trim() = "" Then
                                        pCadastro.Cnl = _tok
                                    End If
                                Else
                                    me.AplicarCampoRaizProdutoRestante(pCadastro, pChave, _tok, pImagemReal, pImagemIlustrativa)
                                End If
                            End If
                        End If
                    End If
                End If
            End If
        End Sub

        Private Function TextoSeVazio(pAtual As String, pValor As String) As String
            Dim _result As String = pAtual

            If pAtual.Trim() = "" Then
                _result = pValor
            End If
            TextoSeVazio = _result
        End Function

        Private Sub AplicarCampoRaizProdutoRestante(pCadastro As RedeAncoraProdutoModel, pChave As String, pValor As String, ByRef pImagemReal As String, ByRef pImagemIlustrativa As String)
            If pChave = "codigoReferencia" Then
                pCadastro.CodigoReferencia = me.TextoSeVazio(pCadastro.CodigoReferencia, pValor)
            End If
            If pChave = "code" Then
                pCadastro.CodigoReferencia = me.TextoSeVazio(pCadastro.CodigoReferencia, pValor)
            End If
            If pChave = "code_edi" Then
                pCadastro.CodeEdi = me.TextoSeVazio(pCadastro.CodeEdi, pValor)
            End If
            If pChave = "code_manufacturer" Then
                pCadastro.CodeManufacturer = me.TextoSeVazio(pCadastro.CodeManufacturer, pValor)
            End If
            If pChave = "nomeProduto" Then
                pCadastro.NomeProduto = me.TextoSeVazio(pCadastro.NomeProduto, pValor)
            End If
            If pChave = "description" Then
                pCadastro.NomeProduto = me.TextoSeVazio(pCadastro.NomeProduto, pValor)
            End If
            If pChave = "nome" Then
                pCadastro.NomeErp = me.TextoSeVazio(pCadastro.NomeErp, pValor)
            End If
            If pChave = "name" Then
                pCadastro.NomeErp = me.TextoSeVazio(pCadastro.NomeErp, pValor)
            End If
            If pChave = "informacoesAdicionais" Then
                pCadastro.InformacoesAdicionais = me.TextoSeVazio(pCadastro.InformacoesAdicionais, pValor)
            End If
            If pChave = "informacoesComplementares" Then
                pCadastro.InformacoesComplementares = me.TextoSeVazio(pCadastro.InformacoesComplementares, pValor)
            End If
            If pChave = "additional_description" Then
                pCadastro.AdditionalDescription = me.TextoSeVazio(pCadastro.AdditionalDescription, pValor)
            End If
            If pChave = "pontoCriticoAtencao" Then
                pCadastro.PontoCriticoAtencao = me.TextoSeVazio(pCadastro.PontoCriticoAtencao, pValor)
            End If
            If pChave = "dimensoes" Then
                pCadastro.Dimensoes = me.TextoSeVazio(pCadastro.Dimensoes, pValor)
            End If
            If pChave = "marcaId" Then
                If pCadastro.CodMarca <= 0 Then
                    pCadastro.CodMarca = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "brand_id" Then
                If pCadastro.CodMarcaErp <= 0 Then
                    pCadastro.CodMarcaErp = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "marca" Then
                pCadastro.NomeMarca = me.TextoSeVazio(pCadastro.NomeMarca, pValor)
            End If
            If pChave = "brand" Then
                pCadastro.NomeMarca = me.TextoSeVazio(pCadastro.NomeMarca, pValor)
            End If
            If pChave = "line" Then
                If pCadastro.CodLinha <= 0 Then
                    pCadastro.CodLinha = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "line_id" Then
                If pCadastro.CodLinha <= 0 Then
                    pCadastro.CodLinha = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "line_name" Then
                pCadastro.NomeLinha = me.TextoSeVazio(pCadastro.NomeLinha, pValor)
            End If
            If pChave = "family" Then
                If pCadastro.CodFamilia <= 0 Then
                    pCadastro.CodFamilia = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "family_id" Then
                If pCadastro.CodFamilia <= 0 Then
                    pCadastro.CodFamilia = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "family_name" Then
                pCadastro.NomeFamilia = me.TextoSeVazio(pCadastro.NomeFamilia, pValor)
            End If
            If pChave = "manufacturer_id" Then
                If pCadastro.CodFabricante <= 0 Then
                    pCadastro.CodFabricante = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "fabricante" Then
                If pCadastro.CodFabricante <= 0 Then
                    pCadastro.CodFabricante = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "ean" Then
                pCadastro.Ean = me.TextoSeVazio(pCadastro.Ean, pValor)
            End If
            If pChave = "gtin" Then
                pCadastro.Gtin = me.TextoSeVazio(pCadastro.Gtin, pValor)
            End If
            If pChave = "ncm" Then
                pCadastro.Ncm = me.TextoSeVazio(pCadastro.Ncm, pValor)
            End If
            If pChave = "cest" Then
                pCadastro.Cest = me.TextoSeVazio(pCadastro.Cest, pValor)
            End If
            If pChave = "origem" Then
                pCadastro.Origem = me.TextoSeVazio(pCadastro.Origem, pValor)
            End If
            If pChave = "origem_label" Then
                pCadastro.OrigemLabel = me.TextoSeVazio(pCadastro.OrigemLabel, pValor)
            End If
            If pChave = "anp" Then
                If pCadastro.Anp <= 0 Then
                    pCadastro.Anp = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "anp_label" Then
                pCadastro.AnpLabel = me.TextoSeVazio(pCadastro.AnpLabel, pValor)
            End If
            If pChave = "peso_liquido" Then
                If pCadastro.PesoLiquido = 0 Then
                    pCadastro.PesoLiquido = Parser.StringToDouble(pValor)
                End If
            End If
            If pChave = "net_weight" Then
                If pCadastro.PesoLiquido = 0 Then
                    pCadastro.PesoLiquido = Parser.StringToDouble(pValor)
                End If
            End If
            If pChave = "peso_bruto" Then
                If pCadastro.PesoBruto = 0 Then
                    pCadastro.PesoBruto = Parser.StringToDouble(pValor)
                End If
            End If
            If pChave = "gross_weight" Then
                If pCadastro.PesoBruto = 0 Then
                    pCadastro.PesoBruto = Parser.StringToDouble(pValor)
                End If
            End If
            If pChave = "volume" Then
                If pCadastro.Volume = 0 Then
                    pCadastro.Volume = Parser.StringToDouble(pValor)
                End If
            End If
            If pChave = "liters" Then
                If pCadastro.Litros = 0 Then
                    pCadastro.Litros = Parser.StringToDouble(pValor)
                End If
            End If
            If pChave = "tamanho" Then
                pCadastro.Tamanho = me.TextoSeVazio(pCadastro.Tamanho, pValor)
            End If
            If pChave = "material" Then
                pCadastro.Material = me.TextoSeVazio(pCadastro.Material, pValor)
            End If
            If pChave = "tipo" Then
                If pCadastro.Tipo <= 0 Then
                    pCadastro.Tipo = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "medida_venda" Then
                pCadastro.MedidaVenda = me.TextoSeVazio(pCadastro.MedidaVenda, pValor)
            End If
            If pChave = "garantia_dias" Then
                If pCadastro.GarantiaDias <= 0 Then
                    pCadastro.GarantiaDias = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "warranty" Then
                If pCadastro.GarantiaDias <= 0 Then
                    pCadastro.GarantiaDias = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "fracao_fabrica" Then
                If pCadastro.FracaoFabrica <= 0 Then
                    pCadastro.FracaoFabrica = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "fracao_loja" Then
                If pCadastro.FracaoLoja <= 0 Then
                    pCadastro.FracaoLoja = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "status" Then
                If pCadastro.Status <= 0 Then
                    pCadastro.Status = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "erp_handle" Then
                If pCadastro.ErpHandle <= 0 Then
                    pCadastro.ErpHandle = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "handle" Then
                If pCadastro.ErpHandle <= 0 Then
                    pCadastro.ErpHandle = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "leadtime" Then
                If pCadastro.Leadtime <= 0 Then
                    pCadastro.Leadtime = Parser.StringToInteger(pValor)
                End If
            End If
            If pChave = "on_demand_label" Then
                pCadastro.OnDemandLabel = me.TextoSeVazio(pCadastro.OnDemandLabel, pValor)
            End If
            If pChave = "motivo_descontinuado" Then
                pCadastro.MotivoDescontinuado = me.TextoSeVazio(pCadastro.MotivoDescontinuado, pValor)
            End If
            If pChave = "ativo" Then
                pCadastro.Ativo = me.TextoSeVazio(pCadastro.Ativo, me.FlagDeLiteralJson(pValor))
            End If
            If pChave = "descontinuado" Then
                pCadastro.Descontinuado = me.TextoSeVazio(pCadastro.Descontinuado, me.FlagDeLiteralJson(pValor))
            End If
            If pChave = "bloqueado" Then
                pCadastro.Bloqueado = me.TextoSeVazio(pCadastro.Bloqueado, me.FlagDeLiteralJson(pValor))
            End If
            If pChave = "confiavel" Then
                pCadastro.Confiavel = me.TextoSeVazio(pCadastro.Confiavel, me.FlagDeLiteralJson(pValor))
            End If
            If pChave = "sugerido" Then
                pCadastro.Sugerido = me.TextoSeVazio(pCadastro.Sugerido, me.FlagDeLiteralJson(pValor))
            End If
            If pChave = "lancamento" Then
                pCadastro.Lancamento = me.TextoSeVazio(pCadastro.Lancamento, me.FlagDeLiteralJson(pValor))
            End If
            If pChave = "on_demand" Then
                pCadastro.OnDemand = me.TextoSeVazio(pCadastro.OnDemand, me.FlagDeLiteralJson(pValor))
            End If
            If pChave = "parcialmente_similar" Then
                pCadastro.ParcialmenteSimilar = me.TextoSeVazio(pCadastro.ParcialmenteSimilar, me.FlagDeLiteralJson(pValor))
            End If
            If pChave = "has_restrictions" Then
                pCadastro.HasRestrictions = me.TextoSeVazio(pCadastro.HasRestrictions, me.FlagDeLiteralJson(pValor))
            End If
            If pChave = "prazo_especial" Then
                pCadastro.PrazoEspecial = me.TextoSeVazio(pCadastro.PrazoEspecial, me.FlagDeLiteralJson(pValor))
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
        End Sub

        Private Function FlagDeLiteralJson(pValor As String) As String
            Dim _tok As String = LCase(pValor.Trim())
            Dim _result As String = ""

            If _tok = "true" Then
                _result = "S"
            Else
                If _tok = "false" Then
                    _result = "N"
                Else
                    If _tok = "1" Then
                        _result = "S"
                    Else
                        If _tok = "0" Then
                            _result = "N"
                        End If
                    End If
                End If
            End If
            FlagDeLiteralJson = _result
        End Function

        ' So fecha o objeto raiz (depth). Sem extracao e sem Exit Function.
        Private Function AvancarFimObjeto(pBody As String, pStart As Integer) As Integer
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
            AvancarFimObjeto = _result
        End Function

        Private Function ObterLastPageDoSufixo(pBody As String) As Integer
            Dim _bodyLen As Integer = 0
            Dim _janelaMax As Integer = 200
            Dim _janela As String = ""
            Dim _pos As Integer = 0
            Dim _n As Integer = 0
            Dim _passos As Integer = 0

            ObterLastPageDoSufixo = 0
            _bodyLen = Len(pBody)
            If _bodyLen <= 0 Then
                Exit Function
            End If

            If _bodyLen <= _janelaMax Then
                ObterLastPageDoSufixo = me.ExtrairInteiroDoPrefixoAscii(me.CopiarJanelaAscii(pBody, 1, _bodyLen), "last_page")
                Exit Function
            End If

            _pos = _bodyLen - _janelaMax + 1
            While _pos >= 1
                If _passos > 20 Then
                    Exit Function
                End If
                _passos = _passos + 1

                _janela = me.CopiarJanelaAscii(pBody, _pos, 200)
                If _janela = "" Then
                    Exit Function
                End If
                _n = me.ExtrairInteiroDoPrefixoAscii(_janela, "last_page")
                If _n > 0 Then
                    ObterLastPageDoSufixo = _n
                    Exit Function
                End If

                If _pos <= 1 Then
                    Exit Function
                End If
                _pos = _pos - (_janelaMax - 20)
                If _pos < 1 Then
                    _pos = 1
                End If
            Wend
        End Function

        Private Function PosicaoArrayDataAscii(pBody As String) As Integer
            Dim _bodyLen As Integer = 0
            Dim _prefixLen As Integer = 64
            Dim _prefix As String = ""

            PosicaoArrayDataAscii = 0
            _bodyLen = Len(pBody)

            If _bodyLen <= 0 Then
                Exit Function
            End If

            If _prefixLen > _bodyLen Then
                _prefixLen = _bodyLen
            End If

            _prefix = me.CopiarJanelaAscii(pBody, 1, _prefixLen)
            PosicaoArrayDataAscii = me.PosicaoArrayDataNoPrefixo(_prefix)
        End Function

        ' InStr de "cna": em janelas de 200 com overlap 12. Sem Mid longo no body.
        ' Sem Exit Function/Exit While.
        Private Function ExtrairCnaDoObjeto(pBody As String, pObjStart As Integer, pObjFim As Integer) As Integer
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _limite As Integer = 0
            Dim _janela As String = ""
            Dim _needle As String = ""
            Dim _idx As Integer = 0
            Dim _abs As Integer = 0
            Dim _fatia As String = ""
            Dim _fatiaLen As Integer = 0
            Dim _i As Integer = 0
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _digits As String = "0123456789"
            Dim _d As Integer = 0
            Dim _n As Integer = 0
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _seguirSkip As Boolean = False
            Dim _seguirDig As Boolean = False
            Dim _temDigito As Boolean = False
            Dim _result As Integer = 0

            _needle = _q & "cna" & _q & ":"
            _bodyLen = Len(pBody)

            If pObjStart >= 1 Then
                If pObjStart <= _bodyLen Then
                    _pos = pObjStart
                    _limite = pObjFim
                    If _limite <= 0 Then
                        _limite = _bodyLen
                    End If
                    If _limite > _bodyLen Then
                        _limite = _bodyLen
                    End If

                    While _pos <= _limite
                        If _achou Then
                            _pos = _limite + 1
                        Else
                            _janela = me.CopiarJanelaAscii(pBody, _pos, 200)
                            If _janela = "" Then
                                _pos = _limite + 1
                            Else
                                _idx = InStr(_janela, _needle)
                                If _idx > 0 Then
                                    _abs = _pos + _idx + Len(_needle) - 1
                                    _fatia = me.CopiarJanelaAscii(pBody, _abs, 40)
                                    _fatiaLen = Len(_fatia)
                                    _i = 1
                                    _seguirSkip = True
                                    While _seguirSkip
                                        If _i > _fatiaLen Then
                                            _seguirSkip = False
                                        Else
                                            If me.EhBrancoJsonChar(Mid(_fatia, _i, 1)) Then
                                                _i = _i + 1
                                            Else
                                                _seguirSkip = False
                                            End If
                                        End If
                                    Wend

                                    If _i <= _fatiaLen Then
                                        If Mid(_fatia, _i, 1) = _q Then
                                            _i = _i + 1
                                        End If
                                    End If

                                    _n = 0
                                    _temDigito = False
                                    _seguirDig = True
                                    While _seguirDig
                                        If _i > _fatiaLen Then
                                            _seguirDig = False
                                        Else
                                            _ch = Mid(_fatia, _i, 1)
                                            _d = -1
                                            For _j = 1 To 10
                                                If Mid(_digits, _j, 1) = _ch Then
                                                    _d = _j - 1
                                                End If
                                            Next
                                            If _d < 0 Then
                                                _seguirDig = False
                                            Else
                                                _n = (_n * 10) + _d
                                                _temDigito = True
                                                _i = _i + 1
                                            End If
                                        End If
                                    Wend

                                    If _temDigito Then
                                        If _n > 0 Then
                                            _result = _n
                                            _achou = True
                                        End If
                                    End If
                                End If

                                If Not _achou Then
                                    If Len(_janela) < 12 Then
                                        _pos = _limite + 1
                                    Else
                                        _pos = _pos + 188
                                    End If
                                End If
                            End If
                        End If
                    Wend
                End If
            End If

            ExtrairCnaDoObjeto = _result
        End Function

        ' Mid no blob so em fatia <= 200 (padrao que sobreviveu em marcas 370KB).
        ' Sem Exit Function: PaxExitException vaza para Catch do caller.
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

        ' Encontra `},{` (proximo item) ou `}]` (fim) em janelas de 200; overlap 2.
        Private Function PularAteProximoObjeto(pBody As String, pFrom As Integer) As Integer
            Dim _bodyLen As Integer = 0
            Dim _i As Integer = pFrom
            Dim _janela As String = ""
            Dim _janelaLen As Integer = 0
            Dim _j As Integer = 0

            PularAteProximoObjeto = 0

            If pFrom < 1 Then
                Exit Function
            End If

            _bodyLen = Len(pBody)

            While _i <= _bodyLen
                _janela = me.CopiarJanelaAscii(pBody, _i, 200)
                _janelaLen = Len(_janela)
                If _janelaLen < 2 Then
                    Exit Function
                End If

                _j = 1
                While _j <= (_janelaLen - 2)
                    If Mid(_janela, _j, 3) = "},{" Then
                        PularAteProximoObjeto = _i + _j + 1
                        Exit Function
                    End If
                    If Mid(_janela, _j, 2) = "}]" Then
                        Exit Function
                    End If
                    _j = _j + 1
                Wend

                If Mid(_janela, _janelaLen - 1, 2) = "}]" Then
                    Exit Function
                End If

                If _janelaLen <= 2 Then
                    Exit Function
                End If
                _i = _i + _janelaLen - 2
            Wend
        End Function

        Private Function PosicaoArrayDataNoPrefixo(pPrefixo As String) As Integer
            Dim _len As Integer = Len(pPrefixo)
            Dim _i As Integer = 1
            Dim _ch As String = ""
            Dim _posValor As Integer = 0

            PosicaoArrayDataNoPrefixo = 0

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i <= _len Then
                If Mid(pPrefixo, _i, 1) = "[" Then
                    PosicaoArrayDataNoPrefixo = _i
                    Exit Function
                End If
            End If

            _posValor = me.PosicaoValorChaveAscii(pPrefixo, "data")
            If _posValor <= 0 Then
                Exit Function
            End If

            If Mid(pPrefixo, _posValor, 1) = "[" Then
                PosicaoArrayDataNoPrefixo = _posValor
            End If
        End Function

        Private Function PosicaoValorChaveAscii(pPrefixo As String, pChave As String) As Integer
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False

            PosicaoValorChaveAscii = 0

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pPrefixo, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pPrefixo, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pPrefixo, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pPrefixo, _i + _keyLen + 2, 1) = ":" Then
                                _achou = True
                                _i = _i + _keyLen + 3
                                Exit While
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            PosicaoValorChaveAscii = _i
        End Function

        ' -1 = fim do array (]), 0 = sem `{`, >0 = posicao do `{` na janela.
        ' Sem Exit Function/Exit While (PaxExitException no Try do caller).
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
                            _idx = _i
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
                    End If
                End If
            End If
            PosicaoAbreObjetoNaJanela = _result
        End Function

        Private Function ExtrairInteiroDoPrefixoAscii(pPrefixo As String, pChave As String) As Integer
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _digits As String = "0123456789"

            ExtrairInteiroDoPrefixoAscii = 0

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pPrefixo, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pPrefixo, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pPrefixo, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pPrefixo, _i + _keyLen + 2, 1) = ":" Then
                                _achou = True
                                _i = _i + _keyLen + 3
                                Exit While
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            If Mid(pPrefixo, _i, 1) = _q Then
                _i = _i + 1
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                _d = -1
                For _j = 1 To 10
                    If Mid(_digits, _j, 1) = _ch Then
                        _d = _j - 1
                        Exit For
                    End If
                Next
                If _d < 0 Then
                    Exit While
                End If
                _n = (_n * 10) + _d
                _i = _i + 1
            Wend

            ExtrairInteiroDoPrefixoAscii = _n
        End Function

        Private Function PosicaoValorAposChaveAscii(pPrefixo As String, pChave As String) As Integer
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _q As String = Chr(34)
            Dim _igual As Boolean = False
            Dim _ch As String = ""

            PosicaoValorAposChaveAscii = 0

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pPrefixo, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pPrefixo, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pPrefixo, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pPrefixo, _i + _keyLen + 2, 1) = ":" Then
                                _i = _i + _keyLen + 3
                                While _i <= _len
                                    _ch = Mid(pPrefixo, _i, 1)
                                    If _ch = " " Then
                                        _i = _i + 1
                                    Else
                                        PosicaoValorAposChaveAscii = _i
                                        Exit Function
                                    End If
                                Wend
                                Exit Function
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend
        End Function

        Private Function ExtrairLiteralJsonDoPrefixoAscii(pPrefixo As String, pChave As String) As String
            Dim _i As Integer = 0
            Dim _len As Integer = Len(pPrefixo)
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _result As String = ""

            ExtrairLiteralJsonDoPrefixoAscii = ""
            _i = me.PosicaoValorAposChaveAscii(pPrefixo, pChave)

            If _i <= 0 Then
                Exit Function
            End If

            _ch = Mid(pPrefixo, _i, 1)
            If _ch = _q Then
                Exit Function
            End If

            If Mid(pPrefixo, _i, 4) = "null" Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = "," Then
                    Exit While
                End If
                If _ch = "}" Then
                    Exit While
                End If
                If _ch = "]" Then
                    Exit While
                End If
                If _ch = " " Then
                    Exit While
                End If
                _result = _result & _ch
                _i = _i + 1
            Wend

            ExtrairLiteralJsonDoPrefixoAscii = _result
        End Function

        Private Function ExtrairBooleanTriDoPrefixoAscii(pPrefixo As String, pChave As String) As Integer
            Dim _tok As String = ""

            ExtrairBooleanTriDoPrefixoAscii = -1
            _tok = LCase(me.ExtrairLiteralJsonDoPrefixoAscii(pPrefixo, pChave))

            If _tok = "true" Then
                ExtrairBooleanTriDoPrefixoAscii = 1
            Else
                If _tok = "false" Then
                    ExtrairBooleanTriDoPrefixoAscii = 0
                End If
            End If
        End Function

        Private Function ExtrairTextoJsonDoPrefixoAscii(pPrefixo As String, pChave As String) As String
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False
            Dim _escape As Boolean = False
            Dim _result As String = ""
            Dim _maxValor As Integer = 80
            Dim _nValor As Integer = 0

            ExtrairTextoJsonDoPrefixoAscii = ""

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pPrefixo, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pPrefixo, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pPrefixo, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pPrefixo, _i + _keyLen + 2, 1) = ":" Then
                                _achou = True
                                _i = _i + _keyLen + 3
                                Exit While
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            If Mid(pPrefixo, _i, 1) <> _q Then
                Exit Function
            End If

            _i = _i + 1

            While _i <= _len
                If _nValor >= _maxValor Then
                    Exit While
                End If

                _ch = Mid(pPrefixo, _i, 1)

                If _escape Then
                    _result = _result & _ch
                    _nValor = _nValor + 1
                    _escape = False
                Else
                    If _ch = "\" Then
                        _result = _result & _ch
                        _nValor = _nValor + 1
                        _escape = True
                    Else
                        If _ch = _q Then
                            Exit While
                        End If
                        _result = _result & _ch
                        _nValor = _nValor + 1
                    End If
                End If

                _i = _i + 1
            Wend

            ExtrairTextoJsonDoPrefixoAscii = _result
        End Function

        Private Function ExtrairTextoJsonDoPrefixoAsciiComTeto(pPrefixo As String, pChave As String, pMaxValor As Integer) As String
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False
            Dim _escape As Boolean = False
            Dim _result As String = ""
            Dim _maxValor As Integer = pMaxValor
            Dim _nValor As Integer = 0

            ExtrairTextoJsonDoPrefixoAsciiComTeto = ""

            If _maxValor <= 0 Then
                _maxValor = 80
            End If

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pPrefixo, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pPrefixo, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pPrefixo, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pPrefixo, _i + _keyLen + 2, 1) = ":" Then
                                _achou = True
                                _i = _i + _keyLen + 3
                                Exit While
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            If Mid(pPrefixo, _i, 1) <> _q Then
                Exit Function
            End If

            _i = _i + 1

            While _i <= _len
                If _nValor >= _maxValor Then
                    Exit While
                End If

                _ch = Mid(pPrefixo, _i, 1)

                If _escape Then
                    _result = _result & _ch
                    _nValor = _nValor + 1
                    _escape = False
                Else
                    If _ch = "\" Then
                        _result = _result & _ch
                        _nValor = _nValor + 1
                        _escape = True
                    Else
                        If _ch = _q Then
                            Exit While
                        End If
                        _result = _result & _ch
                        _nValor = _nValor + 1
                    End If
                End If

                _i = _i + 1
            Wend

            ExtrairTextoJsonDoPrefixoAsciiComTeto = _result
        End Function

        Private Function ExtrairBlobArrayJsonDoPrefixoAscii(pPrefixo As String, pChave As String) As String
            Dim _posValor As Integer = 0
            Dim _len As Integer = Len(pPrefixo)
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escape As Boolean = False
            Dim _inicio As Integer = 0

            ExtrairBlobArrayJsonDoPrefixoAscii = ""

            If _len <= 0 Then
                Exit Function
            End If

            _posValor = me.PosicaoValorChaveAscii(pPrefixo, pChave)
            If _posValor <= 0 Then
                Exit Function
            End If

            If _posValor > _len Then
                Exit Function
            End If

            If Mid(pPrefixo, _posValor, 1) <> "[" Then
                Exit Function
            End If

            _inicio = _posValor
            _i = _posValor

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)

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
                                        ExtrairBlobArrayJsonDoPrefixoAscii = Mid(pPrefixo, _inicio, _i - _inicio + 1)
                                        Exit Function
                                    End If
                                End If
                            End If
                        End If
                    End If
                End If

                _i = _i + 1
            Wend
        End Function

        ' Bulk-search ainda usa TJSONArray. Catalogo completo nao chama este metodo.
        Private Sub PersistirItensProdutoApi(pData As TJSONArray, pSomenteNovos As Boolean, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel, pUsarTransacaoInterna As Boolean, pCnasEncontrados As RedeAncoraProdutoCnasModel)
            Dim _tx As Transaction = NULL
            Dim _i As Integer
            Dim _itemJson As TJSONObject = NULL
            Dim _cna As Integer
            Dim _upsert As Integer

            If Not Assigned(pData) Then
                Exit Sub
            End If

            Try
                If pUsarTransacaoInterna Then
                    _tx = Transaction.Instance()
                    _tx.OffAutoCommit()
                    _tx.StartTransaction("Integracao.RedeAncoraProdutoVinculo Sync itens")
                End If

                For _i = 0 To pData.Length() - 1
                    _itemJson = pData.GetJSONObject(_i)
                    _cna = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(_itemJson, "cna")

                    If pSomenteNovos And _cna > 0 And me.CnaJaCadastrado(_cna) Then
                        pResultado.QtdIgnorados = pResultado.QtdIgnorados + 1
                    Else
                        _upsert = me._produtoService.UpsertProdutoAncoraDeApiComTransacao(_itemJson, RedeAncoraProdutoVinculoOrigem.Sincronizacao(), False)
                        me.RegistrarResultadoUpsert(_upsert, pResultado)

                        If _upsert = 1 And _cna > 0 Then
                            If Assigned(me._cnasExistentes) Then
                                me._cnasExistentes.PushDistinct(_cna)
                            End If
                        End If

                        If _cna > 0 Then
                            me._produtoService.PersistirImagensProdutoDeApiSemTransacao(_itemJson, _cna)
                        End If
                    End If

                    If Assigned(pCnasEncontrados) Then
                        me.RegistrarCnaEncontrado(_itemJson, pCnasEncontrados)
                    End If

                    _itemJson.Free()
                    _itemJson = NULL
                Next

                If pUsarTransacaoInterna Then
                    _tx.OnAutoCommit()
                    _tx.Commit()
                End If
            Catch ex As Exception
                If Assigned(_itemJson) Then
                    _itemJson.Free()
                End If

                If pUsarTransacaoInterna Then
                    If Assigned(_tx) Then
                        _tx.Rollback()
                        _tx.OnAutoCommit()
                    End If
                End If

                Throw ex
            End Try
        End Sub

        Private Sub RegistrarResultadoUpsert(pUpsert As Integer, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel)
            If pUpsert = 1 Then
                pResultado.QtdInseridos = pResultado.QtdInseridos + 1
            ElseIf pUpsert = 2 Then
                pResultado.QtdAtualizados = pResultado.QtdAtualizados + 1
            ElseIf pUpsert = 3 Then
                pResultado.QtdSemAlteracao = pResultado.QtdSemAlteracao + 1
            End If
        End Sub

        Private Sub LogProgressoChunk(pNumeroChunk As Integer, pTotalChunks As Integer, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel)
            Dim _msg As String = "Rede Ancora sync chunk " + pNumeroChunk.ToString() + "/" + pTotalChunks.ToString()
            _msg = _msg + " - inseridos: " + pResultado.QtdInseridos.ToString()
            _msg = _msg + ", atualizados: " + pResultado.QtdAtualizados.ToString()
            _msg = _msg + ", sem alteracao: " + pResultado.QtdSemAlteracao.ToString()
            mod_logger.Printe(_msg)
        End Sub

        Private Function PrepararChunkParaApi(pChunk As RedeAncoraProdutoCnasModel, pSomenteNovos As Boolean, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel) As RedeAncoraProdutoCnasModel
            Dim _chunkApi As RedeAncoraProdutoCnasModel = NULL

            If Not pSomenteNovos Then
                PrepararChunkParaApi = me.ClonarCnas(pChunk)
                Exit Function
            End If

            _chunkApi = me.FiltrarCnasSomenteNovos(pChunk)
            pResultado.QtdIgnorados = pResultado.QtdIgnorados + (pChunk.Length - _chunkApi.Length)
            PrepararChunkParaApi = _chunkApi
        End Function

        Private Function ClonarCnas(pCnas As RedeAncoraProdutoCnasModel) As RedeAncoraProdutoCnasModel
            Dim _clone As New RedeAncoraProdutoCnasModel()
            Dim _i As Integer

            For _i = 0 To pCnas.Length - 1
                _clone.Push(pCnas.Take(_i))
            Next

            ClonarCnas = _clone
        End Function

        Private Function FiltrarCnasSomenteNovos(pCnas As RedeAncoraProdutoCnasModel) As RedeAncoraProdutoCnasModel
            Dim _filtrados As New RedeAncoraProdutoCnasModel()
            Dim _i As Integer
            Dim _cna As Integer

            For _i = 0 To pCnas.Length - 1
                _cna = pCnas.Take(_i)

                If Not me.CnaJaCadastrado(_cna) Then
                    _filtrados.Push(_cna)
                End If
            Next

            FiltrarCnasSomenteNovos = _filtrados
        End Function

        Private Function CnaJaCadastrado(pCna As Integer) As Boolean
            If Not Assigned(me._cnasExistentes) Then
                CnaJaCadastrado = me._vinculoRepository.ExistePorCna(pCna)
                Exit Function
            End If

            CnaJaCadastrado = me._cnasExistentes.Contem(pCna)
        End Function

        Private Sub RegistrarCnaEncontrado(pItemJson As TJSONObject, pCnasEncontrados As RedeAncoraProdutoCnasModel)
            Dim _cna As Integer = RedeAncoraJsonHelper.ObterInteiroJsonOpcional(pItemJson, "cna")

            If _cna > 0 Then
                pCnasEncontrados.PushDistinct(_cna)
            End If
        End Sub

        Private Sub ProcessarCnasAusentesSomenteNovos(pChunk As RedeAncoraProdutoCnasModel, pCnasEncontrados As RedeAncoraProdutoCnasModel, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel)
            Dim _i As Integer
            Dim _cna As Integer

            For _i = 0 To pChunk.Length - 1
                _cna = pChunk.Take(_i)

                If Not pCnasEncontrados.Contem(_cna) Then
                    pResultado.QtdNaoEncontrados = pResultado.QtdNaoEncontrados + 1
                End If
            Next
        End Sub

        Private Sub ProcessarCnasAusentes(pChunk As RedeAncoraProdutoCnasModel, pCnasEncontrados As RedeAncoraProdutoCnasModel, pDesativarAusentes As Boolean, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel, pUsarTransacao As Boolean)
            Dim _i As Integer
            Dim _cna As Integer

            For _i = 0 To pChunk.Length - 1
                _cna = pChunk.Take(_i)

                If Not pCnasEncontrados.Contem(_cna) Then
                    pResultado.QtdNaoEncontrados = pResultado.QtdNaoEncontrados + 1

                    If pDesativarAusentes And me.CnaJaCadastrado(_cna) Then
                        If pUsarTransacao Then
                            me._produtoService.DesativarProdutoAncora(_cna)
                        Else
                            me._produtoService.DesativarProdutoAncoraSemTransacao(_cna)
                        End If

                        pResultado.QtdDesativados = pResultado.QtdDesativados + 1
                    End If
                End If
            Next
        End Sub

        Private Function NomeTipoExcecao(pEx As Exception) As String
            Dim _tipo As String = ""
            Dim _result As String = "?"

            If Assigned(pEx) Then
                Try
                    _tipo = pEx.ClassName()
                Catch exTipo As Exception
                    _tipo = ""
                End Try
                If _tipo <> "" Then
                    _result = _tipo
                End If
            End If
            NomeTipoExcecao = _result
        End Function

        Private Function EhExcecaoPaxExit(pTipo As String) As Boolean
            Dim _t As String = LCase(pTipo)
            Dim _result As Boolean = False

            If InStr(_t, "paxexit") > 0 Then
                _result = True
            End If
            EhExcecaoPaxExit = _result
        End Function

        Private Function MensagemExcecaoSegura(pEx As Exception) As String
            Dim _msg As String = ""
            Dim _result As String = "Invalid pointer operation"

            If Assigned(pEx) Then
                Try
                    _msg = DiagStack.FormatException(pEx)
                Catch exFmt As Exception
                    _msg = ""
                End Try
                If _msg.Trim() <> "" Then
                    _result = _msg
                End If
            End If
            MensagemExcecaoSegura = _result
        End Function

        Private Function IsErroAutenticacao(pEx As Exception) As Boolean
            Dim _mensagem As String = me.MensagemExcecaoSegura(pEx)

            IsErroAutenticacao = _mensagem.Contains("401") Or _mensagem.Contains("Chave API Rede Ancora")
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._cnasExistentes) Then
                    me._cnasExistentes.Free()
                    me._cnasExistentes = NULL
                End If

                If Assigned(me._produtoService) Then
                    me._produtoService.Free()
                    me._produtoService = NULL
                End If

                If Assigned(me._vinculoRepository) Then
                    me._vinculoRepository.Free()
                    me._vinculoRepository = NULL
                End If

                If Assigned(me._catalogoService) Then
                    me._catalogoService.Free()
                    me._catalogoService = NULL
                End If

                If Assigned(me._progressoRepository) Then
                    me._progressoRepository.Free()
                    me._progressoRepository = NULL
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
