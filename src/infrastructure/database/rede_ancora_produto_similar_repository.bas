Imports mod_tobject
Imports rede_ancora_produto_similar_model
Imports rede_ancora_produto_similares_model
Imports integracao_schema
Imports sql_helper

Namespace rede_ancora_produto_similar_repository
    Class RedeAncoraProdutoSimilarRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaProdutoSimilarQualificada()
        End Function

        Private Function SqlDeletePorCnaCentro() As String
            SqlDeletePorCnaCentro = "DELETE FROM " & me.Tabela() & " WHERE Cna = :Cna AND CodCentroDistribuicao = :CodCentroDistribuicao"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = "INSERT INTO " & me.Tabela() & " (" +_
                "Cna, CodCentroDistribuicao, CodEstado, CnaSimilar, CodigoReferencia, Nome, NomeMarca, CodMarca, DataAtualizacao) " +_
                "VALUES (:Cna, :CodCentroDistribuicao, :CodEstado, :CnaSimilar, :CodigoReferencia, :Nome, :NomeMarca, " +_
                "CASE WHEN :CodMarca = 0 THEN NULL ELSE :CodMarca END, :DataAtualizacao)"
        End Function

        Private Function Truncar(pValor As String, pMax As Integer) As String
            If pMax <= 0 Then
                Truncar = ""
            Else
                If Len(pValor) <= pMax Then
                    Truncar = pValor
                Else
                    Truncar = Mid(pValor, 1, pMax)
                End If
            End If
        End Function

        Sub SubstituirPorCnaCentroSemTransacao(pCna As Integer, pCodCentroDistribuicao As Integer, pItens As RedeAncoraProdutoSimilaresModel)
            Dim _delete As SQL.Command = NULL
            Dim _insert As SQL.Command = NULL
            Dim _item As RedeAncoraProdutoSimilarModel = NULL
            Dim _i As Integer

            If pCna <= 0 Then
                Throw New System.Exception("Cna invalido em Integracao.RedeAncoraProdutoSimilar")
            End If

            If pCodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido em Integracao.RedeAncoraProdutoSimilar")
            End If

            Try
                _delete = SqlHelper.OpenQuery(me.SqlDeletePorCnaCentro())
                _delete.Param("Cna").AsInteger = pCna
                _delete.Param("CodCentroDistribuicao").AsInteger = pCodCentroDistribuicao
                _delete.ExecSQL()
                SqlHelper.ReleaseQuery(_delete)
                _delete = NULL

                If Assigned(pItens) Then
                    For _i = 0 To pItens.Length - 1
                        _item = pItens.Take(_i)

                        If _item.Cna = pCna Then
                            If _item.CodCentroDistribuicao = pCodCentroDistribuicao Then
                                If _item.CnaSimilar > 0 Then
                                    _item.DataAtualizacao = DateTime()
                                    _insert = SqlHelper.OpenQuery(me.SqlInsert())
                                    _insert.Param("Cna").AsInteger = _item.Cna
                                    _insert.Param("CodCentroDistribuicao").AsInteger = _item.CodCentroDistribuicao
                                    _insert.Param("CodEstado").AsInteger = _item.CodEstado
                                    _insert.Param("CnaSimilar").AsInteger = _item.CnaSimilar
                                    _insert.Param("CodigoReferencia").AsString = me.Truncar(_item.CodigoReferencia, 30)
                                    _insert.Param("Nome").AsString = me.Truncar(_item.Nome, 255)
                                    _insert.Param("NomeMarca").AsString = me.Truncar(_item.NomeMarca, 120)
                                    _insert.Param("CodMarca").AsInteger = _item.CodMarca
                                    _insert.Param("DataAtualizacao").AsDateTime = _item.DataAtualizacao
                                    _insert.ExecSQL()
                                    SqlHelper.ReleaseQuery(_insert)
                                    _insert = NULL
                                End If
                            End If
                        End If
                    Next
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_delete)
                SqlHelper.ReleaseQuery(_insert)
                Throw New System.Exception("Erro ao gravar Integracao.RedeAncoraProdutoSimilar: " & Char(13) & ex._getMessage())
            End Try
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

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
