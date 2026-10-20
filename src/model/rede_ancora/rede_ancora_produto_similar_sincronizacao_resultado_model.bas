Imports mod_tobject
Imports try_parser

Namespace rede_ancora_produto_similar_sincronizacao_resultado_model
    Class RedeAncoraProdutoSimilarSincronizacaoResultadoModel
        Inherits TTObject

        QtdCentros As Integer
        QtdCnasSolicitados As Integer
        QtdChunks As Integer
        QtdChunksApi As Integer
        QtdChunksComErro As Integer
        QtdProcessados As Integer
        QtdSimilares As Integer
        QtdNaoEncontrados As Integer
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

        Sub RegistrarErroChunk(pCodCentroDistribuicao As Integer, pNumeroChunk As Integer, pMensagem As String)
            me.QtdChunksComErro = me.QtdChunksComErro + 1
            me.Sucesso = False

            If me.Erros <> "" Then
                me.Erros = me.Erros + Char(13)
            End If

            me.Erros = me.Erros + "CD " + Parser.IntegerToString(pCodCentroDistribuicao) + " chunk " + Parser.IntegerToString(pNumeroChunk) + ": " + pMensagem
        End Sub

        Sub Finalizar()
            me.DataFim = DateTime()
            me.MontarMensagemResumo()
        End Sub

        Private Sub MontarMensagemResumo()
            If me.QtdCnasSolicitados <= 0 Then
                me.MensagemResumo = "Nenhum CNA cadastrado para sincronizacao de similares"
            Else
                If me.QtdCentros <= 0 Then
                    me.MensagemResumo = "Nenhum centro de distribuicao com estado para sincronizacao de similares"
                Else
                    me.MensagemResumo = "Sync similares: " +_
                        Parser.IntegerToString(me.QtdCentros) + " centros, " +_
                        Parser.IntegerToString(me.QtdProcessados) + " produtos, " +_
                        Parser.IntegerToString(me.QtdSimilares) + " similares, " +_
                        Parser.IntegerToString(me.QtdNaoEncontrados) + " nao encontrados"

                    If me.QtdChunksComErro > 0 Then
                        me.MensagemResumo = me.MensagemResumo + ", " + Parser.IntegerToString(me.QtdChunksComErro) + " blocos com erro"
                    End If
                End If
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
