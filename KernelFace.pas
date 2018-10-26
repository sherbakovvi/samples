unit KernelFace;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Forms,
     WinSock, Controls, SConnect, KernDemo_TLB, KernCallBack_TLB,
     ActiveX, ReadWriteData, Dialogs, ComObj, Registry, Logger,
     DB, dbClient, Midas;

const
  THREAD_RECEIVEDSTREAM = WM_USER + 1;
type
  TOnEndPlayDVR = procedure (Handle: Integer) of object;
  TOnEndSaveDVR = procedure (Handle: Integer) of object;
  TOnCommand = procedure (Cmd : Integer) of object;
  TOnPing = procedure of object;

  TKernel = class;
  TCallBackThread = class(TThread)
  private
    FPipe : THandle;
    FOvr  : OVERLAPPED;
    FSemaphore: THandle;
    FParentHandle : THandle;
  protected
    procedure Execute; override;
  public
    constructor Create(Pipe : THandle; Handle : THandle);
    destructor Destroy; override;
    property Semaphore: THandle read FSemaphore;
  end;

  TCallBack = class(TAutoIntfObject, ICallBack)
  private
    FKernel : TKernel;
  public
    procedure EndPlayDVR(Handle: Integer); safecall;
    procedure EndSaveDVR(Handle: Integer); safecall;
    procedure SendTo(Cmd: Integer); safecall;
    procedure Ping; safecall;
  public
    constructor Create(Kernel : TKernel);
  end;

  TKernel = class(TComponent)
  private
    FLocal    : boolean;
    FCallBack : ICallBack;
    FKernDisp : IKernelDisp;
    Pipe  : THandle;
    FOnEndPlayDVR : TOnEndPlayDVR;
    FOnEndSaveDVR : TOnEndSaveDVR;
    FOnPing : TOnPing;
    FOnCommand : TOnCommand;
    FIP : string;
    FConnected : boolean;
    FHandle: THandle;
    Thread : TCallBackThread;
    function  GetKernDisp: IKernelDisp;
    procedure SetConnected(Value : boolean);
    procedure Connect;
    procedure SetIP(const Value: string);
    function GetHandle: THandle;
  protected
    procedure Loaded; override;
    procedure WndProc(var Message: TMessage);
    procedure ThreadReceivedStream(var Message: TMessage); message THREAD_RECEIVEDSTREAM;
    procedure CallBack(Buffer : PChar; ReadBytes : DWORD);
    property  Handle: THandle read GetHandle;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Open(cds : TClientDataSet);
    procedure ExecSQL(SQL : string);
    property KernDisp : IKernelDisp read GetKernDisp;
  published
    property Connected : boolean read FConnected write SetConnected;
    property IP : string read FIP write SetIP;
    property OnEndPlayDVR : TOnEndPlayDVR read FOnEndPlayDVR write FOnEndPlayDVR;
    property OnEndSaveDVR : TOnEndSaveDVR read FOnEndSaveDVR write FOnEndSaveDVR;
    property OnPing : TOnPing read FOnPing write FOnPing;
    property OnCommand : TOnCommand read FOnCommand write FOnCommand;
  end;

procedure Register;

implementation

function OwnIP : string;
var ErrorCode : Integer;
    WSAData   : TWSAData;
    LP        : PHostEnt;
    HostName  : array[ 0..100 ] of char;
    InAddr: TInAddr;
begin
  ErrorCode := WSAStartup($0101, WSAData);
  if ErrorCode <> 0 then
    raise Exception.Create('WindowsSocketError : ' + SysErrorMessage(ErrorCode));
  try
    if gethostname(HostName, 100) <> 0 then
      raise Exception.Create('WindowsSocketError : ' + SysErrorMessage(WSAGetLastError));
    LP := GetHostByName(HostName);
    if LP = nil then
      raise Exception.Create('WindowsSocketError : ' + SysErrorMessage(WSAGetLastError));
    FillChar(InAddr, SizeOf(InAddr), 0);
    if LP <> nil then with InAddr, LP^ do
    begin
      S_un_b.s_b1 := h_addr^[0];
      S_un_b.s_b2 := h_addr^[1];
      S_un_b.s_b3 := h_addr^[2];
      S_un_b.s_b4 := h_addr^[3];
    end;
    Result := inet_ntoa(InAddr)
  finally
    WSACleanup;
  end;
