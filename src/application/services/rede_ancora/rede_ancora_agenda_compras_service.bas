Imports mod_tobject
Imports try_parser
Imports rede_ancora_api_config
Imports rede_ancora_url_helper
Imports rede_ancora_autenticacao_service
Imports rede_ancora_api_client
Imports rede_ancora_empresa_service
Imports http_response
Imports rede_ancora_http_erro_helper

Namespace rede_ancora_agenda_compras_service
    Class RedeAncoraAgendaComprasService
        Inherits TTObject

        Private _authService As RedeAncoraAutenticacaoService
        Private _empresaService As RedeAncoraEmpresaService

        Sub New()
            MyBase.New()
            me._authService = New RedeAncoraAutenticacaoService()
            me._empresaService = New RedeAncoraEmpresaService()
        End Sub

        Function ListarOfertasAgenda(pCodUsuario As Integer, pCodMarca As Integer, pCodCentroDistribuicao As Integer) As String
            Dim _url As String = RedeAncoraApiConfig.IntegrationUrl("/sale-offers/brands")

            me._empresaService.ValidarPodeOperar(pCodUsuario)

            If pCodMarca > 0 Then
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "brand_id", Parser.IntegerToString(pCodMarca))
            End If

            If pCodCentroDistribuicao > 0 Then
                _url = RedeAncoraUrlHelper.AppendQueryParam(_url, "seller", Parser.IntegerToString(pCodCentroDistribuicao))
            End If

            ListarOfertasAgenda = me.ExecutarGetPassThrough(pCodUsuario, _url, "GET /sale-offers/brands")
        End Function

        Private Function ExecutarGetPassThrough(pCodUsuario As Integer, pUrl As String, pOperacao As String) As String
            Dim _api As RedeAncoraApiClient = NULL
            Dim _response As HttpResponse = NULL

            Try
                _api = New RedeAncoraApiClient(pCodUsuario, me._authService)
                _response = _api.GetRequest(pUrl)

                If Not _response.IsSuccess Then
                    Throw New System.Exception(me.MontarErroHttp(pOperacao, _response))
                End If

                RedeAncoraHttpErroHelper.ExigirCorpoJson(pOperacao, _response.StatusCode, _response.Body)

                ExecutarGetPassThrough = _response.Body
                _response.Free()
                _api.Free()
            Catch ex As Exception
                RedeAncoraHttpErroHelper.RegistrarExcecao("RedeAncoraAgendaComprasService." & pOperacao, ex)

                If Assigned(_response) Then
                    _response.Free()
                End If

                If Assigned(_api) Then
                    _api.Free()
                End If

                Throw ex
            End Try
        End Function

        Private Function MontarErroHttp(pOperacao As String, pResponse As HttpResponse) As String
            RedeAncoraHttpErroHelper.RegistrarFalha(pOperacao, pResponse.StatusCode, pResponse.Body)
            MontarErroHttp = RedeAncoraHttpErroHelper.MontarMensagem(pOperacao, pResponse.StatusCode, pResponse.Body)
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me._authService) Then
                    me._authService.Free()
                    me._authService = NULL
                End If

                If Assigned(me._empresaService) Then
                    me._empresaService.Free()
                    me._empresaService = NULL
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
