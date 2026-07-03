Imports mod_tobject
Imports http_header

Namespace http_response
    ' Encapsulates the result of a WinHttp request.
    Class HttpResponse
        Inherits TTObject

        StatusCode As Integer
        StatusText As String
        Body As String
        IsSuccess As Boolean

        Private _headers As HttpHeader

        Sub New()
            MyBase.New()
            me.StatusCode = 0
            me.StatusText = ""
            me.Body = ""
            me.IsSuccess = False
            me._headers = New HttpHeader()
        End Sub

        Function Headers() As HttpHeader
            Headers = me._headers
        End Function

        Function GetHeader(pKey As String) As String
            GetHeader = me._headers.GetValue(pKey)
        End Function

        Function BodyAsJsonObject() As TJSONObject
            BodyAsJsonObject = New TJSONObject(me.NormalizeBody(me.Body))
        End Function

        ' Returns { "Header": {...}, "Body": {...}, "StatusCode": n, "StatusText": "...", "Success": ... }
        Function ToEnvelopeJson() As String
            Dim _envelope As New TJSONObject()
            Dim _bodyJson As TJSONObject = me.BodyAsJsonObject()
            Dim _headerJson As TJSONObject = me._headers.ToJsonObject()

            _envelope.PutObject("Header", _headerJson)
            _envelope.PutObject("Body", _bodyJson)
            _envelope.PutInteger("StatusCode", me.StatusCode)
            _envelope.PutString("StatusText", me.StatusText)
            _envelope.PutBoolean("Success", me.IsSuccess)

            ToEnvelopeJson = _envelope.ToString()
            _bodyJson.Free()
            _headerJson.Free()
            _envelope.Free()
        End Function

        ' Wraps bare JSON arrays so TJSONObject can parse them:
        '   [{...}]  →  {"Data":[{...}]}
        Private Function NormalizeBody(pRaw As String) As String
            Dim _payload As String = pRaw.Trim()

            If _payload = "" Then
                NormalizeBody = "{}"
                Exit Function
            End If

            If Mid(_payload, 1, 2) = "[{" Or Mid(_payload, 1, 1) = "[" Then
                NormalizeBody = "{""Data"":" + _payload + "}"
                Exit Function
            End If

            NormalizeBody = _payload
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._headers) Then
                    me._headers.Free()
                    me._headers = NULL
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
                Throw New System.Exception("Error freeing HttpResponse: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
