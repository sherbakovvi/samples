unit SimpleRptEx;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OleServer, ExcelXP, dbClient, DB, ADODB, RptTypes, Math,
  OfficeXP, Contnrs, Tses, Clipbrd, Registry, ALog, URegIni1;

type
  TExcelSimpleRpt = class;
  TRepQuery = class;
  TColWidth = array of OleVariant;

  TPasteStream = class(TObject)
  private
    FMemory   : Pointer;
    FPosition : Longint;
    FCapacity : Longint;
    FEstimateSize : Longint;
    procedure IncCapacity;
  public
    procedure   Clear(EstimateSize : Longint);
    constructor Create;
    destructor Destroy; override;
    procedure WriteItem(S : string);
    procedure WriteLine;
    procedure WriteTab;
    procedure CopyToClipBoard;
    property Memory: Pointer read FMemory;
    property Size  : Longint read FPosition;
  end;

  TRepQuery = class(TxClientDataSet)
  private
    Rpt            : TExcelSimpleRpt;
    TableInfo      : PTableInfo;
    procedure OpenQuery(ASQL : string);
  public
    procedure ClearTotals;
    procedure SetKeyValues;
    procedure AddTotals;
    procedure SubTotals;
    procedure SetValues;
    procedure SetFirst;
    procedure AfterFirst;
    procedure SetNext;
    procedure SetNextForSect(Sect : PSection);
    function  SameKey : boolean;
    procedure SetRepRecNo;
    function  LastRecord  : boolean;
  end;


  PPageSection = ^TPageSection;
  TPageSection = record
    InSection    : PSection;
    OutStartRow  : integer;
    WasSupressed : boolean;
    HeadCount    : integer;
    QueryRecNo   : integer;
    Query        : TRepQuery;
  end;

  TExcelRpt = class(TExcelApplication)
  private
    FMode       : TReportMode;
    FPreview    : boolean;
    FUserName, FUserPass  : string;
    RptClosed   : THandle;
    FCancel     : boolean;
    Logged      : boolean;
    NameRow     : integer;
    MsgType     : TProgressKind;
    MsgProc     : integer;
    HasPrinter  : boolean;
    procedure SetCancel(Value : boolean);
  protected
    InSheet, OutSheet : _WorkSheet;
    OutName     : string;
    Quest       : string;
    ShowGridLines  : boolean;
    Book        : _WorkBook;
    pntPageHeights : array of Double;
    procedure DoSave;
    procedure DoSaveAs;
    procedure DoSendMail;
    procedure PerformOper;
    procedure WorkbookBeforeClose(ASender: TObject; const Wb: ExcelWorkbook;
                                                                     var Cancel: WordBool);
    procedure SheetBeforeDoubleClick(ASender: TObject; const Sh: IDispatch;
                                       const Target: ExcelRange;
                                       var Cancel: WordBool);
    procedure SheetActivate(ASender: TObject; const Sh: IDispatch);
    procedure ShowAndWait;
    procedure SetBorders(Range : OleVariant; Left, Top, Right, Bottom, VertInside, HorzInside : XlBorderWeight);
  public
    WndHandle : HWND;
    DoneMsg   : Cardinal;
    ProgrMsg  : Cardinal;
    MsgTag    : string;
    FinalMsg  : string;
    Delete_File  : boolean;
    Recipients   : string;
    Subject      : string;
    OutputFileName : string;
    NeedCheckPageSize : boolean;
    Saved : boolean;
    CallParams   : TParams;
    procedure MakePrint; virtual;
    procedure DoPrint; virtual; abstract;
    procedure InfoMessage(Message : string; Err : TErrType = etFatal);
    procedure Progress(ProgressKind : TProgressKind; Value : integer);
    function  GetParm(Nm : string) : Variant;
    property  RptMode    : TReportMode read FMode write FMode;
    property  Preview    : boolean read FPreview write FPreview;
    property  UserName   : string  read FUserName write FUserName;
    property  UserPass   : string  read FUserPass write FUserPass;
    property  Cancel     : boolean read  FCancel write SetCancel;
  end;

  TClip =class(TClipboard)
  end;

  THeadRange = record
    OutStartRow   : integer;
    OutEndRow     : integer;
    SectionHeight : Double;
  end;
  TPageOfInfo = record
    Row, Col : integer;
    Formula  : PCellFormula;
  end;
  TPicDef = record
    pLeft, pTop, pWidth, pHeight : Double;
    SheetNo: integer;
    pName  : string;
    Place  : TPlaceType;
  end;

  TExcelSimpleRpt = class(TExcelRpt)
  private
    FSourceBook : string;
    PageNo, PageOf  : integer;
    FPrintStamp : boolean;
    vOutSheet   : OleVariant;
    PageOfOfs, PageOfCol : SmallInt;
    PageNoRow   : SmallInt;
    PageOfRow   : SmallInt;
    NumPagesRow, NowDateRow, NowTimeRow : SmallInt;
    PageOfForm  : PCellFormula;
    PageOfInfo  : array of TPageOfInfo;
    EmptyData   : boolean;
    Sections     : TSections;
    SectionList  : array of TSections;
    SheetNames   : array of string;
    PageSections : array[ 0..100 ] of TPageSection;
    PageSectionCount : SmallInt;
    TableHeadList : array[ 0..5 ] of THeadRange;
    TableHeadCount: integer;
    MaxCol    : integer;
    OutCurrentRow: integer;
    LastRows  : array of integer;
    OpenedCDS : TObjectList;
    TableInfoCount : SmallInt;
    TableInfos     : TTableInfos;
    Sheet1Cells    : ExcelRange;
    OutSheetCells  : ExcelRange;
    MainDataSet    : TRepQuery;
    SheetCount     : integer;
    ParamInfos     : array of TParamInfo;
    ParamCount     : SmallInt;
    ShrtName       : string;
    SheetName      : TField;
    MaxSheetCol    : integer;
    NoPaging       : boolean;
    ColFits        : array of boolean;
    FirstTableOut  : integer;
    ParamCDS       : TxClientDataSet;
    InlName        : string;
    Company_Code_Ours : TField;
    Company_Code_Ours_Value : string;
    CurrSheetNo    : integer;
    function  AddPageSection(SecNo : integer; AQuery : TRepQuery; Supressed : boolean) : PPageSection;
    function  CreateQuery(Section : PSection; ASQL :string = '') : TRepQuery;
    function  Cond(Sec : PSection) : boolean;
    procedure DoEmbed(Sec : PSection);
    function  GetFormulaValue(Formula : PCellFormula) : Variant;
    function  GetFormulaStrValue(Formula : PCellFormula) : string;
    function  GetFormulaPrevValue(Formula : PCellFormula) : Variant;
    procedure SetValue(nRow : integer; Value : Variant);
    function  GetParam(Param : TParam) : boolean;
  public
    Connection   : TCustomxConnection;
    LocalCDS     : TObjectList;
    CDSdir       : string;
    MainSQL      : string;
    Quest        : string;
    AfterExecute : string;
    ReportDate   : TDate;
    Str          : TPasteStream;
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    function  GetValue(nRow : integer) : Variant;
    function  PrepareParams(Params : TParams) : boolean;
    procedure Prepare; virtual;
//    procedure MakePrint; override;
    procedure After_Execute; virtual;
    procedure CheckPageSetUp;
    procedure OpenData; virtual;
    function  NextNameRow : integer;
    procedure DoPrint; override;
    procedure ReplaceParams;
    function  ReplaceParam(S : string) : string;
    procedure LogRng(Sheet : _WorkSheet; StartRow, EndRow : integer; InS : boolean);
    procedure AddPageHead(Sec : PSection; OutRow : integer);
    procedure ReplacePictures;
    procedure FindParam(AName : string);
    procedure FindBlob(AName : string; Txt : boolean);
    procedure BadParam;
    function  GetParamValue(AName : string; var Expr, StrParam : boolean): string;
    procedure SetParam(AName : string; Value : Variant);
    property  SourceBook  : string read FSourceBook write FSourceBook;
    property  PrintStamp : boolean read FPrintStamp write FPrintStamp;
  end;

  EWarn = class(Exception);

  procedure Warn(S : string);
  procedure AssignFont(ExFont : OleVariant; Font : TFont);
  function  RptPath : string;

var FRptPath : string  = '';
    Used    : boolean = False;
    NameCol : integer = 100;
    DataCol : integer = 4;
    DataColLeft: Double;

implementation

uses Printers, StrUtils, ActiveX, URepFunc, UParam, FMTBcd;


function RptPath : string;
begin
  if FRptPath = '' then
  begin
    FRptPath := SysRegIni.ReadString('Source', 'ReportDir', '');
    if (FRptPath = '') and SysRegIni.Developer then
      raise Exception.Create('ReportDir not defined');
    if FRptPath = '' then
      FRptPath := ExtractFilePath(Application.ExeName) + 'Reports';
    FRptPath := IncludeTrailingPathDelimiter(ExcludeTrailingPathDelimiter(FRptPath));
  end;
  Result := FRptPath;
end;

procedure Warn(S : string);
begin
  raise EWarn.Create(S);
end;

procedure Fatal(S : string);
begin
  raise Exception.Create(S);
end;

procedure AssignFont(ExFont : OleVariant; Font : TFont);
begin
  ExFont.Name  := Font.Name;
  ExFont.Size  := Font.Size;
  if fsBold in Font.Style then
    ExFont.Bold := msoCTrue
  else
    ExFont.Bold := msoFalse;
  if fsItalic in Font.Style then
    ExFont.Italic := msoCTrue
  else
    ExFont.Italic := msoFalse;
  if fsUnderline in Font.Style then
    ExFont.Underline := msoCTrue
  else
    ExFont.Underline := msoFalse;
end;

function Var2String(Value : Variant) : string;
begin
  case VarType(Value) of
    varEmpty, varNull :
      Result := '';
    varString, VarOleStr :
      Result  := TrimRight(Value);
    varBoolean :
      Result  := ifthen(Value, 'TRUE', 'FALSE');
    varDate :
      Result := DateToStr(Value);
    varSingle, varDouble, varCurrency :
      Result := FloatToStr(Value);
    varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64 :
      Result := IntToStr(Value);
  else
    Result := VarToStr(Value);
  end;
end;

function TExcelSimpleRpt.GetParam(Param : TParam) : boolean;
var I, J  : integer;
    ParTable, ParName : string;
begin
  Result  := False;
  ParName := Param.Name;
  I := Pos('_', ParName);
  if I <> 0 then
  begin
    ParTable := Copy(ParName, 1, I - 1);
    ParName  := Copy(ParName, I + 1, MAXINT);
    I := 0;
    while (I < TableInfoCount) do with TableInfos[ I ] do
      if SameText(Table, ParTable) then
        Break
      else
        Inc(I);
    if I = TableInfoCount then
    begin
      if MainDataSet = nil then
        Exit;
      ParName := ParTable + '_' + ParName;
      I := 0;
    end;
  end else if MainDataSet = nil then
    Exit
  else
    I := 0;
  with TableInfos[ I ] do
    if Query = nil then
      Exit
    else with TxClientDataSet(Query) do
      for J := 0 to FieldCount - 1 do
        if SameText(Fields[ J ].FieldName, ParName) then
        begin
          Param.AssignField(Fields[ J ]);
          Result := True;
          Exit;
        end;
end;

procedure TExcelSimpleRpt.SetValue(nRow : integer; Value : Variant);
begin
  if nRow <> 0 then
  begin
    Sheet1Cells.Item[ nRow, NameCol ].Value2 := Value;
  end;
end;

function TExcelSimpleRpt.GetValue(nRow : integer) : Variant;
begin
  if nRow <> 0 then
    Result := Sheet1Cells.Item[ nRow, NameCol ].Value2;
end;

function TExcelSimpleRpt.PrepareParams(Params : TParams) : boolean;
var I, J : integer;
begin
  for I := 0 to Params.Count - 1 do
    if not GetParam(Params[ I ]) then
      for J := 0 to CallParams.Count - 1 do
        if SameText(CallParams[ J ].Name, Params[ I ].Name) then
        begin
          Params[ I ].Assign(CallParams[ J ]);
          Params[ I ].Bound := True;
          Break;
        end;
  Result := not HasUnassignedValue(Params);
end;

procedure TRepQuery.OpenQuery(ASQL : string);
var I : integer;
    sPar, sWhere, sOrder : string;
    AddPars  : TStringList;
    tmpParams  : TParams;
    tmpField : TField;
    nowhere : boolean;

  procedure Prepare_Params(Params : TParams);
  begin
    if not Rpt.PrepareParams(Params) then
    begin
      FetchParams;
      ReadParams(Params);
    end;
  end;

begin
//  Log('Query : ' + ASQL);
  AddPars := CheckParams(ASQL);
  try
    I := AddPars.IndexOfName('TimeOut');
    if I <> -1 then
    begin
      sPar := AddPars.Values[ 'TimeOut' ];
      if sPar <> '' then
        try
          TimeOut := StrToInt(sPar);
        except
        end;
      AddPars.Delete(I);
    end;
    I := AddPars.IndexOfName('RecPack');
    if I <> -1 then
    begin
      sPar := AddPars.Values[ 'RecPack' ];
      if sPar <> '' then
        try
          PacketRecords := StrToInt(sPar);
        except
        end;
      AddPars.Delete(I);
    end;
    I := AddPars.IndexOfName('nowhere');
    nowhere := I <> -1;
    if nowhere then
      AddPars.Delete(I);
    AddPars.Clear;
    if not Assigned(Connection) then
    begin
      sWhere := GetSQLTokenValue(ASQL, ttWhere, False);
      if (sWhere <> '') and not nowhere then
      begin
        tmpParams  := TParams.Create;
        try
          tmpParams.ParseSQL(ASQL, True);
          for I := 0 to tmpParams.Count - 1 do with tmpParams[ I ] do
          begin
            tmpField := FindField(Name);
            if tmpField <> nil then
              DataType := tmpField.DataType;
          end;
          Prepare_Params(tmpParams);
          for I := 0 to tmpParams.Count - 1 do with tmpParams[ I ] do
            sWhere := StringReplace(sWhere, ':' + Name, VarAsString(DataType, Value), [rfReplaceAll, rfIgnoreCase]);
          Filtered := True;
          Filter   := sWhere;
        finally
          tmpParams.Free;
        end;
      end;
      sOrder := GetSQLTokenValue(ASQL, ttOrderBy, False);
      if sOrder <> '' then
      begin
        StringReplace(sOrder, ',', ';', [rfReplaceAll]);
        StringReplace(sOrder, ' ', '', [rfReplaceAll]);
        IndexFieldNames := sOrder;
      end;
    end else
      try
        Close;
        CommandText.Text := ASQL;
        Prepare_Params(Params);
