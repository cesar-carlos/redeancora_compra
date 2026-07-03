Imports migration_column

Namespace migration_columns
    Class MigrationColumns
        Private _list As TObjectList = New TObjectList()

        Public Sub New()
            MyBase.New()
        End Sub

        Sub Add(pColumn As MigrationColumn)
            _list.Add(pColumn)
        End Sub

        Function GetAt(pIndex As Integer) As MigrationColumn
            GetAt = MigrationColumn(_list[pIndex])
        End Function

        Function KeyColumns() As MigrationColumns
            Dim _i As Integer
            Dim _keyColumns As New MigrationColumns()
            For _i = 0 To _list.Count - 1
                If MigrationColumn(_list[_i]).IsKey Then
                    _keyColumns.Add(MigrationColumn(_list[_i]).Copy())
                End If
            Next
            KeyColumns = _keyColumns
        End Function

        Function Count() As Integer
            Count = _list.Count
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
