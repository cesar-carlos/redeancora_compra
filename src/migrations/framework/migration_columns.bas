Imports migration_column
Imports mod_tlist

Namespace migration_columns
    Class MigrationColumns
        Private _list[] As MigrationColumn

        Sub New()
            MyBase.New()
            _list = []
        End Sub

        Sub Add(pColumn As MigrationColumn)
            If Assigned(pColumn) Then
                If Assigned(_list) Then
                    _list.Push(pColumn)
                End If
            End If
        End Sub

        Function GetAt(pIndex As Integer) As MigrationColumn
            GetAt = Null
            If Assigned(_list) Then
                GetAt = _list.Take(pIndex)
            End If
        End Function

        Function KeyColumns() As MigrationColumns
            Dim _i As Integer
            Dim _keyColumns As New MigrationColumns()
            Dim _column As MigrationColumn = Null

            If Assigned(_list) Then
                For _i = 0 To _list.Length - 1
                    _column = _list.Take(_i)
                    If Assigned(_column) Then
                        If _column.IsKey Then
                            _keyColumns.Add(_column.Copy())
                        End If
                    End If
                Next
            End If

            KeyColumns = _keyColumns
        End Function

        Function Count() As Integer
            Count = 0
            If Assigned(_list) Then
                Count = _list.Length
            End If
        End Function

        Sub Free()
            If Assigned(_list) Then
                _list.Free()
                _list = Null
            End If
            MyBase.Free()
        End Sub
    End Class
End Namespace