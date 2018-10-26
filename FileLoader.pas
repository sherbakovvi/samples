unit FileLoader;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Dialogs,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, DBGrids, Grids,
  IdFTP, IdFTPList, IdFTPCommon, IniFiles, StrUtils, ComCtrls,
  Themes, Forms, DB, URegIni1, Logger;

type
  PMemItems = ^TMemItems;
  PMemItem  = ^TMemItem;
  TMemItem = record
    List     : PMemItems;
    Name     : string;
    Dir      : boolean;
    DirList  : PMemItems;
    Modified : TDateTime;
    LocModified : TDateTime;
    NewVer   : boolean;
    Selected : boolean;
    FileSize : integer;
    Loaded   : boolean;
  end;
  TMemItems = record
    UpItems : PMemItems;
    RemDir, LocDir : string;
    Items : TList;
  end;

  TBeforeLoadFile = procedure (FileName : string; Dir : boolean; var Accept : boolean) of object;
  TOnProgress = procedure (ProgressPercent : integer; FileName : string) of object;
  TAfterGetItem = procedure (FileName : string; Dir : boolean; var Accept : boolean) of object;
  TOnGetFileType = procedure (FileName : string; var Index : integer; var FileTypeName : string) of object;

  TLoadMode = (lmAll, lmSelected, lmModified);
  TLoadModes = set of TLoadMode;

  TCustomFTPLoader = class(TComponent)
  private
    FRemote   : boolean;
    FHost     : string;
    FLocalRoot: string;
    FRootMemItems : PMemItems;
    FAfterLoad : TNotifyEvent;
    FAfterGetItem : TAfterGetItem;
    FBeforeLoadFile : TBeforeLoadFile;
    FOnGetFileType  : TOnGetFileType;
    FOnProgress     : TOnProgress;
    FTotalSize      : integer;
    FTP : TIdFTP;
    FLoadedSize : integer;
    LoadErr     : boolean;
    FCheckOnly  : boolean;
    FFlat       : boolean;
    FSelectModified : boolean;
    FModifiedOnly   : boolean;
    FLoadSelf   : boolean;
    FView           : TListView;
    procedure SetAfterLoad(const Value: TNotifyEvent);
    procedure SetAfterGetItem(const Value: TAfterGetItem);
    procedure SetBeforeLoadFile(const Value: TBeforeLoadFile);
    procedure SetOnGetFileType(const Value: TOnGetFileType);
    procedure SetHost(const Value: string);
    procedure SetLocalRoot(const Value: string);
    procedure SetOnProgress(const Value: TOnProgress);
    procedure SetRemote(const Value: boolean);
    procedure SetCheckOnly(const Value: boolean);
    procedure SetFlat(const Value: boolean);
    procedure SetSelectModified(const Value: boolean);
    procedure SetModifiedOnly(const Value: boolean);
    function  GetConnected : boolean;
    procedure SetConnected(const Value: boolean);
    procedure SetView(Value : TListView);
    procedure ClearTree;
    function GetDir(AMemItem : PMemItem) : PMemItems;
    function RemoteGetDir(AMemItem : PMemItem) : PMemItems;
    function NewFile(FileName : string; Modified : TDateTime; Size : integer; Item : PMemItem) : boolean;
    procedure GetAll;
    function  GetPort : integer;
    procedure CheckInactive;
    procedure SetPort(Value : integer);
    function FileType(FileName : string; var Index : integer) : string;
    procedure Connect;
    procedure Disconnect;
    procedure SetFlatList;
    procedure SetList(List : PMemItems = nil);
    procedure Click(Sender : TObject);
    procedure DblClick(Sender : TObject);
    procedure SelectNew;
    procedure ShowView;
    procedure CheckListFormat(ASender: TObject; const ALine: String; Var VListFormat: TIdFTPListFormat);
    procedure CreateFTPList(ASender: TObject; Var VFTPList: TIdFTPListItems);
    procedure ParseCustomListFormat(AItem: TIdFTPListItem);
  protected
    procedure DoAfterGetItem(FileName : string; Dir : boolean; var Accept : boolean; Item : PMemItems); virtual;
  public
    constructor Create(AOwner : TComponent); override;
    destructor  Destroy; override;
    function  NeedUpdate : boolean;
    procedure Load(LoadMode : TLoadModes);
    procedure LoadFile(Item : PMemItem);
    function  GetFile(var PutName : string; GetName : string) : boolean;
    function FindItem(AMemItems : PMemItems; ItemName : string) : PMemItem;
    property TotalSize      : integer read FTotalSize;
    property LoadedSize     : integer read FLoadedSize;
    property RootMemItems : PMemItems read FRootMemItems;
    property Connected  : boolean read GetConnected write SetConnected;
    property Flat       : boolean read FFlat write SetFlat;
    property SelectModified : boolean read FSelectModified write SetSelectModified;
    property ModifiedOnly   : boolean read FModifiedOnly write SetModifiedOnly;
    property View           : TListView read FView write SetView;
    property Remote   : boolean read FRemote write SetRemote;
    property Host     : string read FHost write SetHost;
    property LocalRoot: string read FLocalRoot write SetLocalRoot;
    property AfterLoad : TNotifyEvent read FAfterLoad write SetAfterLoad;
    property AfterGetItem : TAfterGetItem read FAfterGetItem write SetAfterGetItem;
    property BeforeLoadFile : TBeforeLoadFile read FBeforeLoadFile write SetBeforeLoadFile;
    property OnGetFileType  : TOnGetFileType read FOnGetFileType write SetOnGetFileType;
    property OnProgress     : TOnProgress read FOnProgress write SetOnProgress;
    property Port : integer read GetPort write SetPort;
    property CheckOnly  : boolean read FCheckOnly write SetCheckOnly;
    property LoadSelf   : boolean read FLoadSelf;
  end;

  TFTPLoader = class(TCustomFTPLoader)
  published
    property Remote;
    property Host;
    property LocalRoot;
    property AfterLoad;
    property AfterGetItem;
    property BeforeLoadFile;
    property OnGetFileType;
    property OnProgress;
    property Port;
    property CheckOnly;
  end;


