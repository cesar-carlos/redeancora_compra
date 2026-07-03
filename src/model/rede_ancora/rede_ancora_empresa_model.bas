Imports mod_tobject
Imports cnpj_vo
Imports cpf_vo

Namespace rede_ancora_empresa_model
    Class RedeAncoraEmpresaModel
        Inherits TTObject

        CodEmpresaAncora As Integer
        CodUsuario As Integer
        CodInterno As Integer
        RazaoSocial As String
        NomeFantasia As String
        Cnpj As String
        CodEstado As Integer
        CodCentroDistribuicaoPreferencial As Integer
        CpfResponsavel As String
        Bloqueado As String
        MotivosBloqueio As String
        SaldoAtual As Double
        LimiteCredito As Double
        LimiteUtilizado As Double
        IdCarrinhoAtual As String
        Marketplace As String
        Permissoes As String

        Sub New()
            MyBase.New()
            me.RazaoSocial = ""
            me.NomeFantasia = ""
            me.Cnpj = ""
            me.CpfResponsavel = ""
            me.Bloqueado = "N"
            me.MotivosBloqueio = ""
            me.IdCarrinhoAtual = ""
            me.Marketplace = "N"
            me.Permissoes = ""
        End Sub

        Sub New(pValue As RedeAncoraEmpresaModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As RedeAncoraEmpresaModel)
            If Assigned(pValue) Then
                me.CodEmpresaAncora = pValue.CodEmpresaAncora
                me.CodUsuario = pValue.CodUsuario
                me.CodInterno = pValue.CodInterno
                me.RazaoSocial = pValue.RazaoSocial
                me.NomeFantasia = pValue.NomeFantasia
                me.Cnpj = pValue.Cnpj
                me.CodEstado = pValue.CodEstado
                me.CodCentroDistribuicaoPreferencial = pValue.CodCentroDistribuicaoPreferencial
                me.CpfResponsavel = pValue.CpfResponsavel
                me.Bloqueado = pValue.Bloqueado
                me.MotivosBloqueio = pValue.MotivosBloqueio
                me.SaldoAtual = pValue.SaldoAtual
                me.LimiteCredito = pValue.LimiteCredito
                me.LimiteUtilizado = pValue.LimiteUtilizado
                me.IdCarrinhoAtual = pValue.IdCarrinhoAtual
                me.Marketplace = pValue.Marketplace
                me.Permissoes = pValue.Permissoes
            End If
        End Sub

        Sub SetCnpj(pValue As String)
            Dim _cnpj As cnpj_vo.Cnpj = cnpj_vo.Cnpj.Create(pValue)
            me.Cnpj = _cnpj.Value()
            _cnpj.Free()
        End Sub

        Sub SetCpfResponsavel(pValue As String)
            If pValue.Trim() = "" Then
                me.CpfResponsavel = ""
                Exit Sub
            End If

            Dim _cpf As Cpf = Cpf.Create(pValue)
            me.CpfResponsavel = _cpf.Value()
            _cpf.Free()
        End Sub

        Function IsCnpjValido() As Boolean
            IsCnpjValido = cnpj_vo.Cnpj.IsValidCnpj(me.Cnpj)
        End Function

        Function IsCpfResponsavelValido() As Boolean
            If me.CpfResponsavel = "" Then
                IsCpfResponsavelValido = True
                Exit Function
            End If

            IsCpfResponsavelValido = Cpf.IsValidCpf(me.CpfResponsavel)
        End Function

        Function IsBloqueado() As Boolean
            IsBloqueado = me.Bloqueado = "S"
        End Function

        Function TemPermissao(pPermissao As String) As Boolean
            Dim _permissao As String = pPermissao.Trim().ToLower()
            Dim _lista As String = ""

            TemPermissao = False

            If _permissao = "" Or me.Permissoes.Trim() = "" Then
                Exit Function
            End If

            _lista = "," + me.Permissoes.ToLower().Trim() + ","
            TemPermissao = _lista.Contains("," + _permissao + ",")
        End Function

        ' API real retorna CARRINHO_VER / CARRINHO_COMPLETO (nao "checkout" da doc Swagger).
        Function TemPermissaoCarrinho() As Boolean
            Dim _tem As Boolean = False

            _tem = me.TemPermissao("CARRINHO_VER")

            If _tem Then
                TemPermissaoCarrinho = True
                Exit Function
            End If

            _tem = me.TemPermissao("CARRINHO_COMPLETO")

            If _tem Then
                TemPermissaoCarrinho = True
                Exit Function
            End If

            TemPermissaoCarrinho = me.TemPermissao("checkout")
        End Function

        ' API real retorna FECHAR_PEDIDO (nao "orders" da doc Swagger).
        Function TemPermissaoPedido() As Boolean
            Dim _tem As Boolean = False

            _tem = me.TemPermissao("FECHAR_PEDIDO")

            If _tem Then
                TemPermissaoPedido = True
                Exit Function
            End If

            TemPermissaoPedido = me.TemPermissao("orders")
        End Function

        Function CnpjFormatado() As String
            If Not me.IsCnpjValido() Then
                CnpjFormatado = me.Cnpj
                Exit Function
            End If

            Dim _cnpj As cnpj_vo.Cnpj = cnpj_vo.Cnpj.Create(me.Cnpj)
            CnpjFormatado = _cnpj.Formatted()
            _cnpj.Free()
        End Function

        Sub Validate()
            If me.CodUsuario <= 0 Then
                Throw New System.Exception("CodUsuario invalido em RedeAncoraEmpresaModel")
            End If

            If me.CodEmpresaAncora <= 0 Then
                Throw New System.Exception("CodEmpresaAncora invalido em RedeAncoraEmpresaModel")
            End If

            If Not me.IsCnpjValido() Then
                Throw New System.Exception("CNPJ invalido em RedeAncoraEmpresaModel: " + me.Cnpj)
            End If

            If Not me.IsCpfResponsavelValido() Then
                Throw New System.Exception("CPF responsavel invalido em RedeAncoraEmpresaModel: " + me.CpfResponsavel)
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraEmpresaModel
            Clone = New RedeAncoraEmpresaModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = me.CodEmpresaAncora.ToString()
        End Function

        Function ToJsonObject() As TJSONObject
            Dim _json As New TJSONObject
            _json.PutInteger("CodEmpresaAncora", me.CodEmpresaAncora)
            _json.PutInteger("CodUsuario", me.CodUsuario)
            _json.PutInteger("CodInterno", me.CodInterno)
            _json.PutString("RazaoSocial", me.RazaoSocial)
            _json.PutString("NomeFantasia", me.NomeFantasia)
            _json.PutString("Cnpj", me.CnpjFormatado())
            _json.PutInteger("CodEstado", me.CodEstado)
            _json.PutInteger("CodCentroDistribuicaoPreferencial", me.CodCentroDistribuicaoPreferencial)
            _json.PutString("CpfResponsavel", me.CpfResponsavel)
            _json.PutString("Bloqueado", me.Bloqueado)
            _json.PutString("MotivosBloqueio", me.MotivosBloqueio)
            _json.PutString("SaldoAtual", me.SaldoAtual.ToString())
            _json.PutString("LimiteCredito", me.LimiteCredito.ToString())
            _json.PutString("LimiteUtilizado", me.LimiteUtilizado.ToString())
            _json.PutString("IdCarrinhoAtual", me.IdCarrinhoAtual)
            _json.PutString("Marketplace", me.Marketplace)
            _json.PutString("Permissoes", me.Permissoes)
            ToJsonObject = _json
        End Function

        Function ToJson() As String
            Dim _json As TJSONObject = me.ToJsonObject()
            ToJson = _json.ToString()
            _json.Free()
        End Function

        Overridable Function ToString() As String
            With me.BuildLogger(me.ClassName)
                .Prop("CodEmpresaAncora", me.CodEmpresaAncora)
                .Prop("CodUsuario", me.CodUsuario)
                .Prop("CodInterno", me.CodInterno)
                .Prop("RazaoSocial", me.RazaoSocial)
                .Prop("NomeFantasia", me.NomeFantasia)
                .Prop("Cnpj", me.CnpjFormatado())
                .Prop("CodEstado", me.CodEstado)
                .Prop("CodCentroDistribuicaoPreferencial", me.CodCentroDistribuicaoPreferencial)
                .Prop("CpfResponsavel", me.CpfResponsavel)
                .Prop("Bloqueado", me.Bloqueado)
                .Prop("MotivosBloqueio", me.MotivosBloqueio)
                .Prop("SaldoAtual", me.SaldoAtual)
                .Prop("LimiteCredito", me.LimiteCredito)
                .Prop("LimiteUtilizado", me.LimiteUtilizado)
                .Prop("IdCarrinhoAtual", me.IdCarrinhoAtual)
                .Prop("Marketplace", me.Marketplace)
                .Prop("Permissoes", me.Permissoes)
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

                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Erro ao liberar RedeAncoraEmpresaModel: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
