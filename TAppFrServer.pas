unit TAppFrServer;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Windows, Messages, SysUtils, Classes, ComServ, ComObj, VCLCom, DataBkr, SvcMgr,
  DBClient, StdVcl, XFreightSrvr_tlb, Provider, DB, ADODB, Variants, IniFiles, Forms, WinSock,
  IBQuery, IBCustomDataSet, IBStoredProc, IBDatabase, StrUtils, ADOConst, ALog;

type
  TXFRAppServer = class(TRemoteDataModule, ITXFRAppServer)
    ADOConnection: TADOConnection;
    QueryProvider: TDataSetProvider;
    ProcProvider: TDataSetProvider;
    IBDatabase: TIBDatabase;
    IBTransaction: TIBTransaction;
    IBProc: TIBStoredProc;
    IBQuery: TIBQuery;
    ADODataSet: TADODataSet;
    procedure RemoteDataModuleDestroy(Sender: TObject);
    procedure QueryAfterOpen(DataSet: TDataSet);
  private
    { Private declarations }
  protected
    function AS_GetProviderNames: OleVariant; safecall;
    function AS_ApplyUpdates(const ProviderName: WideString; Delta: OleVariant;
      MaxErrors: Integer; out ErrorCount: Integer;
      var OwnerData: OleVariant): OleVariant; safecall;
    function AS_GetRecords(const ProviderName: WideString; Count: Integer;
      out RecsOut: Integer; Options: Integer; const CommandText: WideString;
      var Params, OwnerData: OleVariant): OleVariant; safecall;
    function AS_DataRequest(const ProviderName: WideString;
      Data: OleVariant): OleVariant; safecall;
    function AS_GetParams(const ProviderName: WideString; var OwnerData: OleVariant): OleVariant; safecall;
    function AS_RowRequest(const ProviderName: WideString; Row: OleVariant;
      RequestType: Integer; var OwnerData: OleVariant): OleVariant; safecall;
    procedure AS_Execute(const ProviderName: WideString;
      const CommandText: WideString; var Params, OwnerData: OleVariant); safecall;
    class procedure UpdateRegistry(Register: Boolean; const ClassID, ProgID: string); override;
    function GetRouteM(PFType: Byte; const St, CnFrom, CnTo: WideString;
      DateCalc: Double): Integer; safecall;
    procedure ExecProc(const ProcedureName: WideString; var params: OleVariant;
      TimeOut: Integer); safecall;
    function ExecSQL(const ASQL: WideString; TimeOut: Integer): Integer;
      safecall;
    procedure SetIP(const IP: WideString); safecall;
    procedure LogIn(const AUserName, AUserPass: WideString; InterBase: Integer;
      const AServer, ABase, AMain: WideString;
      var Emp_Company_Uid: Integer; var EmpLang, wuName,
      wuPass: WideString); safecall;
    function GetRefsInfo: OleVariant; safecall;
    function BeginTrans: Integer; safecall;
    procedure CommitTrans; safecall;
    procedure RollbackTrans; safecall;
    procedure Prepare(Proc : boolean; const CommandText: WideString; const Params: OleVariant; OData : OleVariant);
    procedure CheckProcProvider(ProviderName : string; const CommandText: WideString; var Params: OleVariant; OData : OleVariant);
    procedure SetCommand(ProviderName : string; const CommandText: OleVariant);
    function GetDistM(PFType: Byte; const St: WideString;
      DateCalc: TDateTime): Integer; safecall;
    function GetProcParams(const ProcName: WideString): OleVariant;
    function GetQueryParams(const SQLtext: WideString): OleVariant;
    function PSExecute(const GenName, SQL: WideString; Params: OleVariant;
      const Origin: WideString): Integer; safecall;
    procedure Enter; safecall;
    function getBlob(const SQL: WideString; Params: OleVariant): OleVariant;
      safecall;
  public
    ViaIB    : boolean;
    ClientIP : string;
    ClientPublicKey : string;
    UserName : string;
    UserPass : string;
    uName, uPass : string;
    uServer, uBase : string;
    procedure OleErr(S : string; ErrNo : Longint);
    procedure CheckConnectionErrors;
  end;

