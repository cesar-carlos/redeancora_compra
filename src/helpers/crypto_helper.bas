Imports mod_tobject

Namespace crypto_helper
    Class CryptoHelper
        Inherits TTObject

        Shared Function Encrypt(pValue As String) As String
            Encrypt = Data7.Criptografar(pValue)
        End Function

        Shared Function Decrypt(pValue As String) As String
            Decrypt = Data7.Descriptografar(pValue)
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
                Throw New System.Exception("Error freeing CryptoHelper: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
