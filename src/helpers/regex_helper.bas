' COM object: CreateObject("VBScript.RegExp")
' Docs: https://documentation.help/VBSCRIP5/vsobjRegExp.htm
'       https://learn.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/scripting-articles/ms974570(v=msdn.10)
'       https://www.regular-expressions.info/vbscript.html
' Replace supports backreferences: $1, $2, etc.
' Note: VBScript COM may be deprecated on future Windows versions.

Imports Collections
Imports mod_tobject
Imports mod_logger

Namespace regex_helper
    Class Regex
        Inherits TTObject

        Private _global As Boolean
        Private _ignoreCase As Boolean
        Private _pattern As String
        Private _regExp As Variant

        Sub New(pGlobal As Boolean = True, pIgnoreCase As Boolean = True, pPattern As String = "")
            MyBase.New()
            me._global = pGlobal
            me._ignoreCase = pIgnoreCase
            me._pattern = ""
            me._regExp = CreateObject("VBScript.RegExp")
            me.ApplySettings()

            If pPattern <> "" Then
                me.SetPattern(pPattern)
            End If
        End Sub

        Shared Function WithPattern(pPattern As String, pGlobal As Boolean = True, pIgnoreCase As Boolean = True) As Regex
            WithPattern = New Regex(pGlobal, pIgnoreCase, pPattern)
        End Function

        Private Sub ApplySettings()
            me._regExp.IgnoreCase = me._ignoreCase
            me._regExp.Global = me._global

            If me._pattern <> "" Then
                me._regExp.Pattern = me._pattern
            End If
        End Sub

        Private Sub ValidatePattern()
            If me._pattern = "" Then
                Exit Sub
            End If

            Dim _tested As Boolean = me._regExp.Test("")
        End Sub

        Private Sub SetPattern(pValue As String)
            me._pattern = pValue
            me._regExp.Pattern = pValue
            me.ValidatePattern()
        End Sub

        Private Function GetMatches(pValue As String) As Variant
            GetMatches = me._regExp.Execute(pValue)
        End Function

        Shared Function EscapeLiteral(pValue As String) As String
            Dim _special As String = "\^$.|?+*()[]{}"
            Dim _result As String = ""
            Dim _i As Integer
            Dim _char As String = ""
            Dim _j As Integer
            Dim _specialChar As String = ""
            Dim _isSpecial As Boolean = False

            For _i = 1 To pValue.Length
                _char = Mid(pValue, _i, 1)
                _isSpecial = False

                For _j = 1 To _special.Length
                    _specialChar = Mid(_special, _j, 1)

                    If _char = _specialChar Then
                        _isSpecial = True
                        Exit For
                    End If
                Next

                If _isSpecial Then
                    _result = _result + "\" + _char
                Else
                    _result = _result + _char
                End If
            Next

            EscapeLiteral = _result
        End Function

        Property MatchGlobal As Boolean
            Get
                MatchGlobal = me._global
            End Get
            Set(pValue As Boolean)
                me._global = pValue
                me.ApplySettings()
            End Set
        End Property

        Property IgnoreCase As Boolean
            Get
                IgnoreCase = me._ignoreCase
            End Get
            Set(pValue As Boolean)
                me._ignoreCase = pValue
                me.ApplySettings()
            End Set
        End Property

        Property Pattern As String
            Get
                Pattern = me._pattern
            End Get
            Set(pValue As String)
                me.SetPattern(pValue)
            End Set
        End Property

        Function Expression(pValue As String) As Regex
            me.SetPattern(pValue)
            Expression = me
        End Function

        Function Test(pValue As String) As Boolean
            Dim _matched As Boolean = me._regExp.Test(pValue)
            Test = _matched
        End Function

        Function Match(pValue As String) As Boolean
            Match = me.Test(pValue)
        End Function

        Function IsFullMatch(pValue As String) As Boolean
            If Not me.Test(pValue) Then
                IsFullMatch = False
                Exit Function
            End If

            Dim _matches As Variant = me.GetMatches(pValue)

            If _matches.Count <> 1 Then
                IsFullMatch = False
                Exit Function
            End If

            Dim _start As Integer = CInt(_matches.Item(0).FirstIndex)
            Dim _length As Integer = CInt(_matches.Item(0).Length)
            IsFullMatch = _start = 0 And (_start + _length) = pValue.Length
        End Function

        Function MatchCount(pValue As String) As Integer
            Dim _matches As Variant = me.GetMatches(pValue)
            MatchCount = _matches.Count
        End Function

        Function FirstIndex(pValue As String) As Integer
            Dim _matches As Variant = me.GetMatches(pValue)

            If _matches.Count = 0 Then
                FirstIndex = -1
                Exit Function
            End If

            Dim _index As Integer = CInt(_matches.Item(0).FirstIndex)
            FirstIndex = _index
        End Function

        Function MatchLength(pValue As String) As Integer
            Dim _matches As Variant = me.GetMatches(pValue)

            If _matches.Count = 0 Then
                MatchLength = 0
                Exit Function
            End If

            Dim _length As Integer = CInt(_matches.Item(0).Length)
            MatchLength = _length
        End Function

        Function FirstMatch(pValue As String) As String
            Dim _matches As Variant = me.GetMatches(pValue)

            If _matches.Count = 0 Then
                FirstMatch = ""
                Exit Function
            End If

            Dim _value As String = CStr(_matches.Item(0).Value)
            FirstMatch = _value
        End Function

        Function FirstSubMatch(pValue As String, pGroupIndex As Integer = 0) As String
            Dim _matches As Variant = me.GetMatches(pValue)

            If _matches.Count = 0 Then
                FirstSubMatch = ""
                Exit Function
            End If

            Dim _subMatches As Variant = _matches.Item(0).SubMatches

            If pGroupIndex < 0 Or pGroupIndex >= _subMatches.Count Then
                FirstSubMatch = ""
                Exit Function
            End If

            Dim _value As String = CStr(_subMatches.Item(pGroupIndex))
            FirstSubMatch = _value
        End Function

        Function Matches(pValue As String) As StringList
            Dim _result As StringList = New StringList()
            Dim _matches As Variant = me.GetMatches(pValue)
            Dim _i As Integer

            For _i = 0 To _matches.Count - 1
                Dim _value As String = CStr(_matches.Item(_i).Value)
                _result.Add(_value)
            Next

            Matches = _result
        End Function

        Function SubMatches(pValue As String, pMatchIndex As Integer = 0) As StringList
            Dim _result As StringList = New StringList()
            Dim _matches As Variant = me.GetMatches(pValue)

            If _matches.Count = 0 Or pMatchIndex < 0 Or pMatchIndex >= _matches.Count Then
                SubMatches = _result
                Exit Function
            End If

            Dim _subMatches As Variant = _matches.Item(pMatchIndex).SubMatches
            Dim _i As Integer

            For _i = 0 To _subMatches.Count - 1
                Dim _value As String = CStr(_subMatches.Item(_i))
                _result.Add(_value)
            Next

            SubMatches = _result
        End Function

        Function Split(pValue As String) As StringList
            Dim _result As StringList = New StringList()
            Dim _matches As Variant = me.GetMatches(pValue)

            If _matches.Count = 0 Then
                _result.Add(pValue)
                Split = _result
                Exit Function
            End If

            Dim _lastEnd As Integer = 0
            Dim _i As Integer
            Dim _start As Integer = 0
            Dim _length As Integer = 0
            Dim _part As String = ""

            For _i = 0 To _matches.Count - 1
                _start = CInt(_matches.Item(_i).FirstIndex)

                If _start > _lastEnd Then
                    _part = Mid(pValue, _lastEnd + 1, _start - _lastEnd)
                    _result.Add(_part)
                End If

                _length = CInt(_matches.Item(_i).Length)
                _lastEnd = _start + _length
            Next

            If _lastEnd < pValue.Length Then
                _part = Mid(pValue, _lastEnd + 1, pValue.Length - _lastEnd)
                _result.Add(_part)
            End If

            Split = _result
        End Function

        Function Replace(pText As String, pNewValue As String) As String
            Dim _value As Variant = me._regExp.Replace(pText, pNewValue)
            Dim _result As String = CStr(_value)
            Replace = _result
        End Function

        ' Centraliza o log de falha usado pelos wrappers estaticos (Try*/IsFullTextMatch),
        ' evitando repetir a mesma mensagem/format em cada Catch.
        Private Shared Sub LogFailure(pOperation As String, pException As Exception)
            mod_logger.Warn("Regex." + pOperation + " failed: " + Char(13) + pException._getMessage())
        End Sub

        ' Idem: centraliza o "libere se foi criado" usado pelos wrappers estaticos.
        Private Shared Sub SafeFree(pRegex As Regex)
            If Assigned(pRegex) Then
                pRegex.Free()
            End If
        End Sub

        Shared Function TryIsMatch(pPattern As String, pValue As String, ByRef pMatched As Boolean, pGlobal As Boolean = True, pIgnoreCase As Boolean = True) As Boolean
            Dim _regex As Regex = Null

            Try
                _regex = New Regex(pGlobal, pIgnoreCase, pPattern)
                pMatched = _regex.Test(pValue)
                _regex.Free()
                TryIsMatch = True
            Catch ex As Exception
                Regex.SafeFree(_regex)
                Regex.LogFailure("TryIsMatch", ex)
                Return False
            End Try
        End Function

        Shared Function IsMatch(pPattern As String, pValue As String, pGlobal As Boolean = True, pIgnoreCase As Boolean = True) As Boolean
            Dim _matched As Boolean = False

            If Not Regex.TryIsMatch(pPattern, pValue, _matched, pGlobal, pIgnoreCase) Then
                Throw New System.Exception("Invalid regex pattern: " + pPattern)
            End If

            IsMatch = _matched
        End Function

        Shared Function TryReplaceText(pPattern As String, pText As String, pNewValue As String, ByRef pResult As String, pGlobal As Boolean = True, pIgnoreCase As Boolean = True) As Boolean
            Dim _regex As Regex = Null

            Try
                _regex = New Regex(pGlobal, pIgnoreCase, pPattern)
                pResult = _regex.Replace(pText, pNewValue)
                _regex.Free()
                TryReplaceText = True
            Catch ex As Exception
                Regex.SafeFree(_regex)
                Regex.LogFailure("TryReplaceText", ex)
                Return False
            End Try
        End Function

        Shared Function ReplaceText(pPattern As String, pText As String, pNewValue As String, pGlobal As Boolean = True, pIgnoreCase As Boolean = True) As String
            Dim _result As String = pText

            If Not Regex.TryReplaceText(pPattern, pText, pNewValue, _result, pGlobal, pIgnoreCase) Then
                Throw New System.Exception("Invalid regex pattern: " + pPattern)
            End If

            ReplaceText = _result
        End Function

        Shared Function IsFullTextMatch(pPattern As String, pValue As String, pGlobal As Boolean = True, pIgnoreCase As Boolean = True) As Boolean
            Dim _regex As Regex = Null

            Try
                _regex = New Regex(pGlobal, pIgnoreCase, pPattern)
                IsFullTextMatch = _regex.IsFullMatch(pValue)
                _regex.Free()
            Catch ex As Exception
                Regex.SafeFree(_regex)
                Regex.LogFailure("IsFullTextMatch", ex)
                Throw New System.Exception("Invalid regex pattern: " + pPattern)
            End Try
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me._pattern = ""
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
                Throw New System.Exception("Error freeing Regex: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
