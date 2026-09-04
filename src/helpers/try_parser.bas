Imports mod_tobject

Namespace try_parser
    Class Parser
        Inherits TTObject

        ' Retorna o valor (0-9) de um caractere digito, ou -1 se nao for digito.
        ' Nao usa Asc/CInt/Cdbl para evitar EVariantTypeCastError (nao capturavel
        ' por Try/Catch no Data7) quando o texto vem de JSON com tipos mistos.
        Private Shared Function DigitValue(pCh As String) As Integer
            Dim _digits As String = "0123456789"
            Dim _i As Integer

            DigitValue = -1

            For _i = 1 To 10
                If Mid(_digits, _i, 1) = pCh Then
                    DigitValue = _i - 1
                    Exit Function
                End If
            Next
        End Function

        ' Parser manual de numero decimal (sem Cdbl). Aceita "." ou "," como
        ' separador decimal e sinal "+"/"-" opcional. Texto invalido retorna 0.
        Private Shared Function ParseDoubleRaw(value As String) As Double
            Dim _text As String = value.Trim()
            Dim _len As Integer = _text.Length
            Dim _i As Integer = 1
            Dim _sign As Double = 1
            Dim _intPart As Double = 0
            Dim _fracPart As Double = 0
            Dim _fracDiv As Double = 1
            Dim _digit As Integer = 0
            Dim _ch As String = ""

            ParseDoubleRaw = 0

            If _text = "" Then
                Exit Function
            End If

            _ch = Mid(_text, 1, 1)

            If _ch = "-" Then
                _sign = -1
                _i = 2
            ElseIf _ch = "+" Then
                _i = 2
            End If

            While _i <= _len
                _ch = Mid(_text, _i, 1)
                _digit = DigitValue(_ch)

                If _digit < 0 Then
                    Exit While
                End If

                _intPart = (_intPart * 10) + _digit
                _i = _i + 1
            Wend

            If _i <= _len Then
                _ch = Mid(_text, _i, 1)

                If _ch = "." Or _ch = "," Then
                    _i = _i + 1

                    While _i <= _len
                        _ch = Mid(_text, _i, 1)
                        _digit = DigitValue(_ch)

                        If _digit < 0 Then
                            Exit While
                        End If

                        _fracDiv = _fracDiv * 10
                        _fracPart = _fracPart + (_digit / _fracDiv)
                        _i = _i + 1
                    Wend
                End If
            End If

            ParseDoubleRaw = _sign * (_intPart + _fracPart)
        End Function

        Shared Function StringToDouble(value As String) As Double
            StringToDouble = ParseDoubleRaw(value).RoundTo(-4)
        End Function

        Shared Function StringToFloat(value As String) As Decimal
            StringToFloat = ParseDoubleRaw(value).RoundTo(-11)
        End Function

        Shared Function StringToDate(pValue As String) As TDateTime
            Try
                Dim _value As TDateTime = StrToDateTime(pValue)
                Return _value
            Catch ex As Exception
                Return StrToDateTime("01/01/1900 00:00:00")
            End Try
        End Function

        Shared Function StringToInteger(value As String) As Integer
            Dim _text As String = value.Trim()
            Dim _parsed As Integer = 0

            StringToInteger = 0

            If _text = "" Then
                Exit Function
            End If

            If TryStrToInt(_text, _parsed) Then
                StringToInteger = _parsed
            End If
        End Function

        Shared Function IntegerToString(value As Integer) As String
            Try
                Dim _value As String = value.toString()
                Return _value
            Catch ex As Exception
                Return ""
            End Try
        End Function
        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            Try
                If Not me.Disposed Then
                    me.Dispose()
                End If

                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Error freeing Parser: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
