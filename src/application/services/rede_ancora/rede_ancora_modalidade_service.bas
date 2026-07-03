Imports mod_tobject
Imports mod_logger
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_json_helper
Imports rede_ancora_modalidade_model
Imports rede_ancora_modalidades_model
Imports rede_ancora_modalidade_repository
Imports http_response

Namespace rede_ancora_modalidade_service
    Class RedeAncoraModalidadeService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _repository As RedeAncoraModalidadeRepository

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._repository = New RedeAncoraModalidadeRepository()
        End Sub

        Function SincronizarModalidades(pCodUsuario As Integer) As RedeAncoraModalidadesModel
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _json As TJSONObject = NULL
            Dim _modalidades As RedeAncoraModalidadesModel = NULL

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/modalities"))

                If Not _response.IsSuccess Then
                    Throw New System.Exception("GET /modalities Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                _json = _response.BodyAsJsonObject()
                _modalidades = me.MapearModalidades(_json)
                me._repository.SubstituirTodos(_modalidades)

                mod_logger.Printe("Rede Ancora sync modalidades concluido. Registros: " + Parser.IntegerToString(_modalidades.Length))

                SincronizarModalidades = _modalidades
                _json.Free()
                _response.Free()
                _api.Free()
            Catch ex As Exception
                If Assigned(_modalidades) Then
                    _modalidades.Free()
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

                Throw New System.Exception("Erro ao sincronizar modalidades Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Function ListarModalidades() As RedeAncoraModalidadesModel
            ListarModalidades = me._repository.ListarTodos()
        End Function

        Function ObterDescricaoModalidade(pCodModalidade As Integer) As String
            Dim _modalidades As RedeAncoraModalidadesModel = NULL

            Try
                _modalidades = me.ListarModalidades()
                ObterDescricaoModalidade = _modalidades.ObterDescricao(pCodModalidade)
                _modalidades.Free()
            Catch ex As Exception
                If Assigned(_modalidades) Then
                    _modalidades.Free()
                End If

                Throw ex
            End Try
        End Function

        Sub ValidarModalidade(pCodModalidade As Integer)
            Dim _modalidades As RedeAncoraModalidadesModel = NULL

            Try
                _modalidades = me.ListarModalidades()

                If _modalidades.Length <= 0 Then
                    Throw New System.Exception("Modalidades Rede Ancora nao sincronizadas")
                End If

                If Not _modalidades.ExistePorCodigo(pCodModalidade) Then
                    Throw New System.Exception("Modalidade invalida na Rede Ancora: " + pCodModalidade.ToString())
                End If

                _modalidades.Free()
            Catch ex As Exception
                If Assigned(_modalidades) Then
                    _modalidades.Free()
                End If

                Throw ex
            End Try
        End Sub

        Function GarantirModalidadesSincronizadas(pCodUsuario As Integer) As RedeAncoraModalidadesModel
            Dim _modalidades As RedeAncoraModalidadesModel = me.ListarModalidades()

            If _modalidades.Length <= 0 Then
                _modalidades.Free()
                GarantirModalidadesSincronizadas = me.SincronizarModalidades(pCodUsuario)
                Exit Function
            End If

            GarantirModalidadesSincronizadas = _modalidades
        End Function

        Private Function MapearModalidades(pJson As TJSONObject) As RedeAncoraModalidadesModel
            Dim _result As New RedeAncoraModalidadesModel()
            Dim _data As TJSONArray = RedeAncoraJsonHelper.ObterDataArray(pJson)
            Dim _i As Integer

            If Not Assigned(_data) Then
                Throw New System.Exception("Resposta /modalities sem array data")
            End If

            For _i = 0 To _data.Length() - 1
                Dim _itemJson As TJSONObject = _data.GetJSONObject(_i)
                Dim _item As New RedeAncoraModalidadeModel()

                _item.CodModalidade = RedeAncoraJsonHelper.ObterInteiroJson(_itemJson, "value")
                _item.Descricao = RedeAncoraJsonHelper.ObterTextoJson(_itemJson, "label")
                _result.Push(_item)
                _itemJson.Free()
            Next

            _data.Free()
            MapearModalidades = _result
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
