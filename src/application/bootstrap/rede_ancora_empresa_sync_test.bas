Imports mod_logger
Imports mod_tobject
Imports usuario_service
Imports usuario_model
Imports rede_ancora_empresa_model
Imports rede_ancora_centros_distribuicao_model
Imports rede_ancora_centro_distribuicao_model
Imports try_parser

Namespace rede_ancora_empresa_sync_test
    Class RedeAncoraEmpresaSyncTest
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

            Dim _svc As UsuarioService = Null
            Dim _usuario As UsuarioModel = Null
            Dim _empresaSync As RedeAncoraEmpresaModel = Null
            Dim _empresaDb As RedeAncoraEmpresaModel = Null
            Dim _centros As RedeAncoraCentrosDistribuicaoModel = Null
            Dim _i As Integer = 0
            Dim _msg As String = ""

            Try
                mod_logger.Printe("=== Teste sync RedeAncoraEmpresa :: inicio ===")

                _svc = New UsuarioService()
                _usuario = _svc.GetLoggedUsuario()
                _msg = "CodUsuario logado: " + Parser.IntegerToString(_usuario.UserId)
                mod_logger.Printe(_msg)

                If me._chaveApi <> "" Then
                    _svc.SalvarChaveApiRedeAncora(me._chaveApi)
                    _msg = "Chave API gravada para CodUsuario " + Parser.IntegerToString(_usuario.UserId)
                    mod_logger.Printe(_msg)
                End If

                mod_logger.Printe("Chamando GET /profile -> Integracao.RedeAncoraEmpresa...")
                _empresaSync = _svc.SincronizarRedeAncoraPerfil()
                mod_logger.Printe("Sync API concluido. Lendo registro gravado no banco...")

                _empresaDb = _svc.ObterRedeAncoraEmpresa()
                me.ImprimirEmpresa("Banco", _empresaDb)

                _centros = _svc.ListarRedeAncoraCentrosDistribuicao()
                _msg = "Centros de distribuicao gravados: " + Parser.IntegerToString(_centros.Length)
                mod_logger.Printe(_msg)

                For _i = 0 To _centros.Length - 1
                    Dim _cd As RedeAncoraCentroDistribuicaoModel = _centros.Take(_i)

                    _msg = "  CD " + Parser.IntegerToString(_cd.CodCentroDistribuicao)
                    _msg = _msg + " | " + _cd.Nome
                    _msg = _msg + " | estado=" + Parser.IntegerToString(_cd.CodEstado)
                    _msg = _msg + " | pref=" + _cd.Preferencial
                    mod_logger.Printe(_msg)
                Next

                mod_logger.Printe("=== Teste sync RedeAncoraEmpresa :: concluido ===")

                _centros.Free()
                _empresaDb.Free()
                _empresaSync.Free()
                _usuario.Free()
                _svc.Free()
            Catch ex As Exception
                If Assigned(_centros) Then
                    _centros.Free()
                End If

                If Assigned(_empresaDb) Then
                    _empresaDb.Free()
                End If

                If Assigned(_empresaSync) Then
                    _empresaSync.Free()
                End If

                If Assigned(_usuario) Then
                    _usuario.Free()
                End If

                If Assigned(_svc) Then
                    _svc.Free()
                End If

                Throw New System.Exception("Teste sync RedeAncoraEmpresa falhou: " + ex._getMessage())
            End Try
        End Sub

        Private Sub ImprimirEmpresa(pOrigem As String, pModel As RedeAncoraEmpresaModel)
            Dim _msg As String = ""

            _msg = "--- " + pOrigem + " ---"
            mod_logger.Printe(_msg)
            _msg = "CodUsuario: " + Parser.IntegerToString(pModel.CodUsuario)
            mod_logger.Printe(_msg)
            _msg = "CodEmpresaAncora: " + Parser.IntegerToString(pModel.CodEmpresaAncora)
            mod_logger.Printe(_msg)
            _msg = "RazaoSocial: " + pModel.RazaoSocial
            mod_logger.Printe(_msg)
            _msg = "NomeFantasia: " + pModel.NomeFantasia
            mod_logger.Printe(_msg)
            _msg = "CNPJ: " + pModel.Cnpj
            mod_logger.Printe(_msg)
            _msg = "CodEstado: " + Parser.IntegerToString(pModel.CodEstado)
            mod_logger.Printe(_msg)
            _msg = "CD preferencial: " + Parser.IntegerToString(pModel.CodCentroDistribuicaoPreferencial)
            mod_logger.Printe(_msg)
            _msg = "Bloqueado: " + pModel.Bloqueado
            mod_logger.Printe(_msg)
            _msg = "Limite credito: " + CStr(pModel.LimiteCredito)
            mod_logger.Printe(_msg)
            _msg = "IdCarrinhoAtual: " + pModel.IdCarrinhoAtual
            mod_logger.Printe(_msg)
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
