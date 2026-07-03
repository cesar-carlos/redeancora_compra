Imports file_helper
Imports Forms
Imports logo_image_base64
Imports alert_image_base64
Imports icon_hp12c_base64
Imports icon_calculadora_base64

Namespace assets
    Class Asset
        Shared Function Logo() As String
            Logo = LogoImageBase64.Value()
        End Function

        Shared Function Alert() As String
            Alert = AlertImageBase64.Value()
        End Function

        Shared Function IconHP12C() As String
            IconHP12C = IconHp12cBase64.Value()
        End Function

        Shared Function IconCalculadora() As String
            IconCalculadora = IconCalculadoraBase64.Value()
        End Function

        Shared Function Base64(pKey As String) As String
            Select Case pKey.ToLower()
                Case "logo"
                    Base64 = Asset.Logo()
                Case "alert"
                    Base64 = Asset.Alert()
                Case "icon_hp12c", "hp12c"
                    Base64 = Asset.IconHP12C()
                Case "icon_calculadora", "calculadora"
                    Base64 = Asset.IconCalculadora()
                Case Else
                    Base64 = ""
            End Select
        End Function

        Shared Function DataUri(pBase64 As String, pMimeType As String) As String
            DataUri = "data:" + pMimeType + ";base64," + pBase64
        End Function

        Shared Function PngDataUri(pBase64 As String) As String
            PngDataUri = Asset.DataUri(pBase64, "image/png")
        End Function

        Shared Function JpegDataUri(pBase64 As String) As String
            JpegDataUri = Asset.DataUri(pBase64, "image/jpeg")
        End Function

        Shared Function ToTempFile(pBase64 As String, pFileName As String) As String
            Dim _path As String = FileHelper.DefaultTmpPath() + "\" + pFileName
            Base64ToFile(pBase64, _path)
            ToTempFile = _path
        End Function

        Shared Sub LoadIntoImagem(pBase64 As String, pImage As Imagem, pFileName As String)
            pImage.LoadFromFile(Asset.ToTempFile(pBase64, pFileName))
        End Sub

        Shared Sub LoadLogo(pImage As Imagem)
            Asset.LoadIntoImagem(Asset.Logo(), pImage, "rac_logo.png")
        End Sub

        Shared Sub LoadAlert(pImage As Imagem)
            Asset.LoadIntoImagem(Asset.Alert(), pImage, "rac_alert.jpg")
        End Sub

        Shared Sub LoadIconHP12C(pImage As Imagem)
            Asset.LoadIntoImagem(Asset.IconHP12C(), pImage, "rac_icon_hp12c.bmp")
        End Sub

        Shared Sub LoadIconCalculadora(pImage As Imagem)
            Asset.LoadIntoImagem(Asset.IconCalculadora(), pImage, "rac_icon_calculadora.bmp")
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
