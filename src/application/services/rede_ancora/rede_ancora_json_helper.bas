Imports mod_tobject
Imports try_parser
Imports string_helper

Namespace rede_ancora_json_helper
    Class RedeAncoraJsonHelper
        Inherits TTObject

        Private Shared Function AspasJson() As String
            AspasJson = CStr(Chr(34))
        End Function

        Private Shared Function MontarMarcadorJson(pKey As String) As String
            Dim _quote As String = AspasJson()

            MontarMarcadorJson = _quote + pKey + _quote + ":"
        End Function

        ' Localiza a posicao (1-based) do primeiro caractere nao-branco apos o marcador "key":
        ' Retorna 0 se a chave nao existir no blob.
        Private Shared Function LocalizarInicioValor(pBlob As String, pKey As String) As Integer
            Dim _marker As String = MontarMarcadorJson(pKey)
            Dim _blobLen As Integer = pBlob.Length
            Dim _markerLen As Integer = _marker.Length
            Dim _pos As Integer = 0
            Dim _start As Integer = 0
            Dim _ch As String = ""

            LocalizarInicioValor = 0

            If Not pBlob.Contains(_marker) Then
                Exit Function
            End If

            For _pos = 1 To _blobLen - _markerLen + 1
                If Mid(pBlob, _pos, _markerLen) = _marker Then
                    _start = _pos + _markerLen
                    Exit For
                End If
            Next

            If _start <= 0 Then
                Exit Function
            End If

            _ch = Mid(pBlob, _start, 1)

            While _ch = " " And _start < _blobLen
                _start = _start + 1
                _ch = Mid(pBlob, _start, 1)
            Wend

            LocalizarInicioValor = _start
        End Function

        ' Mesmo que LocalizarInicioValor, mas comeca a busca em pFromPos (1-based).
        Private Shared Function LocalizarInicioValorApartir(pBlob As String, pKey As String, pFromPos As Integer) As Integer
            Dim _marker As String = MontarMarcadorJson(pKey)
            Dim _blobLen As Integer = pBlob.Length
            Dim _markerLen As Integer = _marker.Length
            Dim _pos As Integer = 0
            Dim _start As Integer = 0
            Dim _ch As String = ""

            LocalizarInicioValorApartir = 0

            If Not pBlob.Contains(_marker) Then
                Exit Function
            End If

            If pFromPos < 1 Then
                pFromPos = 1
            End If

            For _pos = pFromPos To _blobLen - _markerLen + 1
                If Mid(pBlob, _pos, _markerLen) = _marker Then
                    _start = _pos + _markerLen
                    Exit For
                End If
            Next

            If _start <= 0 Then
                Exit Function
            End If

            _ch = Mid(pBlob, _start, 1)

            While _ch = " " And _start < _blobLen
                _start = _start + 1
                _ch = Mid(pBlob, _start, 1)
            Wend

            LocalizarInicioValorApartir = _start
        End Function

        ' Extrai o bloco bruto (objeto {..} ou array [..]) de uma chave, sem usar getters
        ' tipados do TJSONObject (evita EVariantTypeCastError com tipos mistos da API).
        Shared Function ObterBlocoJson(pJson As TJSONObject, pKey As String) As String
            Dim _blob As String = pJson.ToString()
            Dim _quote As String = AspasJson()
            Dim _start As Integer = 0
            Dim _searchFrom As Integer = 1
            Dim _ch As String = ""
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escapeNext As Boolean = False
            Dim _i As Integer = 0
            Dim _blobLen As Integer = _blob.Length
            Dim _found As Boolean = False

            ObterBlocoJson = ""

            While _searchFrom > 0 And _searchFrom <= _blobLen
                _start = LocalizarInicioValorApartir(_blob, pKey, _searchFrom)

                If _start <= 0 Then
                    Exit Function
                End If

                _ch = Mid(_blob, _start, 1)

                If _ch = "{" Or _ch = "[" Then
                    _found = True
                    Exit While
                End If

                _searchFrom = _start + 1
            Wend

            If Not _found Then
                Exit Function
            End If

            For _i = _start To _blobLen
                _ch = Mid(_blob, _i, 1)

                If _escapeNext Then
                    _escapeNext = False
                ElseIf _inQuotes Then
                    If _ch = "\" Then
                        _escapeNext = True
                    ElseIf _ch = _quote Then
                        _inQuotes = False
                    End If
                Else
                    If _ch = _quote Then
                        _inQuotes = True
                    ElseIf _ch = "{" Or _ch = "[" Then
                        _depth = _depth + 1
                    ElseIf _ch = "}" Or _ch = "]" Then
                        _depth = _depth - 1

                        If _depth = 0 Then
                            ObterBlocoJson = Mid(_blob, _start, _i - _start + 1)
                            Exit Function
                        End If
                    End If
                End If
            Next
        End Function

        Shared Function ObterArrayJson(pJson As TJSONObject, pKey As String) As TJSONArray
            Dim _raw As String = RedeAncoraJsonHelper.ObterBlocoJson(pJson, pKey)

            If Mid(_raw.Trim(), 1, 1) <> "[" Then
                ObterArrayJson = NULL
                Exit Function
            End If

            ObterArrayJson = New TJSONArray(_raw)
        End Function

        ' Retorna o bloco bruto do elemento pIndex (0-based) de um array JSON "[...]".
        Shared Function ExtrairElementoArrayJson(pArrayBlob As String, pIndex As Integer) As String
            Dim _blob As String = pArrayBlob.Trim()
            Dim _blobLen As Integer = _blob.Length
            Dim _quote As String = AspasJson()
            Dim _pos As Integer = 2
            Dim _elemStart As Integer = 0
            Dim _elemIndex As Integer = 0
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escapeNext As Boolean = False
            Dim _ch As String = ""
            Dim _i As Integer = 0

            ExtrairElementoArrayJson = ""

            If pIndex < 0 Then
                Exit Function
            End If

            If _blobLen < 2 Then
                Exit Function
            End If

            If Mid(_blob, 1, 1) <> "[" Then
                Exit Function
            End If

            While _pos <= _blobLen
                _ch = Mid(_blob, _pos, 1)

                If _escapeNext Then
                    _escapeNext = False
                ElseIf _inQuotes Then
                    If _ch = "\" Then
                        _escapeNext = True
                    ElseIf _ch = _quote Then
                        _inQuotes = False
                    End If
                Else
                    If _ch = _quote Then
                        _inQuotes = True
                    ElseIf _ch = "[" Or _ch = "{" Then
                        If _depth = 0 Then
                            _elemStart = _pos
                        End If

                        _depth = _depth + 1
                    ElseIf _ch = "]" Or _ch = "}" Then
                        If _depth = 1 And _elemStart > 0 Then
                            If _elemIndex = pIndex Then
                                ExtrairElementoArrayJson = Mid(_blob, _elemStart, _pos - _elemStart + 1)
                                Exit Function
                            End If

                            _elemIndex = _elemIndex + 1
                            _elemStart = 0
                        End If

                        _depth = _depth - 1

                        If _depth = 0 And _ch = "]" Then
                            Exit Function
                        End If
                    ElseIf _ch = "," And _depth = 0 Then
                        If _elemStart > 0 Then
                            If _elemIndex = pIndex Then
                                ExtrairElementoArrayJson = Mid(_blob, _elemStart, _pos - _elemStart).Trim()
                                Exit Function
                            End If

                            _elemIndex = _elemIndex + 1
                            _elemStart = 0
                        End If
                    ElseIf _depth = 0 And _elemStart = 0 And _ch <> " " And _ch <> "," And _ch <> "]" Then
                        _elemStart = _pos
                    End If
                End If

                _pos = _pos + 1
            Wend
        End Function

        ' Retorna o bloco bruto do objeto filho pIndex (0-based) em um objeto JSON "{...}".
        Shared Function ExtrairObjetoFilhoJson(pObjectBlob As String, pIndex As Integer) As String
            Dim _blob As String = pObjectBlob.Trim()
            Dim _blobLen As Integer = _blob.Length
            Dim _quote As String = AspasJson()
            Dim _pos As Integer = 2
            Dim _valueStart As Integer = 0
            Dim _objIndex As Integer = 0
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escapeNext As Boolean = False
            Dim _ch As String = ""
            Dim _childBlob As String = ""

            ExtrairObjetoFilhoJson = ""

            If pIndex < 0 Then
                Exit Function
            End If

            If _blobLen < 2 Then
                Exit Function
            End If

            If Mid(_blob, 1, 1) <> "{" Then
                Exit Function
            End If

            While _pos <= _blobLen
                _ch = Mid(_blob, _pos, 1)

                If _escapeNext Then
                    _escapeNext = False
                ElseIf _inQuotes Then
                    If _ch = "\" Then
                        _escapeNext = True
                    ElseIf _ch = _quote Then
                        _inQuotes = False
                    End If
                Else
                    If _ch = _quote Then
                        _inQuotes = True
                    ElseIf _ch = "{" Or _ch = "[" Then
                        If _depth = 0 And _valueStart = 0 Then
                            _valueStart = _pos
                        End If

                        _depth = _depth + 1
                    ElseIf _ch = "}" Or _ch = "]" Then
                        If _depth = 1 And _valueStart > 0 Then
                            _childBlob = Mid(_blob, _valueStart, _pos - _valueStart + 1)

                            If Mid(_childBlob.Trim(), 1, 1) = "{" Then
                                If _objIndex = pIndex Then
                                    ExtrairObjetoFilhoJson = _childBlob
                                    Exit Function
                                End If

                                _objIndex = _objIndex + 1
                            End If

                            _valueStart = 0
                        End If

                        _depth = _depth - 1

                        If _depth < 0 Then
                            Exit Function
                        End If
                    ElseIf _ch = "," And _depth = 0 Then
                        _valueStart = 0
                    ElseIf _depth = 0 And _valueStart = 0 And _ch <> " " And _ch <> ":" Then
                        If _ch <> "," Then
                            _valueStart = _pos
                        End If
                    End If
                End If

                _pos = _pos + 1
            Wend
        End Function

        Shared Function ObterObjetoJson(pJson As TJSONObject, pKey As String) As TJSONObject
            Dim _raw As String = RedeAncoraJsonHelper.ObterBlocoJson(pJson, pKey)

            If Mid(_raw.Trim(), 1, 1) <> "{" Then
                ObterObjetoJson = NULL
                Exit Function
            End If

            ObterObjetoJson = New TJSONObject(_raw)
        End Function

        ' Aceita "user"/"company" tanto como objeto (formato atual da API) quanto
        ' como array de 1 posicao (formato legado da documentacao).
        Shared Function ObterFilhoJson(pJson As TJSONObject, pKey As String) As TJSONObject
            Dim _obj As TJSONObject = NULL
            Dim _arr As TJSONArray = NULL

            ObterFilhoJson = NULL

            _obj = RedeAncoraJsonHelper.ObterObjetoJson(pJson, pKey)
            If Assigned(_obj) Then
                ObterFilhoJson = _obj
                Exit Function
            End If

            _arr = RedeAncoraJsonHelper.ObterArrayJson(pJson, pKey)
            If Not Assigned(_arr) Then
                Exit Function
            End If

            If _arr.Length() <= 0 Then
                _arr.Free()
                Exit Function
            End If

            ObterFilhoJson = _arr.GetJSONObject(0)
            _arr.Free()
        End Function

        Shared Function ObterDataArray(pJson As TJSONObject) As TJSONArray
            ObterDataArray = RedeAncoraJsonHelper.ObterArrayJson(pJson, "data")
        End Function

        Shared Function ObterDataObjeto(pJson As TJSONObject) As TJSONObject
            ObterDataObjeto = RedeAncoraJsonHelper.ObterObjetoJson(pJson, "data")
        End Function

        Shared Function ObterRaizOuDataObjeto(pJson As TJSONObject) As TJSONObject
            ObterRaizOuDataObjeto = RedeAncoraJsonHelper.ObterDataObjeto(pJson)
        End Function

        Shared Function UsarRaizOuData(pJson As TJSONObject, pData As TJSONObject) As TJSONObject
            If Assigned(pData) Then
                UsarRaizOuData = pData
                Exit Function
            End If

            UsarRaizOuData = pJson
        End Function

        ' Le um valor escalar (numero, string ou boolean) de uma chave, sem usar
        ' getters tipados do TJSONObject (evita EVariantTypeCastError).
        Shared Function ObterTextoJson(pJson As TJSONObject, pKey As String) As String
            Dim _blob As String = pJson.ToString()
            Dim _quote As String = AspasJson()
            Dim _start As Integer = LocalizarInicioValor(_blob, pKey)
            Dim _tail As String = ""
            Dim _ch As String = ""
            Dim _i As Integer = 0
            Dim _result As String = ""

            ObterTextoJson = ""

            If _start <= 0 Then
                Exit Function
            End If

            _tail = Mid(_blob, _start, _blob.Length - _start + 1)
            _ch = Mid(_tail, 1, 1)

            If _ch = _quote Then
                ObterTextoJson = StringHelper.GetStringPart(_quote, _quote, _tail)
                Exit Function
            End If

            For _i = 1 To _tail.Length
                _ch = Mid(_tail, _i, 1)

                If _ch = "," Or _ch = "}" Or _ch = "]" Then
                    Exit For
                End If

                _result = _result + CStr(_ch)
            Next

            ObterTextoJson = _result.Trim()
        End Function

        Shared Function ObterDecimalJson(pJson As TJSONObject, pKey As String) As Double
            ObterDecimalJson = Parser.StringToDouble(RedeAncoraJsonHelper.ObterTextoJson(pJson, pKey))
        End Function

        Shared Function ObterBooleanJson(pJson As TJSONObject, pKey As String) As Boolean
            Dim _raw As String = RedeAncoraJsonHelper.ObterTextoJson(pJson, pKey).Trim().ToLower()

            ObterBooleanJson = _raw = "true" Or _raw = "1" Or _raw = "s" Or _raw = "sim"
        End Function

        Shared Function SimNao(pValor As Boolean) As String
            If pValor Then
                SimNao = "S"
            Else
                SimNao = "N"
            End If
        End Function

        Shared Function ObterInteiroJson(pJson As TJSONObject, pKey As String) As Integer
            ObterInteiroJson = Parser.StringToInteger(RedeAncoraJsonHelper.ObterTextoJson(pJson, pKey))
        End Function

        Shared Function ObterInteiroJsonOpcional(pJson As TJSONObject, pKey As String) As Integer
            ObterInteiroJsonOpcional = RedeAncoraJsonHelper.ObterInteiroJson(pJson, pKey)
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            If Not me.Disposed Then
                me.Dispose()
            End If

            MyBase.Free()
        End Sub

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
