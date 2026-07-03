' data7:disable missing-import
Imports usuario_model

Namespace usuarios_model
    Class UsuariosModel
        Inherits TTList<UsuarioModel>

        Public Sub New()
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
            Dim _result As New UsuariosModel()
            Dim _json As New TJSONArray(pString)
            For _i = 0 To _json.Length() - 1
                _result.Push(UsuarioModel.FromJson(_json.GetJSONObject(_i).ToString()))
            Next
            _json.Free()
            FromJson = _result
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
