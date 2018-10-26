unit UDown;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ShlObj, ActiveX, UrlMon, StdCtrls, ComCtrls, ExtCtrls, ShellApi;

type
  TBindStatusCallback = class(TObject, IBindStatusCallback)
  protected
     FRefCount: Integer;
   // IUnknown
     function QueryInterface(const IID: TGUID; out Obj): Integer; stdcall;
     function _AddRef: Integer; stdcall;
     function _Release: Integer; stdcall;
  public
    function OnStartBinding(dwReserved: DWORD; pib: IBinding): HResult; stdcall;
    function GetPriority(out nPriority): HResult; stdcall;
    function OnLowResource(reserved: DWORD): HResult; stdcall;
    function OnProgress(ulProgress, ulProgressMax, ulStatusCode: ULONG;
      szStatusText: LPCWSTR): HResult; stdcall;
    function OnStopBinding(hresult: HResult; szError: LPCWSTR): HResult; stdcall;
    function GetBindInfo(out grfBINDF: DWORD; var bindinfo: TBindInfo): HResult; stdcall;
    function OnDataAvailable(grfBSCF: DWORD; dwSize: DWORD; formatetc: PFormatEtc;
      stgmed: PStgMedium): HResult; stdcall;
    function OnObjectAvailable(const iid: TGUID; punk: IUnknown): HResult; stdcall;
  end;

  TFDown = class(TForm)
    ProgressBar: TProgressBar;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Image1: TImage;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Callback : IBindStatusCallback;
    filesize : DWORD;
    function DoDownload : boolean;
  end;


var
  FDown: TFDown;
  URLDownloadToFile : function (Caller: IUnknown; URL: PWideChar; FileName: PWideChar; Reserved: DWORD; StatusCB: IInterface): HResult; stdcall = nil;
  IsValidURL        : function (pBC: IInterface; URL: PWideChar; dwReserved: DWORD): HResult; stdcall = nil;
  URL     : string = 'http://robofile.ru/content/317/109/';
  FileName: string = '761_CrossFire_20100622.exe';
  Target  : string;
  DeskTop : string;
  lasttick, starttick : DWORD;
  lastloaded : ULONG;

implementation

{$R *.dfm}

function TBindStatusCallback.QueryInterface(const IID: TGUID;
  out Obj): Integer;
begin
  if GetInterface(IID, Obj) then Result := S_OK
                            else Result := E_NOINTERFACE;
end;

function TBindStatusCallback._AddRef: Integer;
begin
 Inc(FRefCount);
 Result := FRefCount;
end;

function TBindStatusCallback._Release: Integer;
begin
 Dec(FRefCount);
 Result := FRefCount;
end;

function TBindStatusCallback.GetBindInfo(out grfBINDF: DWORD;
  var bindinfo: TBindInfo): HResult;
begin
  Result := S_OK;
end;

function TBindStatusCallback.GetPriority(out nPriority): HResult;
begin
  Integer(nPriority) := 2;
  Result := S_OK;
end;

function TBindStatusCallback.OnDataAvailable(grfBSCF, dwSize: DWORD;
  formatetc: PFormatEtc; stgmed: PStgMedium): HResult;
begin
  FDown.filesize := dwSize;
  Result := S_OK;
end;

function TBindStatusCallback.OnLowResource(reserved: DWORD): HResult;
begin
  Result := S_OK;
end;

function TBindStatusCallback.OnObjectAvailable(const iid: TGUID;
  punk: IUnknown): HResult;
begin
  Result := S_OK;
end;

function TBindStatusCallback.OnStartBinding(dwReserved: DWORD;
  pib: IBinding): HResult;
begin
  Result := S_OK;
end;

function TBindStatusCallback.OnStopBinding(hresult: HResult;
  szError: LPCWSTR): HResult;
begin
  Result := S_OK;
end;

function TBindStatusCallback.OnProgress(ulProgress, ulProgressMax,
  ulStatusCode: ULONG; szStatusText: LPCWSTR): HResult;

function MB(bytes : integer) : string;
begin
  Result := IntToStr(bytes div (1024 * 1024)) + 'ћб';
end;

var proc, speed : string;
    tick, filesize, loaded, waitsec : DWORD;
    fproc : double;
    iproc : integer;
begin
  Result := S_OK;
  if ulProgressMax = 0 then
    Exit;
  tick := GetTickCount;
  filesize := FDown.filesize;
  fproc := ulProgress / ulProgressMax;
  iproc := Round(fproc * 100.0);
  FDown.ProgressBar.Position := iproc;
  if (tick > lasttick + 1000) or (ulProgress = ulProgressMax) then
  begin
    if filesize <> 0 then
    begin
      proc  := IntToStr(iproc);
      loaded:= Round(filesize * fproc);
      speed := IntToStr(Round((loaded - lastloaded) / (tick - lasttick)));
      FDown.Label5.Caption:='—качано : ' + MB(loaded) +' из ' + MB(filesize) + '(' + proc + '%), скорость : ' + speed + 'кб/сек';
      lastloaded := loaded;
    end else if (ulProgress <> ulProgressMax) and (iproc > 10)  then
    begin
      waitsec := Round((tick - starttick) * (1.0 - fproc)) div 1000;
      FDown.Label5.Caption:= '»дет загрузка, осталось ' + IntToStr(waitsec) + ' сек';
    end else if iproc < 95 then
      FDown.Label5.Caption:= '»дет загрузка...';
    lasttick := tick;
  end;
  Application.ProcessMessages;
