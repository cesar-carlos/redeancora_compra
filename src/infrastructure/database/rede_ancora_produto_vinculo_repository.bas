Imports mod_tobject
Imports rede_ancora_produto_vinculo_model
Imports rede_ancora_produto_vinculos_model
Imports rede_ancora_produto_cnas_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_produto_vinculo_repository
    Class RedeAncoraProdutoVinculoRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaProdutoVinculoQualificada()
        End Function

        Private Function SqlSelectCnas() As String
            SqlSelectCnas = $"SELECT Cna FROM {me.Tabela()}"
        End Function

        Private Function SqlSelectBase() As String
            SqlSelectBase = $"SELECT Cna, " +_
            $"       CodProduto, " +_
            $"       CodigoAncora, " +_
            $"       DescricaoAncora, " +_
            $"       CodMarca, " +_
            $"       CodLinha, " +_
            $"       CodFamilia, " +_
            $"       Ativo, " +_
            $"       DataVinculo, " +_
            $"       DataAtualizacao, " +_
            $"       OrigemVinculo, " +_
            $"       Observacao " +_
            $"FROM {me.Tabela()}"
        End Function

        Private Function SqlSelectPorCna() As String
            SqlSelectPorCna = me.SqlSelectBase() + $" WHERE Cna = :Cna"
        End Function

        Private Function SqlSelectAtivoPorCna() As String
            SqlSelectAtivoPorCna = me.SqlSelectBase() + " WHERE Cna = :Cna AND Ativo = " + SqlHelper.SqlText("S")
        End Function

        Private Function SqlSelectPorCodProduto() As String
            SqlSelectPorCodProduto = me.SqlSelectBase() + $" WHERE CodProduto = :CodProduto"
        End Function

        Private Function SqlSelectAtivoPorCodProduto() As String
            SqlSelectAtivoPorCodProduto = me.SqlSelectBase() + " WHERE CodProduto = :CodProduto AND Ativo = " + SqlHelper.SqlText("S")
        End Function

        Private Function SqlSelectAtivos() As String
            SqlSelectAtivos = me.SqlSelectBase() + " WHERE Ativo = " + SqlHelper.SqlText("S") + " ORDER BY Cna"
        End Function

        Private Function SqlSelectVinculadosAtivos() As String
            SqlSelectVinculadosAtivos = me.SqlSelectBase() + " WHERE Ativo = " + SqlHelper.SqlText("S") + " AND CodProduto > 0 ORDER BY CodProduto"
        End Function

        Private Function SqlExistePorCna() As String
            SqlExistePorCna = "SELECT CASE " +_
            "           WHEN COUNT(Cna) > 0 THEN " + SqlHelper.SqlText("true") + " " +_
            "           ELSE " + SqlHelper.SqlText("false") + " " +_
            "       END result " +_
            "FROM " + me.Tabela() + " " +_
            "WHERE Cna = :Cna"
        End Function

        Private Function SqlExisteCodProdutoAtivo() As String
            SqlExisteCodProdutoAtivo = "SELECT CASE " +_
            "           WHEN COUNT(Cna) > 0 THEN " + SqlHelper.SqlText("true") + " " +_
            "           ELSE " + SqlHelper.SqlText("false") + " " +_
            "       END result " +_
            "FROM " + me.Tabela() + " " +_
            "WHERE CodProduto = :CodProduto AND Ativo = " + SqlHelper.SqlText("S") + " AND Cna <> :Cna"
        End Function

        Private Function SqlCampoInteiroOuNull(pParametro As String) As String
            SqlCampoInteiroOuNull = "CASE WHEN :" + pParametro + " = 0 THEN NULL ELSE :" + pParametro + " END"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = $"INSERT INTO {me.Tabela()} (Cna, CodProduto, CodigoAncora, DescricaoAncora, CodMarca, CodLinha, CodFamilia, Ativo, DataVinculo, DataAtualizacao, OrigemVinculo, Observacao) " +_
            $"VALUES (:Cna, " + me.SqlCampoInteiroOuNull("CodProduto") + ", :CodigoAncora, :DescricaoAncora, " + me.SqlCampoInteiroOuNull("CodMarca") + ", " + me.SqlCampoInteiroOuNull("CodLinha") + ", " + me.SqlCampoInteiroOuNull("CodFamilia") + ", :Ativo, :DataVinculo, :DataAtualizacao, :OrigemVinculo, :Observacao)"
        End Function

        Private Function SqlUpdate() As String
            SqlUpdate = $"UPDATE {me.Tabela()} " +_
            $"SET CodProduto = " + me.SqlCampoInteiroOuNull("CodProduto") + ", " +_
            $"    CodigoAncora = :CodigoAncora, " +_
            $"    DescricaoAncora = :DescricaoAncora, " +_
            $"    CodMarca = " + me.SqlCampoInteiroOuNull("CodMarca") + ", " +_
            $"    CodLinha = " + me.SqlCampoInteiroOuNull("CodLinha") + ", " +_
            $"    CodFamilia = " + me.SqlCampoInteiroOuNull("CodFamilia") + ", " +_
            $"    Ativo = :Ativo, " +_
            $"    DataAtualizacao = :DataAtualizacao, " +_
            $"    OrigemVinculo = :OrigemVinculo, " +_
            $"    Observacao = :Observacao " +_
            $"WHERE Cna = :Cna"
        End Function

        Private Function SqlUpdateMetadadosApi() As String
            SqlUpdateMetadadosApi = $"UPDATE {me.Tabela()} " +_
            $"SET CodigoAncora = :CodigoAncora, " +_
            $"    DescricaoAncora = :DescricaoAncora, " +_
            $"    CodMarca = " + me.SqlCampoInteiroOuNull("CodMarca") + ", " +_
            $"    CodLinha = " + me.SqlCampoInteiroOuNull("CodLinha") + ", " +_
            $"    CodFamilia = " + me.SqlCampoInteiroOuNull("CodFamilia") + ", " +_
            $"    Ativo = :Ativo, " +_
            $"    DataAtualizacao = :DataAtualizacao " +_
            $"WHERE Cna = :Cna"
        End Function

        Private Function SqlDesativarPorCna() As String
            SqlDesativarPorCna = $"UPDATE {me.Tabela()} " +_
            $"SET Ativo = " + SqlHelper.SqlText("N") + ", DataAtualizacao = :DataAtualizacao " +_
            $"WHERE Cna = :Cna"
        End Function

        Private Function SqlDesativarPorCodProduto() As String
            SqlDesativarPorCodProduto = $"UPDATE {me.Tabela()} " +_
            $"SET Ativo = " + SqlHelper.SqlText("N") + ", DataAtualizacao = :DataAtualizacao " +_
            $"WHERE CodProduto = :CodProduto"
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraProdutoVinculoModel)
            pItem.Cna = pQuery.Field("Cna").AsInteger
            pItem.CodProduto = pQuery.Field("CodProduto").AsInteger
            pItem.CodigoAncora = pQuery.Field("CodigoAncora").AsString
            pItem.DescricaoAncora = pQuery.Field("DescricaoAncora").AsString
            pItem.CodMarca = pQuery.Field("CodMarca").AsInteger
            pItem.CodLinha = pQuery.Field("CodLinha").AsInteger
            pItem.CodFamilia = pQuery.Field("CodFamilia").AsInteger
            pItem.Ativo = pQuery.Field("Ativo").AsString
            pItem.DataVinculo = pQuery.Field("DataVinculo").AsDateTime
            pItem.DataAtualizacao = pQuery.Field("DataAtualizacao").AsDateTime
            pItem.OrigemVinculo = pQuery.Field("OrigemVinculo").AsString
            pItem.Observacao = pQuery.Field("Observacao").AsString
        End Sub

        Private Sub BindParamsMetadadosApi(pQuery As SQL.Command, pModel As RedeAncoraProdutoVinculoModel)
            pQuery.Param("Cna").AsInteger = pModel.Cna
            pQuery.Param("CodigoAncora").AsString = pModel.CodigoAncora
            pQuery.Param("DescricaoAncora").AsString = pModel.DescricaoAncora
            pQuery.Param("CodMarca").AsInteger = pModel.CodMarca
            pQuery.Param("CodLinha").AsInteger = pModel.CodLinha
            pQuery.Param("CodFamilia").AsInteger = pModel.CodFamilia
            pQuery.Param("Ativo").AsString = pModel.Ativo
            pQuery.Param("DataAtualizacao").AsDateTime = pModel.DataAtualizacao
        End Sub

        Private Sub BindParams(pQuery As SQL.Command, pModel As RedeAncoraProdutoVinculoModel)
            pQuery.Param("Cna").AsInteger = pModel.Cna
            pQuery.Param("CodProduto").AsInteger = pModel.CodProduto
            pQuery.Param("CodigoAncora").AsString = pModel.CodigoAncora
            pQuery.Param("DescricaoAncora").AsString = pModel.DescricaoAncora
            pQuery.Param("CodMarca").AsInteger = pModel.CodMarca
            pQuery.Param("CodLinha").AsInteger = pModel.CodLinha
            pQuery.Param("CodFamilia").AsInteger = pModel.CodFamilia
            pQuery.Param("Ativo").AsString = pModel.Ativo
            pQuery.Param("DataVinculo").AsDateTime = pModel.DataVinculo
            pQuery.Param("DataAtualizacao").AsDateTime = pModel.DataAtualizacao
            pQuery.Param("OrigemVinculo").AsString = pModel.OrigemVinculo
            pQuery.Param("Observacao").AsString = pModel.Observacao
        End Sub

        Private Sub ValidarCodProdutoUnicoAtivo(pModel As RedeAncoraProdutoVinculoModel)
            Dim _query As SQL.Command = NULL

            If Not pModel.IsAtivo() Or Not pModel.IsVinculado() Then
                Exit Sub
            End If

            Try
                _query = SqlHelper.OpenQuery(me.SqlExisteCodProdutoAtivo())
                _query.Param("CodProduto").AsInteger = pModel.CodProduto
                _query.Param("Cna").AsInteger = pModel.Cna
                _query.Open()

                If _query.Field("result").AsBoolean Then
                    Throw New System.Exception("Produto.CodProduto " + pModel.CodProduto.ToString() + " ja vinculado a outro CNA ativo")
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                Throw ex
            End Try
        End Sub

        Function ExistePorCna(pCna As Integer) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlExistePorCna())
                _query.Param("Cna").AsInteger = pCna
                _query.Open()
                ExistePorCna = _query.Field("result").AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao verificar Integracao.RedeAncoraProdutoVinculo por Cna", "9161")
            End Try
        End Function

        Function ExisteCodProdutoAtivo(pCodProduto As Integer, pIgnorarCna As Integer) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlExisteCodProdutoAtivo())
                _query.Param("CodProduto").AsInteger = pCodProduto
                _query.Param("Cna").AsInteger = pIgnorarCna
                _query.Open()
                ExisteCodProdutoAtivo = _query.Field("result").AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao verificar CodProduto em Integracao.RedeAncoraProdutoVinculo", "9166")
            End Try
        End Function

        Function TryObterPorCna(pCna As Integer, pItem As RedeAncoraProdutoVinculoModel) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCna())
                _query.Param("Cna").AsInteger = pCna
                _query.Open()

                If _query.EOF Then
                    TryObterPorCna = False
                Else
                    me.Mapear(_query, pItem)
                    TryObterPorCna = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar Integracao.RedeAncoraProdutoVinculo por Cna", "9162")
            End Try
        End Function

        Function TryObterAtivoPorCna(pCna As Integer, pItem As RedeAncoraProdutoVinculoModel) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectAtivoPorCna())
                _query.Param("Cna").AsInteger = pCna
                _query.Open()

                If _query.EOF Then
                    TryObterAtivoPorCna = False
                Else
                    me.Mapear(_query, pItem)
                    TryObterAtivoPorCna = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar produto Ancora ativo por Cna", "9164")
            End Try
        End Function

        Function ObterPorCna(pCna As Integer) As RedeAncoraProdutoVinculoModel
            Dim _item As New RedeAncoraProdutoVinculoModel()

            If Not me.TryObterPorCna(pCna, _item) Then
                _item.Free()
                Throw New System.Exception("Integracao.RedeAncoraProdutoVinculo nao encontrado para CNA " + pCna.ToString() + ". Codigo: 9163")
            End If

            ObterPorCna = _item
        End Function

        Function TryObterPorCodProduto(pCodProduto As Integer, pItem As RedeAncoraProdutoVinculoModel) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCodProduto())
                _query.Param("CodProduto").AsInteger = pCodProduto
                _query.Open()

                If _query.EOF Then
                    TryObterPorCodProduto = False
                Else
                    me.Mapear(_query, pItem)
                    TryObterPorCodProduto = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar Integracao.RedeAncoraProdutoVinculo por CodProduto", "9169")
            End Try
        End Function

        Function TryObterAtivoPorCodProduto(pCodProduto As Integer, pItem As RedeAncoraProdutoVinculoModel) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectAtivoPorCodProduto())
                _query.Param("CodProduto").AsInteger = pCodProduto
                _query.Open()

                If _query.EOF Then
                    TryObterAtivoPorCodProduto = False
                Else
                    me.Mapear(_query, pItem)
                    TryObterAtivoPorCodProduto = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar vinculo ativo por CodProduto", "9167")
            End Try
        End Function

        Function ObterAtivoPorCodProduto(pCodProduto As Integer) As RedeAncoraProdutoVinculoModel
            Dim _item As New RedeAncoraProdutoVinculoModel()

            If Not me.TryObterAtivoPorCodProduto(pCodProduto, _item) Then
                _item.Free()
                Throw New System.Exception("Vinculo ativo nao encontrado para Produto.CodProduto " + pCodProduto.ToString() + ". Codigo: 9168")
            End If

            ObterAtivoPorCodProduto = _item
        End Function

        Function ObterPorCodProduto(pCodProduto As Integer) As RedeAncoraProdutoVinculoModel
            ObterPorCodProduto = me.ObterAtivoPorCodProduto(pCodProduto)
        End Function

        Function ListarTodosCnas() As RedeAncoraProdutoCnasModel
            Dim _result As New RedeAncoraProdutoCnasModel()
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectCnas())
                _query.Open()

                While Not _query.EOF
                    _result.Push(_query.Field("Cna").AsInteger)
                    _query.Next()
                Wend

                SqlHelper.ReleaseQuery(_query)
                ListarTodosCnas = _result
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _result.Free()
                SqlHelper.HandleQueryError(ex, "Erro ao listar CNAs de Integracao.RedeAncoraProdutoVinculo", "9170")
            End Try
        End Function

        Function ListarAtivos() As RedeAncoraProdutoVinculosModel
            ListarAtivos = me.ListarPorSql(me.SqlSelectAtivos())
        End Function

        Function ListarVinculadosAtivos() As RedeAncoraProdutoVinculosModel
            ListarVinculadosAtivos = me.ListarPorSql(me.SqlSelectVinculadosAtivos())
        End Function

        Private Function ListarPorSql(pSql As String) As RedeAncoraProdutoVinculosModel
            Dim _result As New RedeAncoraProdutoVinculosModel()
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(pSql)
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraProdutoVinculoModel()
                    me.Mapear(_query, _item)
                    _result.Push(_item)
                    _query.Next()
                Wend

                SqlHelper.ReleaseQuery(_query)
                ListarPorSql = _result
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _result.Free()
                SqlHelper.HandleQueryError(ex, "Erro ao listar Integracao.RedeAncoraProdutoVinculo", "9165")
            End Try
        End Function

        Sub Salvar(pModel As RedeAncoraProdutoVinculoModel)
            me.SalvarComTransacao(pModel, True)
        End Sub

        Sub SalvarSemTransacao(pModel As RedeAncoraProdutoVinculoModel)
            me.SalvarComTransacao(pModel, False)
        End Sub

        Sub AtualizarMetadadosApi(pModel As RedeAncoraProdutoVinculoModel)
            me.AtualizarMetadadosApiComTransacao(pModel, True)
        End Sub

        Sub AtualizarMetadadosApiSemTransacao(pModel As RedeAncoraProdutoVinculoModel)
            me.AtualizarMetadadosApiComTransacao(pModel, False)
        End Sub

        Private Sub SalvarComTransacao(pModel As RedeAncoraProdutoVinculoModel, pUsarTransacao As Boolean)
            If me.ExistePorCna(pModel.Cna) Then
                me.AtualizarComTransacao(pModel, pUsarTransacao)
            Else
                me.InserirComTransacao(pModel, pUsarTransacao)
            End If
        End Sub

        Sub DesativarPorCna(pCna As Integer)
            me.DesativarPorCnaComTransacao(pCna, True)
        End Sub

        Sub DesativarPorCnaSemTransacao(pCna As Integer)
            me.DesativarPorCnaComTransacao(pCna, False)
        End Sub

        Private Sub DesativarPorCnaComTransacao(pCna As Integer, pUsarTransacao As Boolean)
            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraProdutoVinculo Desativar Cna")
                End If

                _query = SqlHelper.OpenQuery(me.SqlDesativarPorCna())
                _query.Param("Cna").AsInteger = pCna
                _query.Param("DataAtualizacao").AsDateTime = DateTime()
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    _tx.AutoCommit()
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    If Assigned(_tx) Then
                        _tx.Rollback()
                    End If
                End If

                Throw New System.Exception("Erro ao desativar Integracao.RedeAncoraProdutoVinculo por Cna: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Private Sub InserirComTransacao(pModel As RedeAncoraProdutoVinculoModel, pUsarTransacao As Boolean)
            pModel.Validate()
            me.ValidarCodProdutoUnicoAtivo(pModel)
            pModel.DataVinculo = DateTime()
            pModel.DataAtualizacao = DateTime()

            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraProdutoVinculo Insert")
                End If

                _query = SqlHelper.OpenQuery(me.SqlInsert())
                me.BindParams(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    _tx.AutoCommit()
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    If Assigned(_tx) Then
                        _tx.Rollback()
                    End If
                End If

                Throw New System.Exception("Erro ao inserir Integracao.RedeAncoraProdutoVinculo: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Private Sub AtualizarComTransacao(pModel As RedeAncoraProdutoVinculoModel, pUsarTransacao As Boolean)
            pModel.Validate()
            me.ValidarCodProdutoUnicoAtivo(pModel)
            pModel.DataAtualizacao = DateTime()

            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraProdutoVinculo Update")
                End If

                _query = SqlHelper.OpenQuery(me.SqlUpdate())
                me.BindParams(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    _tx.AutoCommit()
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    If Assigned(_tx) Then
                        _tx.Rollback()
                    End If
                End If

                Throw New System.Exception("Erro ao atualizar Integracao.RedeAncoraProdutoVinculo: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Private Sub AtualizarMetadadosApiComTransacao(pModel As RedeAncoraProdutoVinculoModel, pUsarTransacao As Boolean)
            pModel.Validate()
            pModel.DataAtualizacao = DateTime()

            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraProdutoVinculo Update API")
                End If

                _query = SqlHelper.OpenQuery(me.SqlUpdateMetadadosApi())
                me.BindParamsMetadadosApi(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    _tx.AutoCommit()
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If pUsarTransacao Then
                    If Assigned(_tx) Then
                        _tx.Rollback()
                    End If
                End If

                Throw New System.Exception("Erro ao atualizar metadados API em Integracao.RedeAncoraProdutoVinculo: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub Inserir(pModel As RedeAncoraProdutoVinculoModel)
            me.InserirComTransacao(pModel, True)
        End Sub

        Sub Atualizar(pModel As RedeAncoraProdutoVinculoModel)
            me.AtualizarComTransacao(pModel, True)
        End Sub

        Sub DesativarPorCodProduto(pCodProduto As Integer)
            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL

            Try
                _tx.StartTransaction("Integracao.RedeAncoraProdutoVinculo Desativar CodProduto")
                _query = SqlHelper.OpenQuery(me.SqlDesativarPorCodProduto())
                _query.Param("CodProduto").AsInteger = pCodProduto
                _query.Param("DataAtualizacao").AsDateTime = DateTime()
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _tx.Rollback()
                Throw New System.Exception("Erro ao desativar Integracao.RedeAncoraProdutoVinculo por CodProduto: " + Char(13) + ex._getMessage())
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
                Throw New System.Exception("Erro ao liberar RedeAncoraProdutoVinculoRepository: " + Char(13) + ex._getMessage())
            End Try
        End Sub
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