function GetRouteV6(PFType, St, CnFrom, CnTo, DateCalc: PChar;
  ADOC: TADOConnection): integer; external 'RouteClc.dll';
function GetRouteMDistV6(PFType, St: PChar; DateCalc: TDateTime;
  ADOC: TADOConnection): integer; external 'RouteClc.dll';

function  GetBlowFish : TObject;
   external 'Cipher.dll';
procedure InitialiseString(BlowFish : TObject; const Key: string);
   external 'Cipher.dll';
procedure EncString(BlowFish : TObject; const Input: string; var Output: string);
   external 'Cipher.dll';
procedure DecString(BlowFish : TObject; const Input: string; var Output: string);
   external 'Cipher.dll';

implementation

uses {RouteV6,} IBInsert, CryptString;

type
  TParametersTypes = set of TParameterDirection;
const
  AllParametersTypes = [pdUnknown, pdInput, pdOutput, pdInputOutput,
    pdReturnValue];
var
  Registration : boolean;

{$R *.DFM}

procedure TXFRAppServer.CheckConnectionErrors;
var I : integer;
    S : string;
begin
  if not ViaIB then
  begin
    S := '';
    with ADOConnection do
    begin
      for I := 0 to Errors.Count - 1 do
      begin
//        if Trim(Errors[ I ].SQLState) = '' then
        if Errors[ I ].NativeError = 265929 then
        else
        begin
          if S = '' then
            S := Errors[ I ].Description
          else
            S := S + #13#10 + Errors[ I ].Description;
          Log(Errors[ I ].Description + '/' + Errors[ I ].SQLState);
        end;
      end;
      Errors.Clear;
    end;
    if S <> '' then
      raise Exception.Create(S);
  end;
end;

function PackageParameters(Parameters: TParameters; Types: TParametersTypes = AllParametersTypes): OleVariant;
var
  I, Idx, Count: Integer;
begin
  Result := NULL;
  Count := 0;
  for I := 0 to Parameters.Count - 1 do
    if Parameters[I].Direction in Types then Inc(Count);
  if Count > 0 then
  begin
    Idx := 0;
    Result := VarArrayCreate([0, Count - 1], varVariant);
    for I := 0 to Parameters.Count - 1 do
      with Parameters[ I ] do
        if Direction in Types then
        begin
          Result[ Idx ] := VarArrayOf([Name, Value, Ord(DataType), Ord(Direction)]);
          Inc(Idx);
        end;
  end;
end;

procedure TXFRAppServer.Prepare(Proc : boolean; const CommandText: WideString; const Params: OleVariant; OData : OleVariant);
var FParams : TParams;
    I : integer;
    P : TParameter;

    function TimeOut : Integer;
    begin
      if VarIsArray(OData) then
        Result := OData[ 0 ]
      else
        Result := OData;
    end;

begin
  FParams := TParams.Create;
  try
    UnpackParams(Params, FParams);
    if ViaIB then
    begin
      if Proc then
      begin
        IBProc.StoredProcName := CommandText;
        IBProc.Params.Assign(FParams);
        for I := 0 to IBProc.Params.Count - 1 do with IBProc.Params[ I ] do
          if DataType = ftString then
            Size := 2048;
      end else
      begin
        IBQuery.SQL.Text := CommandText;
        IBQuery.Params.Assign(FParams);
        for I := 0 to IBQuery.Params.Count - 1 do with IBQuery.Params[ I ] do
          if DataType = ftString then
            Size := 2048;
      end;
      IBTransaction.IdleTimer := TimeOut * 1000;
    end else
    begin
      proc := IsValidIdent(CommandText);
      if Proc then
        ADODataSet.CommandType := cmdStoredProc
      else
        ADODataSet.CommandType  := cmdText;
      ADODataSet.CommandText := CommandText;
      ADODataSet.CommandTimeout:= TimeOut;
      ADODataSet.Parameters.Clear;