procedure Register;

implementation

uses UTimeBias;

var
  LastError : integer = 0;
{ TCustomFTPLoader }

function SortCompare(Item1, Item2: Pointer): Integer;
begin
  if PMemItem(Item1).Dir and not PMemItem(Item2).Dir then
    Result := -1
  else if not PMemItem(Item1).Dir and PMemItem(Item2).Dir then
    Result := 1
  else
    Result := CompareText(PMemItem(Item1).Name, PMemItem(Item2).Name);
end;

function TCustomFTPLoader.GetPort : integer;
begin
  Result := FTP.Port;
end;

function  TCustomFTPLoader.GetConnected : boolean;
begin
  Result := not Remote and (RootMemItems <> nil) or FTP.Connected;
end;

procedure TCustomFTPLoader.SetConnected(const Value : boolean);
begin
  if Connected <> Value then
  begin
    if Value then
      Connect
    else
      Disconnect;
  end;
end;

procedure TCustomFTPLoader.CheckInactive;
begin
  if not (csDesigning in ComponentState) then
    Disconnect;
end;

procedure TCustomFTPLoader.SetPort(Value : integer);
begin
  CheckInactive;
  FTP.Port := Value;
end;

function TCustomFTPLoader.FileType(FileName : string; var Index : integer) : string;
var Ext : string;
begin
  Ext := ExtractFileExt(FileName);
  Index := -1;
  Result := UpperCase(Copy(Ext, 2, MAXINT)) + ' ' + ExtractFileName(FileName);
  if Assigned(OnGetFileType) then
    OnGetFileType(FileName, Index, Result);
end;

procedure TCustomFTPLoader.SetList(List : PMemItems = nil);
var I, Ind : integer;
    ListItem : TListItem;
begin
  Flat := False;
  if List = nil then
    List := RootMemItems;
  with List^, View.Items do
  begin
    BeginUpdate;
    try
      Clear;
      if Assigned(UpItems) then
      begin
        ListItem := Add;
        ListItem.Caption := '..';
        ListItem.SubItems.Add('<DIR>');
        ListItem.ImageIndex := 7;
        ListItem.Data := List;
      end;
      for I := 0 to Items.Count - 1 do with PMemItem(Items[ I ])^ do
      begin
        if ModifiedOnly and not NewVer and not Dir then
          Continue;
        ListItem := Add;
        ListItem.Caption := Name;
        ListItem.Data := Items[ I ];
        if not Dir then
        begin
          ListItem.Selected := not ModifiedOnly and SelectModified and NewVer;
          ListItem.SubItems.Add(FileType(Name, Ind));
          ListItem.ImageIndex := Ind;
          ListItem.SubItems.Add(IntToStr(FileSize));
          ListItem.SubItems.Add(FormatDateTime('dd.mm.yyyy hh:nn', Modified));
        end else
        begin
          ListItem.SubItems.Add('<DIR>');
          ListItem.ImageIndex := 7;
          ListItem.SubItems.Add('');
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

