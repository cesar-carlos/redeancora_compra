Imports mod_tobject
Imports mod_logger
Imports diag_stack
Imports try_parser
Imports rede_ancora_json_helper

Namespace rede_ancora_http_erro_helper
    ' Classifica HTTP da API B2B (Swagger + docs locais) sem getters tipados no body.
    Class RedeAncoraHttpErroHelper
        Inherits TTObject

        Shared Function TruncarCorpo(pBody As String) As String
            Dim _texto As String = ""

            TruncarCorpo = ""

            If pBody = "" Then
                Exit Function
            End If

            _texto = pBody.Trim()

            If Len(_texto) <= 500 Then
                TruncarCorpo = _texto
                Exit Function
            End If

            TruncarCorpo = Mid(_texto, 1, 500) & "...[truncado]"
        End Function

        Shared Function EhStatusConhecido(pStatus As Integer) As Boolean
            EhStatusConhecido = False

            If pStatus = 400 Then
                EhStatusConhecido = True
                Exit Function
            End If

            If pStatus = 401 Then
                EhStatusConhecido = True
                Exit Function
            End If

            If pStatus = 403 Then
                EhStatusConhecido = True
                Exit Function
            End If

            If pStatus = 404 Then
                EhStatusConhecido = True
                Exit Function
            End If

            If pStatus = 419 Then
                EhStatusConhecido = True
                Exit Function
            End If

            If pStatus = 422 Then
                EhStatusConhecido = True
                Exit Function
            End If

            If pStatus = 429 Then
                EhStatusConhecido = True
                Exit Function
            End If

            If pStatus = 500 Then
                EhStatusConhecido = True
                Exit Function
            End If

            If pStatus = 504 Then
                EhStatusConhecido = True
            End If
        End Function

        Shared Function ClassificarStatus(pStatus As Integer) As String
            If pStatus = 400 Then
                ClassificarStatus = "validacao ou regra de negocio (HTTP 400). Nao retentar automaticamente"
                Exit Function
            End If

            If pStatus = 401 Then
                ClassificarStatus = "chave API invalida ou sem permissao (HTTP 401)"
                Exit Function
            End If

            If pStatus = 403 Then
                ClassificarStatus = "operacao proibida (HTTP 403). Nao retentar"
                Exit Function
            End If

            If pStatus = 404 Then
                ClassificarStatus = "recurso nao encontrado (HTTP 404)"
                Exit Function
            End If

            If pStatus = 419 Then
                ClassificarStatus = "CSRF invalido (HTTP 419). Integracao por X-API-KEY nao deve enviar CSRF"
                Exit Function
            End If

            If pStatus = 422 Then
                ClassificarStatus = "dados semanticamente invalidos (HTTP 422). Nao retentar automaticamente"
                Exit Function
            End If

            If pStatus = 429 Then
                ClassificarStatus = "rate limit excedido (HTTP 429) apos retries"
                Exit Function
            End If

            If pStatus = 500 Then
                ClassificarStatus = "erro interno do servidor (HTTP 500) apos retry"
                Exit Function
            End If

            If pStatus = 504 Then
                ClassificarStatus = "gateway timeout (HTTP 504) apos retries"
                Exit Function
            End If

            ClassificarStatus = "HTTP inesperado " & Parser.IntegerToString(pStatus)
        End Function

        Shared Function ExtrairDetalheErro(pBody As String) As String
            Dim _message As String = ""
            Dim _errors As String = ""
            Dim _result As String = ""

            ExtrairDetalheErro = ""

            If pBody.Trim() = "" Then
                Exit Function
            End If

            _message = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pBody, "message")
            _errors = RedeAncoraJsonHelper.ObterBlocoJsonDeBlob(pBody, "errors")

            If _message.Trim() <> "" Then
                _result = _message.Trim()
            End If

            If _errors.Trim() <> "" Then
                If _result <> "" Then
                    _result = _result & " errors=" & RedeAncoraHttpErroHelper.TruncarCorpo(_errors)
                Else
                    _result = "errors=" & RedeAncoraHttpErroHelper.TruncarCorpo(_errors)
                End If
            End If

            ExtrairDetalheErro = _result
        End Function

        Shared Function MontarMensagem(pOperacao As String, pStatus As Integer, pBody As String) As String
            Dim _msg As String = ""
            Dim _detalhe As String = ""
            Dim _corpo As String = ""

            _msg = pOperacao & " Rede Ancora falhou. " & RedeAncoraHttpErroHelper.ClassificarStatus(pStatus)
            _detalhe = RedeAncoraHttpErroHelper.ExtrairDetalheErro(pBody)

            If _detalhe <> "" Then
                _msg = _msg & ": " & _detalhe
            Else
                _corpo = RedeAncoraHttpErroHelper.TruncarCorpo(pBody)
                If _corpo <> "" Then
                    _msg = _msg & ": " & _corpo
                End If
            End If

            MontarMensagem = _msg
        End Function

        Shared Sub RegistrarFalha(pOperacao As String, pStatus As Integer, pBody As String)
            Dim _msg As String = RedeAncoraHttpErroHelper.MontarMensagem(pOperacao, pStatus, pBody)

            DiagStack.Trace("http-erro: " & _msg)
            mod_logger.Erro(_msg)
        End Sub

        Shared Sub ExigirCorpoJson(pOperacao As String, pStatus As Integer, pBody As String)
            If pBody.Trim() <> "" Then
                Exit Sub
            End If

            RedeAncoraHttpErroHelper.RegistrarFalha(pOperacao, pStatus, "")
            Throw New System.Exception(pOperacao & " HTTP " & Parser.IntegerToString(pStatus) & " com corpo vazio")
        End Sub

        Shared Sub RegistrarExcecao(pContexto As String, pEx As Exception)
            Dim _detalhe As String = ""

            _detalhe = DiagStack.FormatException(pEx)
            DiagStack.DumpOnError(pEx)
            mod_logger.Erro(pContexto & ": " & _detalhe)
        End Sub

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
