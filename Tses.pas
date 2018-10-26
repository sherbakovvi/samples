unit Tses;
// 950 50 38 Zolkin
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Dialogs, Forms, Menus,
  ADODB, Db, DBConsts, Syncobjs, DBClient, Provider, Crypter, Variants, Contnrs,
  WinSock, SConnect, ScktComp, IBDatabase, IBHeader, XFreightSrvr_TLB, IBQuery,
  IBStoredProc, IBCustomDataSet, IBTable, URepOp, DBGrids, ZLibEx,
  IBSQL, IBUtils, URepFunc, DSIntf, ADOConst;

type
  TxClientDataSet = class;
  TLockResult = (lrYes, lrFailed, lrNo);
  TConnectionType = (ctMidas, ctADO, ctIB);
  TApplyState     = (asDeleted, asInApply, asBegApply, asRealized, asEnded);
  TApplyStates    = set of TApplyState;
  TUserTransType  = (utReadOnly, utReadWrite);
  TCustomxConnection = class;
  TOnUpdateConnectInfo = procedure(Sender : TCustomxConnection; SaveInfo : boolean) of object;
  TOnApplyInsert = procedure (DataSet : TxClientDataSet; var Identity : integer) of object;
  TOnApplyModified = procedure (DataSet : TxClientDataSet) of object;
  TOnApplyDeleted = procedure (DataSet : TxClientDataSet) of object;
  TOnMasterModify = procedure (DataSet : TxClientDataSet; MasterInsert : boolean) of object;
  TExeMethod = function : boolean of object;
  TCustomxConnection = class(TComponent)
  private
    FAppServerGUID : string;
    FAppHost       : string;
    FCaption       : string;
    FAppPort       : integer;
    FDBName        : string;
    FServerName    : string;
    FDBMain           : string;
    FLogin            : string;
    FPassword         : string;
    FKeyDir           : string;
    FPingInterval     : integer;
    FConnectionType   : TConnectionType;
    FCanADO           : boolean;
    FCanIB            : boolean;
    FADOConnection    : TADOConnection;
    FIBDataBase       : TIBDataBase;
    FRemoteServer     : TSesSocketConnection;
    FRenewRemoteServer: boolean;
    FAfterSysConnect  : TNotifyEvent;
    FAfterConnect     : TNotifyEvent;
    FAfterDisconnect  : TNotifyEvent;
    FBeforeDisconnect : TNotifyEvent;
    FAppServerDisp    : ITXFRAppServerDisp;
    FAppServerIB      : boolean;
    FOnUpdateConnectInfo : TOnUpdateConnectInfo;
    FOnResetConnectInfo  : TOnUpdateConnectInfo;
    FIBTransactions : array[ TUserTransType ] of TIBTransaction;
    FTransType : TUserTransType;
    FInTransaction : boolean;
    FDeleteDog : boolean;
    FClients   : TObjectList;
    FDelayConnect  : boolean;
    FSystemMode: boolean;
    uName, uPass : string;
    FExternalClient : boolean;
    function  Loading: Boolean;
    function  GetTransaction(const TransType : TUserTransType) : TIBTransaction;
    procedure SetConnectionType(Value : TConnectionType);
    function  ConnectType : TConnectionType;
  protected
    RemoteAddr: TInAddr;
//    BlobSource: TBlobSource;
    FSilentMode: boolean; //By Jimmy
    function  GetConnected : boolean;  virtual;
    procedure SetConnected(Value : boolean); virtual;
    procedure DoAfterConnect;
    procedure DoAfterDisconnect(Sender : TObject);
    procedure DoBeforeDisconnect(Sender : TObject);
    procedure MidasConnect;
    procedure ADOConnect;
    procedure IBConnect;
    function  GetInTransaction : boolean;
    procedure UnregisterClient(Client : TxClientDataSet);
    procedure RegisterClient(Client : TxClientDataSet);
    function  DoGetConnectInfo(Msg : string) : boolean;
    function  InfoReqired : boolean;
//    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    Emp_Company_Uid : integer;
    Emp_Language    : string;
    Save_Pass       : boolean;
    NoRefModInfo    : boolean;
    function GetRouteM(PFType : Char; StLine, CnFrom, CnTo : string; DateCalc : TDate) : Integer;
    procedure CheckConnectionErrors;
    procedure ReopenDataSets;
    procedure CloseDataSets;
    procedure TryConnect;
    procedure Disconnect;
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure Assign(Source : TPersistent);  override;
    function  LoadFromServer(TableName, FName : string) : boolean;
    procedure CancelUpdates;
    function  CanLocalConnect : boolean;
    function  GetConnectInfo : boolean;
    procedure GetTableNames(Tables : TStringList);
    function  DelDog(Param : string) : string;
    function  AddDog(Param : string) : string;
    procedure JoinParams(const Source: OleVariant; Dest: TParams);
    function  LockAll(Lock : boolean) : boolean;
    function  BeginTrans(TransType : TUserTransType = utReadWrite): Integer;
    procedure CommitTrans;
    procedure RollbackTrans;
    procedure DoException(E : Exception; Info : string = '');
    procedure CheckConnected;
    procedure CreateGenerator(GenName : string);
    procedure DeleteGenerator(GenName : string);
    function  ExecSQL(PSQL : string; PTimeOut : integer = 30) : boolean;
    procedure ExecProc(const AProcedureName: string;
               ProcParams : TParams; TimeOut: Integer);
    function  TableLastUpdate(TableNames : string) : TDateTime;
    property  Clients : TObjectList read FClients;
    property  RemoteServer    : TSesSocketConnection read FRemoteServer;
    property  CanADO          : boolean read FCanADO;
    property  CanIB           : boolean read FCanIB;
    property  IBDataBase      : TIBDataBase read FIBDataBase;
    property  AppServerDisp : ITXFRAppServerDisp read FAppServerDisp;
    property  IBTransactions[ const TransType : TUserTransType ] : TIBTransaction read GetTransaction;
    property  InTransaction: Boolean read GetInTransaction;
    property  ADOConnection   : TADOConnection read FADOConnection write FADOConnection;

    property ConnectionType  : TConnectionType read FConnectionType write SetConnectionType;
    property Connected       : boolean read GetConnected write SetConnected;
    property AfterConnect    : TNotifyEvent read FAfterConnect write FAfterConnect;
    property AfterSysConnect : TNotifyEvent read FAfterSysConnect write FAfterSysConnect;
    property AfterDisconnect : TNotifyEvent read FAfterDisconnect write FAfterDisconnect;
    property BeforeDisconnect : TNotifyEvent read FBeforeDisconnect write FBeforeDisconnect;
    property OnUpdateConnectInfo : TOnUpdateConnectInfo read FOnUpdateConnectInfo write FOnUpdateConnectInfo;
    property OnResetConnectInfo  : TOnUpdateConnectInfo read FOnResetConnectInfo write FOnResetConnectInfo;

    property ExternalClient: boolean read FExternalClient write FExternalClient;
    property DBName        : string read FDBName write FDBName;
    property ServerName    : string read FServerName write FServerName;
    property DBMain        : string read FDBMain write FDBMain;
    property Login         : string read FLogin write FLogin;
    property Password      : string read FPassword write FPassword;
    property ADOName       : string read uName;
    property ADOPass       : string read uPass;
    property KeyDir        : string read FKeyDir write FKeyDir;

    property AppServerGUID : string read FAppServerGUID write FAppServerGUID;
    property AppHost       : string read FAppHost write FAppHost;
    property Caption       : string read FCaption write FCaption;
    property AppPort       : integer read FAppPort write FAppPort default 211;
    property DelayConnect  : boolean read FDelayConnect write FDelayConnect default True;
    property AppServerIB   : boolean read FAppServerIB write FAppServerIB;
    property DeleteDog     : boolean read FDeleteDog write FDeleteDog;
    property SystemMode    : boolean read FSystemMode write FSystemMode;
    property SilentMode    : boolean read FSilentMode write FSilentMode default False;
  end;

  TxConnection = class(TCustomxConnection)
  published
    property ConnectionType;
    property AfterSysConnect;
    property AfterConnect;
    property AfterDisconnect;
    property BeforeDisconnect;
    property OnUpdateConnectInfo;

    property DBName;
    property ServerName;
    property DBMain;
    property Login;
    property Password;
    property KeyDir;

    property AppServerGUID;
    property AppHost;
    property Caption;
    property AppPort;
    property AppServerIB;
    property DeleteDog;
    property Connected;
    property DelayConnect;
    property SystemMode;
    property SilentMode;
  end;

  TTokenType = (ttUnknown, ttEnd, ttValue, ttNumber, ttIdent, ttBlank, ttParam, ttAllFields,
      ttSeparator, ttDistinct, ttExecute, ttAscending, ttDescending,
      ttSelect, ttFrom, ttWhere, ttGroupBy, ttHaving, ttUnion,
      ttPlan, ttForUpdate, ttOrderBy, ttLiteral, ttComment);

  TRefField = record
    FromField : TField;
    ToDataSet : TxClientDataSet;
    WeakRef   : boolean;
  end;

  TRefFields = array of TRefField;

  TChangeIdent = record
    Old, New : integer;
  end;

  PBlobInfo = ^TBlobInfo;
  TBlobInfo = record
    BlobField : TBlobField;
    BlobName  : TStringField;
    BlobDate  : TDateTimeField;
  end;

  TKeyBookMark = class
    Key         : Variant;
    OldIdent    : integer;
    FNewIdent   : integer;
    UserIdent   : boolean;
    State       : char;
    Updates     : TStringList;
  private
    function  GetNewIdent: integer;
    procedure SetNewIdent(const Value: integer);
  public
    constructor Create;
    destructor  Destroy; override;
    property NewIdent : integer read GetNewIdent write SetNewIdent;
  end;

  TxClientDataSet = class(TCustomClientDataSet)
  private
    FConnection   : TCustomxConnection;
    FTransType    : TUserTransType;
    ADODataSet    : TADODataSet;
    IBQuery       : TIBQuery;
    IBStoredProc  : TIBStoredProc;
    Provider      : TDataSetProvider;
    FSQL          : TStrings;
    FSQLtext      : string;
    FParams       : TParams;
    FApplyParams  : TParams;
    FResultSet    : boolean;
    FUpdateMode   : TUpdateMode;
    FTableName    : string; //GetSQLTokenValue(FSQL, ttFrom)
    FApplyTable : string;
    FGenName      : string;
    FDeleteProc   : string;
    FIdentField   : TField;
    FAutoInc      : integer;
    FDetailDataSets : TObjectList;
    FDetailDataSetsChecked : boolean;
    FIdentity     : LongInt;
    FUniqueKey    : string;
    FSaveRec      : TBookMark;
    FSaveIdent    : integer;
    FCanEmpty     : boolean;
    FOnApplyInsert: TOnApplyInsert;
    FOnApplyModified : TOnApplyModified;
    FOnApplyDeleted  : TOnApplyDeleted;
    FBeforeApplyRecord : TDataSetNotifyEvent;
    FOnMasterModify  : TOnMasterModify;
    FOnMasterModified : TDataSetNotifyEvent;
    FBookMarks    : TObjectList;
    FActive       : boolean;
    FTransactional: boolean;
    FTimeOut     : integer;
    ApplyState   : TApplyStates;
    FSaveFileName   : string;
    FromServer : boolean;
    SavedSource : TDataSource;
    SavedMasterFlds : string;
    SaveAutoCalcFields : boolean;
    SaveAggregatesActive: boolean;
    BlobInfo : array of TBlobInfo;
    FNeedLock : boolean;
    RefFieldLen : integer;
    FStartRange, FEndRange : Variant;
    FInsertIdentity : boolean;
    FInsertIdentityOn : boolean;
    FUserIdentity : boolean;
    Stack : array[0..30] of TxClientDataSet;
    StackTop : integer;
    FLockedRecord : Integer;
    FDelBookMark  : TKeyBookMark;
    procedure SetNeedLock(Value : boolean);
    function  Loading : Boolean;
    procedure SetConnection(Value : TCustomxConnection);
    procedure SetResultSet(Value : boolean);
    procedure SetTimeOut(Value : integer);
    procedure SetSQL(Value : TStrings);
    procedure SetTransactional(Value : boolean);
    procedure SQLChanged(Sender : TObject);
    procedure BegApply;
    procedure Realize;
    procedure CheckWeak;
    procedure WeakApply;
    procedure EndApply;
    procedure ApplyWeakRec;
    procedure ApplyInserted;
    function  PSExecuteSQL(const SQL : string)  : boolean;
    function  IsRefField(Field : TField; var RefValue : integer; var Weak : boolean) : boolean;
    function  GetNewRef(OldRef : integer) : integer;
    procedure PrepareDeleteProc;
    procedure ExecDeleteProc(ABookMark : TKeyBookMark);
    procedure ApplyModified;
    function  GetWhere(Params : TParams) : string;
    function  GetWeakWhere(Params : TParams) : string;
    function  ConnectType : TConnectionType;
    procedure PasteDetails(Dets : Variant);
    procedure PasteRecord(Rec : Variant);
    function  CopyDetails : Variant;
    function  CopyRecord  : Variant;
    function  GetDataTypes : Variant;
    function  GetAutoInc : integer;
    function  GetBookMarks : TObjectList;
    procedure AfterADOOpen(DataSet : TDataSet);
    procedure RestCursorRange;
    procedure SaveCursorRange;
  protected
    function  LockedRecord : integer;
    procedure AddParam(Field : TField; V : Variant; Fld : boolean = True);
    property  BookMarks  : TObjectList read GetBookMarks;
    function  UseFieldInUpdate(Fld: TField): Boolean;
    function  NewBlobData(Field: TField): Boolean;
    function  IsIdent(Field: TField): Boolean;
    function  HasBlobData(Field: TField): Boolean;
    function  UseFieldInInsert(Fld: TField): Boolean;
    function  UseFieldInWhere(Field: TField; Mode: TUpdateMode): Boolean;
    procedure DoBeforeApplyRecord;
    procedure AppendRecord(Rec : Variant);
    procedure AppendDetails(Dets : Variant);
    procedure InternalApplyUpdates;
    procedure RefApply;
    function  DoGetRecords(Count: Integer; out RecsOut: Integer; Options: Integer;
             const CommandText: WideString; Params: OleVariant): OleVariant; override;
    procedure DoExecute(Params: OleVariant); override;
    procedure DoBeforeGetParams(var OwnerData: OleVariant); override;
    procedure DoBeforeRowRequest(var OwnerData: OleVariant); override;
    procedure DoAfterGetParams(var OwnerData: OleVariant); override;
    function  GetProviderName : string;
    procedure PrepareProvider;
    procedure Prepare;
    procedure SetCmdText;
    procedure ResetProvider(DataSet : TDataSet);
    procedure SetIdentMasters;
    function  IndexedByMaster : boolean;
    function  GetIndex_Field(Index: Integer): TField;
    procedure SetIndex_Field(Index: Integer; Value: TField);
    procedure DataEvent(Event: TDataEvent; Info: Integer); override;
    procedure Loaded; override;
    procedure OpenCursor(InfoQuery: Boolean); override;
    function  GetSQLText : string;
    function  ConvertExecToIB(SQL : string) : string;
    procedure DoAfterClose; override;
    procedure DoBeforeClose; override;
    procedure DoBeforeCancel; override;
    procedure DoAfterCancel; override;
    procedure DoAfterExecute(var OwnerData: OleVariant); override;
    procedure DoAfterOpen; override;
    procedure DoBeforeOpen; override;
    procedure DoBeforePost; override;
    procedure DoBeforeEdit; override;
    procedure DoAfterPost; override;
    procedure DoAfterEdit; override;
    procedure DoOnNewRecord; override;
    procedure DoBeforeDelete; override;
    procedure DoBeforeInsert; override;
    procedure InternalDelete; override;
    procedure DoAfterDelete; override;
    procedure DoBeforeScroll; override;
    procedure DoAfterScroll; override;
    procedure DoAfterRefresh; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function  BookMarkIndex : integer;
    procedure DeleteBookMark;
    function  GetKeyBookMark : TKeyBookMark;
    function  RecKeyBookMark : TKeyBookMark;
    function  CanPaste(V : Variant) : boolean; overload;
    function  GetDetailList : TObjectList;
    function  CanApply : boolean;
    function  GetInApply : boolean;
    procedure CheckConnected;
    procedure DeleteDetails;
    function  CreateADOStream(AField : TField) : TStream;
    function  CreateMidasStream(AField : TField) : TStream;
    procedure ApplyErr(Err, SQL : string);
    procedure MasterModify(Insert : boolean = False);
    procedure MasterModified;
    function  GetLockMaster : TxClientDataSet;
    function  GetLocked : boolean;
    property  Index_Fields[Index: Integer]: TField read GetIndex_Field write SetIndex_Field;
  public
    RefFields   : TRefFields;
    LastChangeIdent : array of TChangeIdent;
    ZipBlob : boolean;
    Reference : boolean;
    IdentName  : string;
    function  UpdateDetailDataSetList : TObjectList;
    function  LoadPackets(Clear : boolean) : boolean;
    procedure SetCalcField(Field : TField; const Value: Variant);
    function  LockMaster : TLockResult;
    function  LockRecord(Lock : boolean; Force : boolean = False) : TLockResult;
    function  UpdateRef(const RefName : string)  : boolean;
    function  BlobValue(AField : TField) : OleVariant;
    function  CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream; override;
    function  GetBlobInfo(Field: TField) : PBlobInfo;
    procedure AddBlobInfo(ABlobField : TBlobField; ABlobName : TStringField; ABlobDate : TDateTimeField);
    procedure LogRec(S : string);
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure Execute; override;
    function  Master : TxClientDataSet;
    procedure MergeChanges;
    function  CallInfo : string;
    procedure RefreshDetails;
    procedure CopyToClipboard(SelectedRows: TBookmarkList = nil);
    procedure PasteFromClipBoard;
    function  RecState : char;
    function  CanPaste : boolean; overload;
    procedure StrictCopyFrom(CDS : TxClientDataSet; New : boolean = True);
    function  Edited  : boolean;
    function  RecordModified : boolean;
    procedure Post; override;
    procedure DoRevertRecord;
    function  TableName : string;
    function  ApplyDataSetUpdates : boolean;
    procedure DoBeforeApplyUpdates(var OwnerData: OleVariant); override;
    procedure CancelDataSetUpdates;
    function  GetRecAttr : DSAttr;
    function  ConvertADOToIB(SQL : string; Params : TParams; DeleteDog : boolean = True) : string;
    procedure CreateTable(Exists : boolean = False);
    function  NewIdent(OldId : Integer) : Integer;

    property  IdentField : TField read FIdentField;
    property  Identity   : LongInt read FIdentity;
    property  DetailDataSets : TObjectList read GetDetailList;
    property  RemoteServer;
    property  AutoInc : integer read GetAutoInc write FAutoInc;
    property  SQLtext : string read GetSQLtext;
    property  InApply  : boolean read GetInApply;
    property  Locked : boolean read GetLocked;
    property  NeedLock : boolean read FNeedLock write SetNeedLock;
    property  InsertIdentity : boolean read FInsertIdentity write FInsertIdentity;
    property  UserIdentity : boolean read FUserIdentity write FUserIdentity;
  published
    property Connection : TcustomxConnection read FConnection write SetConnection;
    property TransType  : TUserTransType read FTransType write FTransType;
    property ResultSet  : boolean read FResultSet write SetResultSet default True;
    property TimeOut    : integer read FTimeOut write SetTimeOut default 60;
    property CanEmpty   : boolean read FCanEmpty write FCanEmpty;
    property UpdateMode : TUpdateMode read FUpdateMode write FUpdateMode;
    property GenName    : string read FGenName write FGenName;
    property DeleteProc : string read FDeleteProc write FDeleteProc;
    property ApplyTable : string read FApplyTable write FApplyTable;
    property UniqueKey  : string read FUniqueKey write FUniqueKey;

    property OnApplyInsert: TOnApplyInsert read FOnApplyInsert write FOnApplyInsert;
    property OnApplyModified : TOnApplyModified read FOnApplyModified write FOnApplyModified;
    property OnApplyDeleted  : TOnApplyDeleted read FOnApplyDeleted write FOnApplyDeleted;
    property OnMasterModify  : TOnMasterModify read FOnMasterModify write FOnMasterModify;
    property OnMasterModified  : TDataSetNotifyEvent read FOnMasterModified write FOnMasterModified;
    property BeforeApplyRecord : TDataSetNotifyEvent read FBeforeApplyRecord write FBeforeApplyRecord;
    property CommandText : TStrings read FSQL write SetSQL;
    property Transactional: boolean read FTransactional write SetTransactional;
    property PacketRecords;
    property FileName;
    property FetchOnDemand;
    property MasterFields;
    property MasterSource;
    property AutoCalcFields;
    property Constraints;
    property DataSetField;
    property DisableStringTrim;
    property FieldDefs;
    property IndexDefs;
    property ObjectView;
    property StoreDefs;
    property Params;
    property Active;
    property Filter;
    property Filtered;
    property FilterOptions;
    property ProviderName;
    property IndexName;
    property ReadOnly;
    property IndexFieldNames;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
    property BeforeRefresh;
    property AfterRefresh;
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;
    property OnReconcileError;
    property BeforeApplyUpdates;
    property AfterApplyUpdates;
    property BeforeGetRecords;
    property AfterGetRecords;
    property BeforeRowRequest;
    property AfterRowRequest;
    property BeforeExecute;
    property AfterExecute;
    property BeforeGetParams;
    property AfterGetParams;
  end;

  // by Jimmy, 21.05.2004
  TxSortedClientDataSet = class(TxClientDataSet)
  protected
   FSort: string;
   Procedure SetSort(Value:string);
   procedure DoAfterOpen; override;
   Procedure DoAfterClose; override;
  published
   property Sort: string read FSort Write SetSort;
  end;

  TMidasStream = class(TStringStream)
  end;

  TSQLStream = class(TStringStream)
  end;

  TPar  = class(TParameter)
  end;

  TCastCDS = class(TCustomClientDataSet)
  end;

  TCastADO = class(TCustomADODataSet)
  end;

  TCompressionStream = class(TZCompressionStream)
  private
    FDest: TStream;
  public
    constructor DoCreate(dest: TStream;
      compressionLevel: TZCompressionLevel = zcDefault);
    destructor  Destroy; override;
  end;

  TDeCompressionStream = class(TZDeCompressionStream)
  private
    FSource: TStream;
  public
    constructor DoCreate(source: TStream);
    destructor  Destroy; override;
  end;

