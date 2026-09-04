Imports mod_logger
Imports mod_tobject
Imports try_parser
Imports usuario_service
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_sincronizacao_modo
Imports rede_ancora_produto_sincronizacao_opcoes_model
Imports rede_ancora_produto_sincronizacao_resultado_model
Imports rede_ancora_centros_distribuicao_model
Imports rede_ancora_empresa_model
Imports rede_ancora_integracao_context

Namespace rede_ancora_produto_sync_bootstrap
    Class RedeAncoraProdutoSyncBootstrap
        Inherits TTObject

        Private _configurado As String
        Private _habilitado As Boolean
        Private _modo As String
        Private _usarProdutosCadastrados As Boolean
        Private _desativarAusentes As Boolean
        Private _sincronizarCatalogo As Boolean
        Private _tamanhoChunk As Integer
        Private _cnas As RedeAncoraProdutoCnasModel
        Private _chaveApi As String
        Private _inicializarRedeAncora As Boolean
        Private _baixarCatalogoCompleto As Boolean

        Sub DefinirChaveApi(pChaveApi As String)
            me._chaveApi = pChaveApi
        End Sub

        Sub DefinirInicializarRedeAncora(pInicializar As Boolean)
            me._inicializarRedeAncora = pInicializar
        End Sub

        Sub DefinirBaixarCatalogoCompleto(pBaixar As Boolean)
            me._baixarCatalogoCompleto = pBaixar
        End Sub

        Sub Definir(pHabilitar As Boolean, pModo As String, pUsarProdutosCadastrados As Boolean, pDesativarAusentes As Boolean, pSincronizarCatalogo As Boolean, pTamanhoChunk As Integer)
            me.AplicarConfiguracao(pHabilitar, pModo, pUsarProdutosCadastrados, pDesativarAusentes, pSincronizarCatalogo, pTamanhoChunk)
        End Sub

        Sub LimparCnas()
            If Assigned(me._cnas) Then
                me._cnas.Free()
                me._cnas = Null
            End If
        End Sub

        Sub AdicionarCna(pCna As Integer)
            me.GarantirConfiguracaoPadrao()

            If Not Assigned(me._cnas) Then
                me._cnas = New RedeAncoraProdutoCnasModel()
            End If

            me._cnas.PushDistinct(pCna)
        End Sub

        Sub Executar()
            me.GarantirConfiguracaoPadrao()

            If Not me._habilitado Then
                mod_logger.Printe("Rede Ancora sync bootstrap desabilitado.")
                Exit Sub
            End If

            Dim _svc As UsuarioService = Null
            Dim _centros As RedeAncoraCentrosDistribuicaoModel = Null
            Dim _opcoes As RedeAncoraProdutoSincronizacaoOpcoesModel = Null
            Dim _resultado As RedeAncoraProdutoSincronizacaoResultadoModel = Null
            Dim _codUsuario As Integer = 0
            Dim _codCentro As Integer = 0
            Dim _codEstado As Integer = 0

            Try
                mod_logger.Printe("=== Rede Ancora sync produtos :: inicio ===")

                _svc = New UsuarioService()

                If Not _svc.PingRedeAncora() Then
                    Throw New System.Exception("API Rede Ancora indisponivel (ping falhou)")
                End If

                _codUsuario = RedeAncoraIntegracaoContext.ObterCodUsuarioLogado()

                me.GarantirAutenticacao(_svc)

                _centros = _svc.ListarRedeAncoraCentrosDistribuicao()
                me.ResolverCentroDistribuicao(_centros, _codCentro, _codEstado)

                mod_logger.Printe("Usuario: " + Parser.IntegerToString(_codUsuario) + " | Centro: " + Parser.IntegerToString(_codCentro) + " | Estado: " + Parser.IntegerToString(_codEstado))
                mod_logger.Printe("Modo: " + me._modo)

                _opcoes = New RedeAncoraProdutoSincronizacaoOpcoesModel()
                _opcoes.CodUsuario = _codUsuario
                _opcoes.CodCentroDistribuicao = _codCentro
                _opcoes.CodEstado = _codEstado
                _opcoes.TamanhoChunk = me._tamanhoChunk
                _opcoes.DesativarAusentes = me._desativarAusentes
                _opcoes.SincronizarCatalogo = me._sincronizarCatalogo
                _opcoes.Modo = me._modo
                _opcoes.UsarProdutosCadastrados = me._usarProdutosCadastrados
                _opcoes.BaixarCatalogoCompleto = me._baixarCatalogoCompleto
                _opcoes.Cnas = NULL

                If Not _opcoes.UsarProdutosCadastrados And Not _opcoes.BaixarCatalogoCompleto Then
                    _opcoes.Cnas = me._cnas
                End If

                mod_logger.Printe("BaixarCatalogoCompleto: " + _opcoes.BaixarCatalogoCompleto.ToString())

                _resultado = _svc.SincronizarRedeAncoraProdutosOpcoes(_opcoes)
                me.ImprimirResultado(_resultado)

                mod_logger.Printe("=== Rede Ancora sync produtos :: concluido ===")

                _resultado.Free()
                _opcoes.Free()
                _centros.Free()
                _svc.Free()
            Catch ex As Exception
                If Assigned(_resultado) Then
                    _resultado.Free()
                End If

                If Assigned(_opcoes) Then
                    _opcoes.Free()
                End If

                If Assigned(_centros) Then
                    _centros.Free()
                End If

                If Assigned(_svc) Then
                    _svc.Free()
                End If

                Throw New System.Exception("Rede Ancora sync produtos falhou: " + ex._getMessage())
            End Try
        End Sub

        Private Sub AplicarConfiguracao(pHabilitar As Boolean, pModo As String, pUsarProdutosCadastrados As Boolean, pDesativarAusentes As Boolean, pSincronizarCatalogo As Boolean, pTamanhoChunk As Integer)
            me._configurado = "S"
            me._habilitado = pHabilitar
            me._modo = pModo
            me._usarProdutosCadastrados = pUsarProdutosCadastrados
            me._desativarAusentes = pDesativarAusentes
            me._sincronizarCatalogo = pSincronizarCatalogo
            me._tamanhoChunk = pTamanhoChunk
        End Sub

        Private Sub GarantirConfiguracaoPadrao()
            If me._configurado = "S" Then
                Exit Sub
            End If

            me.AplicarConfiguracao(True, RedeAncoraProdutoSincronizacaoModo.Completa(), False, False, True, 0)
            me._cnas = New RedeAncoraProdutoCnasModel()

            ' Edite os CNAs de teste abaixo ou use Definir/AdicionarCna antes de Executar.
            me._cnas.Push(849766)
            me._cnas.Push(880939)
        End Sub

        Private Sub GarantirAutenticacao(pSvc As UsuarioService)
            Dim _chaveApi As String = me._chaveApi
            Dim _inicializar As Boolean = me._inicializarRedeAncora
            Dim _empresa As RedeAncoraEmpresaModel = Null

            If _chaveApi = "" Then
                Exit Sub
            End If

            mod_logger.Printe("Preparando chave API Rede Ancora...")

            Try
                pSvc.SalvarChaveApiRedeAncora(_chaveApi)
                mod_logger.Printe("Chave API gravada.")

                If _inicializar Then
                    mod_logger.Printe("Iniciando InicializarRedeAncora...")
                    _empresa = pSvc.InicializarRedeAncora()
                    mod_logger.Printe("InicializarRedeAncora retornou; liberando empresa...")
                    _empresa.Free()
                    _empresa = Null
                    mod_logger.Printe("Inicializacao Rede Ancora concluida (profile, modalidades, catalogo).")
                End If
            Catch ex As Exception
                If Assigned(_empresa) Then
                    _empresa.Free()
                End If

                Throw New System.Exception("Falha ao configurar chave API Rede Ancora: " + ex._getMessage())
            End Try
        End Sub

        Private Sub ResolverCentroDistribuicao(pCentros As RedeAncoraCentrosDistribuicaoModel, ByRef pCodCentro As Integer, ByRef pCodEstado As Integer)
            Dim _i As Integer

            If Not Assigned(pCentros) Then
                Throw New System.Exception("Nenhum centro de distribuicao encontrado. Execute InicializarRedeAncora antes do sync.")
            End If

            If pCentros.Length <= 0 Then
                Throw New System.Exception("Nenhum centro de distribuicao encontrado. Execute InicializarRedeAncora antes do sync.")
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

        Private Sub ImprimirResultado(pResultado As RedeAncoraProdutoSincronizacaoResultadoModel)
            mod_logger.Printe("Sucesso: " + pResultado.Sucesso.ToString())
            mod_logger.Printe(pResultado.MensagemResumo)
            mod_logger.Printe("Chunks: " + pResultado.QtdChunks.ToString() + " | API: " + pResultado.QtdChunksApi.ToString() + " | Com erro: " + pResultado.QtdChunksComErro.ToString())
            mod_logger.Printe("Inseridos: " + pResultado.QtdInseridos.ToString() + " | Atualizados: " + pResultado.QtdAtualizados.ToString() + " | Sem alteracao: " + pResultado.QtdSemAlteracao.ToString())
            mod_logger.Printe("Ignorados: " + pResultado.QtdIgnorados.ToString() + " | Nao encontrados: " + pResultado.QtdNaoEncontrados.ToString() + " | Desativados: " + pResultado.QtdDesativados.ToString())

            If pResultado.Erros <> "" Then
                mod_logger.Printe("Erros por chunk:")
                mod_logger.Printe(pResultado.Erros)
            End If
        End Sub

        Sub Free()
            me.LimparCnas()
            MyBase.Free()
        End Sub
        Sub New()
            MyBase.New()
            me._baixarCatalogoCompleto = False
            me._inicializarRedeAncora = False
            me._cnas = NULL
        End Sub

    End Class
End Namespace
