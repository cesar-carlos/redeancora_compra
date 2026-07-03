Imports mod_logger
Imports mod_tobject
Imports rede_ancora_autenticacao_service
Imports rede_ancora_autenticacao_model
Imports rede_ancora_integracao_context
Imports try_parser

Namespace rede_ancora_smoke_test
    Class RedeAncoraSmokeTest
        Inherits TTObject

        Private _habilitado As Boolean
        Private _chaveApi As String

        Sub New()
            MyBase.New()
            me._habilitado = True
            me._chaveApi = ""
        End Sub

        Sub Definir(pHabilitar As Boolean)
            me._habilitado = pHabilitar
        End Sub

        Sub DefinirChaveApi(pChaveApi As String)
            me._chaveApi = pChaveApi
        End Sub

        Sub Executar()
            If Not me._habilitado Then
                Exit Sub
            End If

            Dim _authService As RedeAncoraAutenticacaoService = NULL
            Dim _codUsuario As Integer = 0

            Try
                mod_logger.Printe("=== Rede Ancora smoke test :: inicio ===")
                _authService = New RedeAncoraAutenticacaoService()
                _authService.Ping()
                mod_logger.Printe("Smoke: ping OK")

                If me._chaveApi <> "" Then
                    Dim _auth As RedeAncoraAutenticacaoModel = NULL

                    _codUsuario = RedeAncoraIntegracaoContext.ObterCodUsuarioLogado()
                    _authService.SalvarChaveApi(_codUsuario, me._chaveApi)
                    _auth = _authService.SincronizarUsuarioApi(_codUsuario)
                    mod_logger.Printe("Smoke: chave API + GET /profile OK (CodUsuario " + Parser.IntegerToString(_codUsuario) + ")")
                    _auth.Free()
                End If

                mod_logger.Printe("=== Rede Ancora smoke test :: concluido ===")
                _authService.Free()
                _authService = NULL
            Catch ex As Exception
                If Assigned(_authService) Then
                    _authService.Free()
                End If

                Throw New System.Exception("Rede Ancora smoke test falhou: " + ex._getMessage())
            End Try
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
