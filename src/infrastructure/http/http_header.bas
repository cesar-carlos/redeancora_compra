Imports Collections
Imports mod_tobject

Namespace http_header
    ' Key/value header store. Reaproveita o suporte nativo de pares nome/valor
    ' do StringList (Values/Names/IndexOfName/NameValueSeparator) em vez de
    ' reimplementar parsing manual de string. Usa Chr(1) como separador (em vez
    ' do "=" padrao) para suportar valores de header que contenham "=" (ex.:
    ' Base64 em Authorization). Preserva ordem de insercao; Add para uma chave
    ' existente substitui o valor anterior.
    Class HttpHeader
        Inherits TTObject

        Private _entries As StringList

        Sub New()
            MyBase.New()
            me._entries = New StringList()
            me._entries.NameValueSeparator = Chr(1)
        End Sub

        Sub Add(pKey As String, pValue As String)
            me.Remove(pKey)
            me._entries.Add(pKey + me._entries.NameValueSeparator + pValue)
        End Sub

        Function Contains(pKey As String) As Boolean
            Contains = me._entries.IndexOfName(pKey) >= 0
        End Function

        Function TryGetValue(pKey As String, ByRef pValue As String) As Boolean
            If Not me.Contains(pKey) Then
                TryGetValue = False
                Exit Function
            End If

            pValue = me._entries.Values(pKey)
            TryGetValue = True
        End Function

        Function GetValue(pKey As String) As String
            Dim _val As String = ""
            GetValue = ""

            If me.TryGetValue(pKey, _val) Then
                GetValue = _val
            End If
        End Function

        Sub Remove(pKey As String)
            Dim _index As Integer = me._entries.IndexOfName(pKey)

            If _index >= 0 Then
                me._entries.Delete(_index)
            End If
        End Sub

        Sub Clear()
            me._entries.Clear()
        End Sub

        Function Count() As Integer
            Count = me._entries.Count
        End Function

        ' Applies headers to a WinHttp COM object (after Open, before Send).
        Sub ApplyToWinHttp(pHttp As Variant)
            Dim _i As Integer
            Dim _key As String = ""

            For _i = 0 To me._entries.Count - 1
                _key = me._entries.Names(_i)
                pHttp.SetRequestHeader(_key, me._entries.Values(_key))
            Next
        End Sub

        Function ToJsonObject() As TJSONObject
            Dim _json As New TJSONObject()
            Dim _i As Integer
            Dim _key As String = ""

            For _i = 0 To me._entries.Count - 1
                _key = me._entries.Names(_i)
                _json.PutString(_key, me._entries.Values(_key))
            Next

            ToJsonObject = _json
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._entries) Then
                    me._entries.Free()
                    me._entries = NULL
                End If

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
                Throw New System.Exception("Error freeing HttpHeader: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
