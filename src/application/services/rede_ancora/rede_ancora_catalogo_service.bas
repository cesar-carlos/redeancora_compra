Imports mod_tobject
Imports mod_logger
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_json_helper
Imports rede_ancora_marca_model
Imports rede_ancora_marcas_model
Imports rede_ancora_linha_model
Imports rede_ancora_linhas_model
Imports rede_ancora_familia_model
Imports rede_ancora_familias_model
Imports rede_ancora_catalogo_repository
Imports http_response

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
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _json As TJSONObject = Null
            Dim _marcas As RedeAncoraMarcasModel = Null

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/products/brands"))

                If Not _response.IsSuccess Then
                    Throw New System.Exception("GET /products/brands Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                _json = _response.BodyAsJsonObject()
                _marcas = me.MapearMarcas(_json)
                me._repository.SubstituirMarcas(_marcas)

                mod_logger.Printe("Rede Ancora sync marcas concluido. Registros: " + Parser.IntegerToString(_marcas.Length))

                SincronizarMarcas = _marcas
                _json.Free()
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_marcas) Then
                    _marcas.Free()
                End If

                If Assigned(_json) Then
                    _json.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar marcas Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function SincronizarLinhas(pCodUsuario As Integer) As RedeAncoraLinhasModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _json As TJSONObject = Null
            Dim _linhas As RedeAncoraLinhasModel = Null

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/products/lines"))

                If Not _response.IsSuccess Then
                    Throw New System.Exception("GET /products/lines Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                _json = _response.BodyAsJsonObject()
                _linhas = me.MapearLinhas(_json)
                me._repository.SubstituirLinhas(_linhas)

                mod_logger.Printe("Rede Ancora sync linhas concluido. Registros: " + Parser.IntegerToString(_linhas.Length))

                SincronizarLinhas = _linhas
                _json.Free()
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_linhas) Then
                    _linhas.Free()
                End If

                If Assigned(_json) Then
                    _json.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar linhas Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function SincronizarFamilias(pCodUsuario As Integer) As RedeAncoraFamiliasModel
            Dim _api As RedeAncoraApiClient = Null
            Dim _response As HttpResponse = Null
            Dim _json As TJSONObject = Null
            Dim _familias As RedeAncoraFamiliasModel = Null

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/products/families"))

                If Not _response.IsSuccess Then
                    Throw New System.Exception("GET /products/families Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                _json = _response.BodyAsJsonObject()
                _familias = me.MapearFamilias(_json)
                mod_logger.Printe("Rede Ancora sync familias :: mapeamento OK (" + Parser.IntegerToString(_familias.Length) + ")")
                me._repository.SubstituirFamilias(_familias)

                mod_logger.Printe("Rede Ancora sync familias concluido. Registros: " + Parser.IntegerToString(_familias.Length))

                SincronizarFamilias = _familias
                _json.Free()
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_familias) Then
                    _familias.Free()
                End If

                If Assigned(_json) Then
                    _json.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar familias Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Sub SincronizarCatalogo(pCodUsuario As Integer)
            Dim _marcas As RedeAncoraMarcasModel = Null
            Dim _linhas As RedeAncoraLinhasModel = Null
            Dim _familias As RedeAncoraFamiliasModel = Null

            Try
                mod_logger.Printe("Rede Ancora sync catalogo :: marcas...")
                _marcas = me.SincronizarMarcas(pCodUsuario)
                mod_logger.Printe("Rede Ancora sync catalogo :: linhas...")
                _linhas = me.SincronizarLinhas(pCodUsuario)
                mod_logger.Printe("Rede Ancora sync catalogo :: familias...")
                _familias = me.SincronizarFamilias(pCodUsuario)
                mod_logger.Printe("Rede Ancora sync catalogo concluido.")
                _marcas.Free()
                _linhas.Free()
                _familias.Free()
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

            mod_logger.Printe("Rede Ancora catalogo ja sincronizado. Marcas em cache: " + Parser.IntegerToString(_marcas.Length))
            _marcas.Free()
        End Sub

        Private Function MapearMarcas(pJson As TJSONObject) As RedeAncoraMarcasModel
            Dim _result As New RedeAncoraMarcasModel()
            Dim _data As TJSONArray = RedeAncoraJsonHelper.ObterDataArray(pJson)
            Dim _i As Integer

            If Not Assigned(_data) Then
                Throw New System.Exception("Resposta /products/brands sem array data")
            End If

            For _i = 0 To _data.Length() - 1
                Dim _itemJson As TJSONObject = _data.GetJSONObject(_i)
                Dim _item As New RedeAncoraMarcaModel()

                _item.CodMarca = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "id")
                _item.Nome = RedeAncoraJsonHelper.ObterTextoJson(_itemJson, "name")
                _item.CodCatalogo = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "catalog_code")
                _item.CodErp = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "erp_code")
                _result.Push(_item)
                _itemJson.Free()
            Next

            _data.Free()
            MapearMarcas = _result
        End Function

        Private Function MapearLinhas(pJson As TJSONObject) As RedeAncoraLinhasModel
            Dim _result As New RedeAncoraLinhasModel()
            Dim _data As TJSONArray = RedeAncoraJsonHelper.ObterDataArray(pJson)
            Dim _i As Integer

            If Not Assigned(_data) Then
                Throw New System.Exception("Resposta /products/lines sem array data")
            End If

            For _i = 0 To _data.Length() - 1
                Dim _itemJson As TJSONObject = _data.GetJSONObject(_i)
                Dim _item As New RedeAncoraLinhaModel()

                _item.CodLinha = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "id")
                _item.Nome = RedeAncoraJsonHelper.ObterTextoJson(_itemJson, "name")
                _result.Push(_item)
                _itemJson.Free()
            Next

            _data.Free()
            MapearLinhas = _result
        End Function

        Private Function MapearFamilias(pJson As TJSONObject) As RedeAncoraFamiliasModel
            Dim _result As New RedeAncoraFamiliasModel()
            Dim _data As TJSONArray = RedeAncoraJsonHelper.ObterDataArray(pJson)
            Dim _i As Integer
            Dim _j As Integer
            Dim _jaExiste As Boolean

            If Not Assigned(_data) Then
                Throw New System.Exception("Resposta /products/families sem array data")
            End If

            For _i = 0 To _data.Length() - 1
                Dim _itemJson As TJSONObject = _data.GetJSONObject(_i)
                Dim _item As New RedeAncoraFamiliaModel()

                _item.CodFamilia = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "value")
                _item.Nome = RedeAncoraJsonHelper.ObterTextoJson(_itemJson, "label")
                _itemJson.Free()

                If _item.CodFamilia <= 0 Then
                    _item.Free()
                Else
                    _jaExiste = False

                    For _j = 0 To _result.Length - 1
                        If _result.Take(_j).CodFamilia = _item.CodFamilia Then
                            _jaExiste = True
                            Exit For
                        End If
                    Next

                    If _jaExiste Then
                        _item.Free()
                    Else
                        _result.Push(_item)
                    End If
                End If
            Next

            _data.Free()
            MapearFamilias = _result
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._authService) Then
                    me._authService.Free()
                    me._authService = Null
                End If

                If Assigned(me._repository) Then
                    me._repository.Free()
                    me._repository = Null
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