end;

function GetRegValue(const Key, Name : string; RootKey : HKEY = HKEY_LOCAL_MACHINE) : string;
var Reg : TRegistry;
begin
  Result := '';
  Reg    := TRegistry.Create;
  try
    Reg.RootKey := RootKey;
    if Reg.OpenKey(Key, False) then
      Result := Reg.ReadString(Name);
  finally
    Reg.Free;
  end;
end;

{ TCallBack }

constructor TCallBack.Create(Kernel: TKernel);
var
  Lib  : ITypeLib;
  Path : string;
begin
//  Path := GetRegValue('\SOFTWARE\Classes\TypeLib\' +
//    GuidToString(LIBID_KernCallBack)+ '\1.0\0\win32', '');
//  if Path = '' then
    Path := GetCurrentDir + '\KernCallBack.tlb';
  OleCheck(LoadTypeLib(PWideChar(WideString(Path)), Lib));
  inherited Create(Lib, ICallBackDisp);
  FKernel := Kernel;
end;

procedure TCallBack.EndPlayDVR(Handle: Integer);
begin
  if Assigned(FKernel.FOnEndPlayDVR) then
    FKernel.FOnEndPlayDVR(Handle);
end;

procedure TCallBack.EndSaveDVR(Handle: Integer);
begin
  if Assigned(FKernel.FOnEndSaveDVR) then
    FKernel.FOnEndSaveDVR(Handle);
end;

procedure TCallBack.Ping;
begin
  if Assigned(FKernel.FOnPing) then
    FKernel.FOnPing;
end;

procedure TCallBack.SendTo(Cmd : Integer);
begin
  if Assigned(FKernel.FOnCommand) then
    FKernel.FOnCommand(Cmd);
end;

{ TKernel }

constructor TKernel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCallBack := TCallBack.Create(Self) as ICallBack;
end;

destructor TKernel.Destroy;
begin
  if Thread <> nil then with Thread do
  begin
    Terminate;
    SetEvent(FOvr.hEvent);
    WaitForSingleObject(Semaphore, INFINITE);
    Free;
  end;
  FKernDisp := nil;
  FCallBack := nil;
  if Pipe <> 0 then
    CloseHandle(Pipe);
  inherited;
end;

function TKernel.GetKernDisp: IKernelDisp;
begin
  if not Connected then
    raise Exception.Create('Kernal disconnected');
  Result := FKernDisp;
end;

function GetVariantPointer(const Value: OleVariant): Pointer;
begin
  case VarType(Value) of
    varEmpty, varNull: Result := nil;
    varDispatch: Result := TVarData(Value).VDispatch;
    varVariant: Result := @Value;
    varUnknown: Result := TVarData(Value).VUnknown;
  else
    Result := @TVarData(Value).VPointer;
  end;
end;

procedure TKernel.CallBack(Buffer : PChar; ReadBytes : DWORD);
var
  ExcepInfo: TExcepInfo;
  DispParams: TDispParams;
  DispID, Flags, i: Integer;
  RetVal: HRESULT;
  VarFlags: TVarFlags;
  VarList: PVariantArray;
  V : OleVariant;
  Stream : TMemStream;
begin
  VarList := nil;
  FillChar(ExcepInfo, SizeOf(ExcepInfo), 0);
  FillChar(DispParams, SizeOf(DispParams), 0);
  Stream := TMemStream.Create;
  try
    Stream.Write(Buffer^, ReadBytes);
    StrDispose(Buffer);
    Stream.Position := 0;
    DispID := Stream.ReadVariant(VarFlags);
