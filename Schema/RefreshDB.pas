unit RefreshDB;

interface

uses
  SysUtils, Classes, Provider, FIBDatabase, pFIBDatabase, pFIBScripter, DB, Dialogs,
  DBClient, pFIBClientDataSet, FIBDataSet, pFIBDataSet, Variants, StrUtils;

type
  TOption = (roDropTables, roDropIndexes, roDropFields, roDropDomains, roDropGens);
  TOptions = set of TOption;
  TRefreshDM = class(TDataModule)
    SourceDB: TpFIBDatabase;
    TargetDB: TpFIBDatabase;
    SourceTables: TpFIBClientDataSet;
    TargetTables: TpFIBClientDataSet;
    Scripter: TpFIBScripter;
    SourceTransaction: TpFIBTransaction;
    TargetTransaction: TpFIBTransaction;
    SourceTablesDataSet: TpFIBDataSet;
    TargetTablesDataSet: TpFIBDataSet;
    TargetDimenProvider: TpFIBDataSetProvider;
    TargetDimen: TpFIBClientDataSet;
    SourceDimen: TpFIBClientDataSet;
    SourceDimenProvider: TpFIBDataSetProvider;
    SourceDimenDataSet: TpFIBDataSet;
    TargetDimenDataSet: TpFIBDataSet;
    SourceDimenRDBFIELD_NAME: TWideStringField;
    SourceDimenRDBDIMENSION: TSmallintField;
    SourceDimenRDBLOWER_BOUND: TIntegerField;
    SourceDimenRDBUPPER_BOUND: TIntegerField;
    TargetDimenRDBFIELD_NAME: TWideStringField;
    TargetDimenRDBDIMENSION: TSmallintField;
    TargetDimenRDBLOWER_BOUND: TIntegerField;
    TargetDimenRDBUPPER_BOUND: TIntegerField;
    SourceDomainDataSet: TpFIBDataSet;
    SourceDomainProvider: TpFIBDataSetProvider;
    SourceDomain: TpFIBClientDataSet;
    TargetDomainDataSet: TpFIBDataSet;
    TargetDomainProvider: TpFIBDataSetProvider;
    TargetDomain: TpFIBClientDataSet;
    TargetDomainRDBFIELD_NAME: TWideStringField;
    TargetDomainRDBFIELD_TYPE: TSmallintField;
    TargetDomainRDBFIELD_SUB_TYPE: TSmallintField;
    TargetDomainRDBNULL_FLAG: TSmallintField;
    TargetDomainRDBFIELD_LENGTH: TSmallintField;
    TargetDomainRDBFIELD_SCALE: TSmallintField;
    TargetDomainRDBCHARACTER_LENGTH: TSmallintField;
    TargetDomainRDBFIELD_PRECISION: TSmallintField;
    TargetDomainRDBDEFAULT_SOURCE: TMemoField;
    TargetDomainRDBVALIDATION_SOURCE: TMemoField;
    SourceDomainRDBFIELD_NAME: TWideStringField;
    SourceDomainRDBFIELD_TYPE: TSmallintField;
    SourceDomainRDBFIELD_SUB_TYPE: TSmallintField;
    SourceDomainRDBNULL_FLAG: TSmallintField;
    SourceDomainRDBFIELD_LENGTH: TSmallintField;
    SourceDomainRDBFIELD_SCALE: TSmallintField;
    SourceDomainRDBCHARACTER_LENGTH: TSmallintField;
    SourceDomainRDBFIELD_PRECISION: TSmallintField;
    SourceDomainRDBDEFAULT_SOURCE: TMemoField;
    SourceDomainRDBVALIDATION_SOURCE: TMemoField;
    CharSet: TpFIBClientDataSet;
    CharSetDataSet: TpFIBDataSet;
    Collation: TpFIBClientDataSet;
    CollationDataSet: TpFIBDataSet;
    CollationRDBCOLLATION_NAME: TWideStringField;
    CollationRDBCOLLATION_ID: TSmallintField;
    CharSetRDBCHARACTER_SET_NAME: TWideStringField;
    CharSetRDBCHARACTER_SET_ID: TSmallintField;
    SourceTablesRDBRELATION_NAME: TWideStringField;
    SourceTablesRDBFIELD_SOURCE: TWideStringField;
    SourceTablesRDBFIELD_POSITION: TSmallintField;
    SourceTablesRDBFIELD_NAME: TWideStringField;
    SourceTablesRDBFIELD_TYPE: TSmallintField;
    SourceTablesRDBFIELD_SUB_TYPE: TSmallintField;
    SourceTablesRDBNULL_FLAG: TSmallintField;
    SourceTablesRDBFIELD_LENGTH: TSmallintField;
    SourceTablesRDBFIELD_SCALE: TSmallintField;
    SourceTablesRDBCHARACTER_LENGTH: TSmallintField;
    SourceTablesRDBFIELD_PRECISION: TSmallintField;
    SourceTablesRDBDEFAULT_SOURCE: TMemoField;
    SourceTablesRDBVALIDATION_SOURCE: TMemoField;
    SourceTablesRDBCOMPUTED_SOURCE: TMemoField;
    SourceTablesRDBCOLLATION_ID: TSmallintField;
    SourceTablesRDBCHARACTER_SET_ID: TSmallintField;
    TargetTablesRDBRELATION_NAME: TWideStringField;
    TargetTablesRDBFIELD_SOURCE: TWideStringField;
    TargetTablesRDBFIELD_POSITION: TSmallintField;
    TargetTablesRDBFIELD_NAME: TWideStringField;
    TargetTablesRDBFIELD_TYPE: TSmallintField;
    TargetTablesRDBFIELD_SUB_TYPE: TSmallintField;
    TargetTablesRDBNULL_FLAG: TSmallintField;
    TargetTablesRDBFIELD_LENGTH: TSmallintField;
    TargetTablesRDBFIELD_SCALE: TSmallintField;
    TargetTablesRDBCHARACTER_LENGTH: TSmallintField;
    TargetTablesRDBFIELD_PRECISION: TSmallintField;
    TargetTablesRDBDEFAULT_SOURCE: TMemoField;
    TargetTablesRDBVALIDATION_SOURCE: TMemoField;
    TargetTablesRDBCOMPUTED_SOURCE: TMemoField;
    TargetTablesRDBCOLLATION_ID: TSmallintField;
    TargetTablesRDBCHARACTER_SET_ID: TSmallintField;
    SourceTablesProvider: TpFIBDataSetProvider;
    TargetTablesProvider: TpFIBDataSetProvider;
    CharSetProvider: TpFIBDataSetProvider;
    CollationProvider: TpFIBDataSetProvider;
    SourceIndexDataSet: TpFIBDataSet;
    TargetIndexDataSet: TpFIBDataSet;
    SourceIndexProvider: TpFIBDataSetProvider;
    TargetIndexProvider: TpFIBDataSetProvider;
    SourceIndex: TpFIBClientDataSet;
    SourceIndexRDBINDEX_NAME: TWideStringField;
    SourceIndexRDBRELATION_NAME: TWideStringField;
    SourceIndexRDBUNIQUE_FLAG: TSmallintField;
    SourceIndexRDBINDEX_INACTIVE: TSmallintField;
    SourceIndexRDBINDEX_TYPE: TSmallintField;
    SourceIndexRDBFIELD_NAME: TWideStringField;
    SourceIndexRDBFIELD_POSITION: TSmallintField;
    TargetIndex: TpFIBClientDataSet;
    TargetIndexRDBINDEX_NAME: TWideStringField;
    TargetIndexRDBRELATION_NAME: TWideStringField;
    TargetIndexRDBUNIQUE_FLAG: TSmallintField;
    TargetIndexRDBINDEX_INACTIVE: TSmallintField;
    TargetIndexRDBINDEX_TYPE: TSmallintField;
    TargetIndexRDBFIELD_NAME: TWideStringField;
    TargetIndexRDBFIELD_POSITION: TSmallintField;
    SourceTablesRDBSEGMENT_LENGTH: TSmallintField;
    TargetTablesRDBSEGMENT_LENGTH: TSmallintField;
    SourceGenDataSet: TpFIBDataSet;
    SourceGenProvider: TpFIBDataSetProvider;
    SourceGen: TpFIBClientDataSet;
    TargetGenDataSet: TpFIBDataSet;
    TargetGenProvider: TpFIBDataSetProvider;
    TargetGen: TpFIBClientDataSet;
    SourceGenRDBGENERATOR_NAME: TWideStringField;
    TargetGenRDBGENERATOR_NAME: TWideStringField;
    SourceTrigDataSet: TpFIBDataSet;
    TargetTriigDataSet: TpFIBDataSet;
    SourceTrigProvider: TpFIBDataSetProvider;
    TargetTrigProvider: TpFIBDataSetProvider;
    TargetTrig: TpFIBClientDataSet;
    SourceTrig: TpFIBClientDataSet;
    TargetTrigRDBTRIGGER_NAME: TWideStringField;
    TargetTrigRDBRELATION_NAME: TWideStringField;
    TargetTrigRDBTRIGGER_SEQUENCE: TSmallintField;
    TargetTrigRDBTRIGGER_TYPE: TSmallintField;
    TargetTrigRDBTRIGGER_SOURCE: TMemoField;
    TargetTrigRDBTRIGGER_INACTIVE: TSmallintField;
    TargetTrigRDBSYSTEM_FLAG: TSmallintField;
    TargetTrigRDBFLAGS: TSmallintField;
    SourceTrigRDBTRIGGER_NAME: TWideStringField;
    SourceTrigRDBRELATION_NAME: TWideStringField;
    SourceTrigRDBTRIGGER_SEQUENCE: TSmallintField;
    SourceTrigRDBTRIGGER_TYPE: TSmallintField;
    SourceTrigRDBTRIGGER_SOURCE: TMemoField;
    SourceTrigRDBTRIGGER_INACTIVE: TSmallintField;
    SourceTrigRDBSYSTEM_FLAG: TSmallintField;
    SourceTrigRDBFLAGS: TSmallintField;
    SourceTablesRDBDESCRIPTION: TMemoField;
    TargetTablesRDBDESCRIPTION: TMemoField;
    SourceRefCnstDataSet: TpFIBDataSet;
    TargetRefCnstDataSet: TpFIBDataSet;
    SourceRefCnstProvider: TpFIBDataSetProvider;
    TargetRefCnstProvider: TpFIBDataSetProvider;
    SourceRefCnst: TpFIBClientDataSet;
    TargetRefCnst: TpFIBClientDataSet;
    SourceRelCnstDataSet: TpFIBDataSet;
    TargetRelCnstDataSet: TpFIBDataSet;
    SourceRelCnstProvider: TpFIBDataSetProvider;
    TargetRelCnstProvider: TpFIBDataSetProvider;
    SourceRelCnst: TpFIBClientDataSet;
    TargetRelCnst: TpFIBClientDataSet;
    SourceRefCnstRDBCONSTRAINT_NAME: TWideStringField;
    SourceRefCnstRDBCONST_NAME_UQ: TWideStringField;
    SourceRefCnstRDBMATCH_OPTION: TStringField;
    SourceRefCnstRDBUPDATE_RULE: TStringField;
    SourceRefCnstRDBDELETE_RULE: TStringField;
    TargetRefCnstRDBCONSTRAINT_NAME: TWideStringField;
    TargetRefCnstRDBCONST_NAME_UQ: TWideStringField;
    TargetRefCnstRDBMATCH_OPTION: TStringField;
    TargetRefCnstRDBUPDATE_RULE: TStringField;
    TargetRefCnstRDBDELETE_RULE: TStringField;
    TargetRelCnstRDBCONSTRAINT_NAME: TWideStringField;
    TargetRelCnstRDBCONSTRAINT_TYPE: TStringField;
    TargetRelCnstRDBRELATION_NAME: TWideStringField;
    TargetRelCnstRDBDEFERRABLE: TStringField;
    TargetRelCnstRDBINITIALLY_DEFERRED: TStringField;
    TargetRelCnstRDBINDEX_NAME: TWideStringField;
    SourceRelCnstRDBCONSTRAINT_NAME: TWideStringField;
    SourceRelCnstRDBCONSTRAINT_TYPE: TStringField;
    SourceRelCnstRDBRELATION_NAME: TWideStringField;
    SourceRelCnstRDBDEFERRABLE: TStringField;
    SourceRelCnstRDBINITIALLY_DEFERRED: TStringField;
    SourceRelCnstRDBINDEX_NAME: TWideStringField;
    SourceCheckCnstDataSet: TpFIBDataSet;
    TargetCheckCnstDataSet: TpFIBDataSet;
    SourceCheckCnstProvider: TpFIBDataSetProvider;
    TargetCheckCnstProvider: TpFIBDataSetProvider;
    SourceCheckCnst: TpFIBClientDataSet;
    TargetCheckCnst: TpFIBClientDataSet;
    TargetCheckCnstRDBCONSTRAINT_NAME: TWideStringField;
    TargetCheckCnstRDBTRIGGER_NAME: TWideStringField;
    SourceCheckCnstRDBCONSTRAINT_NAME: TWideStringField;
    SourceCheckCnstRDBTRIGGER_NAME: TWideStringField;
    procedure DataModuleCreate(Sender: TObject);
    procedure ScripterExecuteError(Sender: TObject; StatementNo, Line: Integer;
      Statement: TStrings; SQLCode: Integer; const Msg: string; var doRollBack,
      Stop: Boolean);
  private
    LastSourceFDB : WideString;
    WasError : boolean;
    procedure Error(S : WideString);
  public
    ExecuteScript : boolean;
    function RefreshDataBase(const SourceFDB, TargetFDB : WideString; Options : TOptions = []) : boolean;
  end;