//        for I := 0 to Params.Count - 1 do with Params[ I ] do
//          Log(Name + ' = ' + VarToStr(Value));
        Open;
//        SaveToFile('sss');
      except
        on E:Exception do
          if E is EAbort then
            raise
          else
            Fatal(ASQL + ' - ' + E.Message);
      end;
  finally
    AddPars.Free;
  end;
end;

procedure TRepQuery.ClearTotals;
var I, J : integer;
begin
  with TableInfo^ do
    for I := 0 to NumFields - 1 do with TableFlds[ I ] do
      if SumField then
        for J := Level to NumLevels - 1 do
        begin
          Total[ J ] := 0;
          Rpt.SetValue(TotalRow[ J ], Total[ J ]);
//          Log(IntToStr(J) + ' clear ');
        end;
end;

procedure TRepQuery.SetKeyValues;
var I : integer;
begin
  with TableInfo^ do
    for I := 0 to LevelKeyLen[ Level ] - 1 do
    begin
      KeyValues[ I ] := IndexFields[ I ].Value;
//      Log(IndexFields[ I ].FieldName + '=' + VarToStr(KeyValues[ I ]));
    end;
//    Li('Level', TableInfo.Level);
end;

procedure TRepQuery.AddTotals;
var I, J : integer;
begin
  with TableInfo^ do
    for I := 0 to NumFields - 1 do with TableFlds[ I ] do
      if SumField then
        for J := 0 to NumLevels - 1 do
        begin
//          Log(IntToStr(J) + ' = ' + FloatToStr(Total[ J ]) + ' - ' + FloatToStr(Field.AsFloat));
          PrevTotal[ J ] := Total[ J ];
          Total[ J ] := Total[ J ] + Field.AsFloat;
          Rpt.SetValue(TotalRow[ J ], Total[ J ]);
        end;
end;

procedure TRepQuery.SubTotals;
var I, J : integer;
begin
  with TableInfo^ do
    for I := 0 to NumFields - 1 do with TableFlds[ I ] do
      if SumField then
        for J := Level to NumLevels - 1 do
          Total[ J ] := Total[ J ] - Field.AsFloat;
end;

procedure TRepQuery.SetValues;
var I : integer;
begin
//  Log('RecNo = ' + IntToStr(RecNo));
//  SetKeyValues;
  with TableInfo^ do
    for I := 0 to NumFields - 1 do with TableFlds[ I ] do
    begin
//      if SameText(Field.FieldName, 'Clnt_Type') then
//        ShowMessage(IntToStr(Ord(Field.DataType)));
      if Field.DataType = ftDateTime then
      begin
        if Field.IsNull then
          Rpt.SetValue(Row, null)
        else
        begin
          Rpt.SetValue(Row, Field.Value);
//          Log(Field.FieldName + ' = ' + VarToStr(Field.Value));
        end;
      end else
        if Field.IsNull then
          Rpt.SetValue(Row, '')
        else
        begin
          Rpt.SetValue(Row, Field.Value);
//          Log(Field.FieldName + ' = ' + VarToStr(Field.Value));
        end;
    end;
end;

procedure TRepQuery.SetFirst;
begin
  First;
  AfterFirst;
end;

procedure TRepQuery.AfterFirst;
begin
  TableInfo^.Level := 0;
  ClearTotals;
  SetValues;
  SetRepRecNo;
end;

function TExcelSimpleRpt.GetFormulaPrevValue(Formula : PCellFormula) : Variant;
begin
  with Formula^ do
  begin
    case DataType of
      dtField :
        with TableInfos[ TableIndex ], TableFlds[ FieldIndex ] do
        begin
          if TRepQuery(Query).RecNo = 1 then
            Result := null
          else if not SumField or (TotalIndex = -1) then
          begin
            Result := PrevValue;
            if Field.DataType = ftDateTime then
            begin
              if not VarIsNull(Result) then
                Result := VarToDateTime(Result);
            end;
          end else
            Result := PrevTotal[ TotalIndex ];
        end;
     else
       Fatal('supress error');
    end;
  end;
end;

function TExcelSimpleRpt.GetFormulaValue(Formula : PCellFormula) : Variant;
begin
  with Formula^, TableInfos[ TableIndex ], TableFlds[ FieldIndex ] do
  begin
   if TotalIndex >= NumLevels then
      Fatal('field ' + FldName + ' of ' + Table + ' has to big level');
    case DataType of
      dtField :
        begin
          if Query = nil then
            Fatal('field ' + FldName + ' of ' + Table + ' is used before it has value');
          if not SumField or (TotalIndex = -1) then
          begin
            if Field.DataType = ftDateTime then
            begin
              if Field.IsNull then
                Result := null
              else
                Result := Field.AsDateTime;
            end else
              Result := Field.Value;
          end else
            Result := Total[ TotalIndex ];
        end;
      dtExpr, dtPageOfExpr :
      begin
        Result := Sheet1Cells.Item[ ExprRow, NameCol ].Value2;
      end;
      dtRecNo:
        with TableInfos[ TableIndex ] do
        begin
          if Query = nil then
            Fatal('recno'  + ' of ' + Table + ' is used before table active');
          Result := RecNos[ TotalIndex ];
//          Result := Query.RecNo;
        end;
      dtRecCount:
        with TableInfos[ TableIndex ] do
        begin
          if Query = nil then
            Fatal('record count ' + ' of ' + Table + ' is used before table active');
          Result := RecCounts[ TotalIndex ];
        end;
      dtPageNo  :
        Result := PageNo;
      dtPageOf  :
        Result := PageOf; // IntToStr(PageNo) +' PageOf ' + IntToStr(NumPages);
      dtNumPages :
        Result := PageNo;
      dtNowDate :
        Result := Date;
      dtNowTime:
        Result := Time;
    end;
  end;
end;

function TExcelSimpleRpt.GetFormulaStrValue(Formula : PCellFormula) : string;
begin
  with Formula^, TableInfos[ TableIndex ], TableFlds[ FieldIndex ] do
  begin
   if TotalIndex >= NumLevels then
      Fatal('field ' + FldName + ' of ' + Table + ' has to big level');
    case DataType of
      dtField :
        begin
          if Query = nil then
            Fatal('field ' + FldName + ' of ' + Table + ' is used before it has value');
          if not SumField or (TotalIndex = -1) then
          begin
            if Field.IsNull then
               Result := ''
            else
              Result := Trim(Field.AsString);
          end else
            Result := FloatToStr(Total[ TotalIndex ]);
        end;
      dtExpr, dtPageOfExpr :
      begin
        Result := VarToStr(Sheet1Cells.Item[ ExprRow, NameCol ].Value2);
      end;
      dtRecNo:
        with TableInfos[ TableIndex ] do
        begin
          if Query = nil then
            Fatal('recno'  + ' of ' + Table + ' is used before table active');
          Result := IntToStr(RecNos[ TotalIndex ]);
//          Result := Query.RecNo;
        end;
      dtRecCount:
        with TableInfos[ TableIndex ] do
        begin
          if Query = nil then
            Fatal('record count ' + ' of ' + Table + ' is used before table active');
          Result := IntToStr(RecCounts[ TotalIndex ]);
        end;
      dtPageNo  :
        Result := IntToStr(PageNo);
      dtPageOf  :
        Result := IntToStr(PageOf); // IntToStr(PageNo) +' PageOf ' + IntToStr(NumPages);
      dtNumPages :
        Result := IntToStr(PageNo);
      dtNowDate :
        Result := DateToStr(Date);
      dtNowTime:
        Result := TimeToStr(Time);
    end;
  end;
end;

function TExcelSimpleRpt.NextNameRow : integer;
begin
  Inc(NameRow);
  Result := NameRow;
end;

procedure TExcelSimpleRpt.DoEmbed(Sec : PSection);
var O  : OleVariant;
    H, nTop  : Double;
    Inl     : ExcelOleObject;
begin
  with Sec^ do
  begin
    nTop := OutSheet.Cells.Item[ OutCurrentRow, 1 ].Top;
    try
      O := OleVariant(OutSheet).OLEObjects.Add(Filename:=InlName,Link:=False,DisplayAsIcon:=False);
    except
      Log('ole InlName=' + InlName);
      raise;
    end;
    O.ShapeRange.Line.Visible := msoFalse;
    H := O.Height;
    RowHeights[ 0 ] := H - SectionHeight + RowHeights[ 0 ];
    OleVariant(OutSheet).Rows[ OutCurrentRow ].RowHeight :=  RowHeights[ 0 ];
    SectionHeight := H;
    Inl  := IDispatch(TVarData(O).VDispatch) as ExcelOleObject;
    Inl.Left   := 0;
    Inl.Top    := nTop;
    Inl.Height := H;
  end;
end;

function TExcelSimpleRpt.Cond(Sec : PSection) : boolean;
var Tp : TVarType;
    V  : OleVariant;
    Blob    : TField;
    PutSeal : boolean;
    I : integer;
begin
  if Sec.CondFlag = cfCondRow then
    V := Sheet1Cells.Item[ Sec.CondRow, NameCol ].Value2
  else
    V := Sec.CondFlag = cfTrue;
  Tp := VarType(V);
  Result := True;
  case Tp of
    varBoolean :
      Result := V;
    varSmallint, varInteger, varDouble, varCurrency,
    varByte, varWord :
      Result := V > 0;
    else
      Fatal('Error in Cond formula, row : ' + IntToStr(Sec^.StartRow) + ', F = ' + Sheet1Cells.Item[ Sec.CondRow, NameCol ].Formula);
  end;
  if Result and Sec.Embed then with Sec^ do
  begin
    InlName := Trim(InSheet.Cells.Item[ Sec.StartRow, 2 ].Text);
    PutSeal  := True;
    for I := 0 to FormulaCount - 1 do with Formulas[ I ] do
      if Col = 1 then
      begin
        try
          PutSeal := Sheet1Cells.Item[ ExprRow, NameCol ].Value2;
        except
          PutSeal := True;
        end;
//        PutSeal := Application.Evaluate(Copy(S, 2, MaxInt),  LOCALE_USER_DEFAULT);
        Break;
      end;
    if InlName[ 1 ] = '_' then
    begin
      InlName := Copy(InlName, 2, MAXINT);
      FindBlob(InlName, not PutSeal);
      Blob := ParamCDS.FieldByName('RP_Blob');
      InlName := RptPath + InlName + '.xls';
      TBlobField(Blob).SaveToFile(InlName);
    end else with ParamCDS  do
    begin
      Close;
      CommandText.Text := InlName;
      if not PrepareParams(Params) then
        raise Exception.Create('Params not defined');
//        CommandText.Text := 'select RCS_Seal from Report_Client_Seal where RCS_Name=:Name and RCS_ClientCode=:Code and :Date >= RCS_DateFrom and (RCS_DateTo is NULL or :Date < RCS_DateTo)';
      Open;
      Blob := Fields[ 0 ];
      Result  := RecordCount > 0;
      SetParam('_Embeded', Result);
      if Result then
      begin
        InlName := RptPath + 'inlay.xls';
        TBlobField(Blob).SaveToFile(InlName);
      end;
    end;
  end;
//  Log(IntToStr(Sec.StartRow) + '=' + ifthen(Result, 'TRUE', 'FALSE'));
end;

procedure TExcelSimpleRpt.BadParam;
var I, J : integer;
    InlName, Msg : string;
    SheetCount : integer;

procedure CheckParam(AName : string);
begin
  ParamCDS.Close;
  ParamCDS.CommandText.Text := 'sp_get_Report_Parameter';
  with ParamCDS, Params do
  begin
    if Count = 0 then
    begin
      CreateParam(ftString, '@RP_Code', ptInput);
      CreateParam(ftDateTime, '@Date', ptInput);
      CreateParam(ftString, '@Lang', ptInput);
      if Company_Code_Ours <> nil then
        CreateParam(ftString, '@Company_Code_Ours', ptInput);
    end;
    ParamByName('@RP_Code').AsString := AName;
    ParamByName('@Date').AsDateTime := ReportDate;
    ParamByName('@Lang').AsString := GetParm('Language');
    if Company_Code_Ours <> nil then
      Params[ 3 ].AssignField(Company_Code_Ours);
    Open;
    if EOF then
      Msg := Msg + #13#10'Parameter ' + AName + ' is not found'
    else if not FieldByName('RP_Replaced').AsBoolean then
      Msg := Msg + #13#10'Parameter ' + AName + ' is not defined';
  end;
end;

begin
  Msg := 'Params error :';
  SheetCount := Length(SectionList);
  for J := 0 to SheetCount - 1 do
    for I := 0 to Length(SectionList[ J ]) - 1 do
      if SectionList[ J, I ].Embed then
      begin
        InlName := Trim(InSheet.Cells.Item[ SectionList[ J, I ].StartRow, 2 ].Text);
        if InlName[ 1 ] = '_' then
          CheckParam(Copy(InlName, 2, MAXINT));
      end;
  for I := 0 to ParamCount - 1 do with ParamInfos[ I ] do
    if Name[ 1 ] <> '_' then
       CheckParam(Name);
  raise Exception.Create(Msg);
