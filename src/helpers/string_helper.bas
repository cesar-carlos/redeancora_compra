Imports Collections
Imports regex_helper
Imports mod_tobject

Namespace string_helper
    Class StringHelper
        Inherits TTObject

        Private Shared Function CharAt(pValue As String, pOneBasedIndex As Integer) As String
            If pOneBasedIndex < 1 Or pOneBasedIndex > pValue.Length Then
                CharAt = ""
                Exit Function
            End If
            Dim _char As String = Mid(pValue, pOneBasedIndex, 1)
            CharAt = _char
        End Function

        ' Reaproveitado por FillCharacterLeft/FillCharacterRight para evitar
        ' duplicar o loop de construcao de padding em ambas as funcoes.
        Private Shared Function BuildPadding(pCharacter As String, pLength As Integer) As String
            Dim _padding As String = ""
            Dim _i As Integer

            For _i = 1 To pLength
                _padding = _padding + pCharacter
            Next

            BuildPadding = _padding
        End Function

        Shared Function GetStringPart(pStartCharacter As String, pEndCharacter As String, pValue As String) As String
            If pStartCharacter = "" Or pEndCharacter = "" Then
                GetStringPart = ""
                Exit Function
            End If

            Dim _pattern As String = Regex.EscapeLiteral(pStartCharacter) + "(.*?)" + Regex.EscapeLiteral(pEndCharacter)
            Dim _regex As Regex = Regex.WithPattern(_pattern, True, False)
            Dim _matched As String = _regex.FirstSubMatch(pValue, 0)

            If _matched = "" Then
                _matched = _regex.FirstMatch(pValue)
            End If

            If _matched = "" Then
                _regex.Free()
                GetStringPart = ""
                Exit Function
            End If

            GetStringPart = _matched.Trim()
            _regex.Free()
        End Function

        Shared Function ReverseString(pValue As String) As String
            Dim _index As Integer = pValue.Length
            Dim _result As String = ""

            While _index > 0
                _result = _result + StringHelper.CharAt(pValue, _index)
                _index = _index - 1
                Wend

                ReverseString = _result
            End Function

            Shared Function GetStringParts(pStartCharacter As String, pEndCharacter As String, pValue As String) As StringList
                Dim _limit As Integer = 256
                Dim _remaining As String = pValue
                Dim _part As String = ""
                Dim _result As StringList = New StringList()
                Dim _lowerValue As String = pValue.ToLower()
                Dim _lowerStart As String = pStartCharacter.ToLower()
                Dim _lowerEnd As String = pEndCharacter.ToLower()

                If _lowerValue.Contains(_lowerStart) And _lowerValue.Contains(_lowerEnd) Then
                    While _remaining <> "" And _remaining.ToLower().Contains(_lowerStart) And _remaining.ToLower().Contains(_lowerEnd)
                        _part = StringHelper.GetStringPart(pStartCharacter, pEndCharacter, _remaining)

                        If _part = "" Then
                            Exit While
                        End If

                        _remaining = _remaining.Replace(_part, "")
                        _result.Add(_part)
                        _limit = _limit - 1

                        If _limit = 0 Then
                            Exit While
                        End If
                        Wend
                    End If

                    GetStringParts = _result
                End Function

                Shared Function ReadString(pStart As Integer, pEnd As Integer, pValue As String) As String
                    Dim _i As Integer
                    Dim _result As String = ""

                    If pStart > pEnd Then
                        ReadString = ""
                        Exit Function
                    End If

                    If pStart <= 0 Then
                        pStart = 1
                    End If

                    If pEnd > pValue.Length Then
                        pEnd = pValue.Length
                    End If

                    For _i = pStart To pValue.Length
                        _result = _result + StringHelper.CharAt(pValue, _i)

                        If _i = pEnd Then
                            Exit For
                        End If
                    Next

                    ReadString = _result
                End Function

                Shared Function SubString(pStart As Integer, pLength As Integer, pValue As String) As String
                    Dim _i As Integer
                    Dim _endIndex As Integer
                    Dim _result As String = ""

                    If pStart <= 0 Then
                        pStart = 1
                    End If

                    If (pStart + pLength) > pValue.Length Then
                        _endIndex = pValue.Length
                    Else
                        _endIndex = (pStart + pLength) - 1
                    End If

                    For _i = pStart To _endIndex
                        _result = _result + StringHelper.CharAt(pValue, _i)
                    Next

                    SubString = _result
                End Function

                Shared Function CountCharacter(pCharacter As String, pValue As String) As Integer
                    If pCharacter = "" Or pValue = "" Then
                        CountCharacter = 0
                        Exit Function
                    End If

                    Dim _regex As Regex = Regex.WithPattern(Regex.EscapeLiteral(pCharacter), True, False)
                    CountCharacter = _regex.MatchCount(pValue)
                    _regex.Free()
                End Function

                Shared Function FillCharacterLeft(pValue As String, pCharacter As String, pLength As Integer) As String
                    Dim _fillLength As Integer = pLength - pValue.Length

                    If _fillLength <= 0 Then
                        FillCharacterLeft = pValue
                        Exit Function
                    End If

                    FillCharacterLeft = StringHelper.BuildPadding(pCharacter, _fillLength) + pValue
                End Function

                Shared Function FillCharacterRight(pValue As String, pCharacter As String, pLength As Integer) As String
                    Dim _fillLength As Integer = pLength - pValue.Length

                    If pValue.Length > pLength Then
                        FillCharacterRight = StringHelper.SubString(1, pLength, pValue)
                        Exit Function
                    End If

                    If _fillLength <= 0 Then
                        FillCharacterRight = pValue
                        Exit Function
                    End If

                    FillCharacterRight = pValue + StringHelper.BuildPadding(pCharacter, _fillLength)
                End Function

                Shared Function RemoveLeftCharacter(pValue As String, pCharacter As String) As String
                    If pCharacter = "" Then
                        RemoveLeftCharacter = pValue
                        Exit Function
                    End If

                    Dim _pattern As String = "^" + Regex.EscapeLiteral(pCharacter) + "+"
                    RemoveLeftCharacter = Regex.ReplaceText(_pattern, pValue, "", False, False)
                End Function

                Shared Function SplitToList(pDelimiter As String, pValue As String) As StringList
                    Dim _result As StringList = New StringList()
                    Dim _remaining As String = pValue
                    Dim _part As String = ""

                    Try
                        If Not pValue.Contains(pDelimiter) Then
                            SplitToList = _result
                            Exit Function
                        End If

                        While _remaining.Contains(pDelimiter)
                            _part = _remaining.Split(pDelimiter)[0].Trim()
                            _result.Add(_part)
                            _remaining = _remaining.Split(pDelimiter)[1]
                            Wend

                            _result.Add(_remaining.Trim())
                            SplitToList = _result
                        Catch ex As Exception
                            Return _result
                        End Try
                    End Function

                    Shared Function ExtractNumbers(pValue As String) As String
                        ExtractNumbers = Regex.ReplaceText("[^0-9]", pValue, "", True, False)
                    End Function

                    Shared Function ExtractNumbersWithoutLeadingZeros(pValue As String) As String
                        Dim _numbers As String = StringHelper.ExtractNumbers(pValue)
                        ExtractNumbersWithoutLeadingZeros = Regex.ReplaceText("^0+", _numbers, "", False, False)
                    End Function

                    Shared Function IntegerToStringMask(pValue As Integer, pFormatCharacter As String, pFormatQuantity As Integer) As String
                        Dim _result As String = ""
                        Dim _valueText As String = pValue.ToString()
                        Dim _i As Integer
                        Dim _loops As Integer

                        If pValue > 0 Then
                            If pFormatQuantity > 0 And pFormatQuantity <= 99 Then
                                If pFormatCharacter <> "" Then
                                    _loops = (pFormatQuantity - 1) - _valueText.Length

                                    For _i = 0 To _loops
                                        _result = _result + pFormatCharacter
                                    Next
                                End If
                            End If
                        End If

                        IntegerToStringMask = _result + _valueText
                    End Function

                    Shared Function SplitAndFirst(pDelimiter As String, pValue As String) As String
                        Try
                            If Not pValue.Contains(pDelimiter) Then
                                SplitAndFirst = pValue
                                Exit Function
                            End If

                            SplitAndFirst = pValue.Split(pDelimiter)[0].Trim()
                        Catch ex As Exception
                            Return pValue
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
                            Throw New System.Exception("Error freeing StringHelper: " + Char(13) + ex._getMessage())
                        End Try
                    End Sub

                    Sub New()
                        MyBase.New()
                    End Sub
                End Class
            End Namespace
