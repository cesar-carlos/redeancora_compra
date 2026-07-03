Namespace colors
    Class Color
        Shared Function LightGray() As Integer
            Dim _color As Integer = RGB(193, 205, 205)
            LightGray = _color
        End Function

        Shared Function Disabled() As Integer
            Dim _color As Integer = RGB(193, 205, 205)
            Disabled = _color
        End Function

        Shared Function Required() As Integer
            Dim _color As Integer = RGB(0, 0, 255)
            Required = _color
        End Function

        Shared Function Blue() As Integer
            Dim _color As Integer = RGB(0, 0, 255)
            Blue = _color
        End Function

        Shared Function Green() As Integer
            Dim _color As Integer = RGB(0, 139, 69)
            Green = _color
        End Function

        Shared Function Purple() As Integer
            Dim _color As Integer = RGB(128, 0, 128)
            Purple = _color
        End Function

        Shared Function White() As Integer
            Dim _color As Integer = RGB(248, 248, 255)
            White = _color
        End Function

        Shared Function DefaultColor() As Integer
            Dim _color As Integer = RGB(193, 205, 205)
            DefaultColor = _color
        End Function

        Shared Function Black() As Integer
            Dim _color As Integer = RGB(0, 0, 0)
            Black = _color
        End Function

        Shared Function Gray() As Integer
            Dim _color As Integer = RGB(192, 192, 192)
            Gray = _color
        End Function

        Shared Function Red() As Integer
            Dim _color As Integer = RGB(220, 20, 60)
            Red = _color
        End Function

        Shared Function DefaultBackground() As Integer
            Dim _color As Integer = RGB(197, 193, 170)
            DefaultBackground = _color
        End Function

        Shared Function HeaderColor() As Integer
            Dim _color As Integer = RGB(243, 243, 243)
            HeaderColor = _color
        End Function

        Sub Free()
            MyBase.Free()
        End Sub
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