end;

procedure TExcelSimpleRpt.FindParam(AName : string);
begin
  ParamCDS.Close;
  ParamCDS.CommandText.Text := 'sp_get_Report_Parameter';
  with ParamCDS, Params do
  begin
    Clear;
    CreateParam(ftString, '@RP_Code', ptInput);
    CreateParam(ftDateTime, '@Date', ptInput);
    CreateParam(ftString, '@Lang', ptInput);
    if Company_Code_Ours <> nil then
      CreateParam(ftString, '@Company_Code_Ours', ptInput);
    Params[ 0 ].AsString := AName;
    Params[ 1 ].AsDateTime := ReportDate;
    Params[ 2 ].AsString := GetParm('Language');
    if Company_Code_Ours <> nil then
      Params[ 3 ].AssignField(Company_Code_Ours);
//    Log('FindParam : ' + Params[ 3 ].AsString);
    Open;
    if EOF or not FieldByName('RP_Replaced').AsBoolean then
      BadParam;
  end;
end;

procedure TExcelSimpleRpt.FindBlob(AName : string; Txt : boolean);
begin
  ParamCDS.Close;
  ParamCDS.CommandText.Text := 'sp_get_Report_BlobParameter';
  with ParamCDS, Params do
  begin
    Clear;
    CreateParam(ftString, '@RP_Code', ptInput);
    CreateParam(ftDateTime, '@Date', ptInput);
    CreateParam(ftBoolean, '@Txt', ptInput);
    if Company_Code_Ours <> nil then
      CreateParam(ftString, '@Company_Code_Ours', ptInput);
    Params[ 0 ].AsString := AName;
    Params[ 1 ].AsDateTime := ReportDate;
    Params[ 2 ].AsBoolean := Txt;
    if Company_Code_Ours <> nil then
      Params[ 3 ].AssignField(Company_Code_Ours);
//    Log('FindBlob : ' + Params[ 3 ].AsString);
    Open;
    if EOF or not FieldByName('RP_Replaced').AsBoolean then
      BadParam;
  end;
end;

procedure TExcelSimpleRpt.ReplacePictures;
var J, N, L  : integer;
    S        : string;
    Sheet1   : _WorkSheet;
    Picture  : ExcelXP.Picture;
    Pics     : ExcelXP.Pictures;
    Bitmap   : TBitMap;
    nWidth, nHeight : Double;
    BS  : TStream;
    ShNo, ShapeNo : integer;
    Pl       : string;
    APictDef : array[ 0..30 ] of TPicDef;
    PicCount : integer;
begin
  ShapeNo := 0;
  Bitmap := TBitMap.Create;
  try
    PicCount := 0;
    for N := 1 to Book.WorkSheets.Count do
    begin
      Sheet1 := Book.WorkSheets[ N ] as _WorkSheet;
      for J := OleVariant(Sheet1).Pictures.Count downto 1 do
      begin
        Picture := Sheet1.Pictures(J, LOCALE_USER_DEFAULT) as ExcelXP.Picture;
        S   := Picture.Name;
        if (Length(S) > 0) and (S[ 1 ] = '_') then with Picture, APictDef[ PicCount ] do
        begin
          System.Delete(S, 1, 1);
          L  := Pos('$', S);
          if L <> 0 then
          begin
            Pl := UpperCase(System.Copy(S, L, 2));
            S  := System.Copy(S, 1, L - 1);
            L  := Pos(PL[ 1 ], 'ASC');
            Place := TPlaceType(L - 1);
          end else
            Place := ptAsIs;
          pLeft   := Left;
          pTop    := Top;
          pWidth  := Width;
          pHeight := Height;
          SheetNo := N;
          pName   := S;
          Delete;
          if not SameText(System.Copy(S, 1, 5), 'Stamp') or PrintStamp then
            Inc(PicCount);
        end;
      end;
    end;
    ShNo  := 0;
    for J := 0 to PicCount - 1 do with APictDef[ J ] do
    begin
      FindBlob(pName, False);
      if ShNo <> SheetNo then
      begin
        ShNo := SheetNo;
        Pics := Pictures((Book.WorkSheets[ ShNo ] as _WorkSheet).Pictures(null, LOCALE_USER_DEFAULT));
      end;
      with ParamCDS do
        BS := CreateBlobStream(FieldByName('RP_Blob'), bmRead);
      try
        BitMap.LoadFromStream(BS);
      finally
        BS.Free;
      end;
      CopyToClipBoard(BitMap);
      Picture := Pics.Paste(null);
//        Clipboard.Clear;
      nWidth := 120.75/175 * BitMap.Width;
      nHeight:= 173.25/229 * BitMap.Height;
      Picture.Name  := pName + IntToStr(ShapeNo);
      Inc(ShapeNo);
      with Picture do
      case Place of
        ptCenter :
          begin
            Left  := pLeft + (pWidth - nWidth) / 2;
            Top   := pTop + (pHeight - nHeight) / 2;
            Width := nWidth;
            Height:= nHeight;
          end;
        ptStretch :
          begin
            Left  := pLeft;
            Top   := pTop;
            Width := pWidth;
            Height:= pHeight;
          end;
        else
           Left  := pLeft;
           Top   := pTop;
           Width := nWidth;
           Height:= nHeight;
      end;
    end;
  finally
    BitMap.Free;
  end;
end;

function TExcelSimpleRpt.ReplaceParam(S : string) : string;
var I  : integer;
    Strings  : TStringList;
    S1, Item : string;
    StrParam, Expr : boolean;
begin
  Result := S;
  Strings := TStringList.Create;
  try
    ExtractStrings(Separators, [' '], PChar(S), Strings);
    for I := Strings.Count - 1 downto 0 do
    begin
      Item := Trim(Strings[ I ]);
      if IsValidIdent(Item) then
      begin
        if not IsFunc(S, Integer(Strings.Objects[ I ]) + Length(Item)) and (Item[ 1 ] = '_') then
        begin
          S1 := GetParamValue(Copy(Item, 2, MAXINT), Expr, StrParam);
          if Expr then
            S1 := '(' + Copy(S1, 2, MAXINT) + ')'
          else if StrParam then
            S1 := AnsiQuotedStr(S1, '"');
          Result := StuffString(Result, Integer(Strings.Objects[ I ]), Length(Item), S1)
        end;
      end;
    end;
  finally
    Strings.Free;
  end;
end;

procedure TExcelSimpleRpt.SetParam(AName : string; Value : Variant);
var Param : TParam;
    J : integer;
begin
  if AName[ 1 ] = '_' then
  begin
    Param  := CallParams.FindParam(Copy(AName, 2, MAXINT));
    if Param <> nil then
      Param.Value := Value
  end;
  for J := 0 to ParamCount - 1 do with ParamInfos[ J ] do
    if SameText(Name, AName) then
    begin
      (Book.Worksheets[ Sheet ] as _Worksheet).Cells.Item[ Row, Col ].Value2 := Value;
      Break;
    end;
end;

function TExcelSimpleRpt.GetParamValue(AName : string; var Expr, StrParam : boolean): string;
var Param : TParam;
    Yr, Mn, Dy : Word;
begin
  StrParam := False;
  if AName[ 1 ] = '_' then
  begin
    AName := Copy(AName, 2, MAXINT);
    Param := CallParams.FindParam(AName);
    if Param = nil then
      raise Exception.Create('CallParm ' + AName + ' not found');
    with Param do
      if Param.IsNull then
        Result := ''
      else case DataType of
        ftBoolean :
          Result := ifthen(AsBoolean, 'TRUE', 'FALSE');
        ftString :
          begin
            StrParam := True;
            Result := AsString;
          end;
        ftDate, ftDateTime :
          begin
            DecodeDate(AsDateTime, Yr, Mn, Dy);
            Result := 'DATE(' + IntToStr(Yr) + ';' + IntToStr(Mn) + ';' + IntToStr(Dy) + ')';
          end;
        else
          Result := AsString;
      end;
  end else
  begin
    FindParam(AName);
    StrParam := True;
    Result := ParamCDS.FieldByName('RP_Value').AsString;
  end;
  Expr := (Result <> '') and (Result[ 1 ] = '=');
  if Expr then
    Result := ReplaceParam(Result);
end;

procedure TExcelSimpleRpt.ReplaceParams;
var Cell : OleVariant;
    S : string;
    Expr, StrParam : boolean;
    J, I, Count  : integer;
begin
//  Log(DateToStr(ReportDate));
  for I := 0 to ParamCount - 1 do with ParamInfos[ I ] do
  begin
    S := GetParamValue(Name, Expr, StrParam);