function GetRemoteAddress(Address : string) : TInAddr;
procedure RequiredField(Field : TField);
function GetRouteV6x(PFType, St, CnFrom, CnTo: PChar; DateCalc: TDateTime;
  xConn: TCustomxConnection): integer;
  external 'RouteClc.dll';

function  NextSQLToken(var PSQL : PChar; var Token : string; DeleteDog : boolean = True): TTokenType;
function  NextNotBlankSQLToken(var PSQL : PChar; var Token : string; DeleteDog : boolean = True): TTokenType;
function  GetSQLTokenValue(SQL : string; TokenType : TTokenType; DeleteDog : boolean = True) : string;
procedure GetSQLParams(SQL : string; Params : TParams; DeleteDog : boolean = True);
function  RusLanguage : boolean;
function  ParamInfo(Params : TParams) : string; overload;
function  GetFileStream(FileName : string) : TStream;
function  BlobFetched(Field: TField): boolean;
function  BlobLen(Field: TField): Integer;

var
  FUpdatedRefs  : TStringList = nil;

procedure Register;

var
  VClipBoard : Variant;
  DelProc    : TxClientDataSet = nil;
  RusLang    : boolean = True;

implementation

uses StrUtils, CryptString, CustomConnect, IBIntf, IBInsert, Math,
  TypInfo, FMTBcd, UGetPass, URegIni1, Logger, URegS, UNetApi{$IFNDEF VER150},DBCommonTypes{$ENDIF};


procedure TxClientDataSet.CreateTable(Exists : boolean = False);
var I  : integer;
    Coll, Tp, Tail : string;
    S : TStringList;
    Table : TIBTable;
begin
  S := TStringList.Create;
  try
    if ConnectType = ctADO then
    begin
      S.Add('if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[' + TableName + ']'') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)');
      S.Add('drop table [dbo].[' + TableName + ']');
      S.Add('CREATE TABLE [dbo].[' + TableName + '] (');
      for I := 0 to FieldCount - 1 do with Fields[ I ] do
      begin
        case DataType of
          ftSmallInt : Tp := '[smallint]';
          ftInteger  :
            if Fields[ I ] = IdentField then
              Tp := '[int] identity(1,1)'
            else
              Tp := '[int]';
          ftLargeint : Tp := '[bigint]';
          ftString   :
            if TStringField(Fields[ I ]).FixedChar then
              Tp := '[char] (' + IntToStr(Size) + ')'
            else
              Tp := '[varchar] (' + IntToStr(Size) + ')';
          ftWideString:
            if TStringField(Fields[ I ]).FixedChar then
              Tp := '[nchar] (' + IntToStr(Size) + ')'
            else
              Tp := '[nvarchar] (' + IntToStr(Size) + ')';
          ftMemo     : Tp := '[text]';
          ftDateTime : Tp := '[datetime]';
          ftFloat    : Tp := '[float]';
          ftWord     : Tp := '[tinyint]';
          ftGuid     : Tp := '[uniqueidentifier]';
          ftVariant  : Tp := '[sql_variant]';
          ftVarBytes : Tp := '[varbinary] (' + IntToStr(Size) + ')';
          ftBytes    :
            begin
              if Size = 8 then
                Tp := '[timestamp]'
              else
                Tp := '[binary] (' + IntToStr(Size) + ')';
            end;
          ftBCD      :
            with TBCDField(Fields[ I ]) do
            begin
              if (Precision = 19) and (Size = 4) then
                Tp := '[money]'
              else if (Precision = 10) and (Size = 4) then
                Tp := '[smallmoney]'
              else
                TP := '[numeric] (' + IntToStr(Precision) + ',' + IntToStr(Size) + ')';
            end;
          ftAutoInc  : Tp := '[int] identity(1,1)';
          ftBoolean  : Tp := '[bit]';
          ftBlob, ftGraphic : Tp := '[image]';
        end;
        if DataType in [ ftString, ftMemo ] then
          Coll := ' COLLATE SQL_Latin1_General_CP1251_CI_AS'
        else
          Coll := '';
        Tail := ',';
        if I = FieldCount - 1 then
          Tail := '';
        if Required or (DataType = ftAutoInc) or (Fields[ I ] = IdentField) then
          Tail := ' NOT NULL' + Tail
        else
          Tail := ' NULL' + Tail;
        S.Add('  [' + FieldName + '] ' + Tp + Coll + Tail);
      end;
      S.Add(') ON [PRIMARY]');
      Connection.ExecSQL(S.Text);
    end else if ConnectType = ctIB then
    begin
      if FieldDefs.Count = 0 then
        for I := 0 to Fields.Count - 1 do with Fields[ I ] do
          FieldDefs.Add(FieldName, DataType, Size, Required);
      Table := TIBTable.Create(nil);
      with Table do
      try
        TableName   := Self.TableName;
        DataBase    := Connection.IBDataBase;
        Transaction := Connection.IBTransactions[ utReadWrite ];
        Transaction.Active := True;
        try
          FieldDefs.Assign(Self.FieldDefs);
          for I := 0 to FieldDefs.Count - 1 do with FieldDefs[ I ] do
            if DataType = ftAutoInc then
            begin
              Attributes := Attributes - [faReadonly];
              DataType   := ftInteger;
              if GenName = '' then
                GenName    := TableName + '_GEN';
              Break;
            end;
          if Exists then
          begin
            DeleteTable;
            Connection.DeleteGenerator(GenName);
          end;
          Connection.CreateGenerator(GenName);
          CreateTable;
          Transaction.Commit;
        except
          Transaction.Rollback;
          raise;
        end;
      finally
        Free;
      end;
    end;
  finally
    S.Free;
  end;
end;

procedure TCustomxConnection.GetTableNames(Tables : TStringList);
begin
  if ConnectionType = ctADO then
    ADOConnection.GetTableNames(Tables)
  else if ConnectType = ctIB then
    FIBDataBase.GetTableNames(Tables);
end;

function RusLanguage : boolean;
begin
  Result := RusLang;
end;

constructor TKeyBookMark.Create;
begin
  inherited Create;
  Updates := TStringList.Create;
end;

destructor TKeyBookMark.Destroy;
begin
  Updates.Free;
  inherited Destroy;
end;

function HandleException(Sender : TComponent; Info : string = '') : boolean;
begin
  if ExceptObject is Exception then
    Log((ExceptObject as Exception).Message);
  Log(Info);
  Result := True;
  if csDesigning in Sender.ComponentState then
    if Assigned(Classes.ApplicationHandleException) then
      Classes.ApplicationHandleException(ExceptObject)
    else
      ShowException(ExceptObject, ExceptAddr)
  else
    Result := False;
end;

function GetFileStream(FileName : string) : TStream;
var IsUnicode : BOOL;
    Buff   : string;
    PBuff  : PWideChar;
    nRead, Len  : integer;
begin
  Result := TFileStream.Create(FileName, fmShareDenyWrite);
  try
//    if not SameText(ExtractFileExt(FileName), '.sql') then
//      Exit;
    Len := Result.Size;
    SetLength(Buff, Len);
    nRead := Result.Read(Buff[ 1 ], Len);
    FreeAndNil(Result);
    if nRead <> Len then
      raise Exception.Create(SysErrorMessage(GetLastError));
    PBuff := @Buff[ 1 ];
    IsUnicode := IsTextUnicode(PBuff, Len, nil);
    if IsUnicode then
    begin
      if PBuff^ = WideChar($FEFF) then
      begin
        Inc(PBuff);
        Dec(Len, 2);
      end;
      Buff := WideCharLenToString(PBuff, Len div 2);
    end;
    Result := TSQLStream.Create(Buff);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TCustomxConnection.GetRouteM(PFType : Char; StLine, CnFrom, CnTo : string; DateCalc : TDate) : Integer;
begin
  Result := -1;
  Connected := True;
  case ConnectionType of
    ctADO, ctIB :
      GetRouteV6x(PChar(string(PFType)), PChar(StLine),
        PChar(CnFrom), PChar(CnTo), DateCalc, Self);
    ctMidas :
      Result := AppServerDisp.GetRouteM(Ord(PFType), StLine, CnFrom, CnTo, DateCalc);
  end;
end;


function VarAsStr(V : Variant) : string;
begin
  if VarIsNull(V) then
    Result := 'null'
  else if VarIsEmpty(V) then
    Result := 'unassigned'
  else
    Result := VarToStr(V);
end;


function ParamInfo(Params : TParams) : string; overload;
var I : integer;
    S : string;
begin
  Result := '';
  for I := 0 to Params.Count - 1 do with Params[ I ] do
  begin
    if DataType in [ftBlob..ftmemo, ftOraBlob..ftOraClob] then
    begin
      if IsNull then
        S := 'Null'
      else
        S := 'NotNull';
    end else
      S := VarAsStr(Value);
    Result := Result + '    ' + Name + ', ' +
      GetEnumName(TypeInfo(TFieldType), Ord(DataType)) + ', ' +
      IntToStr(Size) + ', ' +
      GetEnumName(TypeInfo(TParamType), Ord(ParamType)) + ', ' +
      S + #13#10;
  end;
end;

function ParamList(Params : TParams) : string; overload;
var I : integer;
    S : string;
begin
  Result := '';
  for I := 0 to Params.Count - 1 do with Params[ I ] do
  begin
    if DataType in [ftBlob..ftmemo, ftOraBlob..ftOraClob] then
    begin
      if IsNull then
        S := 'Null'
      else
        S := 'NotNull';
    end else
      S := VarAsString(DataType, Value);
    if Result = '' then
      Result := S
    else
    Result := Result + ', ' + S;
  end;
end;

function ParamInfo(Params : TParameters) : string; overload;
var I : integer;
begin
  Result := '';
  for I := 0 to Params.Count - 1 do with Params[ I ] do
    Result := Result + '    ' + Name + ', ' +
      GetEnumName(TypeInfo(TFieldType), Ord(DataType)) + ', ' +
      IntToStr(Size) + ', ' +
      GetEnumName(TypeInfo(TParameterDirection), Ord(Direction)) + ', ' +
      VarToStr(Value) + #13#10;
end;

function GetRemoteAddress(Address : string) : TInAddr;
var
  HostEnt: PHostEnt;
  WSAData: TWSAData;
begin
  FillChar(Result, SizeOf(Result), 0);
  if WSAStartup($0101, WSAData) <> 0 then
    Exit;
  HostEnt := gethostbyname(PChar(Address));
  if HostEnt <> nil then
  begin
    with Result, HostEnt^ do
    begin
      S_un_b.s_b1 := h_addr^[0];
      S_un_b.s_b2 := h_addr^[1];
      S_un_b.s_b3 := h_addr^[2];
      S_un_b.s_b4 := h_addr^[3];
    end;
  end;
  WSACleanup;
end;

procedure RequiredField(Field : TField);
begin
  with Field do
    if IsNull then
    begin
      FocusControl;
      raise Exception.Create('Заполните поле : ' + DisplayName);
    end;
end;

function BlobLen(Field: TField): Integer;
var
  Status: DBResult;
  BlobLen: DWord;
begin
  with TCastCDS(Field.DataSet) do
    Status := DSCursor.GetBlobLen(ActiveBuffer, Field.FieldNo, BlobLen);
  if (Status = DBERR_BLOBNOTFETCHED) then
    Result := 0
  else
    Result := Integer(BlobLen);
end;

function BlobFetched(Field: TField): boolean;
var
  Status: DBResult;
  BlobLen: DWord;
begin
  with TCastCDS(Field.DataSet) do
    Status := DSCursor.GetBlobLen(ActiveBuffer, Field.FieldNo, BlobLen);
  Result := (Status <> DBERR_BLOBNOTFETCHED);
end;

function TxClientDataSet.NewBlobData(Field: TField): Boolean;
var Info : PBlobInfo;
    OldDate : Double;
    OldName : string;
begin
  Info := GetBlobInfo(Field);
  if Info = nil then
    Result := FetchOnDemand and (BlobLen(Field) > 0) or not FetchOnDemand and not VarSameValue(Field.NewValue, Field.OldValue)
  else with Info^, BlobDate do
  begin
    if VarType(OldValue) <= varNull then
      OldDate := 0
    else
      OldDate := VarAsType(OldValue, varDouble);
    if VarType(BlobName.OldValue) <= varNull then
      OldName := ''
    else
      OldName := VarAsType(BlobName.OldValue, varString);
    Result := (BlobLen(Field) > 0) or (Value <> OldDate) or (BlobName.Value <> OldName);
  end;
end;

function TxClientDataSet.IsIdent(Field: TField): Boolean;
begin
   Result := FIdentField = Field;
end;

function TxClientDataSet.HasBlobData(Field: TField): Boolean;
var Info : PBlobInfo;
begin
  Info := GetBlobInfo(Field);
  if Info = nil then
    Result := BlobLen(Field) > 0
  else with Info^ do
  begin
    Result := (BlobLen(Field) > 0) or (BlobDate.AsFloat <> 0) and (BlobName.AsString <> '');
  end;
end;

function TxClientDataSet.UseFieldInUpdate(Fld: TField): Boolean;
const
  ExcludedTypes = [ftAutoInc, ftDataSet, ftADT, ftArray, ftReference, ftCursor, ftUnknown];
begin
  with Fld do
  begin
    Result := (pfInUpdate in ProviderFlags) and not (DataType in ExcludedTypes) and
      not ReadOnly and (FieldKind = fkData) and not (pfHidden in ProviderFlags) and
      not IsIdent(Fld) and
     (not IsBlob and ( (VarType(OldValue) <= varNull) and (VarType(NewValue) > varNull)
          or (VarType(OldValue) > varNull) and
                 ((VarType(NewValue) <= varNull) or not VarSameValue(NewValue, OldValue)) )
     or IsBlob and NewBlobData(Fld));
  end;
end;

function TxClientDataSet.UseFieldInInsert(Fld: TField): Boolean;
const
  ExcludedTypes = [ftAutoInc, ftDataSet, ftADT, ftArray, ftReference, ftCursor, ftUnknown];
begin
  with Fld do
  begin
    Result := (pfInUpdate in ProviderFlags) and not (DataType in ExcludedTypes) and
      not ReadOnly and (FieldKind = fkData) and not (pfHidden in ProviderFlags) and
      (not IsIdent(Fld) or FInsertIdentityOn) and
     (not IsBlob and (VarType(NewValue) > varNull) and not ((DataType = ftString) and (AsString = '')) or IsBlob and HasBlobData(Fld));
  end;
end;

function TxClientDataSet.UseFieldInWhere(Field: TField; Mode: TUpdateMode): Boolean;
const
  ExcludedTypes = [ftDataSet, ftADT, ftArray, ftReference, ftCursor, ftUnknown ];
