Imports mod_tobject
Imports try_parser

Namespace date_helper
    Class DateHelper
        Inherits TTObject

        Shared Function CurrentDateTime() As TDateTime
            CurrentDateTime = DateTime()
        End Function

        Shared Function TodayAsString() As String
            TodayAsString = DateHelper.CurrentDateTime().ToString("dd/mm/yyyy")
        End Function

        Shared Function TodayAsDateTime() As TDateTime
            TodayAsDateTime = Parser.StringToDate(DateHelper.TodayAsString())
        End Function

        Shared Function TimeAsString() As String
            TimeAsString = DateHelper.CurrentDateTime().ToString("HH:MM:SS")
        End Function

        Shared Function DateTimeAsString() As String
            DateTimeAsString = DateHelper.CurrentDateTime().ToString("dd/mm/yyyy HH:MM:SS")
        End Function

        Shared Function MonthYearAsString() As String
            MonthYearAsString = DateHelper.CurrentDateTime().ToString("mm/yyyy")
        End Function

        Shared Function PreviousMonthDateAsString() As String
            PreviousMonthDateAsString = DateHelper.CurrentDateTime().AddDays(-30).ToString("dd/mm/yyyy")
        End Function

        Shared Function NextMonthDateAsString() As String
            NextMonthDateAsString = DateHelper.CurrentDateTime().AddDays(30).ToString("dd/mm/yyyy")
        End Function

        Shared Function WeekDayName(pDate As TDateTime) As String
            Select WeekDay(pDate)
            Case 1
                WeekDayName = "Domingo"
            Case 2
                WeekDayName = "Segunda"
            Case 3
                WeekDayName = "Terca"
            Case 4
                WeekDayName = "Quarta"
            Case 5
                WeekDayName = "Quinta"
            Case 6
                WeekDayName = "Sexta"
            Case 7
                WeekDayName = "Sabado"
            End Select
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
                Throw New System.Exception("Error freeing DateHelper: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Sub New()
            MyBase.New()
        End Sub
    End Class
End Namespace
