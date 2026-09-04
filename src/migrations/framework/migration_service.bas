Imports migration_column
Imports migration_columns
Imports migration_table
Imports sql_helper
Imports diag_stack

Namespace migration_service
    Class MigrationService
        Sub New()
            MyBase.New()
        End Sub

        Function SchemaExists(pSchema As String) As Boolean
            Dim _schema As String = ""
            Dim _quoted As String = ""
            Dim _sql As String = ""
            Dim _existe As Boolean = False

            ' Do not call SqlHelper.ValidateIdentifier here: first Shared
            ' method on SqlHelper was a nil-VMT (FFFFFFD0) after this log.
            DiagStack.Trace("boot: SchemaExists validate")
            _schema = Trim(pSchema)
            DiagStack.Trace("boot: SchemaExists trimmed")
            If _schema = "" Then
                Throw New System.Exception("Invalid SQL identifier: empty value")
            End If
            DiagStack.Trace("boot: SchemaExists named")
            DiagStack.Push("SchemaExists")
            DiagStack.Trace("boot: SchemaExists stacked")
            DiagStack.Trace("boot: SchemaExists sql-build")
            _quoted = Chr(39) + _schema + Chr(39)
            DiagStack.Trace("boot: SchemaExists quoted")
            _sql = "SELECT 1 AS Qtd FROM sys.schemas WHERE name = " + _quoted
            DiagStack.Trace("boot: SchemaExists sql-built")
            DiagStack.Trace("boot: SchemaExists execute")
            _existe = SqlHelper.ExecuteExists(_sql, "Failed to check schema")
            DiagStack.Trace("boot: SchemaExists executed")
            DiagStack.Pop()
            SchemaExists = _existe
        End Function

        Sub CreateSchema(pSchema As String)
            Dim _schema As String = SqlHelper.ValidateIdentifier(pSchema)
            Dim _sql As String = ""

            DiagStack.Push("CreateSchema")
            _sql = "IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = " + SqlHelper.SqlText(_schema) + ") "
            _sql = _sql + "EXEC(" + SqlHelper.SqlText("CREATE SCHEMA " + _schema) + ")"

            SqlHelper.ExecuteNonQuery( _
            _sql, _
            "Failed to create schema", _
            "Create schema " + _schema)
            DiagStack.Pop()
        End Sub

        Function TableExists(pTable As String) As Boolean
            TableExists = me.TableExists("", pTable)
        End Function

        Function TableExists(pSchema As String, pTable As String) As Boolean
            Dim _table As String = SqlHelper.ValidateIdentifier(pTable)
            Dim _schema As String = pSchema.Trim()

            If _schema = "" Then
                TableExists = SqlHelper.ExecuteExists( _
                "SELECT 1 AS Qtd FROM SYSOBJECTS WHERE NAME = " + SqlHelper.SqlText(_table), _
                "Failed to check table")
                Exit Function
            End If

            _schema = SqlHelper.ValidateIdentifier(_schema)

            TableExists = SqlHelper.ExecuteExists( _
            "SELECT 1 AS Qtd FROM sys.tables t " + _
            "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " + _
            "WHERE s.name = " + SqlHelper.SqlText(_schema) + " AND t.name = " + SqlHelper.SqlText(_table), _
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
                ColumnExists = SqlHelper.ExecuteExists( _
                "SELECT 1 AS Qtd FROM dbo.syscolumns " + _
                "WHERE Id = object_id(" + SqlHelper.SqlText(_table) + ") " + _
                "  AND NAME = " + SqlHelper.SqlText(_column), _
                "Failed to check column")
                Exit Function
            End If

            _schema = SqlHelper.ValidateIdentifier(_schema)

            ColumnExists = SqlHelper.ExecuteExists( _
            "SELECT 1 AS Qtd FROM sys.columns c " + _
            "INNER JOIN sys.tables t ON c.object_id = t.object_id " + _
            "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " + _
            "WHERE s.name = " + SqlHelper.SqlText(_schema) + " " + _
            "  AND t.name = " + SqlHelper.SqlText(_table) + " " + _
            "  AND c.name = " + SqlHelper.SqlText(_column), _
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
                If Assigned(_column) Then
                    _tableString += SqlHelper.ValidateIdentifier(_column.Column) + " " + _column.SqlType + " "
                    If Not _column.Nullable Then
                        _tableString += "NOT NULL "
                    End If
                    If _i < pMigrationTable.Columns.Count() - 1 Then
                        _tableString += ","
                    End If
                End If
            Next

            Dim _keyColumns As MigrationColumns = pMigrationTable.Columns.KeyColumns()
            If _keyColumns.Count() > 0 Then
                _tableString += ", PRIMARY KEY ("

                For _i = 0 To _keyColumns.Count() - 1
                    Dim _keyColumn As MigrationColumn = _keyColumns.GetAt(_i)
                    If Assigned(_keyColumn) Then
                        If _i > 0 Then
                            _tableString += ","
                        End If
                        _tableString += SqlHelper.ValidateIdentifier(_keyColumn.Column)
                    End If
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
