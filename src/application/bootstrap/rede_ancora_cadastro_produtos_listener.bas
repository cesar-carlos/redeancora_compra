Imports mod_tobject
Imports mod_logger
Imports base_listener
Imports usuario_service
Imports rede_ancora_produto_sincronizacao_resultado_model
Imports diag_stack

Namespace rede_ancora_cadastro_produtos_listener
    ' Timer sobre BaseListener. Padrao 4h (algumas vezes ao dia). Nao auto-start.
    ' Chama UsuarioService.SincronizarRedeAncoraCadastroProdutosCompleto.
    Class RedeAncoraCadastroProdutosListener
        Inherits BaseListener

        Shared Function IntervaloPadraoMs() As Integer
            IntervaloPadraoMs = 14400000
        End Function

        Sub New()
            MyBase.New(RedeAncoraCadastroProdutosListener.IntervaloPadraoMs(), False, False)
        End Sub

        Sub New(pMillisecondsInterval As Integer)
            MyBase.New(pMillisecondsInterval, False, False)
        End Sub

        Overrides Sub OnListener()
            Dim _svc As UsuarioService = NULL
            Dim _resultado As RedeAncoraProdutoSincronizacaoResultadoModel = NULL

            Try
                mod_logger.Printe("=== Rede Ancora cadastro produtos listener :: inicio ===")
                _svc = New UsuarioService()

                If Not _svc.PingRedeAncora() Then
                    Throw New System.Exception("API Rede Ancora indisponivel (ping falhou)")
                End If

                _resultado = _svc.SincronizarRedeAncoraCadastroProdutosCompleto()
                me.ImprimirResultado(_resultado)

                _resultado.Free()
                _resultado = NULL
                _svc.Free()
                _svc = NULL
                mod_logger.Printe("=== Rede Ancora cadastro produtos listener :: concluido ===")
            Catch ex As Exception
                If Assigned(_resultado) Then
                    _resultado.Free()
                End If

                If Assigned(_svc) Then
                    _svc.Free()
                End If

                Throw ex
            End Try
        End Sub

        Overrides Sub OnListenerError(pException As Exception)
            DiagStack.DumpOnError(pException)
            mod_logger.Erro("RedeAncoraCadastroProdutosListener: " & DiagStack.FormatException(pException))
        End Sub

        Private Sub ImprimirResultado(pResultado As RedeAncoraProdutoSincronizacaoResultadoModel)
            If Not Assigned(pResultado) Then
                Exit Sub
            End If

            mod_logger.Printe("Sucesso: " & pResultado.Sucesso.ToString())
            mod_logger.Printe(pResultado.MensagemResumo)
            mod_logger.Printe("Chunks: " & pResultado.QtdChunks.ToString() & " | API: " & pResultado.QtdChunksApi.ToString() & " | Com erro: " & pResultado.QtdChunksComErro.ToString())
            mod_logger.Printe("Inseridos: " & pResultado.QtdInseridos.ToString() & " | Atualizados: " & pResultado.QtdAtualizados.ToString() & " | Sem alteracao: " & pResultado.QtdSemAlteracao.ToString())
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
