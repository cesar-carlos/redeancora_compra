' Migration 001 — Integração Rede Âncora B2B (auth, empresa, produto, carrinho e pedido)
Imports migration_controller
Imports migration_column
Imports migration_columns
Imports migration_table
Imports integracao_schema
Imports sql_helper
Imports diag_stack

Namespace rede_ancora_migration
    Class RedeAncoraMigration
        Private _controller As MigrationController

        Sub New()
            MyBase.New()
            _controller = New MigrationController()
        End Sub

        Sub Run()
            Dim _schema As String = IntegracaoSchema.Nome()

            DiagStack.Push("schema=" + _schema)
            DiagStack.Trace("boot: schema=" + _schema)
            DiagStack.Push("EnsureSchema")
            DiagStack.Trace("boot: EnsureSchema start")
            _controller.EnsureSchema(_schema)
            DiagStack.Pop()
            DiagStack.Pop()
            DiagStack.Trace("boot: EnsureSchema ok")
            DiagStack.Push("CriarTabelaAutenticacao")
            DiagStack.Trace("boot: CriarTabelaAutenticacao start")
            me.CriarTabelaAutenticacao(_schema)
            DiagStack.Pop()
            DiagStack.Trace("boot: CriarTabelaAutenticacao ok")
            me.AtualizarColunasAutenticacao(_schema)
            me.RemoverColunasAutenticacaoObsoletas(_schema)
            me.CriarTabelaEmpresa(_schema)
            me.AtualizarColunasEmpresa(_schema)
            me.RenomearCodEmpresaParaCodEmpresaAncora(_schema)
            me.CriarTabelaCentroDistribuicao(_schema)
            me.CriarTabelaModalidade(_schema)
            me.CriarTabelaMarca(_schema)
            me.CriarTabelaLinha(_schema)
            me.CriarTabelaFamilia(_schema)
            me.CriarTabelaProduto(_schema)
            me.CriarTabelaProdutoVinculo(_schema)
            me.AtualizarColunasProdutoVinculo(_schema)
            me.CriarIndiceProdutoVinculo(_schema)
            me.CriarTabelaProdutoImagem(_schema)
            me.CriarTabelaCarrinho(_schema)
            me.AtualizarColunasCarrinho(_schema)
            me.CriarTabelaCarrinhoItem(_schema)
            me.AtualizarColunasCarrinhoItem(_schema)
            me.RenomearCodigoProdutoParaCodigoReferenciaFabricante(_schema)
            me.AtualizarEstruturaCarrinhoLocal(_schema)
            me.CriarTabelaPedido(_schema)
            me.AlterarTamanhosColunasTexto(_schema)
            me.AlterarCodCarrinhoParaInteiro(_schema)
            me.AjustarEstruturaCarrinhoSemCodUsuario(_schema)
            me.RemoverCodUsuarioDoCarrinhoItem(_schema)
            me.AtualizarColunasAuditoriaCarrinhoItem(_schema)
            me.LimparTabelaReordCarrinhoItemOrfa(_schema)
            me.ReordenarColunasCarrinhoItem(_schema)
            me.CorrigirNomePkCarrinhoItemLegado(_schema)
            me.AjustarNullabilidadeAuditoriaCarrinhoItem(_schema)
        End Sub

        Private Sub CriarTabelaAutenticacao(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaAutenticacao()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodUsuario", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Email", "VARCHAR(100)", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "ChaveApi", "VARCHAR(255)", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Ativo", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "IdUsuarioApi", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "NomeUsuario", "VARCHAR(120)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodSeller", "INTEGER", True, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub AtualizarColunasAutenticacao(pSchema As String)
            Dim _tabela As String = IntegracaoSchema.TabelaAutenticacao()

            _controller.CreateColumn(pSchema, _tabela, "IdUsuarioApi", "INTEGER")
            _controller.CreateColumn(pSchema, _tabela, "NomeUsuario", "VARCHAR(120)")
            _controller.CreateColumn(pSchema, _tabela, "CodSeller", "INTEGER")
        End Sub

        Private Sub RemoverColunasAutenticacaoObsoletas(pSchema As String)
            Dim _tabela As String = IntegracaoSchema.TabelaAutenticacao()

            _controller.DropColumnIfExists(pSchema, _tabela, "TokenAcesso")
            _controller.DropColumnIfExists(pSchema, _tabela, "DataExpiracaoToken")
        End Sub

        Private Sub CriarTabelaEmpresa(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaEmpresa()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodUsuario", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodEmpresaAncora", "INTEGER", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodInterno", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "RazaoSocial", "VARCHAR(200)", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "NomeFantasia", "VARCHAR(200)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Cnpj", "VARCHAR(14)", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodEstado", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodCentroDistribuicaoPreferencial", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CpfResponsavel", "VARCHAR(11)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Bloqueado", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "MotivosBloqueio", "VARCHAR(2000)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "SaldoAtual", "DECIMAL(18,2)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "LimiteCredito", "DECIMAL(18,2)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "LimiteUtilizado", "DECIMAL(18,2)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "IdCarrinhoAtual", "VARCHAR(36)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Marketplace", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Permissoes", "VARCHAR(4000)", True, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub AtualizarColunasEmpresa(pSchema As String)
            Dim _tabela As String = IntegracaoSchema.TabelaEmpresa()

            _controller.CreateColumn(pSchema, _tabela, "Bloqueado", "VARCHAR(1)")
            _controller.CreateColumn(pSchema, _tabela, "MotivosBloqueio", "VARCHAR(2000)")
            _controller.CreateColumn(pSchema, _tabela, "SaldoAtual", "DECIMAL(18,2)")
            _controller.CreateColumn(pSchema, _tabela, "LimiteCredito", "DECIMAL(18,2)")
            _controller.CreateColumn(pSchema, _tabela, "LimiteUtilizado", "DECIMAL(18,2)")
            _controller.CreateColumn(pSchema, _tabela, "IdCarrinhoAtual", "VARCHAR(36)")
            _controller.CreateColumn(pSchema, _tabela, "Marketplace", "VARCHAR(1)")
            _controller.CreateColumn(pSchema, _tabela, "Permissoes", "VARCHAR(4000)")
        End Sub

        Private Sub RenomearCodEmpresaParaCodEmpresaAncora(pSchema As String)
            Dim _tabela As String = IntegracaoSchema.TabelaEmpresa()
            Dim _colunaAntiga As String = pSchema + "." + _tabela + ".CodEmpresa"
            Dim _sql As String = ""

            _sql = "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabela) + " " +_
                "AND c.name = " + SqlHelper.SqlText("CodEmpresa") + ") " +_
                "AND NOT EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabela) + " " +_
                "AND c.name = " + SqlHelper.SqlText("CodEmpresaAncora") + ") " +_
                "EXEC sp_rename " + SqlHelper.SqlText(_colunaAntiga) + ", " + SqlHelper.SqlText("CodEmpresaAncora") + ", " + SqlHelper.SqlText("COLUMN")

            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub AlterarTamanhosColunasTexto(pSchema As String)
            Dim _empresa As String = IntegracaoSchema.TabelaEmpresaQualificada()
            Dim _centro As String = IntegracaoSchema.TabelaCentroDistribuicaoQualificada()
            Dim _produto As String = IntegracaoSchema.TabelaProdutoVinculoQualificada()
            Dim _carrinhoItem As String = IntegracaoSchema.TabelaCarrinhoItemQualificada()
            Dim _sql As String = ""

            _sql = "SET ANSI_WARNINGS ON; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(IntegracaoSchema.TabelaEmpresa()) + " " +_
                "AND c.name = " + SqlHelper.SqlText("RazaoSocial") + " AND c.max_length < 200) " +_
                "ALTER TABLE " + _empresa + " ALTER COLUMN RazaoSocial VARCHAR(200) NOT NULL; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(IntegracaoSchema.TabelaEmpresa()) + " " +_
                "AND c.name = " + SqlHelper.SqlText("NomeFantasia") + " AND c.max_length < 200) " +_
                "ALTER TABLE " + _empresa + " ALTER COLUMN NomeFantasia VARCHAR(200) NULL; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(IntegracaoSchema.TabelaEmpresa()) + " " +_
                "AND c.name = " + SqlHelper.SqlText("MotivosBloqueio") + " AND c.max_length < 2000) " +_
                "ALTER TABLE " + _empresa + " ALTER COLUMN MotivosBloqueio VARCHAR(2000) NULL; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(IntegracaoSchema.TabelaEmpresa()) + " " +_
                "AND c.name = " + SqlHelper.SqlText("Permissoes") + " AND c.max_length < 4000) " +_
                "ALTER TABLE " + _empresa + " ALTER COLUMN Permissoes VARCHAR(4000) NULL; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(IntegracaoSchema.TabelaCentroDistribuicao()) + " " +_
                "AND c.name = " + SqlHelper.SqlText("NomeFantasia") + " AND c.max_length < 120) " +_
                "ALTER TABLE " + _centro + " ALTER COLUMN NomeFantasia VARCHAR(120) NULL; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(IntegracaoSchema.TabelaProdutoVinculo()) + " " +_
                "AND c.name = " + SqlHelper.SqlText("DescricaoAncora") + " AND c.max_length < 255) " +_
                "ALTER TABLE " + _produto + " ALTER COLUMN DescricaoAncora VARCHAR(255) NULL; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(IntegracaoSchema.TabelaCarrinhoItem()) + " " +_
                "AND c.name = " + SqlHelper.SqlText("Descricao") + " AND c.max_length < 255) " +_
                "ALTER TABLE " + _carrinhoItem + " ALTER COLUMN Descricao VARCHAR(255) NULL; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(IntegracaoSchema.TabelaCarrinhoItem()) + " " +_
                "AND c.name = " + SqlHelper.SqlText("DescricaoCondicaoPagamento") + " AND c.max_length < 120) " +_
                "ALTER TABLE " + _carrinhoItem + " ALTER COLUMN DescricaoCondicaoPagamento VARCHAR(120) NULL"

            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub CriarTabelaCentroDistribuicao(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaCentroDistribuicao()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodUsuario", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodCentroDistribuicao", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Nome", "VARCHAR(120)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "NomeFantasia", "VARCHAR(120)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodEstado", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Preferencial", "VARCHAR(1)", True, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub CriarTabelaModalidade(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaModalidade()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodModalidade", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Descricao", "VARCHAR(60)", False, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub CriarTabelaMarca(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaMarca()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodMarca", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Nome", "VARCHAR(120)", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodCatalogo", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodErp", "INTEGER", True, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub CriarTabelaLinha(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaLinha()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodLinha", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Nome", "VARCHAR(120)", False, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub CriarTabelaFamilia(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaFamilia()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodFamilia", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Nome", "VARCHAR(120)", False, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub CriarTabelaProduto(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaProduto()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "Cna", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CatalogoId", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Csa", "VARCHAR(30)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Cnl", "VARCHAR(30)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodigoReferencia", "VARCHAR(30)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodeEdi", "VARCHAR(30)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodeManufacturer", "VARCHAR(30)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "NomeProduto", "VARCHAR(255)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "NomeErp", "VARCHAR(255)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "InformacoesAdicionais", "VARCHAR(2000)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "InformacoesComplementares", "VARCHAR(2000)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "AdditionalDescription", "VARCHAR(2000)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "PontoCriticoAtencao", "VARCHAR(255)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Dimensoes", "VARCHAR(255)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodMarca", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodMarcaErp", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "NomeMarca", "VARCHAR(120)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodLinha", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "NomeLinha", "VARCHAR(120)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodFamilia", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "NomeFamilia", "VARCHAR(120)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodFabricante", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Ean", "VARCHAR(20)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Gtin", "VARCHAR(20)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Ncm", "VARCHAR(30)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Cest", "VARCHAR(20)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Origem", "VARCHAR(10)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "OrigemLabel", "VARCHAR(200)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Anp", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "AnpLabel", "VARCHAR(200)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "PesoLiquido", "DECIMAL(18,4)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "PesoBruto", "DECIMAL(18,4)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Volume", "DECIMAL(18,4)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Litros", "DECIMAL(18,4)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Tamanho", "VARCHAR(60)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Material", "VARCHAR(120)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Tipo", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "MedidaVenda", "VARCHAR(20)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "GarantiaDias", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "FracaoFabrica", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "FracaoLoja", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Status", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "ErpHandle", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Leadtime", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Ativo", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Descontinuado", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Bloqueado", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Confiavel", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Sugerido", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Lancamento", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "OnDemand", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "OnDemandLabel", "VARCHAR(120)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "MotivoDescontinuado", "VARCHAR(255)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "ParcialmenteSimilar", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "HasRestrictions", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "PrazoEspecial", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "DataAtualizacao", "DATETIME", True, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub CriarTabelaProdutoVinculo(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaProdutoVinculo()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "Cna", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodProduto", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodigoAncora", "VARCHAR(30)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "DescricaoAncora", "VARCHAR(255)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodMarca", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodLinha", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodFamilia", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Ativo", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "DataVinculo", "DATETIME", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "DataAtualizacao", "DATETIME", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "OrigemVinculo", "VARCHAR(20)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Observacao", "VARCHAR(255)", True, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub AtualizarColunasProdutoVinculo(pSchema As String)
            Dim _tabela As String = IntegracaoSchema.TabelaProdutoVinculo()

            _controller.CreateColumn(pSchema, _tabela, "CodLinha", "INTEGER")
            _controller.CreateColumn(pSchema, _tabela, "CodFamilia", "INTEGER")
            _controller.CreateColumn(pSchema, _tabela, "DataAtualizacao", "DATETIME")
            _controller.CreateColumn(pSchema, _tabela, "Observacao", "VARCHAR(255)")
        End Sub

        Private Sub CriarIndiceProdutoVinculo(pSchema As String)
            Dim _tabela As String = IntegracaoSchema.TabelaProdutoVinculoQualificada()
            Dim _sql As String = ""

            _sql = "SET ANSI_WARNINGS ON; " +_
                "IF NOT EXISTS (SELECT 1 FROM sys.indexes i " +_
                "INNER JOIN sys.tables t ON i.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(IntegracaoSchema.TabelaProdutoVinculo()) + " " +_
                "AND i.name = " + SqlHelper.SqlText("UX_RedeAncoraProdutoVinculo_CodProdutoAtivo") + ") " +_
                "CREATE UNIQUE INDEX UX_RedeAncoraProdutoVinculo_CodProdutoAtivo ON " + _tabela + " (CodProduto) WHERE CodProduto > 0 AND Ativo = " + SqlHelper.SqlText("S")

            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub CriarTabelaProdutoImagem(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaProdutoImagem()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "Cna", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Item", "VARCHAR(5)", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "TipoImagem", "VARCHAR(15)", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "DataAtualizacao", "DATETIME", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Url", "VARCHAR(500)", False, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub CriarTabelaCarrinho(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaCarrinho()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodCarrinho", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "IdCarrinho", "VARCHAR(36)", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Convertido", "VARCHAR(1)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Canal", "VARCHAR(50)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "QtdItens", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "QtdItensTotal", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Subtotal", "DECIMAL(18,2)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Impostos", "DECIMAL(18,2)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Total", "DECIMAL(18,2)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "DataAtualizacao", "DATETIME", True, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub CriarTabelaCarrinhoItem(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaCarrinhoItem()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodCarrinho", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Item", "VARCHAR(5)", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "IdItemApi", "INTEGER", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Cna", "INTEGER", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodCentroDistribuicao", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodCondicaoPagamento", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "DescricaoCondicaoPagamento", "VARCHAR(120)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodProduto", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodigoReferenciaFabricante", "VARCHAR(30)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Descricao", "VARCHAR(255)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodModalidade", "INTEGER", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "Quantidade", "INTEGER", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "PrecoUnitario", "DECIMAL(18,4)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "ImpostoUnitario", "DECIMAL(18,4)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "CodUsuario", "INTEGER", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "NomeUsuario", "VARCHAR(30)", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "DataLancamento", "DATE", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "HoraLancamento", "VARCHAR(8)", False, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "EstacaoTrabalho", "VARCHAR(50)", False, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Private Sub AtualizarColunasCarrinho(pSchema As String)
            Dim _tabela As String = IntegracaoSchema.TabelaCarrinho()

            _controller.CreateColumn(pSchema, _tabela, "CodCarrinho", "INTEGER")
        End Sub

        Private Sub AtualizarColunasCarrinhoItem(pSchema As String)
            Dim _tabela As String = IntegracaoSchema.TabelaCarrinhoItem()

            _controller.CreateColumn(pSchema, _tabela, "CodProduto", "INTEGER")
            _controller.CreateColumn(pSchema, _tabela, "CodCarrinho", "INTEGER")
            _controller.CreateColumn(pSchema, _tabela, "Item", "VARCHAR(5)")
        End Sub

        Private Sub AtualizarEstruturaCarrinhoLocal(pSchema As String)
            Dim _carrinho As String = IntegracaoSchema.TabelaCarrinhoQualificada()
            Dim _item As String = IntegracaoSchema.TabelaCarrinhoItemQualificada()
            Dim _tabelaCarrinho As String = IntegracaoSchema.TabelaCarrinho()
            Dim _tabelaItem As String = IntegracaoSchema.TabelaCarrinhoItem()
            Dim _sql As String = ""

            _sql = "SET ANSI_WARNINGS ON; " +_
                "UPDATE " + _carrinho + " SET CodCarrinho = 1 " +_
                "WHERE CodCarrinho IS NULL OR CodCarrinho <= 0; " +_
                "UPDATE " + _item + " SET CodCarrinho = 1 " +_
                "WHERE CodCarrinho IS NULL OR CodCarrinho <= 0"
            _controller.ExecuteSql(_sql)

            If _controller.ColumnExists(pSchema, _tabelaCarrinho, "CodUsuario") Then
                If _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuario") Then
                    _sql = "UPDATE i SET i.CodCarrinho = c.CodCarrinho " +_
                        "FROM " + _item + " i " +_
                        "INNER JOIN " + _carrinho + " c ON c.CodUsuario = i.CodUsuario " +_
                        "WHERE i.CodCarrinho IS NULL OR i.CodCarrinho <= 0"
                    _controller.ExecuteSql(_sql)
                ElseIf _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuarioAncora") Then
                    _sql = "UPDATE i SET i.CodCarrinho = c.CodCarrinho " +_
                        "FROM " + _item + " i " +_
                        "INNER JOIN " + _carrinho + " c ON c.CodUsuario = i.CodUsuarioAncora " +_
                        "WHERE i.CodCarrinho IS NULL OR i.CodCarrinho <= 0"
                    _controller.ExecuteSql(_sql)
                End If
            End If

            If _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuario") Then
                _sql = "UPDATE i SET i.Item = RIGHT(" + SqlHelper.SqlText("00000") + " + CAST(n.Seq AS VARCHAR(5)), 5) " +_
                    "FROM " + _item + " i " +_
                    "INNER JOIN ( " +_
                    "    SELECT CodUsuario, IdItemApi, " +_
                    "           ROW_NUMBER() OVER (PARTITION BY CodUsuario ORDER BY IdItemApi) AS Seq " +_
                    "    FROM " + _item + " " +_
                    ") n ON n.CodUsuario = i.CodUsuario AND n.IdItemApi = i.IdItemApi " +_
                    "WHERE i.Item IS NULL OR LTRIM(RTRIM(i.Item)) = " + SqlHelper.SqlText("")
                _controller.ExecuteSql(_sql)
            Else
                _sql = "UPDATE i SET i.Item = RIGHT(" + SqlHelper.SqlText("00000") + " + CAST(n.Seq AS VARCHAR(5)), 5) " +_
                    "FROM " + _item + " i " +_
                    "INNER JOIN ( " +_
                    "    SELECT CodCarrinho, IdItemApi, " +_
                    "           ROW_NUMBER() OVER (PARTITION BY CodCarrinho ORDER BY IdItemApi) AS Seq " +_
                    "    FROM " + _item + " " +_
                    ") n ON n.CodCarrinho = i.CodCarrinho AND n.IdItemApi = i.IdItemApi " +_
                    "WHERE i.Item IS NULL OR LTRIM(RTRIM(i.Item)) = " + SqlHelper.SqlText("")
                _controller.ExecuteSql(_sql)
            End If

            If Not _controller.ColumnExists(pSchema, _tabelaItem, "IdCarrinho") Then
                Exit Sub
            End If

            _sql = "DECLARE @pkItem NVARCHAR(200); " +_
                "SELECT @pkItem = kc.name " +_
                "FROM sys.key_constraints kc " +_
                "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " AND kc.type = " + SqlHelper.SqlText("PK") + "; " +_
                "IF @pkItem IS NOT NULL AND EXISTS (SELECT 1 FROM sys.index_columns ic " +_
                "INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id " +_
                "INNER JOIN sys.tables t ON ic.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "INNER JOIN sys.key_constraints kc ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " AND kc.name = @pkItem AND c.name = " + SqlHelper.SqlText("IdItemApi") + ") " +_
                "BEGIN " +_
                "DECLARE @sqlDropPk NVARCHAR(MAX); " +_
                "SET @sqlDropPk = N'ALTER TABLE " + _item + " DROP CONSTRAINT ' + QUOTENAME(@pkItem); " +_
                "EXEC sp_executesql @sqlDropPk; " +_
                "END"
            _controller.ExecuteSql(_sql)

            If _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuario") Then
                _sql = "IF NOT EXISTS (SELECT 1 FROM sys.key_constraints kc " +_
                    "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                    "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                    "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " AND kc.type = " + SqlHelper.SqlText("PK") + ") " +_
                    "ALTER TABLE " + _item + " ADD CONSTRAINT PK_RedeAncoraCarrinhoItem PRIMARY KEY (CodUsuario, CodCarrinho, Item)"
                _controller.ExecuteSql(_sql)
            Else
                _sql = "IF NOT EXISTS (SELECT 1 FROM sys.key_constraints kc " +_
                    "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                    "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                    "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " AND kc.type = " + SqlHelper.SqlText("PK") + ") " +_
                    "ALTER TABLE " + _item + " ADD CONSTRAINT PK_RedeAncoraCarrinhoItem PRIMARY KEY (CodCarrinho, Item)"
                _controller.ExecuteSql(_sql)
            End If

            _sql = "ALTER TABLE " + _item + " DROP COLUMN IdCarrinho"
            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub AlterarCodCarrinhoParaInteiro(pSchema As String)
            Dim _carrinho As String = IntegracaoSchema.TabelaCarrinhoQualificada()
            Dim _item As String = IntegracaoSchema.TabelaCarrinhoItemQualificada()
            Dim _tabelaCarrinho As String = IntegracaoSchema.TabelaCarrinho()
            Dim _tabelaItem As String = IntegracaoSchema.TabelaCarrinhoItem()
            Dim _sql As String = ""

            _sql = "SET ANSI_WARNINGS ON; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaCarrinho) + " " +_
                "AND c.name = " + SqlHelper.SqlText("CodCarrinho") + " AND ty.name IN (" + SqlHelper.SqlText("varchar") + ", " + SqlHelper.SqlText("nvarchar") + ")) " +_
                "BEGIN " +_
                "UPDATE " + _carrinho + " SET CodCarrinho = CASE WHEN TRY_CAST(CodCarrinho AS INTEGER) > 0 THEN TRY_CAST(CodCarrinho AS INTEGER) ELSE 1 END; " +_
                "ALTER TABLE " + _carrinho + " ALTER COLUMN CodCarrinho INTEGER NOT NULL; " +_
                "END"
            _controller.ExecuteSql(_sql)

            If _controller.ColumnExists(pSchema, _tabelaCarrinho, "CodUsuario") Then
                If _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuario") Then
                    _sql = "UPDATE i SET i.CodCarrinho = CASE WHEN TRY_CAST(i.CodCarrinho AS INTEGER) > 0 THEN TRY_CAST(i.CodCarrinho AS INTEGER) ELSE c.CodCarrinho END " +_
                        "FROM " + _item + " i " +_
                        "LEFT JOIN " + _carrinho + " c ON c.CodUsuario = i.CodUsuario"
                    _controller.ExecuteSql(_sql)
                ElseIf _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuarioAncora") Then
                    _sql = "UPDATE i SET i.CodCarrinho = CASE WHEN TRY_CAST(i.CodCarrinho AS INTEGER) > 0 THEN TRY_CAST(i.CodCarrinho AS INTEGER) ELSE c.CodCarrinho END " +_
                        "FROM " + _item + " i " +_
                        "LEFT JOIN " + _carrinho + " c ON c.CodUsuario = i.CodUsuarioAncora"
                    _controller.ExecuteSql(_sql)
                End If
            Else
                _sql = "UPDATE " + _item + " SET CodCarrinho = CASE WHEN TRY_CAST(CodCarrinho AS INTEGER) > 0 THEN TRY_CAST(CodCarrinho AS INTEGER) ELSE 1 END " +_
                    "WHERE EXISTS (SELECT 1 FROM sys.columns c " +_
                    "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                    "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                    "INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id " +_
                    "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " " +_
                    "AND c.name = " + SqlHelper.SqlText("CodCarrinho") + " AND ty.name IN (" + SqlHelper.SqlText("varchar") + ", " + SqlHelper.SqlText("nvarchar") + "))"
                _controller.ExecuteSql(_sql)
            End If

            _sql = "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " " +_
                "AND c.name = " + SqlHelper.SqlText("CodCarrinho") + " AND ty.name IN (" + SqlHelper.SqlText("varchar") + ", " + SqlHelper.SqlText("nvarchar") + ")) " +_
                "BEGIN " +_
                "UPDATE " + _item + " SET CodCarrinho = 1 WHERE CodCarrinho IS NULL; " +_
                "ALTER TABLE " + _item + " ALTER COLUMN CodCarrinho INTEGER NOT NULL; " +_
                "END"
            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub RenomearCodigoProdutoParaCodigoReferenciaFabricante(pSchema As String)
            Dim _tabela As String = IntegracaoSchema.TabelaCarrinhoItem()
            Dim _colunaAntiga As String = pSchema + "." + _tabela + ".CodigoProduto"
            Dim _sql As String = ""

            _sql = "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabela) + " " +_
                "AND c.name = " + SqlHelper.SqlText("CodigoProduto") + ") " +_
                "AND NOT EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabela) + " " +_
                "AND c.name = " + SqlHelper.SqlText("CodigoReferenciaFabricante") + ") " +_
                "EXEC sp_rename " + SqlHelper.SqlText(_colunaAntiga) + ", " + SqlHelper.SqlText("CodigoReferenciaFabricante") + ", " + SqlHelper.SqlText("COLUMN")

            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub AjustarEstruturaCarrinhoSemCodUsuario(pSchema As String)
            Dim _carrinho As String = IntegracaoSchema.TabelaCarrinhoQualificada()
            Dim _item As String = IntegracaoSchema.TabelaCarrinhoItemQualificada()
            Dim _tabelaCarrinho As String = IntegracaoSchema.TabelaCarrinho()
            Dim _tabelaItem As String = IntegracaoSchema.TabelaCarrinhoItem()
            Dim _sql As String = ""

            If _controller.ColumnExists(pSchema, _tabelaCarrinho, "CodUsuario") Then
                If _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuarioAncora") Then
                    _sql = "UPDATE i SET i.CodCarrinho = c.CodCarrinho " +_
                        "FROM " + _item + " i " +_
                        "INNER JOIN " + _carrinho + " c ON c.CodUsuario = i.CodUsuarioAncora"
                    _controller.ExecuteSql(_sql)
                ElseIf _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuario") Then
                    _sql = "UPDATE i SET i.CodCarrinho = c.CodCarrinho " +_
                        "FROM " + _item + " i " +_
                        "INNER JOIN " + _carrinho + " c ON c.CodUsuario = i.CodUsuario"
                    _controller.ExecuteSql(_sql)
                End If

                _sql = "SET ANSI_WARNINGS ON; " +_
                    "DECLARE @pkCarrinho NVARCHAR(200); " +_
                    "SELECT @pkCarrinho = kc.name " +_
                    "FROM sys.key_constraints kc " +_
                    "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                    "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                    "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaCarrinho) + " AND kc.type = " + SqlHelper.SqlText("PK") + "; " +_
                    "IF @pkCarrinho IS NOT NULL " +_
                    "BEGIN " +_
                    "DECLARE @sqlDropPkCarrinho NVARCHAR(MAX); " +_
                    "SET @sqlDropPkCarrinho = N'ALTER TABLE " + _carrinho + " DROP CONSTRAINT ' + QUOTENAME(@pkCarrinho); " +_
                    "EXEC sp_executesql @sqlDropPkCarrinho; " +_
                    "END; " +_
                    "UPDATE c SET c.CodCarrinho = n.NovoCod " +_
                    "FROM " + _carrinho + " c " +_
                    "INNER JOIN ( " +_
                    "    SELECT CodUsuario, CodCarrinho, ROW_NUMBER() OVER (ORDER BY CodUsuario) AS NovoCod " +_
                    "    FROM " + _carrinho + " " +_
                    ") n ON n.CodUsuario = c.CodUsuario AND n.CodCarrinho = c.CodCarrinho; " +_
                    "ALTER TABLE " + _carrinho + " DROP COLUMN CodUsuario"
                _controller.ExecuteSql(_sql)
            End If

            _sql = "IF NOT EXISTS (SELECT 1 FROM sys.key_constraints kc " +_
                "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id " +_
                "INNER JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaCarrinho) + " AND kc.type = " + SqlHelper.SqlText("PK") + " " +_
                "AND col.name = " + SqlHelper.SqlText("CodCarrinho") + ") " +_
                "BEGIN " +_
                "UPDATE " + _carrinho + " SET CodCarrinho = 1 WHERE CodCarrinho IS NULL OR CodCarrinho <= 0; " +_
                "ALTER TABLE " + _carrinho + " ADD CONSTRAINT PK_RedeAncoraCarrinho PRIMARY KEY (CodCarrinho); " +_
                "END"
            _controller.ExecuteSql(_sql)
        End Sub

        Private Function CodUsuarioFazParteDaPkCarrinhoItem(pSchema As String, pTabela As String) As Boolean
            Dim _sql As String = ""

            _sql = "SELECT 1 AS Qtd " +_
                "FROM sys.key_constraints kc " +_
                "INNER JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id " +_
                "INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id " +_
                "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " " +_
                "AND t.name = " + SqlHelper.SqlText(pTabela) + " " +_
                "AND kc.type = " + SqlHelper.SqlText("PK") + " " +_
                "AND c.name = " + SqlHelper.SqlText("CodUsuario")

            CodUsuarioFazParteDaPkCarrinhoItem = SqlHelper.ExecuteExists(_sql, "Failed to check PK column CodUsuario")
        End Function

        Private Sub GarantirPkCarrinhoItem(pSchema As String, pTabelaItem As String, pItemQualificada As String)
            Dim _sql As String = ""

            _sql = "IF NOT EXISTS (SELECT 1 FROM sys.key_constraints kc " +_
                "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(pTabelaItem) + " AND kc.type = " + SqlHelper.SqlText("PK") + ") " +_
                "ALTER TABLE " + pItemQualificada + " ADD CONSTRAINT PK_RedeAncoraCarrinhoItem PRIMARY KEY (CodCarrinho, Item)"
            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub RemoverCodUsuarioDoCarrinhoItem(pSchema As String)
            Dim _item As String = IntegracaoSchema.TabelaCarrinhoItemQualificada()
            Dim _tabelaItem As String = IntegracaoSchema.TabelaCarrinhoItem()
            Dim _sql As String = ""

            If Not _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuarioAncora") Then
                If Not me.CodUsuarioFazParteDaPkCarrinhoItem(pSchema, _tabelaItem) Then
                    me.GarantirPkCarrinhoItem(pSchema, _tabelaItem, _item)
                    Exit Sub
                End If
            End If

            _sql = "DECLARE @pkItem NVARCHAR(200); " +_
                "SELECT @pkItem = kc.name " +_
                "FROM sys.key_constraints kc " +_
                "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " AND kc.type = " + SqlHelper.SqlText("PK") + "; " +_
                "IF @pkItem IS NOT NULL " +_
                "BEGIN " +_
                "DECLARE @sqlDropPkItem NVARCHAR(MAX); " +_
                "SET @sqlDropPkItem = N'ALTER TABLE " + _item + " DROP CONSTRAINT ' + QUOTENAME(@pkItem); " +_
                "EXEC sp_executesql @sqlDropPkItem; " +_
                "END"
            _controller.ExecuteSql(_sql)

            _controller.DropColumnIfExists(pSchema, _tabelaItem, "CodUsuarioAncora")
            _controller.DropColumnIfExists(pSchema, _tabelaItem, "CodUsuario")

            me.GarantirPkCarrinhoItem(pSchema, _tabelaItem, _item)
        End Sub

        Private Sub LimparTabelaReordCarrinhoItemOrfa(pSchema As String)
            Dim _item As String = IntegracaoSchema.TabelaCarrinhoItemQualificada()
            Dim _tabelaItem As String = IntegracaoSchema.TabelaCarrinhoItem()
            Dim _itemReord As String = pSchema + "." + _tabelaItem + "_Reord"
            Dim _sql As String = ""

            _sql = "IF OBJECT_ID(" + SqlHelper.SqlText(_itemReord) + ", " + SqlHelper.SqlText("U") + ") IS NOT NULL " +_
                "AND OBJECT_ID(" + SqlHelper.SqlText(_item) + ", " + SqlHelper.SqlText("U") + ") IS NOT NULL " +_
                "DROP TABLE " + _itemReord

            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub ReordenarColunasCarrinhoItem(pSchema As String)
            Dim _item As String = IntegracaoSchema.TabelaCarrinhoItemQualificada()
            Dim _tabelaItem As String = IntegracaoSchema.TabelaCarrinhoItem()
            Dim _tabelaReord As String = _tabelaItem + "_Reord"
            Dim _itemReord As String = pSchema + "." + _tabelaReord
            Dim _selectAuditoria As String = ""
            Dim _sql As String = ""

            If _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuario") Then
                _selectAuditoria = "ISNULL(CodUsuario, 0), ISNULL(NomeUsuario, " + SqlHelper.SqlText("") + "), " +_
                    "CASE WHEN ISNULL(CodUsuario, 0) = 0 THEN CAST(" + SqlHelper.SqlText("1900-01-01") + " AS DATE) ELSE ISNULL(DataLancamento, CAST(" + SqlHelper.SqlText("1900-01-01") + " AS DATE)) END, " +_
                    "ISNULL(HoraLancamento, " + SqlHelper.SqlText("") + "), ISNULL(EstacaoTrabalho, " + SqlHelper.SqlText("") + ")"
            Else
                _selectAuditoria = "0, " + SqlHelper.SqlText("") + ", CAST(" + SqlHelper.SqlText("1900-01-01") + " AS DATE), " + SqlHelper.SqlText("") + ", " + SqlHelper.SqlText("")
            End If

            _sql = "SET ANSI_WARNINGS ON; " +_
                "IF EXISTS (SELECT 1 FROM sys.tables t " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + ") " +_
                "AND ( " +_
                "EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " " +_
                "AND c.column_id = 1 AND c.name <> " + SqlHelper.SqlText("CodCarrinho") + ") " +_
                "OR NOT EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " " +_
                "AND c.name = " + SqlHelper.SqlText("CodUsuario") + ") " +_
                ") " +_
                "BEGIN " +_
                "IF OBJECT_ID(" + SqlHelper.SqlText(_itemReord) + ", " + SqlHelper.SqlText("U") + ") IS NOT NULL DROP TABLE " + _itemReord + "; " +_
                "CREATE TABLE " + _itemReord + " ( " +_
                "CodCarrinho INTEGER NOT NULL, " +_
                "Item VARCHAR(5) NOT NULL, " +_
                "IdItemApi INTEGER NOT NULL, " +_
                "Cna INTEGER NOT NULL, " +_
                "CodCentroDistribuicao INTEGER NULL, " +_
                "CodCondicaoPagamento INTEGER NULL, " +_
                "DescricaoCondicaoPagamento VARCHAR(120) NULL, " +_
                "CodProduto INTEGER NULL, " +_
                "CodigoReferenciaFabricante VARCHAR(30) NULL, " +_
                "Descricao VARCHAR(255) NULL, " +_
                "CodModalidade INTEGER NULL, " +_
                "Quantidade INTEGER NOT NULL, " +_
                "PrecoUnitario DECIMAL(18,4) NULL, " +_
                "ImpostoUnitario DECIMAL(18,4) NULL, " +_
                "CodUsuario INTEGER NOT NULL, " +_
                "NomeUsuario VARCHAR(30) NOT NULL, " +_
                "DataLancamento DATE NOT NULL, " +_
                "HoraLancamento VARCHAR(8) NOT NULL, " +_
                "EstacaoTrabalho VARCHAR(50) NOT NULL, " +_
                "CONSTRAINT PK_RedeAncoraCarrinhoItem PRIMARY KEY (CodCarrinho, Item) " +_
                "); " +_
                "INSERT INTO " + _itemReord + " (CodCarrinho, Item, IdItemApi, Cna, CodCentroDistribuicao, CodCondicaoPagamento, DescricaoCondicaoPagamento, CodProduto, CodigoReferenciaFabricante, Descricao, CodModalidade, Quantidade, PrecoUnitario, ImpostoUnitario, CodUsuario, NomeUsuario, DataLancamento, HoraLancamento, EstacaoTrabalho) " +_
                "SELECT CodCarrinho, Item, IdItemApi, Cna, CodCentroDistribuicao, CodCondicaoPagamento, DescricaoCondicaoPagamento, CodProduto, CodigoReferenciaFabricante, Descricao, CodModalidade, Quantidade, PrecoUnitario, ImpostoUnitario, " + _selectAuditoria + " " +_
                "FROM " + _item + "; " +_
                "DECLARE @pkItem NVARCHAR(200); " +_
                "SELECT @pkItem = kc.name " +_
                "FROM sys.key_constraints kc " +_
                "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " AND kc.type = " + SqlHelper.SqlText("PK") + "; " +_
                "IF @pkItem IS NOT NULL " +_
                "BEGIN " +_
                "DECLARE @sqlDropPkItem NVARCHAR(MAX); " +_
                "SET @sqlDropPkItem = N'ALTER TABLE " + _item + " DROP CONSTRAINT ' + QUOTENAME(@pkItem); " +_
                "EXEC sp_executesql @sqlDropPkItem; " +_
                "END; " +_
                "DROP TABLE " + _item + "; " +_
                "EXEC sp_rename " + SqlHelper.SqlText(_itemReord) + ", " + SqlHelper.SqlText(_tabelaItem) + ", " + SqlHelper.SqlText("OBJECT") + "; " +_
                "END"

            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub CorrigirNomePkCarrinhoItemLegado(pSchema As String)
            Dim _item As String = IntegracaoSchema.TabelaCarrinhoItemQualificada()
            Dim _tabelaItem As String = IntegracaoSchema.TabelaCarrinhoItem()
            Dim _sql As String = ""

            _sql = "IF EXISTS (SELECT 1 FROM sys.key_constraints kc " +_
                "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " " +_
                "AND kc.type = " + SqlHelper.SqlText("PK") + " AND kc.name = " + SqlHelper.SqlText("PK_RedeAncoraCarrinhoItem_Reord") + ") " +_
                "AND NOT EXISTS (SELECT 1 FROM sys.key_constraints kc " +_
                "INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " " +_
                "AND kc.name = " + SqlHelper.SqlText("PK_RedeAncoraCarrinhoItem") + ") " +_
                "EXEC sp_rename " + SqlHelper.SqlText(pSchema + "." + _tabelaItem + ".PK_RedeAncoraCarrinhoItem_Reord") + ", " + SqlHelper.SqlText("PK_RedeAncoraCarrinhoItem") + ", " + SqlHelper.SqlText("INDEX")

            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub AjustarNullabilidadeAuditoriaCarrinhoItem(pSchema As String)
            Dim _item As String = IntegracaoSchema.TabelaCarrinhoItemQualificada()
            Dim _tabelaItem As String = IntegracaoSchema.TabelaCarrinhoItem()
            Dim _sql As String = ""

            If Not _controller.ColumnExists(pSchema, _tabelaItem, "CodUsuario") Then
                Exit Sub
            End If

            _sql = "SET ANSI_WARNINGS ON; " +_
                "IF EXISTS (SELECT 1 FROM sys.columns c " +_
                "INNER JOIN sys.tables t ON c.object_id = t.object_id " +_
                "INNER JOIN sys.schemas s ON t.schema_id = s.schema_id " +_
                "WHERE s.name = " + SqlHelper.SqlText(pSchema) + " AND t.name = " + SqlHelper.SqlText(_tabelaItem) + " " +_
                "AND c.name = " + SqlHelper.SqlText("CodUsuario") + " AND c.is_nullable = 1) " +_
                "BEGIN " +_
                "UPDATE " + _item + " SET CodUsuario = ISNULL(CodUsuario, 0), " +_
                "NomeUsuario = ISNULL(NomeUsuario, " + SqlHelper.SqlText("") + "), " +_
                "DataLancamento = CASE WHEN ISNULL(CodUsuario, 0) = 0 THEN CAST(" + SqlHelper.SqlText("1900-01-01") + " AS DATE) ELSE ISNULL(DataLancamento, CAST(" + SqlHelper.SqlText("1900-01-01") + " AS DATE)) END, " +_
                "HoraLancamento = ISNULL(HoraLancamento, " + SqlHelper.SqlText("") + "), " +_
                "EstacaoTrabalho = ISNULL(EstacaoTrabalho, " + SqlHelper.SqlText("") + "); " +_
                "ALTER TABLE " + _item + " ALTER COLUMN CodUsuario INTEGER NOT NULL; " +_
                "ALTER TABLE " + _item + " ALTER COLUMN NomeUsuario VARCHAR(30) NOT NULL; " +_
                "ALTER TABLE " + _item + " ALTER COLUMN DataLancamento DATE NOT NULL; " +_
                "ALTER TABLE " + _item + " ALTER COLUMN HoraLancamento VARCHAR(8) NOT NULL; " +_
                "ALTER TABLE " + _item + " ALTER COLUMN EstacaoTrabalho VARCHAR(50) NOT NULL; " +_
                "END"

            _controller.ExecuteSql(_sql)
        End Sub

        Private Sub AtualizarColunasAuditoriaCarrinhoItem(pSchema As String)
            ' CodUsuario aqui e auditoria de lancamento ERP (distinto da coluna legada removida em RemoverCodUsuarioDoCarrinhoItem).
            Dim _tabela As String = IntegracaoSchema.TabelaCarrinhoItem()

            _controller.CreateColumn(pSchema, _tabela, "CodUsuario", "INTEGER")
            _controller.CreateColumn(pSchema, _tabela, "NomeUsuario", "VARCHAR(30)")
            _controller.CreateColumn(pSchema, _tabela, "DataLancamento", "DATE")
            _controller.CreateColumn(pSchema, _tabela, "HoraLancamento", "VARCHAR(8)")
            _controller.CreateColumn(pSchema, _tabela, "EstacaoTrabalho", "VARCHAR(50)")
        End Sub

        Private Sub CriarTabelaPedido(pSchema As String)
            Dim _columns As MigrationColumns = Null
            Dim _table As MigrationTable = Null
            Dim _tabela As String = IntegracaoSchema.TabelaPedido()

            _columns = New MigrationColumns()
            _columns.Add(New MigrationColumn(_tabela, "CodUsuario", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "IdPedidoApi", "INTEGER", False, True, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "IdCarrinho", "VARCHAR(36)", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "DataPedido", "DATETIME", True, False, pSchema))
            _columns.Add(New MigrationColumn(_tabela, "ValorTotal", "DECIMAL(18,2)", True, False, pSchema))
            _table = New MigrationTable(_tabela, _columns, pSchema)
            _controller.CreateTable(_table)
            _table.Free()
            _columns.Free()
        End Sub

        Sub Free()
            If Assigned(_controller) Then
                _controller.Free()
                _controller = Null
            End If
            MyBase.Free()
        End Sub
    End Class
End Namespace
