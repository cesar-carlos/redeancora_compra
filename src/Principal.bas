' data7:disable missing-import

Imports app_boot
Imports rede_ancora_dev_harness
Imports usuario_service
Imports rede_ancora_produto_preco_estoque_sincronizacao_resultado_model
Imports rede_ancora_produto_similar_sincronizacao_resultado_model
Imports rede_ancora_produto_imagem_sincronizacao_resultado_model

mod_logger.ConfigureVSCode("C:\Data7\logger.txt")

AppBoot.Run()

' Teste local: cadastro completo de produtos.
' Cadeia: InicializarRedeAncora (CD do profile) ->
' UsuarioService.SincronizarRedeAncoraCadastroProdutosCompleto ->
' RedeAncoraProdutoSincronizacaoService.SincronizarCadastroProdutosCompleto
Dim _dev As New RedeAncoraDevHarness()
' Preencha a X-API-KEY abaixo para testar. Nao commitar a chave.
_dev.DefinirChaveApi("")
_dev.DefinirCenario(RedeAncoraDevHarness.CenarioSincronizacao())
_dev.DefinirBaixarCatalogoCompleto(True)
_dev.Executar()
_dev.Free()

' Carga completa de preco/estoque, similares e imagens.
' Usa os CNAs de RedeAncoraProduto e os centros ja gravados. 0 = bloco de 100.
' Imagens usam o centro preferencial, porque a tabela nao guarda o CD.
Dim _svc As New UsuarioService()
Dim _precos As RedeAncoraProdutoPrecoEstoqueSincronizacaoResultadoModel = NULL
Dim _similares As RedeAncoraProdutoSimilarSincronizacaoResultadoModel = NULL
Dim _imagens As RedeAncoraProdutoImagemSincronizacaoResultadoModel = NULL

Try
    mod_logger.Printe("=== Rede Ancora sync precos :: inicio ===")
    _precos = _svc.SincronizarRedeAncoraPrecosEstoquesCompleto(0)
    mod_logger.Printe(_precos.MensagemResumo)
    _precos.Free()
    _precos = NULL
    mod_logger.Printe("=== Rede Ancora sync precos :: concluido ===")

    mod_logger.Printe("=== Rede Ancora sync similares :: inicio ===")
    _similares = _svc.SincronizarRedeAncoraSimilaresCompleto(0)
    mod_logger.Printe(_similares.MensagemResumo)
    _similares.Free()
    _similares = NULL
    mod_logger.Printe("=== Rede Ancora sync similares :: concluido ===")

    mod_logger.Printe("=== Rede Ancora sync imagens :: inicio ===")
    _imagens = _svc.SincronizarRedeAncoraImagensCompleto(0)
    mod_logger.Printe(_imagens.MensagemResumo)
    _imagens.Free()
    _imagens = NULL
    mod_logger.Printe("=== Rede Ancora sync imagens :: concluido ===")
    _svc.Free()
    _svc = NULL
Catch ex As Exception
    If Assigned(_precos) Then
        _precos.Free()
    End If

    If Assigned(_similares) Then
        _similares.Free()
    End If

    If Assigned(_imagens) Then
        _imagens.Free()
    End If

    If Assigned(_svc) Then
        _svc.Free()
    End If

    Throw ex
End Try

' --- Fluxo anterior (checkout / COMPLETO). Para restaurar, comente o bloco acima e descomente: ---
' Dim _dev As New RedeAncoraDevHarness()
' _dev.DefinirChaveApi("")
' _dev.DefinirCenario(RedeAncoraDevHarness.CenarioCompleto())
' _dev.DefinirCenario(RedeAncoraDevHarness.CenarioCheckout())
' _dev.DefinirInicializarRedeAncora(False)
' _dev.DefinirDeletarCarrinhoAoFinal(False)
' _dev.DefinirConfirmarPedido(False)
' _dev.DefinirTestarEndpointsProduto(False)
' _dev.Executar()
' _dev.Free()
