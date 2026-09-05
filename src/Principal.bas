' data7:disable missing-import

Imports app_boot
Imports rede_ancora_dev_harness

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
