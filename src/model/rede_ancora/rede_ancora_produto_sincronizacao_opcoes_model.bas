Imports mod_tobject
Imports rede_ancora_produto_cnas_model
Imports rede_ancora_produto_sincronizacao_modo

Namespace rede_ancora_produto_sincronizacao_opcoes_model
    Class RedeAncoraProdutoSincronizacaoOpcoesModel
        Inherits TTObject

        CodUsuario As Integer
        CodCentroDistribuicao As Integer
        CodEstado As Integer
        Cnas As RedeAncoraProdutoCnasModel
        TamanhoChunk As Integer
        DesativarAusentes As Boolean
        SincronizarCatalogo As Boolean
        Modo As String
        UsarProdutosCadastrados As Boolean
        BaixarCatalogoCompleto As Boolean
        ReiniciarProgresso As Boolean

        Sub New()
            MyBase.New()
            me.Cnas = NULL
            me.TamanhoChunk = 0
            me.DesativarAusentes = False
            me.SincronizarCatalogo = True
            me.Modo = RedeAncoraProdutoSincronizacaoModo.Completa()
            me.UsarProdutosCadastrados = False
            me.BaixarCatalogoCompleto = False
            me.ReiniciarProgresso = False
        End Sub

        Sub Validate()
            If me.CodUsuario <= 0 Then
                Throw New System.Exception("CodUsuario invalido em RedeAncoraProdutoSincronizacaoOpcoesModel")
            End If

            If me.CodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido em RedeAncoraProdutoSincronizacaoOpcoesModel")
            End If

            If me.CodEstado <= 0 Then
                Throw New System.Exception("CodEstado invalido em RedeAncoraProdutoSincronizacaoOpcoesModel")
            End If

            If RedeAncoraProdutoSincronizacaoModo.IsSomenteNovos(me.Modo) Then
                If me.UsarProdutosCadastrados Then
                    Throw New System.Exception("Modo NOVOS nao pode usar UsarProdutosCadastrados")
                End If

                If Not me.TemListaCnas() Then
                    Throw New System.Exception("Modo NOVOS exige lista de CNAs candidatos")
                End If
            End If
        End Sub

        Function TemListaCnas() As Boolean
            TemListaCnas = False

            If Assigned(me.Cnas) Then
                TemListaCnas = me.Cnas.Length > 0
            End If
        End Function

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