//    Log('DispID = ' + IntToStr(DispID));

    Flags  := Stream.ReadVariant(VarFlags);
    Stream.ReadVariant(VarFlags); // ExpectResult
    DispParams.cArgs := Stream.ReadVariant(VarFlags);
    DispParams.cNamedArgs := Stream.ReadVariant(VarFlags);
    try
      DispParams.rgdispidNamedArgs := nil;
      if DispParams.cNamedArgs > 0 then
      begin
        GetMem(DispParams.rgdispidNamedArgs, DispParams.cNamedArgs * SizeOf(Integer));
        for i := 0 to DispParams.cNamedArgs - 1 do
          DispParams.rgdispidNamedArgs[i] := Stream.ReadVariant(VarFlags);
      end;
      if DispParams.cArgs > 0 then
      begin
        GetMem(DispParams.rgvarg, DispParams.cArgs * SizeOf(TVariantArg));
        GetMem(VarList, DispParams.cArgs * SizeOf(OleVariant));
        Initialize(VarList^, DispParams.cArgs);
        for i := 0 to DispParams.cArgs - 1 do
        begin
          VarList[i] := Stream.ReadVariant(VarFlags);
          if vfByRef in VarFlags then
          begin
            if vfVariant in VarFlags then
            begin
              DispParams.rgvarg[i].vt := varVariant or varByRef;
              TVarData(DispParams.rgvarg[i]).VPointer := @VarList[i];
            end else
            begin
              DispParams.rgvarg[i].vt := VarType(VarList[i]) or varByRef;
              TVarData(DispParams.rgvarg[i]).VPointer := GetVariantPointer(VarList[i]);
            end;
          end else
            DispParams.rgvarg[i] := TVariantArg(VarList[i]);
        end;
      end;
      RetVal := FCallBack.Invoke(DispID, GUID_NULL, 0, Flags, DispParams, @V, @ExcepInfo, nil);
      if RetVal = DISP_E_EXCEPTION then
      begin
  //        WriteVariant(ExcepInfo.scode, Data);
  //        WriteVariant(ExcepInfo.bstrDescription, Data);
      end;
    finally
      if DispParams.rgdispidNamedArgs <> nil then
        FreeMem(DispParams.rgdispidNamedArgs);
      if VarList <> nil then
      begin
        Finalize(VarList^, DispParams.cArgs);
        FreeMem(VarList);
      end;
      if DispParams.rgvarg <> nil then
        FreeMem(DispParams.rgvarg);
    end;
  finally
    Stream.Free;
  end;
end;

procedure TKernel.Connect;
var Appl, PipeName : string;
    hPipe : THandle;
    Ovr   : OVERLAPPED;
    ReadBytes : DWORD;
    Res : integer;
begin
  FConnected := False;
  FLocal := IP = OwnIP;
  Appl := ChangeFileExt(ExtractFileName(Application.ExeName), '');
  if FLocal then
  begin
    FKernDisp := IKernelDisp(CoKernel.Create);
    PipeName  := '\\.\pipe\Kernel';
  end else
  begin
    PipeName  := '\\' + IP + '\pipe\Kernel';
    FKernDisp := IKernelDisp(CoKernel.CreateRemote(IP));
  end;
  if not WaitNamedPipe(PChar(PipeName), NMPWAIT_USE_DEFAULT_WAIT) then
    RaiseLastOSError;
  Pipe := CreateFile(PChar(PipeName), GENERIC_READ,
     FILE_SHARE_READ, nil, CREATE_NEW, FILE_FLAG_OVERLAPPED, 0);
  if Pipe = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  try
    Ovr.hEvent := CreateEvent(nil, True, False, nil);
    if not ReadFile(Pipe, hPipe, SizeOf(hPipe), ReadBytes, @Ovr) then
    begin
      Res := GetLastError;
      if Res <> ERROR_IO_PENDING then
        raise Exception.Create('ReadFile : ' + SysErrorMessage(Res));
        Res := WaitForSingleObject(Ovr.hEvent, INFINITE);
      if Res <> WAIT_OBJECT_0 then
        raise Exception.Create('WaitForSingleObject : ' + SysErrorMessage(GetLastError));
      if not GetOverlappedResult(Pipe, Ovr, ReadBytes, False) then
        raise Exception.Create('GetOverlappedResult : ' + SysErrorMessage(GetLastError));
    end;
  finally
    CloseHandle(Ovr.hEvent);
  end;
  FKernDisp.Connect(hPipe, '', IP, Appl);
  Thread := TCallBackThread.Create(Pipe, Handle);
  WaitForSingleObject(Thread.Semaphore, INFINITE);
  FConnected := True;
end;

