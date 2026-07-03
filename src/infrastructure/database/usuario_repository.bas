Imports mod_tobject
Imports usuario_model
Imports usuarios_model
Imports sql_helper

Namespace usuario_repository
    Class UsuarioRepository
        Inherits TTObject

        Private Function SqlSystemVersion() As String
            Dim _dot As String = SqlHelper.SqlText(".")

            SqlSystemVersion = "(SELECT TOP 1 " +_
            "CONVERT(VARCHAR(2), Versao) + " + _dot + " + " +_
            "CONVERT(VARCHAR(2), MenorVersao) + " + _dot + " + " +_
            "CONVERT(VARCHAR(5), ReleaseDaVersao) + " + _dot + " + " +_
            "CONVERT(VARCHAR(5), BuilderDaVersao) " +_
            "FROM HistoricoAtualizacaoVersao ORDER BY id DESC)"
        End Function

        Private Function SqlDatabaseType() As String
            SqlDatabaseType = "(SELECT TOP 1 CASE WHEN LEN(@@VERSION) <= 30 THEN " + SqlHelper.SqlText("SyBase") + " ELSE " + SqlHelper.SqlText("SQL Server") + " END)"
        End Function

        Private Function SqlUsuarioSubquery(pFilterByUserId As Boolean) As String
            Dim _sql As String
            _sql = $"(SELECT " +_
            $"CodUsuario, " +_
            $"NomeLegivel NomeUsuario, " +_
            $"Senha, " +_
            $"{me.SqlSystemVersion()} VersaoSistema, " +_
            $"{me.SqlDatabaseType()} Base, " +_
            $"(SELECT CodContaFinanceira FROM CaixaOperador WHERE CodUsuario = Usuario.CodUsuario) CodContaFinanceira " +_
            $"FROM Usuario"
            If pFilterByUserId Then
                _sql = _sql + $" WHERE CodUsuario = :CodUsuario"
            End If
            _sql = _sql + $") Sub"
            SqlUsuarioSubquery = _sql
        End Function

        Private Function SqlSelectUsuarios(pFilterByUserId As Boolean) As String
            Dim _sql As String
            _sql = $"SELECT " +_
            $"(SELECT TOP 1 CodEmpresa FROM SessaoConexao WHERE CodUsuario = Sub.CodUsuario) CodEmpresa, " +_
            $"(SELECT TOP 1 CodFilial FROM SessaoConexao WHERE CodUsuario = Sub.CodUsuario) CodFilial, " +_
            $"(SELECT TOP 1 CONVERT(VARCHAR(50), CodSessaoConexao) FROM SessaoConexao WHERE CodUsuario = Sub.CodUsuario ORDER BY CodSessaoConexao DESC) SessionId, " +_
            $"Sub.CodUsuario, " +_
            $"Sub.NomeUsuario, " +_
            $"Sub.Senha, " +_
            $"Sub.CodContaFinanceira, " +_
            $"(SELECT TOP 1 CodPeriodoCaixa FROM PeriodoCaixa WHERE CodContaFinanceira = Sub.CodContaFinanceira ORDER BY CodPeriodoCaixa DESC) CodPeriodoCaixa, " +_
            $"(SELECT TOP 1 CASE WHEN DataAbertura IS NOT NULL AND DataFechamento IS NULL THEN " + SqlHelper.SqlText("Aberto") + " ELSE " + SqlHelper.SqlText("Fechado") + " END " +_
            $" FROM PeriodoCaixa WHERE CodContaFinanceira = Sub.CodContaFinanceira ORDER BY CodPeriodoCaixa DESC) StatusPeriodoCaixa, " +_
            $"COALESCE((SELECT TOP 1 CodSetorEstoque FROM CaixaOperador WHERE CodUsuario = Sub.CodUsuario), 0) CodSetorEstoque, " +_
            $"COALESCE((SELECT TOP 1 CodSetorConferencia FROM CaixaOperador WHERE CodUsuario = Sub.CodUsuario), 0) CodSetorConferencia, " +_
            $"(SELECT TOP 1 EstacaoTrabalho FROM SessaoConexao WHERE CodUsuario = Sub.CodUsuario) MachineName, " +_
            $"(SELECT TOP 1 NomeUsuario FROM SessaoConexao WHERE CodUsuario = Sub.CodUsuario) UserName, " +_
            $"Sub.VersaoSistema, " +_
            $"Sub.Base " +_
            $"FROM {me.SqlUsuarioSubquery(pFilterByUserId)}"
            If pFilterByUserId Then
                _sql = _sql + $" WHERE Sub.CodUsuario = :CodUsuario"
            End If
            SqlSelectUsuarios = _sql
        End Function

        Private Function SqlLoggedUsuario() As String
            SqlLoggedUsuario = $"SELECT " +_
            $"{me.SqlSystemVersion()} VersaoSistema, " +_
            $"{me.SqlDatabaseType()} Base, " +_
            $"(SELECT TOP 1 CodContaFinanceira FROM PeriodoCaixa WHERE CodPeriodoCaixa = :CodPeriodoCaixa) CodContaFinanceira, " +_
            $"(SELECT TOP 1 Senha FROM Usuario WHERE CodUsuario = :CodUsuario) Senha, " +_
            $"(SELECT TOP 1 CASE WHEN pc.DataAbertura IS NOT NULL AND pc.DataFechamento IS NULL THEN " + SqlHelper.SqlText("Aberto") + " ELSE " + SqlHelper.SqlText("Fechado") + " END " +_
            $" FROM PeriodoCaixa pc WHERE CodPeriodoCaixa = :CodPeriodoCaixa) StatusPeriodoCaixa, " +_
            $"COALESCE((SELECT TOP 1 CodSetorEstoque FROM CaixaOperador WHERE CodUsuario = :CodUsuario), 0) CodSetorEstoque, " +_
            $"COALESCE((SELECT TOP 1 CodSetorConferencia FROM CaixaOperador WHERE CodUsuario = :CodUsuario), 0) CodSetorConferencia, " +_
            $"(SELECT TOP 1 CONVERT(VARCHAR(50), CodSessaoConexao) FROM SessaoConexao WHERE CodUsuario = :CodUsuario ORDER BY CodSessaoConexao DESC) SessionId, " +_
            $"(SELECT TOP 1 EstacaoTrabalho FROM SessaoConexao WHERE CodUsuario = :CodUsuario ORDER BY CodSessaoConexao DESC) EstacaoTrabalho"
        End Function

        Private Sub MapUsuario(pQuery As SQL.Command, pItem As UsuarioModel)
            pItem.CompanyCode = pQuery.Field("CodEmpresa").AsInteger
            pItem.BranchCode = pQuery.Field("CodFilial").AsInteger
            pItem.SessionId = pQuery.Field("SessionId").AsString
            pItem.UserId = pQuery.Field("CodUsuario").AsInteger
            pItem.UserName = pQuery.Field("NomeUsuario").AsString
            pItem.Password = pQuery.Field("Senha").AsString
            pItem.FinancialAccountCode = pQuery.Field("CodContaFinanceira").AsString
            pItem.CashPeriodCode = pQuery.Field("CodPeriodoCaixa").AsInteger
            pItem.CashPeriodStatus = pQuery.Field("StatusPeriodoCaixa").AsString
            pItem.StockSectorCode = pQuery.Field("CodSetorEstoque").AsInteger
            pItem.ConferenceSectorCode = pQuery.Field("CodSetorConferencia").AsInteger
            pItem.ComputerName = pQuery.Field("MachineName").AsString
            pItem.WindowsUser = pQuery.Field("UserName").AsString
            pItem.SystemVersion = pQuery.Field("VersaoSistema").AsString
            pItem.Database = pQuery.Field("Base").AsString
        End Sub

        Private Sub MapLoggedUsuario(pQuery As SQL.Command, pItem As UsuarioModel)
            pItem.CompanyCode = data7.CodEmpresa()
            pItem.BranchCode = data7.CodFilial()
            pItem.UserId = data7.CodUsuario()
            pItem.UserName = data7.NomeUsuario()
            pItem.CashPeriodCode = data7.CodPeriodoCaixa()
            pItem.SessionId = pQuery.Field("SessionId").AsString
            pItem.Password = pQuery.Field("Senha").AsString
            pItem.FinancialAccountCode = pQuery.Field("CodContaFinanceira").AsString
            pItem.CashPeriodStatus = pQuery.Field("StatusPeriodoCaixa").AsString
            pItem.StockSectorCode = pQuery.Field("CodSetorEstoque").AsInteger
            pItem.ConferenceSectorCode = pQuery.Field("CodSetorConferencia").AsInteger
            pItem.ComputerName = pQuery.Field("EstacaoTrabalho").AsString
            pItem.WindowsUser = Environment.UserName()
            pItem.SystemVersion = pQuery.Field("VersaoSistema").AsString
            pItem.Database = pQuery.Field("Base").AsString
        End Sub

        Function GetLoggedUsuario() As UsuarioModel
            Dim _item As New UsuarioModel
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlLoggedUsuario())
                _query.Param("CodPeriodoCaixa").AsInteger = data7.CodPeriodoCaixa
                _query.Param("CodUsuario").AsInteger = data7.CodUsuario
                _query.Open()
                me.MapLoggedUsuario(_query, _item)
                GetLoggedUsuario = _item
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Error loading logged usuario", "7787")
            End Try
        End Function

        Function TryGetByUserId(pUserId As Integer, pItem As UsuarioModel) As Boolean
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectUsuarios(True))
                _query.Param("CodUsuario").AsInteger = pUserId
                _query.Open()

                If _query.EOF Then
                    TryGetByUserId = False
                Else
                    me.MapUsuario(_query, pItem)
                    TryGetByUserId = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Error loading usuario", "516")
            End Try
        End Function

        Function GetByUserId(pUserId As Integer) As UsuarioModel
            Dim _item As New UsuarioModel

            If Not me.TryGetByUserId(pUserId, _item) Then
                Throw New System.Exception("Usuario not found. Code: 517")
            End If

            GetByUserId = _item
        End Function

        Function GetAll() As UsuariosModel
            Dim _items As New UsuariosModel
            Dim _query As SQL.Command = NULL

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectUsuarios(False))
                _query.Open()

                While Not _query.EOF
                    Dim _item As New UsuarioModel
                    me.MapUsuario(_query, _item)
                    _items.Push(_item)
                    _query.Next()
                    Wend

                    GetAll = _items
                    SqlHelper.ReleaseQuery(_query)
                Catch ex As Exception
                    SqlHelper.ReleaseQuery(_query)
                    SqlHelper.HandleQueryError(ex, "Error loading usuarios", "522")
                End Try
            End Function

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
                    Throw New System.Exception("Error freeing UsuarioRepository: " + Char(13) + ex._getMessage())
                End Try
            End Sub
       Sub New()
          MyBase.New()
       End Sub

        End Class
    End Namespace
