Imports mod_tobject

Namespace rede_ancora_autenticacao_model
    Class RedeAncoraAutenticacaoModel
        Inherits TTObject

        CodUsuario As Integer
        Email As String
        ChaveApi As String
        Ativo As String
        IdUsuarioApi As Integer
        NomeUsuario As String
        CodSeller As Integer

        Sub New()
            MyBase.New()
            me.Email = ""
            me.ChaveApi = ""
            me.Ativo = "S"
            me.NomeUsuario = ""
        End Sub

        Sub New(pValue As RedeAncoraAutenticacaoModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As RedeAncoraAutenticacaoModel)
            If Assigned(pValue) Then
                me.CodUsuario = pValue.CodUsuario
                me.Email = pValue.Email
                me.ChaveApi = pValue.ChaveApi
                me.Ativo = pValue.Ativo
                me.IdUsuarioApi = pValue.IdUsuarioApi
                me.NomeUsuario = pValue.NomeUsuario
                me.CodSeller = pValue.CodSeller
            End If
        End Sub

        Sub SetEmail(pValue As String)
            Dim _raw As String = pValue.Trim().ToLower()

            If _raw = "" Then
                Exit Sub
            End If

            me.Email = _raw
        End Sub

        Function IsEmailValido() As Boolean
            IsEmailValido = me.Email.Trim() <> ""
        End Function

        Function TemChaveApi() As Boolean
            TemChaveApi = me.ChaveApi.Trim() <> "" And me.Ativo = "S"
        End Function

        Function TemSellerPadrao() As Boolean
            TemSellerPadrao = me.CodSeller > 0
        End Function

        Sub Validate()
            If me.Email.Trim() = "" Then
                Throw New System.Exception("Email invalido em RedeAncoraAutenticacaoModel: vazio")
            End If

            If me.CodUsuario <= 0 Then
                Throw New System.Exception("CodUsuario invalido em RedeAncoraAutenticacaoModel")
            End If

            If me.ChaveApi = "" Then
                Throw New System.Exception("ChaveApi invalida em RedeAncoraAutenticacaoModel")
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraAutenticacaoModel
            Clone = New RedeAncoraAutenticacaoModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = me.CodUsuario.ToString()
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            Try
                If Not me.Disposed Then
                    me.Dispose()
                End If

                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Erro ao liberar RedeAncoraAutenticacaoModel: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
