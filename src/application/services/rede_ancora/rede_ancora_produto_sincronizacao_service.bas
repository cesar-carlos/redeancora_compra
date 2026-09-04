Imports mod_tobject
Imports mod_logger
Imports try_parser
Imports rede_ancora_produto_service
Imports rede_ancora_produto_vinculo_repository
Imports rede_ancora_produto_vinculo_origem
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_vinculos_model
Imports rede_ancora_produto_sincronizacao_resultado_model
Imports rede_ancora_produto_sincronizacao_opcoes_model
Imports rede_ancora_catalogo_service
Imports rede_ancora_familias_model
Imports rede_ancora_json_helper
Imports rede_ancora_produto_sincronizacao_modo
Imports rede_ancora_api_config
Imports transactions
Imports diag_stack

Namespace rede_ancora_produto_sincronizacao_service
    Class RedeAncoraProdutoSincronizacaoService
        Inherits TTObject

        Private _produtoService As RedeAncoraProdutoService
        Private _vinculoRepository As RedeAncoraProdutoVinculoRepository
        Private _catalogoService As RedeAncoraCatalogoService
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
        End Sub

        Function Sincronizar(pOpcoes As RedeAncoraProdutoSincronizacaoOpcoesModel) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _cnas As RedeAncoraProdutoCnasModel = NULL
            Dim _resultadoSync As RedeAncoraProdutoSincronizacaoResultadoModel = NULL

            pOpcoes.Validate()

            If pOpcoes.SincronizarCatalogo Then
                me._catalogoService.SincronizarCatalogo(pOpcoes.CodUsuario)
            End If

            Try
                If pOpcoes.BaixarCatalogoCompleto Then
                    mod_logger.Printe("Rede Ancora sync :: iniciando catalogo completo...")
                    _resultadoSync = me.ExecutarSincronizacaoCatalogoCompleto(pOpcoes)
                Else
                    _cnas = me.ResolverListaCnas(pOpcoes)
                    _resultadoSync = me.ExecutarSincronizacaoCnas(pOpcoes, _cnas)
                    _cnas.Free()
                End If

                Sincronizar = _resultadoSync
            Catch ex As Exception
                If Assigned(_cnas) Then
                    _cnas.Free()
                End If

                Throw New System.Exception("Erro na sincronizacao de produtos Rede Ancora: " + ex._getMessage())
            End Try
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

        Private Function ExecutarSincronizacaoCatalogoCompleto(pOpcoes As RedeAncoraProdutoSincronizacaoOpcoesModel) As RedeAncoraProdutoSincronizacaoResultadoModel
            Dim _resultado As New RedeAncoraProdutoSincronizacaoResultadoModel()
            Dim _familias As RedeAncoraFamiliasModel = NULL
            Dim _tamanhoPagina As Integer = me.ResolverTamanhoChunk(pOpcoes.TamanhoChunk)
            Dim _modo As String = me.ResolverModo(pOpcoes.Modo)
            Dim _i As Integer
            Dim _codFamilia As Integer
            Dim _pagina As Integer
            Dim _ultimaPagina As Integer
            Dim _qtdItens As Integer
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

                mod_logger.Printe("Rede Ancora sync catalogo completo :: familias: " & Parser.IntegerToString(_familias.Length) & " | pagina: " & Parser.IntegerToString(_tamanhoPagina))
                mod_logger.Info("sync-full: imagens omitidas neste passo (fields=details; sem TJSONObject)")

                For _i = 0 To _familias.Length - 1
                    mod_logger.Info("sync-full: Take familia i=" & Parser.IntegerToString(_i) & "/" & Parser.IntegerToString(_familias.Length))
                    _codFamilia = _familias.Take(_i).CodFamilia
                    mod_logger.Info("sync-full: familia id=" & Parser.IntegerToString(_codFamilia))
                    _pagina = 1
                    _ultimaPagina = 1

                    While _pagina <= _ultimaPagina
                        _resultado.QtdChunks = _resultado.QtdChunks + 1
                        _qtdItens = 0
                        _body = ""

                        Try
                            _body = me._produtoService.BuscarProdutoFullSearchPorFamilia(pOpcoes.CodUsuario, pOpcoes.CodCentroDistribuicao, _codFamilia, _pagina, _tamanhoPagina)
                            _resultado.QtdChunksApi = _resultado.QtdChunksApi + 1
                        Catch exPagina As Exception
                            If me.IsErroAutenticacao(exPagina) Then
                                Throw exPagina
                            End If

                            _resultado.RegistrarErroChunk(_resultado.QtdChunks, "Familia " & Parser.IntegerToString(_codFamilia) & " pagina " & Parser.IntegerToString(_pagina) & ": " & exPagina._getMessage())
                            Exit While
                        End Try

                        mod_logger.Info("sync-full: before parse familia=" & Parser.IntegerToString(_codFamilia) & " pagina=" & Parser.IntegerToString(_pagina) & " bytes=" & Parser.IntegerToString(Len(_body)))
                        DiagStack.Push("sync-full.PersistirBlob")

                        Try
                            _qtdItens = me.PersistirProdutosFullSearchDeBlob(_body, RedeAncoraProdutoSincronizacaoModo.IsSomenteNovos(_modo), _resultado, _codFamilia)
                            DiagStack.Pop()
                        Catch exPersistir As Exception
                            DiagStack.DumpOnError(exPersistir)
                            DiagStack.Pop()
                            If me.IsErroAutenticacao(exPersistir) Then
                                Throw exPersistir
                            End If

                            _resultado.RegistrarErroChunk(_resultado.QtdChunks, "Familia " & Parser.IntegerToString(_codFamilia) & " pagina " & Parser.IntegerToString(_pagina) & ": " & exPersistir._getMessage())
                        End Try

                        _ultimaPagina = me.ObterLastPageDoSufixo(_body)
                        If _ultimaPagina <= 0 Then
                            If _qtdItens < _tamanhoPagina Then
                                _ultimaPagina = _pagina
                            Else
                                _ultimaPagina = _pagina + 1
                            End If
                        End If

                        mod_logger.Info("sync-full: after parse familia=" & Parser.IntegerToString(_codFamilia) & " itens=" & Parser.IntegerToString(_qtdItens) & " last_page=" & Parser.IntegerToString(_ultimaPagina))
                        mod_logger.Printe("Rede Ancora sync familia " & Parser.IntegerToString(_codFamilia) & " pagina " & Parser.IntegerToString(_pagina) & "/" & Parser.IntegerToString(_ultimaPagina) & " | inseridos: " & Parser.IntegerToString(_resultado.QtdInseridos) & " | atualizados: " & Parser.IntegerToString(_resultado.QtdAtualizados))

                        _pagina = _pagina + 1
                        If _pagina > 10000 Then
                            Throw New System.Exception("Limite de paginas full-search excedido na familia " & Parser.IntegerToString(_codFamilia))
                        End If
                    Wend
                Next

                _resultado.Finalizar()
                me._cnasExistentes.Free()
                me._cnasExistentes = NULL
                _familias.Free()
                _familias = NULL
                _result = _resultado
                _resultado = NULL
            Catch ex As Exception
                DiagStack.DumpOnError(ex)

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

                Throw New System.Exception("Erro ao sincronizar catalogo completo Rede Ancora: " & ex._getMessage())
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
                ExecutarSincronizacaoCnas = _resultado
            Catch ex As Exception
                If Assigned(me._cnasExistentes) Then
                    me._cnasExistentes.Free()
                    me._cnasExistentes = NULL
                End If

                If Assigned(_resultado) Then
                    _resultado.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar produtos Rede Ancora: " + ex._getMessage())
            End Try
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

        ' Full-search: nunca New TJSONObject / GetJSONObject no body (pagina ~100 itens / details = centenas de KB = AV 00220000).
        ' Janela Mid 200 chars; profundidade {} para pular details aninhado; imagens nao entram em fields=details.
        Private Function PersistirProdutosFullSearchDeBlob(pBody As String, pSomenteNovos As Boolean, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel, pCodFamilia As Integer) As Integer
            Dim _tx As Transaction = NULL
            Dim _arrayStart As Integer = 0
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _janelaMax As Integer = 200
            Dim _janelaLen As Integer = 0
            Dim _janela As String = ""
            Dim _idxAbre As Integer = 0
            Dim _objStart As Integer = 0
            Dim _objFim As Integer = 0
            Dim _prefix As String = ""
            Dim _prefixLen As Integer = 0
            Dim _qtd As Integer = 0
            Dim _result As Integer = 0
            Dim _brandId As Integer = 0
            Dim _lineId As Integer = 0
            Dim _familyId As Integer = 0

            Try
                _arrayStart = me.PosicaoArrayDataAscii(pBody)
                If _arrayStart <= 0 Then
                    Throw New System.Exception("Resposta /products/full-search sem array data")
                End If
                mod_logger.Info("sync-full: array pos=" & Parser.IntegerToString(_arrayStart))

                _tx = Transaction.Instance()
                _tx.OffAutoCommit()
                _tx.StartTransaction("Integracao.RedeAncoraProdutoVinculo Sync full-search")

                _bodyLen = Len(pBody)
                _pos = _arrayStart + 1

                While _pos <= _bodyLen
                    _janelaLen = _janelaMax
                    If _janelaLen > (_bodyLen - _pos + 1) Then
                        _janelaLen = _bodyLen - _pos + 1
                    End If
                    If _janelaLen <= 0 Then
                        Exit While
                    End If

                    _janela = Mid(pBody, _pos, _janelaLen)
                    _idxAbre = me.PosicaoAbreObjetoNaJanela(_janela)

                    If _idxAbre < 0 Then
                        Exit While
                    End If

                    If _idxAbre = 0 Then
                        _pos = _pos + _janelaLen
                    Else
                        _objStart = _pos + _idxAbre - 1
                        _prefixLen = _janelaLen - _idxAbre + 1
                        _prefix = Mid(_janela, _idxAbre, _prefixLen)
                        _brandId = 0
                        _lineId = 0
                        _familyId = 0
                        _objFim = me.AvancarFimObjetoEExtrair(pBody, _objStart, _brandId, _lineId, _familyId)
                        me.PersistirProdutoDoPrefixo(_prefix, _brandId, _lineId, _familyId, pCodFamilia, pSomenteNovos, pResultado)
                        _qtd = _qtd + 1

                        If _qtd = 1 Then
                            mod_logger.Info("sync-full: primeiro item ok")
                        End If

                        If _objFim <= 0 Then
                            Exit While
                        End If
                        _pos = _objFim + 1
                    End If
                Wend

                _tx.OnAutoCommit()
                _tx.Commit()
                _tx = NULL
                _result = _qtd
            Catch ex As Exception
                If Assigned(_tx) Then
                    _tx.Rollback()
                    _tx.OnAutoCommit()
                End If

                Throw ex
            End Try

            PersistirProdutosFullSearchDeBlob = _result
        End Function

        Private Sub PersistirProdutoDoPrefixo(pPrefixo As String, pBrandId As Integer, pLineId As Integer, pFamilyId As Integer, pCodFamilia As Integer, pSomenteNovos As Boolean, pResultado As RedeAncoraProdutoSincronizacaoResultadoModel)
            Dim _cna As Integer = 0
            Dim _codigo As String = ""
            Dim _descricao As String = ""
            Dim _codMarca As Integer = 0
            Dim _codLinha As Integer = 0
            Dim _codFamilia As Integer = 0
            Dim _upsert As Integer = 0

            _cna = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "cna")
            If _cna <= 0 Then
                Exit Sub
            End If

            If pSomenteNovos Then
                If me.CnaJaCadastrado(_cna) Then
                    pResultado.QtdIgnorados = pResultado.QtdIgnorados + 1
                    Exit Sub
                End If
            End If

            _codigo = me.ExtrairTextoJsonDoPrefixoAscii(pPrefixo, "codigoReferencia")
            If _codigo.Trim() = "" Then
                _codigo = me.ExtrairTextoJsonDoPrefixoAscii(pPrefixo, "code")
            End If

            _descricao = me.ExtrairTextoJsonDoPrefixoAscii(pPrefixo, "nomeProduto")
            If _descricao.Trim() = "" Then
                _descricao = me.ExtrairTextoJsonDoPrefixoAscii(pPrefixo, "description")
            End If

            _codMarca = pBrandId
            If _codMarca <= 0 Then
                _codMarca = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "marcaId")
            End If
            If _codMarca <= 0 Then
                _codMarca = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "brand_id")
            End If

            _codLinha = pLineId
            If _codLinha <= 0 Then
                _codLinha = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "line_id")
            End If

            _codFamilia = pFamilyId
            If _codFamilia <= 0 Then
                _codFamilia = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "family_id")
            End If
            If _codFamilia <= 0 Then
                _codFamilia = pCodFamilia
            End If

            _upsert = me._produtoService.UpsertProdutoAncoraDeCampos(_cna, _codigo, _descricao, _codMarca, _codLinha, _codFamilia, RedeAncoraProdutoVinculoOrigem.Sincronizacao(), False)
            me.RegistrarResultadoUpsert(_upsert, pResultado)

            If _upsert = 1 Then
                If Assigned(me._cnasExistentes) Then
                    me._cnasExistentes.PushDistinct(_cna)
                End If
            End If
        End Sub

        ' Caminha o objeto com janelas de 200 (nunca Mid 1-char no blob). Extrai brand_id/line/family de details.
        Private Function AvancarFimObjetoEExtrair(pBody As String, pStart As Integer, ByRef pBrandId As Integer, ByRef pLineId As Integer, ByRef pFamilyId As Integer) As Integer
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = pStart
            Dim _janelaMax As Integer = 200
            Dim _janelaLen As Integer = 0
            Dim _janela As String = ""
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escape As Boolean = False
            Dim _fim As Integer = 0
            Dim _n As Integer = 0

            AvancarFimObjetoEExtrair = 0

            If pStart < 1 Then
                Exit Function
            End If

            _bodyLen = Len(pBody)
            If pStart > _bodyLen Then
                Exit Function
            End If

            While _pos <= _bodyLen
                If _fim > 0 Then
                    Exit While
                End If

                _janelaLen = _janelaMax
                If _janelaLen > (_bodyLen - _pos + 1) Then
                    _janelaLen = _bodyLen - _pos + 1
                End If
                If _janelaLen <= 0 Then
                    Exit While
                End If

                _janela = Mid(pBody, _pos, _janelaLen)

                If pBrandId <= 0 Then
                    _n = me.ExtrairInteiroDoPrefixoAscii(_janela, "brand_id")
                    If _n > 0 Then
                        pBrandId = _n
                    End If
                End If
                If pFamilyId <= 0 Then
                    _n = me.ExtrairInteiroDoPrefixoAscii(_janela, "family")
                    If _n > 0 Then
                        pFamilyId = _n
                    End If
                End If
                If pLineId <= 0 Then
                    _n = me.ExtrairInteiroDoPrefixoAscii(_janela, "line")
                    If _n > 0 Then
                        pLineId = _n
                    End If
                End If

                _i = 1
                While _i <= _janelaLen
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
                                            Exit While
                                        End If
                                    End If
                                End If
                            End If
                        End If
                    End If

                    _i = _i + 1
                Wend

                If _fim > 0 Then
                    Exit While
                End If
                _pos = _pos + _janelaLen
            Wend

            AvancarFimObjetoEExtrair = _fim
        End Function

        Private Function ObterLastPageDoSufixo(pBody As String) As Integer
            Dim _bodyLen As Integer = 0
            Dim _janelaMax As Integer = 200
            Dim _janelaLen As Integer = 0
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
                ObterLastPageDoSufixo = me.ExtrairInteiroDoPrefixoAscii(pBody, "last_page")
                Exit Function
            End If

            _pos = _bodyLen - _janelaMax + 1
            While _pos >= 1
                If _passos > 20 Then
                    Exit Function
                End If
                _passos = _passos + 1

                _janelaLen = _janelaMax
                If _janelaLen > (_bodyLen - _pos + 1) Then
                    _janelaLen = _bodyLen - _pos + 1
                End If
                If _janelaLen <= 0 Then
                    Exit Function
                End If

                _janela = Mid(pBody, _pos, _janelaLen)
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

            _prefix = Mid(pBody, 1, _prefixLen)
            PosicaoArrayDataAscii = me.PosicaoArrayDataNoPrefixo(_prefix)
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
        Private Function PosicaoAbreObjetoNaJanela(pJanela As String) As Integer
            Dim _len As Integer = Len(pJanela)
            Dim _i As Integer = 1
            Dim _ch As String = ""

            PosicaoAbreObjetoNaJanela = 0

            While _i <= _len
                _ch = Mid(pJanela, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    If _ch = "," Then
                        _i = _i + 1
                    Else
                        Exit While
                    End If
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            _ch = Mid(pJanela, _i, 1)
            If _ch = "]" Then
                PosicaoAbreObjetoNaJanela = -1
                Exit Function
            End If

            If _ch = "{" Then
                PosicaoAbreObjetoNaJanela = _i
            End If
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

        Private Function IsErroAutenticacao(pEx As Exception) As Boolean
            Dim _mensagem As String = pEx._getMessage()

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
