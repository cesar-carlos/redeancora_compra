Imports mod_tobject
Imports rede_ancora_produto_preco_estoque_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_produto_preco_estoque_repository
    Class RedeAncoraProdutoPrecoEstoqueRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaProdutoPrecoEstoqueQualificada()
        End Function

        Private Function SqlExistePorChave() As String
            SqlExistePorChave = "SELECT CASE " +_
                "           WHEN COUNT(Cna) > 0 THEN " & SqlHelper.SqlText("true") & " " +_
                "           ELSE " & SqlHelper.SqlText("false") & " " +_
                "       END result " +_
                "FROM " & me.Tabela() & " " +_
                "WHERE Cna = :Cna AND CodCentroDistribuicao = :CodCentroDistribuicao"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = "INSERT INTO " & me.Tabela() & " (" +_
                "Cna, CodCentroDistribuicao, CodEstado, QtdDisponivel, QtdProjetada, " +_
                "PrecoTabela, StTabela, PrecoCrossDocking, PrecoCompraJunto, DataAtualizacao) " +_
                "VALUES (:Cna, :CodCentroDistribuicao, :CodEstado, :QtdDisponivel, :QtdProjetada, " +_
                ":PrecoTabela, :StTabela, :PrecoCrossDocking, :PrecoCompraJunto, :DataAtualizacao)"
        End Function

        Private Function SqlUpdate() As String
            SqlUpdate = "UPDATE " & me.Tabela() & " SET " +_
                "CodEstado = :CodEstado, QtdDisponivel = :QtdDisponivel, QtdProjetada = :QtdProjetada, " +_
                "PrecoTabela = :PrecoTabela, StTabela = :StTabela, PrecoCrossDocking = :PrecoCrossDocking, " +_
                "PrecoCompraJunto = :PrecoCompraJunto, DataAtualizacao = :DataAtualizacao " +_
                "WHERE Cna = :Cna AND CodCentroDistribuicao = :CodCentroDistribuicao"
        End Function

        Function ExistePorChave(pCna As Integer, pCodCentroDistribuicao As Integer) As Boolean
            Dim _query As SQL.Command = NULL
            Dim _ok As Boolean = False

            Try
                _query = SqlHelper.OpenQuery(me.SqlExistePorChave())
                _query.Param("Cna").AsInteger = pCna
                _query.Param("CodCentroDistribuicao").AsInteger = pCodCentroDistribuicao
                _query.Open()
                _ok = _query.Field("result").AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao verificar Integracao.RedeAncoraProdutoPrecoEstoque", "9181")
            End Try

            ExistePorChave = _ok
        End Function

        Sub Salvar(pModel As RedeAncoraProdutoPrecoEstoqueModel)
            me.SalvarComTransacao(pModel, True)
        End Sub

        Sub SalvarSemTransacao(pModel As RedeAncoraProdutoPrecoEstoqueModel)
            me.SalvarComTransacao(pModel, False)
        End Sub

        Private Sub SalvarComTransacao(pModel As RedeAncoraProdutoPrecoEstoqueModel, pUsarTransacao As Boolean)
            If me.ExistePorChave(pModel.Cna, pModel.CodCentroDistribuicao) Then
                me.AtualizarComTransacao(pModel, pUsarTransacao)
            Else
                me.InserirComTransacao(pModel, pUsarTransacao)
            End If
        End Sub

        Private Sub ExigirChave(pModel As RedeAncoraProdutoPrecoEstoqueModel)
            If Not Assigned(pModel) Then
                Throw New System.Exception("Preco e estoque nao informado")
            End If

            If pModel.Cna <= 0 Then
                Throw New System.Exception("Cna invalido em Integracao.RedeAncoraProdutoPrecoEstoque")
            End If

            If pModel.CodCentroDistribuicao <= 0 Then
                Throw New System.Exception("CodCentroDistribuicao invalido em Integracao.RedeAncoraProdutoPrecoEstoque")
            End If
        End Sub

        Private Sub BindParams(pQuery As SQL.Command, pModel As RedeAncoraProdutoPrecoEstoqueModel)
            pQuery.Param("Cna").AsInteger = pModel.Cna
            pQuery.Param("CodCentroDistribuicao").AsInteger = pModel.CodCentroDistribuicao
            pQuery.Param("CodEstado").AsInteger = pModel.CodEstado
            pQuery.Param("QtdDisponivel").AsInteger = pModel.QtdDisponivel
            pQuery.Param("QtdProjetada").AsInteger = pModel.QtdProjetada
            pQuery.Param("PrecoTabela").AsFloat = pModel.PrecoTabela
            pQuery.Param("StTabela").AsFloat = pModel.StTabela
            pQuery.Param("PrecoCrossDocking").AsFloat = pModel.PrecoCrossDocking
            pQuery.Param("PrecoCompraJunto").AsFloat = pModel.PrecoCompraJunto
            pQuery.Param("DataAtualizacao").AsDateTime = pModel.DataAtualizacao
        End Sub

        Private Sub InserirComTransacao(pModel As RedeAncoraProdutoPrecoEstoqueModel, pUsarTransacao As Boolean)
            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            me.ExigirChave(pModel)
            pModel.DataAtualizacao = DateTime()

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraProdutoPrecoEstoque Insert")
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

                Throw New System.Exception("Erro ao inserir Integracao.RedeAncoraProdutoPrecoEstoque: " & Char(13) & ex._getMessage())
            End Try
        End Sub

        Private Sub AtualizarComTransacao(pModel As RedeAncoraProdutoPrecoEstoqueModel, pUsarTransacao As Boolean)
            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            me.ExigirChave(pModel)
            pModel.DataAtualizacao = DateTime()

            Try
                If pUsarTransacao Then
                    _tx = Transaction.Instance()
                    _tx.StartTransaction("Integracao.RedeAncoraProdutoPrecoEstoque Update")
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

                Throw New System.Exception("Erro ao atualizar Integracao.RedeAncoraProdutoPrecoEstoque: " & Char(13) & ex._getMessage())
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
