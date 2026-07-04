Imports migration_columns

Namespace migration_table
    Class MigrationTable
        Schema As String
        Name As String
        Columns As MigrationColumns

        Sub New(pName As String, pColumns As MigrationColumns, pSchema As String = "")
            MyBase.New()
            Name = pName
            Schema = pSchema
            Columns = pColumns
        End Sub

        Function CanCreate() As Boolean
            CanCreate = Columns.Count() > 0
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
