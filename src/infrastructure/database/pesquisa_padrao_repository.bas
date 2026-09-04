Imports mod_tobject
Imports pesquisa_padrao_model
Imports pesquisas_padrao_model
Imports sql_helper

Namespace pesquisa_padrao_repository
    Class PesquisaPadraoRepository
        Inherits TTObject

        Private Function SqlSelectColumns() As String
            SqlSelectColumns = $"t.CodTabela, " +_
                $"       t.NomeSchema, " +_
                $"       t.Nome NomeTabela, " +_
                $"       pp.CodPesquisaPadrao"
        End Function

        Private Function SqlFromWhere() As String
            SqlFromWhere = $"FROM Tabela t " +_
                $"INNER JOIN PesquisaPadrao pp ON " +_
                $"   pp.CodTabela = t.CodTabela " +_
                $"WHERE LOWER(t.Nome) LIKE LOWER(:NomeTabela) " +_
                $"  AND COALESCE(t.NomeSchema, " + SqlHelper.SqlText("dbo") + ") LIKE :NomeSchema"
        End Function

        Private Function SqlSelectByTableName() As String
            SqlSelectByTableName = $"SELECT TOP (1) " +_
                $"       {me.SqlSelectColumns()} " +_
                $"{me.SqlFromWhere()}"
        End Function

        Private Function SqlListByTableName() As String
            SqlListByTableName = $"SELECT " +_
                $"       {me.SqlSelectColumns()} " +_
                $"{me.SqlFromWhere()}"
        End Function

        Private Function ResolveSchemaName(pSchemaName As String) As String
            If pSchemaName = "" Then
                ResolveSchemaName = "dbo"
            Else
                ResolveSchemaName = pSchemaName
            End If
        End Function

        Private Sub BindTableNameParams(pQuery As SQL.Command, pTableName As String, pSchemaName As String)
            pQuery.Param("NomeTabela").AsString = pTableName
            pQuery.Param("NomeSchema").AsString = me.ResolveSchemaName(pSchemaName)
        End Sub

        Private Sub MapPesquisaPadrao(pQuery As SQL.Command, pItem As PesquisaPadraoModel)
            pItem.TableCode = pQuery.Field("CodTabela").AsInteger
            pItem.SchemaName = pQuery.Field("NomeSchema").AsString
            pItem.TableName = pQuery.Field("NomeTabela").AsString
            pItem.DefaultSearchCode = pQuery.Field("CodPesquisaPadrao").AsInteger
        End Sub

        Function TryGetByTableName(pTableName As String, pSchemaName As String, pItem As PesquisaPadraoModel) As Boolean
            Dim _query As SQL.Command = Null

            Try
                _query = SqlHelper.OpenQuery(me.SqlSelectByTableName())
                me.BindTableNameParams(_query, pTableName, pSchemaName)
                _query.Open()

                If _query.EOF Then
                    TryGetByTableName = False
                Else
                    me.MapPesquisaPadrao(_query, pItem)
                    TryGetByTableName = True
                End If

                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleQueryError(ex, "Error loading PesquisaPadrao", "9301")
            End Try
        End Function

        Function GetByTableName(pTableName As String, pSchemaName As String) As PesquisaPadraoModel
            Dim _item As New PesquisaPadraoModel

            If Not me.TryGetByTableName(pTableName, pSchemaName, _item) Then
                Throw New System.Exception("PesquisaPadrao not found. Code: 9302")
            End If

            GetByTableName = _item
        End Function

        Function ListByTableName(pTableName As String, pSchemaName As String) As PesquisasPadraoModel
            Dim _items As New PesquisasPadraoModel
            Dim _query As SQL.Command = Null

            Try
                _query = SqlHelper.OpenQuery(me.SqlListByTableName())
                me.BindTableNameParams(_query, pTableName, pSchemaName)
                _query.Open()

                While Not _query.EOF
                    Dim _item As New PesquisaPadraoModel
                    me.MapPesquisaPadrao(_query, _item)
                    _items.Push(_item)
                    _query.Next()
                    Wend

                    ListByTableName = _items
                    SqlHelper.ReleaseQuery(_query)
                Catch ex As Exception
                    SqlHelper.ReleaseQuery(_query)
                    SqlHelper.HandleQueryError(ex, "Error loading PesquisaPadrao list", "9303")
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
                    Throw New System.Exception("Error freeing PesquisaPadraoRepository: " + Char(13) + ex._getMessage())
                End Try
            End Sub
            Sub New()
                MyBase.New()
            End Sub

        End Class
    End Namespace
