Imports IO
Imports Collections
Imports mod_tobject

Namespace file_helper
    Class FileHelper
        Inherits TTObject

        Private Shared Function PathSegmentAt(pPath As String, pDelimiter As String, pIndex As Integer) As String
            Dim _current As String = pPath
            Dim _i As Integer

            For _i = 0 To pIndex - 1
                If Not _current.Contains(pDelimiter) Then
                    PathSegmentAt = ""
                    Exit Function
                End If
                _current = _current.Split(pDelimiter)[1]
            Next

            If _current.Contains(pDelimiter) Then
                PathSegmentAt = _current.Split(pDelimiter)[0]
            Else
                PathSegmentAt = _current
            End If
        End Function

        Private Shared Function HasPathSegmentAt(pPath As String, pDelimiter As String, pIndex As Integer) As Boolean
            If pPath = "" Then
                HasPathSegmentAt = False
                Exit Function
            End If

            If pIndex = 0 Then
                HasPathSegmentAt = True
                Exit Function
            End If

            Dim _current As String = pPath
            Dim _i As Integer

            For _i = 0 To pIndex - 1
                If Not _current.Contains(pDelimiter) Then
                    HasPathSegmentAt = False
                    Exit Function
                End If
                _current = _current.Split(pDelimiter)[1]
            Next

            HasPathSegmentAt = True
        End Function

        Private Shared Function JoinPathSegments(pPath As String, pSegmentLimit As Integer) As String
            If pPath = "" Then
                JoinPathSegments = ""
                Exit Function
            End If

            Dim _delimiter As String = "\"
            Dim _path As String = ""
            Dim _segment As String = ""
            Dim _i As Integer

            For _i = 0 To pSegmentLimit - 1
                If Not FileHelper.HasPathSegmentAt(pPath, _delimiter, _i) Then
                    Exit For
                End If

                _segment = FileHelper.PathSegmentAt(pPath, _delimiter, _i)

                If _i = 0 Then
                    _path = _segment
                Else
                    _path = _path + _delimiter + _segment
                End If
            Next

            JoinPathSegments = _path
        End Function

        ' Conta quantos segmentos (separados por "\") existem em pPath.
        Private Shared Function CountPathSegments(pPath As String) As Integer
            Dim _delimiter As String = "\"
            Dim _count As Integer = 0

            While FileHelper.HasPathSegmentAt(pPath, _delimiter, _count)
                _count = _count + 1
            Wend

            CountPathSegments = _count
        End Function

        ' Equivalente a "dirname": reaproveita JoinPathSegments/HasPathSegmentAt
        ' em vez de reimplementar a divisao de path por conta propria.
        Private Shared Function DirectoryNameOf(pPath As String) As String
            If pPath = "" Or Not pPath.Contains("\") Then
                DirectoryNameOf = ""
                Exit Function
            End If

            Dim _segmentCount As Integer = FileHelper.CountPathSegments(pPath) - 1
            DirectoryNameOf = FileHelper.JoinPathSegments(pPath, _segmentCount)
        End Function

        Private Shared Function EnsureDirectoryPath(pSubDirectory As String) As String
            Dim _basePath As String = FileHelper.GetData7RootDirectory()
            Dim _fullPath As String = _basePath + "\" + pSubDirectory

            If Not FileHelper.DirectoryExists(_fullPath) Then
                FileHelper.CreateDirectory(_fullPath)
            End If

            EnsureDirectoryPath = _fullPath
        End Function

        Shared Function GetExecutableDirectory() As String
            GetExecutableDirectory = FileHelper.DirectoryNameOf(Data7.NomeArquivoExecutavel())
        End Function

        Shared Function GetData7RootDirectory() As String
            GetData7RootDirectory = FileHelper.JoinPathSegments(Data7.NomeArquivoExecutavel(), 2)
        End Function

        Shared Function CreateDirectory(pPath As String) As Boolean
            CreateDirectory = Directory.Create(pPath)
        End Function

        Shared Function DirectoryExists(pPath As String) As Boolean
            DirectoryExists = Directory.Exists(pPath)
        End Function

        Shared Function SelectDirectory(pMessage As String, pRootDir As String = "default user") As String
            SelectDirectory = Directory.SelectDialog(pMessage, pRootDir)
        End Function

        Shared Function DeleteFile(pFile As String) As Boolean
            DeleteFile = File.Delete(pFile)
        End Function

        Shared Function FileExists(pFile As String) As Boolean
            FileExists = File.Exists(pFile)
        End Function

        Shared Function SelectFile(pFormatFiles As String, pRootDir As String = "default user") As String
            SelectFile = File.OpenFileDialog(pRootDir, pFormatFiles)
        End Function

        Shared Function RandomName() As String
            Dim _now As TDateTime = DateTime()
            RandomName = _now.ToString("yyyymmddHHMM") + _now.MilliSecondOf().ToString()
        End Function

        Shared Function DefaultDataPath() As String
            DefaultDataPath = FileHelper.EnsureDirectoryPath("FileData")
        End Function

        Shared Function DefaultErrorPath() As String
            DefaultErrorPath = FileHelper.EnsureDirectoryPath("FileError")
        End Function

        Shared Function DefaultTmpPath() As String
            DefaultTmpPath = FileHelper.EnsureDirectoryPath("tmp")
        End Function

        Shared Function CopyFile(pSource As String, pDestination As String) As Boolean
            File.Copy(pSource, pDestination)
            CopyFile = True
        End Function

        Shared Function SaveToFile(pStringList As StringList, pFullPathName As String) As Boolean
            pStringList.SaveToFile(pFullPathName)
            SaveToFile = True
        End Function

        Shared Function SaveToFile(pContent As String, pFullPathName As String) As Boolean
            Dim _stringList As StringList = New StringList()
            _stringList.Add(pContent)
            _stringList.SaveToFile(pFullPathName)
            _stringList.Free()
            SaveToFile = True
        End Function

        Shared Function ListFiles(pDirectory As String, pFormat As String = "*") As StringList
            Try
                Dim _files As StringList = New StringList()
                File.GetFiles(_files, pDirectory, pFormat)
                ListFiles = _files
            Catch ex As Exception
                Return New StringList()
            End Try
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
                Throw New System.Exception("Error freeing FileHelper: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
