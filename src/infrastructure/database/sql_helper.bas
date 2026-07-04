Imports mod_tobject
Imports mod_logger
Imports transactions

Namespace sql_helper
    Class SqlHelper
        Private Shared Function IsIdentifierChar(pCharacter As String, pIsFirst As Boolean) As Boolean
            If pCharacter = "_" Then
                IsIdentifierChar = True
                Exit Function
            End If

            If Not pIsFirst Then
                IsIdentifierChar = SqlHelper.IsDigit(pCharacter)
                Exit Function
            End If

            IsIdentifierChar = (pCharacter >= "A" And pCharacter <= "Z") Or (pCharacter >= "a" And pCharacter <= "z")
        End Function

        Private Shared Function IsDigit(pCharacter As String) As Boolean
            IsDigit = (pCharacter >= "0" And pCharacter <= "9") Or (pCharacter >= "A" And pCharacter <= "Z") Or (pCharacter >= "a" And pCharacter <= "z") Or pCharacter = "_"
        End Function

        Shared Function ValidateIdentifier(pValue As String) As String
            Dim _value As String = pValue.Trim()

            If _value = "" Then
                Throw New System.Exception("Invalid SQL identifier: empty value")
            End If

            Dim _i As Integer
            Dim _char As String = ""

            For _i = 1 To _value.Length
                _char = Mid(_value, _i, 1)

                If Not SqlHelper.IsIdentifierChar(_char, _i = 1) Then
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
            Dim _schema As String = pSchema.Trim()

            If _schema = "" Then
                QualifiedTable = _table
                Exit Function
            End If

            QualifiedTable = SqlHelper.ValidateIdentifier(_schema) + "." + _table
        End Function

        Shared Sub ReleaseQuery(pQuery As SQL.Command)
            If Assigned(pQuery) Then
                pQuery.Free()
            End If
        End Sub

        Shared Sub HandleError(pTransaction As Transaction, pMessage As String, pException As Exception)
            mod_logger.Warn(pMessage + Char(13) + pException._getMessage())
            pTransaction.Rollback()
            Throw New System.Exception(pMessage + Char(13) + pException._getMessage())
        End Sub

        Shared Sub ExecuteNonQuery(pSql As String, pErrorMessage As String, pDescription As String = "")
            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL

            Try
                _tx.StartTransaction(pDescription)
                _query = New SQL.Command()
                _query.CommandText = pSql
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleError(_tx, pErrorMessage, ex)
            End Try
        End Sub

        Shared Function ExecuteScalarBoolean(pSql As String, pFieldName As String, pErrorMessage As String) As Boolean
            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL

            Try
                _query = New SQL.Command()
                _query.CommandText = pSql
                _query.Open()
                ExecuteScalarBoolean = _query.Field(pFieldName).AsBoolean
                SqlHelper.ReleaseQuery(_query)
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                SqlHelper.HandleError(_tx, pErrorMessage, ex)
            End Try
        End Function

        Shared Function OpenQuery(pSql As String) As SQL.Command
            Dim _query As SQL.Command = New SQL.Command()
            _query.CommandText = pSql
            OpenQuery = _query
        End Function

        Shared Sub HandleQueryError(pException As Exception, pMessage As String, pCode As String)
            mod_logger.Warn(pMessage + " Code: " + pCode + Char(13) + pException._getMessage())
            Transaction.Instance().Rollback()
            Throw New System.Exception(pMessage + " Code: " + pCode + Char(13) + pException._getMessage())
        End Sub
        Sub Free()
            MyBase.Free()
        End Sub

       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
