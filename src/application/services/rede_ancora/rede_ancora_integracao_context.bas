Imports usuario_repository
Imports usuario_model

Namespace rede_ancora_integracao_context
    Class RedeAncoraIntegracaoContext
        Shared Function ObterUsuarioLogado() As UsuarioModel
            Dim _repo As UsuarioRepository = Null
            Dim _usuario As UsuarioModel = Null

            Try
                _repo = New UsuarioRepository()
                _usuario = _repo.GetLoggedUsuario()

                If _usuario.UserId <= 0 Then
                    _usuario.Free()
                    _usuario = Null
                    Throw New System.Exception("Usuario ERP nao autenticado. Efetue login antes de operar a integracao Rede Ancora.")
                End If

                ObterUsuarioLogado = _usuario
                _repo.Free()
            Catch ex As Exception
                If Assigned(_usuario) Then
                    _usuario.Free()
                End If

                If Assigned(_repo) Then
                    _repo.Free()
                End If

                Throw ex
            End Try
        End Function

        Shared Function ObterCodUsuarioLogado() As Integer
            Dim _usuario As UsuarioModel = Null
            ObterCodUsuarioLogado = 0

            Try
                _usuario = RedeAncoraIntegracaoContext.ObterUsuarioLogado()
                ObterCodUsuarioLogado = _usuario.UserId
                _usuario.Free()
            Catch ex As Exception
                If Assigned(_usuario) Then
                    _usuario.Free()
                End If

                Throw ex
            End Try
        End Function

        Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub

    End Class
End Namespace