//log('FParams.Count = ' + inttostr(FParams.Count));
      for I := 0 to FParams.Count - 1 do with FParams[ I ] do
      begin
//log('FParams[0] = ' + vartostr(FParams[0].value));
        P := ADODataSet.Parameters.AddParameter;
        if Proc and (Name[ 1 ] <> '@') then
          P.Name := '@' + Name
        else
          P.Name := Name;
        P.Attributes := [];
        P.NumericScale := 0;
        P.Precision := 0;
        P.Size := 0;
        if ParamType = ptUnknown then
          P.Direction := pdInput
        else
          P.Direction := TParameterDirection(ParamType);
        if ParamType = ptInputOutput then
          P.Size := 2000;
        P.DataType  := DataType;
        if (ParamType = ptInputOutput) and (IsNull or VarIsEmpty(Value) or (DataType = ftString) and (AsString = '')) then
          P.Value := VarAsType(0, FieldTypeVarMap[ DataType ])
        else
          P.Value := Value;
      end;
    end;
  finally
    FParams.Free;
  end;
end;

procedure TXFRAppServer.CheckProcProvider(ProviderName : string; const CommandText: WideString; var Params: OleVariant; OData : OleVariant);

begin
  if CommandText = '' then
  begin
    Params := null;
  end else
  begin
    Prepare(SameText(ProviderName, 'ProcProvider'), CommandText, Params, OData);
    Params := Unassigned;
  end;
end;

procedure TXFRAppServer.SetCommand(ProviderName : string; const CommandText: OleVariant);
begin
  if SameText(ProviderName, 'ProcProvider') then
  begin
    if ViaIB then
      IBProc.StoredProcName := CommandText
    else
    begin
      ADODataSet.CommandText  := CommandText;
      ADODataSet.CommandType  := cmdStoredProc;
    end;
  end else
  begin
    if SameText(ProviderName, 'QueryProvider') then
    begin
      if ViaIB then
        IBQuery.SQL.Text := CommandText
      else
      begin
        ADODataSet.CommandText  := CommandText;
        ADODataSet.CommandType  := cmdText;
      end;
    end;
  end;
end;

procedure TXFRAppServer.OleErr(S : string; ErrNo : Longint);
begin
  try
    Log(UserName + ' ' + S + '/' + IntToStr(ErrNo));
  except
  end;
  raise EOleException.Create(S, ErrNo, '', '', 0);
end;

function TXFRAppServer.AS_GetProviderNames: OleVariant;
var
  List: TStringList;
  i: Integer;
begin
  Lock;
  try
    List := TStringList.Create;
    try
      for i := 0 to ComponentCount - 1 do
        if (Components[ i ] is TCustomProvider) and TCustomProvider(Components[i]).Exported then
          List.Add(TCustomProvider(Components[i]).Name);
      List.Sort;
      Result := VarArrayFromStrings(List);
    finally
      List.Free;
    end;
  finally
    UnLock;
  end;
end;

function TXFRAppServer.AS_ApplyUpdates(const ProviderName: WideString;
  Delta: OleVariant; MaxErrors: Integer; out ErrorCount: Integer;
  var OwnerData: OleVariant): OleVariant;
begin
  try
    Lock;
    try
      SetCommand(ProviderName, OwnerData);
      Result := Providers[ProviderName].ApplyUpdates(Delta, MaxErrors, ErrorCount, OwnerData);
    finally
      UnLock;
    end;
  except
    on E:Exception do OleErr(E.Message, 0);
  end;
end;

function TXFRAppServer.AS_GetRecords(const ProviderName: WideString; Count: Integer;
  out RecsOut: Integer; Options: Integer; const CommandText: WideString;
  var Params, OwnerData: OleVariant): OleVariant;
var P : TDataSetProvider;
begin
  try
    Lock;
    try
      CheckProcProvider(ProviderName, CommandText, Params, OwnerData);
      P := TDataSetProvider(Providers[ProviderName]);
      if VarIsArray(OwnerData) and WordBool(OwnerData[ 1 ]) then
      begin
        P.Options := [ poFetchBlobsOnDemand ];
