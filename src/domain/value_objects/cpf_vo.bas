Imports base_value_object
Imports regex_helper

Namespace cpf_vo
    Class Cpf
        Inherits BaseValueObject

        Private Shared Function Pattern() As String
            Pattern = "^\d{11}$"
        End Function

        Sub New(pValue As String)
            MyBase.New(Cpf.OnlyDigits(pValue))
        End Sub

        Shared Function Create(pValue As String) As Cpf
            Dim _cpf As Cpf = New Cpf(pValue)

            If Not _cpf.IsValid() Then
                Throw New System.Exception("Invalid CPF: " + pValue)
            End If

            Create = _cpf
        End Function

        Shared Function TryCreate(pValue As String, ByRef pResult As Cpf) As Boolean
            Dim _cpf As Cpf = New Cpf(pValue)

            If Not _cpf.IsValid() Then
                pResult = NULL
                TryCreate = False
                Exit Function
            End If

            pResult = _cpf
            TryCreate = True
        End Function

        Shared Function IsValidCpf(pValue As String) As Boolean
            Dim _cpf As String = Cpf.OnlyDigits(pValue)

            If Not Regex.IsFullTextMatch(Cpf.Pattern(), _cpf, False, False) Then
                IsValidCpf = False
                Exit Function
            End If

            If Cpf.HasOnlyRepeatedDigits(_cpf) Then
                IsValidCpf = False
                Exit Function
            End If

            IsValidCpf = Cpf.ValidateCheckDigits(_cpf)
        End Function

        Private Shared Function ValidateCheckDigits(pCpf As String) As Boolean
            Dim _sum As Integer = 0
            Dim _i As Integer
            Dim _digit As Integer = 0
            Dim _firstCheck As Integer = 0
            Dim _secondCheck As Integer = 0

            For _i = 1 To 9
                _digit = CInt(Mid(pCpf, _i, 1))
                _sum = _sum + (_digit * (11 - _i))
            Next

            _firstCheck = Cpf.Mod11Digit(_sum)

            If CInt(Mid(pCpf, 10, 1)) <> _firstCheck Then
                ValidateCheckDigits = False
                Exit Function
            End If

            _sum = 0

            For _i = 1 To 10
                _digit = CInt(Mid(pCpf, _i, 1))
                _sum = _sum + (_digit * (12 - _i))
            Next

            _secondCheck = Cpf.Mod11Digit(_sum)
            ValidateCheckDigits = CInt(Mid(pCpf, 11, 1)) = _secondCheck
        End Function

        Overrides Function IsValid() As Boolean
            IsValid = Cpf.IsValidCpf(me._value)
        End Function

        Function Formatted() As String
            If me._value.Length <> 11 Then
                Formatted = me._value
                Exit Function
            End If

            Formatted = Mid(me._value, 1, 3) + "." + Mid(me._value, 4, 3) + "." + Mid(me._value, 7, 3) + "-" + Mid(me._value, 10, 2)
        End Function

        Overrides Function ToString() As String
            ToString = me.Formatted()
        End Function

        Sub Free()
            Try
                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Error freeing Cpf: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
