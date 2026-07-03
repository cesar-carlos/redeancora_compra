Imports mod_tobject

Namespace barcode_helper
    Class BarCodeHelper
        Inherits TTObject

        Private Shared Function SplitSegmentAt(pValue As String, pDelimiter As String) As String
            If pValue.Contains(pDelimiter) Then
                SplitSegmentAt = pValue.Split(pDelimiter)[1].Trim()
            Else
                SplitSegmentAt = pValue.Trim()
            End If
        End Function

        Shared Function IsBarCode(pValue As String) As Boolean
            Dim _maxInternalCodeLength As Integer = 7
            Dim _subtractDelimiter As String = "-"
            Dim _multiplyDelimiter As String = "*"

            If Not pValue.Contains(_subtractDelimiter) And Not pValue.Contains(_multiplyDelimiter) Then
                IsBarCode = pValue.Trim().Length > _maxInternalCodeLength
                Exit Function
            End If

            If pValue.Contains(_subtractDelimiter) Then
                IsBarCode = BarCodeHelper.SplitSegmentAt(pValue, _subtractDelimiter).Length > _maxInternalCodeLength
                Exit Function
            End If

            If pValue.Contains(_multiplyDelimiter) Then
                IsBarCode = BarCodeHelper.SplitSegmentAt(pValue, _multiplyDelimiter).Length > _maxInternalCodeLength
            End If
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
                Throw New System.Exception("Error freeing BarCodeHelper: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
