Imports mod_tobject
Imports crypto_helper
Imports date_helper

Namespace uid_helper
    Class UidHelper
        Inherits TTObject

        Shared Function BuildUid() As String
            Dim _now As TDateTime = DateHelper.CurrentDateTime()
            Dim _payload As String = "{ "
            _payload += """UserName"":""" + data7.NomeUsuario() + """, "
            _payload += """CreatedAt"":""" + _now.ToString("dd/mm/yyyy HH:MM") + """, "
            _payload += """WindowsUser"":""" + Environment.UserName() + """, "
            _payload += """Computer"":""" + Environment.MachineName() + """ "
            _payload += "}"
            BuildUid = CryptoHelper.Encrypt(_payload)
        End Function

        Shared Function BuildUid(pPayload As String) As String
            Dim _payload As String = "{ " + pPayload + " }"
            BuildUid = CryptoHelper.Encrypt(_payload)
        End Function

        Shared Function BuildTimeUid() As String
            Dim _now As TDateTime = DateHelper.CurrentDateTime()
            Dim _payload As String = _now.ToString("yyyymmddHHMMSS") + _now.MilliSecondOf().ToString()
            BuildTimeUid = CryptoHelper.Encrypt(_payload)
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
                Throw New System.Exception("Error freeing UidHelper: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
