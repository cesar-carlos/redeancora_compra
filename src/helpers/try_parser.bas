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
            Dim _result As Integer = -1

            For _i = 1 To 10
                If _result < 0 Then
                    If Mid(_digits, _i, 1) = pCh Then
                        _result = _i - 1
                    End If
                End If
            Next

            DigitValue = _result
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
            Dim _seguir As Boolean = True
            Dim _frac As Boolean = False
            Dim _casas As Integer = 0

            ParseDoubleRaw = 0

            If _len <= 0 Then
                _seguir = False
            End If

            If _seguir Then
                _ch = Mid(_text, 1, 1)

                If _ch = "-" Then
                    _sign = -1
                    _i = 2
                Else
                    If _ch = "+" Then
                        _i = 2
                    End If
                End If
            End If

            While _seguir
                If _i > _len Then
                    _seguir = False
                Else
                    _ch = Mid(_text, _i, 1)
                    _digit = DigitValue(_ch)

                    If _digit < 0 Then
                        _seguir = False
                    Else
                        ' 9 digitos: 10o * 10 estoura Integer se o runtime promover a conta.
                        If _casas < 9 Then
                            _intPart = (_intPart * 10) + _digit
                            _casas = _casas + 1
                        End If
                        _i = _i + 1
                    End If
                End If
            Wend

            If _i <= _len Then
                _ch = Mid(_text, _i, 1)

                If _ch = "." Then
                    _frac = True
                Else
                    If _ch = "," Then
                        _frac = True
                    End If
                End If
            End If

            If _frac Then
                _i = _i + 1
                _seguir = True
                _casas = 0

                While _seguir
                    If _i > _len Then
                        _seguir = False
                    Else
                        _ch = Mid(_text, _i, 1)
                        _digit = DigitValue(_ch)

                        If _digit < 0 Then
                            _seguir = False
                        Else
                            ' JSON manda peso como 36.100100000000005. A 10a casa
                            ' faz escala 10^10 e estoura Integer. 6 casas bastam (RoundTo -4).
                            If _casas < 6 Then
                                _fracDiv = _fracDiv * 10
                                _fracPart = _fracPart + (_digit / _fracDiv)
                                _casas = _casas + 1
                            End If
                            _i = _i + 1
                        End If
                    End If
                Wend
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

        ' Sem TryStrToInt e sem Exit: os dois viram PaxExitException ou Integer overflow
        ' quando o parse roda dentro do Try do full-search.
        Shared Function StringToInteger(value As String) As Integer
            Dim _text As String = value.Trim()
            Dim _len As Integer = Len(_text)
            Dim _i As Integer = 1
            Dim _sign As Integer = 1
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _ch As String = ""
            Dim _seguir As Boolean = True
            Dim _ok As Boolean = True
            Dim _tem As Boolean = False

            StringToInteger = 0

            If _len <= 0 Then
                _seguir = False
                _ok = False
            End If

            If _seguir Then
                _ch = Mid(_text, 1, 1)

                If _ch = "-" Then
                    _sign = -1
                    _i = 2
                Else
                    If _ch = "+" Then
                        _i = 2
                    End If
                End If
            End If

            If _i > _len Then
                _ok = False
                _seguir = False
            End If

            While _seguir
                If _i > _len Then
                    _seguir = False
                Else
                    _ch = Mid(_text, _i, 1)
                    _d = DigitValue(_ch)

                    If _d < 0 Then
                        _ok = False
                        _seguir = False
                    Else
                        If PodeAcumularDigito(_n, _d) Then
                            _n = (_n * 10) + _d
                            _tem = True
                            _i = _i + 1
                        Else
                            _ok = False
                            _n = 0
                            _seguir = False
                        End If
                    End If
                End If
            Wend

            If _ok Then
                If _tem Then
                    If _sign < 0 Then
                        StringToInteger = 0 - _n
                    Else
                        StringToInteger = _n
                    End If
                End If
            End If
        End Function

        ' True se (pAtual * 10) + pDigito cabe em Integer. Evita EIntOverflow
        ' ("Integer overflow"), que o Catch do Data7 deixa escapar e aborta o sync.
        Shared Function PodeAcumularDigito(pAtual As Integer, pDigito As Integer) As Boolean
            Dim _ok As Boolean = False

            If pDigito >= 0 Then
                If pDigito <= 9 Then
                    If pAtual >= 0 Then
                        If pAtual < 214748364 Then
                            _ok = True
                        Else
                            If pAtual = 214748364 Then
                                If pDigito <= 7 Then
                                    _ok = True
                                End If
                            End If
                        End If
                    End If
                End If
            End If

            PodeAcumularDigito = _ok
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
