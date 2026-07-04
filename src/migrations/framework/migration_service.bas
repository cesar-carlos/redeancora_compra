Imports migration_column
Imports migration_columns
Imports migration_table
Imports sql_helper

Namespace migration_service
    Class MigrationService
        Sub New()
            MyBase.New()
        End Sub

        Function SchemaExists(pSchema As String) As Boolean
            Dim _schema As String = SqlHelper.ValidateIdentifier(pSchema)

            SchemaExists = SqlHelper.ExecuteScalarBoolean( _
            "SELECT CASE WHEN COUNT(name) > 0 THEN " + SqlHelper.SqlText("true") + " " + _
            "           ELSE " + SqlHelper.SqlText("false") + " " + _
            "      END result " + _
            "FROM sys.schemas " + _
            "WHERE name = " + SqlHelper.SqlText(_schema), _
            "result", _
            "Failed to check schema")
        End Function

        Sub CreateSchema(pSchema As String)
            Dim _schema As String = SqlHelper.ValidateIdentifier(pSchema)
            Dim _sql As String = ""

            _sql = "IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = " + SqlHelper.SqlText(_schema) + ") "
            _sql = _sql + "EXEC(" + SqlHelper.SqlText("CREATE SCHEMA " + _schema) + ")"

            SqlHelper.ExecuteNonQuery( _
            _sql, _
            "Failed to create schema", _
            "Create schema " + _schema)
        End Sub

        Function TableExists(pTable As String) As Boolean
            TableExists = me.TableExists("", pTable)
        End Function

        Function TableExists(pSchema As String, pTable As String) As Boolean
            Dim _table As String = SqlHelper.ValidateIdentifier(pTable)
            Dim _schema As String = pSchema.Trim()

            If _schema = "" Then
                TableExists = SqlHelper.ExecuteScalarBoolean( _
                "SELECT CASE WHEN count(NAME) > 0 THEN " + SqlHelper.SqlText("true") + " " + _
                "           ELSE " + SqlHelper.SqlText("false") + " " + _
                "      END result " + _
                "FROM SYSOBJECTS " + _
                "WHERE NAME = " + SqlHelper.SqlText(_table), _
                "result", _
                "Failed to check table")
                Exit Function
            End If

            _schema = SqlHelper.ValidateIdentifier(_schema)

            TableExists = SqlHelper.ExecuteScalarBoolean( _
            "SELECT CASE WHEN COUNT(t.name) > 0 THEN " + SqlHelper.SqlText("true") + " " + _
            "           ELSE " + SqlHelper.SqlText("false") + " " + _
            "      END result " + _
            "FROM sys.tables t " + _
            "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " + _
            "WHERE s.name = " + SqlHelper.SqlText(_schema) + " AND t.name = " + SqlHelper.SqlText(_table), _
            "result", _
            "Failed to check table")
        End Function

        Function ColumnExists(pTable As String, pColumn As String) As Boolean
            ColumnExists = me.ColumnExists("", pTable, pColumn)
        End Function

        Function ColumnExists(pSchema As String, pTable As String, pColumn As String) As Boolean
            Dim _table As String = SqlHelper.ValidateIdentifier(pTable)
            Dim _column As String = SqlHelper.ValidateIdentifier(pColumn)
            Dim _schema As String = pSchema.Trim()

            If _schema = "" Then
                ColumnExists = SqlHelper.ExecuteScalarBoolean( _
                "IF EXISTS(SELECT * " + _
                "          FROM dbo.syscolumns " + _
                "          WHERE Id = object_id(" + SqlHelper.SqlText(_table) + ") " + _
                "            AND NAME = " + SqlHelper.SqlText(_column) + ") " + _
                "SELECT " + SqlHelper.SqlText("true") + " Result " + _
                "ELSE " + _
                "SELECT " + SqlHelper.SqlText("false") + " Result", _
                "result", _
                "Failed to check column")
                Exit Function
            End If

            _schema = SqlHelper.ValidateIdentifier(_schema)

            ColumnExists = SqlHelper.ExecuteScalarBoolean( _
            "IF EXISTS(SELECT 1 " + _
            "          FROM sys.columns c " + _
            "          INNER JOIN sys.tables t ON c.object_id = t.object_id " + _
            "          INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " + _
            "          WHERE s.name = " + SqlHelper.SqlText(_schema) + " " + _
            "            AND t.name = " + SqlHelper.SqlText(_table) + " " + _
            "            AND c.name = " + SqlHelper.SqlText(_column) + ") " + _
            "SELECT " + SqlHelper.SqlText("true") + " Result " + _
            "ELSE " + _
            "SELECT " + SqlHelper.SqlText("false") + " Result", _
            "result", _
            "Failed to check column")
        End Function

        Sub CreateColumn(pTable As String, pColumn As String, pSqlType As String)
            me.CreateColumn("", pTable, pColumn, pSqlType)
        End Sub

        Sub CreateColumn(pSchema As String, pTable As String, pColumn As String, pSqlType As String)
            Dim _qualifiedTable As String = SqlHelper.QualifiedTable(pSchema, pTable)
            Dim _column As String = SqlHelper.ValidateIdentifier(pColumn)

            SqlHelper.ExecuteNonQuery( _
            "ALTER TABLE " + _qualifiedTable + " ADD " + _column + " " + pSqlType, _
            "Failed to create column")
        End Sub

        Sub CreateColumn(pMigrationColumn As MigrationColumn)
            me.CreateColumn(pMigrationColumn.Schema, pMigrationColumn.Table, pMigrationColumn.Column, pMigrationColumn.SqlType)
        End Sub

        Sub DropColumn(pSchema As String, pTable As String, pColumn As String)
            Dim _qualifiedTable As String = SqlHelper.QualifiedTable(pSchema, pTable)
            Dim _column As String = SqlHelper.ValidateIdentifier(pColumn)

            SqlHelper.ExecuteNonQuery( _
            "ALTER TABLE " + _qualifiedTable + " DROP COLUMN " + _column, _
            "Failed to drop column")
        End Sub

        Sub CreateTable(pMigrationTable As MigrationTable)
            If Not pMigrationTable.CanCreate() Then
                Exit Sub
            End If

            Dim _i As Integer
            Dim _qualifiedTable As String = SqlHelper.QualifiedTable(pMigrationTable.Schema, pMigrationTable.Name)
            Dim _tableString As String = "CREATE TABLE " + _qualifiedTable + "("

            For _i = 0 To pMigrationTable.Columns.Count() - 1
                Dim _column As MigrationColumn = pMigrationTable.Columns.GetAt(_i)
                _tableString += SqlHelper.ValidateIdentifier(_column.Column) + " " + _column.SqlType + " "
                If Not _column.Nullable Then
                    _tableString += "NOT NULL "
                End If
                If _i < pMigrationTable.Columns.Count() - 1 Then
                    _tableString += ","
                End If
            Next

            Dim _keyColumns As MigrationColumns = pMigrationTable.Columns.KeyColumns()
            If _keyColumns.Count() > 0 Then
                _tableString += ", PRIMARY KEY ("

                For _i = 0 To _keyColumns.Count() - 1
                    If _i > 0 Then
                        _tableString += ","
                    End If
                    _tableString += SqlHelper.ValidateIdentifier(_keyColumns.GetAt(_i).Column)
                Next

                _tableString += ")"
            End If

            _keyColumns.Free()
            _tableString += ")"
            me.RawCommand(_tableString)
        End Sub

        Sub RawCommand(pSql As String)
            SqlHelper.ExecuteNonQuery(pSql, "Failed to execute SQL")
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
