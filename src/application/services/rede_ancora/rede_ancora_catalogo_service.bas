Imports mod_tobject
Imports mod_logger
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_marca_model
Imports rede_ancora_marcas_model
Imports rede_ancora_linha_model
Imports rede_ancora_linhas_model
Imports rede_ancora_familia_model
Imports rede_ancora_familias_model
Imports rede_ancora_catalogo_repository
Imports http_response
Imports rede_ancora_http_erro_helper

Namespace rede_ancora_catalogo_service
    Class RedeAncoraCatalogoService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _repository As RedeAncoraCatalogoRepository

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._repository = New RedeAncoraCatalogoRepository()
        End Sub

        Function SincronizarMarcas(pCodUsuario As Integer) As RedeAncoraMarcasModel
            Dim _marcas As RedeAncoraMarcasModel = NULL
            Dim _result As RedeAncoraMarcasModel = NULL
            Dim _body As String = ""

            Try
                _body = me.BaixarBlobCatalogo(pCodUsuario, "/products/brands", "sync-marcas")
                mod_logger.Info("sync-marcas: before MapearMarcasDeBlob")
                _marcas = me.MapearMarcasDeBlob(_body)
                mod_logger.Info("sync-marcas: after MapearMarcasDeBlob qtd=" & Parser.IntegerToString(_marcas.Length))
                mod_logger.Printe("Rede Ancora sync marcas :: mapeamento JSON OK")

                me._repository.SubstituirMarcas(_marcas)
                mod_logger.Info("sync-marcas: gravadas")
                mod_logger.Printe("Rede Ancora sync marcas concluido. Registros: " & Parser.IntegerToString(_marcas.Length))

                _result = _marcas
                _marcas = NULL
            Catch ex As Exception
                If Assigned(_marcas) Then
                    _marcas.Free()
                End If

                If Assigned(_result) Then
                    _result.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar marcas Rede Ancora: " & ex._getMessage())
            End Try

            SincronizarMarcas = _result
        End Function

        Function SincronizarLinhas(pCodUsuario As Integer) As RedeAncoraLinhasModel
            Dim _linhas As RedeAncoraLinhasModel = NULL
            Dim _result As RedeAncoraLinhasModel = NULL
            Dim _body As String = ""

            Try
                _body = me.BaixarBlobCatalogo(pCodUsuario, "/products/lines", "sync-linhas")
                mod_logger.Info("sync-linhas: before MapearLinhasDeBlob")
                _linhas = me.MapearLinhasDeBlob(_body)
                mod_logger.Info("sync-linhas: after MapearLinhasDeBlob qtd=" & Parser.IntegerToString(_linhas.Length))
                mod_logger.Printe("Rede Ancora sync linhas :: mapeamento JSON OK")

                me._repository.SubstituirLinhas(_linhas)
                mod_logger.Info("sync-linhas: gravadas")
                mod_logger.Printe("Rede Ancora sync linhas concluido. Registros: " & Parser.IntegerToString(_linhas.Length))

                _result = _linhas
                _linhas = NULL
            Catch ex As Exception
                If Assigned(_linhas) Then
                    _linhas.Free()
                End If

                If Assigned(_result) Then
                    _result.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar linhas Rede Ancora: " & ex._getMessage())
            End Try

            SincronizarLinhas = _result
        End Function

        Function SincronizarFamilias(pCodUsuario As Integer) As RedeAncoraFamiliasModel
            Dim _familias As RedeAncoraFamiliasModel = NULL
            Dim _result As RedeAncoraFamiliasModel = NULL
            Dim _body As String = ""

            Try
                _body = me.BaixarBlobCatalogo(pCodUsuario, "/products/families", "sync-familias")
                mod_logger.Info("sync-familias: before MapearFamiliasDeBlob")
                _familias = me.MapearFamiliasDeBlob(_body)
                mod_logger.Info("sync-familias: after MapearFamiliasDeBlob qtd=" & Parser.IntegerToString(_familias.Length))
                mod_logger.Printe("Rede Ancora sync familias :: mapeamento JSON OK")

                me._repository.SubstituirFamilias(_familias)
                mod_logger.Info("sync-familias: gravadas")
                mod_logger.Printe("Rede Ancora sync familias concluido. Registros: " & Parser.IntegerToString(_familias.Length))

                _result = _familias
                _familias = NULL
            Catch ex As Exception
                If Assigned(_familias) Then
                    _familias.Free()
                End If

                If Assigned(_result) Then
                    _result.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar familias Rede Ancora: " & ex._getMessage())
            End Try

            SincronizarFamilias = _result
        End Function

        Sub SincronizarCatalogo(pCodUsuario As Integer)
            Dim _marcas As RedeAncoraMarcasModel = NULL
            Dim _linhas As RedeAncoraLinhasModel = NULL
            Dim _familias As RedeAncoraFamiliasModel = NULL

            Try
                mod_logger.Printe("Rede Ancora sync catalogo :: marcas...")
                _marcas = me.SincronizarMarcas(pCodUsuario)
                mod_logger.Printe("Rede Ancora sync catalogo :: linhas...")
                _linhas = me.SincronizarLinhas(pCodUsuario)
                mod_logger.Printe("Rede Ancora sync catalogo :: familias...")
                _familias = me.SincronizarFamilias(pCodUsuario)
                mod_logger.Printe("Rede Ancora sync catalogo concluido.")
                _marcas.Free()
                _marcas = NULL
                _linhas.Free()
                _linhas = NULL
                _familias.Free()
                _familias = NULL
            Catch ex As Exception
                If Assigned(_marcas) Then
                    _marcas.Free()
                End If

                If Assigned(_linhas) Then
                    _linhas.Free()
                End If

                If Assigned(_familias) Then
                    _familias.Free()
                End If

                Throw ex
            End Try
        End Sub

        Function ListarMarcas() As RedeAncoraMarcasModel
            ListarMarcas = me._repository.ListarMarcas()
        End Function

        Function ListarLinhas() As RedeAncoraLinhasModel
            ListarLinhas = me._repository.ListarLinhas()
        End Function

        Function ListarFamilias() As RedeAncoraFamiliasModel
            ListarFamilias = me._repository.ListarFamilias()
        End Function

        Sub GarantirCatalogoSincronizado(pCodUsuario As Integer)
            Dim _marcas As RedeAncoraMarcasModel = me.ListarMarcas()

            If _marcas.Length <= 0 Then
                _marcas.Free()
                mod_logger.Printe("Rede Ancora catalogo local vazio; iniciando sincronizacao completa...")
                me.SincronizarCatalogo(pCodUsuario)
                Exit Sub
            End If

            mod_logger.Printe("Rede Ancora catalogo ja sincronizado. Marcas em cache: " & Parser.IntegerToString(_marcas.Length))
            _marcas.Free()
        End Sub

        ' BodyAsJsonObject / TJSONArray.GetJSONObject = AV 00220000 (brands ~370KB / 1634 itens).
        ' Nao caminhar o blob com Mid(pBody, i, 1) nem PosicaoTexto/Obter*JsonDeBlob no body.
        Private Function BaixarBlobCatalogo(pCodUsuario As Integer, pRota As String, pBreadcrumb As String) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _body As String = ""
            Dim _status As Integer = 0
            Dim _bytes As Integer = 0
            Dim _snippet As String = ""
            Dim _ok As Boolean = False
            Dim _result As String = ""

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl(pRota))

                If Assigned(_response) Then
                    _status = _response.StatusCode
                    _body = _response.Body
                    _bytes = Len(_body)
                    If _bytes <= 80 Then
                        _snippet = _body
                    Else
                        _snippet = Mid(_body, 1, 80) & "..."
                    End If
                End If

                mod_logger.Info("GET " & pRota & " HTTP " & Parser.IntegerToString(_status) & " bytes=" & Parser.IntegerToString(_bytes) & " body=" & _snippet)
                mod_logger.Info(pBreadcrumb & ": after HTTP log")

                If Not Assigned(_response) Then
                    Throw New System.Exception("GET " & pRota & " resposta nula")
                End If
                mod_logger.Info(pBreadcrumb & ": response assigned")

                _ok = _response.IsSuccess
                mod_logger.Info(pBreadcrumb & ": after IsSuccess")

                If Not _ok Then
                    Throw New System.Exception(RedeAncoraHttpErroHelper.MontarMensagem("GET " & pRota, _status, _body))
                End If
                mod_logger.Info(pBreadcrumb & ": response success")
                RedeAncoraHttpErroHelper.ExigirCorpoJson("GET " & pRota, _status, _body)

                _response.Free()
                _response = NULL
                _api.Free()
                _api = NULL
                _result = _body
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraCatalogoService." & pBreadcrumb, ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw ex
            End Try

            BaixarBlobCatalogo = _result
        End Function

        Private Function MapearMarcasDeBlob(pBody As String) As RedeAncoraMarcasModel
            Dim _result As New RedeAncoraMarcasModel()

            mod_logger.Info("sync-marcas: MapearMarcasDeBlob start")
            me.VarrerPrefixosArrayData(pBody, "/products/brands", "sync-marcas", _result, NULL, NULL)

            If _result.Length <= 0 Then
                _result.Free()
                Throw New System.Exception("Resposta /products/brands sem marcas (id/name)")
            End If

            MapearMarcasDeBlob = _result
        End Function

        Private Function MapearLinhasDeBlob(pBody As String) As RedeAncoraLinhasModel
            Dim _result As New RedeAncoraLinhasModel()

            mod_logger.Info("sync-linhas: MapearLinhasDeBlob start")
            me.VarrerPrefixosArrayData(pBody, "/products/lines", "sync-linhas", NULL, _result, NULL)

            If _result.Length <= 0 Then
                _result.Free()
                Throw New System.Exception("Resposta /products/lines sem linhas (id/name)")
            End If

            MapearLinhasDeBlob = _result
        End Function

        Private Function MapearFamiliasDeBlob(pBody As String) As RedeAncoraFamiliasModel
            Dim _result As New RedeAncoraFamiliasModel()

            mod_logger.Info("sync-familias: MapearFamiliasDeBlob start")
            me.VarrerPrefixosArrayData(pBody, "/products/families", "sync-familias", NULL, NULL, _result)

            If _result.Length <= 0 Then
                _result.Free()
                Throw New System.Exception("Resposta /products/families sem familias (value/label)")
            End If

            MapearFamiliasDeBlob = _result
        End Function

        ' Apos array pos=9 o While Mid(pBody, _pos, 1) no OleStr 370KB AV 00220000.
        ' Janela Mid(pBody, _pos, 200); parse ASCII no slice; avanca pelo `}` da janela
        ' ou pula ate `},{` com janelas de 200 (nunca Mid do blob inteiro).
        Private Sub VarrerPrefixosArrayData(pBody As String, pRota As String, pBreadcrumb As String, pMarcas As RedeAncoraMarcasModel, pLinhas As RedeAncoraLinhasModel, pFamilias As RedeAncoraFamiliasModel)
            Dim _arrayStart As Integer = 0
            Dim _bodyLen As Integer = 0
            Dim _pos As Integer = 0
            Dim _janelaMax As Integer = 200
            Dim _janelaLen As Integer = 0
            Dim _janela As String = ""
            Dim _idxAbre As Integer = 0
            Dim _idxFecha As Integer = 0
            Dim _prefix As String = ""
            Dim _prefixLen As Integer = 0
            Dim _qtd As Integer = 0
            Dim _qtdAntes As Integer = 0
            Dim _proxLog As Integer = 400
            Dim _prox As Integer = 0

            _arrayStart = me.PosicaoArrayDataAscii(pBody)
            If _arrayStart <= 0 Then
                Throw New System.Exception("Resposta " & pRota & " sem array data")
            End If
            mod_logger.Info(pBreadcrumb & ": array pos=" & Parser.IntegerToString(_arrayStart))

            _bodyLen = Len(pBody)
            _pos = _arrayStart + 1

            While _pos <= _bodyLen
                _janelaLen = _janelaMax
                If _janelaLen > (_bodyLen - _pos + 1) Then
                    _janelaLen = _bodyLen - _pos + 1
                End If
                If _janelaLen <= 0 Then
                    Exit While
                End If

                _janela = Mid(pBody, _pos, _janelaLen)
                _idxAbre = me.PosicaoAbreObjetoNaJanela(_janela)

                If _idxAbre < 0 Then
                    Exit While
                End If

                If _idxAbre = 0 Then
                    _pos = _pos + _janelaLen
                Else
                    _idxFecha = me.PosicaoFechaObjetoNaJanela(_janela, _idxAbre)
                    If _idxFecha > 0 Then
                        _prefixLen = _idxFecha - _idxAbre + 1
                        _prefix = Mid(_janela, _idxAbre, _prefixLen)
                    Else
                        _prefixLen = _janelaLen - _idxAbre + 1
                        _prefix = Mid(_janela, _idxAbre, _prefixLen)
                    End If

                    _qtdAntes = me.QtdItensCatalogo(pMarcas, pLinhas, pFamilias)
                    me.AdicionarItemCatalogoDoPrefixo(_prefix, pMarcas, pLinhas, pFamilias)
                    _qtd = me.QtdItensCatalogo(pMarcas, pLinhas, pFamilias)

                    If _qtd > _qtdAntes Then
                        If _qtdAntes = 0 Then
                            mod_logger.Info(pBreadcrumb & ": primeiro item ok")
                        Else
                            If _qtd >= _proxLog Then
                                mod_logger.Info(pBreadcrumb & ": itens=" & Parser.IntegerToString(_qtd))
                                _proxLog = _proxLog + 400
                            End If
                        End If
                    End If

                    If _idxFecha > 0 Then
                        _pos = _pos + _idxFecha
                    Else
                        _prox = me.PularAteProximoObjeto(pBody, _pos + _idxAbre)
                        If _prox <= 0 Then
                            Exit While
                        End If
                        _pos = _prox
                    End If
                End If
            Wend

            mod_logger.Info(pBreadcrumb & ": itens=" & Parser.IntegerToString(_qtd))
        End Sub

        Private Function QtdItensCatalogo(pMarcas As RedeAncoraMarcasModel, pLinhas As RedeAncoraLinhasModel, pFamilias As RedeAncoraFamiliasModel) As Integer
            QtdItensCatalogo = 0

            If Assigned(pMarcas) Then
                QtdItensCatalogo = pMarcas.Length
                Exit Function
            End If

            If Assigned(pLinhas) Then
                QtdItensCatalogo = pLinhas.Length
                Exit Function
            End If

            If Assigned(pFamilias) Then
                QtdItensCatalogo = pFamilias.Length
            End If
        End Function

        ' -1 = fim do array (]), 0 = sem `{`, >0 = posicao do `{` na janela.
        Private Function PosicaoAbreObjetoNaJanela(pJanela As String) As Integer
            Dim _len As Integer = Len(pJanela)
            Dim _i As Integer = 1
            Dim _ch As String = ""

            PosicaoAbreObjetoNaJanela = 0

            While _i <= _len
                _ch = Mid(pJanela, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    If _ch = "," Then
                        _i = _i + 1
                    Else
                        Exit While
                    End If
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            _ch = Mid(pJanela, _i, 1)
            If _ch = "]" Then
                PosicaoAbreObjetoNaJanela = -1
                Exit Function
            End If

            If _ch = "{" Then
                PosicaoAbreObjetoNaJanela = _i
            End If
        End Function

        Private Function PosicaoFechaObjetoNaJanela(pJanela As String, pAbre As Integer) As Integer
            Dim _len As Integer = Len(pJanela)
            Dim _i As Integer = pAbre
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _depth As Integer = 0
            Dim _inQuotes As Boolean = False
            Dim _escape As Boolean = False

            PosicaoFechaObjetoNaJanela = 0

            If pAbre < 1 Then
                Exit Function
            End If

            If pAbre > _len Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pJanela, _i, 1)

                If _escape Then
                    _escape = False
                Else
                    If _inQuotes Then
                        If _ch = "\" Then
                            _escape = True
                        Else
                            If _ch = _q Then
                                _inQuotes = False
                            End If
                        End If
                    Else
                        If _ch = _q Then
                            _inQuotes = True
                        Else
                            If _ch = "{" Then
                                _depth = _depth + 1
                            Else
                                If _ch = "}" Then
                                    _depth = _depth - 1
                                    If _depth = 0 Then
                                        PosicaoFechaObjetoNaJanela = _i
                                        Exit Function
                                    End If
                                End If
                            End If
                        End If
                    End If
                End If

                _i = _i + 1
            Wend
        End Function

        ' Encontra `},{` (proximo item) ou `}]` (fim) em janelas de 200; overlap 2.
        Private Function PularAteProximoObjeto(pBody As String, pFrom As Integer) As Integer
            Dim _bodyLen As Integer = 0
            Dim _i As Integer = pFrom
            Dim _janelaMax As Integer = 200
            Dim _janelaLen As Integer = 0
            Dim _janela As String = ""
            Dim _j As Integer = 0

            PularAteProximoObjeto = 0

            If pFrom < 1 Then
                Exit Function
            End If

            _bodyLen = Len(pBody)

            While _i <= _bodyLen
                _janelaLen = _janelaMax
                If _janelaLen > (_bodyLen - _i + 1) Then
                    _janelaLen = _bodyLen - _i + 1
                End If
                If _janelaLen < 2 Then
                    Exit Function
                End If

                _janela = Mid(pBody, _i, _janelaLen)

                _j = 1
                While _j <= (_janelaLen - 2)
                    If Mid(_janela, _j, 3) = "},{" Then
                        PularAteProximoObjeto = _i + _j + 1
                        Exit Function
                    End If
                    If Mid(_janela, _j, 2) = "}]" Then
                        Exit Function
                    End If
                    _j = _j + 1
                Wend

                If Mid(_janela, _janelaLen - 1, 2) = "}]" Then
                    Exit Function
                End If

                If _janelaLen <= 2 Then
                    Exit Function
                End If
                _i = _i + _janelaLen - 2
            Wend
        End Function

        Private Sub AdicionarItemCatalogoDoPrefixo(pPrefixo As String, pMarcas As RedeAncoraMarcasModel, pLinhas As RedeAncoraLinhasModel, pFamilias As RedeAncoraFamiliasModel)
            If Assigned(pMarcas) Then
                me.AdicionarMarcaDoPrefixo(pMarcas, pPrefixo)
            Else
                If Assigned(pLinhas) Then
                    me.AdicionarLinhaDoPrefixo(pLinhas, pPrefixo)
                Else
                    If Assigned(pFamilias) Then
                        me.AdicionarFamiliaDoPrefixo(pFamilias, pPrefixo)
                    End If
                End If
            End If
        End Sub

        Private Sub AdicionarMarcaDoPrefixo(pLista As RedeAncoraMarcasModel, pPrefixo As String)
            Dim _item As RedeAncoraMarcaModel = NULL
            Dim _cod As Integer = 0
            Dim _nome As String = ""

            _cod = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "id")
            _nome = me.ExtrairTextoJsonDoPrefixoAscii(pPrefixo, "name")

            If _cod <= 0 Then
                Exit Sub
            End If

            If _nome.Trim() = "" Then
                Exit Sub
            End If

            _item = New RedeAncoraMarcaModel()
            _item.CodMarca = _cod
            _item.Nome = _nome
            _item.CodCatalogo = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "catalog_code")
            _item.CodErp = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "erp_code")
            pLista.Push(_item)
        End Sub

        Private Sub AdicionarLinhaDoPrefixo(pLista As RedeAncoraLinhasModel, pPrefixo As String)
            Dim _item As RedeAncoraLinhaModel = NULL
            Dim _cod As Integer = 0
            Dim _nome As String = ""

            _cod = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "id")
            _nome = me.ExtrairTextoJsonDoPrefixoAscii(pPrefixo, "name")

            If _cod <= 0 Then
                Exit Sub
            End If

            If _nome.Trim() = "" Then
                Exit Sub
            End If

            _item = New RedeAncoraLinhaModel()
            _item.CodLinha = _cod
            _item.Nome = _nome
            pLista.Push(_item)
        End Sub

        Private Sub AdicionarFamiliaDoPrefixo(pLista As RedeAncoraFamiliasModel, pPrefixo As String)
            Dim _item As RedeAncoraFamiliaModel = NULL
            Dim _cod As Integer = 0
            Dim _nome As String = ""
            Dim _j As Integer = 0
            Dim _jaExiste As Boolean = False

            _cod = me.ExtrairInteiroDoPrefixoAscii(pPrefixo, "value")
            _nome = me.ExtrairTextoJsonDoPrefixoAscii(pPrefixo, "label")

            If _cod <= 0 Then
                Exit Sub
            End If

            If _nome.Trim() = "" Then
                Exit Sub
            End If

            For _j = 0 To pLista.Length - 1
                If pLista.Take(_j).CodFamilia = _cod Then
                    _jaExiste = True
                    Exit For
                End If
            Next

            If _jaExiste Then
                Exit Sub
            End If

            _item = New RedeAncoraFamiliaModel()
            _item.CodFamilia = _cod
            _item.Nome = _nome
            pLista.Push(_item)
        End Sub

        ' So o prefixo ASCII (~64). Nao varrer o body 370KB.
        Private Function PosicaoArrayDataAscii(pBody As String) As Integer
            Dim _bodyLen As Integer = 0
            Dim _prefixLen As Integer = 64
            Dim _prefix As String = ""

            PosicaoArrayDataAscii = 0
            _bodyLen = Len(pBody)

            If _bodyLen <= 0 Then
                Exit Function
            End If

            If _prefixLen > _bodyLen Then
                _prefixLen = _bodyLen
            End If

            _prefix = Mid(pBody, 1, _prefixLen)
            PosicaoArrayDataAscii = me.PosicaoArrayDataNoPrefixo(_prefix)
        End Function

        Private Function PosicaoArrayDataNoPrefixo(pPrefixo As String) As Integer
            Dim _len As Integer = Len(pPrefixo)
            Dim _i As Integer = 1
            Dim _ch As String = ""
            Dim _posValor As Integer = 0

            PosicaoArrayDataNoPrefixo = 0

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i <= _len Then
                If Mid(pPrefixo, _i, 1) = "[" Then
                    PosicaoArrayDataNoPrefixo = _i
                    Exit Function
                End If
            End If

            _posValor = me.PosicaoValorChaveAscii(pPrefixo, "data")
            If _posValor <= 0 Then
                Exit Function
            End If

            If Mid(pPrefixo, _posValor, 1) = "[" Then
                PosicaoArrayDataNoPrefixo = _posValor
            End If
        End Function

        Private Function PosicaoValorChaveAscii(pPrefixo As String, pChave As String) As Integer
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False

            PosicaoValorChaveAscii = 0

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pPrefixo, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pPrefixo, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pPrefixo, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pPrefixo, _i + _keyLen + 2, 1) = ":" Then
                                _achou = True
                                _i = _i + _keyLen + 3
                                Exit While
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            PosicaoValorChaveAscii = _i
        End Function

        Private Function ExtrairInteiroDoPrefixoAscii(pPrefixo As String, pChave As String) As Integer
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False
            Dim _n As Integer = 0
            Dim _d As Integer = 0
            Dim _digits As String = "0123456789"

            ExtrairInteiroDoPrefixoAscii = 0

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pPrefixo, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pPrefixo, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pPrefixo, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pPrefixo, _i + _keyLen + 2, 1) = ":" Then
                                _achou = True
                                _i = _i + _keyLen + 3
                                Exit While
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            If Mid(pPrefixo, _i, 1) = _q Then
                _i = _i + 1
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                _d = -1
                For _j = 1 To 10
                    If Mid(_digits, _j, 1) = _ch Then
                        _d = _j - 1
                        Exit For
                    End If
                Next
                If _d < 0 Then
                    Exit While
                End If
                _n = (_n * 10) + _d
                _i = _i + 1
            Wend

            ExtrairInteiroDoPrefixoAscii = _n
        End Function

        Private Function ExtrairTextoJsonDoPrefixoAscii(pPrefixo As String, pChave As String) As String
            Dim _len As Integer = Len(pPrefixo)
            Dim _keyLen As Integer = Len(pChave)
            Dim _i As Integer = 1
            Dim _j As Integer = 0
            Dim _ch As String = ""
            Dim _q As String = Chr(34)
            Dim _achou As Boolean = False
            Dim _igual As Boolean = False
            Dim _escape As Boolean = False
            Dim _result As String = ""
            Dim _maxValor As Integer = 80
            Dim _nValor As Integer = 0

            ExtrairTextoJsonDoPrefixoAscii = ""

            If _len <= 0 Then
                Exit Function
            End If

            If _keyLen <= 0 Then
                Exit Function
            End If

            While _i <= (_len - _keyLen - 2)
                If Mid(pPrefixo, _i, 1) = _q Then
                    _igual = True
                    For _j = 1 To _keyLen
                        If Mid(pPrefixo, _i + _j, 1) <> Mid(pChave, _j, 1) Then
                            _igual = False
                            Exit For
                        End If
                    Next
                    If _igual Then
                        If Mid(pPrefixo, _i + _keyLen + 1, 1) = _q Then
                            If Mid(pPrefixo, _i + _keyLen + 2, 1) = ":" Then
                                _achou = True
                                _i = _i + _keyLen + 3
                                Exit While
                            End If
                        End If
                    End If
                End If
                _i = _i + 1
            Wend

            If Not _achou Then
                Exit Function
            End If

            While _i <= _len
                _ch = Mid(pPrefixo, _i, 1)
                If _ch = " " Then
                    _i = _i + 1
                Else
                    Exit While
                End If
            Wend

            If _i > _len Then
                Exit Function
            End If

            If Mid(pPrefixo, _i, 1) <> _q Then
                Exit Function
            End If

            _i = _i + 1

            While _i <= _len
                If _nValor >= _maxValor Then
                    Exit While
                End If

                _ch = Mid(pPrefixo, _i, 1)

                If _escape Then
                    _result = _result & _ch
                    _nValor = _nValor + 1
                    _escape = False
                Else
                    If _ch = "\" Then
                        _result = _result & _ch
                        _nValor = _nValor + 1
                        _escape = True
                    Else
                        If _ch = _q Then
                            Exit While
                        End If
                        _result = _result & _ch
                        _nValor = _nValor + 1
                    End If
                End If

                _i = _i + 1
            Wend

            ExtrairTextoJsonDoPrefixoAscii = _result
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._authService) Then
                    me._authService.Free()
                    me._authService = NULL
                End If

                If Assigned(me._repository) Then
                    me._repository.Free()
                    me._repository = NULL
                End If

                me.Disposed = True
            End If
        End Sub

        Sub Free()
            If Not me.Disposed Then
                me.Dispose()
            End If

            MyBase.Free()
        End Sub
    End Class
End Namespace
