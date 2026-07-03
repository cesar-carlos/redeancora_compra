Imports mod_tobject

'@Module
Namespace transactions
    Private Dim _instance As Transaction

    Class Transaction
        Inherits TTObject

        Private _autoCommit As Boolean
        Private _isOpen As Boolean
        Private _depth As Integer

        Private Sub New()
            MyBase.New()
            me._isOpen = False
            me._autoCommit = True
            me._depth = 0
        End Sub

        Shared Function Instance() As Transaction
            If _instance = NULL Then
                _instance = New Transaction()
            End If

            Instance = _instance
        End Function

        Shared Sub ResetInstance()
            If _instance = NULL Then
                Exit Sub
            End If

            If _instance.IsOpen() Then
                _instance.Rollback()
            End If

            _instance.Free()
            _instance = NULL
        End Sub

        Function IsAutoCommitEnabled() As Boolean
            IsAutoCommitEnabled = me._autoCommit
        End Function

        Sub OnAutoCommit()
            me._autoCommit = True
        End Sub

        Sub OffAutoCommit()
            me._autoCommit = False
        End Sub

        Function IsOpen() As Boolean
            IsOpen = me._isOpen
        End Function

        Function Depth() As Integer
            Depth = me._depth
        End Function

        Sub StartTransaction(pDescription As String = "")
            If me._depth = 0 Then
                If Not me._isOpen Then
                    SQL.Connection.StartTransaction(pDescription)
                    me._isOpen = True
                End If
            End If

            me._depth = me._depth + 1
        End Sub

        Sub Commit()
            If me._depth = 0 Then
                Exit Sub
            End If

            me._depth = me._depth - 1

            If me._depth = 0 And me._isOpen Then
                SQL.Connection.Commit()
                me._autoCommit = True
                me._isOpen = False
            End If
        End Sub

        Sub AutoCommit()
            If Not me._autoCommit Or me._depth = 0 Then
                Exit Sub
            End If

            me._depth = me._depth - 1

            If me._depth = 0 And me._isOpen Then
                SQL.Connection.Commit()
                me._isOpen = False
            End If
        End Sub

        Sub Rollback()
            If me._isOpen Then
                SQL.Connection.RollBack()
                me._isOpen = False
            End If

            me._depth = 0
        End Sub

        Sub AutoRollback()
            If Not me._autoCommit Then
                Exit Sub
            End If

            me.Rollback()
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Rollback()
                me.Disposed = True
            End If
        End Sub

        Overridable Function ToString() As String
            With me.BuildLogger(me.ClassName)
                .Prop("IsOpen", me._isOpen)
                .Prop("Depth", me._depth)
                .Prop("AutoCommit", me._autoCommit)
                ToString = .Text()
                .Free()
            End With
        End Function

        Sub Free()
            Try
                If Not me.Disposed Then
                    me.Dispose()
                End If

                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Error freeing Transaction: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