type
  TTrigType = record
    Code : integer;
    Name : string;
  end;
const
  LastTrigType = 10;
  TrigTypes : array[0..LastTrigType] of TTrigType = ((Code:1;Name:'BEFORE INSERT'),(Code:2;Name:'AFTER INSERT'),
       (Code:3;Name:'BEFORE UPDATE'),(Code:4;Name:'AFTER UPDATE'), (Code:5;Name:'BEFORE DELETE'),(Code:6;Name:'AFTER DELETE'),
       (Code:8192;Name:'ON CONNECT'),(Code:8193;Name:'ON DISCONNECT'),
   (Code:8194;Name:'ON TRANSACTION START'),(Code:8195;Name:'ON TRANSACTION COMMIT'),(Code:8196;Name:'ON TRANSACTION ROLLBACK'));

// PRIMARY KEY,UNIQUE  - rdb$index_name
// FOREIGN KEY         - rdb$index_name
// CHECK               - rdb$constaint_name -> rdb$check_constraints.rdb$trigger_name
(*
1-BEFORE INSERT,2-AFTER INSERT,3-BEFORE UPDATE,4-AFTER UPDATE,5-BEFORE DELETE,6-AFTER DELETE,
8192-ON CONNECT,8193-ON DISCONNECT,8194-ON TRANSACTION START,8195-ON TRANSACTION COMMIT,8196-ON TRANSACTION ROLLBACK
SET TERM ^ ;

CREATE TRIGGER name [FOR table/view]
 [IN]ACTIVE
 [ON {[DIS]CONNECT | TRANSACTION {START | COMMIT | ROLLBACK}} ]
 [{BEFORE | AFTER} INSERT OR UPDATE OR DELETE]
 POSITION number
Source.AsString
 SET TERM ; ^
*)
// CREATE GENERATOR name;
// SET GENERATOR name TO value;