begin
  with Field do
  begin
    Result := not (DataType in ExcludedTypes) and not IsBlob and
      (FieldKind = fkData);
    if Result then
      case Mode of
        upWhereAll:
          Result := pfInWhere in ProviderFlags;
        upWhereChanged:
          Result := ((pfInWhere in ProviderFlags) and not VarIsClear(NewValue)) or
            (pfInKey in ProviderFlags);
        upWhereKeyOnly:
          Result := pfInKey in ProviderFlags;
      end;
  end;
end;

procedure TCustomxConnection.JoinParams(const Source: OleVariant; Dest: TParams);
var
  I     : Integer;
  pName : string;
  Par   : TParam;
  HasDog, New : boolean;
begin
  if not VarIsNull(Source) and VarIsArray(Source) and VarIsArray(Source[ 0 ]) then
  begin
    HasDog := (Dest.Count > 0) and (Length(Dest[ 0 ].Name) > 0) and (Dest[ 0 ].Name[ 1 ] = '@');
    for I := 0 to VarArrayHighBound(Source, 1) do
    begin
      pName := Source[ I ][ 0 ];
      if HasDog and (Length(pName) > 0) and (pName[ 1 ] <> '@') then
        pName := '@' + pName;
      Par := Dest.FindParam(pName);
      New := not Assigned(Par);
      if New then
        Par := TParam(Dest.Add);
      with Par do
      begin
        if New then
        begin
          Name  := pName;
          if VarArrayHighBound(Source[ I ], 1) > 2 then
            ParamType := TParamType(Source[ I ] [ 3 ]);
          if VarArrayHighBound(Source[ I ], 1) > 1 then
            DataType := TFieldType(Source[ i ] [ 2 ]);
        end;
        if ParamType in [ptOutput, ptInputOutput, ptResult] then
          Value := Source[ I ][ 1 ];
      end;
    end;
  end;
end;

function TCustomxConnection.DelDog(Param : string) : string;
begin
  Result := Param;
  if DeleteDog and (Length(Result) > 0) and (Result[ 1 ] = '@') then
    System.Delete(Result, 1, 1);
end;

function TCustomxConnection.AddDog(Param : string) : string;
begin
  Result := Param;
  if DeleteDog and (Length(Result) > 0) and (Result[ 1 ] <> '@') then
    Result := '@' + Result;
end;

function TCustomxConnection.ConnectType : TConnectionType;
begin
  if (csDesigning in ComponentState) and (ConnectionType = ctMidas) then
    Result := ctADO
  else
    Result := ConnectionType;
end;

function  TCustomxConnection.GetInTransaction : boolean;
begin
  Result := FInTransaction;
end;

function TCustomxConnection.BeginTrans(TransType : TUserTransType = utReadWrite): Integer;
begin
  Connected := True;
  FTransType := TransType;
  Result := 0;
  case ConnectionType of
    ctADO   : Result := ADOConnection.BeginTrans;
    ctIB    : FIBDataBase.DefaultTransaction.StartTransaction;
    ctMidas : Result := FAppServerDisp.BeginTrans;
  end;
  FInTransaction := True;
end;

procedure TCustomxConnection.CommitTrans;
begin
  case ConnectionType of
    ctADO   : ADOConnection.CommitTrans;
    ctIB    : FIBDataBase.DefaultTransaction.Commit;
    ctMidas : FAppServerDisp.CommitTrans;
  end;
  FInTransaction := False;
end;

procedure TCustomxConnection.RollbackTrans;
begin
  case ConnectionType of
    ctADO   : ADOConnection.RollbackTrans;
    ctIB    : FIBDataBase.DefaultTransaction.Rollback;
    ctMidas : FAppServerDisp.RollbackTrans;
  end;
  FInTransaction := False;
end;

procedure TCustomxConnection.ExecProc(const AProcedureName: string;
   ProcParams : TParams; TimeOut: Integer);
var {P   : TParam;
    I   : integer;}
    cds : TxClientDataSet;
begin
  CheckConnected;
  cds := TxClientDataSet.Create(nil);
  try
    cds.Connection := Self;
    cds.CommandText.Text := AProcedureName;
    cds.Timeout := TimeOut;
    cds.Params.Assign(ProcParams);
    cds.Execute;
    ProcParams.Assign(cds.Params);
{    for I := 0 to cds.Params.Count - 1 do with cds.Params[ I ] do
    begin
      P := .FindParam(Name);
      if P <> nil then
        P.Assign(cds.Params[ I ]);
    end;}
  finally
    cds.Free;
  end;
end;

function TCustomxConnection.ExecSQL(PSQL : string; PTimeOut : integer = 30) : boolean;
var Q   : TADOQuery;
    I   : TIBQuery;
begin
  CheckConnected;
  Result := True;
  case ConnectionType of
    ctADO :
      begin
        Q := TADOQuery.Create(nil);
        try
          Q.Connection  := ADOConnection;
          Q.CommandTimeout := PTimeOut;
          Q.SQL.Text := PSQL;
          CheckConnectionErrors;
        finally
          Q.Free;
        end;
      end;
    ctIB :
      begin
        I := TIBQuery.Create(nil);
        try
          I.DataBase := IBDataBase;
          I.Transaction := IBTransactions[ utReadWrite ];
          I.Transaction.IdleTimer := PTimeOut * 1000;
          I.SQL.Text := PSQL;
          I.ExecSQL;
          Result := True;
        finally
          I.Free;
        end;
      end;
    ctMidas :
      Result := AppServerDisp.ExecSQL(PSQL, PTimeOut) > 0;
  end;
end;

procedure TCustomxConnection.DoException(E : Exception; Info : string = '');
var ErrInfo : string;
begin
  if csDesigning in ComponentState then
  begin
    HandleException(Self, Info)
  end else
  begin
    ErrInfo := E.Message + #13#10 + Info;
    Log(ErrInfo);
    if (E is ESocketConnectionError) or (E is ESocketError) then
    begin
      Disconnect;
    end;
    raise Exception.Create(E.Message);
  end;
end;

function TCustomxConnection.GetTransaction(const TransType : TUserTransType) : TIBTransaction;
begin
  if CanIB then
    Result := FIBTransactions[ TransType ]
  else
    Result := nil;
end;

{function TCustomxConnection.TableLastUpdate(FName : string) : TDateTime;
var I : integer;
    V : string;
begin
  Result   := 0;
  if Trim(FName) = '' then
    Exit;
  FName := ExtractFileName(FName);
  V := ExtractFileExt(FName);
  FName := Copy(FName, 1, Length(FName) - Length(V));
  I := FUpdatedRefs.IndexOfName(V);
  if I = -1 then
    Exit;
  with FUpdatedRefs do
    V := Trim(Values[ Names[ I ] ]);
  if V = '0' then
    Result := Max(1900, Result)
  else if V <> '' then
    Result := Max(StrToDateTime(V), Result);
end;
}

function TCustomxConnection.TableLastUpdate(TableNames : string) : TDateTime;
var I, Iscan, PrevPos : integer;
    V, S : string;
begin
  Result   := 0;
  if Trim(TableNames) = '' then
    Exit;
  PrevPos  := 1;
  repeat
    Iscan := PosEx(',', TableNames, PrevPos);
    if Iscan = 0 then
      S := Trim(Copy(TableNames, PrevPos, MAXINT))
    else
      S := Trim(Copy(TableNames, PrevPos, Iscan - PrevPos));
    if not IsValidIdent(S) then
      raise Exception.Create('LastUpdate/Bad table name : ' + S);
    I := FUpdatedRefs.IndexOfName(S);
    if I = -1 then
      Exit;
    with FUpdatedRefs do
      V := Trim(Values[ Names[ I ] ]);
    if V = '0' then
      Result := Max(1900, Result)
    else if V <> '' then
      Result := Max(StrToDateTime(V), Result);
    PrevPos := Iscan + 1;
  until Iscan = 0;
end;

function TCustomxConnection.CanLocalConnect : boolean;
begin
//  with SysRegIni do
//    Result := Developer or not Remote;
  Result := True;
end;

procedure TCustomxConnection.UnregisterClient(Client : TxClientDataSet);
begin
  FClients.Remove(Client);
end;

procedure TCustomxConnection.RegisterClient(Client : TxClientDataSet);
begin
  FClients.Add(Client);
end;

constructor TCustomxConnection.Create(AOwner : TComponent);
var I : TUserTransType;
begin
  inherited Create(AOwner);
  FClients := TObjectList.Create;
  FClients.OwnsObjects := False;
  DelayConnect   := True;
  FDBName        := 'tses2';
  FDBMain        := 'tses2';
  FServerName    := 'sql2000';
  FPingInterval  := 1;
  FAppServerGUID := GuidToString(CLASS_XFRAppServer);
  FAppHost       := 'app.tses.ru';
//  RemoteAddr := GetRemoteAddress('app.tses.ru');
  FAppPort       := 211;
  FCanADO  := True;
  try
    FADOConnection := TADOConnection.Create(Self);
    with FADOConnection do
    begin
      LoginPrompt := False;
    end;
  except
    FCanADO := False;
  end;

  FCanIB := True;
  try
    FIBDataBase := TIBDataBase.Create(Self);
    with FIBDataBase do
    begin
      SQLDialect := 3;
      LoginPrompt := False;
    end;
    for I := Low(TUserTransType) to High(TUserTransType) do
    begin
      FIBTransactions[ I ] := TIBTransaction.Create(Self);
      with FIBTransactions[ I ] do
        DefaultDataBase := FIBDataBase;
    end;
    with FIBTransactions[ utReadOnly ] do
    begin
      Params.Add(TPBConstantNames[ isc_tpb_shared ]);
      Params.Add(TPBConstantNames[ isc_tpb_read ]);
    end;
    with FIBTransactions[ utReadWrite ] do
    begin
      Params.Add(TPBConstantNames[ isc_tpb_concurrency ]);
      Params.Add(TPBConstantNames[ isc_tpb_write ]);
    end;
  except
    FCanIB := False;
  end;
  FRemoteServer := TSesSocketConnection.Create(Self);
end;

destructor TCustomxConnection.Destroy;
begin
  FADOConnection.Free;
  FIBDataBase.Free;
  FRemoteServer.Free;
  FClients.Free;
  inherited Destroy;
end;

procedure TCustomxConnection.SetConnectionType(Value : TConnectionType);
//var I : integer;
begin
  if not CanLocalConnect then
    Value := ctMidas
  else if not CanADO and (Value = ctADO) then
    Value := ctMidas
  else if not CanIB and (Value = ctIB) then
    Value := ctMidas;
  if Value = ConnectionType then
    Exit;
  FConnectionType := Value;
  if not Loading then
    Disconnect
{  else
    for I := 0 to Clients.Count - 1 do
      TxClientDataSet(Clients[ I ]).PrepareProvider;}
end;

function TCustomxConnection.GetConnected : boolean;
begin
  case ConnectType of
    ctADO   : Result := ADOConnection.Connected;
    ctIB    : Result := IBDataBase.Connected;
    ctMidas : Result := RemoteServer.Connected;
  else
    Result := False;
  end;
end;

procedure TCustomxConnection.DoAfterConnect;
begin
  if Assigned(FAfterConnect) then FAfterConnect(Self);
end;

procedure TCustomxConnection.DoAfterDisconnect(Sender : TObject);
begin
  if csDestroying in ComponentState then
    Exit;
  if Assigned(FAfterDisconnect) then FAfterDisconnect(Self);
  case ConnectType of
    ctADO   : ADOConnection.AfterDisconnect := nil;
    ctIB    : IBDataBase.AfterDisconnect := nil;
    ctMidas :
      begin
        RemoteServer.AfterDisconnect := nil;
      end;
  end;
end;

procedure TCustomxConnection.DoBeforeDisconnect(Sender : TObject);
begin
  if csDestroying in ComponentState then
    Exit;
  if Assigned(FBeforeDisconnect) then FBeforeDisconnect(Self);
end;

procedure TCustomxConnection.CheckConnectionErrors;
var I : integer;
    S : string;
begin
  if ConnectionType = ctADO then
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

function TCustomxConnection.GetConnectInfo : boolean;
begin
  try
    Result := DoGetConnectInfo('');
    if Connected then
      DoAfterConnect;
  except
    Result := False;
  end;
end;

function TCustomxConnection.DoGetConnectInfo(Msg : string) : boolean;
begin
  if not SysRegIni.Developer then
  begin
    Result := AcceptNamePass(Self, Msg);
    if not Result then
      Abort;
    Exit;
  end;
  FormCustomConnect  := TFormCustomConnect.Create(nil);
  try
    FormCustomConnect.Caption := Caption;
    with FormCustomConnect do
    begin
      SavePass.Checked := Save_Pass;
      Connection := Self;
      if ConnectionType = ctADO then
        rb_SQL_Server.Checked := True
      else if ConnectionType = ctIB then
        rb_IB_Server.Checked := True
      else
        rb_App_Server.Checked := True;
      ErrText.Caption := Msg;
      rb_SQL_Server.Enabled := CanADO;
      rb_IB_Server.Enabled  := CanIB;
      EditServer.Text    := FServerName;
      EditServer.Enabled := (CanADO or CanIB) and CanLocalConnect;
      EditDB.Text        := FDBName;
      EditDB.Enabled     := EditServer.Enabled;
      EditIBDB.Text      := FDBMain;
      EditIBDB.Enabled   := EditServer.Enabled;
      EditUser.Text      := FLogin;
      EditPsw.Text       := FPassword;
      Port.Text          := IntToStr(FAppPort);
      Host.Text          := FAppHost;
      IB.Checked         := FAppServerIB;

      Result := ShowModal = mrOK;
      Save_Pass := SavePass.Checked;

      if not Result then
      begin
        if not Connected then
        begin
          if Modified and Assigned(OnResetConnectInfo) then
            OnResetConnectInfo(Self, SaveInfo);
          if ResExcept <> '' then
            raise Exception.Create(ResExcept)
          else
            Abort;
        end;
      end;
      if Modified and Assigned(OnUpdateConnectInfo) then
        OnUpdateConnectInfo(Self, SaveInfo);
    end;
  finally
    FormCustomConnect.Free;
  end;
end;

procedure TCustomxConnection.CloseDataSets;
var I : integer;
begin
  for I := 0 to Clients.Count - 1 do with TxClientDataSet(Clients[ I ]) do
  begin
    FActive := Active;
    Active  := False;
  end;
end;

procedure TCustomxConnection.ReopenDataSets;
var I : integer;
begin
  for I := 0 to Clients.Count - 1 do with TxClientDataSet(Clients[ I ]) do
    if FActive then
    begin
      Open;
      FActive := False;
    end;
end;

procedure TCustomxConnection.Assign(Source : TPersistent);
begin
  if (Source = nil) or not (Source is TCustomxConnection) then
     Exit;
   Connected := False;
   with (Source as TCustomxConnection) do
   begin
     Self.ConnectionType := ConnectionType;
     Self.DBName  := DBName;
     Self.ServerName := ServerName;
     Self.DBMain  := DBMain;
     Self.Login := Login;
     Self.Password := Password;
     Self.KeyDir := KeyDir;

     Self.AppServerGUID := AppServerGUID;
     Self.AppHost := AppHost;
     Self.Caption := Caption;
     Self.AppPort := AppPort;
     Self.DelayConnect := DelayConnect;
     Self.AppServerIB := AppServerIB;
     Self.DeleteDog := DeleteDog;
     Self.SystemMode := SystemMode;
     Self.SilentMode := SilentMode;
   end;
end;

procedure TCustomxConnection.ADOConnect;
var ADOlogin: TADOQuery;
    CryptPass, CryptName{, AppCode} : string;
