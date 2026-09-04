Imports mod_tobject
Imports try_parser

Namespace rede_ancora_json_helper
    Class RedeAncoraJsonHelper
        Inherits TTObject

        Private Shared Function AspasJson() As String
            AspasJson = Chr(34)
        End Function

        Private Shared Function MontarMarcadorJson(pKey As String) As String
            Dim _quote As String = AspasJson()

            MontarMarcadorJson = _quote & pKey & _quote & ":"
        End Function

        Private Shared Function EhBrancoJson(pCh As String) As Boolean
            EhBrancoJson = False

            If pCh = " " Then
                EhBrancoJson = True
                Exit Function
            End If

            If pCh = Chr(9) Then
                EhBrancoJson = True
                Exit Function
            End If

            If pCh = Chr(10) Then
                EhBrancoJson = True
                Exit Function
            End If

            If pCh = Chr(13) Then
                EhBrancoJson = True
            End If
        End Function

        Private Shared Function ValorDigito(pCh As String) As Integer
            Dim _digits As String = "0123456789"
            Dim _i As Integer = 0

            ValorDigito = -1

            For _i = 1 To 10
                If Mid(_digits, _i, 1) = pCh Then
                    ValorDigito = _i - 1
                    Exit Function
                End If
            Next
        End Function

        ' Busca so com Mid curto (nunca InStr no blob: OleStr 00220000).
        ' Nao copia o haystack com Mid(hay, from) de cauda longa.
        Private Shared Function PosicaoTexto(pHaystack As String, pNeedle As String, pFromPos As Integer) As Integer
            Dim _from As Integer = pFromPos
            Dim _hayLen As Integer = Len(pHaystack)
            Dim _needleLen As Integer = Len(pNeedle)
            Dim _pos As Integer = 0

            PosicaoTexto = 0

            If _needleLen <= 0 Then
                Exit Function
            End If

            If _from < 1 Then
                _from = 1
            End If

            If _from > _hayLen Then
                Exit Function
            End If

            For _pos = _from To _hayLen - _needleLen + 1
                If Mid(pHaystack, _pos, _needleLen) = pNeedle Then
                    PosicaoTexto = _pos
                    Exit Function
                End If
            Next
        End Function

        Private Shared Function PularBrancos(pBlob As String, pStart As Integer) As Integer
            Dim _start As Integer = pStart
            Dim _blobLen As Integer = Len(pBlob)
            Dim _ch As String = ""

            PularBrancos = _start

            If _start < 1 Then
                Exit Function
            End If

            While _start <= _blobLen
                _ch = Mid(pBlob, _start, 1)
                If Not EhBrancoJson(_ch) Then
                    Exit While
                End If
                _start = _start + 1
            Wend

            PularBrancos = _start
        End Function

        ' Mesmo que LocalizarInicioValor, mas comeca a busca em pFromPos (1-based).
        Private Shared Function LocalizarInicioValorApartir(pBlob As String, pKey As String, pFromPos As Integer) As Integer
            Dim _marker As String = MontarMarcadorJson(pKey)
            Dim _pos As Integer = 0
            Dim _start As Integer = 0

            LocalizarInicioValorApartir = 0

            _pos = PosicaoTexto(pBlob, _marker, pFromPos)
            If _pos <= 0 Then
                Exit Function
            End If

            _start = PularBrancos(pBlob, _pos + Len(_marker))
            If _start > Len(pBlob) Then
                Exit Function
            End If

            LocalizarInicioValorApartir = _start
        End Function

        ' Posicao do '{' ou '[' apos a chave; pula escalares (user.company e numero).
        ' Nao copia o bloco (Mid de janela grande em unicode = AV 00220000).
        Private Shared Function PosicaoInicioBlocoJsonDeBlob(pBlob As String, pKey As String, pAbre As String) As Integer
            Dim _start As Integer = 0
            Dim _searchFrom As Integer = 1
            Dim _ch As String = ""
            Dim _blobLen As Integer = Len(pBlob)

            PosicaoInicioBlocoJsonDeBlob = 0

            While _searchFrom > 0
                If _searchFrom > _blobLen Then
                    Exit Function
                End If

                _start = LocalizarInicioValorApartir(pBlob, pKey, _searchFrom)

                If _start <= 0 Then
                    Exit Function
                End If

                _ch = Mid(pBlob, _start, 1)

                If pAbre = "" Then
                    If _ch = "{" Then
                        PosicaoInicioBlocoJsonDeBlob = _start
                        Exit Function
                    End If

                    If _ch = "[" Then
                        PosicaoInicioBlocoJsonDeBlob = _start
                        Exit Function
                    End If
                Else
                    If _ch = pAbre Then
                        PosicaoInicioBlocoJsonDeBlob = _start
                        Exit Function
                    End If
                End If

                _searchFrom = _start + 1
            Wend
        End Function

        Shared Function PosicaoInicioObjetoJsonDeBlob(pBlob As String, pKey As String) As Integer
            PosicaoInicioObjetoJsonDeBlob = PosicaoInicioBlocoJsonDeBlob(pBlob, pKey, "{")
        End Function

        Shared Function PosicaoInicioArrayJsonDeBlob(pBlob As String, pKey As String) As Integer
            PosicaoInicioArrayJsonDeBlob = PosicaoInicioBlocoJsonDeBlob(pBlob, pKey, "[")
        End Function

        ' Posicao do '}' ou ']' que fecha o bloco em pStart. Mid de 1 char; sem copiar o bloco.
        Shared Function PosicaoFimBlocoJsonDeBlob(pBlob As String, pStart As Integer) As Integer
            Dim _quote As String = AspasJson()
            Dim _blobLen As Integer = Len(pBlob)
            Dim _ch As String = ""
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escapeNext As Boolean = False
            Dim _i As Integer = 0

            PosicaoFimBlocoJsonDeBlob = 0

            If pStart < 1 Then
                Exit Function
            End If

            If pStart > _blobLen Then
                Exit Function
            End If

            _ch = Mid(pBlob, pStart, 1)
            If _ch <> "{" Then
                If _ch <> "[" Then
                    Exit Function
                End If
            End If

            For _i = pStart To _blobLen
                _ch = Mid(pBlob, _i, 1)

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
                    ElseIf _ch = "{" Then
                        _depth = _depth + 1
                    ElseIf _ch = "[" Then
                        _depth = _depth + 1
                    ElseIf _ch = "}" Then
                        _depth = _depth - 1
                        If _depth = 0 Then
                            PosicaoFimBlocoJsonDeBlob = _i
                            Exit Function
                        End If
                    ElseIf _ch = "]" Then
                        _depth = _depth - 1
                        If _depth = 0 Then
                            PosicaoFimBlocoJsonDeBlob = _i
                            Exit Function
                        End If
                    End If
                End If
            Next
        End Function

        ' Posicao (1-based) do inicio do elemento pIndex (0-based) no array em pArrayStart.
        Shared Function PosicaoElementoArrayJsonDeBlob(pBlob As String, pArrayStart As Integer, pIndex As Integer) As Integer
            Dim _blobLen As Integer = Len(pBlob)
            Dim _quote As String = AspasJson()
            Dim _pos As Integer = 0
            Dim _elemStart As Integer = 0
            Dim _elemIndex As Integer = 0
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escapeNext As Boolean = False
            Dim _ch As String = ""

            PosicaoElementoArrayJsonDeBlob = 0

            If pIndex < 0 Then
                Exit Function
            End If

            If pArrayStart < 1 Then
                Exit Function
            End If

            If pArrayStart > _blobLen Then
                Exit Function
            End If

            If Mid(pBlob, pArrayStart, 1) <> "[" Then
                Exit Function
            End If

            _pos = pArrayStart + 1

            While _pos <= _blobLen
                _ch = Mid(pBlob, _pos, 1)

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
                        If _depth = 0 Then
                            If _elemStart = 0 Then
                                _elemStart = _pos
                            End If
                        End If
                    ElseIf _ch = "[" Then
                        If _depth = 0 Then
                            If _elemStart = 0 Then
                                _elemStart = _pos
                            End If
                        End If
                        _depth = _depth + 1
                    ElseIf _ch = "{" Then
                        If _depth = 0 Then
                            If _elemStart = 0 Then
                                _elemStart = _pos
                            End If
                        End If
                        _depth = _depth + 1
                    ElseIf _ch = "]" Then
                        If _depth = 0 Then
                            If _elemStart > 0 Then
                                If _elemIndex = pIndex Then
                                    PosicaoElementoArrayJsonDeBlob = _elemStart
                                    Exit Function
                                End If
                            End If
                            Exit Function
                        End If

                        If _depth = 1 Then
                            If _elemStart > 0 Then
                                If _elemIndex = pIndex Then
                                    PosicaoElementoArrayJsonDeBlob = _elemStart
                                    Exit Function
                                End If
                                _elemIndex = _elemIndex + 1
                                _elemStart = 0
                            End If
                        End If

                        _depth = _depth - 1
                    ElseIf _ch = "}" Then
                        If _depth = 1 Then
                            If _elemStart > 0 Then
                                If _elemIndex = pIndex Then
                                    PosicaoElementoArrayJsonDeBlob = _elemStart
                                    Exit Function
                                End If
                                _elemIndex = _elemIndex + 1
                                _elemStart = 0
                            End If
                        End If

                        _depth = _depth - 1
                    ElseIf _ch = "," Then
                        If _depth = 0 Then
                            If _elemStart > 0 Then
                                If _elemIndex = pIndex Then
                                    PosicaoElementoArrayJsonDeBlob = _elemStart
                                    Exit Function
                                End If
                                _elemIndex = _elemIndex + 1
                                _elemStart = 0
                            End If
                        End If
                    Else
                        If Not EhBrancoJson(_ch) Then
                            If _depth = 0 Then
                                If _elemStart = 0 Then
                                    _elemStart = _pos
                                End If
                            End If
                        End If
                    End If
                End If

                _pos = _pos + 1
            Wend
        End Function

        ' Posicao do '{' do objeto pIndex (0-based) dentro do array em pArrayStart.
        Shared Function PosicaoObjetoEmArrayJsonDeBlob(pBlob As String, pArrayStart As Integer, pIndex As Integer) As Integer
            Dim _elemStart As Integer = 0
            Dim _ch As String = ""

            PosicaoObjetoEmArrayJsonDeBlob = 0
            _elemStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(pBlob, pArrayStart, pIndex)

            If _elemStart <= 0 Then
                Exit Function
            End If

            _ch = Mid(pBlob, _elemStart, 1)
            If _ch <> "{" Then
                Exit Function
            End If

            PosicaoObjetoEmArrayJsonDeBlob = _elemStart
        End Function

        ' Extrai o bloco bruto (objeto {..} ou array [..]) de uma chave, sem usar getters
        ' tipados do TJSONObject (evita EVariantTypeCastError com tipos mistos da API).
        Shared Function ObterBlocoJson(pJson As TJSONObject, pKey As String) As String
            ObterBlocoJson = RedeAncoraJsonHelper.ObterBlocoJsonDeBlob(pJson.ToString(), pKey)
        End Function

        ' Extrai objeto/array de uma chave a partir do blob cru (sem TJSONObject.ToString
        ' de documento ja parseado — ToString em JSON misto da API pode AV 00220000).
        Shared Function ObterBlocoJsonDeBlob(pBlob As String, pKey As String) As String
            Dim _start As Integer = 0
            Dim _fim As Integer = 0

            ObterBlocoJsonDeBlob = ""
            _start = PosicaoInicioBlocoJsonDeBlob(pBlob, pKey, "")

            If _start <= 0 Then
                Exit Function
            End If

            _fim = RedeAncoraJsonHelper.PosicaoFimBlocoJsonDeBlob(pBlob, _start)

            If _fim <= 0 Then
                Exit Function
            End If

            ObterBlocoJsonDeBlob = Mid(pBlob, _start, _fim - _start + 1)
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
        ' Nao usa TJSONArray.GetJSONObject (getter tipado = AV 00220000 em tipo misto).
        Shared Function ObterFilhoJsonDeBlob(pBlob As String, pKey As String) As String
            Dim _raw As String = RedeAncoraJsonHelper.ObterBlocoJsonDeBlob(pBlob, pKey)
            Dim _elem As String = ""

            ObterFilhoJsonDeBlob = ""

            If Mid(_raw.Trim(), 1, 1) = "{" Then
                ObterFilhoJsonDeBlob = _raw
                Exit Function
            End If

            If Mid(_raw.Trim(), 1, 1) <> "[" Then
                Exit Function
            End If

            _elem = RedeAncoraJsonHelper.ExtrairElementoArrayJson(_raw, 0)
            If Mid(_elem.Trim(), 1, 1) = "{" Then
                ObterFilhoJsonDeBlob = _elem
            End If
        End Function

        Shared Function ObterFilhoJson(pJson As TJSONObject, pKey As String) As TJSONObject
            Dim _blob As String = ""

            ObterFilhoJson = NULL
            _blob = RedeAncoraJsonHelper.ObterFilhoJsonDeBlob(pJson.ToString(), pKey)

            If Mid(_blob.Trim(), 1, 1) <> "{" Then
                Exit Function
            End If

            ObterFilhoJson = New TJSONObject(_blob)
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

        ' Extrai string JSON no blob, da aspa de abertura, sem copiar o restante do documento.
        Private Shared Function ExtrairStringJsonEm(pBlob As String, pQuotePos As Integer) As String
            Dim _quote As String = AspasJson()
            Dim _i As Integer = 0
            Dim _ch As String = ""
            Dim _escape As Boolean = False
            Dim _result As String = ""
            Dim _blobLen As Integer = Len(pBlob)

            ExtrairStringJsonEm = ""

            If pQuotePos < 1 Then
                Exit Function
            End If

            If pQuotePos > _blobLen Then
                Exit Function
            End If

            If Mid(pBlob, pQuotePos, 1) <> _quote Then
                Exit Function
            End If

            For _i = pQuotePos + 1 To _blobLen
                _ch = Mid(pBlob, _i, 1)

                If _escape Then
                    _result = _result & _ch
                    _escape = False
                ElseIf _ch = "\" Then
                    _escape = True
                    _result = _result & _ch
                ElseIf _ch = _quote Then
                    ExtrairStringJsonEm = _result
                    Exit Function
                Else
                    _result = _result & _ch
                End If
            Next
        End Function

        Private Shared Function TextoAposInicioValor(pBlob As String, pStart As Integer) As String
            Dim _quote As String = AspasJson()
            Dim _blobLen As Integer = Len(pBlob)
            Dim _ch As String = ""
            Dim _i As Integer = 0
            Dim _result As String = ""

            TextoAposInicioValor = ""

            If pStart <= 0 Then
                Exit Function
            End If

            If pStart > _blobLen Then
                Exit Function
            End If

            _ch = Mid(pBlob, pStart, 1)

            If _ch = _quote Then
                TextoAposInicioValor = ExtrairStringJsonEm(pBlob, pStart)
                Exit Function
            End If

            If _ch = "{" Or _ch = "[" Then
                Exit Function
            End If

            If pStart + 3 <= _blobLen Then
                If Mid(pBlob, pStart, 4) = "null" Then
                    Exit Function
                End If
            End If

            For _i = pStart To _blobLen
                _ch = Mid(pBlob, _i, 1)

                If _ch = "," Or _ch = "}" Or _ch = "]" Then
                    Exit For
                End If

                If EhBrancoJson(_ch) Then
                    Exit For
                End If

                _result = _result & _ch
            Next

            TextoAposInicioValor = _result
        End Function

        ' Le um valor escalar (numero, string ou boolean) de uma chave, sem usar
        ' getters tipados do TJSONObject (evita EVariantTypeCastError).
        Shared Function ObterTextoJsonDeBlob(pBlob As String, pKey As String) As String
            ObterTextoJsonDeBlob = RedeAncoraJsonHelper.ObterTextoJsonDeBlobApos(pBlob, pKey, 1)
        End Function

        Shared Function ObterTextoJsonDeBlobApos(pBlob As String, pKey As String, pFromPos As Integer) As String
            Dim _start As Integer = LocalizarInicioValorApartir(pBlob, pKey, pFromPos)

            ObterTextoJsonDeBlobApos = ""

            If _start <= 0 Then
                Exit Function
            End If

            ObterTextoJsonDeBlobApos = TextoAposInicioValor(pBlob, _start)
        End Function

        ' Le escalar no blob original entre pFromPos e pToPos (sem copiar janela unicode).
        Shared Function ObterTextoJsonDeBlobEntre(pBlob As String, pKey As String, pFromPos As Integer, pToPos As Integer) As String
            Dim _start As Integer = LocalizarInicioValorApartir(pBlob, pKey, pFromPos)

            ObterTextoJsonDeBlobEntre = ""

            If _start <= 0 Then
                Exit Function
            End If

            If pToPos > 0 Then
                If _start > pToPos Then
                    Exit Function
                End If
            End If

            ObterTextoJsonDeBlobEntre = TextoAposInicioValor(pBlob, _start)
        End Function

        Shared Function ObterTextoJsonEmPosicaoDeBlob(pBlob As String, pStart As Integer) As String
            ObterTextoJsonEmPosicaoDeBlob = TextoAposInicioValor(pBlob, pStart)
        End Function

        Shared Function ObterTextoJson(pJson As TJSONObject, pKey As String) As String
            ObterTextoJson = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pJson.ToString(), pKey)
        End Function

        Shared Function ObterDecimalJsonDeBlob(pBlob As String, pKey As String) As Double
            ObterDecimalJsonDeBlob = Parser.StringToDouble(RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pBlob, pKey))
        End Function

        Shared Function ObterDecimalJsonDeBlobEntre(pBlob As String, pKey As String, pFromPos As Integer, pToPos As Integer) As Double
            ObterDecimalJsonDeBlobEntre = Parser.StringToDouble(RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBlob, pKey, pFromPos, pToPos))
        End Function

        Shared Function ObterDecimalJson(pJson As TJSONObject, pKey As String) As Double
            ObterDecimalJson = Parser.StringToDouble(RedeAncoraJsonHelper.ObterTextoJson(pJson, pKey))
        End Function

        Private Shared Function TextoEhBooleanTrue(pRaw As String) As Boolean
            Dim _raw As String = pRaw.Trim().ToLower()

            TextoEhBooleanTrue = False

            If _raw = "true" Then
                TextoEhBooleanTrue = True
                Exit Function
            End If

            If _raw = "1" Then
                TextoEhBooleanTrue = True
                Exit Function
            End If

            If _raw = "s" Then
                TextoEhBooleanTrue = True
                Exit Function
            End If

            If _raw = "sim" Then
                TextoEhBooleanTrue = True
            End If
        End Function

        Shared Function ObterBooleanJsonDeBlob(pBlob As String, pKey As String) As Boolean
            ObterBooleanJsonDeBlob = TextoEhBooleanTrue(RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pBlob, pKey))
        End Function

        Shared Function ObterBooleanJson(pJson As TJSONObject, pKey As String) As Boolean
            ObterBooleanJson = TextoEhBooleanTrue(RedeAncoraJsonHelper.ObterTextoJson(pJson, pKey))
        End Function

        ' Junta strings de um array JSON no blob original (sem TJSONArray / TJSONObject).
        Shared Function ConcatenarTextosArrayJsonDeBlob(pBlob As String, pKey As String, pSeparador As String) As String
            Dim _arrStart As Integer = 0
            Dim _elemStart As Integer = 0
            Dim _texto As String = ""
            Dim _result As String = ""
            Dim _i As Integer = 0

            ConcatenarTextosArrayJsonDeBlob = ""
            _arrStart = RedeAncoraJsonHelper.PosicaoInicioArrayJsonDeBlob(pBlob, pKey)

            If _arrStart <= 0 Then
                Exit Function
            End If

            For _i = 0 To 9999
                _elemStart = RedeAncoraJsonHelper.PosicaoElementoArrayJsonDeBlob(pBlob, _arrStart, _i)

                If _elemStart <= 0 Then
                    Exit For
                End If

                _texto = RedeAncoraJsonHelper.ObterTextoJsonEmPosicaoDeBlob(pBlob, _elemStart)

                If _texto <> "" Then
                    If _result <> "" Then
                        _result = _result & pSeparador
                    End If

                    _result = _result & _texto
                End If
            Next

            ConcatenarTextosArrayJsonDeBlob = _result
        End Function

        Shared Function SimNao(pValor As Boolean) As String
            If pValor Then
                SimNao = "S"
            Else
                SimNao = "N"
            End If
        End Function

        Private Shared Function TextoParaInteiro(pRaw As String) As Integer
            Dim _text As String = pRaw
            Dim _len As Integer = 0
            Dim _i As Integer = 1
            Dim _sign As Integer = 1
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _ch As String = ""

            TextoParaInteiro = 0

            _len = Len(_text)
            If _len <= 0 Then
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
                _d = ValorDigito(_ch)
                If _d < 0 Then
                    Exit While
                End If
                _n = (_n * 10) + _d
                _i = _i + 1
            Wend

            TextoParaInteiro = _sign * _n
        End Function

        Shared Function ObterInteiroJsonDeBlob(pBlob As String, pKey As String) As Integer
            ObterInteiroJsonDeBlob = TextoParaInteiro(RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pBlob, pKey))
        End Function

        Shared Function ObterInteiroJsonDeBlobApos(pBlob As String, pKey As String, pFromPos As Integer) As Integer
            ObterInteiroJsonDeBlobApos = TextoParaInteiro(RedeAncoraJsonHelper.ObterTextoJsonDeBlobApos(pBlob, pKey, pFromPos))
        End Function

        Shared Function ObterInteiroJsonDeBlobEntre(pBlob As String, pKey As String, pFromPos As Integer, pToPos As Integer) As Integer
            ObterInteiroJsonDeBlobEntre = TextoParaInteiro(RedeAncoraJsonHelper.ObterTextoJsonDeBlobEntre(pBlob, pKey, pFromPos, pToPos))
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