procedure TKernel.SetConnected(Value: boolean);
begin
  if Value <> FConnected then
  begin
    FConnected := Value;
    if FConnected and ([ csDesigning, csLoading ] * ComponentState = []) then
      Connect;
  end;
end;

procedure TKernel.Loaded;
begin
  inherited;
  if FConnected and not (csDesigning in ComponentState) then
  begin
    if FIP = '' then
      FConnected := False
    else
      Connect;
  end;
end;

procedure TKernel.SetIP(const Value: string);
begin
  FIP := Value;
end;

procedure TKernel.Open(cds: TClientDataSet);
begin
  cds.AppServer := KernDisp as IAppServer;
  cds.ProviderName := 'QueryProvider';
  cds.Open;
end;

procedure TKernel.ExecSQL(SQL: string);
var cds: TClientDataSet;
begin
  cds := TClientDataSet.Create(nil);
  try
    cds.AppServer   := KernDisp as IAppServer;
    cds.CommandText := SQL;
    cds.ProviderName := 'ProcProvider';
    cds.Execute;
  finally
    cds.Free;
  end;
end;

function TKernel.GetHandle: THandle;
begin
  if FHandle = 0 then
    FHandle := Classes.AllocateHwnd(WndProc);
  Result := FHandle;
end;

procedure TKernel.WndProc(var Message: TMessage);
begin
  try
    Dispatch(Message);
  except
    if Assigned(ApplicationHandleException) then
      ApplicationHandleException(Self);
  end;
end;

procedure TKernel.ThreadReceivedStream(var Message: TMessage);
begin
  with Message do
    CallBack(PChar(lParam), wParam);
end;

{ TCallBackThread }

constructor TCallBackThread.Create(Pipe : THandle; Handle : THandle);
begin
  inherited Create(True);
  FPipe := Pipe;
  FOvr.hEvent := CreateEvent(nil, True, False, nil);
  FreeOnTerminate := False;
  FSemaphore := CreateSemaphore(nil, 0, 1, nil);
  FParentHandle := Handle;
  Resume;
end;

destructor TCallBackThread.Destroy;
begin
  CloseHandle(FSemaphore);
  CloseHandle(FOvr.hEvent);
  inherited;
end;

procedure TCallBackThread.Execute;
var DataLen   : DWORD;
    DataBlock : PChar;

  function ReadData(var Buffer; Len : DWORD) : boolean;
  var ReadBytes : DWORD;
      Res : integer;
  begin
    Result := False;
    if not ReadFile(FPipe, Buffer, Len, ReadBytes, @FOvr) then
    begin
      if Terminated then
        Exit;
      Res := GetLastError;
      if Res <> ERROR_IO_PENDING then
      begin
        Log('ReadFile : ' + SysErrorMessage(Res));
        Exit;
      end;
    end else
    begin
      Result := not Terminated;
      Exit;
    end;
    Res := WaitForSingleObject(FOvr.hEvent, INFINITE);
    if Terminated then
      Exit;
    if Res <> WAIT_OBJECT_0 then
    begin
      Log('WaitForSingleObject : ' + SysErrorMessage(GetLastError));
      Exit;
    end;
    if not GetOverlappedResult(FPipe, FOvr, ReadBytes, False) then
    begin
      Log('GetOverlappedResult : ' + SysErrorMessage(GetLastError));
      Exit;
    end;
    if ReadBytes <> Len then
    begin
      Log('ReadBytes <> BytesToRead');
      Exit;
    end;
    Result := True;
  end;

begin
  ReleaseSemaphore(FSemaphore, 1, nil);
  try
    while not Terminated do
    begin
      ResetEvent(FOvr.hEvent);
      if not ReadData(DataLen, SizeOf(integer)) then
        Exit;
      ResetEvent(FOvr.hEvent);
      DataBlock := StrAlloc(DataLen);
      if not ReadData(DataBlock^, DataLen) then
        Exit;
      PostMessage(FParentHandle, THREAD_RECEIVEDSTREAM, DataLen, Integer(DataBlock));
    end;
  finally
    ReleaseSemaphore(FSemaphore, 1, nil);
  end;
end;

procedure Register;
begin
  RegisterComponents('GUARD', [TKernel]);
end;

end.
