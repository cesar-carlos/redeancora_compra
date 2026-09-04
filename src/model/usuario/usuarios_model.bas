' data7:disable missing-import
Imports usuario_model
Imports rede_ancora_json_helper

Namespace usuarios_model
    Class UsuariosModel
        Inherits TTList<UsuarioModel>

        Sub New()
            MyBase.New()
        End Sub

        Function FindByUserId(pUserId As Integer) As UsuarioModel
            Dim _i As Integer
            For _i = 0 To me.Length - 1
                If me.Take(_i).UserId = pUserId Then
                    FindByUserId = me.Take(_i)
                    Exit Function
                End If
            Next
        End Function

        Function ToJson() As String
            Dim _json As TJSONArray = me.ToJsonObject()
            ToJson = _json.ToString()
            _json.Free()
        End Function

        Function ToJsonObject() As TJSONArray
            Dim _i As Integer
            Dim _json As New TJSONArray
            For _i = 0 To me.Length - 1
                _json.PutObject(me.Take(_i).ToJsonObject())
            Next
            ToJsonObject = _json
        End Function

        Shared Function FromJson(pString As String) As UsuariosModel
            Dim _i As Integer = 0
            Dim _elem As String = ""
            Dim _result As UsuariosModel = NULL
            Dim _item As UsuarioModel = NULL

            Try
                _result = New UsuariosModel()

                For _i = 0 To 9999
                    _elem = RedeAncoraJsonHelper.ExtrairElementoArrayJson(pString, _i)

                    If _elem = "" Then
                        Exit For
                    End If

                    _item = UsuarioModel.FromJson(_elem)
                    _result.Push(_item)
                    _item = NULL
                Next
            Catch ex As Exception
                If Assigned(_item) Then
                    _item.Free()
                End If

                If Assigned(_result) Then
                    _result.Free()
                End If

                Throw ex
            End Try

            FromJson = _result
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