//        OwnerData :=
      end else
        P.Options := [];
      Result := P.GetRecords(Count, RecsOut, Options,
        '', Params, OwnerData);
      CheckConnectionErrors;
      Params := PackageParameters(ADODataSet.Parameters);
    finally
      UnLock;
    end;
  except
    on E:Exception do OleErr(CommandText + ' : ' + E.Message, 0);
  end;
end;

function TXFRAppServer.AS_RowRequest(const ProviderName: WideString;
  Row: OleVariant; RequestType: Integer; var OwnerData: OleVariant): OleVariant;
begin
  try
    Lock;
    try
      SetCommand(ProviderName, OwnerData);
      Result := Providers[ProviderName].RowRequest(Row, RequestType, OwnerData);
    finally
      UnLock;
    end;
  except
    on E:Exception do OleErr(E.Message, 0);
  end;
end;

function TXFRAppServer.AS_DataRequest(const ProviderName: WideString;
  Data: OleVariant): OleVariant; safecall;
begin
  try
    Lock;
    try
      Result := Providers[ProviderName].DataRequest(Data);
    finally
      UnLock;
    end;
  except
    on E:Exception do OleErr(E.Message, 0);
  end;
end;

function TXFRAppServer.AS_GetParams(const ProviderName: WideString; var OwnerData: OleVariant): OleVariant;
begin
  try
    Lock;
    try
      if SameText(string(ProviderName), 'ProcProvider') then
        Result := GetProcParams(OwnerData)
      else if SameText(string(ProviderName), 'QueryProvider') then
        Result := GetQueryParams(OwnerData)
      else
        Result := Providers[ProviderName].GetParams(OwnerData);
    finally
      UnLock;
    end;
  except
    on E:Exception do OleErr(E.Message, 0);
  end;
end;

procedure TXFRAppServer.AS_Execute(const ProviderName: WideString;
  const CommandText: WideString; var Params, OwnerData: OleVariant);
var RecsOut : integer;
    Options : TGetRecordOptions;
begin
  try
    Lock;
    try
      CheckProcProvider(ProviderName, CommandText, Params, OwnerData);
      if ViaIB then
        Providers[ProviderName].Execute('', Params, OwnerData)
      else
      begin
        Options := [grMetaData];
        try
          Providers[ProviderName].GetRecords(-1, RecsOut, Byte(Options),
            '', Params, OwnerData);
        except
          on E:Exception do
            if not AnsiContainsText(E.Message, SNoResultSet) then
              raise;
        end;
        Params := PackageParameters(ADODataSet.Parameters);
      end;
      CheckConnectionErrors;
    finally
      UnLock;
    end;
  except
    on E:Exception do OleErr(E.Message, 0);
  end;
end;

class procedure TXFRAppServer.UpdateRegistry(Register: Boolean; const ClassID, ProgID: string);
begin
  if Register then
  begin
    inherited UpdateRegistry(Register, ClassID, ProgID);
    EnableSocketTransport(ClassID);
    EnableWebTransport(ClassID);
  end else
  begin
    DisableSocketTransport(ClassID);
    DisableWebTransport(ClassID);
    inherited UpdateRegistry(Register, ClassID, ProgID);
  end;
end;

procedure DoFinalize;
begin
  CloseLog;
end;

procedure DoInitialize;
begin
  OpenLog;
end;

function TXFRAppServer.GetRouteM(PFType: Byte; const St, CnFrom,
  CnTo: WideString; DateCalc: Double): Integer;
  var Pt : PChar;
begin
  Lock;
  try
    Pt := PChar(string(Char(PFType)));
    try
      if ViaIB then
//        Result := IBCalcRouteV6(Chr(PFType), St, CnFrom, CnTo, DateCalc, IBDataBase)
         raise Exception.Create('InterBase GetRoute does not exist')
      else