begin
  with ADOConnection do
  begin
    ConnectionTimeout:= 10;
    ConnectionString := 'Provider=SQLOLEDB.1;Persist Security Info=True'
          + ';Data Source=' + FServerName + ';Initial Catalog=' + ifthen(FSystemMode, FDBName, FDBMain)
          + ';Application Name=' + Application.Title;
    ADOlogin := TADOQuery.Create(nil);
    try
      if FSystemMode then
        Open(Login, Password)
      else
        Open('xconnadm', 'xconnadm_tbc');
      with ADOlogin do
      begin
        Connection := ADOConnection;
        if (FUpdatedRefs.Count = 0) and not NoRefModInfo then
          try
            SQL.Text   := 'select * from Remote_Ref_List';
            Open;
            while not EOF do
            begin
              FUpdatedRefs.Add(Trim(Fields[ 0 ].AsString) + '=' + Fields[ 1 ].AsString);
              Next;
            end;
            Close;
          except
            if not FSystemMode then
              raise;
          end;
        if FSystemMode then
          Exit;
        if Assigned(AfterSysConnect) then
           AfterSysConnect(Self);
        CryptPass := AnsiQuotedStr(EncodeString(Password), '''');
        CryptName := AnsiQuotedStr(EncodeString(Login), '''');
        Execute('SET ANSI_WARNINGS OFF');
        SQL.Text   := 'select Emp_Company_Uid, Emp_Name, Emp_Password_SQL, Emp_Language from Emp where Emp_Login_Remote = ' +
          CryptName + ' and Emp_Password_Remote = ' + CryptPass;
        Open;
        try
          uName       := FieldByName('Emp_Name').AsString;
          uPass       := DecodeString(FieldByName('Emp_Password_SQL').AsString);
          Emp_Company_Uid := FieldByName('Emp_Company_Uid').AsInteger;
          with FieldByName('Emp_Language') do
            if IsNull then
              Emp_Language := 'R'
            else
              Emp_Language := AsString;
        except
          uName := '';
        end;
        if uName = '' then
          raise Exception.Create('Bad name or password');
        Close;
      end;
      Connected := False;
      ConnectionString := 'Provider=SQLOLEDB.1;Persist Security Info=True'
          + ';Data Source=' + FServerName + ';Initial Catalog=' + FDBName
          + ';Application Name=' + Application.Title;
      Open(uName, uPass);
    finally
      if Connected then
      begin
        AfterDisconnect  := DoAfterDisconnect;
        BeforeDisconnect := DoBeforeDisconnect;
      end;
      ADOlogin.Free;
    end;
  end;
end;

procedure TCustomxConnection.IBConnect;
var IBlogin: TIBQuery;
    CryptPass, CryptName : string;
begin
  with IBDataBase do
  begin
    if Params.IndexOfName('user_name') = -1 then
      Params.Add('user_name');
    Params.Values[ 'user_name' ] := ifthen(FSystemMode, Login, 'xconnadm');
    if Params.IndexOfName('password') = -1 then
      Params.Add('password');
    Params.Values[ 'password' ] := ifthen(FSystemMode, Password, 'xconnadm_tbc');
    DataBaseName := ServerName + ':' + DBMain;
    Connected    := True;
    if FSystemMode then
      Exit;
    if Assigned(AfterSysConnect) then
       AfterSysConnect(Self);
    CryptPass := AnsiQuotedStr(EncodeString(Password), '''');
    CryptName := AnsiQuotedStr(EncodeString(Login), '''');
    IBLogin   := TIBQuery.Create(IBDataBase);
    try
      with IBLogin, Params do
      begin
        DataBase  := IBDataBase;
        SQL.Text   := 'select Emp_Company_Uid, Emp_Name, Emp_Password_SQL, Emp_Language from Emp where Emp_Login_Remote = ' +
          CryptName + ' and Emp_Password_Remote = ' + CryptPass;
        Open;
        try
          uName := FieldByName('Emp_Name').AsString;
          uPass := DecodeString(FieldByName('Emp_Password_SQL').AsString);
          Emp_Company_Uid := FieldByName('Emp_Company_Uid').AsInteger;
          with FieldByName('Emp_Language') do
            if IsNull then
              Emp_Language := 'R'
            else
              Emp_Language := AsString;
        except
          uName := '';
        end;
        if uName = '' then
          raise Exception.Create('Bad name or password');
      end;
      Connected := False;
      Params.Values[ 'user_name' ] := uName;
      Params.Values[ 'password' ]  := uPass;
      DataBaseName := ServerName + ':' + DBName;
      Connected := True;
      FUpdatedRefs.Clear;
      with IBLogin do
      begin
        SQL.Text  := 'select * from Remote_Ref_List';
        Open;
        while not EOF do
        begin
          FUpdatedRefs.Add(Trim(Fields[ 0 ].AsString) + '=' + Fields[ 1 ].AsString);
          Next;
        end;
      end;
    finally
      IBLogin.Free;
    end;
    AfterDisconnect  := DoAfterDisconnect;
    BeforeDisconnect := DoBeforeDisconnect;
  end;
end;

function ReadKey(FileName : string) : string;
var Stream : TFileStream;
begin
  if not FileExists(FileName) then
  begin
    Result := '';
    Exit;
  end;
  try
    Stream := TFileStream.Create(FileName, fmOpenRead);
    try
      SetLength(Result, Stream.Size);
      Stream.Read(Result[ 1 ], Stream.Size);
    finally
      Stream.Free;
    end;
  except
    Result := '';
  end;
end;

procedure TCustomxConnection.MidasConnect;
var wuName, wuPass, wEmp_LNG : WideString;
    MAC : string;
begin
  if FRenewRemoteServer then
  begin
    FRenewRemoteServer := False;
    FRemoteServer.Free;
    FRemoteServer := TSesSocketConnection.Create(Self);
  end;
  with RemoteServer do
  begin
    SupportCallbacks := False;
    ServerGUID   := GuidToString(CLASS_XFRAppServer);
    Host         := FAppHost;
    Port         := FAppPort;
    if KeyDir = '' then
    begin
      SetLength(FKeyDir, 261);
      FillChar(FKeyDir[ 1 ], 260, #0);
      GetSystemDirectory(PChar(FKeyDir), 260);
      KeyDir := Trim(FKeyDir);
    end;
    PublicKey  := ReadKey(KeyDir + '\asferor.dll');
    PrivateKey := ReadKey(KeyDir + '\asfsip.dll');
    if (PublicKey = '') or (PrivateKey = '') then
      raise Exception.Create('public key not found');
    Connected := True;
    FAppServerDisp := ITXFRAppServerDisp(IDispatch(AppServer));

    if ExternalClient then
    begin
      MAC := GetMACAdress;
      if MAC = '' then
        raise Exception.Create('MAC Adress is empty');
      MAC := MAC + GetSession;
      ExternalRegister(Self.ServerName, DBMain, MAC, Login, Password);
    end;

    AppServerDisp.LogIn(Login, Password, Integer(FAppServerIB),
       FServerName, DBName, DBMain,
       Emp_Company_Uid, wEmp_LNG, wuName, wuPass);
    uName := wuName;
    uPass := wuPass;
    if Length(wEmp_LNG) = 0 then
      wEmp_LNG := 'R';
    Emp_Language := wEmp_LNG;
    if Assigned(AfterSysConnect) then
       AfterSysConnect(Self);
    AppServerDisp.Enter;
    FUpdatedRefs.Text := AppServerDisp.GetRefsInfo;
    AfterDisconnect  := DoAfterDisconnect;
    BeforeDisconnect := DoBeforeDisconnect;
  end;
end;

procedure TCustomxConnection.TryConnect;
begin
  try
    case ConnectType of
      ctADO   : ADOConnect;
      ctIB    : IBConnect;
      ctMidas : MidasConnect;
    end;
   except
     on E:Exception do
     begin
       Log('Can"t connect : ' + E.Message);
       raise;
     end;
   end;
end;

function TCustomxConnection.InfoReqired : boolean;
begin
  InfoReqired := False;
  if (Login = '') or (Password = '') then
    InfoReqired := True
  else case ConnectType of
    ctADO, ctIB :
      InfoReqired := (DBName = '') or (DBMain = '') or (ServerName = '');
    ctMidas :
      InfoReqired := (AppHost = '') or (AppPort = 0);
  end;
end;

procedure TCustomxConnection.Disconnect;
begin
  if csDestroying in ComponentState then
    Exit;
  try
    case ConnectType of
      ctADO   :
        ADOConnection.Connected := False;
      ctIB    :
        IBDataBase.Connected := False;
      ctMidas :
        begin
          FRemoteServer.Connected := False;
          FRenewRemoteServer := True;
        end;
    end;
  except
    on E:Exception do ShowMsg('Can"t disconnect : ' + E.Message);
  end;
end;

function TCustomxConnection.Loading: Boolean;
begin
  Result := (csLoading in ComponentState) or (Assigned(Owner) and
    (csLoading in Owner.ComponentState));
end;

{procedure TCustomxConnection.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent is TxClientDataSet) then
    FClients.Remove(AComponent);
end;
}
procedure TCustomxConnection.SetConnected(Value : boolean);
begin
  if Loading or (Value = Connected) then
    Exit;
  if Value then
  begin
    if InfoReqired then
    begin
      if SilentMode then
        raise Exception.Create('incomplete connection info');
      DoGetConnectInfo('*');
    end else
      try
        TryConnect;
      except
        on E:Exception do
        begin
          Disconnect;
          if (E is EAbort) or SilentMode then
            raise;
//          try
            DoGetConnectInfo(E.Message);
//          except
//            if not (csDesigning in ComponentState) then
//              raise;
//          end;
        end;
      end;
    if Connected then
    begin
      RusLang := Emp_Language <> 'L';
      DoAfterConnect;
      ReopenDataSets;
    end;
  end else
    Disconnect;
end;

function NextSQLToken(var PSQL : PChar; var Token : string; DeleteDog : boolean = True): TTokenType;
var TokenStart : PChar;
    Quote      : Char;

  function NextTokenIs(Value: string; var Str: string): Boolean;
  var
    Tmp : PChar;
    S   : string;
  begin
    Tmp    := PSQL;
    Result := False;
    if NextSQLToken(Tmp, S, DeleteDog) <> ttBlank then
      Exit;
    NextSQLToken(Tmp, S, DeleteDog);
    Result := AnsiCompareText(Value, S) = 0;
    if Result then
    begin
      Str  := Str + ' ' + S;
      PSQL := Tmp;
    end;
  end;

  function GetSQLToken(var Str: string): TTokenType;
  begin
    if Length(Str) = 0 then
      Result := ttEnd else
    if (AnsiCompareText('DISTINCT', Str) = 0) then
      Result := ttDistinct else
    if (AnsiCompareText('EXEC', Str) = 0) or (AnsiCompareText('EXECUTE', Str) = 0)then
      Result := ttExecute else
    if (AnsiCompareText('ASC', Str) = 0) or (AnsiCompareText('ASCENDING', Str) = 0)then
      Result := ttAscending else
    if (AnsiCompareText('DESC', Str) = 0) or (AnsiCompareText('DESCENDING', Str) = 0)then
      Result := ttDescending else
    if AnsiCompareText('SELECT', Str) = 0 then
      Result := ttSelect else
    if AnsiCompareText('FROM', Str) = 0 then
      Result := ttFrom else
    if AnsiCompareText('WHERE', Str) = 0 then
      Result := ttWhere else
    if (AnsiCompareText('GROUP', Str) = 0) and NextTokenIs('BY', Str) then
      Result := ttGroupBy else
    if AnsiCompareText('HAVING', Str) = 0 then
      Result := ttHaving else
    if AnsiCompareText('UNION', Str) = 0 then
      Result := ttUnion else
    if AnsiCompareText('PLAN', Str) = 0 then
      Result := ttPlan else
    if (AnsiCompareText('FOR', Str) = 0) and NextTokenIs('UPDATE', Str) then
      Result := ttForUpdate else
    if (AnsiCompareText('ORDER', Str) = 0) and NextTokenIs('BY', Str)  then
      Result := ttOrderBy else
      Result := ttIdent;
  end;

begin
   case PSQL^ of
     '/' :
       begin
         TokenStart := PSQL;
         if (PSQL + 1)^ = '*' then
         begin
           while True do
           begin
             PSQL  := AnsiStrScan(PSQL + 1, '*');
             if PSQL = nil then
               PSQL := StrEnd(TokenStart)
             else
             begin
               Inc(PSQL);
               if PSQL^ <> '/' then
                 Continue;
               Inc(PSQL);
             end;
             SetString(Token, TokenStart, PSQL - TokenStart);
             Result := ttComment;
             Exit;
           end;
         end;
         Result := ttSeparator;
         Token := PSQL^;
         Inc(PSQL);
       end;
     '"','''','`':
       begin
         Quote    := PSQL^;
         Token    := Quote + AnsiExtractQuotedStr(PSQL, Quote) + Quote;
         Result   := ttLiteral;
       end;
     ' ', #10, #13:
       begin
         Token := ' ';
         repeat Inc(PSQL) until not (PSQL^ in [' ', #10, #13]);
         Result := ttBlank;
       end;
     #0 :
       begin
         Token  := #0;
         Result := ttEnd;
       end;
     '0'..'9' :
       begin
         TokenStart := PSQL;
         while PSQL^ in ['0'..'9'] do Inc(PSQL);
         if PSQL^ = '.' then
         begin
           Inc(PSQL);
           while PSQL^ in ['0'..'9'] do Inc(PSQL);
         end;
         if UpperCase(PSQL^) = 'E' then
         begin
           if PSQL^ in ['-', '+'] then
             Inc(PSQL);
           while PSQL^ in ['0'..'9'] do Inc(PSQL);
         end;
         SetString(Token, TokenStart, PSQL - TokenStart);
         Result := ttNumber;
       end;
     'A'..'Z', 'a'..'z', '@' :
       begin
         TokenStart := PSQL;
         if PSQL^ = '@' then Inc(PSQL);
         while PSQL^ in ['A'..'Z', 'a'..'z', '0'..'9', '_'] do Inc(PSQL);
         SetString(Token, TokenStart, PSQL - TokenStart);
         if Token[ 1 ] = '@' then
         begin
           if DeleteDog then
             System.Delete(Token, 1, 1);
           Result := ttIdent;
         end else
           Result := GetSQLToken(Token);
       end;
      ':' :
        begin
          TokenStart := PSQL;
          Result := ttParam;
          Token  := PSQL^;
          Inc(PSQL);
          if PSQL^ in [ '"','''','`' ] then
          begin
            Quote := PSQL^;
            Token := AnsiExtractQuotedStr(PSQL, Quote);
            if (Token[ 1 ] = '@') and DeleteDog then
              System.Delete(Token, 1, 1);
            if not IsValidIdent(Token) then
              Token :=  Quote + Token + Quote;
            Token := ':' + Token;
          end else if PSQL^ in [ 'A'..'Z', 'a'..'z', '@' ] then
          begin
            if PSQL^ = '@' then Inc(PSQL);
            while PSQL^ in ['A'..'Z', 'a'..'z', '0'..'9', '_'] do Inc(PSQL);
            SetString(Token, TokenStart, PSQL - TokenStart);
            if (Token[ 2 ] = '@') and DeleteDog then
              System.Delete(Token, 2, 1);
          end else
            Result := ttSeparator;
        end;
     else
       if PSQL^ = '*' then
         Result := ttAllFields
       else
         Result := ttSeparator;
       Token := PSQL^;
       Inc(PSQL);
    end;
end;

function NextNotBlankSQLToken(var PSQL : PChar; var Token : string; DeleteDog : boolean = True): TTokenType;
begin
  Result := NextSQLToken(PSQL, Token, DeleteDog);
  if Result = ttBlank then
    Result := NextSQLToken(PSQL, Token, DeleteDog);
end;

function GetSQLTokenValue(SQL : string; TokenType : TTokenType; DeleteDog : boolean = True) : string;
var
  Start : PChar;
  Token : string;
  CurrToken : TTokenType;
begin
  Result := '';
  Start  := PChar(SQL);
  repeat
    CurrToken := NextSQLToken(Start, Token, DeleteDog);
  until (CurrToken = ttEnd) or (CurrToken = TokenType);
  if CurrToken = TokenType then
    while True do
    begin
      CurrToken := NextSQLToken(Start, Token, DeleteDog);
      if not (CurrToken in [ ttValue, ttParam, ttIdent, ttNumber, ttSeparator, ttBlank ]) then
      begin
        Result := Trim(Result);
        Exit;
      end;
      Result := Result + Token;
    end;
end;

procedure GetSQLParams(SQL : string; Params : TParams; DeleteDog : boolean = True);
var
  Start : PChar;
  Token : string;
  CurrToken : TTokenType;
begin
  Start  := PChar(SQL);
  repeat
    CurrToken := NextSQLToken(Start, Token, DeleteDog);
    if CurrToken = ttParam then
    begin
      System.Delete(Token, 1, 1);
      if Token[ 1 ] in [ '"','''','`' ] then
        Token := AnsiDequotedStr(Token, Token[ 1 ]);
      if Params.FindParam(Token) = nil then
        TParam(Params.Add).Name := Token;
    end;
  until CurrToken = ttEnd;
end;

function TxClientDataSet.ConvertADOToIB(SQL : string; Params : TParams; DeleteDog : boolean = True) : string;
var
  I : integer;
  Start : PChar;
  Token, ProcName, ProcParams : string;
  CurrToken, PredToken : TTokenType;

  function NextTokenIs(Sep: Char): Boolean;
  var
    Tmp : PChar;
    S   : string;
  begin
    Tmp    := Start;
    Result := (NextNotBlankSQLToken(Tmp, S, DeleteDog) = ttSeparator) and (Sep = S);
    if Result then
      Start := Tmp;
  end;

begin
  Result  := SQL;
  if IsValidIdent(SQL) then
  begin
    if Params.Count > 0 then
    begin
      Result := '';
      for I := 0 to Params.Count - 1 do if Params[ I ].ParamType in [ ptInput, ptInputOutput ] then
      begin
        if Result = '' then
          Result := Result + '(:'
        else
          Result := Result + ',:';
        Result := Result + Params[ I ].Name;
      end;
      Result := 'select * from ' + SQL + Result + ')'
    end else
      Result := 'select * from ' + SQL;
    Exit;
  end;
  Start     := PChar(SQL);
  CurrToken := NextNotBlankSQLToken(Start, Token, DeleteDog);
  if CurrToken = ttExecute then
  begin
    CurrToken := NextNotBlankSQLToken(Start, ProcName, DeleteDog);
    if CurrToken <> ttIdent then
      Exit;
    ProcParams := '';
    if NextTokenIs('(') then
      ProcParams := '(';
    PredToken  := ttSeparator;
    while True do
    begin
      CurrToken := NextNotBlankSQLToken(Start, Token, DeleteDog);
      case CurrToken of
        ttIdent :
          if PredToken <> ttSeparator then
            Exit
          else if NextTokenIs('=') then
            CurrToken  := ttSeparator
          else
            ProcParams := ProcParams + Token;
        ttSeparator :
          if Token = ',' then
            ProcParams := ProcParams + Token
          else if Token = ')' then
            Break
          else if Token <> '=' then
            Exit;
        ttParam :
          ProcParams := ProcParams + Token;
        ttNumber, ttValue, ttLiteral :
          if PredToken  <> ttSeparator then
            Exit
          else
            ProcParams := ProcParams + Token;
      else
        Break;
      end;
      PredToken := CurrToken;
    end;
    if ProcParams = '' then
      ProcParams := ' '
    else if ProcParams[ 1 ] <> '(' then
      ProcParams := '(' + ProcParams + ')';
    Result := 'select * from ' + ProcName + ProcParams + ' ';
  end else
    Result := '';
  while CurrToken <> ttEnd do
  begin
    Result := Result + Token;
    CurrToken := NextSQLToken(Start, Token, DeleteDog);
  end;
end;

procedure TxClientDataSet.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FConnection) then
    FConnection := nil;
end;

procedure TxClientDataSet.SetTransactional(Value : boolean);
begin
  CheckInactive;
  FTransactional := Value;
end;

procedure TxClientDataSet.SQLChanged(Sender : TObject);

  function DeleteAs(S : string) : string;
  var I, J : integer;
      V    : string;
  begin
    J := 1;
    Result := '';
    if Trim(S) = '' then
      Exit;
    repeat
      I := PosEx(',', S, J);
      if I = 0 then
        V := Trim(Copy(S, J, MAXINT))
      else
        V := Trim(Copy(S, J, I - J));
      J := Pos(' ', S);
      if J <> 0 then
        V := Copy(V, 1, J - 1);
      if Result = '' then
        Result := V
      else
        Result := Result + ',' + V;
      J := I + 1;
    until I = 0;
  end;

begin
  FSQLtext   := Trim(FSQL.Text);
  FTableName := DeleteAs(GetSQLTokenValue(FSQLtext, ttFrom));
  if not Loading then
  begin
    CheckConnected;
    if csDesigning in ComponentState then
    begin
      FetchParams;
    end else
      inherited CommandText := SQLtext;
  end;
end;

procedure TxClientDataSet.SetSQL(Value : TStrings);
begin
  if Value.Text <> FSQL.Text then
    FSQL.Assign(Value);
end;

procedure TxClientDataSet.SetTimeOut(Value : integer);
begin
  if Value <> FTimeOut then
  begin
    CheckInactive;
    FTimeOut := Value;
  end;
end;

procedure TxClientDataSet.SetResultSet(Value : boolean);
begin
  if Value <> ResultSet then
  begin
    CheckInactive;
    FResultSet := Value;
  end;
end;

function TxClientDataSet.ConnectType : TConnectionType;
begin
  Result := ctADO;
  if Assigned(FConnection) then
    Result := Connection.ConnectType
  else if not Loading and not (csDesigning in ComponentState) then
    raise Exception.Create('Connection not assigned');
end;

procedure TxClientDataSet.CheckConnected;
begin
  if Assigned(FConnection) then
    Connection.CheckConnected
  else if not Loading and not (csDesigning in ComponentState) then
    raise Exception.Create('Connection not assigned');
end;

procedure TxClientDataSet.DoExecute(Params: OleVariant);
var
  OwnerData: OleVariant;
  Cmd  : string;
  I    : integer;
  P    : TParam;
begin
  Prepare;
  DoBeforeExecute(OwnerData);
  if VarIsEmpty(OwnerData) then
    OwnerData := TimeOut;
  try
    if ConnectType = ctMidas then
    begin
      Cmd := SQLText;
      if Cmd = '' then
        raise Exception.Create('Empty CommandText');
      Connection.AppServerDisp.AS_Execute(GetProviderName, Cmd, Params, OwnerData)
    end else if ConnectType = ctADO then
    begin
      try
        ADODataSet.Open;
//        AppServer.AS_GetRecords(ProviderName, -1, RecsOut, 0, '', Par, OwnerData);
      except
        on E:Exception do
          if not AnsiContainsText(E.Message, SNoResultSet) then
            raise;
      end;
    end else
      AppServer.AS_Execute(ProviderName, '', Params, OwnerData);
  finally
    Self.Params.Assign(FParams);
    if ConnectType = ctADO then with ADODataSet do
      for I := 0 to Parameters.Count - 1 do
      begin
        P := Self.Params.FindParam(Parameters[ I ].Name);
        if P <> nil then
          TPar(Parameters[ I ]).AssignTo(P);
      end
    else
      Connection.JoinParams(Params, Self.Params);
  end;
  DoAfterExecute(OwnerData);
end;

function TxClientDataSet.DoGetRecords(Count: Integer; out RecsOut: Integer;
  Options: Integer; const CommandText: WideString; Params: OleVariant): OleVariant;
var
  Par, OwnerData: OleVariant;
  I : integer;
  P    : TParam;
//  Cmd  : string;
begin
  DoBeforeGetRecords(OwnerData);
  FParams.Assign(Self.Params);
  if VarIsEmpty(Params) and (Self.Params.Count > 0) then
    Params := PackageParams(Self.Params);
  try
    if ConnectType = ctMidas then
    begin
      if VarIsEmpty(OwnerData) then
      begin
//        OwnerData := VarArrayOf([TimeOut, WordBool(FetchOnDemand)]);
      end;
      Result := Connection.AppServerDisp.AS_GetRecords(GetProviderName, Count, RecsOut, Options,
        SQLText, Params, OwnerData);
    end else
      Result := AppServer.AS_GetRecords(ProviderName, Count, RecsOut, Options,
        '', Par, OwnerData);
  finally
    Self.Params.Assign(FParams);
    if ConnectType = ctADO then with ADODataSet do
      for I := 0 to Parameters.Count - 1 do
      begin
        P := Self.Params.FindParam(Parameters[ I ].Name);
        if P <> nil then
          TPar(Parameters[ I ]).AssignTo(P);
      end
    else
      Connection.JoinParams(Params, Self.Params);
  end;
  DoAfterGetRecords(OwnerData);
end;

function TxClientDataSet.Loading : Boolean;
begin
  Result := ([csLoading, csReading]  * ComponentState <> []) or (Assigned(Owner) and
    ([csLoading, csReading]  * Owner.ComponentState <> []));
end;

procedure TxClientDataSet.SetConnection(Value : TCustomxConnection);
begin
  if Value = Connection then
    Exit;
  if (csDesigning in ComponentState) then CheckInactive;
  if Connection <> nil then Connection.UnregisterClient(Self);
  FConnection := Value;
  if Active then
    Close
  else
  begin
    FreeAndNil(ADODataSet);
    FreeAndNil(IBQuery);
    FreeAndNil(IBStoredProc);
  end;
  if Value <> nil then
  begin
    Value.RegisterClient(Self);
    Value.FreeNotification(Self);
  end;
end;

function TxClientDataSet.ConvertExecToIB(SQL : string) : string;
begin
  Result := ConvertADOToIB(SQL, Params, Connection.DeleteDog);
end;

procedure TxClientDataSet.DoAfterPost;
begin
  if not InApply and LogChanges then with RecKeyBookMark do
  begin
    if IdentField <> nil then
    begin
      OldIdent := IdentField.AsInteger;
      NewIdent := OldIdent;
      UserIdent := UserIdentity and (UpdateStatus = usInserted);
    end;
    if State <> 'I' then
      if UpdateStatus = usInserted then
        State  := 'I'
      else
        State  := 'M';
  end;
  inherited;
end;

function  TxClientDataSet.GetInApply : boolean;
begin
  Result := ApplyState <> [];
end;

procedure TxClientDataSet.StrictCopyFrom(CDS : TxClientDataSet; New : boolean = True);
var I : integer;
begin
  ApplyState := [asInApply];
  try
    if New then
      Append
    else
      Edit;
    for I := 0 to FieldCount - 1 do
      Fields[ I ].Value := CDS.Fields[ I ].Value;
    Post;
  finally
    ApplyState := [];
  end;
end;

function TxClientDataSet.GetAutoInc : integer;
begin
  if CloneSource <> nil then
    Result := TxClientDataSet(CloneSource).AutoInc
  else
  begin
    Result := FAutoInc;
    Dec(FAutoInc);
  end;
end;

function TxClientDataSet.GetBookMarks : TObjectList;
begin
  if Assigned(CloneSource) then
    Result := TxClientDataSet(CloneSource).FBookMarks
  else
    Result := FBookMarks
end;

function TxClientDataSet.BookMarkIndex : integer;
var I, J  : integer;
    vKey  : Variant;
    OK    : boolean;
begin
  Result := -1;
  if FUniqueKey = ''  then
    Exit;
  vKey  := FieldValues[ UniqueKey ];
  for I := 0 to BookMarks.Count - 1 do with TKeyBookMark(BookMarks[ I ]) do
    if VarIsArray(vKey) then
    begin
      OK := True;
      for J := VarArrayLowBound(vKey, 1) to VarArrayHighBound(vKey, 1)do
        if not VarSameValue(vKey[ J ], Key[ J ]) then
        begin
          OK := False;
          Break;
        end;
      if OK then
      begin
        Result := I;
        Break;
      end;
    end else if VarSameValue(vKey, Key) then
    begin
      Result := I;
      Exit;
    end;
end;

procedure TxClientDataSet.DeleteBookMark;
var J : integer;
begin
  J := BookMarkIndex;
  if J <> -1 then
    BookMarks.Delete(J);
end;

procedure TxClientDataSet.DeleteDetails;
var I : integer;
begin
  for I := 0 to Length(RefFields) - 1 do with RefFields[ I ] do
    if not WeakRef and (ToDataSet <> Self) and not ToDataSet.Reference then with ToDataSet do
    begin
      if Locate(IdentName, FromField.Value, []) then
        Delete;
    end;
  for I := 0 to DetailDataSets.Count - 1 do
    with DetailDataSets[ I ] as TxClientDataSet do
    begin
      First;
      while not EOF do Delete;
    end;
end;

procedure TxClientDataSet.DoOnNewRecord;
begin
  if not UserIdentity then
    SetIdentMasters;
  inherited;
  SetModified(False);
end;

procedure TxClientDataSet.DoBeforeInsert;
begin
  inherited;
  MasterModify(True);
end;

procedure TxClientDataSet.DoBeforeDelete;
begin
  if InApply then
    Exit;
  inherited;
  if LogChanges then
  begin
    FDelBookMark := RecKeyBookMark;
    if FDelBookMark.State = 'D' then
      Exit;
    FDelBookMark.State := 'D';
  end;
  MasterModify;
  DeleteDetails;
end;

function TxClientDataSet.RecState : char;
var FBookMark  : TKeyBookMark;
begin
  FBookMark := GetKeyBookMark;
  if FBookMark = nil then
    Result := 'U'
  else
    Result := FBookMark.State;
end;

procedure TxClientDataSet.InternalDelete;
begin
  if not LogChanges or InApply or (FDelBookMark.State in ['I', 'D']) then
    inherited;
end;

procedure TxClientDataSet.DoAfterDelete;
begin
  if InApply then
    Exit;
  if LogChanges then
  begin
    if FDelBookMark.State = 'D' then
      Exit;
    if FDelBookMark.State = 'I' then
      BookMarks.Remove(FDelBookMark)
    else
    begin
      if FDelBookMark.State = 'M' then
        RevertRecord;
      FDelBookMark.State := 'D';
    end;
  end;
  inherited;
  MasterModified;
end;

function TxClientDataSet.GetDetailList : TObjectList;
begin
  if not FDetailDataSetsChecked then
    UpdateDetailDataSetList;
  Result := FDetailDataSets;
end;

function TxClientDataSet.UpdateDetailDataSetList : TObjectList;
begin
  if State = dsBrowse then
  begin
    FDetailDataSetsChecked := True;
    GetDetailDataSets(FDetailDataSets);
  end;
  Result := FDetailDataSets;
end;

procedure TCustomxConnection.DeleteGenerator(GenName : string);
const
  SDelGen = 'DELETE FROM RDB$GENERATORS WHERE RDB$GENERATOR_NAME = %s';
var
  sqlGen : TIBSQL;
begin
  sqlGen := TIBSQL.Create(IBDatabase);
  with sqlGen do
  try
    Transaction := IBTransactions[ utReadWrite ];
    SQL.Text := Format(SDelGen, [QuoteIdentifier(Database.SQLDialect, GenName)]);
    ExecQuery;
    Close;
  finally
    Free;
  end;
end;

procedure TCustomxConnection.CreateGenerator(GenName : string);
const
  SGENSQL = 'CREATE GENERATOR %s';
var
  sqlGen : TIBSQL;
begin
  sqlGen := TIBSQL.Create(IBDatabase);
  with sqlGen do
  try
    Transaction := IBTransactions[ utReadWrite ];
    SQL.Text := Format(SGENSQL, [QuoteIdentifier(Database.SQLDialect, GenName)]);
    ExecQuery;
    Close;
  finally
    Free;
  end;
end;

procedure TxClientDataSet.DoBeforeOpen;
var I : integer;
    Locked : TField;
begin
  inherited;
  if (Trim(FSQLtext) = '') and (FileName = '') and (DataSize = 0) and not Assigned(DSBase) then
    raise Exception.Create('CommandText and FileName are empty');
  FromServer := (Trim(FSQLtext) <> '') and (DataSize = 0)
    and ((csDesigning in ComponentState) or Connection.LoadFromServer(TableName, FileName));
  FSaveFileName := FileName;
  if FromServer then
    FileName := '';
  if not (csDesigning in ComponentState) then
  begin
    Locked := FindField('Locked');
    if Locked <> nil then
      Locked.ReadOnly := True;
    if FieldDefs.Count = 0 then
      for I := 0 to FieldCount - 1 do with Fields[ I ] do
        FieldDefs.Add(FieldName, DataType, Size, Required);
    for I := 0 to FieldCount - 1 do with Fields[ I ] do
      if (DataType = ftAutoInc) or (DataType = ftInteger) and (AutoGenerateValue = arAutoInc) then
      begin
        IdentName  := FieldName;
        FieldDefs[ I ].Attributes := FieldDefs[ I ].Attributes - [faReadonly];
        if ConnectType = ctIB then
          FieldDefs[ I ].DataType := ftInteger;
        if GenName = '' then
          GenName  := TableName + '_GEN';
        ReadOnly := False;
        Break;
      end;
  end;
end;

procedure TxClientDataSet.DoAfterOpen;
var I : integer;
begin
  Connection.CheckConnectionErrors;
  if (CloneSource <> nil) or (csDesigning in ComponentState) then
    Exit;

  inherited;

  LogChanges := FTransactional;
  if FTransactional then
    ReadOnly := False;
  for I := 0 to FieldCount - 1 do with Fields[ I ] do
    if (FieldName = IdentName) then
    begin
      FIdentField := Fields[ I ];
      Break;
    end;

  if FIdentField <> nil then
    FIdentField.ReadOnly := False;
  FAutoInc := -1;
  if (FIdentField <> nil) and Transactional then
  begin
    FUpdateMode := upWhereKeyOnly;
    for I := 0 to FieldCount - 1 do with Fields[ I ] do
      if Fields[ I ] = FIdentField  then
        ProviderFlags := ProviderFlags + [ pfInKey, pfInUpdate]
      else
        ProviderFlags := ProviderFlags - [ pfInKey ];
  end;
  FileName := FSaveFileName;
  if (FileName <> '') and FromServer then
    SaveToFile;
  if (IdentField <> nil) and Transactional then
    UniqueKey := IdentField.FieldName;
end;

procedure TxClientDataSet.DoAfterExecute(var OwnerData: OleVariant);
begin
  Connection.CheckConnectionErrors;
  inherited;
end;

procedure TxClientDataSet.DoBeforeCancel;
begin
  inherited;
end;

procedure TxClientDataSet.DoAfterCancel;
begin
  inherited;
  MasterModified;
end;

procedure TxClientDataSet.DoBeforeClose;
begin
  if Locked then
    LockRecord(False);
  inherited;
end;

procedure TxClientDataSet.DoAfterClose;
begin
  FreeAndNil(ADODataSet);
  FreeAndNil(IBQuery);
  FreeAndNil(IBStoredProc);
  inherited;
  FActive:= False;
  FIdentField := nil;
  FDetailDataSetsChecked := False;
  FAutoInc := -1;
  FBookMarks.Clear;
end;

procedure TxClientDataSet.DoBeforeRowRequest(var OwnerData: OleVariant);
begin
  inherited;
  if VarIsEmpty(OwnerData) then
    OwnerData := SQLtext;
end;

procedure TxClientDataSet.DoBeforeGetParams(var OwnerData: OleVariant);
var I    : integer;
    P    : TParam;
begin
  PrepareProvider;
  FParams.Assign(Params);
  inherited CommandText := SQLtext;
  if Trim(FSQLtext) = '' then
  begin
    Params.Clear;
    if (csDesigning in ComponentState) or not Assigned(Connection) then
      Abort
    else if Assigned(FConnection) then
      raise Exception.Create('CommandText is empty');
  end;
  case ConnectType of
   ctADO :
     with ADODataSet do if CommandType <> cmdText then
     begin
       CommandText := SQLtext;
       Parameters.Refresh;
       for I := 0 to Parameters.Count - 1 do with Parameters[ I ] do
       begin
         P := Params.FindParam(Name);
         if P = nil then
         begin
           P := TParam(Params.Add);
           P.Name := Name;
         end;
         P.DataType  := DataType;
         P.Size      := Size;
         P.ParamType := TParamType(Direction);
       end;
     end;
   ctIB  :
     if IBStoredProc <> nil then
     begin
       IBStoredProc.StoredProcName := SQLText;
       IBStoredProc.Prepare;
     end else
     begin
       IBQuery.SQL.Text := SQLText;
       IBQuery.Prepare;
     end;
   ctMidas :
     OwnerData := SQLtext;
  end;
  inherited;
end;

procedure TxClientDataSet.SetCmdText;
var Proc : boolean;
begin
  FParams.Assign(Params);
  Proc := IsValidIdent(SQLText);
  case ConnectType of
   ctADO :
     begin
       ADODataSet.CommandText := SQLtext;
       AssignParamsToParameters(FParams, ADODataSet.Parameters, Proc);
//       if Name = 'qr_Event_Modify' then
//         log(ParamInfo(ADODataSet.Parameters));
     end;
   ctIB  :
     if IBStoredProc <> nil then
     begin
       IBStoredProc.StoredProcName := SQLText;
       IBStoredProc.Params.Assign(Params);
     end else
     begin
       IBQuery.SQL.Text := SQLText;
       IBQuery.Params.Assign(Params);
     end;
  end;
end;

procedure TxClientDataSet.DoAfterGetParams(var OwnerData: OleVariant);
var I  : integer;
    P  : TParam;
    DT : TDataType;
begin
  if (ConnectType <> ctADO) or (ADODataSet.CommandType <> cmdText) then
    for I := 0 to Params.Count - 1 do
    begin
      P := FParams.FindParam(Params[ I ].Name);
      if P <> nil then with Params[ I ] do
      begin
        DT      := DataType;
        Value   := P.Value;
        DataType:= DT;
      end;
    end;
  inherited;
end;

procedure TxClientDataSet.Loaded;
begin
  inherited Loaded;
  if PacketRecords = 0 then
    PacketRecords := -1;
end;

procedure TxClientDataSet.ResetProvider(DataSet : TDataSet);
begin
  if FetchOnDemand then
    Provider.Options := [ poFetchBlobsOnDemand ]
  else
    Provider.Options := [ ];
  Provider.DataSet := DataSet;
  SetProvider(Provider);
end;

function TxClientDataSet.GetSQLText : string;
begin
  case ConnectType of
   ctADO :
      Result := FSQLtext;
   ctIB  :
     if Assigned(IBStoredProc) then
       Result := FSQLtext
     else
       Result := ConvertExecToIB(FSQLtext);
   ctMidas :
     if Connection.AppServerIB then
       Result := ConvertExecToIB(FSQLtext)
     else
       Result := FSQLtext;
  end;
end;

function TxClientDataSet.GetProviderName : string;
begin
  if IsValidIdent(FSQLtext) and (not Connection.AppServerIB or not ResultSet) then
    Result := 'ProcProvider'
  else
    Result := 'QueryProvider';
end;

procedure TxClientDataSet.PrepareProvider;
var ProcCmd : boolean;
begin
  ProcCmd := IsValidIdent(FSQLtext);
  FreeAndNil(IBQuery);
  FreeAndNil(IBStoredProc);
  FreeAndNil(ADODataSet);
  case ConnectType of
   ctADO :
     begin
       ADODataSet:= TADODataSet.Create(Self);
       ADODataSet.AfterOpen := AfterADOOpen;
       ADODataSet.CacheSize := 1000;
       ADODataSet.Connection := Connection.ADOConnection;
       ADODataSet.Name := 'InternalADODataSet';
       ADODataSet.SetSubComponent(True);
       ADODataSet.EnableBCD := True;
       ADODataSet.CursorType := ctOpenForwardOnly;
       ADODataSet.CommandTimeout := TimeOut;
       ADODataSet.ParamCheck := True;
       if ProcCmd then
         ADODataSet.CommandType := cmdStoredProc
       else
         ADODataSet.CommandType := cmdText;
       if not (csDesigning in ComponentState) and Transactional then
         ADODataSet.LockType  := ltReadOnly;
       ResetProvider(ADODataSet);
     end;
   ctIB  :
     begin
       if ProcCmd and not ResultSet then
       begin
         IBStoredProc := TIBStoredProc.Create(Self);
         IBStoredProc.Name := 'InternalIBStoredProc';
         IBStoredProc.SetSubComponent(True);
         IBStoredProc.DataBase := Connection.IBDataBase;
         if csDesigning in ComponentState then
           IBStoredProc.Transaction := Connection.IBTransactions[ utReadWrite ]
         else
           IBStoredProc.Transaction := Connection.IBTransactions[ utReadOnly ];
         ResetProvider(IBStoredProc);
       end else
       begin
         IBQuery := TIBQuery.Create(Self);
         IBQuery.DataBase := Connection.IBDataBase;
         IBQuery.Name := 'InternalIBQuery';
         IBQuery.SetSubComponent(True);
         IBQuery.CachedUpdates := True;
//         FetchBlobsOnDemand := False;
         if csDesigning in ComponentState then
           IBQuery.Transaction := Connection.IBTransactions[ utReadWrite ]
         else
           IBQuery.Transaction := Connection.IBTransactions[ utReadOnly ];
         ResetProvider(IBQuery);
       end;
     end;
   ctMidas :
     begin
       FreeAndNil(ADODataSet);
       FreeAndNil(IBQuery);
       FreeAndNil(IBStoredProc);
       RemoteServer := Connection.RemoteServer;
     end;
  end;
end;

procedure TxClientDataSet.DoAfterRefresh;
begin
  inherited;
end;

function TxClientDataSet.LoadPackets(Clear : boolean) : boolean;
begin
  Result := True;
  if not ProviderEOF then
  begin
     if Clear then
     begin
       Emptydataset;
       ProviderEOF := False;
     end;
     GetNextPacket;
  end else
    Result := False;
end;

function TxClientDataSet.CallInfo : string;
begin
  Result := Name + ' cmd : ';
  case ConnectType of
    ctADO  :
      begin
        Result := Result + ADODataSet.CommandText + #13#10 +
          ParamInfo(ADODataSet.Parameters);
      end;
    ctIB   :
      begin
        if IBStoredProc <> nil then
        begin
          Result := Result + IBStoredProc.StoredProcName + #13#10 +
            ParamInfo(IBStoredProc.Params);
        end else
          Result := Result + IBQuery.SQL.Text;
      end;
    ctMidas:
      Result := Result + SQLText + #13#10 +
            ParamInfo(Params);
  end;
end;

procedure TxClientDataSet.Execute;
begin
  try
    inherited Execute;
  except
    on E:Exception do
      Connection.DoException(E, CallInfo);
  end;
end;

procedure TxClientDataSet.Prepare;
begin
  CheckConnected;
  PrepareProvider;
  SetCmdText;
end;

procedure TxClientDataSet.OpenCursor(InfoQuery: Boolean);
begin
  Prepare;
  try
    inherited OpenCursor(InfoQuery);
  except
    on E:Exception do
      Connection.DoException(E, CallInfo);
  end;
end;

procedure TxClientDataSet.AfterADOOpen(DataSet : TDataSet);
var I : integer;
    Field : TField;
begin
  with TCustomADODataSet(DataSet) do
  begin
    for I := 0 to FieldCount - 1 do with Fields[ I ] do
      if (DataType in [ftBlob..ftMemo, ftTimeStamp, ftOraBlob..ftOraClob, ftAutoInc]) or (FieldName = IdentName) then
      begin
        ReadOnly := False;
        if Self.FieldCount > 0 then
        begin
          Field := Self.FieldByName(FieldName);
          if Field = nil then
            raise Exception.Create(FieldName + ' in ' + Self.Name + ' not found');
          Field.ReadOnly := False;
        end;
      end;
    while NextRecordset(I) <> nil do;
  end;
end;

constructor TxClientDataSet.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  FDetailDataSets := TObjectList.Create;
  FDetailDataSets.OwnsObjects := False;
  FBookMarks     := TObjectList.Create;
  FBookMarks.OwnsObjects := True;
  PacketRecords := -1;
  FSQL     := TStringList.Create;
  FTimeOut := 60;
  TStringList(FSQL).OnChange := SQLChanged;
  FResultSet   := True;
  FParams  := TParams.Create;;
  FApplyParams := TParams.Create;
  Provider := TDataSetProvider.Create(Self);
  Provider.Name := 'InternalProvider';
  inherited ProviderName  := 'InternalProvider';
  Provider.SetSubComponent(True);
end;

destructor TxClientDataSet.Destroy;
begin
  Connection := nil;
  FParams.Free;
  FApplyParams.Free;
  FDetailDataSets.Free;
  FBookMarks.Free;
  FreeAndNil(ADODataSet);
  FreeAndNil(IBQuery);
  FreeAndNil(IBStoredProc);
  FreeAndNil(Provider);
  FSQL.Free;
  inherited Destroy;
end;

procedure TxClientDataSet.RefreshDetails;
var I : integer;
begin
  for I := 0 to DetailDataSets.Count - 1 do
    with TxClientDataSet(DetailDataSets[ I ]) do
      if Active then DataEvent(deParentScroll, 0);
end;

procedure TxClientDataSet.DoAfterScroll;
begin
  if not InApply then
  begin
    RefreshDetails;
    inherited;
  end;
end;

procedure TxClientDataSet.DoBeforeScroll;
begin
  if not InApply then
    inherited;
end;

function TxClientDataSet.CanApply : boolean;
begin
  if not IsValidIdent(TableName) then
    raise Exception.Create('ApplyTable not assigned');
  Result := Active and Edited and (CloneSource = nil) and LogChanges;
end;

procedure TxClientDataSet.DoBeforeApplyUpdates(var OwnerData: OleVariant);
begin
  inherited;
  if VarIsEmpty(OwnerData) then
    OwnerData := SQLtext;
end;

function TxClientDataSet.ApplyDataSetUpdates : boolean;
var SaveTrans : TIBTransaction;
begin
  if Connection = nil then
    raise Exception.Create('Connection = nil');
  if Connection.InTransaction then
    raise Exception.Create('Connection.InTransaction = true, please, apply manually');

  Connection.Connected := True;
  Result := True;
  with Connection do
  begin
    BegApply;
    if ApplyState = [] then
      Exit;
    SaveTrans := nil;
    if ConnectType = ctIB then
    begin
      SaveTrans := FIBDataBase.DefaultTransaction;
      FIBDataBase.DefaultTransaction := IBTransactions[ utReadWrite ];
    end;
    BeginTrans;
    try
      StackTop := 0;
      InternalApplyUpdates;
      CheckWeak;
      CommitTrans;
    except
      on E:Exception do {if E is EAbort then
        CommitTrans
      else} begin
        RollbackTrans;
        ShowMsg(E.Message);
        Result := False;
      end;
    end;
    if ConnectType = ctIB then
      FIBDataBase.DefaultTransaction := SaveTrans;
    if Result then
      Realize;
    EndApply;
  end;
end;

procedure TCustomxConnection.CancelUpdates;
var I : integer;
begin
  for I := 0 to Clients.Count - 1 do with TxClientDataSet(Clients[ I ]) do
    if not Assigned(MasterSource) and Active and Edited then
      CancelDataSetUpdates;
end;

procedure TxClientDataSet.DoRevertRecord;
begin
  if State <> dsBrowse then
    raise Exception.Create('DoRevertRecord State <> dsBrowse');
  if not LogChanges then
    Exit;
  FDelBookMark := GetKeyBookMark;
  if FDelBookMark <> nil then
  begin
    if FDelBookMark.State = 'I' then
      Delete;
    if FDelBookMark.State = 'M' then
      RevertRecord;
    BookMarks.Remove(FDelBookMark);
  end;
end;

function TxClientDataSet.RecordModified : boolean;
begin
  Result := (State in [ dsEdit, dsInsert ]) or (UpdateStatus <> usUnmodified);
end;

function TxClientDataSet.Edited : boolean;
var I : integer;
begin
  Result := (State in [ dsEdit, dsInsert ])
    or (BookMarks.Count > 0) or (ChangeCount > 0);
  if not Result then
  begin
    for I := 0 to DetailDataSets.Count - 1 do
      with DetailDataSets[ I ] as TxClientDataSet do
      begin
        Result := Edited;
        if Result then
          Exit;
      end;
  end;
end;

procedure TxClientDataSet.RestCursorRange;
var I : integer;
    DoRange : boolean;
begin
  if MasterSource <> nil then
    Exit;
  DoRange := False;
  if not VarIsNull(FStartRange) then
  begin
    EditRangeStart;
    for I := 0 to VarArrayHighBound(FStartRange, 1) do
      Index_Fields[ I ].Value := FStartRange[ I ];
    DoRange := True;
    FStartRange := null;
  end;
  if not VarIsNull(FEndRange) then
  begin
    EditRangeEnd;
    for I := 0 to VarArrayHighBound(FEndRange, 1) do
      Index_Fields[ I ].Value := FEndRange[ I ];
    DoRange := True;
    FEndRange := null;
  end;
  if DoRange then
  begin
    ApplyRange;
  end;
end;

procedure TxClientDataSet.SaveCursorRange;
var
  RangeStart, RangeEnd: PKeyBuffer;
  I : integer;
begin
  if MasterSource <> nil then
    Exit;
  RangeStart := GetKeyBuffer(kiRangeStart);
  FStartRange := null;
  if RangeStart.Modified then
  begin
    FStartRange := VarArrayCreate([0, RangeStart.FieldCount - 1], varVariant);
    EditRangeStart;
    for I := 0 to RangeStart.FieldCount - 1 do
      FStartRange[ I ] := Index_Fields[ I ].Value;
  end;
  RangeEnd   := GetKeyBuffer(kiRangeEnd);
  FEndRange := null;
  if RangeEnd.Modified then
  begin
    FEndRange := VarArrayCreate([0, RangeEnd.FieldCount - 1], varVariant);
    EditRangeEnd;
    for I := 0 to RangeEnd.FieldCount - 1 do
      FEndRange[ I ] := Index_Fields[ I ].Value;
  end;
  CancelRange;
end;

procedure TxClientDataSet.BegApply;
var I : integer;
    List : TList;
begin
  if InApply or not CanApply then
    Exit;
  if State in [ dsEdit, dsInsert ] then
    Post;
  ApplyState := [asBegApply];
  for I := 0 to Length(RefFields) - 1 do with RefFields[ I ] do
    if not WeakRef then
      ToDataSet.BegApply;
  if IdentField = nil then
    FSaveRec   := GetBookMark
  else
    FSaveIdent := IdentField.AsInteger;
  DisableControls;
  SaveCursorRange;
  SaveAggregatesActive := AggregatesActive;
  AggregatesActive := False;
  SaveAutoCalcFields := AutoCalcFields;
  AutoCalcFields := False;
  for I := 0 to BookMarks.Count - 1 do with TKeyBookMark(BookMarks[ I ]) do
    Updates.Clear;
  RefFieldLen := Length(RefFields);
  if IndexedByMaster then
  begin
    List := TList.Create;
    try
      MasterSource.DataSet.GetFieldList(List, MasterFields);
      I := List.IndexOf(TxClientDataSet(MasterSource.DataSet).IdentField);
      if I <> -1 then
      begin
        SetLength(RefFields, RefFieldLen + 1);
        with RefFields[ RefFieldLen ]do
        begin
          FromField := Index_Fields[ I ];
          ToDataSet := TxClientDataSet(MasterSource.DataSet);
          WeakRef   := False;
        end;
      end;
    finally
      List.Free;
    end;
  end;
  UpdateDetailDataSetList;
  SavedSource := MasterSource;
  MasterSource := nil;
  SavedMasterFlds := MasterFields;
  MasterFields := '';
  for I := 0 to DetailDataSets.Count - 1 do
    with DetailDataSets[ I ] as TxClientDataSet do
      BegApply;
end;

procedure TxClientDataSet.DoBeforeApplyRecord;
begin
  if Assigned(FBeforeApplyRecord) then FBeforeApplyRecord(Self);
end;

procedure TxClientDataSet.MergeChanges;
begin
  if ChangeCount > 0 then
    MergeChangeLog;
  BookMarks.Clear;
end;

procedure TxClientDataSet.LogRec(S : string);
var I : integer;
    Info : PBlobInfo;
    B : string;
begin
  for I := 0 to FieldCount - 1 do with Fields[ I ] do
    if IsBlob then
    begin
      Info := GetBlobInfo(Fields[ I ]);
      if Info = nil then
        B := '.'
      else
        B := ' - ' + Info.BlobDate.AsString;
      S := S + ', ' + FieldName + '(Blob)' + B;
    end else
      S := S + ', ' + FieldName + '=' + AsString;
  Log(S);
end;

procedure TxClientDataSet.CheckWeak;
var I, J : integer;
begin
//  Log('------------------');
  with Connection do
    for I := 0 to Clients.Count - 1 do with TxClientDataSet(Clients[ I ]) do
      if asInApply in ApplyState then
      begin
        for J := 0 to Length(RefFields) - 1 do with RefFields[ J ] do
          if WeakRef then
          begin
            WeakApply;
            Break;
          end;
      end;
end;

procedure TxClientDataSet.AddParam(Field : TField; V : Variant; Fld : boolean = True);
begin
  if Field.IsBlob then
    TParam(FApplyParams.Add).AssignFieldValue(Field, BlobValue(Field))
  else if Fld then
    TParam(FApplyParams.Add).AssignField(Field)
  else
    TParam(FApplyParams.Add).AssignFieldValue(Field, V);
end;

function TxClientDataSet.GetWeakWhere(Params : TParams) : string;
var I     : integer;
    Field : TField;
    Item  : string;
begin
  Result := '';
  for I := 0 to FieldCount - 1 do
  begin
    Field := Fields[ I ];
    if UseFieldInWhere(Field, UpdateMode) then  with Field do
    begin
      if Field = IdentField then
      begin
        Item  := FieldName + '=?';
        TParam(Params.Add).AssignFieldValue(Field, GetNewRef(Field.AsInteger));
      end else if VarIsNull(Value) then
        Item  := FieldName + ' is NULL'
      else
      begin
        Item  := FieldName + '=?';
        TParam(Params.Add).AssignField(Field);
      end;
      if Result = '' then
        Result := Item
      else
        Result := Result + ' and ' + Item;
    end;
  end;
end;

procedure TxClientDataSet.ApplyWeakRec;
var I : integer;
    SQL, Item, Sets : string;
    RefValue : integer;
    Field : TField;
    Weak  : boolean;
begin
  FApplyParams.Clear;
  Sets := '';
  for I := 0 to FieldCount - 1 do
  begin
    Field := Fields[ I ];
    if IsRefField(Field, RefValue, Weak) and Weak then
    begin
      if RefValue = Field.AsInteger then
         Continue;
      AddParam(Field, RefValue, False);
      RecKeyBookMark.Updates.AddObject(Field.FieldName, Pointer(RefValue));
      Item  := Field.FieldName + '=?';
      if Sets = '' then
        Sets := Item
      else
        Sets := Sets + ',' + Item;
    end;
  end;
  if Sets <> '' then
  begin
    SQL := 'UPDATE ' + TableName + ' SET ' + Sets + ' WHERE ' + GetWeakWhere(FApplyParams);
//    Log(SQL);
//    Log('   ' + ParamList(FApplyParams));
    PSExecuteSQL(SQL);
  end;
end;


procedure TxClientDataSet.WeakApply;
var SaveIndex : string;
    FieldsIndex : boolean;
    Attr : byte;
begin
  FieldsIndex    := IndexName = '';
  if FieldsIndex then
    SaveIndex  := IndexFieldNames
  else
    SaveIndex  := IndexName;
  StatusFilter := [usModified, usInserted];
  try
    First;
    while not EOF do
    begin
      Attr := GetRecAttr;
      if Attr and dsIsNotVisible <> 0 then
      else if (Attr = dsRecModified) or (Attr = dsRecNew) then
        ApplyWeakRec;
      Next;
    end;
  finally
    StatusFilter := [];
    if FieldsIndex then
      IndexFieldNames := SaveIndex
    else
      IndexName := SaveIndex;
  end;
end;

procedure TxClientDataSet.Realize;
var I, J : integer;
begin
  if (asRealized in ApplyState) or (ApplyState = []) then
    Exit;
  Include(ApplyState, asRealized);
  if IdentField <> nil then
  begin
    SetLength(LastChangeIdent, BookMarks.Count);
    for I := 0 to BookMarks.Count - 1 do with TKeyBookMark(BookMarks[ I ]) do
    begin
      if not Locate(UniqueKey, Key, []) then
        raise Exception.Create('Locate(UniqueKey, Key, []) failed');
      if State = 'D' then
      begin
        LastChangeIdent[ I ].New := 0;
        Continue;
      end else
        LastChangeIdent[ I ].New := NewIdent;
      LastChangeIdent[ I ].Old := OldIdent;
      if FSaveIdent = OldIdent then
        FSaveIdent := NewIdent;
      if Updates.Count > 0 then
      begin
        Edit;
        for J := 0 to Updates.Count - 1 do
          FieldByName(Updates[ J ]).AsInteger := Integer(Updates.Objects[ J ]);
        Post;
      end;
    end;
    if NeedLock and (LockedRecord < 0) then
    begin
      FLockedRecord := TKeyBookMark(BookMarks[ 0 ]).NewIdent;
    end;
  end;
  MergeChanges;
  for I := 0 to DetailDataSets.Count - 1 do
    with DetailDataSets[ I ] as TxClientDataSet do
      Realize;
  for I := 0 to Length(RefFields) - 1 do with RefFields[ I ] do
    if not WeakRef then
      ToDataSet.Realize;
end;

procedure TxClientDataSet.EndApply;
var I : integer;
begin
  if (asEnded in ApplyState) or (ApplyState = []) then
    Exit;
  Include(ApplyState, asEnded);
  MasterFields := SavedMasterFlds;
  MasterSource := SavedSource;
  SetLength(RefFields, RefFieldLen);

  for I := 0 to DetailDataSets.Count - 1 do
    with DetailDataSets[ I ] as TxClientDataSet do
      EndApply;
  for I := 0 to Length(RefFields) - 1 do
    (RefFields[ I ].ToDataSet).EndApply;
  AutoCalcFields := SaveAutoCalcFields;
  AggregatesActive := SaveAggregatesActive;
  MasterModified;
  RestCursorRange;
  if IdentField <> nil then
    Locate(IdentField.FieldName, FSaveIdent, [])
  else
  begin
    if (FSaveRec <> nil) and BookMarkValid(FSaveRec) then
      GotoBookMark(FSaveRec);
    if FSaveRec <> nil then
      FreeBookMark(FSaveRec);
  end;
  ApplyState := [];
  EnableControls;
end;

procedure TxClientDataSet.AppendDetails(Dets : Variant);
var I : integer;
begin
  for I := 0 to VarArrayHighBound(Dets, 1) do
    AppendRecord(Dets[ I ]);
end;

procedure TxClientDataSet.SetCalcField(Field : TField; const Value: Variant);
begin
  SetTempState(dsCalcFields);
  try
    Field.Value := Value;
  finally
    RestoreState(dsBrowse);
  end;
end;

procedure TxClientDataSet.AppendRecord(Rec : Variant);
var Flds, Dets : Variant;
    I  : integer;
begin
  Flds := Rec[ 0 ];
  Append;
  for I := 0 to FieldCount - 1 do with Fields[ I ] do
    if (FieldKind in [ fkData, fkInternalCalc ]) and not IsIdent(Fields[ I ]) then
      Value := Flds[ I ];
  Post;
  Dets := Rec[ 1 ];
  if VarIsArray(Dets) then
    for I := 0 to VarArrayHighBound(Dets, 1) do
      if VarIsArray(Dets[ I ]) then
        TxClientDataSet(Integer(Dets[ I ][ 0 ])).AppendDetails(Dets[ I ][ 1 ]);
end;

function TxClientDataSet.GetNewRef(OldRef : integer) : integer;
var J : integer;
begin
  for J := 0 to BookMarks.Count - 1 do with TKeyBookMark(BookMarks[ J ]) do
    if OldRef = OldIdent then
    begin
      Result := NewIdent;
      Exit;
    end;
  Result := 0;
end;

function TxClientDataSet.IsRefField(Field : TField; var RefValue : integer; var Weak : boolean) : boolean;
var I : integer;
    Ref : integer;
begin
  if Field.DataType in [ ftInteger, ftAutoInc ] then
  begin
    for I := 0 to Length(RefFields) - 1 do with RefFields[ I ] do
      if FromField = Field then
      begin
        Weak := WeakRef;
        Ref := Field.AsInteger;
        if Ref <> 0 then
          Ref := RefFields[ I ].ToDataSet.GetNewRef(Ref);
        Result := True;
        if Ref <> 0 then
          RefValue := Ref
        else
          RefValue := Field.AsInteger;
        Exit;
      end;
  end;
  Result := False;
end;

procedure TxClientDataSet.AddBlobInfo(ABlobField : TBlobField; ABlobName : TStringField; ABlobDate : TDateTimeField);
var I : integer;
begin
   I := Length(BlobInfo);
   SetLength(BlobInfo, I + 1);
   with BlobInfo[ I ] do
   begin
     BlobField:= ABlobField;
     BlobName := ABlobName;
     BlobDate := ABlobDate;
   end;
end;

function TxClientDataSet.CreateMidasStream(AField : TField) : TStream;
var Blob : OleVariant;
    P    : Pointer;
    AParams : TParams;
    where   : string;
    Size    : integer;
begin
  AParams := TParams.Create;
  try
    where  := GetWhere(AParams);
    Blob   := Connection.AppServerDisp.GetBlob( 'select ' + AField.FieldName + ' from ' + TableName + ' where ' + where, PackageParams(AParams));
    Result := TMidasStream.Create('');
    P := VarArrayLock(Blob);
    try
      Size := VarArrayHighBound(Blob, 1) + 1;
      Result.Write(P^, Size);
    finally
      VarArrayUnlock(Blob);
    end;
    Result.Position := 0;
  finally
    AParams.Free;
  end;
end;

function TxClientDataSet.CreateADOStream(AField : TField) : TStream;
var Params : TParams;
    S : string;
begin
  Params := TParams.Create;
  try
    with TADOQuery.Create(nil) do
    try
      Connection := Self.Connection.ADOConnection;
      S := 'select ' + AField.FieldName + ' from ' + TableName + ' where ' + GetWhere(Params);
      SQL.Text   := S;
      RefreshParameters(Parameters, Params);
      Open;
      Result := CreateBlobStream(Fields[ 0 ], bmRead);
    finally
      Free;
    end;
  finally
    Params.Free;
  end;
end;

function TxClientDataSet.GetBlobInfo(Field: TField) : PBlobInfo;
var I : integer;
begin
  for I := 0 to Length(BlobInfo) - 1 do
    if BlobInfo[ I ].BlobField = Field then
    begin
      Result := @BlobInfo[ I ];
      Exit;
    end;
  Result := nil;
end;

function TxClientDataSet.CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream;
var Info : PBlobInfo;
    NewRec : boolean;
    Tmp    : TStream;
begin
  Info := GetBlobInfo(Field);
  if (RecordCount = 0) or not (State in [dsBrowse, dsEdit, dsInsert])
       or (Mode <> bmRead) or not FetchOnDemand or (BlobLen(Field) > 0) then
  begin
    if Mode = bmWrite then
      Result := TClientBlobStream.Create(Field as TBlobField, Mode)
    else
      Result := inherited CreateBlobStream(Field, Mode)
  end else
  begin
    NewRec := (UpdateStatus = usInserted) or (State = dsInsert);
    if Info <> nil then with Info^ do
    begin
      if (BlobDate.AsFloat = 0) or (Info.BlobName.AsString = '') then
      begin
        Result := TMemoryStream.Create;
        Exit;
      end else if NewRec or (BlobDate.AsFloat <> VarAsType(BlobDate.OldValue, varDouble)) or (BlobName.Value <> BlobName.OldValue) then
      begin
        Result := GetFileStream(Info.BlobName.Text);
        if ZipBlob and InApply then
        begin
           Tmp    := Result;
           Result := TMemoryStream.Create;
           with TZCompressionStream.Create(Result) do
           begin
             CopyFrom(Tmp, 0);
             Free;
           end;
           Tmp.Free;
        end;
        Exit;
      end;
    end;
    if NewRec or (Info = nil) and (BlobFetched(Field)) then
      Result := inherited CreateBlobStream(Field, Mode)
    else case ConnectType of
      ctIB  :
        Result := inherited CreateBlobStream(Field, Mode);
      ctADO :
        begin
          Result := CreateADOStream(Field);
        end;
      else
        Result := CreateMidasStream(Field);
    end;
  end;
  if ZipBlob then
  begin
    if Mode = bmWrite then
    begin
      Result := TCompressionStream.DoCreate(Result);
    end else if Mode = bmRead then
    begin
      Result := TDeCompressionStream.DoCreate(Result);
    end;
  end;
end;

function TxClientDataSet.BlobValue(AField : TField) : OleVariant;
var BS : TStream;
    P  : Pointer;
    S  : string;
begin
  BS := CreateBlobStream(AField, bmRead);
  try
    if AField is TMemoField then
    begin
      SetLength(S, BS.Size);
      BS.Read(S[ 1 ], BS.Size);
      Result := S;
    end else if BS.Size = 0 then
      Result := Unassigned
    else
    begin
      Result  := VarArrayCreate([0, BS.Size - 1], varByte);
      BS.Position := 0;
      P  := VarArrayLock(Result);
      try
        BS.Read(P^, BS.Size);
      finally
        VarArrayUnlock(Result);
      end;
    end;
  finally
    BS.Free;
  end;
end;

function TxClientDataSet.LockMaster : TLockResult;
var Master : TxClientDataSet;
begin
  Master := GetLockMaster;
  if Master = nil then
    Result := lrNo
  else
    Result := Master.LockRecord(True);
end;

function TxClientDataSet.GetLocked : boolean;
begin
  Result := (LockedRecord <> 0);
end;

procedure TxClientDataSet.SetNeedLock(Value : boolean);
begin
  if Value and (FindField('Locked') = nil) then
     raise Exception.Create('Can"t set NeedLock');
  FNeedLock := Value;
end;

function TxClientDataSet.LockedRecord : integer;
begin
  if NeedLock and (BookMarks.Count = 1) and (TKeyBookMark(BookMarks[ 0 ]).OldIdent < 0) then
    Result := TKeyBookMark(BookMarks[ 0 ]).OldIdent
  else
    Result := FLockedRecord;
end;

function TxClientDataSet.GetLockMaster : TxClientDataSet;
begin
  Result := Self;
  repeat
    if Result.NeedLock then
       Exit;
    if Assigned(Result.MasterSource) then
      Result := TxClientDataSet(Result.MasterSource.DataSet)
    else
      Result := nil;
  until Result = nil;
end;

procedure TxClientDataSet.MasterModify(Insert : boolean = False);
var Master : TxClientDataSet;
    MasterInserted : boolean;
    LockedRec  : integer;
begin
  Master := GetLockMaster;
  if Master = nil then
    Exit;
  LockedRec  := Master.LockedRecord;
  MasterInserted := (LockedRec <> 0);
  if not Master.NeedLock then
  begin
    if Assigned(Master.FOnMasterModify) then
      Master.FOnMasterModify(Self, MasterInserted);
    Exit;
  end;
  if MasterInserted and (Self = Master) and Insert then
    raise Exception.Create(Name + ' already inserted');
  if not Insert and (Master = Self) and (LockedRec <> Master.IdentField.AsInteger) and (LockedRec <> 0) then
    raise Exception.Create(Name + ' other record locked');
  if Insert and not MasterInserted then
    Exit;
  if Assigned(Master.FOnMasterModify) then
    Master.FOnMasterModify(Self, MasterInserted);
  if not MasterInserted and (Master.LockRecord(True) = lrFailed) then
    raise Exception.Create('Can"t lock master');
end;

procedure TxClientDataSet.MasterModified;
var Root : TxClientDataSet;
begin
  Root := Master;
  if Assigned(Root.FOnMasterModified) then
    Root.FOnMasterModified(Self)
end;

function  TxClientDataSet.LockRecord(Lock : boolean; Force : boolean = False) : TLockResult;
var //IsLevel : TIsolationLevel;
    RecordsAffected : integer;
    SQL : string;
begin
  Result := lrNo;
  if (FindField('Locked') = nil) or (IdentField = nil) then
    Exit;
  Result := lrYes;

  if Lock then
  begin
    Force := False;
    if Locked then
    begin
      if LockedRecord <> IdentField.AsInteger then
        raise Exception.Create('There is Locked master');
      Exit;
    end;
  end else if not Locked or (LockedRecord < 0) then
    Exit;
  if LockedRecord <> IdentField.AsInteger then
    Locate(IdentField.FieldName, LockedRecord, []);
  with Connection, ADOConnection do
  begin
    if Lock then
      SQL := 'UPDATE ' + TableName + ' SET Locked = ''' + Login + '''' +
        ' WHERE ' + IdentField.FieldName + ' = ' + IdentField.AsString +
        ' AND (Locked IS NULL or Locked = '''')'
    else
      SQL := 'UPDATE ' + TableName + ' SET Locked = NULL' +
        ' WHERE ' + IdentField.FieldName + ' = ' + IntToStr(LockedRecord) + ifthen(Force, '',
        ' AND (Locked IS NULL or Locked = '''' or Locked = ''' +  Login + ''')');
    Execute(SQL, RecordsAffected);
    FLockedRecord := 0;
    if RecordsAffected = 1 then
    begin
      if Lock then
        FLockedRecord := IdentField.AsInteger;
    end else
      Result := lrFailed;
  end;
end;

function TxClientDataSet.UpdateRef(const RefName : string)  : boolean;
var SQL : string;
begin
  CheckConnected;
  SQL  := 'update Remote_Ref_List set UpdateDate=? where NameDate=?';
  FApplyParams.Clear;
  TParam(FApplyParams.Add).Value := Now;
  TParam(FApplyParams.Add).Value := RefName;
  Result := PSExecuteSQL(SQL);
end;

function TxClientDataSet.PSExecuteSQL(const SQL : string) : boolean;
var ApplySet : TADOQuery;
begin
//  Result := True;
  case ConnectType of
    ctADO:
      begin
        ApplySet := TADOQuery.Create(nil);
        try
          ApplySet.Connection := Connection.ADOConnection;
          ApplySet.SQL.Text := SQL;
          RefreshParameters(ApplySet.Parameters, FApplyParams);
          try
            ApplySet.ExecSQL;
            Connection.CheckConnectionErrors;
          except
            on E:Exception do
               ApplyErr(E.Message, SQL);
          end;
        finally
          ApplySet.Free;
        end;
        Result := True;
      end;
    ctIB :
      Result := IProviderSupport(Provider.DataSet).PSExecuteStatement(SQL, FApplyParams, nil) <> 1;
    else
      Result := Connection.AppServerDisp.PSExecute('', SQL, PackageParams(FApplyParams), '') <> 1;
    end;
//    if not Result then
//      ApplyErr(TableName + '  failed', SQL);
end;

procedure TxClientDataSet.ApplyInserted;
var I  : integer;
    SQL, Columns, Values : string;
    RefValue : integer;
    Field : TField;
    ApplySet : TADOQuery;
    ValItem  : string;
    Weak     : boolean;
//    P : TParam;

  function Into : string;
  begin
    if ConnectType = ctIB then
      Result := 'INTO '
    else
      Result := '';
  end;

begin
  FApplyParams.Clear;
  DoBeforeApplyRecord;
  if Assigned(OnApplyInsert) then
    OnApplyInsert(Self, FIdentity)
  else
  begin
    if InsertIdentity and (FIdentField <> nil) then
    begin
      if RecKeyBookMark.UserIdent <> FInsertIdentityOn then
      begin
        FInsertIdentityOn := not FInsertIdentityOn;
        Connection.ExecSQL('SET IDENTITY_INSERT ' + TableName + ifthen(FInsertIdentityOn, ' ON', ' OFF'));
      end;
    end;
    Columns := '';
    Values  := '';
    FIdentity := 0;
//    if Name = 'cdsDoneFiles' then
//      Log('');

    for I := 0 to FieldCount - 1 do
    begin
      Field := Fields[ I ];
      if UseFieldInInsert(Field) or SameText(Field.FieldName, 'Locked') and NeedLock then
      begin
        ValItem := '?';
        if IsRefField(Field, RefValue, Weak) then
        begin
          if Weak then
            AddParam(Field, null, False)
          else
          begin
            if RefValue <> Field.AsInteger then
              RecKeyBookMark.Updates.AddObject(Field.FieldName, Pointer(RefValue));
            AddParam(Field, RefValue, False);
          end;
        end else if FIdentField = Field then
        begin
          if ConnectType = ctIB then
          begin
            FIdentity := IBIdentity(Connection.FIBDatabase, GenName);
            AddParam(Field, FIdentity, False);
          end else if ConnectType = ctADO then
          begin
            if FInsertIdentityOn then
              AddParam(Field, null)
            else
              Continue
          end else
            AddParam(Field, 0, False);
        end else if Field.IsBlob then
        begin
          AddParam(Field, null);
        end else if SameText(Field.FieldName, 'Locked') then
        begin
          if NeedLock then
            AddParam(Field, Connection.Login)
          else
            AddParam(Field, null);
        end else
          AddParam(Field, null);
        if Columns = '' then
        begin
          Columns := Field.FieldName;
          Values  := ValItem;
        end else
        begin
          Columns := Columns + ',' + Field.FieldName;
          Values  := Values + ',' + ValItem;
        end;
      end;
    end;
    if Columns = '' then
      SQL := 'INSERT ' + Into + TableName + ' DEFAULT VALUES'
    else
      SQL := 'INSERT ' + Into + TableName + ' (' + Columns + ') VALUES (' + Values + ')';
    with Connection do
      if Assigned(FIdentField) then
      begin
        case ConnectType of
          ctADO :
            begin
              ApplySet := TADOQuery.Create(nil);
              try
                ApplySet.Connection := ADOConnection;
                ApplySet.SQL.Text := SQL + #13#10'SELECT @@IDENTITY';
                RefreshParameters(ApplySet.Parameters, FApplyParams);
                try
                  ApplySet.Open;
                except
                  on E:Exception do
                    ApplyErr(E.Message, SQL);
                end;
                FIdentity := -1;
                with ApplySet do
                  if not EOF then
                    FIdentity := Fields[ 0 ].AsInteger;
              finally
                ApplySet.Free;
              end;
            end;
          ctIB :
            if IProviderSupport(Provider.DataSet).PSExecuteStatement(SQL, FApplyParams, nil) <> 1 then
              FIdentity := -1;
          ctMidas :
            FIdentity := AppServerDisp.PSExecute(GenName, SQL, PackageParams(FApplyParams), FIdentField.FieldName);
        end;
        if (Identity <= 0) and not FInsertIdentityOn then
          ApplyErr('INSERT for ' + TableName + '  failed', SQL);
        RecKeyBookMark.NewIdent := FIdentity;
      end else
        PSExecuteSQL(SQL);
  end;
//  LogRec('write ' + Name);
  if FIdentField <> nil then
  begin
//    Log('    ident ' + IntToStr(Identity));
    RecKeyBookMark.Updates.AddObject(IdentField.FieldName, Pointer(Identity));
  end;
end;

function TxClientDataSet.GetWhere(Params : TParams) : string;
var I     : integer;
    Field : TField;
    Item  : string;
begin
  Result := '';
  for I := 0 to FieldCount - 1 do
  begin
    Field := Fields[ I ];
    if UseFieldInWhere(Field, UpdateMode) then  with Field do
    begin
      if VarIsNull(OldValue) then
        Item  := FieldName + ' is NULL'
      else
      begin
        Item  := FieldName + '=?';
        TParam(Params.Add).AssignFieldValue(Field, Field.OldValue);
      end;
      if Result = '' then
        Result := Item
      else
        Result := Result + ' and ' + Item;
    end;
  end;
end;

function TxClientDataSet.GetKeyBookMark : TKeyBookMark;
var I : integer;
begin
  I := BookMarkIndex;
  if I = -1 then
    Result := nil
  else
    Result := TKeyBookMark(BookMarks[ I ]);
end;

function TxClientDataSet.RecKeyBookMark : TKeyBookMark;
begin
  if UniqueKey = '' then
    raise Exception.Create('Define UniqueKey');
  Result := GetKeyBookMark;
  if Result = nil then
  begin
    Result := TKeyBookMark.Create;
    Result.Key := FieldValues[ UniqueKey ];
    BookMarks.Add(Result);
  end;
end;

function TxClientDataSet.Master : TxClientDataSet;
begin
  Result := Self;
  while Assigned(Result.MasterSource) do Result := TxClientDataSet(Result.MasterSource.DataSet);
end;

procedure TxClientDataSet.ApplyErr(Err, SQL : string);
var S : string;
    I : integer;
begin
  S := '';
  for I := 0 to FApplyParams.Count - 1 do
    if FApplyParams[ I ].DataType in [ftBlob..ftmemo, ftOraBlob..ftOraClob] then
      S := S + #13#10'  [blob]'
    else
      S := S + #13#10 + '  ' + VarToStr(FApplyParams[ I ].Value);
  if ConnectType = ctADO then with Connection.ADOConnection do
  begin
    if Errors.Count <> 0 then
      Err := Errors.Item[ 0 ].Description;
  end;
  S := Err + #13#10 + SQL + S;
  Log(S);
  raise Exception.Create(S);
end;

procedure TxClientDataSet.ApplyModified;
var I : integer;
    SQL, Item, Sets : string;
    RefValue : integer;
    Field : TField;
    V : Variant;
    Weak : boolean;
begin
  FApplyParams.Clear;
  DoBeforeApplyRecord;
  if Assigned(OnApplyModified) then
  begin
    OnApplyModified(Self);
    Exit;
  end;
//  else if not IsValidIdent(TableName) then
//    raise Exception.Create('OnApplyModified not assigned');
  Sets := '';
  for I := 0 to FieldCount - 1 do
  begin
    Field := Fields[ I ];
    if UseFieldInUpdate(Field) and (Field <> FIdentField) then with Field do
    begin
      if IsRefField(Field, RefValue, Weak) then
      begin
        if Weak then
          AddParam(Field, null, False)
        else
        begin
          if RefValue = Field.AsInteger then
            Continue;
          RecKeyBookMark.Updates.AddObject(Field.FieldName, Pointer(RefValue));
          AddParam(Field, RefValue, False);
        end;
      end else
      begin
        if Field.IsBlob then
        begin
          AddParam(Field, null);
        end else
        begin
          V := Field.NewValue;
          if VarIsClear(V) then
            V := Field.OldValue;
          AddParam(Field, V, False);
        end;
      end;
      Item  := FieldName + '=?';
      if Sets = '' then
        Sets := Item
      else
        Sets := Sets + ',' + Item;
    end;
  end;
  if Sets <> '' then
  begin
    SQL := 'UPDATE ' + TableName + ' SET ' + Sets + ' WHERE ' + GetWhere(FApplyParams);
    PSExecuteSQL(SQL);
  end;
//  Log(Name + ' update with ' + IdentField.FieldName + ':' + IdentField.AsString);
end;

procedure TxClientDataSet.DoAfterEdit;
begin
  if not InApply then
    inherited;
end;

procedure TxClientDataSet.DoBeforeEdit;
begin
  if not InApply then
  begin
    inherited;
    MasterModify;
  end;
end;

procedure TxClientDataSet.DoBeforePost;
begin
  if not InApply then
    inherited;
end;

procedure TxClientDataSet.Post;
begin
  if State in [dsEdit, dsInsert] then
  begin
    UpdateRecord;
    if Modified or InApply then
      inherited
    else
      Cancel;
  end else
    inherited;
end;

function TxClientDataSet.IndexedByMaster : boolean;
begin
  Result := (MasterFields <> '') and (MasterSource <> nil) and (MasterSource.DataSet <> nil);
end;

procedure TxClientDataSet.SetIdentMasters;
var I : integer;
    List : TList;
begin
  if Assigned(FIdentField) and FIdentField.IsNull then
    FIdentField.AsInteger := AutoInc;
  if IndexedByMaster then
  begin
    List := TList.Create;
    try
      MasterSource.DataSet.GetFieldList(List, MasterFields);
      for I := 0 to List.Count - 1 do
        Index_Fields[ I ].Value := TField(List[ I ]).Value;
    finally
      List.Free;
    end;
  end;
  for I := 0 to FieldCount - 1 do with Fields[ I ] do
    if IsNull and (DefaultExpression <> '') then
      AsString := AnsiDequotedStr(DefaultExpression, '''');
end;

procedure TxClientDataSet.DataEvent(Event: TDataEvent; Info: Integer);
begin
  if not InApply and not (csDestroying in ComponentState) then
  begin
    inherited;
    case Event of
      deFieldChange :
        if State in [ dsEdit, dsInsert ] then
          MasterModified;
    else
    end;
  end;
end;

function TxClientDataSet.CopyRecord : Variant;
var I, J : integer;
    Rec, Dets : Variant;
begin
  Rec := VarArrayCreate([0, FieldCount - 1], varVariant);
  for I := 0 to FieldCount - 1 do with Fields[ I ] do
    if (FieldKind in [ fkData, fkInternalCalc ]) and not IsIdent(Fields[ I ]) then
      Rec[ I ] := Value;
  J := DetailDataSets.Count;
  if J <> 0 then
  begin
    Dets := VarArrayCreate([0, J - 1], varVariant);
    for I := 0 to J - 1 do with TxClientDataSet(DetailDataSets[ I ]) do
      Dets[ I ] := VarArrayOf([ GetDataTypes, CopyDetails]);
  end;
  Result := VarArrayOf([Rec, Dets]);
end;

function TxClientDataSet.GetDataTypes : Variant;
var I : integer;
begin
  Result := VarArrayCreate([0, FieldCount - 1], varVariant);
  for I := 0 to FieldCount - 1 do
    Result[ I ] := Fields[ I ].DataType;
end;

procedure TxClientDataSet.CopyToClipboard(SelectedRows: TBookmarkList = nil);
var I     : integer;
    Datas : Variant;
begin
  if (SelectedRows <> nil) and (SelectedRows.Count > 0) then
  begin
    Datas := VarArrayCreate([0, SelectedRows.Count - 1], varVariant);
    for I := 0 to SelectedRows.Count - 1 do
    begin
      GotoBookmark(Pointer(SelectedRows.Items[ I ]));
      Datas[ I ] := CopyRecord;
    end;
  end else
  begin
    Datas := VarArrayCreate([ 0, 0 ], varVariant);
    Datas[ 0 ] := CopyRecord;
  end;
  VClipBoard := VarArrayOf([ GetDataTypes, Datas]);
end;

procedure TxClientDataSet.PasteDetails(Dets : Variant);
var I : integer;
begin
  for I := 0 to VarArrayHighBound(Dets, 1) do
    PasteRecord(Dets[ I ]);
end;

procedure TxClientDataSet.PasteRecord(Rec : Variant);
var Flds, Dets : Variant;
    I, J : integer;
    CDS  : TxClientDataSet;
    SaveRO : boolean;
    MasterFld : TField;
begin
  if IndexedByMaster then
    MasterFld := Index_Fields[ 0 ]
  else
    MasterFld := nil;
  Flds := Rec[ 0 ];
  Append;
  for I := 0 to FieldCount - 1 do with Fields[ I ] do
    if (Fields[ I ] <> IdentField) and (Fields[ I ] <> MasterFld) and (FieldKind in [ fkData, fkInternalCalc ]) and not IsIdent(Fields[ I ]) then
    begin
      SaveRO   := ReadOnly;
      ReadOnly := False;
      Value    := Flds[ I ];
      ReadOnly := SaveRO;
    end;
  Post;
  Dets := Rec[ 1 ];
  if VarIsArray(Dets) then
    for I := 0 to VarArrayHighBound(Dets, 1) do
    begin
      CDS := nil;
      for J := 0 to DetailDataSets.Count - 1 do
        if TxClientDataSet(DetailDataSets[ J ]).CanPaste(Dets[ I ]) then
        begin
          CDS := TxClientDataSet(DetailDataSets[ J ]);
          Break;
        end;
      if CDS <> nil then with CDS do
        PasteDetails(Dets[ I ][ 1 ]);
    end;
end;

procedure TxClientDataSet.PasteFromClipboard;
var I : integer;
begin
  if not CanPaste then
    raise Exception.Create('DataType differs');
  for I := 0 to VarArrayHighBound(VClipBoard[ 1 ], 1) do
    PasteRecord(VClipBoard[ 1 ][ I ]);
end;

function TxClientDataSet.CanPaste(V : Variant) : boolean;
var I : integer;
    Types : Variant;
begin
  Result := False;
  try
    Types := V[ 0 ];
    I := VarArrayHighBound(Types, 1);
    if I <> FieldCount - 1 then
      Exit;
    for I := 0 to FieldCount - 1 do
      if Types[ I ] <> Fields[ I ].DataType then
        Exit;
  except
    Exit;
  end;
  Result := True;
end;

function TxClientDataSet.CanPaste : boolean;
begin
  Result := VarIsArray(VClipBoard) and CanPaste(VClipBoard);
end;

function TxClientDataSet.CopyDetails : Variant;
var J : integer;
begin
  Result := VarArrayCreate([0, RecordCount - 1], varVariant);
  J  := 0;
  First;
  while not EOF do
  begin
    Result[ J ] := CopyRecord;
    Inc(J);
    Next;
  end;
end;

procedure TxClientDataSet.RefApply;
var I : integer;
begin
  for I := 0 to StackTop - 1 do
    if Stack[ I ] = Self then
       Exit;
//      raise Exception.Create(Name + ' recursive refers');
  Stack [ StackTop ] := Self;
  Inc(StackTop);
  for I := 0 to Length(RefFields) - 1 do with RefFields[ I ] do
    if not WeakRef and (ToDataSet <> Self) then
      ToDataSet.InternalApplyUpdates;
  Dec(StackTop);
end;

procedure TxClientDataSet.InternalApplyUpdates;
var I, J : integer;
    V    : OleVariant;
    SQL, W : string;
    Field: TField;
    Item : string;
    Fields : TList;
begin
  RefApply;
  if (asInApply in ApplyState) or (ApplyState = []) then
    Exit;
  Include(ApplyState, asInApply);
  DoBeforeApplyUpdates(V);
  PrepareDeleteProc;
  for I := 0 to BookMarks.Count - 1 do with TKeyBookMark(BookMarks[ I ]) do
  begin
    Locate(UniqueKey, Key, []);
    if State = 'I' then
      ApplyInserted
    else if State = 'M' then
      ApplyModified
//    else if Assigned(FOnApplyDeleted) then
//      FOnApplyDeleted
    else if DeleteProc <> '' then
      ExecDeleteProc(TKeyBookMark(BookMarks[ I ]))
    else
    begin
      FApplyParams.Clear;
      W := '';
      if Pos(';', UniqueKey) <> 0 then
      begin
        Fields := TList.Create;
        try
          GetFieldList(Fields, UniqueKey);
          for J := 0 to Fields.Count - 1 do
          begin
            Field := TField(Fields[ J ]);
            Item  := Field.FieldName + '= ? ';
            AddParam(Field, Key[ J ], False);
            if W = '' then
              W := Item
            else
              W := W + ' and ' + Item;
          end;
        finally
          Fields.Free;
        end;
      end else
      begin
        Field := FieldByName(UniqueKey);
        AddParam(Field, Key, False);
        W := Field.FieldName + '= ? ';
      end;
      SQL := 'DELETE FROM ' + TableName + ' WHERE ' + W;
      if not PSExecuteSQL(SQL) then
         ApplyErr('DELETE for ' + TableName + '  failed', SQL);
    end;
  end;
  if InsertIdentity and FInsertIdentityOn then
  begin
    FInsertIdentityOn := False;
    Connection.ExecSQL('SET IDENTITY_INSERT ' + TableName + ' OFF');
  end;
  DoAfterApplyUpdates(V);
  for I := 0 to DetailDataSets.Count - 1 do
    (DetailDataSets[ I ] as TxClientDataSet).InternalApplyUpdates;
end;

procedure TxClientDataSet.ExecDeleteProc(ABookMark : TKeyBookMark);
var I : integer;
begin
  with DelProc do
  begin
    for I := 0 to FieldCount - 1 do with Fields[ I ] do
      if UseFieldInWhere(Fields[ I ], UpdateMode) then
        Params.ParamByName(FieldName).AssignFieldValue(Fields[ I ], ABookMark.Key[ I ]);
    Execute;
  end;
end;

procedure TxClientDataSet.PrepareDeleteProc;
var I : integer;
begin
  if DeleteProc <> '' then
  begin
    if DelProc = nil then
    begin
      DelProc := TxClientDataSet.Create(nil);
      DelProc.ResultSet  := False;
    end;
    with DelProc do
    begin
      FSQL.Text := DeleteProc;
      Params.Clear;
      for I := 0 to FieldCount - 1 do with Fields[ I ] do
        if UseFieldInWhere(Fields[ I ], UpdateMode) then
          Params.CreateParam(DataType, Connection.AddDog(FieldName), ptInput).Size := Size;
      Connection := Self.Connection;
    end;
  end;
end;

function TxClientDataSet.GetRecAttr : DSAttr;
var RecInfoOfs : integer;
begin
//  DSCursor.GetRecordAttribute(Result);
  RecInfoOfs := GetRecordSize + CalcFieldsSize;
  Result     := PRecInfo(ActiveBuffer + RecInfoOfs).Attribute;
end;

procedure TxClientDataSet.CancelDataSetUpdates;
var I : integer;
begin
  if State in [ dsEdit, dsInsert ] then
    Cancel;
  if ChangeCount > 0 then
  begin
    CancelUpdates;
    MasterModified;
  end;
  BookMarks.Clear;
//  UpdateDetailDataSetList;
  for I := 0 to DetailDataSets.Count - 1 do
    with DetailDataSets[ I ] as TxClientDataSet do
      CancelDataSetUpdates;
end;

function TxClientDataSet.TableName : string;
begin
  if Trim(ApplyTable) <> '' then
    Result := ApplyTable
  else
    Result := FTableName;
end;

function TCustomxConnection.LoadFromServer(TableName, FName : string) : boolean;
var Age        : integer;
    LastUpdate : TDateTime;
begin
  Result := True;
  if FName = ''  then
    Exit;
  LastUpdate := TableLastUpdate(TableName);
  if LastUpdate = 0 then
  begin
//    FileName := '';
    Exit;
  end;
  Age  := FileAge(FName);
  if Age <> -1 then
    Result := LastUpdate > FileDateToDateTime(Age);
end;

//  ----------- TxSortedClientDataSet

Procedure TxSortedClientDataSet.SetSort(Value:string);
var SL: TStringList;
    k,i:integer;
    s:string;
    sFlds: string;
    sDFlds: string;

Procedure DelimitedListToStringList(text: string; aList: TStringList; aDelimiter: string = ',');
var ij :integer;
    sv:string;
Begin
 aList.Clear;
 sv := text;
 While sv <> '' do begin
  sv := Trim(sv);
  ij := Pos(aDelimiter,sv);
  if ij = 0 then ij := Length(sv)+1;
  alist.Add(Trim(Copy(sv,1,ij-1)));
  System.Delete(sv,1,ij+Length(aDelimiter)-1);
 end;
end;

Begin
 FSort := Value;
 sFlds := '';
 sDFlds := '';
 sL := TStringList.Create;
 IndexName :='';
 if Trim(Value) = '' then exit;
 if not Active then exit;
 try
  DelimitedListToStringList(value,sl,',');
  For i := 0 to Sl.Count-1 do Begin
    s := UpperCase(Trim(Sl.Strings[i]));
    if s = '' then break;
    k := 0;
    If Length(s) > 4 then
     if Copy(s,Length(s)-3,4) = ' ASC' then begin
       k := 1;
       s := Trim(Copy(s,1,Length(s)-3));
     end else
      if Copy(s,Length(s)-4,5) = ' DESC' then begin
         k := -1;
         s := Trim(Copy(s,1,Length(s)-4));
      end;
     if sFlds <> '' then sFlds := sFlds + ';';
     sFlds := sFlds + s;
     if k < 0 then begin
        if sDFlds <> '' then sDFlds := sDFlds + ';';
        sDFlds := sDFlds + s;
     end;

  end;
  try
   DeleteIndex('x1');
  except
  end;
  AddIndex('x1', sFlds, [], sDFlds);
  IndexName := 'x1';
 except
 end;
 sL.Free;
end;

Procedure TxSortedClientDataSet.DoAfterOpen;
Begin
 inherited;
 if Trim(Sort) <> '' then Sort := Sort;
end;

Procedure TxSortedClientDataSet.DoAfterClose;
Begin
 inherited;
 IndexName := '';
end;

// -------------- register

procedure Register;
begin
  RegisterComponents('TSES', [TxConnection, TxClientDataSet, TxSortedClientDataset]);
end;

{ TCompressionStream }

constructor TCompressionStream.DoCreate(dest: TStream;
  compressionLevel: TZCompressionLevel);
begin
  inherited Create(dest, compressionLevel);
  FDest := dest;
end;

destructor TCompressionStream.Destroy;
begin
  inherited;
  FDest.Free;
end;

{ TDeCompressionStream }

destructor TDeCompressionStream.Destroy;
begin
  inherited;
  FSource.Free;
end;

constructor TDeCompressionStream.DoCreate(source: TStream);
begin
  inherited Create(source);
  FSource := source;
end;

function TxClientDataSet.NewIdent(OldId: Integer): Integer;
var I : integer;
begin
  for I := 0 to Length(LastChangeIdent) - 1 do
    if LastChangeIdent[ I ].Old = OldId then
    begin
      Result := LastChangeIdent[ I ].New;
      Exit;
    end;
  Result := OldId;
//  raise Exception.Create('Ident not found');
end;

function TxClientDataSet.GetIndex_Field(Index: Integer): TField;
var List : TList;
begin
  if IndexFieldCount > 0 then
    Result := IndexFields[ Index ]
  else
  begin
    List := TList.Create;
    try
      GetFieldList(List, IndexFieldNames);
      if Index >= List.Count then
        DatabaseError(SFieldIndexError, Self);
      Result := TField(List[ Index ]);
    finally
      List.Free;
    end;
  end;
end;

procedure TxClientDataSet.SetIndex_Field(Index: Integer; Value: TField);
begin
  GetIndex_Field(Index).Assign(Value);
end;

function TCustomxConnection.LockAll(Lock : boolean): boolean;
var I : integer;
begin
  if not Connected then
    raise Exception.Create('Connected = False');
  BeginTrans;
  try
    for I := 0 to Clients.Count - 1 do with TxClientDataSet(Clients[ I ]) do
      if NeedLock and Active and (Locked <> Lock) then
        if LockRecord(Lock) <> lrYes then
          raise Exception.Create('Can not ' + ifthen(Lock, '', 'un') + 'lock ' + TableName);

    CommitTrans;
    Result := True;
  except
    on E:Exception do
    begin
      RollBackTrans;
      Result := False;
      ShowMessage(E.Message);
    end;
  end;
end;

function TKeyBookMark.GetNewIdent: integer;
begin
  if FNewIdent = 0 then
    raise Exception.Create('FNewIdent = 0');
  Result := FNewIdent;
end;

procedure TKeyBookMark.SetNewIdent(const Value: integer);
begin
  if Value = 0 then
    raise Exception.Create('NewIdent value = 0');
  FNewIdent := Value;
end;

procedure TCustomxConnection.CheckConnected;
begin
  if not Connected then
    SetConnected(True);
end;

initialization
  FUpdatedRefs := TStringList.Create;
  FUpdatedRefs.CaseSensitive := False;

finalization
  FUpdatedRefs.Free;
  try
    DelProc.Free;
  except
  end;

end.
