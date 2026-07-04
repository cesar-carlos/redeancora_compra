Namespace migration_column
    Class MigrationColumn
        Schema As String
        Table As String
        Column As String
        SqlType As String
        Nullable As Boolean
        IsKey As Boolean

        Sub New(pTable As String, pColumn As String, pSqlType As String, pNullable As Boolean = True, pIsKey As Boolean = False, pSchema As String = "")
            MyBase.New()
            Schema = pSchema
            Table = pTable
            Column = pColumn
            SqlType = pSqlType
            Nullable = pNullable
            IsKey = pIsKey
        End Sub

        Function Copy() As MigrationColumn
            Copy = New MigrationColumn(Table, Column, SqlType, Nullable, IsKey, Schema)
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
