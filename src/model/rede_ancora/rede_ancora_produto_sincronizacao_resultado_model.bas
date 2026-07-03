Imports mod_tobject
Imports rede_ancora_produto_sincronizacao_modo

Namespace rede_ancora_produto_sincronizacao_resultado_model
    Class RedeAncoraProdutoSincronizacaoResultadoModel
        Inherits TTObject

        QtdChunks As Integer
        QtdChunksApi As Integer
        QtdChunksComErro As Integer
        QtdCnasSolicitados As Integer
        QtdInseridos As Integer
        QtdAtualizados As Integer
        QtdSemAlteracao As Integer
        QtdIgnorados As Integer
        QtdNaoEncontrados As Integer
        QtdDesativados As Integer
        Modo As String
        Sucesso As Boolean
        DataInicio As TDateTime
        DataFim As TDateTime
        MensagemResumo As String
        Erros As String

        Sub New()
            MyBase.New()
            me.Sucesso = True
            me.MensagemResumo = ""
            me.Erros = ""
        End Sub

        Function TotalPersistidos() As Integer
            TotalPersistidos = me.QtdInseridos + me.QtdAtualizados
        End Function

        Sub RegistrarErroChunk(pNumeroChunk As Integer, pMensagem As String)
            me.QtdChunksComErro = me.QtdChunksComErro + 1
            me.Sucesso = False

            If me.Erros <> "" Then
                me.Erros = me.Erros + Char(13)
            End If

            me.Erros = me.Erros + "Chunk " + pNumeroChunk.ToString() + ": " + pMensagem
        End Sub

        Sub Finalizar()
            me.DataFim = DateTime()
            me.MontarMensagemResumo()
        End Sub

        Private Sub MontarMensagemResumo()
            If me.QtdCnasSolicitados <= 0 Then
                me.MensagemResumo = "Nenhum CNA informado para sincronizacao"
                Exit Sub
            End If

            If RedeAncoraProdutoSincronizacaoModo.IsSomenteNovos(me.Modo) And me.QtdIgnorados = me.QtdCnasSolicitados And me.TotalPersistidos() <= 0 Then
                me.MensagemResumo = "Nenhum CNA novo para importar"
                me.Sucesso = True
                Exit Sub
            End If

            me.MensagemResumo = "Sync " + me.Modo + ": " +_
            me.QtdInseridos.ToString() + " inseridos, " +_
            me.QtdAtualizados.ToString() + " atualizados, " +_
            me.QtdSemAlteracao.ToString() + " sem alteracao, " +_
            me.QtdIgnorados.ToString() + " ignorados, " +_
            me.QtdNaoEncontrados.ToString() + " nao encontrados"

            If me.QtdChunksComErro > 0 Then
                me.MensagemResumo = me.MensagemResumo + ", " + me.QtdChunksComErro.ToString() + " chunks com erro"
            End If
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
