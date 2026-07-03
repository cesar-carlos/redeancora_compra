Imports mod_tobject
Imports mod_logger
Imports rede_ancora_api_config
Imports rede_ancora_autenticacao_model
Imports rede_ancora_autenticacao_repository
Imports rede_ancora_http_client
Imports http_response
Imports http_client
Imports rede_ancora_json_helper

Namespace rede_ancora_autenticacao_service
    Class RedeAncoraAutenticacaoService
        Inherits TTObject

        Private _repository As RedeAncoraAutenticacaoRepository

        Sub New()
            MyBase.New()
            me._repository = New RedeAncoraAutenticacaoRepository()
        End Sub

        Private Function CreateClient(pAuth As RedeAncoraAutenticacaoModel) As HttpClient
            CreateClient = RedeAncoraHttpClient.Criar(pAuth)
        End Function

        Private Function RespostaPingValida(pBody As String) As Boolean
            Dim _body As String = pBody.Trim()
            Dim _json As TJSONObject = NULL
            Dim _data As String = ""

            RespostaPingValida = False

            If _body = "" Then
                Exit Function
            End If

            If Mid(_body, 1, 1) = "{" Then
                Try
                    _json = New TJSONObject(_body)
                    _data = RedeAncoraJsonHelper.ObterTextoJson(_json, "data").Trim()

                    If _data.ToUpper() = "PONG" Then
                        RespostaPingValida = True
                    End If

                    _json.Free()
                    Exit Function
                Catch ex As Exception
                    If Assigned(_json) Then
                        _json.Free()
                    End If
                End Try
            End If

            RespostaPingValida = _body.ToUpper().Contains("PONG")
        End Function

        Function Ping() As Boolean
            Dim _client As HttpClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _url As String = RedeAncoraApiConfig.IntegrationUrl("/ping")

            Try
                mod_logger.Printe("Ping URL: " + _url)
                _client = me.CreateClient(NULL)
                _response = _client.GetRequest(_url)
                mod_logger.Printe("Ping HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)

                If Not _response.IsSuccess Then
                    Throw New System.Exception("GET /ping HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                If Not me.RespostaPingValida(_response.Body) Then
                    Throw New System.Exception("GET /ping resposta inesperada: " + _response.Body)
                End If

                Ping = True
                _response.Free()
                _client.Free()
            Catch ex As Exception
                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_client) Then
                    _client.Free()
                End If

                Throw ex
            End Try
        End Function

        Function GarantirChaveApi(pCodUsuario As Integer) As RedeAncoraAutenticacaoModel
            Dim _model As RedeAncoraAutenticacaoModel = me._repository.ObterPorCodUsuario(pCodUsuario)

            If Not _model.TemChaveApi() Then
                _model.Free()
                Throw New System.Exception("Chave API Rede Ancora nao configurada para CodUsuario " + pCodUsuario.ToString() + ". Grave X-API-KEY em Integracao.RedeAncoraAutenticacao.")
            End If

            GarantirChaveApi = _model
        End Function

        Function ObterAutenticacao(pCodUsuario As Integer) As RedeAncoraAutenticacaoModel
            ObterAutenticacao = me._repository.ObterPorCodUsuario(pCodUsuario)
        End Function

        Function TryObterAutenticacao(pCodUsuario As Integer, pItem As RedeAncoraAutenticacaoModel) As Boolean
            TryObterAutenticacao = me._repository.TryObterPorCodUsuario(pCodUsuario, pItem)
        End Function

        Sub SalvarChaveApi(pCodUsuario As Integer, pChaveApi As String)
            Dim _auth As RedeAncoraAutenticacaoModel = New RedeAncoraAutenticacaoModel()

            Try
                If Not me._repository.TryObterPorCodUsuario(pCodUsuario, _auth) Then
                    _auth.CodUsuario = pCodUsuario
                    _auth.SetEmail("integracao@data7.local")
                End If

                _auth.ChaveApi = pChaveApi
                _auth.Ativo = "S"
                me._repository.Salvar(_auth)
                _auth.Free()
            Catch ex As Exception
                If Assigned(_auth) Then
                    _auth.Free()
                End If

                Throw New System.Exception("Erro ao salvar chave API Rede Ancora: " + ex._getMessage())
            End Try
        End Sub

        Sub AtualizarUsuarioDeProfileJson(pCodUsuario As Integer, pJson As TJSONObject)
            Dim _model As RedeAncoraAutenticacaoModel = NULL

            Try
                _model = me._repository.ObterPorCodUsuario(pCodUsuario)
                me.PreencherUsuarioDeProfile(pJson, _model)
                me._repository.Salvar(_model)
                _model.Free()
            Catch ex As Exception
                If Assigned(_model) Then
                    _model.Free()
                End If

                Throw New System.Exception("Erro ao atualizar usuario Rede Ancora a partir do profile: " + ex._getMessage())
            End Try
        End Sub

        Function SincronizarUsuarioApi(pCodUsuario As Integer) As RedeAncoraAutenticacaoModel
            Dim _auth As RedeAncoraAutenticacaoModel = NULL
            Dim _model As RedeAncoraAutenticacaoModel = NULL
            Dim _client As HttpClient = NULL
            Dim _response As HttpResponse = NULL
            Dim _json As TJSONObject = NULL

            Try
                _auth = me.GarantirChaveApi(pCodUsuario)
                _client = me.CreateClient(_auth)
                _response = _client.GetRequest(RedeAncoraApiConfig.IntegrationUrl("/profile"))

                If Not _response.IsSuccess Then
                    Throw New System.Exception("GET /profile Rede Ancora falhou. HTTP " + _response.StatusCode.ToString() + ": " + _response.Body)
                End If

                _model = me._repository.ObterPorCodUsuario(pCodUsuario)
                _json = _response.BodyAsJsonObject()
                me.PreencherUsuarioDeProfile(_json, _model)
                me._repository.Salvar(_model)

                SincronizarUsuarioApi = _model
                _json.Free()
                _response.Free()
                _client.Free()
                _auth.Free()
            Catch ex As Exception
                If Assigned(_json) Then
                    _json.Free()
                End If

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_client) Then
                    _client.Free()
                End If

                If Assigned(_auth) Then
                    _auth.Free()
                End If

                If Assigned(_model) Then
                    _model.Free()
                End If

                Throw New System.Exception("Erro ao sincronizar usuario Rede Ancora: " + ex._getMessage())
            End Try
        End Function

        Private Sub PreencherUsuarioDeProfile(pJson As TJSONObject, pModel As RedeAncoraAutenticacaoModel)
            Dim _data As TJSONObject = RedeAncoraJsonHelper.ObterRaizOuDataObjeto(pJson)
            Dim _perfil As TJSONObject = RedeAncoraJsonHelper.UsarRaizOuData(pJson, _data)
            Dim _user As TJSONObject = NULL
            Dim _company As TJSONObject = NULL
            Dim _emailApi As String = ""

            _user = RedeAncoraJsonHelper.ObterFilhoJson(_perfil, "user")

            If Assigned(_user) Then
                pModel.IdUsuarioApi = RedeAncoraJsonHelper.ObterInteiroJson(_user, "id")
                pModel.NomeUsuario = RedeAncoraJsonHelper.ObterTextoJson(_user, "name")
                _emailApi = RedeAncoraJsonHelper.ObterTextoJson(_user, "email")
                _user.Free()
            End If

            _company = RedeAncoraJsonHelper.ObterFilhoJson(_perfil, "company")

            If Assigned(_company) Then
                pModel.CodSeller = RedeAncoraJsonHelper.ObterInteiroJson(_company, "warehouse_preferencial")
                _company.Free()
            End If

            If _emailApi.Trim() <> "" Then
                pModel.SetEmail(_emailApi)
            End If

            If Assigned(_data) Then
                _data.Free()
            End If
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
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