//    Log(Name+'='+S);
    if RightStr(S, 2) = #13#10 then
       SetLength(S, Length(S) - 2);
    Cell := (Book.Worksheets[ Sheet ] as _Worksheet).Cells.Item[ Row, Col ];
    if Cell.MergeCells or (Pos(#13#10, S) = 0) then
      Cell.Value2 := S
    else
    begin
      Count := 0;
      repeat
        J := Pos(#13#10, S);
        if J <> 0 then
        begin
          (Book.Worksheets[ Sheet ] as _Worksheet).Cells.Item[ Row + Count, Col ].Value2 := Copy(S, 1, J - 1);
          S := Copy(S, J + 2, MaxInt);
        end else
          (Book.Worksheets[ Sheet ] as _Worksheet).Cells.Item[ Row + Count, Col ].Value2 := S;
        Inc(Count);
      until J = 0;
    end;
  end;
end;

function TExcelSimpleRpt.CreateQuery(Section : PSection; ASQL :string = '') : TRepQuery;
var I : integer;
    Dir, sFrom : string;
begin
  Result := nil;
  with TableInfos[ Section.TableIndex ] do
  begin
    Skipped := not Cond(Section);
    if ASQL = '' then
      ASQL := SQL;
    if Skipped then
      Exit;
  end;
  with Section^ do
  begin
    if Connection = nil then
    begin
      sFrom := GetSQLTokenValue(ASQL, ttFrom, False);
      Result := TRepQuery.Create(nil);
      if Assigned(LocalCDS) then
        for I := 0 to LocalCDS.Count - 1 do
          if SameText(TCustomClientDataSet(LocalCDS[ I ]).Name, sFrom) then
          begin
            Result.CloneCursor(TCustomClientDataSet(LocalCDS[ I ]), False);
            Break;
          end;
      if not Result.Active then with Result do
      begin
        Dir := CDSdir;
        if Dir = '' then
          Dir := ExtractFilePath(Forms.Application.ExeName);
        FileName := Dir + sFrom + '.cds';
        if not FileExists(FileName) then
          raise Exception.Create('Can"t open ' + FileName);
        LoadFromFile;
      end;
    end else
    begin
      Result := TRepQuery.Create(nil);
      Result.Connection := Connection;
    end;
    Result.TableInfo := @TableInfos[ TableIndex ];
    with Result, TableInfo^ do
    begin
      Rpt := Self;
      try
        OpenQuery(ASQL);
      except
        Result.Free;
        raise;
      end;
      Query := Result;
      Name  := TableName;
      if KeyFields <> '' then
        IndexFieldNames := KeyFields;
      SetLength(KeyValues, IndexFieldCount);
      Result.First;
      RecCount  := RecordCount;
//      Log('Query : ' + ASQL + ', RC = ' + IntToStr(RecCount));
//      for I := 0 to FieldCount - 1 do
//        Log('Query : ' + ASQL + ', field : ' + Fields[ I ].FieldName);
//        Log('field : ' + Fields[ I ].FieldName + ', Value : ' + VarToStr(Fields[ I ].Value));

      if RecCount > 0 then
      begin
        SetValue(RecCountRows[ 0 ], RecCount);
        for I := 0 to NumFields - 1 do with TableFlds[ I ] do
        begin
          Field := FindField(FldName);
          if Field = nil then
            Fatal('Field ' + FldName + ' not found in ' + ASQL);
  //        Log(FldName + ' = ' + VarToStr(Field.Value));
        end;
        AfterFirst;
      end;
    end;
  end;
  OpenedCDS.Add(Result);
end;

procedure TExcelRpt.SetBorders(Range : OleVariant; Left, Top, Right, Bottom, VertInside, HorzInside : XlBorderWeight);
var Sel : OleVariant;
begin
  Range.Select;
  Sel := Selection[ LOCALE_USER_DEFAULT ];
  Sel.Borders[ xlInsideHorizontal ].LineStyle := HorzInside;
  Sel.Borders[ xlInsideVertical ].LineStyle := VertInside;
  Sel.Borders[ xlEdgeBottom ].LineStyle := Bottom;
  Sel.Borders[ xlEdgeLeft ].LineStyle := Left;
  Sel.Borders[ xlEdgeRight ].LineStyle := Right;
  Sel.Borders[ xlEdgeTop ].LineStyle := Top;
end;

procedure TExcelRpt.SheetBeforeDoubleClick(ASender: TObject; const Sh: IDispatch;
                                       const Target: ExcelRange;
                                       var Cancel: WordBool);
begin
{  Cancel := True;
  FCancel := True;
  SetEvent(RptClosed);}
end;

procedure TExcelRpt.ShowAndWait;
var msg : TMsg;
begin
  DoSaveAs;
  ActiveWindow.DisplayGridlines := ShowGridLines;
  OnWorkbookBeforeClose := WorkbookBeforeClose;
  OnSheetBeforeDoubleClick := SheetBeforeDoubleClick;
  OnSheetActivate       := SheetActivate;
  DisplayAlerts[ LOCALE_USER_DEFAULT ] := True;
  AlertBeforeOverwriting[ LOCALE_USER_DEFAULT ] := True;
  Book.DisplayDrawingObjects[ LOCALE_USER_DEFAULT ] := xlDisplayShapes;
  ScreenUpdating[ LOCALE_USER_DEFAULT ] := True;
  Visible[ LOCALE_USER_DEFAULT ] := True;
  RptClosed  := CreateEvent(nil, True, False, '');

  while True do
    case MsgWaitForMultipleObjects(1, RptClosed, False, INFINITE, QS_ALLINPUT) of
      WAIT_OBJECT_0 : Break;
      WAIT_OBJECT_0 + 1 :
         while PeekMessage(msg, 0, 0, 0, PM_REMOVE) do
           DispatchMessage(msg);
    end;
  OnSheetBeforeDoubleClick := nil;
  OnWorkbookBeforeClose := nil;
  OnSheetActivate       := nil;
  Visible[ LOCALE_USER_DEFAULT ] := False;
  DisplayAlerts[ LOCALE_USER_DEFAULT ] := False;
  AlertBeforeOverwriting[ LOCALE_USER_DEFAULT ] := False;
  ScreenUpdating[ LOCALE_USER_DEFAULT ] := False;
  CloseHandle(RptClosed);
end;
{         S := _WorkSheet(CurBook.WorkSheets[ 1 ]);
         R := S.Range[ 'A1', 'A1' ];
         V := R.Width;
         Pn := CurBook.Application.CentimetersToPoints(10, 1049);
         ShowMessage(VarToStr(V /Pn * 100));}

//    Papers : array of word;
procedure TExcelSimpleRpt.CheckPageSetUp;
var I, PixPerInch : integer;
    InSheet : _WorkSheet;
begin
  try
    HasPrinter := Printer.PrinterIndex <> -1;
  except
    HasPrinter := False;
  end;
  if not HasPrinter then
    Exit;
  for I := 1 to SheetCount do
  begin
    InSheet := Book.WorkSheets[ I ] as _WorkSheet;
    with InSheet.PageSetUp do
    begin
      if OleVariant(InSheet).PageSetUp.Orientation = xlLandscape then
      begin
        PixPerInch := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
        pntPageHeights[ I - 1 ] := CentimetersToPoints(Trunc(Printer.PageWidth / PixPerInch * 2.5440)) - BottomMargin - TopMargin - FooterMargin - HeaderMargin;
      end else
      begin
        PixPerInch := GetDeviceCaps(Printer.Handle, LOGPIXELSY);
        pntPageHeights[ I - 1 ] := CentimetersToPoints(Trunc(Printer.PageHeight / PixPerInch * 2.5440)) - BottomMargin - TopMargin - FooterMargin - HeaderMargin;
      end;
    end;
  end;
end;

procedure TExcelSimpleRpt.OpenData;
begin
  Book := WorkBooks.Open(RptPath + SourceBook + '.xls', null, False,
                    null, null, null,
                    True, null, null,
                    True, null, null,
                    False, null, null, 1033);
  SheetCount := Book.WorkSheets.Count;
end;

procedure TExcelSimpleRpt.Prepare;
begin
  try
    ConnectKind  := ckNewInstance;
    AutoRecover.Enabled := False;
    AutoConnect  := True;
    AutoQuit     := True;
    UseSystemSeparators := False;
    DecimalSeparator := '.';
    ThousandsSeparator := ' ';
    DisplayAlerts[ LOCALE_USER_DEFAULT ] := False;
    AlertBeforeOverwriting[ LOCALE_USER_DEFAULT ] := False;
    ScreenUpdating[ LOCALE_USER_DEFAULT ] := False;
  except
    Fatal('Проверьте был ли запущен хоть раз Excel и достаточно ли у вас прав');
  end;
end;

procedure TRepQuery.SetRepRecNo;
begin
  with TableInfo^ do
  begin
    RecNos[ 0 ] := RecNo;
    Rpt.SetValue(RecNoRows[ 0 ], RecNo);
  end;
end;

procedure TRepQuery.SetNext;
var I : integer;
begin
  AddTotals;
  with TableInfo^ do
    for I := 0 to NumFields - 1 do with TableFlds[ I ] do
      PrevValue := Field.Value;
  Next;
  if not EOF then
  begin
    SetValues;
    SetRepRecNo;
  end;
end;

procedure TRepQuery.SetNextForSect(Sect : PSection);
var I : integer;
begin
  AddTotals;
  with TableInfo^ do
    for I := 0 to NumFields - 1 do with TableFlds[ I ] do
      PrevValue := Field.Value;
  Next;
  if not EOF then
  begin
//    SetKeyValues;
    with TableInfo^ do
      for I := 0 to Length(Sect.SetFields) - 1 do with TableFlds[ Sect.SetFields[ I ]] do
      begin
        if Field.DataType = ftDateTime then
        begin
          if Field.IsNull then
            Rpt.SetValue(Row, null)
          else
          begin
            Rpt.SetValue(Row, Field.Value);
  //          Log(Field.FieldName + ' = ' + VarToStr(Field.Value));
          end;
        end else
          if Field.IsNull then
            Rpt.SetValue(Row, '')
          else
          begin
            Rpt.SetValue(Row, Field.Value);
  //          Log(Field.FieldName + ' = ' + VarToStr(Field.Value));
          end;
      end;
    SetRepRecNo;
  end;
end;

function TRepQuery.LastRecord  : boolean;
begin
  Next;
  if EOF then
    Result := True
  else
  begin
    Result := not SameKey;
    Prior;
  end;
end;

function TRepQuery.SameKey : boolean;
var I : integer;
begin
  Result := False;
  with TableInfo^ do
    for I := 0 to LevelKeyLen[ Level ] - 1 do
    begin
      Log('Key ' + VarToStr(KeyValues[ I ]));
      Log('Val ' + VarToStr(IndexFields[ I ].Value));
      if KeyValues[ I ] <> IndexFields[ I ].Value then
        Exit;
    end;
  Result := True;
end;

procedure TExcelSimpleRpt.AddPageHead(Sec : PSection; OutRow : integer);
begin
  with Sec^ do
    if not SkipInContinue then
    begin
       with TableHeadList[ TableHeadCount ] do
       begin
         OutStartRow   := OutRow;
         OutEndRow     := OutRow + EndRow - StartRow;
         SectionHeight := Sec.SectionHeight;
//    LogRng(OutSheet, OutStartRow, OutEndRow, False);
       end;
       Inc(TableHeadCount);
    end;
end;

procedure TExcelSimpleRpt.LogRng(Sheet : _WorkSheet; StartRow, EndRow : integer; InS : boolean);
var I, J  : integer;
    S : string;
begin
   for I := StartRow to EndRow do
   begin
{     if InS then
       S := 'in  '
     else
       S := 'out ';}
     S := IntToStr(StartRow) + ' - ';
     for J := 1 to MaxCol do
     begin
       S := S + Sheet.Cells.Item[ I, J ].Text + ' | ';
     end;
     Log(S);
   end;
end;

function TExcelSimpleRpt.AddPageSection(SecNo : integer; AQuery : TRepQuery; Supressed : boolean) : PPageSection;
begin
   Result := @PageSections[ PageSectionCount ];
   with Result^ do
   begin
     InSection     := @Sections[ SecNo ];
     OutStartRow   := OutCurrentRow;
     WasSupressed  := Supressed;
     HeadCount     := TableHeadCount;
     Query := AQuery;
     if Assigned(Query) then
       QueryRecNo := AQuery.RecNo;
     if InSection.SectionType = stTableHead then
       AddPageHead(InSection, OutCurrentRow);
   end;
   Inc(PageSectionCount);
end;

procedure TExcelRpt.InfoMessage(Message : string; Err : TErrType = etFatal);
var Msg : PChar;
begin
  if (WndHandle <> 0) and (DoneMsg <> 0) then
  begin
    Msg := StrAlloc(Length(Message) + 3);
    Msg := StrPCopy(Msg, MsgTag + Message);
    PostMessage(WndHandle, DoneMsg, Integer(Msg), MakeLong(Ord(RptMode), Ord(Err)));
  end;
  if Err > etInfo then
    Log(Message);
end;

procedure TExcelRpt.Progress(ProgressKind : TProgressKind; Value : integer);
begin
  if (WndHandle <> 0) and (ProgrMsg <> 0) and (ProgressKind = MsgType) and (MsgProc <> Value) then
  begin
    PostMessage(WndHandle, ProgrMsg, Ord(ProgressKind), Value);
    MsgProc := Value;
  end;
end;

procedure TExcelRpt.PerformOper;
begin
  Saved := False;
  if Preview or (RptMode = rmView) then
  begin
    Saved := True;
    ShowAndWait;
  end;
  if Cancel or (RptMode = rmView) then
  else if RptMode = rmSend then
    DoSendMail
  else if RptMode = rmExcelFile then
  begin
    if not Saved then
      DoSaveAs;
  end else if RptMode = rmPrint then
    MakePrint;
end;

procedure ExtractEMails(S : TStringList);
var I, p, p_b, p_e : integer;
begin
  I := 0;
  while I < S.Count do
  begin
    p := pos('@', S[ I ]);
    if (p < 1) then S.Delete(I) else
    begin
      p_b := p;
      p_e := p;

      while (p_b > 1) and
        (S[ I ][ p_b - 1] in ['a'..'z','A'..'Z','0'..'9','.','-','_']) do
      Dec(p_b);

      while (p_e < length(S[ I ])) and
        (S[ I ][ p_e + 1] in ['a'..'z','A'..'Z','0'..'9','.','-','_']) do
      inc(p_e);

      S[ I ] := copy(S[ I ], p_b, p_e - p_b + 1);
      Inc(I);
    end;
  end;
end;

function TExcelRpt.GetParm(Nm : string) : Variant;
var Param : TParam;
begin
  Param := CallParams.FindParam(Nm);
  if Param <> nil then
    Result := Param.Value;
end;

procedure TExcelRpt.DoSendMail;
var S : TStringList;
    I : integer;
    V : OleVariant;
begin
  if (Recipients = '') or (Subject = '') then
    Fatal('Не указаны Recipient и Subject');
  DisplayAlerts[ LOCALE_USER_DEFAULT ] := True;
  try
    if not Logged then
    begin
      if (UserPass <> '') and (UserName <> '') then
        MailLogon(UserName, UserPass)
      else
        MailLogon;
      Logged := True;
    end;

    Recipients := StringReplace(Recipients, ';', ',', [rfReplaceAll]);
    S := TStringList.Create;
    try
      S.CommaText := Recipients;
      ExtractEMails(S);
      V := VarArrayCreate([ 0, S.Count - 1 ], varVariant);
      for I := 0 to S.Count - 1 do
        V[ I ] := S[ I ];
      Book.SendMail(V, Subject, EmptyParam, 0);
    finally
      S.Free;
    end;
  finally
    DisplayAlerts[ LOCALE_USER_DEFAULT ] := False;
  end;
end;

procedure TExcelRpt.DoSave;
begin
  Book.Save(LOCALE_USER_DEFAULT);
end;

procedure TExcelRpt.DoSaveAs;
var Dir : string;
begin
  Dir := ExtractFilePath(OutName);
  if Dir <> '' then
  try
    ForceDirectories(Dir);
  except
    on E:Exception do
      Fatal('Can"t create dir : ' + Dir + ' : ' + E.Message);
  end;
  try
    Book.SaveAs(OutName + '.xls', null, null,
                   null, False,
                   False, {xlShared}xlExclusive,
                   null, null,
                   null, null, null, LOCALE_USER_DEFAULT);
  except
    on E:Exception do
      Fatal('Can"t save to file : ' + OutName + '.xls : ' + E.Message);
  end;
//  Log('saved : ' + OutName);
end;

procedure TExcelSimpleRpt.After_Execute;
begin
  if (Quest <> '') and (MessageDlg(Quest, mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then
     Exit;
  if (AfterExecute <> '') and Assigned(Connection) then
    try
      Connection.ExecSQL(AfterExecute, 120);
    except
      on E:Exception do Warn('Выполнено без регистрации : ' + E.Message);
    end;
end;

procedure TExcelRpt.MakePrint;
begin
  Book.PrintOut(null, null, 1, False,
                       null, null, null,
                       null, LOCALE_USER_DEFAULT);
end;

{procedure TExcelSimpleRpt.MakePrint;
var I : integer;
begin
  if not EmptyData then
    for I := 0 to SheetCount - 1 do
      with Book.WorkSheets[ I + 1 ] as _WorkSheet do
        PrintOut(1, LastRows[ I ] - 1, 1, False,
                       null, null, True,
                       null, LOCALE_USER_DEFAULT);
end;
}
procedure TExcelRpt.SheetActivate(ASender: TObject; const Sh: IDispatch);
begin
  ActiveWindow.DisplayGridlines := ShowGridLines;
end;

procedure TExcelRpt.WorkbookBeforeClose(ASender: TObject; const Wb: ExcelWorkbook;
                             var Cancel: WordBool);
begin
  if Wb = Book then
  begin
    Cancel := True;
    SetEvent(RptClosed);
  end;
end;

procedure TPasteStream.Clear(EstimateSize : Longint);
begin
  EstimateSize := (EstimateSize div $4000 + 1) * $4000;
  if (FEstimateSize < EstimateSize) and Assigned(FMemory) then
  begin
    GlobalFreePtr(FMemory);
    FMemory := nil;
    FCapacity := 0;
  end;
  FEstimateSize := EstimateSize;
  FPosition := 0;
end;

constructor TPasteStream.Create;
begin
  inherited Create;
end;

destructor TPasteStream.Destroy;
begin
  if Assigned(FMemory) then
    GlobalFreePtr(FMemory);
  inherited Destroy;
end;

procedure TPasteStream.IncCapacity;
begin
  if Assigned(FMemory) then
  begin
    Inc(FCapacity, FEstimateSize shr 2);
    FMemory := GlobalReallocPtr(FMemory, FCapacity, GMEM_MOVEABLE + GMEM_DDESHARE);
  end else
  begin
    FCapacity := FEstimateSize;
    FMemory   := GlobalAllocPtr(GMEM_MOVEABLE + GMEM_DDESHARE, FCapacity);
  end;
  if FMemory = nil then raise EStreamError.Create('MemoryStreamError');
end;

procedure TPasteStream.WriteItem(S : string);
var
  Pos, Count : Longint;
  R : WideString;
begin
  if (Length(S) > 2) and (System.Pos(#13#10, S) <> 0) then
    S := StringReplace(S, #13#10, '', [rfReplaceAll]);
  R := WideString(S);
  Count := Length(R) * 2;
  Pos   := FPosition + Count;
  if Pos > FCapacity then
    IncCapacity;
  System.Move(R[ 1 ], Pointer(Longint(FMemory) + FPosition)^, Count);
  FPosition := Pos;
end;

procedure TPasteStream.WriteTab;
begin
  WriteItem(#9);
end;

procedure TPasteStream.WriteLine;
begin
  WriteItem(#13#10);
end;

procedure TPasteStream.CopyToClipBoard;
begin
  WriteItem(#0);
  TClip(Clipboard).SetBuffer(CF_UNICODETEXT, Memory^, Size);
end;

constructor TExcelSimpleRpt.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  OpenedCDS := TObjectList.Create;
  CallParams:= TParams.Create;
  Str       := TPasteStream.Create;
  ParamCDS  := TxClientDataSet.Create(nil);
  ParamCDS.FetchOnDemand := False;
end;

destructor TExcelSimpleRpt.Destroy;
begin
  ParamCDS.Free;
  CallParams.Free;
  OpenedCDS.Free;
  Str.Free;
//  Log('Quited');
  inherited Destroy;
end;

procedure TExcelRpt.SetCancel(Value : boolean);
begin
  FCancel := True;
//  if Visible[ LOCALE_USER_DEFAULT ] then
//    SetEvent(RptClosed);
end;

procedure TExcelSimpleRpt.DoPrint;
var
  Stream     : TTestStream;
  SheetNo    : integer;

  MaxSheetCols: array of SmallInt;
  FreeRow     : SmallInt;
  PageHeader : integer;
  Breaking   : boolean;
  BottTitle  : integer;
  I, J, N : integer;
  BreakDoc, NewDoc  : boolean;
  SectionNo  : integer;
  pntPageHeight, SheetPageHeight, PrintedHeight : Double;
  SectionCount : SmallInt;
  DocCount     : integer;
//  StartTime    : TDateTime;
  TmpFont       : TFont;
  PointsInPixel : Double;
  ExprCount, ExprRow  : SmallInt;
  Expr : string;
  ColWidth : array of TColWidth;

  procedure NewOutSheet;
  var N, I : integer;
  begin
    with Book do
    begin
      N := Worksheets.Count;
      InSheet.Copy(null, Worksheets[ N ], LOCALE_USER_DEFAULT);
      OutSheet := Worksheets[ N + 1 ] as _Worksheet;
      OutSheet.Cells.Delete(null);
      if SheetName <> nil then
         OutSheet.Name := SheetName.AsString;
      for I := 1 to MaxSheetCol - DataCol + 1 do
        OleVariant(OutSheet).Columns[ I ].ColumnWidth :=
            ColWidth[ CurrSheetNo ][ I - 1 ];
      OutCurrentRow := 1;
      OutSheetCells := OutSheet.Cells;
      vOutSheet     := OutSheet;
    end;
  end;

  function MainTable : boolean;
  var I : integer;
  begin
    Result := True;
    for I := 0 to SectionCount - 1 do with Sections[ I ] do
      if (SectionType = stTableData) and (TableInfos[ TableIndex ].Query = MainDataSet) then
        Exit;
    Result := False;
  end;

  function GetFormulaSupressedValue(Formula : PCellFormula; First : boolean; var Supressed : boolean) : Variant;
  var PrevV: Variant;
      Prev : OleVariant;
      Equ  : boolean;
  begin
    Supressed := False;
    with Formula^ do
    begin
{      if SupressDupl then
      begin
        Result := GetFormulaValue(Formula);
        Log('Supr : ' + VarToStr(Result));
      end else}
      Result := GetFormulaValue(Formula);
      if SupressDupl then
      begin
        if not First then
        begin
          if DataType = dtExpr then
          begin
            Prev  := Sheet1Cells.Item[ ExprRow, NameCol - 1 ];
            PrevV := Prev.Value2;
          end else
            PrevV := GetFormulaPrevValue(Formula);
          try
            Equ  := (Result = PrevV);
          except
            Equ  := False;
          end;
        end else
        begin
          Equ := False;
          if DataType = dtExpr then
          begin
            Prev  := Sheet1Cells.Item[ ExprRow, NameCol - 1 ];
//            ShowMessage(IntToStr(Formula.ExprRow));
          end;
        end;
        if Equ then
        begin
          Supressed := True;
          Result := null;
        end else if DataType = dtExpr then
          Prev.Value2 := Result;
      end;
    end;
  end;

  procedure BottomReplaceValues(Section : PSection);
  var I : integer;
  begin
    with Section^ do
    begin
      for I := 0 to FormulaCount - 1 do with Formulas[ I ] do
        if not (DataType in [dtPageOf, dtPageOfExpr]) then
        try
          InSheet.Cells.Item[ Row, Col + DataCol - 1 ].Value := GetFormulaValue(@Formulas[ I ])
        except
        end;
    end;
  end;

  function ReplaceValues(Section : PSection; NotSupress : boolean) : boolean;
  var I, tRow : integer;
      Supr :  boolean;
  begin
    Result := False;
    with Section^ do
    begin
      if SectionType <> stTableData then
        for I := 0 to FormulaCount - 1 do with Formulas[ I ] do
        begin
          OutSheetCells.Item[ Row - StartRow + OutCurrentRow, Col ].Value := GetFormulaValue(@Formulas[ I ])
        end
      else for I := 0 to FormulaCount - 1 do with Formulas[ I ] do
      begin
        tRow := Row - StartRow + OutCurrentRow;
        OutSheetCells.Item[ tRow, Col ].Value := GetFormulaSupressedValue(@Formulas[ I ], NotSupress, Supr);
      end;
    end;
  end;

  function CountRowHeight(SheetCells : ExcelRange; nRow, nCol, MergedWidth, RowHeight : Double) : Double;
  var ScreenDC : HDC;
      S        : string;
      hOldFont : THandle;
      MaxPixWidth, Len : integer;
      ExFont      : OleVariant;
      R           : TRect;
      TM          : TTextMetric;
      Style       : TFontStyles;
  const
      Flags  = DT_CALCRECT or DT_TOP or DT_LEFT or DT_WORDBREAK or DT_EXPANDTABS or DT_NOPREFIX;
  begin
     Result := 0;
     S  := SheetCells.Item[ nRow, nCol ].Value;
     if Pos(#13, S) <> 0 then
     begin
       S := StringReplace(S, #13, '', [rfReplaceAll]);
       SheetCells.Item[ nRow, nCol ].Value := S;
     end;
     if Trim(S) = '' then
       Exit;
     Len := Length(S);
     if S[ Len ] = #10 then
       Dec(Len);
     MaxPixWidth   := Trunc(MergedWidth / PointsInPixel);
     ExFont        := SheetCells.Item[ nRow, nCol ].Font;
     TmpFont.Name  := ExFont.Name;
     TmpFont.Size  := ExFont.Size;
     Style := [];
     if ExFont.Bold = 1 then
       Include(Style, fsBold);
     if ExFont.Italic = 1 then
       Include(Style, fsItalic);
     if ExFont.Underline = 2 then
       Include(Style, fsUnderline);
     TmpFont.Style := Style;
     ScreenDC := GetDC(0);
     if ScreenDC = 0 then
       Fatal('ScreenDC = 0');
     try
       hOldFont := SelectObject(ScreenDC, TmpFont.Handle);
       R.Left   := 0;
       R.Top    := 0;
       R.Right  := MaxPixWidth;
       R.Bottom := 0;
       DrawText(ScreenDC, PChar(S), Len, R, Flags);
       GetTextMetrics(ScreenDC, TM);
       Result := Round(R.Bottom / TM.tmHeight) * RowHeight;
       SelectObject(ScreenDC, hOldFont);
     finally
       ReleaseDC(0, ScreenDC);
     end;
  end;

  procedure DoAutoFit(Section : PSection);
  var I, J, nRow, OutRow : integer;
      OrgRowHeight, RowHeight, tHeight, MaxHeight : Double;
      OutRowRng  : ExcelRange;
  begin
    with Section^ do
    begin
      SectionHeight := 0;
      for nRow := StartRow to EndRow do
      begin
        OutRow := nRow - StartRow + OutCurrentRow;
        OutRowRng := OutSheet.Range[ CellRC(OutRow, 1), CellRC(OutRow, MaxCol) ];
        RowHeight := -100;
        for I := 0 to MergeCount - 1 do
          if nRow = Merges[ I ].Row then
          begin
            OrgRowHeight := Merges[ I ].RowHeight;
            MaxHeight    := 0;
            for J := I to MergeCount - 1 do with Merges[ J ] do
              if nRow = Row then
              begin
                tHeight   := CountRowHeight(OutSheetCells, OutRow, Col - DataCol + 1, CellWidth, RowHeight);
                MaxHeight := Max(MaxHeight, tHeight);
              end;
            if MaxHeight < OrgRowHeight then
              RowHeight := OrgRowHeight
            else
              RowHeight := MaxHeight;
            Break;
          end;
        if RowHeight = -100 then //if Breaking then
          RowHeight := RowHeights[ nRow - StartRow ];
        OutRowRng.RowHeight := RowHeight;
        SectionHeight := SectionHeight + RowHeight;
      end;
    end;
  end;

  procedure BottomAutoFit(Section : PSection);
  var I, J, nRow : integer;
      OrgRowHeight, RowHeight, tHeight, MaxHeight : Double;
  begin
    with Section^ do
    begin
      SectionHeight := 0;
      for nRow := StartRow to EndRow do
      begin
        RowHeight := -100;
        for I := 0 to MergeCount - 1 do
          if nRow = Merges[ I ].Row then
          begin
            OrgRowHeight := Merges[ I ].RowHeight;
            MaxHeight    := 0;
            for J := I to MergeCount - 1 do with Merges[ J ] do
              if nRow = Row then
              begin
                tHeight   := CountRowHeight(InSheet.Cells, nRow, Col, CellWidth, RowHeight);
                MaxHeight := Max(MaxHeight, tHeight);
              end;
            if MaxHeight < OrgRowHeight then
              RowHeight := OrgRowHeight
            else
              RowHeight := MaxHeight;
            Break;
          end;
        if RowHeight <> -100 then
          RowHeights[ nRow - StartRow ] := RowHeight;
        SectionHeight := SectionHeight + RowHeights[ nRow - StartRow ];
      end;
    end;
  end;

  procedure SkipSection(var nSec : integer);
  var SecType : TSectionType;
  begin
    SecType := Sections[ nSec ].SectionType;
    while (nSec < SectionCount) and (Sections[ nSec ].SectionType = SecType) do
      Inc(nSec);
  end;

  function FindEndTableSection(nSec : integer; Lev : integer) : integer;
  var TabInd : integer;
      StartSec : integer;
  begin
    StartSec := nSec;
    TabInd := Sections[ nSec ].TableIndex;
    while (nSec < SectionCount) and (Sections[ nSec ].SectionType in [ stTableQuery..stTableSubTotal ]) do
      Inc(nSec);
    Dec(nSec);
    while (Sections[ nSec ].TableIndex <> TabInd) do
      Dec(nSec);
    while (nSec > StartSec) do with Sections[ nSec ] do
      if (SectionType in [ stTableData..stTableSubTotal ]) and
         (TableIndex = TabInd) and (Level < Lev) or (TableIndex <> TabInd) then
        Dec(nSec)
      else
        Break;
    if (Sections[ nSec ].SectionType in [ stTableQuery..stTableHead ]) then
      Fatal('Section sequence error');
    Result := nSec;
  end;

  procedure InsertClearRows(const AStart, AEnd : integer);
  var I : integer;
  begin
    for I := AStart to AEnd do
      vOutSheet.Rows[ OutCurrentRow ].Insert(xlShiftDown);
    OutSheet.Range[ CellRC(OutCurrentRow, 1), CellRC(OutCurrentRow + AEnd - AStart, MaxCol) ].Clear;
  end;

  function OutSection(SecNo : integer; FirstInGroup : boolean = False; Query : TRepQuery = nil) : boolean;
    forward;

  procedure PutSection(SecNo : integer; NotSupress : boolean; Query : TRepQuery = nil);
  var Supressed : boolean;
  begin
    if Cancel then
      Abort;
    with Sections[ SecNo ] do
    begin

      if Breaking then
        InsertClearRows(StartRow, EndRow);

      Supressed := False;
      if Embed then
        DoEmbed(@Sections[ SecNo ])
      else
      begin
        InSheet.Range[ CellRC(StartRow, DataCol), CellRC(EndRow, MaxSheetCol) ].Copy(OutSheetCells.Item[ OutCurrentRow, 1 ]);
        Supressed := ReplaceValues(@Sections[ SecNo ], NotSupress);
      end;

      DoAutoFit(@Sections[ SecNo ]);

      if not Breaking and not NoPaging and (PageHeader <> -1) then
        AddPageSection(SecNo, Query, Supressed);

      Inc(OutCurrentRow, EndRow - StartRow + 1);
      PrintedHeight := PrintedHeight + SectionHeight;
    end;
  end;

  procedure RollBackAndBreakPage; forward;

  procedure SetBottom;
  var I   : integer;
      Sec : PSection;
      Tag : string;
  begin
    if NoPaging then
      Exit;
    I := SectionNo;
    while I < SectionCount do
      if Sections[ I ].SectionType = stBottomTitle then
        Break
      else
        Inc(I);
    if (I < SectionCount) and (BottTitle <> I) then
    begin
      Sec := @Sections[ I ];
      BottomReplaceValues(Sec);
      BottomAutoFit(Sec);
      with Sec^ do
      begin
//   LogRng(InSheet, StartRow, EndRow, True);
        Tag := Trim(InSheet.Cells.Item[ StartRow, 2 ].Text);
        if (PrintedHeight >= SheetPageHeight - SectionHeight) and (Tag = 'L') and not NoPaging  and (PageHeader <> -1) then
          RollBackAndBreakPage;
        pntPageHeight := SheetPageHeight - SectionHeight;
        BottTitle   := I;
        PageOfOfs   := -1;
        for I := 0 to FormulaCount - 1 do with Formulas[ I ] do
          if DataType in [dtPageOf, dtPageOfExpr] then
          begin
            PageOfOfs := Row - StartRow;
            PageOfCol := Col;
            PageOfForm:= @Formulas[ I ];
            Break;
          end;
        if (PrintedHeight >= pntPageHeight) and not NoPaging  and (PageHeader <> -1) then
          RollBackAndBreakPage;
       end;
     end;
  end;

  procedure OutBottomTitle;
  var Height : Double;
      I, N   : integer;
  begin
    if NoPaging then
      Exit;
    if (BottTitle <> -1) then
    begin
      Height := pntPageHeight - PrintedHeight - 0.5;
      if Height > 2 then
      begin
        if Height > 100 then
          N := Trunc(Height / 100) + 1
        else
          N := 1;
        Height := Height / N;
        if Breaking then
          InsertClearRows(1, N);
        for I := 1 to N do
          vOutSheet.Rows[ OutCurrentRow + I - 1 ].RowHeight := Height;
        Inc(OutCurrentRow, N);
      end;
      if PageOfOfs <> -1 then
      begin
        if PageNo > Length(PageOfInfo) then
          SetLength(PageOfInfo, PageNo + 10);
        with PageOfInfo[ PageNo - 1 ] do
        begin
          Row := OutCurrentRow + PageOfOfs;
          Col := PageOfCol;
          Formula := PageOfForm;
        end;
      end;
      with Sections[ BottTitle ] do
      begin
//        Log(' put bott ' + IntToStr(StartRow) + ':' + IntToStr(EndRow));
        if Breaking then
          InsertClearRows(StartRow, EndRow);

        InSheet.Range[ CellRC(StartRow, DataCol), CellRC(EndRow, MaxSheetCol) ].Copy(OutSheetCells.Item[ OutCurrentRow, 1 ]);
        for I := 1 to EndRow - StartRow  + 1 do
          vOutSheet.Rows[ OutCurrentRow + I - 1 ].RowHeight := RowHeights[ I - 1 ];

        Inc(OutCurrentRow, EndRow - StartRow + 1);
        PrintedHeight := PrintedHeight + SectionHeight;
      end;
    end;
    Inc(PageNo);
    if BreakDoc then
    begin
      if PageOfOfs <> -1 then
        for I := 1 to PageNo - 1 do
        begin
          SetValue(PageOfRow, PageNo - 1);
          SetValue(PageNoRow, I);
          with PageOfInfo[ I - 1 ] do
            OutSheetCells.Item[ Row, Col ].Value2 :=
                GetFormulaValue(Formula);
        end;
      PageNo := 1;
    end;
    BreakDoc := False;
    SetValue(PageNoRow, PageNo);
    PrintedHeight := 0;
  end;

  procedure CopyHeader(Head : THeadRange);
  var Rng : ExcelRange;
      I, OutRow, Len : integer;
  begin
    with Head do
    begin
      Len := OutEndRow - OutStartRow;
      InsertClearRows(OutStartRow, OutEndRow);
      Rng := OutSheet.Range[ CellRC(OutStartRow, 1), CellRC(OutEndRow, MaxCol) ];
//   LogRng(OutSheet, OutStartRow, OutEndRow, True);
      Rng.Copy(OutSheetCells.Item[ OutCurrentRow, 1 ]);
      OutRow := OutCurrentRow;
      for I := OutStartRow to OutEndRow do
      begin
        vOutSheet.Rows[ OutRow ].RowHeight := vOutSheet.Rows[ I ].RowHeight;
        Inc(OutRow);
      end;
      OutStartRow := OutCurrentRow;
      OutEndRow   := OutStartRow + Len;
      Inc(OutCurrentRow, Len + 1);
      PrintedHeight := PrintedHeight + SectionHeight;
    end;
  end;

  procedure OutPageHeader;
  var N : integer;
  begin
    if PageHeader = -1 then
      Exit;
//      Fatal('PageHeader not found');
    N := PageHeader;
    while Sections[ N ].SectionType = stPageHeader do
    begin
      if ((PageNo = 1) or not Sections[ N ].SkipInContinue) and Cond(@Sections[ N ]) then
        PutSection(N, True);
      Inc(N);
    end;
  end;

  procedure SkipPageHeader;
  begin
    while Sections[ SectionNo ].SectionType = stPageHeader do
      Inc(SectionNo);
    Dec(SectionNo);
  end;

  function RollBackSections(SecNo : integer) : integer;

  function TableDataRollBacked : boolean;
  var Ind, Lev, N  : integer;
      SecType : TSectionType;
  begin
    N := 0;
    with PageSections[ SecNo ].InSection^ do
    begin
      Ind := TableIndex;
      Lev := Level;
    end;
    while (N < 3) and (SecNo >= N) do with PageSections[ SecNo - N ].InSection^ do
    begin
      if (SectionType = stTableData) and
         (Ind = TableIndex) and
         (Lev = Level) then
        Inc(N)
      else
        Break;
    end;
    Result := N >= 2;
    if not Result then
    begin
      Dec(SecNo, N);
      if SecNo < 0 then
        Fatal('rollback error');
      SecType := PageSections[ SecNo ].InSection.SectionType;
      if (SecType = stTableTotal) or
         (SecType = stTableData) and (PageSections[ SecNo ].InSection.Level < Lev) then
      begin
        Inc(SecNo);
        Result := True;
      end;
    end;
  end;

  procedure SkipSame;
  var SecType : TSectionType;
  begin
    SecType := PageSections[ SecNo ].InSection.SectionType;
    while (SecNo >= 0) and (PageSections[ SecNo ].InSection.SectionType = SecType) do
      Dec(SecNo);
  end;

  begin
    while SecNo >= 0 do with PageSections[ SecNo ].InSection^ do
    begin
      case SectionType of
        stTableHead  :
        begin
          SkipSame;
          Inc(SecNo);
          Break;
        end;
        stTableTotal :
          SkipSame;
        stTableData  :
          if TableDataRollBacked then
            Break;
        stPageFooter :
          SkipSame;
        else
          if not CanBreak then
            Dec(SecNo)
          else
            Break;
      end;
    end;
    Result := SecNo;
    if SecNo < 0 then
      Fatal('rollback error');
  end;

  procedure RollBackAndBreakPage;
  var I : integer;
      BreakRow, RollBackSecNo : integer;
      OverHeight : Double;
      SaveRecNo  : integer;
      FirstRec   : boolean;
      OnEOF      : boolean;
  begin
    RollBackSecNo := RollBackSections(PageSectionCount - 1);
    OverHeight  := 0;
    for I := RollBackSecNo to PageSectionCount - 1 do
      OverHeight := OverHeight + PageSections[ I ].InSection.SectionHeight;
    if PrintedHeight < OverHeight then
    begin
      RollBackSecNo := PageSectionCount - 1;
      OverHeight := PageSections[ RollBackSecNo ].InSection.SectionHeight;
    end;
    Breaking      := True;
    OutCurrentRow := PageSections[ RollBackSecNo ].OutStartRow;
    PrintedHeight := PrintedHeight - OverHeight;
    OutBottomTitle;
//    if PageNo > 3 then
//      Abort;
    BreakRow      := OutCurrentRow;
    OutPageHeader;
    TableHeadCount := PageSections[ RollBackSecNo ].HeadCount;
    for I := 0 to TableHeadCount - 1 do
      CopyHeader(TableHeadList[ I ]);
    FirstRec := True;
    for I := RollBackSecNo to PageSectionCount - 1 do
      with PageSections[ I ] do
      begin
        if InSection.SectionType = stTableData then
        begin
          if WasSupressed then
          begin
            OnEOF := Query.EOF;
            SaveRecNo   := Query.RecNo;
            Query.RecNo := QueryRecNo;
            Query.SetValues;
            ReplaceValues(InSection, FirstRec);
            Query.RecNo := SaveRecNo - 1;
            Query.SetValues;
            Query.Next;
            Query.SetValues;
            if OnEOF then
              Query.Next;
            DoAutoFit(InSection);
          end;
          FirstRec    := False;
        end else if InSection.SectionType = stTableHead then
          AddPageHead(InSection, OutCurrentRow);
        with InSection^ do
          Inc(OutCurrentRow, EndRow - StartRow + 1);
        PrintedHeight := PrintedHeight + InSection.SectionHeight;
      end;
    if HasPrinter then
      OutSheet.HPageBreaks.Add(vOutSheet.Rows[ BreakRow ]);
    PageSectionCount := 0;
    Breaking := False;
  end;

  function OutSection(SecNo : integer; FirstInGroup : boolean = False; Query : TRepQuery = nil) : boolean;
  var NotSupress : boolean;
  begin
    Result := Cond(@Sections[ SecNo ]);
    if not Result then
    begin
//      Log('Sec row cond false : ' + IntToStr(Sections[ SecNo ].StartRow));
      Exit;
    end;
//    Log('Sec row : ' + IntToStr(Sections[ SecNo ].StartRow));
    with Sections[ SecNo ] do
    begin
      if (PageBreak or NewDoc) and not Breaking then
      begin
        if OutCurrentRow > 1 then
        begin
          OutBottomTitle;
          if SheetName <> nil then
            NewOutSheet
          else if HasPrinter then
            OutSheet.HPageBreaks.Add(vOutSheet.Rows[ OutCurrentRow ]);
        end;
        OutPageHeader;
        SetBottom;
        PageSectionCount := 0;
        NewDoc := False;
      end;
      NotSupress := (SectionType <> stTableData) or FirstInGroup;
    end;

    PutSection(SecNo, NotSupress);

    if (PrintedHeight >= pntPageHeight) and not Breaking and not NoPaging  and (PageHeader <> -1) then
      RollBackAndBreakPage;
  end;

  procedure PutHeader;
  begin
    with Sections[ PageHeader ] do
    begin
      if PageBreak then
      begin
        OutBottomTitle;
        if HasPrinter then
          OutSheet.HPageBreaks.Add(vOutSheet.Rows[ OutCurrentRow ]);
      end;
    end;
    OutPageHeader;
    SetBottom;
    PageSectionCount := 0;
  end;

  procedure OutSpacer;
  begin
    with Sections[ SectionNo ] do
    begin
      if (PrintedHeight <> 0) and (PrintedHeight + SectionHeight < pntPageHeight) then
        OutSection(SectionNo);
    end;
  end;

  function OutTable(SectNo, Lev : integer) : integer;
  var DataSet   : TRepQuery;
      TabIndex  : integer;
      TabInfo   : PTableInfo;
      FirstData : boolean;
      SecNo     : integer;
      StartSectionNo : integer;
      EndSectionNo   : integer;
      SaveHeadCount  : integer;
      EndLoop        : integer;
      Cell    : OleVariant;
      I, J    : integer;
      PSec    : PSection;
      FitCol  : boolean;

    function NeedFit(V : OleVariant) : boolean;
    begin
      Result := (VarType(V) > varNull) and
           ((VarType(V) = varBoolean) and V or
           (V = msoTrue) or (V = msoCTrue) or (V = msoTriStateMixed));
    end;

    procedure NextSec;
    begin
      Inc(SecNo);
      if SecNo >= SectionCount then
        Fatal('Bad section sequence');
    end;

    procedure SequenceError;
    begin
      Fatal('Section sequence error : row = ' + IntToStr(Sections[ SecNo ].StartRow));
    end;

    procedure IncRecNo;
    begin
      Inc(TabInfo.RecNos[ Lev ], 1);
      SetValue(TabInfo.RecNoRows[ Lev ], TabInfo.RecNos[ Lev ]);
      if Lev > 0 then
      begin
        Inc(TabInfo.RecCounts[ Lev ], 1);
        SetValue(TabInfo.RecCountRows[ Lev ], TabInfo.RecCounts[ Lev ]);
      end;
    end;

    function SuprSumFld : boolean;
//    var I : integer;
    begin
{      Result := True;
      with Sections[ StartSectionNo ] do
      begin
        for I := 0 to FormulaCount - 1 do
          if Formulas[ I ].SupressDupl then
            Exit;
      end;}
      Result := False;
    end;

    procedure RangeFill;
    var Sect : PSection;
        I, J, N : integer;
//        Supressed, First : boolean;
//        OutRng  : ExcelRange;
        OutRng  : OleVariant;
        FirstRow : integer;
        TotalList: Variant;
        Funct, sCount, TotCol : integer;
    begin
//      First := True;
      FirstRow := OutCurrentRow;
      Sect := @Sections[ StartSectionNo ];
      repeat
        N  := DataSet.RecordCount;
        OutRng := OutSheet.Range[ CellRC(OutCurrentRow, 1), CellRC(OutCurrentRow + N - 1, MaxCol) ];
        InSheet.Range[ CellRC(Sect.StartRow, DataCol), CellRC(Sect.StartRow, MaxSheetCol) ].Copy(null);
        OutRng.PasteSpecial(xlPasteFormats, xlNone, False, False);
        OutRng.RowHeight := Sect.SectionHeight;
        Str.Clear(N * MaxCol * 16);
        sCount := Sect.FormulaCount - 1;
        for I := 0 to N - 1 do
        begin
          if Cond(Sect) then
          begin
            for J := 0 to sCount do
            begin
              Str.WriteItem(GetFormulaStrValue(@Sect.Formulas[ J ]));
              if J <> sCount then
                Str.WriteTab;
            end;
            Str.WriteLine;
            IncRecNo;
            Inc(OutCurrentRow);
            PrintedHeight := PrintedHeight + Sect.SectionHeight;
//            First := False;
          end;
          Progress(pkRecord, 100 * DataSet.RecNo div N);
          DataSet.SetNextForSect(Sect);
        end;
        Str.CopyToClipBoard;
        OleVariant(OutRng).PasteSpecial(null); // UNICODE
      until not DataSet.LoadPackets(True);
      if (StartSectionNo + 1 < SectionCount) and (Sections[ StartSectionNo + 1 ].SectionType = stTableSubTotal) then
      begin
//        OutRng := OleVariant(OutSheet).Rows[ IntToStr(FirstRow) + ':' + IntToStr(OutCurrentRow - 1)];
        TotCol := 0;
        with Sections[ StartSectionNo + 1 ] do
        begin
          N := 0;
          while (N < Length(SetFields)) and (SetFields[ N ] <> 0) do
            Inc(N);
          J := N + 1;
          if J >= Length(SetFields) then
            TotalList := null
          else
          begin
            TotalList := VarArrayCreate([ 0, Length(SetFields) - J - 1 ], varInteger);
            I := 0;
            for J := J to Length(SetFields) - 1 do
            begin
              TotalList[ I ] := SetFields[ J ];
              if TotalList[ I ] > TotCol then
                TotCol := TotalList[ I ];
              Inc(I);
            end;
          end;
          if TotCol = 0 then
            TotCol := MaxCol;
          OutRng := OutSheet.Range[ CellRC(FirstRow, 1), CellRC(OutCurrentRow - 1, TotCol) ];
          Funct := CondRow;
          for I := 0 to N - 1 do
          begin
            OutRng.Subtotal(SetFields[ I ], FuncCodes[ Funct ], TotalList, I = 0, False, xlSummaryBelow);
          end;
        end;
        OutCurrentRow := OutSheet.UsedRange[ LOCALE_USER_DEFAULT ].Rows.Count + 1;
      end;
    end;
 

    procedure FastOut(NoPages : boolean);
    var Sect : PSection;
        I, J, N, No, Cnt : integer;
        Tab   : Variant;
        WasSupressed, Supressed, First : boolean;
//        NumCols : integer;
        OutRng  : ExcelRange;
    begin
{      if PrintedHeight > pntPageHeight then
          ShowMessage(')))');}
      Sect := @Sections[ StartSectionNo ];
      repeat
        No := DataSet.RecNo;
        if NoPages then
          I := 1000
        else
          I  := Trunc((pntPageHeight - PrintedHeight) / Sect.SectionHeight);
        if I > 0 then
        begin
          N := 1;
//DataSet.SaveToFile('sss');
          DataSet.SetKeyValues;
          while (N <> I) do
          begin
            DataSet.Next;
//            DataSet.SetKeyValues;
            if not DataSet.EOF and DataSet.SameKey then
              Inc(N)
            else
              Break
          end;
//          NumCols:= TabInfo.MaxCol - DataCol + 1;
{    Rows("5:5").Select
    Selection.Copy
    Range("9:9,11:11,13:13").Select
    Selection.PasteSpecial Paste:=xlPasteAll, Operation:=xlNone, SkipBlanks:= _
        False, Transpose:=False
}
          OutRng := OutSheet.Range[ CellRC(OutCurrentRow, 1), CellRC(OutCurrentRow + N - 1, MaxCol) ];
          InSheet.Range[ CellRC(Sect.StartRow, DataCol), CellRC(Sect.StartRow, MaxSheetCol) ].Copy(null);
          try
            OutRng.PasteSpecial(xlPasteFormats, xlNone, False, False);
          except
            Li('N', N);
          end;
          OutRng.RowHeight := Sect.SectionHeight;
          Tab := VarArrayCreate([ 0, N - 1, 0, MaxCol - 1 ], varVariant);
//          Log('no ' + VarToStr(No));

          DataSet.RecNo := No;
          DataSet.SetKeyValues;
          DataSet.SetValues;
          First := True;
          Cnt := 0;
          for I := 0 to N - 1 do
          begin
//          Log(VarToStr(DataSet.EOF));
//          Log(VarToStr(DataSet.RecNo));
//          Log(VarToStr(DataSet.FieldByName('clfs_Weight_Calc').Value));
            if Cond(Sect) then
            begin
              WasSupressed := False;
              for J := 0 to Sect.FormulaCount - 1 do
              begin
                Tab[ I, Sect.Formulas[ J ].Col - 1 ] :=
                   GetFormulaSupressedValue(@Sect.Formulas[ J ], First, Supressed);
                WasSupressed := WasSupressed or Supressed;
              end;
              IncRecNo;
              if not NoPages then
                AddPageSection(SecNo, DataSet, WasSupressed);
  //            SetRangeRows;
              Inc(OutCurrentRow);
              PrintedHeight := PrintedHeight + Sect.SectionHeight;
              First := False;
              Inc(Cnt);
            end;
            Progress(pkRecord, 100 * DataSet.RecNo div TabInfo.RecCount);
            DataSet.SetNextForSect(Sect);
          end;
          if Cnt <> N then
            VarArrayRedim(Tab, Cnt);
          OutRng.Value2 := Tab;
        end;
        if not NoPages and not DataSet.EOF and DataSet.SameKey then
        begin
          OutSection(StartSectionNo, False, DataSet);
          IncRecNo;
          DataSet.SetNext;
        end;
{        if PrintedHeight > pntPageHeight then
           ShowMessage(')))');}
        Progress(pkRecord, 100 * DataSet.RecNo div TabInfo.RecCount);
      until DataSet.EOF or not DataSet.SameKey;
    end;

  begin
    SecNo := SectNo;
    with Sections[ SecNo ] do
    begin
      TabIndex := TableIndex;
      TabInfo  := @TableInfos[ TableIndex ];
      TabInfo.Level := Lev;
      EndSectionNo  := FindEndTableSection(SecNo, Lev);
      if TabInfo.Skipped then
      begin
        Result := EndSectionNo;
        Exit;
      end;
      if not Assigned(TabInfo.Query) then
        Fatal('DataSet ' + TabInfo.Table + ' not Active');
      if TabInfo.RecCount = 0 then
      begin
        Result := EndSectionNo;
        if TabInfo.Query = MainDataSet then
          EmptyData := False;
        Exit;
      end;
      DataSet := TRepQuery(TabInfo.Query);
    end;
    SaveHeadCount := TableHeadCount;
    if Sections[ SecNo ].SectionType = stTableTotal then
      SequenceError;
    while (Sections[ SecNo ].SectionType = stTableHead) and (Sections[ SecNo ].Level = Lev)
       and (Sections[ SecNo ].TableIndex = TabIndex) do
    begin
      OutSection(SecNo);
      NextSec;
    end;
    TabInfo.RecNos[ Lev ] := 1;
    SetValue(TabInfo.RecNoRows[ Lev ], TabInfo.RecNos[ Lev ]);
    if Lev > 0 then
    begin
      TabInfo.RecCounts[ Lev ] := 0;
      SetValue(TabInfo.RecCountRows[ Lev ], TabInfo.RecCounts[ Lev ]);
    end;
    EndLoop := EndSectionNo;
    while (Sections[ EndLoop ].Level = Lev) and (Sections[ EndLoop ].TableIndex = TabIndex) and
      (Sections[ EndLoop ].SectionType in [stTableTotal, stTableSubTotal]) do
      Dec(EndLoop);
    FirstData := True;
    DataSet.ClearTotals;
//    DataSet.SetValues;
    DataSet.SetKeyValues;
//    RangeRowCount[ Lev ] := 0;

    StartSectionNo := SecNo;
    PSec := @Sections[ SecNo ];
// and (PSec.CondFlag <> cfCondRow)
    if((StartSectionNo = EndLoop) or (StartSectionNo + 1 = EndLoop) and (Sections[ StartSectionNo + 1 ].SectionType = stTableTotal)) and (Lev = TabInfo.NumLevels - 1) and (not PSec.HasLiteral or PSec.SkipInContinue) then
    begin
      if FirstTableOut = -1 then
      begin
        FirstTableOut := OutCurrentRow;
        SetLength(ColFits, MaxSheetCol - DataCol + 1);
        I := DataCol;
        while I <= MaxSheetCol do
        begin
          Cell := InSheet.Cells.Item[ PSec.StartRow, I ];
          try
            FitCol := NeedFit(Cell.ShrinkToFit);
          except
            FitCol := False;
          end;
          ColFits[ I - DataCol ] := FitCol;
          try
            if Cell.MergeCells then
            begin
              FitCol := False;
              ColFits[ I - DataCol ] := FitCol;
              J := Cell.MergeArea.Count - 1;
              while J > 0 do
              begin
                Inc(I);
                ColFits[ I - DataCol ] := FitCol;
                Dec(J);
              end;
            end
          except
          end;
          try
            if FitCol then
              Cell.ShrinkToFit := False;
          except
          end;
          Inc(I);
        end;
      end;
      if Sections[ SecNo ].SkipInContinue and (Lev = 0) then
      begin
        RangeFill;
      end else
        FastOut(Sections[ SecNo ].SkipInContinue or NoPaging);
    end else
    repeat
      SecNo := StartSectionNo;
      while SecNo <= EndLoop do with Sections[ SecNo ] do
      begin
        if SectionType = stTableQuery then
          CreateQuery(@Sections[ SecNo ])
        else if SectionType in [ stTableHead, stTableTotal, stTableData] then
        begin
          if TableIndex <> TabIndex then
            SecNo := OutTable(SecNo, 0)
          else if SectionType = stTableHead then
            SecNo := OutTable(SecNo, Lev + 1)
          else if SectionType = stTableTotal then
            SequenceError
          else // stTableData
          begin
            if Level = Lev then
            begin
              while (Sections[ SecNo ].Level = Lev) and (Sections[ SecNo ].TableIndex = TabIndex)
                and (Sections[ SecNo ].SectionType = stTableData) do
              begin
//                SetRangeRows;
                OutSection(SecNo, FirstData, DataSet);
                NextSec;
              end;
              Dec(SecNo);
              FirstData := False;
            end else
              SecNo := OutTable(SecNo, Lev + 1);
          end;
        end else
          SequenceError;
        NextSec;
      end;
      if Lev = TabInfo.NumLevels - 1 then
      begin
        DataSet.SetNext;
        Progress(pkRecord, 100 * DataSet.RecNo div TabInfo.RecCount);
      end;
      IncRecNo;
    until DataSet.EOF or not DataSet.SameKey;
//    CloseRangeRows;
    if (Lev = 0) and (FirstTableOut <> -1) then
    begin
      I := 0;
      while I <= MaxSheetCol - DataCol do
      begin
        if ColFits[ I ] then
        begin
          J := I;
          while (I <= MaxSheetCol - DataCol) and ColFits[ I ] do Inc(I);
          OutSheet.Range[ CellRC(FirstTableOut, J + 1), CellRC(OutCurrentRow - 1, I) ].EntireColumn.AutoFit;
        end else
          Inc(I);
      end;
    end;
    if not DataSet.EOF then
    begin
      DataSet.Prior;
      DataSet.SetValues;
    end;
    Inc(EndLoop);
    while EndLoop <= EndSectionNo do
    begin
      if Sections[EndLoop].SectionType <> stTableSubTotal then
        OutSection(EndLoop, False, DataSet);
      Inc(EndLoop);
    end;
    Breaking := False;
    if not DataSet.EOF then
    begin
      DataSet.Next;
      DataSet.SetValues;
    end;

    Dec(TabInfo.Level);

    TableHeadCount := SaveHeadCount;
    Result := EndSectionNo;
  end;

  procedure SectionSequenceError;
  begin
    Fatal('Section sequence error : row = ' + IntToStr(Sections[ SectionNo ].StartRow));
  end;

  function FindTarget(nRow : integer) : integer;
  begin
    if nRow = -1 then
    begin
      Result := SectionCount;
      Exit;
    end;
    Result := 0;
    while Result < SectionCount do with Sections[ Result ] do
      if StartRow = nRow then
      begin
        Dec(Result);
        Exit;
      end else
        Inc(Result);
    Fatal('Bad GOTO row : ' + IntToStr(nRow));
  end;

  procedure PrepareBook;
  var I, J, N : integer;
      InSheet : _WorkSheet;
      Rng   : ExcelRange;
      tName : ExcelXP.Name;
      Width : OleVariant;
  begin
    with Book, Names do
      for I := Count downto 1 do
      begin
        tName := Item(I, False, null);
        Rng := tName.RefersToRange;
        if Rng.HasFormula then
           Rng.Formula := '';
        Rng.Value2 := '';
        tName.Delete;
      end;
    for I := 1 to SheetCount do
    begin
      InSheet := Book.Worksheets[ I ] as _WorkSheet;
      for J := DataCol to MaxSheetCols[ I - 1 ] do
      begin
        Width := InSheet.Range[ CellRC(1, J), CellRC(65536, J) ].ColumnWidth;
        ColWidth[ I - 1 ] [ J - DataCol ] := Width;
      end;
      Rng     := InSheet.Cells;
      Sections    := SectionList[ I - 1];
      SectionCount:= Length(Sections);
      for J := 0 to SectionCount - 1 do with Sections [ J ] do
      begin
        if not (SectionType in [ stTableQuery, stSpacer,
             stNamesDef, stOutFile, stGOTOtrue, stGOTOfalse ]) then
          for N := 0 to FormulaCount - 1 do with Formulas[ N ] do
          begin
            Rng.Item[ Row, Col ].Formula := '';
            Dec(Col, DataCol - 1);
          end;
      end;
    end;
    CheckPageSetUp;
  end;

  procedure CheckPaging(Tag : string);
  begin
    if Pos('-', Tag) <> 0 then
      NoPaging := True
    else if Pos('+', Tag) <> 0 then
      NoPaging := False;
  end;

begin
//  StartTime := Now;
  ShrtName := ShortName(SourceBook);
  ParamCDS.Connection := Connection;
  Prepare;
  OpenData;
  if OutputFileName <> '' then
    OutName := OutputFileName
  else
    OutName := RptPath + ShrtName + '$' + FormatDateTime('yymmdd', Now);
  try
    SetLength(SheetNames, SheetCount);
    SetLength(MaxSheetCols, SheetCount);
    SetLength(LastRows, SheetCount);
    SetLength(SectionList, SheetCount);
    SetLength(pntPageHeights, SheetCount);
    SetLength(ColWidth, SheetCount);
    Stream := TTestStream.Create(True);
    with Stream do
    try
      LoadFromFile(RptPath + SourceBook + '.tls');
//      Debug := True;
      try
        for SheetNo := 0 to SheetCount - 1 do
        begin
          ReadInt('FreeRow', FreeRow);
          ReadInt('MaxSheetCol', MaxSheetCols[ SheetNo ]);
          ReadDbl('PageHeight', pntPageHeights[ SheetNo ]);
          ReadInt('SectionCount', SectionCount);
          SetLength(ColWidth[ SheetNo ], MaxSheetCols[ SheetNo ] - DataCol + 1);
          SetLength(SectionList[ SheetNo ], SectionCount);
          for I := 0 to SectionCount - 1 do with SectionList[ SheetNo ][ I ] do
          begin
            ReadInt('Level', Level);
            CondFlag := TCondFlag(ReadByte('CondFlag'));
            ReadInt('CondRow', CondRow);
            Embedded := False;
//            if CondRow <> 0 then
//              Log('CondRow = ' + IntToStr(CondRow) + '('+IntToStr(StartRow)+')');
            ReadBool('SkipInContinue', SkipInContinue);
            ReadBool('Embed', Embed);
            SectionType := TSectionType(ReadByte('SectionType'));
            ReadBool('PageBreak', PageBreak);
            ReadInt('StartRow', StartRow);
            ReadInt('EndRow', EndRow);
            ReadInt('FormulaCount', FormulaCount);
            ReadInt('MergeCount', MergeCount);
            ReadBool('CanBreak', CanBreak);
            ReadDbl('SectionHeight', SectionHeight);
            ReadInt('TableIndex', TableIndex);
            if SectionHeight <> 0 then
            begin
              SetLength(RowHeights, EndRow - StartRow + 1);
              for J := StartRow to EndRow do
                ReadDbl('RowHeight', RowHeights[ J - StartRow ]);
            end;
            HasLiteral := True;
            if (SectionType = stTableData) and (StartRow = EndRow) and (MergeCount = 0) then
            begin
              ReadBool('HasLiteral', HasLiteral);
            end;
            ReadInt('SetFieldsLen', ExprCount);
            SetLength(SetFields, ExprCount);
            ReadLevelArray('SetFields', SetFields);

            SetLength(Formulas, FormulaCount);
            SetLength(Merges, MergeCount);
            for J := 0 to FormulaCount - 1 do
            begin
              Read(Formulas[ J ], SizeOf(TCellFormula));
//              if Formulas[ J ].ExprRow <> 0 then
//                Log('ExprRow = ' + IntToStr(Formulas[ J ].ExprRow) + '('+IntToStr(StartRow)+')');
            end;
            for J := 0 to MergeCount - 1 do
            begin
              Read(Merges[ J ], SizeOf(TCellMerge));
//              Log('Merges row ' + IntToStr(Merges[ J ].Row) + ', col ' + IntToStr(Merges[ J ].Col));
            end;
          end;
        end;
        ReadInt('TableInfoCount', TableInfoCount);
        SetLength(TableInfos, TableInfoCount);
        for J := 0 to TableInfoCount - 1 do with TableInfos[ J ] do
        begin
          ReadStr('Table', Table);
          ReadStr('SQL', SQL);
          ReadInt('NumLevels', NumLevels);
          SetLength(LevelKeyLen, NumLevels);
          ReadLevelArray('LevelKeyLen', LevelKeyLen);
          ReadStr('KeyFields', KeyFields);
          SetLength(RecNoRows, NumLevels);
          SetLength(RecNos, NumLevels);
          ReadLevelArray('RecNoRows', RecNoRows);
          SetLength(RecCountRows, NumLevels);
          SetLength(RecCounts, NumLevels);
          ReadLevelArray('RecCountRows', RecCountRows);
          ReadInt('NumFields', NumFields);
          ReadInt('MaxCol', MaxCol);
          SetLength(KeyValues, NumLevels);
          SetLength(TableFlds, NumFields);
          for N := 0 to NumFields - 1 do with TableFlds[ N ] do
          begin
            ReadStr('FldName', FldName);
            ReadInt('Row', Row);
//            if row <> 0 then
//              Log('FldName : ' + FldName + ', Row' + IntToStr(Row));
            ReadBool('SumField', SumField);
            SetLength(TotalRow, NumLevels);
            ReadLevelArray('TotalRow', TotalRow);
//            for I := 0 to Length(TotalRow) - 1 do
//              LI('TotalRow', TotalRow[ I ]);
            if SumField then
            begin
              SetLength(Total, NumLevels);
              SetLength(PrevTotal, NumLevels);
  //              SetLength(RangeRowCount);
  //              SetLength(RangeRows);
            end;
          end;
        end;
//        Debug := True;
        ReadInt('PageNoRow', PageNoRow);
        ReadInt('PageOfRow', PageOfRow);
        ReadInt('NumPagesRow', NumPagesRow);
        ReadInt('NowDateRow', NowDateRow);
        ReadInt('NowTimeRow', NowTimeRow);
//        Debug := False;
        InSheet  := Book.Worksheets[ 1 ] as _WorkSheet;
        Sheet1Cells := InSheet.Cells;
        Sections      := SectionList[ 0 ];
        SectionCount  := Length(Sections);
        PrepareBook;
        ReadInt('NumExpr', ExprCount);
        for I := 0 to ExprCount - 1 do
        begin
          ReadInt('FormulaRow', ExprRow);
          ReadStr('FormulaExpr', Expr);
          try
            Sheet1Cells.Item[ ExprRow, NameCol ].Formula := '=' + Expr;
          except
            raise Exception.Create('error in formula : ' + Expr);
          end;
//          Log('ExprRow(' + IntToStr(ExprRow) + ') = ' + Expr);
        end;
//        Debug := True;
        ReadInt('ParamCount', ParamCount);
        SetLength(ParamInfos, ParamCount);
        for I := 0 to ParamCount - 1 do with ParamInfos[ I ] do
        begin
          ReadInt('Row', Row);
          ReadInt('Col', Col);
          ReadInt('Sheet', Sheet);
          ReadStr('Name', Name);
        end;
      except
        WasException := True;
        raise;
      end;
    finally
      Free;
    end;
//    ReplacePictures;
    MaxSheetCol := MaxSheetCols[ 0 ];
    MaxCol      := MaxSheetCol - DataCol + 1;
    if SectionList[ 0 ][ 0 ].SectionType = stTableQuery then
      MainDataSet := CreateQuery(@SectionList[ 0 ][ 0 ], MainSQL);
    TmpFont := TFont.Create;
    try
      if MainDataSet = nil then
      begin
        DocCount := 1;
        EmptyData := False;
      end else
      begin
        DocCount  := MainDataSet.RecordCount;
        EmptyData := MainDataSet.EOF;
      end;
      if TableInfoCount > 0 then
      begin
        if (DocCount > 1) and not MainTable then
          MsgType := pkDocument
        else
          MsgType := pkRecord;
      end else if SheetCount > 1 then
        MsgType := pkSheet
      else
        MsgType := pkSection;
      SetValue(NowDateRow, Date);
      SetValue(NowTimeRow, Time);
      PointsInPixel := InchesToPoints(1 / Screen.PixelsPerInch, LOCALE_USER_DEFAULT);

      MsgProc   := 0;
      SheetName := nil;
      if MainDataSet <> nil then
      begin
        SheetName := MainDataSet.FindField('SheetName');
        Company_Code_Ours := MainDataSet.FindField('Company_Code_Ours');
      end;
      if Company_Code_Ours = nil then
        ReplaceParams;
      for SheetNo := 0 to SheetCount - 1 do
      begin
        if not EmptyData and (MainDataSet <> nil) and (MainDataSet.RecNo <> 1) then
          MainDataSet.SetFirst;
        CurrSheetNo  := SheetNo;

        InSheet  := Book.Worksheets[ SheetNo + 1 ] as _Worksheet;
        DataColLeft := InSheet.Cells.Item[ 1, DataCol ].Left;
        MaxSheetCol := MaxSheetCols[ SheetNo ];
        if not EmptyData then
          NewOutSheet;
        SheetPageHeight := pntPageHeights[ SheetNo ] - 10;
        Sections      := SectionList[ SheetNo ];
        SectionCount  := Length(Sections);

        MaxCol      := MaxSheetCol - DataCol + 1;
        NoPaging    := False;
        PageSectionCount := 0;
        TableHeadCount   := 0;
        PageNo        := 1;
        SetValue(PageNoRow, 1);
        BreakDoc := False;
        PrintedHeight := 0;
        Breaking      := False;
        if not EmptyData then
        repeat
          if (Company_Code_Ours <> nil) and (Company_Code_Ours.AsString <> Company_Code_Ours_Value) then
          begin
            ReplaceParams;
            Company_Code_Ours_Value := Company_Code_Ours.AsString;
          end;
          PageHeader  := -1;
          if (SheetNo = 0) and (Sections[ 0 ].SectionType = stTableQuery) or (SheetName <> nil) then
            SectionNo := 1
          else
            SectionNo := 0;
          SetParam('_Embeded', False);
          PageSectionCount := 0;
          TableHeadCount := 0;
          BottTitle   := -1;
          PageOfOfs   := -1;
          NewDoc := True;
          pntPageHeight := SheetPageHeight;
          SetBottom;
          while SectionNo < SectionCount do
          begin
            with Sections[ SectionNo ] do
            begin
              case SectionType of
                stPageHeader:
                  begin
                    CheckPaging(InSheet.Cells.Item[ StartRow, 1 ].Text);
                    PageHeader := SectionNo;
                    SkipPageHeader;
                    if (OutCurrentRow > 1) and NoPaging then
                    begin
                      PutHeader;
                    end;
                  end;
                stGOTOtrue :
                  if Cond(@Sections[ SectionNo ]) then
                    SectionNo := FindTarget(TableIndex);
                stGOTOfalse :
                  if not Cond(@Sections[ SectionNo ]) then
                    SectionNo := FindTarget(TableIndex);
                stTableQuery :
                  CreateQuery(@Sections[ SectionNo ]);
                stPageFooter, stData, stHeader :
                  OutSection(SectionNo);
                stFooter :
                  if (MainDataSet = nil) or not MainDataSet.EOF and (MainDataSet.RecNo = MainDataSet.RecordCount) then
                  begin
                    OutSection(SectionNo);
                  end else
                    SectionNo := SectionCount;
                stSpacer :
                  OutSpacer;
                stTableHead, stTableData, stTableTotal:
                  begin
                    FirstTableOut := -1;
                    SectionNo := OutTable(SectionNo, 0);
                    Progress(pkRecord, 100);
                  end;
                stBottomTitle :
                  SetBottom;
                stNamesDef, stOutFile:;
              end;
            end;
            Inc(SectionNo);
            Progress(pkSection, 100 * SectionNo div SectionCount);
          end;
          BreakDoc := True;
          if DocCount > 1 then
            Progress(pkDocument, 100 * MainDataSet.RecNo div DocCount);
          if (MainDataSet <> nil) and not MainDataSet.EOF then
            MainDataSet.SetNext;
        until (MainDataSet = nil) or MainDataSet.EOF;
        if not EmptyData then
        begin
          if OutCurrentRow <> 1 then
            OutBottomTitle
          else
            OutSheetCells.Clear;
        end;
        LastRows[ SheetNo ] := OutCurrentRow - 1;
        Progress(pkSheet, 100 * (SheetNo + 1) div SheetCount);
      end;
    finally
      TmpFont.Free;
    end;
    if not EmptyData then
    begin
      for SheetNo := 1 to SheetCount do
      begin
         SheetNames[ SheetNo - 1 ] := (Book.Worksheets[ 1 ] as _Worksheet).Name;
        (Book.Worksheets[ 1 ] as _Worksheet).Delete(LOCALE_USER_DEFAULT);
      end;
      if SheetName = nil then
        for SheetNo := 1 to SheetCount do
         (Book.Worksheets[ SheetNo ] as _Worksheet).Name :=
            SheetNames[ SheetNo - 1 ];
  //Log('Total time : ' + FormatDateTime('s:zzz', StartTime - Now));
      Cells.Item[ 1, 1 ].Select;
    end else
      ShowMessage('There is no data');
    if not (Cancel or EmptyData) then
    begin
      PerformOper;
    end;
    After_Execute;
  finally
    SetLength(TableInfos, 0);
    try
      OleVariant(Book).Close;
      if Saved and Delete_File then
        DeleteFile(OutName + '.xls');
    except
      on E:Exception do Log('Book.Close : ' + E.Message);
    end;
  end;
end;

end.

