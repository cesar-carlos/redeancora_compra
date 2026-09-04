Imports mod_tobject
Imports mod_logger
Imports transactions
Imports diag_stack

Namespace sql_helper
    Private Dim _instance As SqlHelper

    Class SqlHelper
        Inherits TTObject

        Shared Function Instance() As SqlHelper
            If Not Assigned(_instance) Then
                _instance = New SqlHelper()
            End If

            Instance = _instance
        End Function

        Shared Function ValidateIdentifier(pValue As String) As String
            Dim _value As String = Trim(pValue)
            Dim _i As Integer
            Dim _char As String = ""
            Dim _ok As Boolean = False

            If _value = "" Then
                Throw New System.Exception("Invalid SQL identifier: empty value")
            End If

            For _i = 1 To Len(_value)
                _char = Mid(_value, _i, 1)
                _ok = False
                If _char = "_" Then
                    _ok = True
                ElseIf (_char >= "A") And (_char <= "Z") Then
                    _ok = True
                ElseIf (_char >= "a") And (_char <= "z") Then
                    _ok = True
                ElseIf _i > 1 Then
                    If (_char >= "0") And (_char <= "9") Then
                        _ok = True
                    End If
                End If

                If Not _ok Then
                    Throw New System.Exception("Invalid SQL identifier: " + _value)
                End If
            Next

            ValidateIdentifier = _value
        End Function

        Shared Function SqlText(pValue As String) As String
            SqlText = Chr(39) + pValue + Chr(39)
        End Function

        Shared Function QualifiedTable(pSchema As String, pTable As String) As String
            Dim _table As String = SqlHelper.ValidateIdentifier(pTable)
            Dim _schema As String = Trim(pSchema)

            If _schema = "" Then
                QualifiedTable = _table
                Exit Function
            End If

            QualifiedTable = SqlHelper.ValidateIdentifier(_schema) + "." + _table
        End Function

        Shared Sub ReleaseQuery(pQuery As SQL.Command)
            If Not Assigned(pQuery) Then
                Exit Sub
            End If

            Try
                pQuery.Close()
            Catch exClose As Exception
            End Try

            Try
                pQuery.Free()
            Catch exFree As Exception
            End Try
        End Sub

        Shared Sub HandleError(pTransaction As Transaction, pMessage As String, pException As Exception)
            Dim _msg As String = pMessage

            If Assigned(pException) Then
                Try
                    _msg = pMessage + Char(13) + pException._getMessage()
                Catch exMsg As Exception
                End Try
            End If

            mod_logger.Warn(_msg)

            If Assigned(pTransaction) Then
                pTransaction.Rollback()
            End If

            Throw New System.Exception(_msg)
        End Sub

        Private Shared Function ClipSql(pSql As String) As String
            If Len(pSql) <= 180 Then
                ClipSql = pSql
            Else
                ClipSql = Mid(pSql, 1, 180) + "..."
            End If
        End Function

        Private Shared Function SafeExceptionMessage(pException As Exception) As String
            Dim _msg As String = ""

            If Not Assigned(pException) Then
                SafeExceptionMessage = ""
                Exit Function
            End If

            Try
                _msg = pException._getMessage()
            Catch exMsg As Exception
                _msg = ""
            End Try

            SafeExceptionMessage = _msg
        End Function

        Shared Sub ExecuteNonQuery(pSql As String, pErrorMessage As String, pDescription As String = "")
            Dim _helper As SqlHelper = SqlHelper.Instance()
            _helper.RunNonQuery(pSql, pErrorMessage, pDescription)
        End Sub

        Private Sub RunNonQuery(pSql As String, pErrorMessage As String, pDescription As String)
            Dim _tx As Transaction = NULL
            Dim _query As SQL.Command = NULL

            DiagStack.Push("SqlHelper.ExecuteNonQuery " + ClipSql(pSql))
            Try
                _tx = Transaction.Instance()
                If Assigned(_tx) Then
                    _tx.StartTransaction(pDescription)
                End If
                _query = New SQL.Command()
                If Not Assigned(_query) Then
                    Throw New System.Exception("SQL.Command New returned empty")
                End If
                _query.CommandText = pSql
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _query = NULL
                If Assigned(_tx) Then
                    _tx.AutoCommit()
                End If
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _query = NULL
                SqlHelper.HandleError(_tx, pErrorMessage, ex)
            End Try
            DiagStack.Pop()
        End Sub

        ' Existence query: Open/IsEmpty must run on an instance (Shared + SQL.Command.Open AVs).
        ' Do not read TField (Field/AsBoolean/AsString on OleStr can AV).
        ' Do not New/Free SqlHelper per call — that New was itself a nil-VMT candidate.
        Shared Function ExecuteExists(pSql As String, pErrorMessage As String) As Boolean
            Dim _helper As SqlHelper = NULL
            Dim _valor As Boolean = False
            Dim _exMsg As String = ""

            DiagStack.Trace("boot: ExecuteExists enter")
            Try
                DiagStack.Trace("boot: ExecuteExists stack")
                DiagStack.Push("SqlHelper.ExecuteExists")
                DiagStack.Trace("boot: ExecuteExists instance")
                _helper = SqlHelper.Instance()
                If Not Assigned(_helper) Then
                    Throw New System.Exception("SqlHelper.Instance returned empty")
                End If
                DiagStack.Trace("boot: ExecuteExists got-instance")
                _valor = _helper.RunExists(pSql)
                DiagStack.Pop()
            Catch ex As Exception
                _exMsg = SafeExceptionMessage(ex)
                If _exMsg = "" Then
                    Throw New System.Exception(pErrorMessage)
                End If
                Throw New System.Exception(pErrorMessage + Char(13) + _exMsg)
            End Try

            ExecuteExists = _valor
        End Function

        Private Function RunExists(pSql As String) As Boolean
            Dim _query As SQL.Command = NULL
            Dim _valor As Boolean = False

            Try
                DiagStack.Trace("boot: ExecuteExists New")
                _query = New SQL.Command()
                If Not Assigned(_query) Then
                    Throw New System.Exception("SQL.Command New returned empty")
                End If
                _query.CommandText = pSql
                DiagStack.Trace("boot: ExecuteExists Open")
                _query.Open()
                DiagStack.Trace("boot: ExecuteExists opened")
                If Not _query.IsEmpty() Then
                    _valor = True
                End If
                DiagStack.Trace("boot: ExecuteExists empty-checked")
                SqlHelper.ReleaseQuery(_query)
                _query = NULL
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _query = NULL
                Throw ex
            End Try

            RunExists = _valor
        End Function

        Shared Function OpenQuery(pSql As String) As SQL.Command
            Dim _query As SQL.Command = New SQL.Command()
            _query.CommandText = pSql
            OpenQuery = _query
        End Function

        Shared Sub HandleQueryError(pException As Exception, pMessage As String, pCode As String)
            Dim _tx As Transaction = NULL
            Dim _msg As String = pMessage + " Code: " + pCode
            Dim _exMsg As String = SafeExceptionMessage(pException)

            If _exMsg <> "" Then
                _msg = _msg + Char(13) + _exMsg
            End If

            mod_logger.Warn(_msg)

            _tx = Transaction.Instance()
            If Assigned(_tx) Then
                _tx.Rollback()
            End If

            Throw New System.Exception(_msg)
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub

        Sub New()
            MyBase.New()
        End Sub

    End Class
End Namespace
