Namespace migration_column
    Class MigrationColumn
        Public Schema As String
        Public Table As String
        Public Column As String
        Public SqlType As String
        Public Nullable As Boolean
        Public IsKey As Boolean

        Public Sub New(pTable As String, pColumn As String, pSqlType As String, pNullable As Boolean = True, pIsKey As Boolean = False, pSchema As String = "")
            MyBase.New()
            Schema = pSchema
            Table = pTable
            Column = pColumn
            SqlType = pSqlType
            Nullable = pNullable
            IsKey = pIsKey
        End Sub

        Public Function Copy() As MigrationColumn
            Copy = New MigrationColumn(Table, Column, SqlType, Nullable, IsKey, Schema)
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