// ON UPDATE RESTRICT,NO ACTION,CASCADE,SET DEFAULT,SET NULL

var
  RefreshDM: TRefreshDM;

implementation

{$R *.dfm}

procedure TRefreshDM.DataModuleCreate(Sender: TObject);
begin
  LastSourceFDB := '';
end;

procedure TRefreshDM.Error(S : WideString);
begin
  Scripter.Script.Add('-- !! ' + S);
end;

function TRefreshDM.RefreshDataBase(const SourceFDB, TargetFDB : WideString; Options : TOptions = []) : boolean;
var TableName : string;
    NotEqu : boolean;

   function Dimensions(const FieldName : string; Dimen : TpFIBClientDataSet) : string;
   var
     Sep : string;
     ExistsInSource : boolean;
   begin
     Result := '';
     ExistsInSource := Dimen.FindKey([FieldName]);
     if ExistsInSource then
     begin
       Result := '[';
       Sep := '';
       while not Dimen.EOF and (FieldName = Dimen.FieldByName('RDB$FIELD_NAME').AsString) do
       begin
         Result := Result + Sep + Dimen.FieldByName('RDB$LOWER_BOUND').AsString + ':' + Dimen.FieldByName('RDB$UPPER_BOUND').AsString;
         Dimen.Next;
         Sep := ',';
       end;
       Result := Result + ']';
     end;
   end;

   function SameDimen(FieldName : string) : boolean;
   begin
     Result := Dimensions(FieldName, SourceDimen) = Dimensions(FieldName, TargetDimen);
   end;

   function SameField : boolean;
   var
     I : integer;
   begin
     Result := False;
     for I := 3 to TargetTables.FieldCount - 1 do
       if not VarSameValue(TargetTables.Fields[ I ].Value, SourceTables.Fields[ I ].Value) then
       begin
{$IFDEF DEBUG}
//         Scripter.Script.Add('-- differs ' + TargetTables.Fields[ I ].FieldName);
{$ENDIF}
         Exit;
       end;
     Result := SameDimen(SourceTablesRDBFIELD_NAME.AsString);
   end;

   function CollationName(Collation_Id : TField) : string;
   begin
     Result := '';
     if not Collation_Id.IsNull and Collation.FindKey([Collation_Id.AsInteger]) then
       Result := ' COLLATION ' + CollationRDBCOLLATION_NAME.AsString;
   end;

   function Data_Type(Source : TpFIBClientDataSet) : string;
   var
     FieldName : string;
     Dimen : TpFIBClientDataSet;

     function Size : string;
     begin
       Result := '(' + Source.FieldByName('RDB$CHARACTER_LENGTH').AsString + ')';
     end;

     function PrecisionScale : string;
     var Scale : integer;
     begin
       Scale := Source.FieldByName('RDB$FIELD_SCALE').AsInteger;
       Result := '[' + Source.FieldByName('RDB$FIELD_PRECISION').AsString + ifthen(Scale = 0, '', ','
          + IntToStr(-Scale)) + ']';
     end;

     function CharSetName(CharSet_Id : TField) : string;
     begin
       Result := '';
       if not CharSet_Id.IsNull and CharSet.FindKey([CharSet_id.AsInteger]) then
         Result :=  ' CHARACTER SET ' + CharSetRDBCHARACTER_SET_NAME.AsString;
     end;

   var
     sub_type : integer;
   begin
     FieldName := Source.FieldByName('RDB$FIELD_NAME').AsString;
     sub_type  := Source.FieldByName('RDB$FIELD_SUB_TYPE').AsInteger;
     case Source.FieldByName('RDB$FIELD_TYPE').AsInteger of
    14	: Result := 'CHAR' + Size;
    7	  : case sub_type of
            1 : Result := 'NUMERIC' + PrecisionScale;
            2 : Result := 'DECIMAL' + PrecisionScale;
          else
            Result := 'SMALLINT';
          end;
    8	  : case sub_type of
            1 : Result := 'NUMERIC' + PrecisionScale;
            2 : Result := 'DECIMAL' + PrecisionScale;
          else
            Result := 'INTEGER';
          end;
    16	: case sub_type of
            1 : Result := 'NUMERIC' + PrecisionScale;
            2 : Result := 'DECIMAL' + PrecisionScale;
          else
            Result := 'BIGINT';
          end;
    9	  : Result := 'QUAD';
    10	: Result := 'FLOAT';
    27	: Result := 'DOUBLE';
    35	: Result := 'TIMESTAMP';
    37	: Result := 'VARCHAR' + Size;
    261	: case sub_type of
            0 : Result := 'BLOB SUB_TYPE BINARY SEGMENT SIZE ' + Source.FieldByName('RDB$SEGMENT_LENGTH').AsString;      // segment_length
            1 : Result := 'BLOB SUB_TYPE TEXT SEGMENT SIZE ' + Source.FieldByName('RDB$SEGMENT_LENGTH').AsString;
            else
              Result := 'BLOB';
          end;
    40	: Result := 'NCHAR' + Size;
    45	: Result := 'BLOB_ID';
    12	: Result := 'DATE';
    13	: Result := 'TIME';
     end;
     if StartsText('Source', Source.Name) then
       Dimen := SourceDimen
     else
       Dimen := TargetDimen;
     Result := LowerCase(Result) + Dimensions(FieldName, Dimen) + CharSetName(Source.FieldByName('RDB$CHARACTER_SET_ID'))
   end;

   function col_def : string;
   var
     FieldName, sSource, sComputed : string;
     Def, Check : string;

     function ColConstraint : string;
     begin
       Result := '';
     end;

   begin
     FieldName := SourceTablesRDBFIELD_NAME.AsString;
     sSource   := SourceTablesRDBFIELD_SOURCE.AsString;
     sComputed := Trim(SourceTablesRDBCOMPUTED_SOURCE.AsString);
     if (sSource <> FieldName) and not AnsiStartsText('RDB$', sSource) then
       Result := sSource
     else if sComputed <> '' then
       Result := 'COMPUTED BY ' + sComputed
     else
     begin
       Def := Trim(SourceTablesRDBDEFAULT_SOURCE.AsString);
       if Def <> '' then
         Def := ' ' + Def;
       Check := Trim(SourceTablesRDBVALIDATION_SOURCE.AsString);
       if Check <> '' then
         Check := ' ' + Check;
       Result := Data_Type(SourceTables)
        + Def
        + Check + ColConstraint
        + ifthen(SourceTablesRDBNULL_FLAG.AsInteger = 1, ' NOT NULL', '')
        + CollationName(SourceTablesRDBCOLLATION_ID);
     end;
   end;

   procedure HandleTriggers;
   var TrigName : string;
          First : boolean;

      procedure AddToScript(S : string);
      begin
        if First then
        begin
          First := False;
          Scripter.Script.Add('');
        end;
        Scripter.Script.Add(S);
      end;

      procedure CreateTrig(Alter : boolean);
      var OnName : string;
          I, TrType : integer;
      begin
        AddToScript('SET TERM ^ ;');
        Scripter.Script.Add(ifthen(Alter, 'ALTER', 'CREATE') + ' TRIGGER ' + TrigName + ifthen(Alter, '', ' FOR ' + SourceTrigRDBRELATION_NAME.AsString));
        Scripter.Script.Add(ifthen(SourceTrigRDBTRIGGER_INACTIVE.AsInteger = 1, 'IN', '') + 'ACTIVE');
        TrType := SourceTrigRDBTRIGGER_TYPE.AsInteger;
        OnName := '';
        for I := 0 to LastTrigType do
          if TrType = TrigTypes[ I ].Code then
          begin
            OnName := TrigTypes[ I ].Name;
            Break;
          end;
        if OnName <> '' then
          Scripter.Script.Add('ON ' + OnName);
        Scripter.Script.Add('POSITION ' + SourceTrigRDBTRIGGER_SEQUENCE.AsString);
        Scripter.Script.Add(SourceTrigRDBTRIGGER_SOURCE.AsString);
        Scripter.Script.Add('SET TERM ; ^');
      end;

      function SameTrig : boolean;
      var
        I : integer;
      begin
        Result := False;
        for I := 1 to TargetTrig.FieldCount - 1 do
          if not VarSameValue(TargetTrig.Fields[ I ].Value, SourceTrig.Fields[ I ].Value) then
            Exit;
        Result := True;
      end;


   begin
     First := True;
     TargetTrig.First;
     while not TargetTrig.EOF do
     begin
       TrigName := TargetTrigRDBTRIGGER_NAME.AsString;
       if not SourceTrig.FindKey([TrigName]) then
          AddToScript('DROP TRIGGER ' + TrigName + ';');
       TargetTrig.Next;
     end;
     SourceTrig.First;
     while not SourceTrig.EOF do
     begin
       TrigName := SourceTrigRDBTRIGGER_NAME.AsString;
       if TargetTrig.FindKey([TrigName]) then
       begin
         if not SameTrig then
         begin
           if SourceTrigRDBRELATION_NAME.AsString <> TargetTrigRDBRELATION_NAME.AsString then
           begin
             AddToScript('DROP TRIGGER ' + TrigName + ';');
             CreateTrig(False);
           end else
             CreateTrig(True);
         end;
       end else
         CreateTrig(False);
       SourceTrig.Next;
     end;
   end;

   procedure AlterCreateDomains;
   var DomainName : string;

      procedure CreateDomain;
      var Def : string;
      begin
        Scripter.Script.Add('CREATE DOMAIN ' + DomainName + ' AS');
        Scripter.Script.Add('  ' + Data_Type(SourceDomain));
        Def := Trim(SourceDomainRDBDEFAULT_SOURCE.AsString);
        if Def <> '' then
          Scripter.Script.Add('  ' + Def);
        if SourceDomainRDBNULL_FLAG.AsInteger = 1 then
          Scripter.Script.Add('  NOT NULL');
        Def := Trim(SourceDomainRDBVALIDATION_SOURCE.AsString);
        if Def <> '' then
          Scripter.Script.Add('  ' + Def);
        Scripter.Script.Add(';');
      end;

      function SameDomain : boolean;
      var
        I : integer;
      begin
        Result := False;
        for I := 1 to TargetDomain.FieldCount - 1 do
          if not VarSameValue(TargetDomain.Fields[ I ].Value, SourceDomain.Fields[ I ].Value) then
            Exit;
        Result := SameDimen(SourceDomainRDBFIELD_NAME.AsString);
      end;

   begin
     SourceDomain.First;
     while not SourceDomain.EOF do
     begin
       DomainName := SourceDomainRDBFIELD_NAME.AsString;
       if TargetDomain.FindKey([DomainName]) then
       begin
         if not SameDomain then
         begin
           Scripter.Script.Add('DROP DOMAIN ' + DomainName + ';');
           CreateDomain;
         end;
       end else
         CreateDomain;
       SourceDomain.Next;
     end;
   end;

   procedure DropDomains;
   var DomainName : string;
       First : boolean;
   begin
     First := True;
     TargetDomain.First;
     while not TargetDomain.EOF do
     begin
       DomainName := TargetDomainRDBFIELD_NAME.AsString;
       if not SourceDomain.FindKey([DomainName]) then
       begin
         if First then
         begin
           First := False;
           Scripter.Script.Add('');
         end;
         Scripter.Script.Add('DROP DOMAIN ' + DomainName + ';');
       end;
       TargetDomain.Next;
     end;
   end;

   procedure DropTableIndexes(All : boolean = True);
   var IndexName : string;
       First : boolean;
   begin
     First := True;
     if TargetIndex.FindKey([TableName]) then
     begin
       while not TargetIndex.EOF and (TableName = TargetIndexRDBRELATION_NAME.AsString) do
       begin
         IndexName := TargetIndexRDBINDEX_NAME.AsString;
         if All or not SourceIndex.FindKey([TableName]) then
         begin
           if First then
             Scripter.Script.Add('');
           First := False;
           Scripter.Script.Add('DROP INDEX ' + IndexName + ';');
         end;
         while not TargetIndex.EOF and (TableName = TargetIndexRDBRELATION_NAME.AsString)
           and (IndexName = TargetIndexRDBINDEX_NAME.AsString) do
           TargetIndex.Next;
       end;
     end;
   end;

   procedure DropTables;
   var First : boolean;
   begin
     First := True;
     TargetTables.First;
     while not TargetTables.EOF do
     begin
       TableName := TargetTablesRDBRELATION_NAME.AsString;
       if not SourceTables.FindKey([TableName]) then
         if roDropTables in Options then
         begin
           if First then
           begin
             First := False;
             Scripter.Script.Add('');
           end;
           Scripter.Script.Add('DROP TABLE ' + TableName + ';');
         end else
           NotEqu := True;
       while not TargetTables.EOF and (TableName = TargetTablesRDBRELATION_NAME.AsString) do
         TargetTables.Next;
     end;
   end;

   procedure CreateTableIndex;
   var S : string;
       IndexFields, IndexName : string;
       Inactive : boolean;
   begin
     IndexName := SourceIndexRDBINDEX_NAME.AsString;
     Inactive  := SourceIndexRDBINDEX_INACTIVE.AsInteger = 1;
     S := 'CREATE' +
       ifthen(SourceIndexRDBUNIQUE_FLAG.AsInteger = 1, ' UNIQUE', '' ) +
       ifthen(SourceIndexRDBINDEX_TYPE.AsInteger = 1, ' DESC', ' ASC') +
       ' INDEX ' + IndexName + ' ON ' + TableName;
     IndexFields := '';
     while not SourceIndex.EOF and (TableName = SourceIndexRDBRELATION_NAME.AsString)
       and (IndexName = SourceIndexRDBINDEX_NAME.AsString)  do
     begin
       if IndexFields = '' then
         IndexFields := SourceIndexRDBFIELD_NAME.AsString
       else
         IndexFields := IndexFields + ',' + SourceIndexRDBFIELD_NAME.AsString;
       SourceIndex.Next;
     end;
     Scripter.Script.Add(S + ' (' + IndexFields + ');');
     if Inactive then
       Scripter.Script.Add('ALTER INDEX ' + IndexName + ' INACTIVE;');
   end;

   procedure ModifyTableIndexes;
   var S : string;
       IndexFields, IndexName : string;
       Inactive, Apply, TargetIndexExists : boolean;
       First : boolean;

     function SameFields : boolean;
     var I : integer;
     begin
       Result := False;
       for I := 2 to TargetIndex.FieldCount - 1 do
         if not VarSameValue(TargetIndex.Fields[ I ].Value, SourceIndex.Fields[ I ].Value) then
           Exit;
       Result := True;
     end;


     procedure AddToScript(const S : string);
     begin
       if First then
         Scripter.Script.Add('');
       First := False;
       Scripter.Script.Add(S);
     end;

   begin
