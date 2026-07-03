Imports mod_tobject
Imports try_parser

Namespace rede_ancora_produto_imagem_sincronizacao_resultado_model
    Class RedeAncoraProdutoImagemSincronizacaoResultadoModel
        Inherits TTObject

        QtdChunks As Integer
        QtdChunksApi As Integer
        QtdChunksComErro As Integer
        QtdCnasSolicitados As Integer
        QtdProcessados As Integer
        QtdComImagem As Integer
        QtdSemImagem As Integer
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

        Sub RegistrarErroChunk(pNumeroChunk As Integer, pMensagem As String)
            me.QtdChunksComErro = me.QtdChunksComErro + 1
            me.Sucesso = False

            If me.Erros <> "" Then
                me.Erros = me.Erros + Char(13)
            End If

            me.Erros = me.Erros + "Chunk " + Parser.IntegerToString(pNumeroChunk) + ": " + pMensagem
        End Sub

        Sub Finalizar()
            me.DataFim = DateTime()
            me.MontarMensagemResumo()
        End Sub

        Private Sub MontarMensagemResumo()
            If me.QtdCnasSolicitados <= 0 Then
                me.MensagemResumo = "Nenhum CNA informado para sincronizacao de imagens"
                Exit Sub
            End If

            me.MensagemResumo = "Sync imagens: " +_
            Parser.IntegerToString(me.QtdProcessados) + " processados, " +_
            Parser.IntegerToString(me.QtdComImagem) + " com imagem, " +_
            Parser.IntegerToString(me.QtdSemImagem) + " sem imagem"

            If me.QtdChunksComErro > 0 Then
                me.MensagemResumo = me.MensagemResumo + ", " + Parser.IntegerToString(me.QtdChunksComErro) + " chunks com erro"
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
