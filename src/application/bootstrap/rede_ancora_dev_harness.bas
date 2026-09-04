Imports mod_logger
Imports mod_tobject
Imports try_parser
Imports rede_ancora_integracao_context
Imports rede_ancora_smoke_test
Imports rede_ancora_empresa_sync_test
Imports rede_ancora_produto_sync_bootstrap
Imports rede_ancora_produto_sincronizacao_modo
Imports rede_ancora_checkout_bootstrap
Imports rede_ancora_api_novos_bootstrap

Namespace rede_ancora_dev_harness
    Class RedeAncoraDevHarness
        Inherits TTObject

        Private _chaveApi As String
        Private _cenario As String
        Private _inicializarRedeAncora As Boolean
        Private _confirmarPedido As Boolean
        Private _deletarCarrinhoAoFinal As Boolean
        Private _testarEndpointsProduto As Boolean
        Private _cna As Integer
        Private _baixarCatalogoCompleto As Boolean

        Sub New()
            MyBase.New()
            me._chaveApi = ""
            me._cenario = RedeAncoraDevHarness.CenarioCompleto()
            me._inicializarRedeAncora = True
            me._confirmarPedido = False
            me._deletarCarrinhoAoFinal = False
            me._testarEndpointsProduto = True
            me._cna = 0
            me._baixarCatalogoCompleto = False
        End Sub

        Shared Function CenarioSmoke() As String
            CenarioSmoke = "SMOKE"
        End Function

        Shared Function CenarioEmpresa() As String
            CenarioEmpresa = "EMPRESA"
        End Function

        Shared Function CenarioProduto() As String
            CenarioProduto = "PRODUTO"
        End Function

        Shared Function CenarioCheckout() As String
            CenarioCheckout = "CHECKOUT"
        End Function

        Shared Function CenarioNovos() As String
            CenarioNovos = "NOVOS"
        End Function

        Shared Function CenarioSincronizacao() As String
            CenarioSincronizacao = "SYNC"
        End Function

        Shared Function CenarioCompleto() As String
            CenarioCompleto = "COMPLETO"
        End Function

        Sub DefinirChaveApi(pChaveApi As String)
            me._chaveApi = pChaveApi
        End Sub

        Sub DefinirCenario(pCenario As String)
            me._cenario = pCenario.Trim().ToUpper()
        End Sub

        Sub DefinirInicializarRedeAncora(pInicializar As Boolean)
            me._inicializarRedeAncora = pInicializar
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

        Sub DefinirCna(pCna As Integer)
            me._cna = pCna
        End Sub

        Sub DefinirBaixarCatalogoCompleto(pBaixar As Boolean)
            me._baixarCatalogoCompleto = pBaixar
        End Sub

        Sub Executar()
            Dim _cenario As String = me._cenario
            Dim _codUsuario As Integer = 0

            Try
                _codUsuario = RedeAncoraIntegracaoContext.ObterCodUsuarioLogado()
            Catch ex As Exception
                Throw New System.Exception("Usuario ERP nao autenticado no dev harness. Efetue login antes de executar.")
            End Try

            mod_logger.Printe("=== Rede Ancora dev harness :: inicio ===")
            mod_logger.Printe("Cenario: " + _cenario + " | CodUsuario: " + Parser.IntegerToString(_codUsuario))

            If _cenario = RedeAncoraDevHarness.CenarioSmoke() Then
                me.ExecutarSmoke()
            ElseIf _cenario = RedeAncoraDevHarness.CenarioEmpresa() Then
                me.ExecutarEmpresa()
            ElseIf _cenario = RedeAncoraDevHarness.CenarioProduto() Then
                me.ExecutarProduto()
            ElseIf _cenario = RedeAncoraDevHarness.CenarioCheckout() Then
                me.ExecutarCheckout()
            ElseIf _cenario = RedeAncoraDevHarness.CenarioNovos() Then
                me.ExecutarNovos()
            ElseIf _cenario = RedeAncoraDevHarness.CenarioSincronizacao() Then
                me.ExecutarSmoke()
                me.ExecutarProduto()
            ElseIf _cenario = RedeAncoraDevHarness.CenarioCompleto() Then
                me.ExecutarSmoke()
                me.ExecutarEmpresa()
                me.ExecutarProduto()
                me.ExecutarCheckout()
                me.ExecutarNovos()
            Else
                Throw New System.Exception("Cenario dev harness desconhecido: " + _cenario)
            End If

            mod_logger.Printe("=== Rede Ancora dev harness :: concluido ===")
        End Sub

        Private Sub ExecutarSmoke()
            Dim _smoke As RedeAncoraSmokeTest = New RedeAncoraSmokeTest()

            _smoke.Definir(True)

            If me._chaveApi <> "" Then
                _smoke.DefinirChaveApi(me._chaveApi)
            End If

            _smoke.Executar()
            _smoke.Free()
        End Sub

        Private Sub ExecutarEmpresa()
            Dim _empresa As RedeAncoraEmpresaSyncTest = New RedeAncoraEmpresaSyncTest()

            _empresa.Definir(True)

            If me._chaveApi <> "" Then
                _empresa.DefinirChaveApi(me._chaveApi)
            End If

            _empresa.Executar()
            _empresa.Free()
        End Sub

        Private Sub ExecutarProduto()
            Dim _sync As RedeAncoraProdutoSyncBootstrap = New RedeAncoraProdutoSyncBootstrap()

            _sync.DefinirChaveApi(me._chaveApi)
            _sync.DefinirInicializarRedeAncora(me._inicializarRedeAncora)
            _sync.Definir(True, RedeAncoraProdutoSincronizacaoModo.Completa(), False, False, True, 100)
            _sync.DefinirBaixarCatalogoCompleto(me._baixarCatalogoCompleto)

            If Not me._baixarCatalogoCompleto Then
                _sync.AdicionarCna(849766)
                _sync.AdicionarCna(880939)
            End If

            _sync.Executar()
            _sync.Free()
        End Sub

        Private Sub ExecutarCheckout()
            Dim _checkout As RedeAncoraCheckoutBootstrap = New RedeAncoraCheckoutBootstrap()

            _checkout.Definir(True)

            If me._chaveApi <> "" Then
                _checkout.DefinirChaveApi(me._chaveApi)
            End If

            _checkout.DefinirInicializarRedeAncora(me._inicializarRedeAncora)
            _checkout.DefinirConfirmarPedido(me._confirmarPedido)
            _checkout.DefinirDeletarCarrinhoAoFinal(me._deletarCarrinhoAoFinal)
            _checkout.DefinirTestarEndpointsProduto(me._testarEndpointsProduto)

            mod_logger.Printe("Checkout: ConfirmarPedido=" + me._confirmarPedido.ToString() + " | DeletarCarrinhoAoFinal=" + me._deletarCarrinhoAoFinal.ToString())

            If me._cna > 0 Then
                _checkout.DefinirCna(me._cna)
            End If

            _checkout.Executar()
            _checkout.Free()
        End Sub

        Private Sub ExecutarNovos()
            Dim _novos As RedeAncoraApiNovosBootstrap = New RedeAncoraApiNovosBootstrap()

            _novos.Definir(True)

            If me._chaveApi <> "" Then
                _novos.DefinirChaveApi(me._chaveApi)
            End If

            _novos.DefinirInicializarRedeAncora(me._inicializarRedeAncora)

            If me._cna > 0 Then
                _novos.DefinirCna(me._cna)
            End If

            _novos.Executar()
            _novos.Free()
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
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
