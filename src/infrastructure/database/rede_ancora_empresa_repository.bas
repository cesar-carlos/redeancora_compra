Imports mod_tobject
Imports rede_ancora_empresa_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_empresa_repository
    Class RedeAncoraEmpresaRepository
        Inherits TTObject

        Private Function Tabela() As String
            Tabela = IntegracaoSchema.TabelaEmpresaQualificada()
        End Function

        Private Function SqlSelectPorCodUsuario() As String
            SqlSelectPorCodUsuario = $"SELECT CodEmpresaAncora, " +_
            $"       CodUsuario, " +_
            $"       CodInterno, " +_
            $"       RazaoSocial, " +_
            $"       NomeFantasia, " +_
            $"       Cnpj, " +_
            $"       CodEstado, " +_
            $"       CodCentroDistribuicaoPreferencial, " +_
            $"       CpfResponsavel, " +_
            $"       Bloqueado, " +_
            $"       MotivosBloqueio, " +_
            $"       SaldoAtual, " +_
            $"       LimiteCredito, " +_
            $"       LimiteUtilizado, " +_
            $"       IdCarrinhoAtual, " +_
            $"       Marketplace, " +_
            $"       Permissoes " +_
            $"FROM {me.Tabela()} " +_
            $"WHERE CodUsuario = :CodUsuario"
        End Function

        Private Function SqlExistePorCodUsuario() As String
            SqlExistePorCodUsuario = "SELECT CASE " +_
            "           WHEN COUNT(CodUsuario) > 0 THEN " + SqlHelper.SqlText("true") + " " +_
            "           ELSE " + SqlHelper.SqlText("false") + " " +_
            "       END result " +_
            "FROM " + me.Tabela() + " " +_
            "WHERE CodUsuario = :CodUsuario"
        End Function

        Private Function SqlInsert() As String
            SqlInsert = $"INSERT INTO {me.Tabela()} (CodEmpresaAncora, CodUsuario, CodInterno, RazaoSocial, NomeFantasia, Cnpj, CodEstado, CodCentroDistribuicaoPreferencial, CpfResponsavel, Bloqueado, MotivosBloqueio, SaldoAtual, LimiteCredito, LimiteUtilizado, IdCarrinhoAtual, Marketplace, Permissoes) " +_
            $"VALUES (:CodEmpresaAncora, :CodUsuario, :CodInterno, :RazaoSocial, :NomeFantasia, :Cnpj, :CodEstado, :CodCentroDistribuicaoPreferencial, :CpfResponsavel, :Bloqueado, :MotivosBloqueio, :SaldoAtual, :LimiteCredito, :LimiteUtilizado, :IdCarrinhoAtual, :Marketplace, :Permissoes)"
        End Function

        Private Function SqlUpdate() As String
            SqlUpdate = $"UPDATE {me.Tabela()} " +_
            $"SET CodEmpresaAncora = :CodEmpresaAncora, " +_
            $"    CodInterno = :CodInterno, " +_
            $"    RazaoSocial = :RazaoSocial, " +_
            $"    NomeFantasia = :NomeFantasia, " +_
            $"    Cnpj = :Cnpj, " +_
            $"    CodEstado = :CodEstado, " +_
            $"    CodCentroDistribuicaoPreferencial = :CodCentroDistribuicaoPreferencial, " +_
            $"    CpfResponsavel = :CpfResponsavel, " +_
            $"    Bloqueado = :Bloqueado, " +_
            $"    MotivosBloqueio = :MotivosBloqueio, " +_
            $"    SaldoAtual = :SaldoAtual, " +_
            $"    LimiteCredito = :LimiteCredito, " +_
            $"    LimiteUtilizado = :LimiteUtilizado, " +_
            $"    IdCarrinhoAtual = :IdCarrinhoAtual, " +_
            $"    Marketplace = :Marketplace, " +_
            $"    Permissoes = :Permissoes " +_
            $"WHERE CodUsuario = :CodUsuario"
        End Function

        Private Sub Mapear(pQuery As SQL.Command, pItem As RedeAncoraEmpresaModel)
            pItem.CodEmpresaAncora = pQuery.Field("CodEmpresaAncora").AsInteger
            pItem.CodUsuario = pQuery.Field("CodUsuario").AsInteger
            pItem.CodInterno = pQuery.Field("CodInterno").AsInteger
            pItem.RazaoSocial = pQuery.Field("RazaoSocial").AsString
            pItem.NomeFantasia = pQuery.Field("NomeFantasia").AsString
            pItem.Cnpj = pQuery.Field("Cnpj").AsString
            pItem.CodEstado = pQuery.Field("CodEstado").AsInteger
            pItem.CodCentroDistribuicaoPreferencial = pQuery.Field("CodCentroDistribuicaoPreferencial").AsInteger
            pItem.CpfResponsavel = pQuery.Field("CpfResponsavel").AsString
            pItem.Bloqueado = pQuery.Field("Bloqueado").AsString
            pItem.MotivosBloqueio = pQuery.Field("MotivosBloqueio").AsString
            pItem.SaldoAtual = pQuery.Field("SaldoAtual").AsFloat
            pItem.LimiteCredito = pQuery.Field("LimiteCredito").AsFloat
            pItem.LimiteUtilizado = pQuery.Field("LimiteUtilizado").AsFloat
            pItem.IdCarrinhoAtual = pQuery.Field("IdCarrinhoAtual").AsString
            pItem.Marketplace = pQuery.Field("Marketplace").AsString
            pItem.Permissoes = pQuery.Field("Permissoes").AsString
        End Sub

        Private Sub BindParams(pQuery As SQL.Command, pModel As RedeAncoraEmpresaModel)
            pQuery.Param("CodEmpresaAncora").AsInteger = pModel.CodEmpresaAncora
            pQuery.Param("CodUsuario").AsInteger = pModel.CodUsuario
            pQuery.Param("CodInterno").AsInteger = pModel.CodInterno
            pQuery.Param("RazaoSocial").AsString = pModel.RazaoSocial
            pQuery.Param("NomeFantasia").AsString = pModel.NomeFantasia
            pQuery.Param("Cnpj").AsString = pModel.Cnpj
            pQuery.Param("CodEstado").AsInteger = pModel.CodEstado
            pQuery.Param("CodCentroDistribuicaoPreferencial").AsInteger = pModel.CodCentroDistribuicaoPreferencial
            pQuery.Param("CpfResponsavel").AsString = pModel.CpfResponsavel
            pQuery.Param("Bloqueado").AsString = pModel.Bloqueado
            pQuery.Param("MotivosBloqueio").AsString = pModel.MotivosBloqueio
            pQuery.Param("SaldoAtual").AsFloat = pModel.SaldoAtual
            pQuery.Param("LimiteCredito").AsFloat = pModel.LimiteCredito
            pQuery.Param("LimiteUtilizado").AsFloat = pModel.LimiteUtilizado
            pQuery.Param("IdCarrinhoAtual").AsString = pModel.IdCarrinhoAtual
            pQuery.Param("Marketplace").AsString = pModel.Marketplace
            pQuery.Param("Permissoes").AsString = pModel.Permissoes
        End Sub

        Function ExistePorCodUsuario(pCodUsuario As Integer) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlExistePorCodUsuario())
                _query.Param("CodUsuario").AsInteger = pCodUsuario
                _query.Open()
                ExistePorCodUsuario = _query.Field("result").AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao verificar Integracao.RedeAncoraEmpresa", "9101")
            End Try
        End Function

        Function TryObterPorCodUsuario(pCodUsuario As Integer, pItem As RedeAncoraEmpresaModel) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectPorCodUsuario())
                _query.Param("CodUsuario").AsInteger = pCodUsuario
                _query.Open()

                If _query.EOF Then
                    TryObterPorCodUsuario = False
                Else
                    me.Mapear(_query, pItem)
                    TryObterPorCodUsuario = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Erro ao carregar Integracao.RedeAncoraEmpresa", "9102")
            End Try
        End Function

        Function ObterPorCodUsuario(pCodUsuario As Integer) As RedeAncoraEmpresaModel
            Dim _item As New RedeAncoraEmpresaModel

            If Not me.TryObterPorCodUsuario(pCodUsuario, _item) Then
                Throw New System.Exception("Integracao.RedeAncoraEmpresa nao encontrada. Codigo: 9103")
            End If

            ObterPorCodUsuario = _item
        End Function

        Sub Inserir(pModel As RedeAncoraEmpresaModel)
            pModel.Validate()

            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL

            Try
                _tx.StartTransaction("Integracao.RedeAncoraEmpresa Insert")
                _query = SqlHelper.OpenQuery(me.SqlInsert())
                me.BindParams(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _tx.Rollback()
                Throw New System.Exception("Erro ao inserir Integracao.RedeAncoraEmpresa: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub Atualizar(pModel As RedeAncoraEmpresaModel)
            pModel.Validate()

            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL

            Try
                _tx.StartTransaction("Integracao.RedeAncoraEmpresa Update")
                _query = SqlHelper.OpenQuery(me.SqlUpdate())
                me.BindParams(_query, pModel)
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _tx.Rollback()
                Throw New System.Exception("Erro ao atualizar Integracao.RedeAncoraEmpresa: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub Salvar(pModel As RedeAncoraEmpresaModel)
            If me.ExistePorCodUsuario(pModel.CodUsuario) Then
                me.Atualizar(pModel)
            Else
                me.Inserir(pModel)
            End If
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
                Throw New System.Exception("Erro ao liberar RedeAncoraEmpresaRepository: " + Char(13) + ex._getMessage())
            End Try
        End Sub
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
