Imports mod_tobject

Namespace rede_ancora_url_helper
    Class RedeAncoraUrlHelper
        Inherits TTObject

        Shared Function EncodeQueryParam(pValor As String) As String
            Dim _i As Integer
            Dim _ch As String = ""
            Dim _result As String = ""
            Dim _code As Integer
            Dim _hex As String = ""

            For _i = 1 To Len(pValor)
                _ch = Mid(pValor, _i, 1)

                If RedeAncoraUrlHelper.IsCaractereSeguroQuery(_ch) Then
                    _result = _result + _ch
                ElseIf _ch = " " Then
                    _result = _result + "%20"
                Else
                    _code = RedeAncoraUrlHelper.CodigoDoCaractere(_ch)

                    If _code < 0 Then
                        _result = _result + _ch
                    Else
                        _hex = Hex(_code).ToUpper()

                        If Len(_hex) = 1 Then
                            _hex = "0" + _hex
                        End If

                        _result = _result + "%" + _hex
                    End If
                End If
            Next

            EncodeQueryParam = _result
        End Function

        Shared Function AppendQueryParam(pUrl As String, pNome As String, pValor As String) As String
            If pNome.Trim() = "" Or pValor.Trim() = "" Then
                AppendQueryParam = pUrl
                Exit Function
            End If

            Dim _separador As String = "?"

            If pUrl.Contains("?") Then
                _separador = "&"
            End If

            AppendQueryParam = pUrl + _separador + pNome + "=" + RedeAncoraUrlHelper.EncodeQueryParam(pValor)
        End Function

        Private Shared Function IsCaractereSeguroQuery(pCh As String) As Boolean
            If pCh >= "0" And pCh <= "9" Then
                IsCaractereSeguroQuery = True
                Exit Function
            End If

            If pCh >= "A" And pCh <= "Z" Then
                IsCaractereSeguroQuery = True
                Exit Function
            End If

            If pCh >= "a" And pCh <= "z" Then
                IsCaractereSeguroQuery = True
                Exit Function
            End If

            IsCaractereSeguroQuery = pCh = "-" Or pCh = "_" Or pCh = "." Or pCh = "~"
        End Function

        Private Shared Function CodigoDoCaractere(pCh As String) As Integer
            Dim _i As Integer

            CodigoDoCaractere = -1

            For _i = 0 To 255
                If Char(_i) = pCh Then
                    CodigoDoCaractere = _i
                    Exit Function
                End If
            Next
        End Function

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
