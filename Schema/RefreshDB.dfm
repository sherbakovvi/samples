object RefreshDM: TRefreshDM
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 653
  Width = 1093
  object SourceDB: TpFIBDatabase
    DBName = 
      'C:\Program Files\Firebird\Firebird_2_5\examples\empbuild\EMPLOYE' +
      'E.FDB'
    DBParams.Strings = (
      'user_name=SYSDBA'
      'password=masterkey')
    DefaultTransaction = SourceTransaction
    SQLDialect = 3
    Timeout = 0
    WaitForRestoreConnect = 0
    Left = 48
    Top = 8
  end
  object TargetDB: TpFIBDatabase
    DBName = 
      'C:\Program Files\Firebird\Firebird_2_5\examples\empbuild\EMPLOYE' +
      'E.FDB'
    DBParams.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      '')
    DefaultTransaction = TargetTransaction
    SQLDialect = 3
    Timeout = 0
    WaitForRestoreConnect = 0
    Left = 120
    Top = 8
  end
  object SourceTables: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'rdb$relation_name;rdb$field_position;rdb$field_name'
    Params = <>
    ProviderName = 'SourceTablesProvider'
    Left = 48
    Top = 144
    object SourceTablesRDBRELATION_NAME: TWideStringField
      FieldName = 'RDB$RELATION_NAME'
      Size = 31
    end
    object SourceTablesRDBFIELD_SOURCE: TWideStringField
      FieldName = 'RDB$FIELD_SOURCE'
      Size = 31
    end
    object SourceTablesRDBFIELD_POSITION: TSmallintField
      FieldName = 'RDB$FIELD_POSITION'
    end
    object SourceTablesRDBFIELD_NAME: TWideStringField
      FieldName = 'RDB$FIELD_NAME'
      Size = 31
    end
    object SourceTablesRDBFIELD_TYPE: TSmallintField
      FieldName = 'RDB$FIELD_TYPE'
    end
    object SourceTablesRDBFIELD_SUB_TYPE: TSmallintField
      FieldName = 'RDB$FIELD_SUB_TYPE'
    end
    object SourceTablesRDBNULL_FLAG: TSmallintField
      FieldName = 'RDB$NULL_FLAG'
    end
    object SourceTablesRDBFIELD_LENGTH: TSmallintField
      FieldName = 'RDB$FIELD_LENGTH'
    end
    object SourceTablesRDBFIELD_SCALE: TSmallintField
      FieldName = 'RDB$FIELD_SCALE'
    end
    object SourceTablesRDBCHARACTER_LENGTH: TSmallintField
      FieldName = 'RDB$CHARACTER_LENGTH'
    end
    object SourceTablesRDBFIELD_PRECISION: TSmallintField
      FieldName = 'RDB$FIELD_PRECISION'
    end
    object SourceTablesRDBDEFAULT_SOURCE: TMemoField
      FieldName = 'RDB$DEFAULT_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object SourceTablesRDBVALIDATION_SOURCE: TMemoField
      FieldName = 'RDB$VALIDATION_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object SourceTablesRDBCOMPUTED_SOURCE: TMemoField
      FieldName = 'RDB$COMPUTED_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object SourceTablesRDBCOLLATION_ID: TSmallintField
      FieldName = 'RDB$COLLATION_ID'
    end
    object SourceTablesRDBCHARACTER_SET_ID: TSmallintField
      FieldName = 'RDB$CHARACTER_SET_ID'
    end
    object SourceTablesRDBSEGMENT_LENGTH: TSmallintField
      FieldName = 'RDB$SEGMENT_LENGTH'
    end
    object SourceTablesRDBDESCRIPTION: TMemoField
      FieldName = 'RDB$DESCRIPTION'
      BlobType = ftMemo
      Size = 8
    end
  end
  object TargetTables: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'rdb$relation_name;rdb$field_position;rdb$field_name'
    Params = <>
    ProviderName = 'TargetTablesProvider'
    Left = 208
    Top = 144
    object TargetTablesRDBRELATION_NAME: TWideStringField
      FieldName = 'RDB$RELATION_NAME'
      Size = 31
    end
    object TargetTablesRDBFIELD_SOURCE: TWideStringField
      FieldName = 'RDB$FIELD_SOURCE'
      Size = 31
    end
    object TargetTablesRDBFIELD_POSITION: TSmallintField
      FieldName = 'RDB$FIELD_POSITION'
    end
    object TargetTablesRDBFIELD_NAME: TWideStringField
      FieldName = 'RDB$FIELD_NAME'
      Size = 31
    end
    object TargetTablesRDBFIELD_TYPE: TSmallintField
      FieldName = 'RDB$FIELD_TYPE'
    end
    object TargetTablesRDBFIELD_SUB_TYPE: TSmallintField
      FieldName = 'RDB$FIELD_SUB_TYPE'
    end
    object TargetTablesRDBNULL_FLAG: TSmallintField
      FieldName = 'RDB$NULL_FLAG'
    end
    object TargetTablesRDBFIELD_LENGTH: TSmallintField
      FieldName = 'RDB$FIELD_LENGTH'
    end
    object TargetTablesRDBFIELD_SCALE: TSmallintField
      FieldName = 'RDB$FIELD_SCALE'
    end
    object TargetTablesRDBCHARACTER_LENGTH: TSmallintField
      FieldName = 'RDB$CHARACTER_LENGTH'
    end
    object TargetTablesRDBFIELD_PRECISION: TSmallintField
      FieldName = 'RDB$FIELD_PRECISION'
    end
    object TargetTablesRDBDEFAULT_SOURCE: TMemoField
      FieldName = 'RDB$DEFAULT_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object TargetTablesRDBVALIDATION_SOURCE: TMemoField
      FieldName = 'RDB$VALIDATION_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object TargetTablesRDBCOMPUTED_SOURCE: TMemoField
      FieldName = 'RDB$COMPUTED_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object TargetTablesRDBCOLLATION_ID: TSmallintField
      FieldName = 'RDB$COLLATION_ID'
    end
    object TargetTablesRDBCHARACTER_SET_ID: TSmallintField
      FieldName = 'RDB$CHARACTER_SET_ID'
    end
    object TargetTablesRDBSEGMENT_LENGTH: TSmallintField
      FieldName = 'RDB$SEGMENT_LENGTH'
    end
    object TargetTablesRDBDESCRIPTION: TMemoField
      FieldName = 'RDB$DESCRIPTION'
      BlobType = ftMemo
      Size = 8
    end
  end
  object Scripter: TpFIBScripter
    Database = TargetDB
    Transaction = TargetTransaction
    OnExecuteError = ScripterExecuteError
    Left = 336
    Top = 8
  end
  object SourceTransaction: TpFIBTransaction
    DefaultDatabase = SourceDB
    TimeoutAction = TARollback
    MDTTransactionRole = mtrAutoDefine
    Left = 192
    Top = 8
  end
  object TargetTransaction: TpFIBTransaction
    DefaultDatabase = TargetDB
    TimeoutAction = TARollback
    MDTTransactionRole = mtrAutoDefine
    Left = 264
    Top = 8
  end
  object SourceTablesDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT rel.rdb$relation_name, rel_field.rdb$field_source, rel_fi' +
        'eld.rdb$field_position,'
      '    rel_field.rdb$description,'
      
        '    rel_field.rdb$field_name, field.rdb$field_type, field.rdb$fi' +
        'eld_sub_type,'
      
        '    rel_field.rdb$null_flag, field.rdb$field_length, field.rdb$f' +
        'ield_scale,'
      '    field.rdb$character_length, field.rdb$field_precision,'
      
        '    field.rdb$default_source, field.rdb$validation_source, field' +
        '.rdb$computed_source,'
      
        '    field.rdb$collation_id, field.rdb$character_set_id, field.rd' +
        'b$segment_length'
      '  FROM rdb$relations rel'
      '    JOIN rdb$relation_fields rel_field'
      '      ON rel_field.rdb$relation_name = rel.rdb$relation_name'
      '    JOIN rdb$fields field'
      '      ON rel_field.rdb$field_source = field.rdb$field_name'
      
        '  WHERE ((rel.rdb$system_flag = 0) OR (rel.rdb$system_flag IS NU' +
        'LL)) AND (rel.rdb$view_source IS NULL)'
      '')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 48
    Top = 56
  end
  object TargetTablesDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT rel.rdb$relation_name, rel_field.rdb$field_source, rel_fi' +
        'eld.rdb$field_position,'
      '    rel_field.rdb$description,'
      
        '    rel_field.rdb$field_name, field.rdb$field_type, field.rdb$fi' +
        'eld_sub_type,'
      
        '    rel_field.rdb$null_flag, field.rdb$field_length, field.rdb$f' +
        'ield_scale,'
      '    field.rdb$character_length, field.rdb$field_precision,'
      
        '    field.rdb$default_source, field.rdb$validation_source, field' +
        '.rdb$computed_source,'
      
        '    field.rdb$collation_id, field.rdb$character_set_id, field.rd' +
        'b$segment_length'
      '  FROM rdb$relations rel'
      '    JOIN rdb$relation_fields rel_field'
      '      ON rel_field.rdb$relation_name = rel.rdb$relation_name'
      '    JOIN rdb$fields field'
      '      ON rel_field.rdb$field_source = field.rdb$field_name'
      
        '  WHERE ((rel.rdb$system_flag = 0) OR (rel.rdb$system_flag IS NU' +
        'LL)) AND (rel.rdb$view_source IS NULL)'
      '')
    Transaction = TargetTransaction
    Database = TargetDB
    Left = 208
    Top = 56
  end
  object TargetDimenProvider: TpFIBDataSetProvider
    DataSet = TargetDimenDataSet
    Left = 216
    Top = 280
  end
  object TargetDimen: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$FIELD_NAME;RDB$DIMENSION'
    Params = <>
    ProviderName = 'TargetDimenProvider'
    Left = 216
    Top = 328
    object TargetDimenRDBFIELD_NAME: TWideStringField
      FieldName = 'RDB$FIELD_NAME'
      Size = 31
    end
    object TargetDimenRDBDIMENSION: TSmallintField
      FieldName = 'RDB$DIMENSION'
    end
    object TargetDimenRDBLOWER_BOUND: TIntegerField
      FieldName = 'RDB$LOWER_BOUND'
    end
    object TargetDimenRDBUPPER_BOUND: TIntegerField
      FieldName = 'RDB$UPPER_BOUND'
    end
  end
  object SourceDimen: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$FIELD_NAME;RDB$DIMENSION'
    Params = <>
    ProviderName = 'SourceDimenProvider'
    Left = 48
    Top = 328
    object SourceDimenRDBFIELD_NAME: TWideStringField
      FieldName = 'RDB$FIELD_NAME'
      Size = 31
    end
    object SourceDimenRDBDIMENSION: TSmallintField
      FieldName = 'RDB$DIMENSION'
    end
    object SourceDimenRDBLOWER_BOUND: TIntegerField
      FieldName = 'RDB$LOWER_BOUND'
    end
    object SourceDimenRDBUPPER_BOUND: TIntegerField
      FieldName = 'RDB$UPPER_BOUND'
    end
  end
  object SourceDimenProvider: TpFIBDataSetProvider
    DataSet = SourceDimenDataSet
    Left = 48
    Top = 280
  end
  object SourceDimenDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      'select * from RDB$FIELD_DIMENSIONS')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 48
    Top = 232
  end
  object TargetDimenDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      'select * from RDB$FIELD_DIMENSIONS')
    Transaction = TargetTransaction
    Database = TargetDB
    Left = 216
    Top = 232
  end
  object SourceDomainDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      'select rdb$field_name, rdb$field_type, rdb$field_sub_type,'
      '    rdb$null_flag, rdb$field_length, rdb$field_scale,'
      '    rdb$character_length, rdb$field_precision,'
      
        '    rdb$default_source, rdb$validation_source from rdb$fields wh' +
        'ere rdb$field_name not like '#39'RDB$%'#39
      '')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 48
    Top = 400
  end
  object SourceDomainProvider: TpFIBDataSetProvider
    DataSet = SourceDomainDataSet
    Left = 48
    Top = 456
  end
  object SourceDomain: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$FIELD_NAME'
    Params = <>
    ProviderName = 'SourceDomainProvider'
    Left = 48
    Top = 512
    object SourceDomainRDBFIELD_NAME: TWideStringField
      FieldName = 'RDB$FIELD_NAME'
      Size = 31
    end
    object SourceDomainRDBFIELD_TYPE: TSmallintField
      FieldName = 'RDB$FIELD_TYPE'
    end
    object SourceDomainRDBFIELD_SUB_TYPE: TSmallintField
      FieldName = 'RDB$FIELD_SUB_TYPE'
    end
    object SourceDomainRDBNULL_FLAG: TSmallintField
      FieldName = 'RDB$NULL_FLAG'
    end
    object SourceDomainRDBFIELD_LENGTH: TSmallintField
      FieldName = 'RDB$FIELD_LENGTH'
    end
    object SourceDomainRDBFIELD_SCALE: TSmallintField
      FieldName = 'RDB$FIELD_SCALE'
    end
    object SourceDomainRDBCHARACTER_LENGTH: TSmallintField
      FieldName = 'RDB$CHARACTER_LENGTH'
    end
    object SourceDomainRDBFIELD_PRECISION: TSmallintField
      FieldName = 'RDB$FIELD_PRECISION'
    end
    object SourceDomainRDBDEFAULT_SOURCE: TMemoField
      FieldName = 'RDB$DEFAULT_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object SourceDomainRDBVALIDATION_SOURCE: TMemoField
      FieldName = 'RDB$VALIDATION_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
  end
  object TargetDomainDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      'select rdb$field_name, rdb$field_type, rdb$field_sub_type,'
      '    rdb$null_flag, rdb$field_length, rdb$field_scale,'
      '    rdb$character_length, rdb$field_precision,'
      
        '    rdb$default_source, rdb$validation_source from rdb$fields wh' +
        'ere rdb$field_name not like '#39'RDB$%'#39
      '')
    Transaction = TargetTransaction
    Database = TargetDB
    Left = 216
    Top = 400
  end
  object TargetDomainProvider: TpFIBDataSetProvider
    DataSet = TargetDomainDataSet
    Left = 216
    Top = 456
  end
  object TargetDomain: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$FIELD_NAME'
    Params = <>
    ProviderName = 'TargetDomainProvider'
    Left = 216
    Top = 512
    object TargetDomainRDBFIELD_NAME: TWideStringField
      FieldName = 'RDB$FIELD_NAME'
      Size = 31
    end
    object TargetDomainRDBFIELD_TYPE: TSmallintField
      FieldName = 'RDB$FIELD_TYPE'
    end
    object TargetDomainRDBFIELD_SUB_TYPE: TSmallintField
      FieldName = 'RDB$FIELD_SUB_TYPE'
    end
    object TargetDomainRDBNULL_FLAG: TSmallintField
      FieldName = 'RDB$NULL_FLAG'
    end
    object TargetDomainRDBFIELD_LENGTH: TSmallintField
      FieldName = 'RDB$FIELD_LENGTH'
    end
    object TargetDomainRDBFIELD_SCALE: TSmallintField
      FieldName = 'RDB$FIELD_SCALE'
    end
    object TargetDomainRDBCHARACTER_LENGTH: TSmallintField
      FieldName = 'RDB$CHARACTER_LENGTH'
    end
    object TargetDomainRDBFIELD_PRECISION: TSmallintField
      FieldName = 'RDB$FIELD_PRECISION'
    end
    object TargetDomainRDBDEFAULT_SOURCE: TMemoField
      FieldName = 'RDB$DEFAULT_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object TargetDomainRDBVALIDATION_SOURCE: TMemoField
      FieldName = 'RDB$VALIDATION_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
  end
  object CharSet: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$CHARACTER_SET_ID'
    Params = <>
    ProviderName = 'CharSetProvider'
    Left = 408
    Top = 144
    object CharSetRDBCHARACTER_SET_NAME: TWideStringField
      FieldName = 'RDB$CHARACTER_SET_NAME'
      Size = 31
    end
    object CharSetRDBCHARACTER_SET_ID: TSmallintField
      FieldName = 'RDB$CHARACTER_SET_ID'
    end
  end
  object CharSetDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'select rdb$character_set_name, rdb$character_set_id from rdb$cha' +
        'racter_sets')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 408
    Top = 56
  end
  object Collation: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$COLLATION_ID'
    Params = <>
    ProviderName = 'CollationProvider'
    Left = 536
    Top = 144
    object CollationRDBCOLLATION_NAME: TWideStringField
      FieldName = 'RDB$COLLATION_NAME'
      Size = 31
    end
    object CollationRDBCOLLATION_ID: TSmallintField
      FieldName = 'RDB$COLLATION_ID'
    end
  end
  object CollationDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      'select rdb$collation_name, rdb$collation_id from rdb$collations')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 536
    Top = 56
  end
  object SourceTablesProvider: TpFIBDataSetProvider
    DataSet = SourceTablesDataSet
    Left = 48
    Top = 104
  end
  object TargetTablesProvider: TpFIBDataSetProvider
    DataSet = TargetTablesDataSet
    Left = 208
    Top = 104
  end
  object CharSetProvider: TpFIBDataSetProvider
    DataSet = CharSetDataSet
    Left = 408
    Top = 104
  end
  object CollationProvider: TpFIBDataSetProvider
    DataSet = CollationDataSet
    Left = 536
    Top = 104
  end
  object SourceIndexDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      'SELECT RDB$INDICES.RDB$INDEX_NAME,'
      '       RDB$INDICES.RDB$RELATION_NAME,'
      '       RDB$INDICES.RDB$UNIQUE_FLAG,'
      '       RDB$INDICES.RDB$INDEX_INACTIVE,'
      '       RDB$INDICES.RDB$INDEX_TYPE,'
      '       RDB$INDEX_SEGMENTS.RDB$FIELD_NAME,'
      '       RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION'
      'FROM RDB$INDICES'
      '   INNER JOIN RDB$INDEX_SEGMENTS ON'
      
        '      (RDB$INDICES.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX' +
        '_NAME)'
      'WHERE'
      '   NOT (RDB$INDICES.RDB$INDEX_NAME STARTING WITH '#39'RDB$'#39')')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 400
    Top = 232
  end
  object TargetIndexDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      'SELECT RDB$INDICES.RDB$INDEX_NAME,'
      '       RDB$INDICES.RDB$RELATION_NAME,'
      '       RDB$INDICES.RDB$UNIQUE_FLAG,'
      '       RDB$INDICES.RDB$INDEX_INACTIVE,'
      '       RDB$INDICES.RDB$INDEX_TYPE,'
      '       RDB$INDEX_SEGMENTS.RDB$FIELD_NAME,'
      '       RDB$INDEX_SEGMENTS.RDB$FIELD_POSITION'
      'FROM RDB$INDICES'
      '   INNER JOIN RDB$INDEX_SEGMENTS ON'
      
        '      (RDB$INDICES.RDB$INDEX_NAME = RDB$INDEX_SEGMENTS.RDB$INDEX' +
        '_NAME)'
      'WHERE'
      '   NOT (RDB$INDICES.RDB$INDEX_NAME STARTING WITH '#39'RDB$'#39')'
      '')
    Transaction = TargetTransaction
    Database = TargetDB
    Left = 536
    Top = 232
  end
  object SourceIndexProvider: TpFIBDataSetProvider
    DataSet = SourceIndexDataSet
    Left = 400
    Top = 288
  end
  object TargetIndexProvider: TpFIBDataSetProvider
    DataSet = TargetIndexDataSet
    Left = 536
    Top = 288
  end
  object SourceIndex: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$RELATION_NAME;RDB$INDEX_NAME;RDB$FIELD_POSITION'
    Params = <>
    ProviderName = 'SourceIndexProvider'
    Left = 400
    Top = 336
    object SourceIndexRDBINDEX_NAME: TWideStringField
      FieldName = 'RDB$INDEX_NAME'
      Size = 31
    end
    object SourceIndexRDBRELATION_NAME: TWideStringField
      FieldName = 'RDB$RELATION_NAME'
      Size = 31
    end
    object SourceIndexRDBUNIQUE_FLAG: TSmallintField
      FieldName = 'RDB$UNIQUE_FLAG'
    end
    object SourceIndexRDBINDEX_INACTIVE: TSmallintField
      FieldName = 'RDB$INDEX_INACTIVE'
    end
    object SourceIndexRDBINDEX_TYPE: TSmallintField
      FieldName = 'RDB$INDEX_TYPE'
    end
    object SourceIndexRDBFIELD_NAME: TWideStringField
      FieldName = 'RDB$FIELD_NAME'
      Size = 31
    end
    object SourceIndexRDBFIELD_POSITION: TSmallintField
      FieldName = 'RDB$FIELD_POSITION'
    end
  end
  object TargetIndex: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$RELATION_NAME;RDB$INDEX_NAME;RDB$FIELD_POSITION'
    Params = <>
    ProviderName = 'TargetIndexProvider'
    Left = 536
    Top = 336
    object TargetIndexRDBINDEX_NAME: TWideStringField
      FieldName = 'RDB$INDEX_NAME'
      Size = 31
    end
    object TargetIndexRDBRELATION_NAME: TWideStringField
      FieldName = 'RDB$RELATION_NAME'
      Size = 31
    end
    object TargetIndexRDBUNIQUE_FLAG: TSmallintField
      FieldName = 'RDB$UNIQUE_FLAG'
    end
    object TargetIndexRDBINDEX_INACTIVE: TSmallintField
      FieldName = 'RDB$INDEX_INACTIVE'
    end
    object TargetIndexRDBINDEX_TYPE: TSmallintField
      FieldName = 'RDB$INDEX_TYPE'
    end
    object TargetIndexRDBFIELD_NAME: TWideStringField
      FieldName = 'RDB$FIELD_NAME'
      Size = 31
    end
    object TargetIndexRDBFIELD_POSITION: TSmallintField
      FieldName = 'RDB$FIELD_POSITION'
    end
  end
  object SourceGenDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT RDB$GENERATOR_NAME FROM RDB$GENERATORS WHERE RDB$SYSTEM_F' +
        'LAG = 0')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 400
    Top = 408
  end
  object SourceGenProvider: TpFIBDataSetProvider
    DataSet = SourceGenDataSet
    Left = 400
    Top = 464
  end
  object SourceGen: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$GENERATOR_NAME'
    Params = <>
    ProviderName = 'SourceGenProvider'
    Left = 400
    Top = 520
    object SourceGenRDBGENERATOR_NAME: TWideStringField
      FieldName = 'RDB$GENERATOR_NAME'
      Size = 31
    end
  end
  object TargetGenDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT a.RDB$GENERATOR_NAME FROM RDB$GENERATORS a WHERE a.RDB$SY' +
        'STEM_FLAG = 0')
    Transaction = TargetTransaction
    Database = TargetDB
    Left = 536
    Top = 408
  end
  object TargetGenProvider: TpFIBDataSetProvider
    DataSet = TargetGenDataSet
    Left = 536
    Top = 464
  end
  object TargetGen: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$GENERATOR_NAME'
    Params = <>
    ProviderName = 'TargetGenProvider'
    Left = 536
    Top = 520
    object TargetGenRDBGENERATOR_NAME: TWideStringField
      FieldName = 'RDB$GENERATOR_NAME'
      Size = 31
    end
  end
  object SourceTrigDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT RDB$TRIGGER_NAME, RDB$RELATION_NAME, RDB$TRIGGER_SEQUENCE' +
        ', RDB$TRIGGER_TYPE, RDB$TRIGGER_SOURCE, RDB$TRIGGER_INACTIVE, RD' +
        'B$SYSTEM_FLAG, RDB$FLAGS'
      ' FROM RDB$TRIGGERS WHERE RDB$SYSTEM_FLAG = 0'
      '')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 648
    Top = 56
  end
  object TargetTriigDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT RDB$TRIGGER_NAME, RDB$RELATION_NAME, RDB$TRIGGER_SEQUENCE' +
        ', RDB$TRIGGER_TYPE, RDB$TRIGGER_SOURCE, RDB$TRIGGER_INACTIVE, RD' +
        'B$SYSTEM_FLAG, RDB$FLAGS'
      ' FROM RDB$TRIGGERS WHERE RDB$SYSTEM_FLAG = 0'
      '')
    Transaction = TargetTransaction
    Database = TargetDB
    Left = 744
    Top = 56
  end
  object SourceTrigProvider: TpFIBDataSetProvider
    DataSet = SourceTrigDataSet
    Left = 648
    Top = 104
  end
  object TargetTrigProvider: TpFIBDataSetProvider
    DataSet = TargetTriigDataSet
    Left = 744
    Top = 104
  end
  object TargetTrig: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$TRIGGER_NAME'
    Params = <>
    ProviderName = 'TargetTrigProvider'
    Left = 744
    Top = 144
    object TargetTrigRDBTRIGGER_NAME: TWideStringField
      FieldName = 'RDB$TRIGGER_NAME'
      Size = 31
    end
    object TargetTrigRDBRELATION_NAME: TWideStringField
      FieldName = 'RDB$RELATION_NAME'
      Size = 31
    end
    object TargetTrigRDBTRIGGER_SEQUENCE: TSmallintField
      FieldName = 'RDB$TRIGGER_SEQUENCE'
    end
    object TargetTrigRDBTRIGGER_TYPE: TSmallintField
      FieldName = 'RDB$TRIGGER_TYPE'
    end
    object TargetTrigRDBTRIGGER_SOURCE: TMemoField
      FieldName = 'RDB$TRIGGER_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object TargetTrigRDBTRIGGER_INACTIVE: TSmallintField
      FieldName = 'RDB$TRIGGER_INACTIVE'
    end
    object TargetTrigRDBSYSTEM_FLAG: TSmallintField
      FieldName = 'RDB$SYSTEM_FLAG'
    end
    object TargetTrigRDBFLAGS: TSmallintField
      FieldName = 'RDB$FLAGS'
    end
  end
  object SourceTrig: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$TRIGGER_NAME'
    Params = <>
    ProviderName = 'SourceTrigProvider'
    Left = 648
    Top = 144
    object SourceTrigRDBTRIGGER_NAME: TWideStringField
      FieldName = 'RDB$TRIGGER_NAME'
      Size = 31
    end
    object SourceTrigRDBRELATION_NAME: TWideStringField
      FieldName = 'RDB$RELATION_NAME'
      Size = 31
    end
    object SourceTrigRDBTRIGGER_SEQUENCE: TSmallintField
      FieldName = 'RDB$TRIGGER_SEQUENCE'
    end
    object SourceTrigRDBTRIGGER_TYPE: TSmallintField
      FieldName = 'RDB$TRIGGER_TYPE'
    end
    object SourceTrigRDBTRIGGER_SOURCE: TMemoField
      FieldName = 'RDB$TRIGGER_SOURCE'
      BlobType = ftMemo
      Size = 8
    end
    object SourceTrigRDBTRIGGER_INACTIVE: TSmallintField
      FieldName = 'RDB$TRIGGER_INACTIVE'
    end
    object SourceTrigRDBSYSTEM_FLAG: TSmallintField
      FieldName = 'RDB$SYSTEM_FLAG'
    end
    object SourceTrigRDBFLAGS: TSmallintField
      FieldName = 'RDB$FLAGS'
    end
  end
  object SourceRefCnstDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT RDB$CONSTRAINT_NAME, RDB$CONST_NAME_UQ, RDB$MATCH_OPTION,' +
        ' RDB$UPDATE_RULE, RDB$DELETE_RULE'
      'FROM RDB$REF_CONSTRAINTS')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 648
    Top = 232
  end
  object TargetRefCnstDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT RDB$CONSTRAINT_NAME, RDB$CONST_NAME_UQ, RDB$MATCH_OPTION,' +
        ' RDB$UPDATE_RULE, RDB$DELETE_RULE'
      'FROM RDB$REF_CONSTRAINTS')
    Transaction = TargetTransaction
    Database = TargetDB
    Left = 744
    Top = 232
  end
  object SourceRefCnstProvider: TpFIBDataSetProvider
    DataSet = SourceRefCnstDataSet
    Left = 648
    Top = 288
  end
  object TargetRefCnstProvider: TpFIBDataSetProvider
    DataSet = TargetRefCnstDataSet
    Left = 744
    Top = 288
  end
  object SourceRefCnst: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$CONSTRAINT_NAME'
    Params = <>
    ProviderName = 'SourceRefCnstProvider'
    Left = 648
    Top = 336
    object SourceRefCnstRDBCONSTRAINT_NAME: TWideStringField
      FieldName = 'RDB$CONSTRAINT_NAME'
      Size = 31
    end
    object SourceRefCnstRDBCONST_NAME_UQ: TWideStringField
      FieldName = 'RDB$CONST_NAME_UQ'
      Size = 31
    end
    object SourceRefCnstRDBMATCH_OPTION: TStringField
      FieldName = 'RDB$MATCH_OPTION'
      Size = 7
    end
    object SourceRefCnstRDBUPDATE_RULE: TStringField
      FieldName = 'RDB$UPDATE_RULE'
      Size = 11
    end
    object SourceRefCnstRDBDELETE_RULE: TStringField
      FieldName = 'RDB$DELETE_RULE'
      Size = 11
    end
  end
  object TargetRefCnst: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$CONSTRAINT_NAME'
    Params = <>
    ProviderName = 'TargetRefCnstProvider'
    Left = 744
    Top = 336
    object TargetRefCnstRDBCONSTRAINT_NAME: TWideStringField
      FieldName = 'RDB$CONSTRAINT_NAME'
      Size = 31
    end
    object TargetRefCnstRDBCONST_NAME_UQ: TWideStringField
      FieldName = 'RDB$CONST_NAME_UQ'
      Size = 31
    end
    object TargetRefCnstRDBMATCH_OPTION: TStringField
      FieldName = 'RDB$MATCH_OPTION'
      Size = 7
    end
    object TargetRefCnstRDBUPDATE_RULE: TStringField
      FieldName = 'RDB$UPDATE_RULE'
      Size = 11
    end
    object TargetRefCnstRDBDELETE_RULE: TStringField
      FieldName = 'RDB$DELETE_RULE'
      Size = 11
    end
  end
  object SourceRelCnstDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT RDB$CONSTRAINT_NAME, RDB$CONSTRAINT_TYPE, RDB$RELATION_NA' +
        'ME, RDB$DEFERRABLE, RDB$INITIALLY_DEFERRED, RDB$INDEX_NAME'
      'FROM RDB$RELATION_CONSTRAINTS')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 648
    Top = 408
  end
  object TargetRelCnstDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT RDB$CONSTRAINT_NAME, RDB$CONSTRAINT_TYPE, RDB$RELATION_NA' +
        'ME, RDB$DEFERRABLE, RDB$INITIALLY_DEFERRED, RDB$INDEX_NAME'
      'FROM RDB$RELATION_CONSTRAINTS'
      '')
    Transaction = TargetTransaction
    Database = TargetDB
    Left = 744
    Top = 408
  end
  object SourceRelCnstProvider: TpFIBDataSetProvider
    DataSet = SourceRelCnstDataSet
    Left = 648
    Top = 464
  end
  object TargetRelCnstProvider: TpFIBDataSetProvider
    DataSet = TargetRelCnstDataSet
    Left = 744
    Top = 464
  end
  object SourceRelCnst: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$RELATION_NAME;RDB$CONSTRAINT_NAME'
    Params = <>
    ProviderName = 'SourceRelCnstProvider'
    Left = 648
    Top = 520
    object SourceRelCnstRDBCONSTRAINT_NAME: TWideStringField
      FieldName = 'RDB$CONSTRAINT_NAME'
      Size = 31
    end
    object SourceRelCnstRDBCONSTRAINT_TYPE: TStringField
      FieldName = 'RDB$CONSTRAINT_TYPE'
      Size = 11
    end
    object SourceRelCnstRDBRELATION_NAME: TWideStringField
      FieldName = 'RDB$RELATION_NAME'
      Size = 31
    end
    object SourceRelCnstRDBDEFERRABLE: TStringField
      FieldName = 'RDB$DEFERRABLE'
      Size = 3
    end
    object SourceRelCnstRDBINITIALLY_DEFERRED: TStringField
      FieldName = 'RDB$INITIALLY_DEFERRED'
      Size = 3
    end
    object SourceRelCnstRDBINDEX_NAME: TWideStringField
      FieldName = 'RDB$INDEX_NAME'
      Size = 31
    end
  end
  object TargetRelCnst: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$RELATION_NAME;RDB$CONSTRAINT_NAME'
    Params = <>
    ProviderName = 'TargetRelCnstProvider'
    Left = 744
    Top = 520
    object TargetRelCnstRDBCONSTRAINT_NAME: TWideStringField
      FieldName = 'RDB$CONSTRAINT_NAME'
      Size = 31
    end
    object TargetRelCnstRDBCONSTRAINT_TYPE: TStringField
      FieldName = 'RDB$CONSTRAINT_TYPE'
      Size = 11
    end
    object TargetRelCnstRDBRELATION_NAME: TWideStringField
      FieldName = 'RDB$RELATION_NAME'
      Size = 31
    end
    object TargetRelCnstRDBDEFERRABLE: TStringField
      FieldName = 'RDB$DEFERRABLE'
      Size = 3
    end
    object TargetRelCnstRDBINITIALLY_DEFERRED: TStringField
      FieldName = 'RDB$INITIALLY_DEFERRED'
      Size = 3
    end
    object TargetRelCnstRDBINDEX_NAME: TWideStringField
      FieldName = 'RDB$INDEX_NAME'
      Size = 31
    end
  end
  object SourceCheckCnstDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT RDB$CONSTRAINT_NAME, RDB$TRIGGER_NAME FROM RDB$CHECK_CONS' +
        'TRAINTS')
    Transaction = SourceTransaction
    Database = SourceDB
    Left = 856
    Top = 56
  end
  object TargetCheckCnstDataSet: TpFIBDataSet
    SelectSQL.Strings = (
      
        'SELECT RDB$CONSTRAINT_NAME, RDB$TRIGGER_NAME FROM RDB$CHECK_CONS' +
        'TRAINTS')
    Transaction = TargetTransaction
    Database = TargetDB
    Left = 992
    Top = 56
  end
  object SourceCheckCnstProvider: TpFIBDataSetProvider
    DataSet = SourceCheckCnstDataSet
    Left = 856
    Top = 104
  end
  object TargetCheckCnstProvider: TpFIBDataSetProvider
    DataSet = TargetCheckCnstDataSet
    Left = 992
    Top = 104
  end
  object SourceCheckCnst: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$CONSTRAINT_NAME'
    Params = <>
    ProviderName = 'SourceCheckCnstProvider'
    Left = 856
    Top = 152
    object SourceCheckCnstRDBCONSTRAINT_NAME: TWideStringField
      FieldName = 'RDB$CONSTRAINT_NAME'
      Size = 31
    end
    object SourceCheckCnstRDBTRIGGER_NAME: TWideStringField
      FieldName = 'RDB$TRIGGER_NAME'
      Size = 31
    end
  end
  object TargetCheckCnst: TpFIBClientDataSet
    Aggregates = <>
    IndexFieldNames = 'RDB$CONSTRAINT_NAME'
    Params = <>
    ProviderName = 'TargetCheckCnstProvider'
    Left = 992
    Top = 152
    object TargetCheckCnstRDBCONSTRAINT_NAME: TWideStringField
      FieldName = 'RDB$CONSTRAINT_NAME'
      Size = 31
    end
    object TargetCheckCnstRDBTRIGGER_NAME: TWideStringField
      FieldName = 'RDB$TRIGGER_NAME'
      Size = 31
    end
  end
end