//        Result := CalcRouteV6(Chr(PFType), St, CnFrom, CnTo, DateCalc, ADOConnection);
        Result := GetRouteV6(Pt, PChar(string(St)), PChar(string(CnFrom)), PChar(string(CnTo)), PChar(FormatDateTime('mm.dd.yyyy', DateCalc)), ADOConnection);
    except
      on E:Exception do OleErr('GetRoute : ' + E.Message, 0);
    end;
  finally
    UnLock;
  end;
end;

procedure TXFRAppServer.ExecProc(const ProcedureName: WideString;
  var params: OleVariant; TimeOut: Integer);
begin
  Lock;
  try
    try
      Prepare(True, ProcedureName, Params, TimeOut);
      if ViaIB then
      begin
        IBProc.ExecProc;
        Params := PackageParams(IBProc.Params);
      end else with ADODataSet do
      begin
        try
          Open;
        except
          on E:Exception do
            if not AnsiContainsText(E.Message, SNoResultSet) then
              raise;
        end;
        Params := PackageParameters(Parameters);
      end;
    except
      on E:Exception do OleErr(ProcedureName + ' : ' + E.Message, 0);
    end;
  finally
    Unlock;
  end;
end;

function TXFRAppServer.ExecSQL(const ASQL: WideString;
  TimeOut: Integer): Integer;
begin
  Lock;
  try
    try
//        Log(ASQL);
      Result := 1;
      if ViaIB then with IBQuery do
      begin
        SQL.Text := ASQL;
        IBTransaction.IdleTimer := TimeOut * 1000;
        ExecSQL;
      end else with ADODataSet do
      begin
        CommandTimeOut := TimeOut;
        CommandText    := ASQL;
        CommandType    := cmdText;
        Open;
      end;
      CheckConnectionErrors;
    except
      on E:Exception do OleErr('ExecSQL : ' + E.Message, 0);
    end;
  finally
    UnLock;
  end;
end;

procedure TXFRAppServer.SetIP(const IP: WideString);
begin
  ClientIP := IP;
end;

procedure TXFRAppServer.LogIn(const AUserName, AUserPass: WideString;
  InterBase: Integer; const AServer, ABase, AMain: WideString;
  var Emp_Company_Uid: Integer; var EmpLang, wuName, wuPass: WideString);
var CryptPass,
    CryptName, sIP : string;
    uIP  : Variant;
    Fish : TObject;
    ADOLogin: TADOQuery;
    IBLogin: TIBQuery;

procedure Err(S : string);
begin
  raise Exception.Create(S);
end;

