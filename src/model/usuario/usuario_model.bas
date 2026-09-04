Imports mod_tobject
Imports rede_ancora_json_helper

Namespace usuario_model
    Class UsuarioModel
        Inherits TTObject

        CompanyCode As Integer
        BranchCode As Integer
        SessionId As String
        UserId As Integer
        UserName As String
        Password As String
        FinancialAccountCode As String
        CashPeriodCode As Integer
        CashPeriodStatus As String
        StockSectorCode As Integer
        ConferenceSectorCode As Integer
        ComputerName As String
        WindowsUser As String
        SystemVersion As String
        Database As String

        Sub New()
            MyBase.New()
        End Sub

        Sub New (pValue As UsuarioModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Shared Function BuildSessionId(pUserName As String) As String
            Dim _now As TDateTime = DateTime()
            Dim _payload As String = "{ "
            _payload += """UserName"":""" + pUserName + """, "
            _payload += """CreatedAt"":""" + _now.ToString("dd/mm/yyyy HH:MM") + """ "
            _payload += "}"
            BuildSessionId = Data7.Criptografar(_payload)
        End Function

        Function RefreshSessionId() As String
            me.SessionId = UsuarioModel.BuildSessionId(me.UserName)
            RefreshSessionId = me.SessionId
        End Function

        Sub Assign(pValue As UsuarioModel)
            If Assigned(pValue) Then
                me.CompanyCode = pValue.CompanyCode
                me.BranchCode = pValue.BranchCode
                me.SessionId = pValue.SessionId
                me.UserId = pValue.UserId
                me.UserName = pValue.UserName
                me.Password = pValue.Password
                me.FinancialAccountCode = pValue.FinancialAccountCode
                me.CashPeriodCode = pValue.CashPeriodCode
                me.CashPeriodStatus = pValue.CashPeriodStatus
                me.StockSectorCode = pValue.StockSectorCode
                me.ConferenceSectorCode = pValue.ConferenceSectorCode
                me.ComputerName = pValue.ComputerName
                me.WindowsUser = pValue.WindowsUser
                me.SystemVersion = pValue.SystemVersion
                me.Database = pValue.Database
            End If
        End Sub

        Overrides Function Clone() As UsuarioModel
            Clone = New UsuarioModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = me.UserId.toString()
        End Function

        Function ToJson() As String
            Dim _json As TJSONObject = me.ToJsonObject()
            ToJson = _json.ToString()
            _json.Free()
        End Function

        Function ToJsonObject() As TJSONObject
            Dim _json As New TJSONObject
            _json.PutInteger("CompanyCode", me.CompanyCode)
            _json.PutInteger("BranchCode", me.BranchCode)
            _json.PutString("SessionId", me.SessionId)
            _json.PutInteger("UserId", me.UserId)
            _json.PutString("UserName", me.UserName)
            _json.PutString("FinancialAccountCode", me.FinancialAccountCode)
            _json.PutInteger("CashPeriodCode", me.CashPeriodCode)
            _json.PutString("CashPeriodStatus", me.CashPeriodStatus)
            _json.PutInteger("StockSectorCode", me.StockSectorCode)
            _json.PutInteger("ConferenceSectorCode", me.ConferenceSectorCode)
            _json.PutString("ComputerName", me.ComputerName)
            _json.PutString("WindowsUser", me.WindowsUser)
            _json.PutString("SystemVersion", me.SystemVersion)
            _json.PutString("Database", me.Database)
            ToJsonObject = _json
        End Function

        Shared Function FromJson(pString As String) As UsuarioModel
            Dim model As UsuarioModel = NULL

            Try
                model = New UsuarioModel()
                model.CompanyCode = RedeAncoraJsonHelper.ObterInteiroJsonDeBlob(pString, "CompanyCode")
                model.BranchCode = RedeAncoraJsonHelper.ObterInteiroJsonDeBlob(pString, "BranchCode")
                model.SessionId = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pString, "SessionId")
                model.UserId = RedeAncoraJsonHelper.ObterInteiroJsonDeBlob(pString, "UserId")
                model.UserName = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pString, "UserName")
                model.FinancialAccountCode = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pString, "FinancialAccountCode")
                model.CashPeriodCode = RedeAncoraJsonHelper.ObterInteiroJsonDeBlob(pString, "CashPeriodCode")
                model.CashPeriodStatus = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pString, "CashPeriodStatus")
                model.StockSectorCode = RedeAncoraJsonHelper.ObterInteiroJsonDeBlob(pString, "StockSectorCode")
                model.ConferenceSectorCode = RedeAncoraJsonHelper.ObterInteiroJsonDeBlob(pString, "ConferenceSectorCode")
                model.ComputerName = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pString, "ComputerName")
                model.WindowsUser = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pString, "WindowsUser")
                model.SystemVersion = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pString, "SystemVersion")
                model.Database = RedeAncoraJsonHelper.ObterTextoJsonDeBlob(pString, "Database")
            Catch ex As Exception
                If Assigned(model) Then
                    model.Free()
                End If

                Throw ex
            End Try

            FromJson = model
        End Function

        Overridable Function ToString() As String
            With me.BuildLogger(me.ClassName)
                .Prop("CompanyCode", me.CompanyCode)
                .Prop("BranchCode", me.BranchCode)
                .Prop("SessionId", me.SessionId)
                .Prop("UserId", me.UserId)
                .Prop("UserName", me.UserName)
                .Prop("FinancialAccountCode", me.FinancialAccountCode)
                .Prop("CashPeriodCode", me.CashPeriodCode)
                .Prop("CashPeriodStatus", me.CashPeriodStatus)
                .Prop("StockSectorCode", me.StockSectorCode)
                .Prop("ConferenceSectorCode", me.ConferenceSectorCode)
                .Prop("ComputerName", me.ComputerName)
                .Prop("WindowsUser", me.WindowsUser)
                .Prop("SystemVersion", me.SystemVersion)
                .Prop("Database", me.Database)
                ToString = .Text()
                .Free()
            End With
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

                MyBase.free()
            Catch ex As Exception
                Throw New system.exception("Error freeing UsuarioModel: " + char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
