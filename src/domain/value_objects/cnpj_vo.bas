Imports base_value_object
Imports regex_helper

Namespace cnpj_vo
    Class Cnpj
        Inherits BaseValueObject

        Private Shared Function Pattern() As String
            Pattern = "^\d{14}$"
        End Function

        Sub New(pValue As String)
            MyBase.New(Cnpj.OnlyDigits(pValue))
        End Sub

        Shared Function Create(pValue As String) As Cnpj
            Dim _cnpj As Cnpj = New Cnpj(pValue)

            If Not _cnpj.IsValid() Then
                Throw New System.Exception("Invalid CNPJ: " + pValue)
            End If

            Create = _cnpj
        End Function

        Shared Function TryCreate(pValue As String, ByRef pResult As Cnpj) As Boolean
            Dim _cnpj As Cnpj = New Cnpj(pValue)

            If Not _cnpj.IsValid() Then
                pResult = NULL
                TryCreate = False
                Exit Function
            End If

            pResult = _cnpj
            TryCreate = True
        End Function

        Shared Function IsValidCnpj(pValue As String) As Boolean
            Dim _cnpj As String = Cnpj.OnlyDigits(pValue)

            If Not Regex.IsFullTextMatch(Pattern(), _cnpj, False, False) Then
                IsValidCnpj = False
                Exit Function
            End If

            If Cnpj.HasOnlyRepeatedDigits(_cnpj) Then
                IsValidCnpj = False
                Exit Function
            End If

            IsValidCnpj = ValidateCheckDigits(_cnpj)
        End Function

        Private Shared Function ValidateCheckDigits(pCnpj As String) As Boolean
            Dim _weightsFirst As String = "543298765432"
            Dim _weightsSecond As String = "6543298765432"
            Dim _sum As Integer = 0
            Dim _i As Integer
            Dim _digit As Integer = 0
            Dim _weight As Integer = 0
            Dim _firstCheck As Integer = 0
            Dim _secondCheck As Integer = 0

            For _i = 1 To 12
                _digit = CInt(Mid(pCnpj, _i, 1))
                _weight = CInt(Mid(_weightsFirst, _i, 1))
                _sum = _sum + (_digit * _weight)
            Next

            _firstCheck = Cnpj.Mod11Digit(_sum)

            If CInt(Mid(pCnpj, 13, 1)) <> _firstCheck Then
                ValidateCheckDigits = False
                Exit Function
            End If

            _sum = 0

            For _i = 1 To 13
                _digit = CInt(Mid(pCnpj, _i, 1))
                _weight = CInt(Mid(_weightsSecond, _i, 1))
                _sum = _sum + (_digit * _weight)
            Next

            _secondCheck = Cnpj.Mod11Digit(_sum)
            ValidateCheckDigits = CInt(Mid(pCnpj, 14, 1)) = _secondCheck
        End Function

        Overrides Function IsValid() As Boolean
            IsValid = Cnpj.IsValidCnpj(Me._value)
        End Function

        Function Formatted() As String
            If Me._value.Length <> 14 Then
                Formatted = Me._value
                Exit Function
            End If

            Formatted = Mid(Me._value, 1, 2) + "." + Mid(Me._value, 3, 3) + "." + Mid(Me._value, 6, 3) + "/" + Mid(Me._value, 9, 4) + "-" + Mid(Me._value, 13, 2)
        End Function

        Overrides Function ToString() As String
            ToString = Me.Formatted()
        End Function

        Sub Free()
            Try
                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Error freeing Cnpj: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