//     DropTableIndexes(False);
     First := True;
     if SourceIndex.FindKey([TableName]) then
     begin
       while not SourceIndex.EOF and (TableName = SourceIndexRDBRELATION_NAME.AsString) do
       begin
         IndexName := SourceIndexRDBINDEX_NAME.AsString;
         Inactive  := SourceIndexRDBINDEX_INACTIVE.AsInteger = 1;
         S := 'CREATE' +
           ifthen(SourceIndexRDBUNIQUE_FLAG.AsInteger = 1, ' UNIQUE', '' ) +
           ifthen(SourceIndexRDBINDEX_TYPE.AsInteger = 1, ' DESC', ' ASC') +
           ' INDEX ' + IndexName + ' ON ' + TableName;
         Apply := False;
         TargetIndexExists :=  TargetIndex.FindKey([TableName, IndexName]);
         IndexFields := '';
         while not SourceIndex.EOF and (TableName = SourceIndexRDBRELATION_NAME.AsString)
           and (IndexName = SourceIndexRDBINDEX_NAME.AsString)  do
         begin
           if not Apply and TargetIndexExists then
           begin
             if TargetIndex.EOF or (TableName <> TargetIndexRDBRELATION_NAME.AsString)
               or (IndexName <> TargetIndexRDBINDEX_NAME.AsString) or not SameFields then
             begin
               Apply := True;
               AddToScript('DROP INDEX ' + IndexName + ';');
             end;
             if not Apply then
               TargetIndex.Next;
           end;
           if IndexFields = '' then
             IndexFields := SourceIndexRDBFIELD_NAME.AsString
           else
             IndexFields := IndexFields + ',' + SourceIndexRDBFIELD_NAME.AsString;
           SourceIndex.Next;
         end;
         if Apply or not TargetIndexExists then
         begin
           AddToScript(S + ' (' + IndexFields + ');');
           if Inactive then
             AddToScript('ALTER INDEX ' + IndexName + ' INACTIVE;');
         end;
       end;
     end;
   end;

   procedure CreateTableIndexes;
   var First : boolean;
   begin
     First := True;
     if SourceIndex.FindKey([TableName]) then
     begin
       while not SourceIndex.EOF and (TableName = SourceIndexRDBRELATION_NAME.AsString) do
       begin
         if First then
           Scripter.Script.Add('');
         First := False;
         CreateTableIndex;
       end;
     end;
   end;

   procedure TerminateStmt;
   var I : integer;
       S : string;
   begin
      I := Scripter.Script.Count - 1;
      S := Scripter.Script[ I ];
      S[ Length(S) ] := ';';
      Scripter.Script[ I ] := S;
   end;

   procedure AlterTable;
   var FieldName : string;
       First : boolean;
       I : integer;
       AlterDomains : TStringList;
       SourceDataType, TargetDataType : string;
       sComputed : string;

       procedure AddToScript(const S : string);
       begin
         if First then
         begin
           DropTableIndexes;
           Scripter.Script.Add('');
           Scripter.Script.Add('ALTER TABLE ' + TableName);
           First := False;
         end;
         Scripter.Script.Add(S + ',');
       end;

       procedure AlterDomain;
       var
         Domain : string;
         Def, Check, Descr, FldSet : string;
         First, NewNull, NewDescr : boolean;

         procedure Add(const S : string);
         begin
           if First then
           begin
             AlterDomains.Add('ALTER DOMAIN ' + Domain);
             First := False;
           end;
           AlterDomains.Add(S + ' ');
         end;

         procedure TerminateStmt;
         var I : integer;
             S : string;
         begin
            I := AlterDomains.Count - 1;
            S := AlterDomains[ I ];
            S[ Length(S) ] := ';';
            AlterDomains[ I ] := S;
         end;

         function GetDefault : string;
         begin
           if Def <> '' then
             Result := Trim(Copy(Def, 8, MaxInt))
           else
             Result := '0';
         end;

       begin
         First   := True;
         Domain  := SourceTablesRDBFIELD_SOURCE.AsString;
         Def     := SourceTablesRDBDEFAULT_SOURCE.AsString;
         Descr   := SourceTablesRDBDESCRIPTION.AsString;
         if Def <> TargetTablesRDBDEFAULT_SOURCE.AsString then
         begin
           if Def = ''  then
             Add('DROP DEFAULT')
           else
             Add('SET DEFAULT ' + GetDefault);
         end;
         Check := SourceTablesRDBVALIDATION_SOURCE.AsString;
         if Check <> TargetTablesRDBVALIDATION_SOURCE.AsString then
         begin
           if Check = '' then
             Add('DROP CONSTRAINT')
           else
             Add('ADD CONSTRAINT ' + Check);
         end;
         if not First then
         begin
           TerminateStmt;
         end;
         NewNull := (SourceTablesRDBNULL_FLAG.AsInteger <> TargetTablesRDBNULL_FLAG.AsInteger);
         NewDescr:= (Descr <> TargetTablesRDBDESCRIPTION.AsString);
         if NewNull or NewDescr then
         begin
           if NewNull and (SourceTablesRDBNULL_FLAG.AsInteger = 1) then
           begin
             Add('UPDATE ' + TableName);
             Add('SET ' + FieldName + ' = ' + GetDefault);
             Add('WHERE ' + FieldName + ' IS NULL;');
           end;
           FldSet := '';
           if NewNull then
           begin
             FldSet := 'RDB$NULL_FLAG = ' + SourceTablesRDBNULL_FLAG.AsString;
             if NewDescr then
               FldSet := FldSet + ', ';
           end;
           if NewDescr then
             FldSet := FldSet + 'RDB$DESCRIPTION = ''' + Descr + '''';
           Add('UPDATE RDB$RELATION_FIELDS SET '+ FldSet);
           Add('WHERE RDB$FIELD_NAME = ''' + FieldName + ''' AND RDB$RELATION_NAME = ''' + TableName + ''';');
         end;
       end;

       procedure AddDescription;
       var Descr : string;
       begin
         Descr := SourceTablesRDBDESCRIPTION.AsString;
         if Descr <> '' then
         begin
           AlterDomains.Add('UPDATE RDB$RELATION_FIELDS SET RDB$DESCRIPTION = ''' + Descr + '''');
           AlterDomains.Add('WHERE RDB$FIELD_NAME = ''' + FieldName + ''' AND RDB$RELATION_NAME = ''' + TableName + ''';');
         end;
       end;

   begin
     AlterDomains := TStringList.Create;
     try
       First := True;
       while not TargetTables.EOF and (TableName = TargetTablesRDBRELATION_NAME.AsString) do
       begin
         FieldName := TargetTablesRDBFIELD_NAME.AsString;
         if not SourceTables.Locate('RDB$RELATION_NAME;RDB$FIELD_NAME', VarArrayOf([TableName, FieldName]), []) then
{           AddToScript('DROP ' + FieldName)};
         TargetTables.Next;
       end;
       SourceTables.FindKey([TableName]);
       while not SourceTables.EOF and (TableName = SourceTablesRDBRELATION_NAME.AsString) do
       begin
         FieldName := SourceTablesRDBFIELD_NAME.AsString;
         if not TargetTables.Locate('RDB$RELATION_NAME;RDB$FIELD_NAME', VarArrayOf([TableName, FieldName]), []) then
         begin
           AddToScript('ADD ' + FieldName + ' ' + col_def);
           AddDescription;
         end
         else if not SameField then
         begin
           sComputed := SourceTablesRDBCOMPUTED_SOURCE.AsString;
           if sComputed <> '' then
             AddToScript('ALTER COLUMN ' + FieldName + ' COMPUTED BY ' + sComputed)
           else
           begin
             SourceDataType := Data_Type(SourceTables);
             TargetDataType := Data_Type(TargetTables);
             if TargetDataType <> SourceDataType then
               AddToScript('ALTER COLUMN ' + FieldName + ' TYPE ' + SourceDataType);
             AlterDomain;
           end;
         end;
         SourceTables.Next;
       end;
       if not First then
       begin
         TerminateStmt;
         for I := 0 to AlterDomains.Count - 1 do
           Scripter.Script.Add(AlterDomains[ I ]);
         CreateTableIndexes;
       end else
         ModifyTableIndexes;
     finally
       AlterDomains.Free;
     end;
   end;

   procedure CreateTable;
   var S : string;
       I : integer;
   begin
     Scripter.Script.Add('');
     Scripter.Script.Add('CREATE TABLE ' + TableName);
     Scripter.Script.Add('(');
     while not SourceTables.EOF and (TableName = SourceTablesRDBRELATION_NAME.AsString) do
     begin
       Scripter.Script.Add(SourceTablesRDBFIELD_NAME.AsString + ' ' + col_def + ',');
       SourceTables.Next;
     end;
     I := Scripter.Script.Count - 1;
     S := Scripter.Script[ I ];
     Scripter.Script[ I ] := Copy(S, 1, Length(S) - 1) + ');';
     CreateTableIndexes;
   end;

  procedure CreateGenerators;
  var GenName : string;
  begin
    while not SourceGen.EOF do
    begin
      GenName := SourceGenRDBGENERATOR_NAME.AsString;
      if not TargetGen.FindKey([GenName]) then
        Scripter.Script.Add('CREATE GENERATOR ' + GenName + ';');
      SourceGen.Next;
    end;
  end;

  procedure OpenTarget;
  begin
    TargetDB.Connected := False;
    TargetDB.DBName := TargetFDB;
    TargetDB.Connected := True;
    TargetTables.Close;
    TargetTables.Open;
    TargetDimen.Close;
    TargetDimen.Open;
    TargetDomain.Close;
    TargetDomain.Open;
    TargetTrig.Close;
    TargetTrig.Open;
    TargetIndex.Close;
    TargetIndex.Open;
    TargetGen.Close;
    TargetGen.Open;
  end;

  procedure OpenSource;
  begin
    SourceDB.Connected := False;
    SourceDB.DBName := SourceFDB;
    SourceDB.Connected := True;
    SourceTables.Close;
    SourceTables.Open;
    SourceDimen.Close;
    SourceDimen.Open;
    SourceTrig.Close;
    SourceTrig.Open;
    SourceDomain.Close;
    SourceDomain.Open;
    SourceIndex.Close;
    SourceIndex.Open;
    SourceGen.Close;
    SourceGen.Open;
    if not CharSet.Active then
    begin
      CharSet.Open;
      Collation.Open;
    end;
  end;

begin
  NotEqu   := False;
  WasError := False;
  Scripter.Script.Clear;
  Result := False;
  if LastSourceFDB <> SourceFDB then
    try
      OpenSource;
      LastSourceFDB := SourceFDB;
    except
      on E:Exception do
      begin
        LastSourceFDB := '';
        Error('Can"t connect to "' + SourceFDB + '" : ' + E.Message);
        Exit;
      end;
    end;
  try
    OpenTarget;
  except
    on E:Exception do
    begin
      Error('Can"t connect to "' + TargetFDB + '" : ' + E.Message);
      Exit;
    end;
  end;

  CreateGenerators;

  AlterCreateDomains;

  HandleTriggers;

  DropTables;

  SourceTables.First;
  while not SourceTables.EOF do
  begin
    TableName := SourceTablesRDBRELATION_NAME.AsString;
    if not TargetTables.FindKey([TableName]) then
      CreateTable
    else
      AlterTable;
  end;

//  DropDomains;

  if Scripter.Script.Count <> 0 then
    try
      if ExecuteScript then
        Scripter.ExecuteScript;
      Result := not WasError;
      if Result then
      begin
        if ExecuteScript then
          Scripter.Script.Add('-- Refreshed OK');
      end;
    except
      on E:Exception do
      begin
        Scripter.Transaction.RollBack;
        Error('Errors in script : ' + E.Message);
      end;
    end
  else
  begin
    Scripter.Script.Add('DB structures are equal');
    Result := True;
  end;
  TargetDB.Connected := False;
end;

procedure TRefreshDM.ScripterExecuteError(Sender: TObject; StatementNo,
  Line: Integer; Statement: TStrings; SQLCode: Integer; const Msg: string;
  var doRollBack, Stop: Boolean);
begin
  Error('Line : ' + IntToStr(Line) + ' ' + Msg);
  doRollBack := True;
  Stop := True;
  WasError := True;
end;

end.
