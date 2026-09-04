Imports base_value_object
Imports regex_helper

Namespace email_vo
    Class Email
        Inherits BaseValueObject

        Private Shared Function Pattern() As String
            Pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        End Function

        Sub New(pValue As String)
            MyBase.New(pValue.Trim())
        End Sub

        Shared Function Create(pValue As String) As Email
            Dim _email As Email = New Email(pValue)

            If Not _email.IsValid() Then
                Throw New System.Exception("Invalid email: " + pValue)
            End If

            Create = _email
        End Function

        Shared Function TryCreate(pValue As String, ByRef pResult As Email) As Boolean
            Dim _email As Email = New Email(pValue)

            If Not _email.IsValid() Then
                pResult = Null
                TryCreate = False
                Exit Function
            End If

            pResult = _email
            TryCreate = True
        End Function

        Shared Function IsValidEmail(pValue As String) As Boolean
            IsValidEmail = Regex.IsFullTextMatch(Pattern(), pValue.Trim(), False, False)
        End Function

        Overrides Function IsValid() As Boolean
            IsValid = Email.IsValidEmail(me._value)
        End Function

        Function Normalized() As String
            Normalized = me._value.ToLower()
        End Function

        Overrides Function ToString() As String
            ToString = me.Normalized()
        End Function

        Sub Free()
            Try
                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Error freeing Email: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
