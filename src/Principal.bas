' data7:disable missing-import

Imports app_boot
Imports rede_ancora_dev_harness

AppBoot.Run()

Dim _dev As New RedeAncoraDevHarness()
_dev.DefinirChaveApi("")
' Sync cadastros: marcas/linhas/familias + vinculos CNA + imagens (sem checkout).
_dev.DefinirCenario(RedeAncoraDevHarness.CenarioSincronizacao())
_dev.DefinirBaixarCatalogoCompleto(True)
' Voltar para checkout / COMPLETO: comente as duas linhas acima e descomente abaixo.
' _dev.DefinirCenario(RedeAncoraDevHarness.CenarioCompleto())
' _dev.DefinirCenario(RedeAncoraDevHarness.CenarioCheckout())
' _dev.DefinirInicializarRedeAncora(False)
' _dev.DefinirDeletarCarrinhoAoFinal(False)
' _dev.DefinirConfirmarPedido(False)
' _dev.DefinirTestarEndpointsProduto(False)
_dev.Executar()
_dev.Free()