function TCustomFTPLoader.FindItem(AMemItems : PMemItems; ItemName : string) : PMemItem;
var I : integer;
    LevName : string;
begin
  I := Pos('\', ItemName);
  if I = 0 then
  begin
    LevName  := ItemName;
    ItemName := '';
  end else
  begin
    LevName  := Copy(ItemName, 1, I - 1);
    ItemName := Copy(ItemName, I + 1, MaxInt);
  end;
  Result := nil;
  if AMemItems <> nil then with AMemItems^ do
    for I := 0 to Items.Count - 1 do with PMemItem(Items[ I ])^ do
    begin
      if SameText(Name, LevName) then
      begin
        if ItemName = '' then
          Result := PMemItem(Items[ I ])
        else
          Result := FindItem(PMemItem(Items[ I ])^.DirList, ItemName);
        Exit;
      end;
    end;
end;

procedure TCustomFTPLoader.SetFlatList;
var Indent : integer;

  procedure RollOut(AMemItems : PMemItems);
  var I, Ind : integer;
      ListItem : TListItem;
  begin
    with AMemItems^ do
      for I := 0 to Items.Count - 1 do with PMemItem(Items[ I ])^ do
      begin
        if ModifiedOnly and not NewVer and not Dir then
          Continue;
        ListItem := View.Items.Add;
        ListItem.Caption := Name;
        ListItem.Data := Items[ I ];
        ListItem.Indent:= Indent;
        if not Dir then
        begin
          ListItem.Selected := not ModifiedOnly and SelectModified and NewVer;
          ListItem.SubItems.Add(FileType(Name, Ind));
          ListItem.ImageIndex := Ind;
          ListItem.SubItems.Add(IntToStr(FileSize));
          ListItem.SubItems.Add(FormatDateTime('dd.mm.yyyy hh:nn', Modified));
        end else
        begin
          ListItem.SubItems.Add('<DIR>');
          ListItem.ImageIndex := 7;
          ListItem.SubItems.Add('');
          Inc(Indent);
          RollOut(DirList);
        end;
    end;
  end;
begin
  Flat := True;
  with View.Items do
  begin
    BeginUpdate;
    try
      Clear;
      Indent := 0;
      RollOut(RootMemItems);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TCustomFTPLoader.Disconnect;
begin
  if Remote then
    FTP.Disconnect;
  ClearTree;
end;

procedure TCustomFTPLoader.Connect;
begin
  if Remote then with FTP do
  begin
    Username := 'anonymous';
    Password := 'idftp@client.com';
    Host     := FHost;
    try
      if Assigned(FOnProgress) then
        FOnProgress(0, 'Connecting');
      Connect;
    except
      Disconnect;
      raise;
    end;
  end;
 if Assigned(FOnProgress) then
   FOnProgress(0, 'Checking files');
  GetAll;
  if not CheckOnly and Assigned(View) then
    ShowView;
end;

procedure TCustomFTPLoader.ParseCustomListFormat(AItem: TIdFTPListItem);
var S : string;
    D, T : TDateTime;
    iMin, iHour : integer;
begin
  S := AItem.Data;
//  Log(S);
  if Pos('<', S) <> 0 then
    AItem.ItemType  := ditDirectory
  else
  begin
    AItem.ItemType  := ditFile;
    AItem.Size := StrToInt(Trim(Copy(S, 31, 8)));
//    Log(IntToStr(AItem.Size));
  end;
  AItem.FileName  := Copy(S, 40, MaxInt);
//  Log(AItem.FileName);
  SetLength(S, 30);
  S := UpperCase(S);
  D := EncodeDate(2000 + StrToInt(Copy(S, 7, 2)), StrToInt(Copy(S, 1, 2)), StrToInt(Copy(S, 4, 2)));
  iHour := StrToInt(Copy(S, 11, 2));
  iMin := StrToInt(Copy(S, 14, 2));
  if Pos('P', S) <> 0 then
  begin
    if iHour < 12 then
      Inc(iHour, 12);
  end;
  if Pos('A', S) <> 0  then
  begin
    if iHour = 12 then
      iHour := 0;
  end;
  T := EncodeTime(iHour, iMin, 0, 0);
  AItem.ModifiedDate := D + T;
//  Log(DateTimeToStr(AItem.ModifiedDate));
//  Log('-----------');
end;

procedure TCustomFTPLoader.CheckListFormat(ASender: TObject; const ALine: String; Var VListFormat: TIdFTPListFormat);
begin
  VListFormat := flfCustom;
end;

procedure TCustomFTPLoader.CreateFTPList(ASender: TObject; Var VFTPList: TIdFTPListItems);
begin
  VFTPList := TIdFTPListItems.Create;
  VFTPList.OnParseCustomListFormat := ParseCustomListFormat;
end;

constructor TCustomFTPLoader.Create(AOwner : TComponent);
begin
  inherited Create(Aowner);
  FTP := TIdFTP.Create(Self);
  FTP.OnCheckListFormat := CheckListFormat;
  FTP.OnCreateFTPList   := CreateFTPList;
end;

procedure TCustomFTPLoader.ClearTree;

  procedure ClrItem(MemItems : PMemItems);
  var I : integer;
  begin
    if MemItems <> nil then with MemItems^ do
    begin
      for I := 0 to Items.Count - 1 do with PMemItem(Items[ I ])^ do
      begin
        if Dir then
          ClrItem(DirList);
        Dispose(PMemItem(Items[ I ]));
      end;
      Items.Free;
      Dispose(MemItems);
    end;
  end;

begin
  ClrItem(RootMemItems);
  FRootMemItems := nil;
end;

destructor TCustomFTPLoader.Destroy;
begin
  ClearTree;
  try
    FTP.Free;
  except
  end;
  inherited;
end;

//var II : byte;
function TCustomFTPLoader.NewFile(FileName : string; Modified : TDateTime; Size : integer; Item : PMemItem) : boolean;
var F : TSearchRec;
    FName : string;
begin
  Result := True;
  FName := ExtractFileName(Trim(Filename));
//  if SameText('equipment.exe', FName) then
//    II := 1;
  Item.LocModified := 0;
  if FindFirst(FileName, faAnyFile, F) = 0 then
  begin
    Item.LocModified := ModifiedDate(F);
    Result := CompareFileDateTime(Modified, Item.LocModified) > 0;
    FindClose(F);
  end;
  if Result and SameText(Fname, 'Cipher.dll') then
    Result := False;
end;

function TCustomFTPLoader.GetFile(var PutName : string; GetName : string) : boolean;
var PutStream : TFileStream;
begin
  ForceDirectories(ExtractFileDir(PutName));
  if SameText(ExtractFileName(PutName), ExtractFileName(ParamStr(0))) then
  begin
    FLoadSelf := True;
    PutName := ChangeFileExt(PutName, '.ex');
  end;
  Result := True;
  try
    if Remote then
    begin
      PutStream := TFileStream.Create(PutName, fmCreate);
      try
        FTP.TransferType := ftBinary;
        FTP.Get('/' + GetName, PutStream, False);
        Sleep(50);
      finally
        PutStream.Free;
      end;
    end else
      Result := CopyFile(PChar(GetName), PChar(PutName), False);
  except
    Result := False;
  end;
end;

procedure TCustomFTPLoader.LoadFile(Item : PMemItem);
var PutName : string;
begin
  with Item^, List^ do
  begin
    PutName := LocDir + '\' + Name;
    Loaded  := GetFile(PutName, RemDir + '\' + Name);
    if Loaded then
    begin
      FileSetDate(PutName, DateTimeToFileDate(Modified));
      Inc(FLoadedSize, Item^.FileSize);
      if Assigned(FOnProgress) and (FTotalSize <> 0) then
        FOnProgress(MulDiv(LoadedSize, 100, FTotalSize), Name);
      Log(PutName + ', Modified : ' + DateTimeToStr(Modified) + ', LocModified : ' + DateTimeToStr(LocModified));
    end else
    begin
      LastError := GetLastError;
      Log(SysErrorMessage(LastError));
      Log('From : ' + RemDir + '\' + Name);
      Log('Failed : ' + PutName + ', Modified : ' + DateTimeToStr(Modified) + ', LocModified : ' + DateTimeToStr(LocModified));
      LoadErr  := True;
    end;
  end;
end;

function TCustomFTPLoader.GetDir(AMemItem : PMemItem) : PMemItems;
var F : TSearchRec;
    tItem : PMemItem;
    Accepted : boolean;
begin
  if Remote then
    Result := RemoteGetDir(AMemItem)
  else
  begin
    if (AMemItem = nil) and not DirectoryExists(FHost) then
      raise Exception.Create('Directory ' + FHost + ' not found');
    New(Result);
    with Result^ do
    begin
      if AMemItem = nil then
      begin
        LocDir := LocalRoot;
        RemDir := FHost;
        UpItems := nil;
      end else with AMemItem^ do
      begin
        RemDir := List.RemDir + '\' + Name;
        LocDir := List.LocDir + '\' + Name;;
        UpItems := List;
      end;
      Items   := TList.Create;
      if FindFirst(RemDir + '\*.*', faAnyFile, F) = 0 then
      try
        repeat
          Accepted := True;
          if F.Attr and faDirectory <> 0 then
          begin
            if F.Name[ 1 ] = '.' then
              Accepted := False
            else
              DoAfterGetItem(F.Name, True, Accepted, Result);
          end else
            DoAfterGetItem(F.Name, False, Accepted, Result);
          if Accepted then
          begin
            New(tItem);
            Result^.Items.Add(tItem);
            with tItem^ do
            begin
              List   := Result;
              Name   := F.Name;
              Modified := ModifiedDate(F);
              Dir    := F.Attr and faDirectory <> 0;
              NewVer := not Dir and NewFile(Result.LocDir + '\' + F.Name, Modified, F.Size, tItem);
              DirList:= nil;
              Selected := False;
              Loaded   := False;
            end;
            tItem.FileSize := F.Size;
          end;
        until FindNext(F) <> 0;
      finally
        FindClose(F);
      end;
    end;
  end;
  Result.Items.Sort(SortCompare);
end;

procedure TCustomFTPLoader.DoAfterGetItem(FileName : string; Dir : boolean; var Accept : boolean; Item : PMemItems);
begin
  if Assigned(FAfterGetItem) then
  begin
    AfterGetItem(Copy(Item.LocDir, Length(LocalRoot) + 2, MAXINT) + '\' + FileName, False, Accept);
  end;
end;

function TCustomFTPLoader.RemoteGetDir(AMemItem : PMemItem) : PMemItems;
var I : integer;
    tItem : PMemItem;
    DirListing : TIdFTPListItems;
    Accepted : boolean;
begin
  New(Result);
  with Result^, FTP do
  begin
    Sleep(50);
    TransferType := ftASCII;
    if AMemItem = nil then
    begin
      LocDir := LocalRoot;
      ChangeDir('\' + SysRegIni.SourceDir);
    end else with AMemItem^ do
    begin
      RemDir := List.RemDir + '\' + Name;
      LocDir := List.LocDir + '\' + Name;;
      ChangeDir('\' + RemDir);
    end;
    Sleep(50);
    List(nil);
    if AMemItem = nil then
    begin
      Sleep(50);
      RemDir  := RetrieveCurrentDir;
      UpItems := nil;
    end else
      UpItems := AMemItem.List;
    Items   := TList.Create;
    DirListing := DirectoryListing;
  end;
  for I := 0 to DirListing.Count - 1 do with DirListing[ I ] do
  begin
    FileName := Trim(FileName);
    Accepted := True;
    if ItemType = ditFile then
      DoAfterGetItem(FileName, False, Accepted, Result)
    else if (ItemType <> ditDirectory) or (FileName[ 1 ] = '.') then
      Accepted := False
    else
      DoAfterGetItem(FileName, True, Accepted, Result);
    if not Accepted then
      Continue;
    New(tItem);
    Result^.Items.Add(tItem);
    with tItem^ do
    begin
      List   := Result;
      Name   := Trim(FileName);
      Dir    := ItemType <> ditFile;
      NewVer := not Dir and NewFile(Result.LocDir + '\' + FileName, ModifiedDate, Size, tItem);
      DirList  := nil;
      Modified := ModifiedDate;
      Selected := False;
      Loaded   := False;
    end;
    tItem.FileSize := Size;
  end;
end;

function TCustomFTPLoader.NeedUpdate : boolean;

  procedure Check(AMemItems : PMemItems);
  var I : integer;
      Accept : boolean;
  begin
    if AMemItems <> nil then
    begin
      for I := 0 to AMemItems.Items.Count - 1 do with PMemItem(AMemItems.Items[ I ])^ do
      begin
        Accept := True;
        if Assigned(FBeforeLoadFile) then
          FBeforeLoadFile(List.LocDir + '\' + Name, Dir, Accept);
        if not Accept then
          Continue;
        if Dir then
          Check(DirList)
        else if NewVer then
        begin
          if CheckOnly then
            Log('new ' + List.LocDir + '\' + Name + ', Modified : ' + DateTimeToStr(Modified) + ', LocModified : ' + DateTimeToStr(LocModified));
          Abort;
        end;
      end;
    end;
  end;

begin
  Result := False;
  try
    Check(FRootMemItems);
  except
    Result := True;
  end;
end;

procedure TCustomFTPLoader.GetAll;

  procedure RollOut(AMemItems : PMemItems);
  var I : integer;
  begin
    with AMemItems^ do
    begin
      if Remote and Assigned(OnProgress) then
        OnProgress(0, LocDir);
      for I := 0 to Items.Count - 1 do with PMemItem(Items[ I ])^ do
        if Dir then
        begin
          DirList := GetDir(Items[ I ]);
          RollOut(DirList);
        end;
    end;
  end;

begin
  ClearTree;
  FRootMemItems := GetDir(nil);
  if FRootMemItems <> nil then
    RollOut(FRootMemItems);
end;

procedure TCustomFTPLoader.Load(LoadMode: TLoadModes);

  procedure CountSize(MemItems : PMemItems; DirSelected : boolean = False);
  var I : integer;
      Accept : boolean;
  begin
    if MemItems <> nil then with MemItems^ do
    begin
      for I := 0 to Items.Count - 1 do with PMemItem(Items[ I ])^ do
      begin
        Accept := True;
        if Assigned(FBeforeLoadFile) then
          FBeforeLoadFile(List.LocDir + '\' + Name, Dir, Accept);
        if not Accept then
        else if Dir then
        begin
          if not Assigned(DirList) then
            DirList := GetDir(Items[ I ]);
          CountSize(DirList, Selected);
        end else if ((lmAll in LoadMode) or (lmSelected in LoadMode) and (DirSelected or Selected)
           or (lmModified in LoadMode) and NewVer) and not Loaded then
            Inc(FTotalSize, FileSize);
      end;
    end;
  end;

  procedure DoLoad(MemItems : PMemItems; DirSelected : boolean = False);
  var I : integer;
      Accept : boolean;
  begin
    if MemItems <> nil then with MemItems^ do
    begin
      for I := 0 to Items.Count - 1 do with PMemItem(Items[ I ])^ do
      begin
        Accept := True;
        if Assigned(FBeforeLoadFile) then
          FBeforeLoadFile(List.LocDir + '\' + Name, Dir, Accept);
        if not Accept then
        else if Dir then
        begin
          if not Assigned(DirList) then
            DirList := GetDir(Items[ I ]);
          DoLoad(DirList, Selected);
        end else if ((lmAll in LoadMode) or (lmSelected in LoadMode) and (DirSelected or Selected)
           or (lmModified in LoadMode) and NewVer) and not Loaded then
          LoadFile(Items[ I ]);
      end;
    end;
  end;

begin
  if RootMemItems = nil then
    Exit;
  if lmAll in LoadMode then
    Log('Load all');
  if lmSelected in LoadMode then
    Log('Load Selected');
  if lmModified in LoadMode then
    Log('Load Modified');
  FLoadedSize := 0;
  FTotalSize  := 0;
  CountSize(RootMemItems);
  Log(IntToStr(FTotalSize) + '-FTotalSize');

  LoadErr    := False;
  try
    DoLoad(RootMemItems);
    while LoadErr do
    begin
      if MessageDlg(SysErrorMessage(LastError) + ', Close all applications and hit OK', mtConfirmation, [ mbOK, mbCancel ], 0) = mrCancel then
        Abort;
      LoadErr := False;
      DoLoad(RootMemItems);
    end;
  except
    Disconnect;
    raise;
  end;
  if Assigned(FAfterLoad) then
    FAfterLoad(Self);
end;

procedure TCustomFTPLoader.DblClick(Sender : TObject);
begin
  with View do
    if Selected <> nil then with Selected do
    begin
      if Caption = '..' then
        SetList(PMemItems(Data)^.UpItems)
      else if SubItems[ 0 ] = '<DIR>' then with PMemItem(Data)^ do
      begin
        if not Flat then
          SetList(DirList);
      end else
      begin
        FLoadedSize:= 0;
        FTotalSize := 0;
        LoadFile(Data);
        if not PMemItem(Data)^.Loaded then
          ShowMessage(SysErrorMessage(LastError) + ', Close all applications and repeat Loading');
        LoadErr    := False;
        if Assigned(FAfterLoad) then
          FAfterLoad(Self);
      end;
    end;
end;

procedure TCustomFTPLoader.Click(Sender : TObject);
var I : integer;
begin
  with View do
    for I := 0 to Items.Count - 1 do with Items[ I ] do
      if Caption = '..' then
         PMemItem(Data)^.Selected := Selected;
end;

procedure TCustomFTPLoader.SelectNew;
var I : integer;
    Item : PMemItem;
begin
  with View do
  begin
    Items.BeginUpdate;
    try
      for I := 0 to Items.Count - 1 do
      begin
        if Items[ I ].Caption = '..' then
          Continue;
        Item := PMemItem(Items[ I ].Data);
        if Item.NewVer then
          Items[ I ].Selected := SelectModified;
      end;
    finally
      Items.EndUpdate;
    end;
  end;
end;

procedure TCustomFTPLoader.SetAfterLoad(const Value: TNotifyEvent);
begin
  FAfterLoad := Value;
end;

procedure TCustomFTPLoader.SetAfterGetItem(const Value: TAfterGetItem);
begin
  FAfterGetItem := Value;
end;

procedure TCustomFTPLoader.SetOnGetFileType(const Value: TOnGetFileType);
begin
  FOnGetFileType := Value;
end;

procedure TCustomFTPLoader.SetBeforeLoadFile(const Value: TBeforeLoadFile);
begin
  FBeforeLoadFile := Value;
end;

procedure TCustomFTPLoader.SetHost(const Value: string);
begin
  if FHost <> Value then
  begin
    CheckInactive;
    FHost := Value;
  end;
end;

procedure TCustomFTPLoader.SetLocalRoot(const Value: string);
begin
  if FLocalRoot <> Value then
  begin
    CheckInactive;
    FLocalRoot := Value;
  end;
end;

procedure TCustomFTPLoader.SetOnProgress(const Value: TOnProgress);
begin
  FOnProgress := Value;
end;

procedure TCustomFTPLoader.ShowView;
begin
  if RootMemItems = nil then
    Exit;
  if FFlat then
    SetFlatList
  else
    SetList;
end;

procedure TCustomFTPLoader.SetFlat(const Value: boolean);
begin
  if FFlat <> Value then
  begin
    FFlat := Value;
    ShowView;
  end;
end;

procedure TCustomFTPLoader.SetSelectModified(const Value: boolean);
begin
  if FSelectModified <> Value then
  begin
    FSelectModified:= Value;
    if Value then
      FModifiedOnly := False;
    SelectNew;
  end;
end;

procedure TCustomFTPLoader.SetModifiedOnly(const Value: boolean);
begin
  if FModifiedOnly <> Value then
  begin
    FModifiedOnly := Value;
    if Value then
      FSelectModified := False;
    ShowView;
  end;
end;

procedure TCustomFTPLoader.SetCheckOnly(const Value: boolean);
begin
  if FCheckOnly <> Value then
  begin
    CheckInactive;
    FCheckOnly := Value;
  end;
end;

procedure TCustomFTPLoader.SetView(Value : TListView);
begin
  if FView <> nil then
    raise Exception.Create('View already assigned');
  FView := Value;
  FView.OnClick := Click;
  FView.OnDblClick := DblClick;
end;


procedure TCustomFTPLoader.SetRemote(const Value: boolean);
begin
  if FRemote <> Value then
  begin
    CheckInactive;
    FRemote := Value;
  end;
end;

procedure Register;
begin
  RegisterComponents('TSES', [TFTPLoader]);
end;

end.