begin
  Lock;
  try
    UserName := AUserName;
    UserPass := AUserPass;
    uServer  := string(AServer);
    uBase    := string(ABase);
    if SameText(UserName, 'sa') and SameText(UserPass, 'tbc') then
    begin
      uName  := UserName;
      uPass  := UserPass;
      wuName := uName;
      wuPass := uPass;
      Emp_Company_Uid := -1;
      EmpLang := 'R';
      Exit;
    end;
    try
      ViaIB := boolean(InterBase);
      if ViaIB then
      begin
        ADOLogin := nil;
        IBLogin  := TIBQuery.Create(nil);
        IBLogin.DataBase    := IBDataBase;
        IBLogin.Transaction := IBTransaction;
      end else
      begin
        IBLogin  := nil;
        ADOLogin := TADOQuery.Create(nil);
        ADOLogin.Connection := ADOConnection;
      end;
      try
        Fish  := GetBlowFish;
        try
          InitialiseString(Fish, FishInitialiseString);
          UserName := AUserName;
          UserPass := AUserPass;
  // Log(UserName + ',' + UserPass + ',' + AServer + ',' + ABase + ',' + AMain);
          EncString(Fish, UserPass, CryptPass);
          EncString(Fish, UserName, CryptName);
          CryptPass := AnsiQuotedStr(CryptPass, '''');
          CryptName := AnsiQuotedStr(CryptName, '''');
          if ViaIB then
          begin
            ProcProvider.DataSet   := IBProc;
            QueryProvider.DataSet  := IBQuery;
            with IBDataBase do
            begin
              DataBaseName := string(AServer + ':' + AMain);
              Params.Values['user_name'] := 'xconnadm';
              Params.Values['password']  := 'xconnadm_tbc';
              Connected := True;
            end;
            with IBLogin do
            begin
              SQL.Text   := 'select Emp_IP_Net, Emp_Company_Uid, Emp_Name, Emp_Password_SQL, Emp_Language from Emp where Emp_Login_Remote = ' +
                CryptName + ' and Emp_Password_Remote = ' + CryptPass;
              Open;
              try
                uName := FieldByName('Emp_Name').AsString;
                DecString(Fish, FieldByName('Emp_Password_SQL').AsString, uPass);
                uIP         := FieldByName('Emp_IP_Net').AsString;
                Emp_Company_Uid := FieldByName('Emp_Company_Uid').AsInteger;
                with FieldByName('Emp_Language') do
                  if IsNull then
                    EmpLang  := 'R'
                  else
                    EmpLang  := AsString;
              except
                uName := '';
              end;
            end;
          end else
          begin
            ProcProvider.DataSet    := ADODataSet;
            QueryProvider.DataSet   := ADODataSet;
            ADOConnection.ConnectionString := 'Provider=SQLOLEDB.1;Persist Security Info=True'
              + ';Data Source=' + string(AServer) + ';Initial Catalog=' + string(AMain)
              + ';Application Name=AppServer';
//Log(ADOConnection.ConnectionString);
//Log(UserName);
//Log(UserPass);
            ADOConnection.Open('xconnadm', 'xconnadm_tbc');
            with ADOlogin do
            begin
              SQL.Text   := 'select Emp_IP_Net, Emp_Company_Uid, Emp_Name, Emp_Password_SQL, Emp_Language from Emp where Emp_Login_Remote = ' +
                CryptName + ' and Emp_Password_Remote = ' + CryptPass;
              Open;
              try
                uName := FieldByName('Emp_Name').AsString;
                DecString(Fish, FieldByName('Emp_Password_SQL').AsString, uPass);
                uIP         := FieldByName('Emp_IP_Net').AsString;
                Emp_Company_Uid := FieldByName('Emp_Company_Uid').AsInteger;
                with FieldByName('Emp_Language') do
                  if IsNull then
                    EmpLang  := 'R'
                  else
                    EmpLang  := AsString;
              except
                uName := '';
              end;
              Close;
//              SQL.Text := 'select Rights_App_Code from Rights where Rights_RT_Code = ''APP'' and Rights_Emp_Name = ' +
//                   '''' + UserName + '''';
//              Open;
            end;
          end;
        finally
          Fish.Free;
        end;
        if uName = '' then
          Err('Bad name or password');
        if not VarIsNull(uIP) then
        begin
          sIP := Trim(uIP);
          if Copy(ClientIP, 1, Length(sIP)) <> sIP then
          begin
             Log(UserName + ' - bad IP ' + ClientIP + '(' + sIP + ')');
             Err(UserName + ' - bad IP');
          end;
        end;
        wuName := uName;
        wuPass := uPass;
      finally
        if ViaIB then
          IBLogin.Free
        else
          ADOLogin.Free;
      end;
    except
      on E:Exception do OleErr(E.Message, -1);
    end;
  finally
    UnLock;
  end;
end;

procedure TXFRAppServer.RemoteDataModuleDestroy(Sender: TObject);
begin
  if UserName <> '' then
  begin
    if ClientIP <> '' then
      Log(UserName + ' logged out, IP = ' + ClientIP)
    else
      Log(UserName + ' logged out');
  end;
end;

function TXFRAppServer.GetRefsInfo: OleVariant;
var List  : TStringList;
    aRefs : TADOQuery;
    Refs  : TIBQuery;
begin
  Lock;
  try
    try
      Result := '';
      List := TStringList.Create;
      try
        if ViaIB then
        begin
           Refs := TIBQuery.Create(nil);
           try
             with Refs do
             begin
               DataBase  := IBDataBase;
               SQL.Text  := 'select * from Remote_Ref_List';
               Open;
               while not EOF do
               begin
                 List.Add(Trim(Fields[ 0 ].AsString) + '=' + Fields[ 1 ].AsString);
                 Next;
               end;
             end;
           finally
             Refs.Free;
           end;
        end else
        begin
           aRefs := TADOQuery.Create(nil);
           try
             with aRefs do
             begin
               Connection  := ADOConnection;
               SQL.Text  := 'select * from Remote_Ref_List';
               Open;
               while not EOF do
               begin
                 List.Add(Trim(Fields[ 0 ].AsString) + '=' + FormatDateTime('dd.mm.yy', Fields[ 1 ].AsDateTime));
                 Next;
               end;
             end;
           finally
             aRefs.Free;
           end;
        end;
        Result := List.Text;
      finally
        List.Free;
      end;
    except
      on E:Exception do OleErr(E.Message, -1);
    end;
//      Log('RefList : ' + Result);
  finally
    UnLock;
  end;
end;

function TXFRAppServer.BeginTrans: Integer;
begin
  Lock;
  try
    if ViaIB then
    begin
      Result := 0;
      IBTransaction.StartTransaction;
    end else
      Result := ADOConnection.BeginTrans;
  finally
    UnLock;
  end;
end;

procedure TXFRAppServer.CommitTrans;
begin
  Lock;
  try
    if ViaIB then
      IBTransaction.Commit
    else
      ADOConnection.CommitTrans;
  finally
    UnLock;
  end;
end;

procedure TXFRAppServer.RollbackTrans;
begin
  Lock;
  try
    if ViaIB then
      IBTransaction.Rollback
    else
      ADOConnection.RollbackTrans;
  finally
    UnLock;
  end;
end;

function TXFRAppServer.GetDistM(PFType: Byte; const St: WideString;
  DateCalc: TDateTime): Integer;
  var Pt : PChar;
begin
  Lock;
  try
    Pt := PChar(string(Char(PFType)));
    try
//Log(Pt + ' ' + string(St));
      if ViaIB then
//        Result := IBCalcRouteV6(Chr(PFType), St, CnFrom, CnTo, DateCalc, IBDataBase)
         raise Exception.Create('InterBase GetRoute does not exist')
      else
//        Result := CalcRouteV6(Chr(PFType), St, CnFrom, CnTo, DateCalc, ADOConnection);
        Result := GetRouteMDistV6(Pt, PChar(string(St)), DateCalc, ADOConnection);
    except
      on E:Exception do OleErr('GetDist : ' + E.Message, 0);
    end;
  finally
    UnLock;
  end;
end;

function TXFRAppServer.GetQueryParams(const SQLtext: WideString): OleVariant;
begin
  if ViaIB then
  begin
    IBQuery.SQL.Text := SQLtext;
    IBQuery.Prepare;
    Result := PackageParams(IBQuery.Params);
  end else with ADODataSet do
  begin
    CommandText := SQLtext;
    CommandType := cmdText;
    Parameters.Refresh;
    Result   := PackageParameters(Parameters);
  end;
end;

function TXFRAppServer.GetProcParams(const ProcName: WideString): OleVariant;
begin
  if ViaIB then
  begin
    IBProc.StoredProcName := ProcName;
    IBProc.Prepare;
    Result := PackageParams(IBProc.Params);
  end else with ADODataSet do
  begin
    CommandText := ProcName;
    CommandType := cmdStoredProc;
    Parameters.Refresh;
    Result := PackageParameters(Parameters);
  end;
end;

function TXFRAppServer.PSExecute(const GenName, SQL: WideString;
  Params: OleVariant; const Origin: WideString): Integer;
var FParams : TParams;
    I, J, Identity : integer;
    S, O : string;
    T : TStringList;
    DoIns : boolean;
    Query : TADOQuery;
begin
  Lock;
  try
    FParams := TParams.Create;
    try
      UnpackParams(Params, FParams);
      S := string(SQL);
      DoIns := AnsiStartsText('INSERT', S);
      if ViaIB then
      begin
        if DoIns and (Length(GenName) <> 0) then
        begin
          Identity := IBIdentity(IBDatabase, string(GenName));
          I := Pos('(', S);
          J := PosEx(')', S, I + 1);
          T := TStringList.Create;
          T.CaseSensitive := False;
          try
            T.CommaText := Copy(S, I + 1, J - I - 1);
            O := string(Origin);
            I := T.IndexOf(O);
            FParams[ I ].AsInteger := Identity;
          finally
            T.Free;
          end;
        end;
        Result := IProviderSupport(IBQuery).PSExecuteStatement(S, FParams, nil);
      end else
      begin
        Query := TADOQuery.Create(nil);
        try
          if DoIns then
            Query.SQL.Text := S + #13#10'SELECT @@IDENTITY'
          else
            Query.SQL.Text := S;
          RefreshParameters(Query.Parameters, FParams);
          with Query do
          begin
            Open;
            if DoIns then
            begin
              if not EOF and (FieldCount = 1) then
                Result := Fields[ 0 ].AsInteger
              else
                Result := 0;
            end else
              Result := 1;
          end;
        finally
          Query.Free;
        end;
      end;
    finally
      FParams.Free;
    end;
  finally
    UnLock;
  end;
end;

procedure TXFRAppServer.Enter;
begin
  Lock;
  try
    try
      if ViaIB then with IBDataBase do
      begin
        IBDataBase.Connected := False;
        DataBaseName := uServer + ':' + uBase;
        Params.Values['user_name'] := uName;
        Params.Values['password']  := uPass;
        Connected := True;
      end else with ADOConnection do
      begin
        ADOConnection.Connected := False;
        ProcProvider.DataSet    := ADODataSet;
        QueryProvider.DataSet   := ADODataSet;
        ConnectionString := 'Provider=SQLOLEDB.1;Persist Security Info=True'
          + ';Data Source=' + uServer + ';Initial Catalog=' + uBase
          + ';Application Name=AppServer';
//        Log(ConnectionString);
//        Log(uName);
//        Log(uPass);
        Open(uName, uPass);
      end;
    except
      on E:Exception do OleErr(E.Message, -1);
    end;
  finally
    UnLock;
  end;
  Log(UserName + ' logged in, IP = ' + ClientIP);
end;

function TXFRAppServer.getBlob(const SQL: WideString;
  Params: OleVariant): OleVariant;
var BS : TStream;
    P  : Pointer;
    FParams : TParams;
    Query : TADOQuery;
begin
  Lock;
  try
    FParams := TParams.Create;
    try
      UnpackParams(Params, FParams);
      Query := TADOQuery.Create(nil);
      try
        Query.SQL.Text := SQL;
        with Query do
        begin
          RefreshParameters(Parameters, FParams);
          Open;
          BS := CreateBlobStream(Fields[ 0 ], bmRead);
          try
            Result  := VarArrayCreate([0, BS.Size - 1], varByte);
            P  := VarArrayLock(Result);
            try
              BS.Read(P^, BS.Size);
            finally
              VarArrayUnlock(Result);
            end;
          finally
            BS.Free;
          end;
        end;
      finally
        Query.Free;
      end;
    finally
      FParams.Free;
    end;
  finally
    UnLock;
  end;
end;

procedure TXFRAppServer.QueryAfterOpen(DataSet: TDataSet);
var N : integer;
begin
  while TCustomADODataSet(DataSet).NextRecordset(N) <> nil do;
end;

initialization
  Registration := FindCmdLineSwitch('REGSERVER', ['-', '/'], True) or
                FindCmdLineSwitch('UNREGSERVER', ['-', '/'], True);
  TComponentFactory.Create(ComServer, TXFRAppServer,
    Class_XFRAppServer, ciMultiInstance, tmApartment);
  if not Registration then
    DoInitialize;

finalization
  if not Registration then
    DoFinalize;
end.