Imports mod_tobject
Imports rede_ancora_produto_imagem_model
Imports rede_ancora_produto_imagens_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_produto_imagem_repository
    Class RedeAncoraProdutoImagemRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaProdutoImagemQualificada()
        End Function

        Private Function SqlSelectPorCna() As String
            SqlSelectPorCna = $"SELECT Cna, Item, TipoImagem, DataAtualizacao, Url " +_
            $"FROM {me.Tabela()} " +_
            $"WHERE Cna = :Cna " +_
            $"ORDER BY Item, TipoImagem"
        End Function

        Private Function SqlDeletePorCna() As String
            SqlDeletePorCna = $"DELETE FROM {me.Tabela()} WHERE Cna = :Cna"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = $"INSERT INTO {me.Tabela()} (Cna, Item, TipoImagem, DataAtualizacao, Url) " +_
            $"VALUES (:Cna, :Item, :TipoImagem, :DataAtualizacao, :Url)"
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraProdutoImagemModel)
            pItem.Cna = pQuery.Field("Cna").AsInteger
            pItem.Item = pQuery.Field("Item").AsString
            pItem.TipoImagem = pQuery.Field("TipoImagem").AsString
            pItem.DataAtualizacao = pQuery.Field("DataAtualizacao").AsDateTime
            pItem.Url = pQuery.Field("Url").AsString
        End Sub

        Private Sub BindInsertParams(pQuery As SQL.Command, pItem As RedeAncoraProdutoImagemModel)
            pQuery.Param("Cna").AsInteger = pItem.Cna
            pQuery.Param("Item").AsString = pItem.Item
            pQuery.Param("TipoImagem").AsString = pItem.TipoImagem
            pQuery.Param("DataAtualizacao").AsDateTime = pItem.DataAtualizacao
            pQuery.Param("Url").AsString = pItem.Url
        End Sub

        Function ListarPorCna(pCna As Integer) As RedeAncoraProdutoImagensModel
            Dim _result As New RedeAncoraProdutoImagensModel()
            Dim _query As SQL.Command = Null

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCna())
                _query.Param("Cna").AsInteger = pCna
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraProdutoImagemModel()
                    me.Mapear(_query, _item)
                    _result.Push(_item)
                    _query.Next()
                    Wend

                    SqlHelper.ReleaseQuery(_query)
                    ListarPorCna = _result
                Catch ex As Exception
                    SqlHelper.ReleaseQuery(_query)
                    _result.Free()
                    SqlHelper.HandleQueryError(ex, "Erro ao listar Integracao.RedeAncoraProdutoImagem", "9142")
                End Try
            End Function

            Sub SubstituirPorCna(pCna As Integer, pImagens As RedeAncoraProdutoImagensModel)
                me.SubstituirPorCnaComTransacao(pCna, pImagens, True)
            End Sub

            Sub SubstituirPorCnaSemTransacao(pCna As Integer, pImagens As RedeAncoraProdutoImagensModel)
                me.SubstituirPorCnaComTransacao(pCna, pImagens, False)
            End Sub

            Private Sub SubstituirPorCnaComTransacao(pCna As Integer, pImagens As RedeAncoraProdutoImagensModel, pUsarTransacao As Boolean)
                Dim _tx As Transaction = Null
                Dim _deleteQuery As SQL.Command = Null
                Dim _insertQuery As SQL.Command = Null
                Dim _i As Integer

                Try
                    If pUsarTransacao Then
                        _tx = Transaction.Instance()
                        _tx.StartTransaction("Integracao.RedeAncoraProdutoImagem Replace")
                    End If

                    _deleteQuery = SqlHelper.OpenQuery(me.SqlDeletePorCna())
                    _deleteQuery.Param("Cna").AsInteger = pCna
                    _deleteQuery.ExecSQL()
                    SqlHelper.ReleaseQuery(_deleteQuery)
                    _deleteQuery = Null

                    If Assigned(pImagens) Then
                        For _i = 0 To pImagens.Length - 1
                            Dim _item As RedeAncoraProdutoImagemModel = pImagens.Take(_i)
                            _item.Cna = pCna
                            _item.Validate()

                            _insertQuery = SqlHelper.OpenQuery(me.SqlInsert())
                            me.BindInsertParams(_insertQuery, _item)
                            _insertQuery.ExecSQL()
                            SqlHelper.ReleaseQuery(_insertQuery)
                            _insertQuery = Null
                        Next
                    End If

                    If pUsarTransacao Then
                        _tx.AutoCommit()
                    End If
                Catch ex As Exception
                    SqlHelper.ReleaseQuery(_deleteQuery)
                    SqlHelper.ReleaseQuery(_insertQuery)

                    If pUsarTransacao Then
                        If Assigned(_tx) Then
                            _tx.Rollback()
                        End If
                    End If

                    Throw New System.Exception("Erro ao substituir Integracao.RedeAncoraProdutoImagem: " + Char(13) + ex._getMessage())
                End Try
            End Sub

            Sub ExcluirPorCna(pCna As Integer)
                me.ExcluirPorCnaComTransacao(pCna, True)
            End Sub

            Sub ExcluirPorCnaSemTransacao(pCna As Integer)
                me.ExcluirPorCnaComTransacao(pCna, False)
            End Sub

            Private Sub ExcluirPorCnaComTransacao(pCna As Integer, pUsarTransacao As Boolean)
                Dim _tx As Transaction = Null
                Dim _deleteQuery As SQL.Command = Null

                Try
                    If pUsarTransacao Then
                        _tx = Transaction.Instance()
                        _tx.StartTransaction("Integracao.RedeAncoraProdutoImagem Delete")
                    End If

                    _deleteQuery = SqlHelper.OpenQuery(me.SqlDeletePorCna())
                    _deleteQuery.Param("Cna").AsInteger = pCna
                    _deleteQuery.ExecSQL()
                    SqlHelper.ReleaseQuery(_deleteQuery)
                    _deleteQuery = Null

                    If pUsarTransacao Then
                        _tx.AutoCommit()
                    End If
                Catch ex As Exception
                    SqlHelper.ReleaseQuery(_deleteQuery)

                    If pUsarTransacao Then
                        If Assigned(_tx) Then
                            _tx.Rollback()
                        End If
                    End If

                    Throw New System.Exception("Erro ao excluir Integracao.RedeAncoraProdutoImagem: " + Char(13) + ex._getMessage())
                End Try
            End Sub

            Overrides Sub Dispose()
                If Not me.Disposed Then
                    me.Disposed = True
                End If
            End Sub

            Sub Free()
                Try
                    If Not me.Disposed Then
                        me.Dispose()
                    End If

                    MyBase.Free()
                Catch ex As Exception
                    Throw New System.Exception("Erro ao liberar RedeAncoraProdutoImagemRepository: " + Char(13) + ex._getMessage())
                End Try
            End Sub

            Sub New()
                MyBase.New()
            End Sub
        End Class
    End Namespace
