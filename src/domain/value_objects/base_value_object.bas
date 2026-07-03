Imports mod_tobject
Imports string_helper

Namespace base_value_object
    Class BaseValueObject
        Inherits TTObject

        Protected _value As String

        Protected Sub New()
            MyBase.New()
            me._value = ""
        End Sub

        Protected Sub New(pValue As String)
            MyBase.New()
            me._value = pValue
        End Sub

        Function Value() As String
            Value = me._value
        End Function

        Overridable Function IsValid() As Boolean
            IsValid = False
        End Function

        Overridable Function ToString() As String
            ToString = me._value
        End Function

        Protected Shared Function OnlyDigits(pValue As String) As String
            OnlyDigits = StringHelper.ExtractNumbers(pValue)
        End Function

        Protected Shared Function HasOnlyRepeatedDigits(pValue As String) As Boolean
            If pValue = "" Then
                HasOnlyRepeatedDigits = True
                Exit Function
            End If

            Dim _first As String = Mid(pValue, 1, 1)
            Dim _i As Integer
            Dim _char As String = ""

            For _i = 2 To pValue.Length
                _char = Mid(pValue, _i, 1)

                If _char <> _first Then
                    HasOnlyRepeatedDigits = False
                    Exit Function
                End If
            Next

            HasOnlyRepeatedDigits = True
        End Function

        Protected Shared Function Mod11Digit(pSum As Integer) As Integer
            Dim _remainder As Integer = pSum Mod 11
            Mod11Digit = 0

            If _remainder >= 2 Then
                Mod11Digit = 11 - _remainder
            End If
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me._value = ""
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
                Throw New System.Exception("Error freeing BaseValueObject: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