end;

var
  UrlMonHandle : HMODULE;

function InitUrlMon : boolean;
const
  UrlMonLib = 'URLMON.DLL';
  sURLDownloadToFileW = 'URLDownloadToFileW';
  sIsValidURL = 'IsValidURL';
begin
  Result := Assigned(URLDownloadToFile);
  if not Result then
  begin
    UrlMonHandle := LoadLibrary(UrlMonLib);
    if UrlMonHandle = 0 then
       Exit;
    URLDownloadToFile := GetProcAddress(UrlMonHandle, sURLDownloadToFileW);
    IsValidURL := GetProcAddress(UrlMonHandle, sIsValidURL);
    Result := true;
  end;
end;

function TFDown.DoDownload : boolean;
var Res : HResult;
    errmsg : string;
begin
  errmsg := '';
  try
    lasttick := GetTickCount;
    starttick := lasttick;
    lastloaded   := 0;
    Res := URLDownloadToFile(nil, PWideChar(URL), PWideChar(Target), 0, Callback);
    if Res <> S_OK then
    begin
      if Res = -2147483646 then // $80000002 = E_OUTOFMEMORY
        errmsg := 'Insufficient memory'
      else if Res = -2147221020	then  // $800401E4 = MK_E_SYNTAX
        errmsg := 'Invalid URL syntax'
      else if Res = -2147024891	then  // $80070005 (ERROR_ACCESS_DENIED, ...)
        errmsg := 'Access denied'
      else if Res = -2146697211	then  // $800C0005 = INET_E_RESOURCE_NOT_FOUND
        errmsg := 'Cannot locate the Internet server'
      else if Res = -2146697210	then  // 0x800C0006 = INET_E_OBJECT_NOT_FOUND
        errmsg := 'File not found'
      else if Res = -2146697208	then  // $800C0008 = INET_E_DOWNLOAD_FAILURE
        errmsg := 'Cannot download'
      else if Res = -2146697203	then  // $800C000D = INET_E_UNKNOWN_PROTOCOL
        errmsg := 'Unknown URL protocol'
      else if IsValidURL(nil, PWideChar(URL), 0) <> S_OK then
        errmsg := 'Is not ValidURL'
      else			 // not a recognized error code
        errmsg := 'Download failed Err - ' + IntToStr(Res);
    end;
  except
    on E:Exception do
     errmsg := E.Message;
  end;
  Result := errmsg = '';
  if not Result then
    Label6.Caption := errmsg + ' : ' + URL;
end;

procedure Execute(const FileName : string);
var
  SEI: TShellExecuteInfo;
begin
  FillChar(SEI, SizeOf(SEI), 0); // Wipe the record to start with
  with SEI do
  begin
    cbSize := SizeOf(SEI);
    lpVerb := 'open';
    lpFile := PWideChar(FileName);
    lpParameters := nil;
    nShow := SW_SHOWNORMAL;
    ShellExecuteEx(@SEI);
  end;
end;


procedure Exec(const FileName: string);
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  CmdLine: string;
begin
  CmdLine := '"' + FileName + '"';
  FillChar(StartInfo, SizeOf(StartInfo), #0);
  with StartInfo do
  begin
    cb := SizeOf(StartInfo);
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := SW_SHOWNORMAL;
  end;
  CreateProcess(nil, PWideChar(CmdLine), nil, nil, False,
    CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, nil, StartInfo, ProcInfo);
end;

function GetSpecialPath(CSIDL: Word): string;
var
  S : WideString;
begin
  SetLength(S, MAX_PATH);
  if not SHGetSpecialFolderPath(0, PWideChar(S), CSIDL, True) then
    S := '';
  Result := string(PWideChar(S));
end;


procedure TFDown.FormActivate(Sender: TObject);
begin
  if DoDownload then
  begin
    Execute(Target);
    Close;
  end;
end;

procedure TFDown.FormCreate(Sender: TObject);
begin
  Callback := TBindStatusCallback.Create;
end;

procedure TFDown.FormShow(Sender: TObject);
begin
  if not InitUrlMon then
  begin
    ShowMessage('URLMON.DLL не надена');
    Application.Terminate;
    Exit;
  end;
  DeskTop := GetSpecialPath(CSIDL_DESKTOP);
  Target  := DeskTop + '\' + FileName;
  URL := URL + FileName;
  Label2.Caption := URL;
//  URL := URL +  '?' + IntToStr(random(100000));
  Label4.Caption := Target;
end;

end.
