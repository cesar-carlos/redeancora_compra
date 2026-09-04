Imports migration_service
Imports migration_column
Imports migration_table
Imports diag_stack

Namespace migration_controller
    Class MigrationController
        Private _service As MigrationService

        Sub New()
            MyBase.New()
            _service = New MigrationService()
        End Sub

        Function SchemaExists(pSchema As String) As Boolean
            SchemaExists = _service.SchemaExists(pSchema)
        End Function

        Sub EnsureSchema(pSchema As String)
            If pSchema.Trim() = "" Then
                Exit Sub
            End If

            DiagStack.Push("MigrationController.EnsureSchema")
            DiagStack.Trace("boot: SchemaExists start")
            If Not _service.SchemaExists(pSchema) Then
                DiagStack.Trace("boot: CreateSchema start")
                _service.CreateSchema(pSchema)
                DiagStack.Trace("boot: CreateSchema ok")
            End If
            DiagStack.Pop()
        End Sub

        Function TableExists(pTable As String) As Boolean
            TableExists = _service.TableExists(pTable)
        End Function

        Function TableExists(pSchema As String, pTable As String) As Boolean
            TableExists = _service.TableExists(pSchema, pTable)
        End Function

        Function ColumnExists(pTable As String, pColumn As String) As Boolean
            ColumnExists = _service.ColumnExists(pTable, pColumn)
        End Function

        Function ColumnExists(pSchema As String, pTable As String, pColumn As String) As Boolean
            ColumnExists = _service.ColumnExists(pSchema, pTable, pColumn)
        End Function

        Sub CreateColumn(pTable As String, pColumn As String, pSqlType As String)
            If Not _service.ColumnExists(pTable, pColumn) Then
                _service.CreateColumn(pTable, pColumn, pSqlType)
            End If
        End Sub

        Sub CreateColumn(pSchema As String, pTable As String, pColumn As String, pSqlType As String)
            If Not _service.ColumnExists(pSchema, pTable, pColumn) Then
                _service.CreateColumn(pSchema, pTable, pColumn, pSqlType)
            End If
        End Sub

        Sub CreateColumn(pMigrationColumn As MigrationColumn)
            If Not _service.ColumnExists(pMigrationColumn.Schema, pMigrationColumn.Table, pMigrationColumn.Column) Then
                _service.CreateColumn(pMigrationColumn)
            End If
        End Sub

        Sub DropColumnIfExists(pSchema As String, pTable As String, pColumn As String)
            If _service.ColumnExists(pSchema, pTable, pColumn) Then
                _service.DropColumn(pSchema, pTable, pColumn)
            End If
        End Sub

        Sub CreateTable(pMigrationTable As MigrationTable)
            me.EnsureSchema(pMigrationTable.Schema)

            If Not _service.TableExists(pMigrationTable.Schema, pMigrationTable.Name) Then
                _service.CreateTable(pMigrationTable)
            End If
        End Sub

        Sub ExecuteSql(pSql As String)
            _service.RawCommand(pSql)
        End Sub

        Sub Free()
            If Assigned(_service) Then
                _service.Free()
                _service = NULL
            End If
            MyBase.Free()
        End Sub
    End Class
End Namespace
