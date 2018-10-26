unit TextViewer;

interface

uses Messages, Windows, SysUtils, Classes, Grids,
  Variants, Graphics, Menus, Controls, Forms, StdCtrls,
  Mask, Tokens, Math, StrUtils, Clipbrd, Dialogs,UTimeBias;

const
  MaxLineLen = 1024;
  lenEOL = {$IFDEF LINUX}1{$ELSE}2{$ENDIF};
  VK_CHAR  = 1;
  VK_PASTE = 2;
  VK_POS   = 3;
  MinEqu   = 4;
  ScanStep = 4;
type
  PHistRec = ^THistRec;
  THistRec = record
    Msg : DWORD;
    New : string;
    Pos : Integer;
    Old : string;
    Over: boolean;
  end;

  TSourceInfo = class;
  TOnPutFile = procedure (Str : TMemoryStream; FileInfo : TSourceInfo) of object;
  TOnGetFile = procedure (Str : TMemoryStream; FileInfo : TSourceInfo) of object;
  TSourceInfo = class(TObject)
    FileName: string;
    FileDate: TDateTime;
    FileData: Pointer;
    Item    : TMenuItem;
    Unicode : boolean;
    UTF8    : boolean;
    FileInd : integer;
    OnPutFile : TOnPutFile;
    OnGetFile : TOnGetFile;
  end;

  THistList = class(TList)
    procedure DeleteLast;
    function  GetItem(Index: Integer):PHistRec;
    destructor Destroy; override;
    property Items[Index: Integer]: PHistRec read GetItem;
  end;

  TScrollDirection = set of (sdLeft, sdRight, sdUp, sdDown);
  TUseFont = (ufCheck, ufCourier, ufOwn);
  TCustomTextViewer = class(TCustomControl)
  private
    FSelecting  : boolean;
    FAnchor     : TPoint;
    FCurrent    : TPoint;
    FTopLeft    : TPoint;
    FBorderStyle: TBorderStyle;
    FReadOnly   : Boolean;
    FTM         : TTextMetric;
    FThumbTracking : boolean;
    FLines      : TLines;
    Lang        : TLang;
    PageLines   : integer;
    PageChars   : integer;
    LineHeight  : integer;
    FNumberCol  : boolean;
    FNumberWidth: integer;
    OldSel      : HRGN;
    CaretHidden : boolean;
    Courier    : TFont;
    UseFont    : TUseFont;
    FOnCurrentChanged : TNotifyEvent;
    FOnTopLeftChanged : TNotifyEvent;
    FOnChange         : TNotifyEvent;
    Hist : THistList;
    DataChanged : boolean;
    Modified  : boolean;
    MousePos  : integer;
    CurrTok : PToken;
    MoveForw  : boolean;
    Info : TSourceInfo;
    OwnInfo   : boolean;
    procedure CancelMode;
    procedure ClampInView(const Point: TPoint);
    procedure ModifyScrollBar(ScrollBar, ScrollCode, Pos: Cardinal;
      UseRightToLeft: Boolean);
    procedure MoveAnchor(const NewAnchor: TPoint);
    procedure MoveCurrent(ACurrent: TPoint; MoveAnchor, Show : Boolean);
    procedure SelectionMoved;
    procedure MoveTopLeft(NewTopLeft : TPoint);
    procedure TopLeftMoved(const OldTopLeft : TPoint);
    procedure UpdateScrollPos;
    procedure UpdateScrollRange;
    function  GetSelection: HRGN;
    function  IsActiveControl: Boolean;
    procedure SetBorderStyle(Value: TBorderStyle);
    procedure CMCancelMode(var Msg: TMessage); message CM_CANCELMODE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMCtl3DChanged(var Message: TMessage); message CM_CTL3DCHANGED;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure WMCancelMode(var Msg: TWMCancelMode); message WM_CANCELMODE;
    procedure WMGetDlgCode(var Msg: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure WMTimer(var Msg: TWMTimer); message WM_TIMER;
    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure SetCurrent(const Value: TPoint);
    procedure SetTopLeft(const Value: TPoint);
    function  GetSelLength: integer;
    function  GetSelStart: integer;
    function  EndPoint: TPoint;
    function  StartPoint: TPoint;
    procedure SetSelLength(const Value: integer);
    procedure SetSelStart(const Value: integer);
    function  PointByPos(const Pos: integer) : TPoint;
  protected
    WasModified : boolean;
    FInUpdate   : boolean;
    FEditing    : boolean;
    OverWrite   : boolean;
    WasSelLen   : integer;
    WasSelStart : integer;
    procedure DoEdit(aMsg : DWORD; const aNew : string; aPos : DWORD = 0; const aOld : string = '');
    function  GetFile(Str : TMemoryStream) : boolean;
    function  GetPos(X, Y : integer) : TPoint;
    procedure CopySelection;
    procedure ResetCaret;
    procedure ChangeOrientation(RightToLeftOrientation: Boolean);
    procedure Resize; override;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMSetFocus); message WM_KILLFOCUS;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure DoExit; override;
    function  DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    function  DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    procedure ScrollData(DX, DY: Integer);
    procedure TimedScroll(Direction: TScrollDirection); dynamic;
    procedure Paint; override;
    procedure SetCanvasFont;
    procedure PriorWord(var NewCurrent : TPoint); virtual;
    procedure NextWord(var NewCurrent : TPoint); virtual;
    procedure CurrentChanged; virtual;
    procedure TopLeftChanged; virtual;
    procedure DoSynchronize; virtual;
    function  TokenByPos : PToken;
    procedure FontChanged(AFont : TFont);
    procedure InvalidateLines(FromInd, ToInd : integer);
    procedure Apply;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property Color default clBlack;
    property ParentColor default False;
    property Selection : HRGN read GetSelection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function  RangeText(Up, Dn : TPoint) : string;
    function  SelText : string;
    procedure Undo(RealUndo : boolean);
    function  LoadFile(AInfo : TSourceInfo) : boolean;
    function  FindLang(const Ext : string) : TLang; virtual;
    procedure Change; virtual;
    procedure SetLang;
    procedure OpenFile(FileName : string);
    procedure SaveToFile;
    function  CloseFile : boolean;
    function  CanClose : Boolean;
    property SelStart  : integer read GetSelStart write SetSelStart;
    property SelLength : integer read GetSelLength write SetSelLength;
    property Lines : TLines read FLines;
    property Font;
    property TabStop default True;
    property NumberCol : boolean read FNumberCol write FNumberCol default True;
    property Current : TPoint read FCurrent write SetCurrent;
    property TopLeft : TPoint read FTopLeft write SetTopLeft;
    property OnCurrentChanged : TNotifyEvent read FOnCurrentChanged write FOnCurrentChanged;
    property OnTopLeftChanged : TNotifyEvent read FOnTopLeftChanged write FOnTopLeftChanged;
    property OnChange : TNotifyEvent read FOnChange write FOnChange;
  end;

  TTextViewer = class(TCustomTextViewer)
    published
    property Align;
    property Anchors;
    property BevelEdges;
    property BevelInner;
    property BevelKind default bkNone;
    property BevelOuter;
    property BiDiMode;
    property BorderStyle;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ImeMode;
    property ImeName;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnCurrentChanged;
    property OnTopLeftChanged;
    property NumberCol;
  end;

  TLog = procedure (S : string);

procedure Register;

var
  Log : TLog = nil;

implementation

uses TextFind;

procedure LogRect(Hd : string; R : PRect);
begin
  if @Log = nil then
    Exit;
  if Hd <> '' then
    Log('< ' + Hd + ' >');
   Log(IntToStr(R.Left) + ',' + IntToStr(R.Top) + ',' + IntToStr(R.Right) + ',' + IntToStr(R.Bottom));
end;

procedure LogRgn(Hd : string; Rgn : HRGN);
var Data : PRgnData;
    Rect : PRect;
    I, Count : integer;
begin
  if @Log = nil then
    Exit;
  Log('--- ' + Hd + ' ---');
  Count := GetRegionData(Rgn, 0, nil);
  GetMem(Data, Count);
  try
    GetRegionData(Rgn, Count, Data);
    with Data^ do
    begin
      Rect := @buffer;
      for I := 0 to rdh.nCount - 1 do
      begin
        LogRect('', Rect);
        Rect := Pointer(Integer(Rect) + SizeOf(TRect));
      end;
    end;
  finally
    FreeMem(Data);
  end;
end;

{ TCustomTextViewer }

constructor TCustomTextViewer.Create(AOwner: TComponent);
const
  vStyle = [csCaptureMouse, csOpaque, csDoubleClicks];
begin
  inherited Create(AOwner);
  if NewStyleControls then
    ControlStyle := vStyle
  else
    ControlStyle := vStyle + [csFramed];
  DoubleBuffered := True;
  FReadOnly    := False;
  FNumberCol   := True;
  FBorderStyle := bsSingle;
  Color        := clBlack;
  ParentColor  := False;
  TabStop      := True;
  FThumbTracking:= True;
  FTopLeft.X := 0;
  FTopLeft.Y := 0;
  FCurrent := FTopLeft;
  FAnchor  := FCurrent;
  SetBounds(Left, Top, 300, 300);
  FLines  := TLines.Create;
  Hist := THistList.Create;

  Courier := TFont.Create;
  Courier.Name := 'Courier New';
  Courier.Color:= clWhite;
  Courier.Size := 13;
end;


procedure TCustomTextViewer.ResetCaret;
var CaretPos : TPoint;
    NewCaret : TPoint;
begin
  if FReadOnly then
    Exit;
  NewCaret.X := (FCurrent.X - FTopLeft.X) * FTM.tmAveCharWidth;
  NewCaret.Y := (FCurrent.Y - FTopLeft.Y) * LineHeight;
  if PtInRect(ClientRect, NewCaret) then
  begin
    Inc(NewCaret.X, FNumberWidth);
    if CaretHidden then
      ShowCaret(Handle);
    CaretPos.X := -1;
    GetCaretPos(CaretPos);
    if (NewCaret.X <> CaretPos.X) or (NewCaret.Y <> CaretPos.Y) then
      SetCaretPos(NewCaret.X, NewCaret.Y);
    CaretHidden := False;
  end else
  begin
    if not CaretHidden then
      HideCaret(Handle);
    CaretHidden := True;
  end;
end;

procedure TCustomTextViewer.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  if not FReadOnly then
  begin
    CreateCaret(Handle, 0, 2, FTM.tmHeight);
    CaretHidden := True;
    ResetCaret;
  end
end;

procedure TCustomTextViewer.WMKillFocus(var Message: TWMSetFocus);
begin
  inherited;
  if not FReadOnly then
    DestroyCaret;
end;

destructor TCustomTextViewer.Destroy;
begin
  Courier.Free;
  FLines.Free;
  Hist.Free;
  inherited Destroy;
end;

procedure TCustomTextViewer.DoExit;
begin
  inherited DoExit;
end;

function TCustomTextViewer.IsActiveControl: Boolean;
var
  H: Hwnd;
  ParentForm: TCustomForm;
begin
  Result := False;
  ParentForm := GetParentForm(Self);
  if Assigned(ParentForm) then
  begin
    if (ParentForm.ActiveControl = Self) then
      Result := True
  end
  else
  begin
    H := GetFocus;
    while IsWindow(H) and (Result = False) do
    begin
      if H = WindowHandle then
        Result := True
      else
        H := GetParent(H);
    end;
  end;
end;

procedure TCustomTextViewer.FontChanged(AFont : TFont);
var
  DC : HDC;
  SaveFont: HFont;
  I : Integer;
  SysMetrics : TTextMetric;
begin
  DC := GetDC(0);
  GetTextMetrics(DC, SysMetrics);
  SaveFont := SelectObject(DC, AFont.Handle);
  GetTextMetrics(DC, FTM);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
  I := SysMetrics.tmHeight;
  if I > FTM.tmHeight then
    I := FTM.tmHeight;
  LineHeight := FTM.tmHeight + I div 8;
  PageLines := ClientHeight div LineHeight;
  FNumberWidth := 0;
  if NumberCol then
    FNumberWidth := 4 * FTM.tmAveCharWidth + 3;
  PageChars := (ClientWidth - FNumberWidth) div FTM.tmAveCharWidth;
  UseFont   := ufCheck;
end;

procedure TCustomTextViewer.CMFontChanged(var Message: TMessage);
begin
  FontChanged(Font);
  inherited;
end;

procedure TCustomTextViewer.SetCanvasFont;
begin
  if UseFont = ufCheck then
  begin
    if Font.Pitch <> fpFixed{FTM.tmPitchAndFamily and $F <> FIXED_PITCH} then
    begin
      Courier.Size := Font.Size;
      Courier.Color:= Font.Color;
      FontChanged(Courier);
      UseFont := ufCourier;
    end else
      UseFont := ufOwn;
  end;
  if UseFont = ufCourier then
    Canvas.Font := Courier
  else
    Canvas.Font := Font;
end;

procedure TCustomTextViewer.Paint;
var
  I, X, Y : integer;
  S : string;
  R : TRect;
  EOL : boolean;
  SaveColor : TColor;
  LnToken : PToken;
  Style : TFontStyles;
  NewSel, Tmp : HRGN;
begin
  if UseRightToLeftAlignment then ChangeOrientation(True);
  with Canvas do
  begin
    SetCanvasFont;
    NewSel := Selection;
    R := ClientRect;
    if FNumberWidth > 0 then
    begin
      SaveColor := Font.Color;
      R.Right := FNumberWidth;
      Brush.Color := clSilver;
      FillRect(R);
      DrawEdge(Handle, R, BDR_RAISEDINNER, BF_RIGHT);
      Tmp := CreateRectRgnIndirect(R);
      CombineRgn(NewSel, NewSel, Tmp, RGN_DIFF);
      DeleteObject(Tmp);
      R.Left := FNumberWidth;
      R.Right:= ClientWidth;
      Font.Color := clBlack;
      for I := FTopLeft.Y to FTopLeft.Y + PageLines - 1 do
        if (I >= 0) and (I < Lines.Count) then
        begin
          S := IntToStr(I);
          TextOut((4 - Length(S)) * FTM.tmAveCharWidth, (I - FTopLeft.Y) * LineHeight, S);
        end;
      Font.Color := SaveColor;
    end;
    Brush.Color := Color;
    FillRect(R);
    for I := FTopLeft.Y to FTopLeft.Y + PageLines - 1 do
      if (I >= 0) and (I < Lines.Count) then
      begin
        LnToken := Lines.TopLines[ I ];
        if LnToken = nil then
          Continue;
        X := FNumberWidth;
        Y := (I - FTopLeft.Y) * LineHeight;
        repeat
          S := Copy(Lines.S, LnToken.Pos, LnToken.Size);
//          if Pos(#13, S) <> 0 then
//            S := S;
          EOL := LnToken.Last;
          with Lang.TxtDefs[ LnToken.Def ] do
          begin
            if Font.Color <> Color then
              Font.Color := Color;
            Style := [];
            if Bold then
              Include(Style, fsBold);
            if Italic then
              Include(Style, fsItalic);
            if LnToken.State = tsDeleted then
              Include(Style, fsStrikeOut);
            if LnToken.State = tsAdded then
              Include(Style, fsUnderline);
            if Font.Style <> Style then
              Font.Style := Style;
            TextOut(X, Y, S);
          end;
          Inc(X, LnToken.Size * FTM.tmAveCharWidth);
          LnToken := LnToken.Next;
        until EOL or (LnToken = nil) or (X > ClientWidth);
      end;
    InvertRgn(Handle, NewSel);
    DeleteObject(NewSel);
  end;
  if UseRightToLeftAlignment then ChangeOrientation(False);
end;

procedure TCustomTextViewer.ChangeOrientation(RightToLeftOrientation: Boolean);
var
  Org : TPoint;
  Ext : TPoint;
begin
  if RightToLeftOrientation then
  begin
    Org := Point(ClientWidth, 0);
    Ext := Point(-1, 1);
  end else
  begin
    Org := Point(0,0);
    Ext := Point(1,1);
  end;
  SetMapMode(Canvas.Handle, mm_Anisotropic);
  SetWindowOrgEx(Canvas.Handle, Org.X, Org.Y, nil);
  SetViewportExtEx(Canvas.Handle, ClientWidth, ClientHeight, nil);
  SetWindowExtEx(Canvas.Handle, Ext.X * ClientWidth, Ext.Y * ClientHeight, nil);
end;

procedure TCustomTextViewer.ClampInView(const Point: TPoint);
var OldTopLeft : TPoint;
begin
  if not HandleAllocated then
    Exit;
  with Point do
  begin
    if (X >= FTopLeft.X + PageChars) or
      (Y >= FTopLeft.Y + PageLines) or (X < FTopLeft.X) or (Y < FTopLeft.Y) then
    begin
      OldTopLeft := FTopLeft;
      Update;
      if X < FTopLeft.X then
        FTopLeft.X := X
      else if X >= FTopLeft.X + PageChars then
        FTopLeft.X := X - PageChars + 1;
      if Y < FTopLeft.Y then
        FTopLeft.Y := Y
      else if Y >= FTopLeft.Y + PageLines then
        FTopLeft.Y := Y - PageLines + 1;
      TopLeftMoved(OldTopLeft);
    end;
  end;
end;

function LongMulDiv(Mult1, Mult2, Div1: Longint): Longint; stdcall;
{$IFDEF LINUX}
  external 'libwine.borland.so' name 'MulDiv';
{$ENDIF}
{$IFDEF MSWINDOWS}
  external 'kernel32.dll' name 'MulDiv';
{$ENDIF}

procedure TCustomTextViewer.ModifyScrollBar(ScrollBar, ScrollCode, Pos: Cardinal;
  UseRightToLeft: Boolean);
var
  RTLFactor: Integer;

  function Min: Longint;
  begin
    Result := 0;
  end;

  function Max: Longint;
  begin
    if ScrollBar = SB_HORZ then Result := MaxLineLen
    else Result := Lines.Count;
  end;

  function PageUp: Longint;
  begin
    if ScrollBar = SB_HORZ then
      Result := -PageChars else
      Result := -PageLines;
    if Result < 1 then Result := 1;
  end;

  function PageDown: Longint;
  begin
    if ScrollBar = SB_HORZ then
      Result := PageChars
    else
      Result := PageLines;
  end;

  function CalcScrollBar(Value, ARTLFactor: Longint): Longint;
  begin
    Result := Value;
    case ScrollCode of
      SB_LINEUP:
        Dec(Result, ARTLFactor);
      SB_LINEDOWN:
        Inc(Result, ARTLFactor);
      SB_PAGEUP:
        Dec(Result, PageUp * ARTLFactor);
      SB_PAGEDOWN:
        Inc(Result, PageDown * ARTLFactor);
      SB_THUMBPOSITION, SB_THUMBTRACK:
        if FThumbTracking or (ScrollCode = SB_THUMBPOSITION) then
        begin
          if (not UseRightToLeftAlignment) or (ARTLFactor = 1) then
            Result := Min + LongMulDiv(Pos, Max - Min, MaxShortInt)
          else
            Result := Max - LongMulDiv(Pos, Max - Min, MaxShortInt);
        end;
      SB_BOTTOM:
        Result := Max;
      SB_TOP:
        Result := Min;
    end;
  end;

var
  NewTopLeft : TPoint;
begin
  if (not UseRightToLeftAlignment) or (not UseRightToLeft) then
    RTLFactor := 1
  else
    RTLFactor := -1;
  if Visible and CanFocus and TabStop and not (csDesigning in ComponentState) then
    SetFocus;
  NewTopLeft := FTopLeft;
  if ScrollBar = SB_HORZ then
    NewTopLeft.X := CalcScrollBar(NewTopLeft.X, RTLFactor)
  else
    NewTopLeft.Y := CalcScrollBar(NewTopLeft.Y, 1);
  NewTopLeft.X := Math.Max(0, Math.Min(MaxLineLen - 1, NewTopLeft.X));
  NewTopLeft.Y := Math.Max(0, Math.Min(Lines.Count - 1, NewTopLeft.Y));
  if (NewTopLeft.X <> FTopLeft.X) or (NewTopLeft.Y <> FTopLeft.Y) then
    MoveTopLeft(NewTopLeft);
end;

procedure TCustomTextViewer.MoveAnchor(const NewAnchor: TPoint);
begin
  OldSel  := Selection;
  FAnchor := NewAnchor;
  ClampInView(NewAnchor);
  SelectionMoved;
end;

procedure TCustomTextViewer.MoveCurrent(ACurrent: TPoint; MoveAnchor, Show : Boolean);
begin
  OldSel   := Selection;
  FCurrent := ACurrent;
  if MoveAnchor then
    FAnchor := FCurrent;
  if Show then
    ClampInView(FCurrent);
  SelectionMoved;
  ResetCaret;
  CurrentChanged;
end;

procedure TCustomTextViewer.MoveTopLeft(NewTopLeft : TPoint);
var
  OldTopLeft : TPoint;
begin
  if (NewTopLeft.X = FTopLeft.X) and (NewTopLeft.Y = FTopLeft.Y) then
    Exit;
  Update;
  OldTopLeft := FTopLeft;
  FTopLeft   := NewTopLeft;
  TopLeftMoved(OldTopLeft);
  TopLeftChanged;
end;

function TCustomTextViewer.GetSelection: HRGN;
var Up, Dn : TPoint;
    Tmp : HRGN;
    R   : TRect;
    UpLen, DnLen, DnX, UpX : integer;
begin
  Up := StartPoint;
  Dn := EndPoint;
  UpLen := Lines.LineLen(Up.Y);
  if (Up.Y = Dn.Y) and ((Up.X = Dn.X) or (Up.X >= UpLen)) then
    Result := 0
  else
  begin
    DnLen := Lines.LineLen(Dn.Y);
    if Dn.X >= DnLen then
      DnX := DnLen
    else
      DnX := Dn.X;
    if Up.X >= UpLen then
      UpX := UpLen
    else
      UpX := Up.X;
    R.Left   := FNumberWidth + (UpX - FTopLeft.X) * FTM.tmAveCharWidth;
    R.Top    := (Up.Y - FTopLeft.Y) * LineHeight;
    R.Bottom := R.Top + LineHeight;
    if Dn.Y = Up.Y then
    begin
      R.Right := FNumberWidth + (DnX - FTopLeft.X) * FTM.tmAveCharWidth;
      Result  := CreateRectRgnIndirect(R);
    end else
    begin
      R.Right := FNumberWidth + MaxLineLen * FTM.tmAveCharWidth;
      Result  := CreateRectRgnIndirect(R);
      R.Left  := FNumberWidth - FTopLeft.X * FTM.tmAveCharWidth;
      R.Top   := (Dn.Y - FTopLeft.Y) * LineHeight;
      R.Bottom:= R.Top + LineHeight;
      R.Right := FNumberWidth + (DnX - FTopLeft.X) * FTM.tmAveCharWidth;
      Tmp := CreateRectRgnIndirect(R);
      CombineRgn(Result, Result, Tmp, RGN_OR);
      DeleteObject(Tmp);
      if Dn.Y > Up.Y + 1 then
      begin
        R.Top   := (Up.Y + 1 - FTopLeft.Y) * LineHeight;
        R.Bottom:= (Dn.Y  - FTopLeft.Y) * LineHeight;
        R.Left  := FNumberWidth - FTopLeft.X * FTM.tmAveCharWidth;
        R.Right := R.Left + FNumberWidth + MaxLineLen * FTM.tmAveCharWidth;
        Tmp := CreateRectRgnIndirect(R);
        CombineRgn(Result, Result, Tmp, RGN_OR);
        DeleteObject(Tmp);
      end;
    end;
  end;
end;

function TCustomTextViewer.SelText : string;
begin
  Result := RangeText(StartPoint, EndPoint);
end;

function TCustomTextViewer.RangeText(Up, Dn : TPoint) : string;
var Ind, Len, I : integer;
    S : string;
begin
  S := '';
  if (Up.X <> Dn.X) or (Up.Y <> Dn.Y) then
  begin
    Ind  := Up.X;
    if Dn.Y = Up.Y then
    begin
      Len := Dn.X - Up.X;
      S := Copy(Lines[ Up.Y ], Ind + 1, Len);
    end else
    begin
      S := Copy(Lines[ Up.Y ], Ind + 1, MaxInt) + #13#10;
      if Dn.Y > Up.Y + 1 then
      begin
        I := Up.Y + 1;
        while I < Dn.Y do
        begin
          S := S + Lines[ I ] + #13#10;
          Inc(I);
        end;
      end;
      S := S + Copy(Lines[ Dn.Y ], 1, Dn.X);
    end;
  end;
  Result := S;
end;

procedure TCustomTextViewer.CopySelection;
begin
  Clipboard.AsText := SelText;
end;

procedure TCustomTextViewer.SelectionMoved;
var NewSel : HRGN;
begin
  if not HandleAllocated then
    Exit;
  NewSel := Selection;
  if OldSel <> 0 then
  begin
//    LogRgn('old', oldsel);
    if NewSel <> 0 then
    begin
//      LogRgn('new', NewSel);
      CombineRgn(OldSel, OldSel, NewSel, RGN_XOR);
//      LogRgn('xor', oldSel);
    end;
    InvalidateRgn(Handle, OldSel, False);
    DeleteObject(OldSel);
  end else if NewSel <> 0 then
    InvalidateRgn(Handle, NewSel, False);
  DeleteObject(NewSel);
end;

procedure TCustomTextViewer.ScrollData(DX, DY: Integer);
var R : TRect;
begin
  DX := DX * FTM.tmAveCharWidth;
  DY := DY * LineHeight;
  R := Rect(FNumberWidth, 0, ClientWidth, PageLines * LineHeight);
  ScrollWindowEx(Handle, DX, DY, @R, @R, 0, nil, SW_INVALIDATE);
  if (FNumberWidth > 0) and (DY <> 0) then
  begin
    R := Rect(0, 0, FNumberWidth, PageLines * LineHeight);
    ScrollWindowEx(Handle, 0, DY, @R, @R, 0, nil, SW_INVALIDATE);
  end;
  if OldSel <> 0 then
    OffsetRgn(OldSel, DX, DY);
  R := Rect(0, PageLines * LineHeight, ClientWidth, ClientHeight);
  InvalidateRect(Handle, @R, False);
end;

procedure TCustomTextViewer.TopLeftMoved(const OldTopLeft : TPoint);
begin
  UpdateScrollPos;
  ScrollData(OldTopLeft.X - FTopLeft.X, OldTopLeft.Y - FTopLeft.Y);
  ResetCaret;
end;

procedure TCustomTextViewer.UpdateScrollPos;

  procedure SetScroll(Code: Word; Value: Integer);
  begin
    if UseRightToLeftAlignment and (Code = SB_HORZ) then
      Value := MaxShortInt - Value;
    if GetScrollPos(Handle, Code) <> Value then
      SetScrollPos(Handle, Code, Value, True);
  end;

begin
  if (not HandleAllocated) then
    Exit;
  SetScroll(SB_HORZ, LongMulDiv(FTopLeft.X, MaxShortInt, MaxLineLen - 1));
  SetScroll(SB_VERT, LongMulDiv(FTopLeft.Y, MaxShortInt, Lines.Count - 1));
end;

procedure TCustomTextViewer.UpdateScrollRange;
var
  OldTopLeft : TPoint;
  Updated    : boolean;

  procedure SetAxisRange(Max, Old : integer; var  Current: Longint; Code: Word);
  begin
    SetScrollRange(Handle, Code, 0, MaxShortInt, True);
    if Old > Max then
    begin
      if not Updated then
      begin
        Update;
        Updated := True;
      end;
      Current := Max;
    end;
  end;

begin
  if not HandleAllocated or not Showing then
    Exit;
  OldTopLeft := FTopLeft;
  Updated := False;
  SetAxisRange(MaxLineLen - 1, OldTopLeft.X, FTopLeft.X, SB_HORZ);
  SetAxisRange(Lines.Count - 1, OldTopLeft.Y, FTopLeft.Y, SB_VERT);
  UpdateScrollPos;
  if (FTopLeft.X <> OldTopLeft.X) or (FTopLeft.Y <> OldTopLeft.Y) then
    TopLeftMoved(OldTopLeft);
end;

procedure TCustomTextViewer.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
  begin
//    Style := Style or WS_TABSTOP;
    Style := Style or WS_VSCROLL or WS_HSCROLL;
    WindowClass.style := CS_DBLCLKS;
    if FBorderStyle = bsSingle then
      if NewStyleControls and Ctl3D then
      begin
        Style := Style and not WS_BORDER;
        ExStyle := ExStyle or WS_EX_CLIENTEDGE;
      end
      else
        Style := Style or WS_BORDER;
  end;
end;

procedure TCustomTextViewer.NextWord(var NewCurrent : TPoint);
var S : string;
    Len : integer;
    OldCurrent : TPoint;
begin
  OldCurrent := NewCurrent;
  S := Lines[ NewCurrent.Y ];
  Len := Length(S);
  while (NewCurrent.X < Len) and IsCharAlphaNumeric(S[ NewCurrent.X + 1]) do
    Inc(NewCurrent.X);
  repeat
    while (NewCurrent.X < Len) and not IsCharAlphaNumeric(S[ NewCurrent.X + 1]) do
      Inc(NewCurrent.X);
    if NewCurrent.X < Len then
      Exit;
    Inc(NewCurrent.Y);
    if NewCurrent.Y = Lines.Count then
      Break;
    S := Lines[ NewCurrent.Y ];
    Len := Length(S);
    NewCurrent.X := 0;
  until False;
  NewCurrent := OldCurrent;
end;

procedure TCustomTextViewer.PriorWord(var NewCurrent : TPoint);
var S : string;
    Len : integer;
    OldCurrent : TPoint;
    Found :  boolean;
begin
  OldCurrent := NewCurrent;
  Found := False;
  S := Lines[ NewCurrent.Y ];
  Len := Length(S);
  if NewCurrent.X >= Len then
    NewCurrent.X := Len - 1;
  repeat
    while (NewCurrent.X >= 0) and not IsCharAlphaNumeric(S[ NewCurrent.X + 1]) do
      Dec(NewCurrent.X);
    while (NewCurrent.X >= 0) and IsCharAlphaNumeric(S[ NewCurrent.X + 1]) do
    begin
      Dec(NewCurrent.X);
      Found := True;
    end;
    if Found then
    begin
      if (NewCurrent.X + 1 = OldCurrent.X) and (NewCurrent.Y = OldCurrent.Y) then
      begin
        Found := False;
        Continue;
      end;
      Inc(NewCurrent.X);
      Exit;
    end;
    Dec(NewCurrent.Y);
    if NewCurrent.Y = -1 then
      Break;
    S := Lines[ NewCurrent.Y ];
    Len := Length(S);
    NewCurrent.X := Len - 1;
  until False;
  NewCurrent := OldCurrent;
end;

function TCustomTextViewer.TokenByPos : PToken;
begin
  Result := nil;
  if Current.Y >= Lines.Count then
    Exit;
  Result := Lines.TopLines[ Current.Y ];
  if Result = nil then
    Exit;
  while Result.Pos + Result.Size < Current.X do
    Result := Result.Next;
end;

procedure TCustomTextViewer.DoSynchronize;
begin
  CurrTok := TokenByPos;
end;

procedure TCustomTextViewer.KeyPress(var Key: Char);
var OldChr : string;
    Len, Start  : integer;
begin
  case Key of
   #13,#10 :
     DoEdit(VK_PASTE, #13#10, SelStart, SelText);
   #127, #8 :;
    else if Key >= #32 then
    begin
      Len    := Lines.LineLen(Current.Y);
      Start  := SelStart;
      OldChr := Lines.S[ Start ];
      if SelLength <> 0 then
        DoEdit(VK_CHAR, Key, Start, SelText)
      else if Current.X <= Len then
        DoEdit(VK_CHAR, Key, Start, ifthen(OverWrite, OldChr, ''))
      else if Key <> ' ' then
        DoEdit(VK_PASTE, StringOfChar(' ', Current.X - Len) + Key, Start - Current.X + Len, '')
      else
        MoveCurrent(Point(Current.X + 1, Current.Y), True, True);
    end;
  end;
end;

procedure TCustomTextViewer.KeyUp(var Key: Word; Shift: TShiftState);
var Forw : boolean;
begin
  case Key of
  VK_PRIOR..VK_DOWN :
      begin
        Forw := Key in [VK_RIGHT, VK_DOWN, VK_NEXT, VK_END];
        DoSynchronize;
        if MoveForw <> Forw then
        begin
          DoEdit(VK_POS, '', SelStart, '');
          MoveForw := Forw;
        end;
      end;
  end;
end;

procedure TCustomTextViewer.KeyDown(var Key: Word; Shift: TShiftState);
var
  NewTopLeft, NewCurrent, MaxTopLeft: TPoint;
  RTLFactor : Integer;
  NeedsInvalidating : Boolean;
  Ch, Txt : string;
  I, Len, Start  : integer;
  IsAlpha : boolean;

  procedure Restrict(var Coord: TPoint; MaxX, MaxY: Longint);
  begin
    with Coord do
    begin
      if X > MaxX then
        X := MaxX
      else if X < 0 then
        X := 0;
      if Y > MaxY then
        Y := MaxY
      else if Y < 0 then
        Y := 0;
    end;
  end;

  procedure LineEnd(Line : integer);
  begin
    NewCurrent.X := Lines.LineLen(Line);
    NewCurrent.Y := Line;
  end;

begin
  inherited KeyDown(Key, Shift);
  NeedsInvalidating := False;
  if FReadOnly then
    Key := 0;
  if not UseRightToLeftAlignment then
    RTLFactor := 1
  else
    RTLFactor := -1;
  NewCurrent := FCurrent;
  NewTopLeft := FTopLeft;
  if ssCtrl in Shift then
    case Key of
      VK_UP  :
        Dec(NewTopLeft.Y);
      VK_DOWN:
        Inc(NewTopLeft.Y);
      VK_LEFT:
        if RTLFactor = 1 then
          PriorWord(NewCurrent)
        else
          NextWord(NewCurrent);
      VK_RIGHT:
        if RTLFactor = -1 then
          PriorWord(NewCurrent)
        else
          NextWord(NewCurrent);
      VK_PRIOR:
        NewCurrent.Y := FTopLeft.Y;
      VK_NEXT :
        NewCurrent.Y := FTopLeft.Y + PageLines - 1;
      VK_HOME :
        begin
          NewCurrent.X := 0;
          NewCurrent.Y := 0;
          NeedsInvalidating := UseRightToLeftAlignment;
        end;
      VK_END:
        begin
          LineEnd(Lines.Count - 1);
          NeedsInvalidating := UseRightToLeftAlignment;
        end;
      VK_F3    :
        begin
          Exclude(Options, soDown);
          FindNext(Self);
          Exit;
        end;
      Ord('C') :
        CopySelection;
      Ord('F') :
        begin
          Find(Self);
          Exit;
        end;
      Ord('Y') :
        begin
          MoveAnchor(Current);
          DoEdit(VK_DELETE, '', Lines.LinePos(Current.Y), Lines.Line[Current.Y] + #13#10);
        end;
      Ord('T') :
        begin
          Start := SelStart;
          I     := Start;
          Len   := Lines.LineLen(Current.Y) - Current.X;
          Ch    := Lines.S[ I ];
          if Ch = #13 then
            DoEdit(VK_DELETE, '', Start, #13#10)
          else
          begin
            IsAlpha := IsCharAlphaNumeric(Ch[ 1 ]);
            while (Len > 0) and (Lines.S[ I ] <> #13) and IsAlpha xor not IsCharAlphaNumeric(Lines.S[ I ]) do
            begin
              Inc(I);
              Dec(Len);
            end;
            Ch := Copy(Lines.S, Start, I - Start);
            DoEdit(VK_DELETE, '', Start, Ch);
          end;
        end;
      VK_BACK :
          if SelStart = 0 then
            Key := 0
          else
          begin
            I  := SelStart;
            Ch := Lines.S[ I ];
            IsAlpha := IsCharAlphaNumeric(Ch[ 1 ]);
            while (I > 0) and IsAlpha xor not IsCharAlphaNumeric(Lines.S[ I ]) do
              Dec(I);
            Ch := Copy(Lines.S, I + 1, SelStart - I);
            DoEdit(VK_DELETE, '', I, Ch);
          end;
      Ord('L') :
        begin
          Include(Options, soDown);
          FindNext(Self);
          Exit;
        end;
     VK_F4 :
       CloseFile;
     Ord('Z') :
       begin
         Undo(False);
         Exit;
       end;
     Ord('X') :
       begin
         Txt := SelText;
         if Txt <> '' then
         begin
           CopySelection;
           DoEdit(VK_DELETE, '', SelStart, Txt);
         end;
       end;
     Ord('V') :
       begin
         Txt := SelText;
         if (Clipboard.AsText = Txt) then
         begin
           SelLength := 0;
           Key := 0;
         end else
           DoEdit(VK_PASTE, Clipboard.AsText, SelStart, Txt);
         Exit;
       end;
    end
  else
    case Key of
      VK_UP   :
        Dec(NewCurrent.Y);
      VK_DOWN :
        Inc(NewCurrent.Y);
      VK_LEFT :
        Dec(NewCurrent.X, RTLFactor);
      VK_RIGHT:
        Inc(NewCurrent.X, RTLFactor);
      VK_NEXT :
        begin
          Inc(NewCurrent.Y, PageLines);
          Inc(NewTopLeft.Y, PageLines);
        end;
      VK_PRIOR:
        begin
          Dec(NewCurrent.Y, PageLines);
          Dec(NewTopLeft.Y, PageLines);
        end;
      VK_HOME:
        NewCurrent.X := 0;
      VK_END :
        LineEnd(NewCurrent.Y);
      VK_F3  :
        begin
          Include(Options, soDown);
          FindNext(Self);
          Exit;
        end;
      VK_TAB :
        begin
          Len  := Lines.LineLen(Current.Y);
          if Current.X <= Len then
            DoEdit(VK_PASTE, '      ', SelStart, '')
          else
            MoveCurrent(Point(Current.X + 6, Current.Y), True, True);
        end;
      VK_DELETE :
         if Shift <> [] then
           Key := 0
         else
         begin
           if SelLength = 0 then
           begin
             Ch   := Lines.S[ SelStart ];
             Len  := Lines.LineLen(Current.Y);
             Start:= SelStart;
             if Current.X <= Len then
               DoEdit(Key, '', Start, Ch)
             else
             begin
               Ch := #13#10;
               DoEdit(VK_PASTE, StringOfChar(' ', Current.X - Len), Start - Current.X + Len, Ch);
             end;
           end else
             DoEdit(Key, '', SelStart, SelText);
          end;
       VK_BACK :
          begin
            Start := SelStart;
            if Start = 0 then
              Key := 0
            else
            begin
              Ch := Lines.S[ Start - 1 ];
              if Ch[ 1 ] = #10 then
                Ch := #13#10;
              DoEdit(VK_BACK, '', Start - 2, Ch);
            end;
          end;
       VK_INSERT :
          if Shift = [] then
            OverWrite := not OverWrite;
    end;
  MaxTopLeft.X := MaxLineLen - 1;
  MaxTopLeft.Y := Lines.Count - 1;
  Restrict(NewTopLeft, MaxTopLeft.X, MaxTopLeft.Y);
  if (NewTopLeft.X <> FTopLeft.X) or (NewTopLeft.Y <> FTopLeft.Y) then
    MoveTopLeft(NewTopLeft);
  Restrict(NewCurrent, MaxTopLeft.X, MaxTopLeft.Y);
  if (NewCurrent.X <> FCurrent.X) or (NewCurrent.Y <> FCurrent.Y) then
    MoveCurrent(NewCurrent, not (ssShift in Shift), True);
  if NeedsInvalidating then
    Invalidate;
end;

procedure TCustomTextViewer.InvalidateLines(FromInd, ToInd : integer);
var R : TRect;
begin
  R.Left   := 0;
  R.Right  := ClientWidth;
  R.Top    := (FromInd - FTopLeft.Y) * LineHeight;
  if ToInd = -1 then
    R.Bottom := ClientHeight
  else
    R.Bottom := R.Top + (ToInd - FromInd + 1) * LineHeight;
  InvalidateRect(Handle, @R, False);
end;

procedure TCustomTextViewer.Undo(RealUndo : boolean);
var Hst, PH : PHistRec;
    I, tPos : integer;
    Ovr : boolean;
    tMsg: DWORD;
    OnlyPos, SameLines : boolean;
    pStart, pEnd  : TPoint;
    nLines : integer;
    SL : string;
begin
  if RealUndo then
     while (Hist.Count > 0) and (PHistRec(Hist.Last)^.Msg = VK_POS) do
       Hist.DeleteLast;
  if Hist.Count = 0 then
  begin
    SelLength := 0;
    SelStart  := 1;
    Exit;
  end;
  Hst := PHistRec(Hist.Last);
  with Hst^ do
  begin
    if Msg = VK_POS then
    begin
      SelLength := 0;
      SelStart  := Pos;
    end else
    begin
      if Msg in [VK_CHAR, VK_DELETE, VK_BACK] then
      begin
        tMsg := Msg;
        tPos := Hst.Pos ;
        if tMsg = VK_BACK then
          Inc(tPos)
        else if tMsg = VK_CHAR then
          Dec(tPos);
        Ovr  := Hst.Over;
        I    := Hist.Count - 2;
        while (I >= 0) do
        begin
          PH := Hist[ I ];
          if (PH.Msg = tMsg) and (PH.Pos = tPos) and (PH.Over = Ovr) then
          begin
            if tMsg = VK_BACK then
            begin
              Hst.New := Hst.New + PH.New;
              Hst.Old := Hst.Old + PH.Old;
            end else
            begin
              Hst.New := PH.New + Hst.New;
              Hst.Old := PH.Old + Hst.Old;
            end;
            if tMsg = VK_CHAR then
              Hst.Pos := tPos;
            Dispose(PH);
            Hist.Delete(I);
            Dec(I);
            if tMsg = VK_BACK then
              Inc(tPos)
            else if tMsg = VK_CHAR then
              Dec(tPos);
          end else
            Break;
        end;
      end;
      pStart:= PointByPos(Pos);
      pEnd  := PointByPos(Pos + Length(New));
      SL    := RangeText(Point(0, pStart.Y), pStart) + Old +
               RangeText(pEnd, Point(MaxLineLen, pEnd.Y));
      nLines  := Lang.Rescan(Lines, pStart.Y, pEnd.Y - pStart.Y + 1, SL);
      Lines.S := StuffString(Lines.S, Pos, Length(New), Old);
      SameLines := pEnd.Y - pStart.Y + 1 = nLines;
      InvalidateLines(pStart.Y, ifthen(not Samelines, -1, pEnd.Y));
      pStart := PointByPos(Pos + Length(Old));
      MoveCurrent(pStart, True, True);
      if not SameLines then
        UpdateScrollRange;
      OverWrite := Over;
    end;
  end;
  Hist.DeleteLast;
  OnlyPos := True;
  for I := 0 to Hist.Count - 1 do
    if PHistRec(Hist[ I ]).Msg <> VK_POS then
    begin
      OnlyPos := False;
      Break;
    end;
  if OnlyPos then
    Modified := False;
  Change;
end;

procedure TCustomTextViewer.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TCustomTextViewer.GetPos(X, Y : integer) : TPoint;
begin
  Dec(X, FNumberWidth);
  if X < 0 then
    X := 0;
  Result.X := FTopLeft.X + Round(X / FTM.tmAveCharWidth);
  Result.Y := FTopLeft.Y + Round(Y / LineHeight);
end;

procedure TCustomTextViewer.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var CellHit : TPoint;
    NewSel : HRGN;
begin
  if not (csDesigning in ComponentState) and
    (CanFocus or (GetParentForm(Self) = nil)) then
  begin
    SetFocus;
    if not IsActiveControl then
    begin
      MouseCapture := False;
      Exit;
    end;
  end;
  if (Button = mbLeft) and (ssDouble in Shift) then
    DblClick
  else if Button = mbLeft then
  begin
    CellHit:= GetPos(X, Y);
    NewSel := Selection;
    if (NewSel <> 0) and not PtInRegion(NewSel, X, Y) then
    begin
      InvalidateRgn(Handle, NewSel, False);
      FAnchor := FCurrent;
    end;
    DeleteObject(NewSel);
    FSelecting := True;
    SetTimer(Handle, 1, 60, nil);
    if ssShift in Shift then
      MoveAnchor(CellHit)
    else
      MoveCurrent(CellHit, True, True);
  end;
  try
    inherited MouseDown(Button, Shift, X, Y);
  except
  end;
end;

procedure TCustomTextViewer.MouseMove(Shift: TShiftState; X, Y: Integer);
var CellHit : TPoint;
begin
  if FSelecting then
  begin
    CellHit := GetPos(X, Y);
    if (CellHit.X <> FAnchor.X) or (CellHit.Y <> FAnchor.Y) then
      MoveAnchor(CellHit);
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TCustomTextViewer.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  try
    if FSelecting then
    begin
      MouseMove(Shift, X, Y);
      KillTimer(Handle, 1);
      Click;
    end;
    DoSynchronize;
    inherited MouseUp(Button, Shift, X, Y);
    if MousePos <> -1 then
      DoEdit(VK_POS, '', MousePos, '');
    MousePos := SelStart;
  finally
    FSelecting := False;
  end;
end;

procedure TCustomTextViewer.SetBorderStyle(Value: TBorderStyle);
begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    RecreateWnd;
  end;
end;

procedure TCustomTextViewer.WMGetDlgCode(var Msg: TWMGetDlgCode);
begin
  Msg.Result := DLGC_WANTARROWS;
  if not FReadOnly then
    Msg.Result := Msg.Result or DLGC_WANTCHARS or DLGC_WANTTAB;
end;

procedure TCustomTextViewer.WMSize(var Msg: TWMSize);
begin
  inherited;
  UpdateScrollRange;
  if UseRightToLeftAlignment then
    Invalidate;
end;

procedure TCustomTextViewer.WMVScroll(var Msg: TWMVScroll);
begin
  ModifyScrollBar(SB_VERT, Msg.ScrollCode, Msg.Pos, True);
end;

procedure TCustomTextViewer.WMHScroll(var Msg: TWMHScroll);
begin
  ModifyScrollBar(SB_HORZ, Msg.ScrollCode, Msg.Pos, True);
end;

procedure TCustomTextViewer.CancelMode;
begin
  if FSelecting then
    KillTimer(Handle, 1);
  FSelecting := False;
end;

procedure TCustomTextViewer.WMCancelMode(var Msg: TWMCancelMode);
begin
  inherited;
  CancelMode;
end;

procedure TCustomTextViewer.CMCancelMode(var Msg: TMessage);
begin
  inherited;
  CancelMode;
end;

procedure TCustomTextViewer.CMCtl3DChanged(var Message: TMessage);
begin
  inherited;
  RecreateWnd;
end;

procedure TCustomTextViewer.TimedScroll(Direction: TScrollDirection);
var
  MaxAnchor, NewAnchor: TPoint;
begin
  NewAnchor := FAnchor;
  MaxAnchor.X := MaxLineLen - 1;
  MaxAnchor.Y := Lines.Count - 1;
  if (sdLeft in Direction) and (FAnchor.X > 0) then Dec(NewAnchor.X);
  if (sdRight in Direction) and (FAnchor.X < MaxAnchor.X) then Inc(NewAnchor.X);
  if (sdUp in Direction) and (FAnchor.Y > 0) then Dec(NewAnchor.Y);
  if (sdDown in Direction) and (FAnchor.Y < MaxAnchor.Y) then Inc(NewAnchor.Y);
  if (FAnchor.X <> NewAnchor.X) or (FAnchor.Y <> NewAnchor.Y) then
    MoveAnchor(NewAnchor);
end;

procedure TCustomTextViewer.WMTimer(var Msg: TWMTimer);
var
  Point : TPoint;
  ScrollDirection: TScrollDirection;
begin
  if not FSelecting then
    Exit;
  GetCursorPos(Point);
  Point := ScreenToClient(Point);
  ScrollDirection := [];
  if not UseRightToLeftAlignment then
  begin
    if Point.X < 0 then
      Include(ScrollDirection, sdLeft)
    else if Point.X > ClientWidth then
      Include(ScrollDirection, sdRight);
  end else
  begin
    if Point.X < 0 then
      Include(ScrollDirection, sdRight)
    else if Point.X > ClientWidth then
      Include(ScrollDirection, sdLeft);
  end;
  if Point.Y < 0 then
    Include(ScrollDirection, sdUp)
  else if Point.Y > ClientHeight then
    Include(ScrollDirection, sdDown);
  if ScrollDirection <> [] then
    TimedScroll(ScrollDirection);
end;

function TCustomTextViewer.DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheelDown(Shift, MousePos);
  if not Result then
  begin
    if TopLeft.Y < Lines.Count - 1 then
      MoveTopLeft(Point(TopLeft.X, TopLeft.Y + 1));
    Result := True;
  end;
end;

function TCustomTextViewer.DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheelUp(Shift, MousePos);
  if not Result and (TopLeft.Y > 0) then
  begin
    MoveTopLeft(Point(TopLeft.X, TopLeft.Y - 1));
    Result := True;
  end;
end;

procedure TCustomTextViewer.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  if Showing then
    UpdateScrollRange;
end;

procedure TCustomTextViewer.CurrentChanged;
begin
  if Assigned(FOnCurrentChanged) then
    FOnCurrentChanged(Self);
end;

procedure TCustomTextViewer.TopLeftChanged;
begin
  if Assigned(FOnTopLeftChanged) then
    FOnTopLeftChanged(Self);
end;

procedure TCustomTextViewer.Resize;
begin
  if LineHeight = 0 then
    Exit;
  PageLines := ClientHeight div LineHeight;
  PageChars := ClientWidth div FTM.tmAveCharWidth;
  inherited;
end;

procedure TCustomTextViewer.SetCurrent(const Value: TPoint);
begin
  if not PtInRect(Rect(0, 0, MaxLineLen, Lines.Count - 1), Value) then
    raise Exception.Create('Bad Current point');
  MoveCurrent(Value, True, True);
end;

procedure TCustomTextViewer.SetTopLeft(const Value: TPoint);
begin
  if not PtInRect(Rect(0, 0, MaxLineLen, Lines.Count - 1), Value) then
    raise Exception.Create('Bad TopLeft point');
  MoveTopLeft(Value);
end;

function TCustomTextViewer.GetSelLength: integer;
begin
  Result := Length(SelText);
end;

function TCustomTextViewer.StartPoint: TPoint;
begin
  if (FAnchor.Y < FCurrent.Y) or (FAnchor.Y = FCurrent.Y) and (FAnchor.X < FCurrent.X) then
    Result := FAnchor
  else
    Result := FCurrent;
end;

function TCustomTextViewer.EndPoint: TPoint;
begin
  if (FAnchor.Y < FCurrent.Y) or (FAnchor.Y = FCurrent.Y) and (FAnchor.X < FCurrent.X) then
    Result := FCurrent
  else
    Result := FAnchor;
end;

function TCustomTextViewer.GetSelStart: integer;
var Start : TPoint;
    Len, X : integer;
begin
  Start := StartPoint;
  Len := Lines.LineLen(Start.Y);
  if Start.X >= Len then
    X := Len
  else
    X := Start.X;
  Result := Lines.LinePos(Start.Y) + X;
end;

procedure TCustomTextViewer.SetSelLength(const Value: integer);
var Pos : integer;
begin
  if Value = 0 then
    MoveAnchor(Current)
  else
  begin
    Pos := SelStart + Value;
    if Pos > Length(Lines.S) then
      Pos := Length(Lines.S);
    MoveAnchor(PointByPos(Pos));
  end;
end;

function  TCustomTextViewer.PointByPos(const Pos: integer) : TPoint;
var I, L, Len : integer;
begin
  L := Pos - 1;
  for I := 0 to Lines.Count - 1 do
  begin
    Len  := Lines.LineLen(I) + 2;
    if L < Len then
    begin
      Result := Point(L, I);
      Exit;
    end else
      Dec(L, Len);
  end;
  I := Lines.Count - 1;
  Result := Point(Lines.LineLen(I), I);
end;

procedure TCustomTextViewer.SetSelStart(const Value: integer);
var Pos : integer;
begin
  Pos := Value;
  if Pos > Length(Lines.S) then
    Pos := Length(Lines.S);
  MoveCurrent(PointByPos(Pos), True, True);
end;

function TCustomTextViewer.CloseFile : boolean;
begin
  Result := CanClose;
  if not Result then
    Exit;
  Result := True;
  if Info = nil then
    Exit;
  if Info.Item <> nil then
    Info.Item.Enabled := True;
  Lines.Clear;
  if OwnInfo then
    Info.Free;
  Info := nil;
end;

function TCustomTextViewer.FindLang(const Ext : string) : TLang;
var L : integer;
begin
  for L := 0 to Langs.Count - 1 do
    if TLang(Langs[ L ]).HasExt(Ext) then
    begin
      Result := TLang(Langs[ L ]);
      Exit;
    end;
  Result := TLang(Langs.Last);
end;

procedure TCustomTextViewer.SetLang;
var Ext : string;
begin
  if Assigned(Lang) then
    Lang.Sources.Remove(Self);
  Ext  := FileExt(Info.FileName);
  Lang := FindLang(Ext);
  Lang.Activate;
  Lang.Sources.Add(Self);
end;

procedure TCustomTextViewer.OpenFile(FileName : string);
var AInfo : TSourceInfo;
begin
  OwnInfo := True;
  AInfo := TSourceInfo.Create;
  AInfo.FileName := FileName;
  LoadFile(AInfo);
end;

function AdjustLen(const Buf : Pointer; BufLen : integer; Style: TTextLineBreakStyle): integer;
var
  Source, SourceEnd : PChar;

  procedure DecEndSpaces;
  var P: PChar;
  begin
    P := Source - 1;
    while (P > Buf) and (P^ <= ' ') and not (P^ in [#13,#10]) do
    begin
      if P^ = #9 then
        Dec(Result, 6)
      else
        Dec(Result);
      Dec(P);
    end;
  end;

begin
  Source := Buf;
  SourceEnd := PChar(Buf) + BufLen;
  Result := BufLen;
  while Source < SourceEnd do
  begin
    case Source^ of
      #10:
        begin
          DecEndSpaces;
          if Style = tlbsCRLF then
            Inc(Result);
        end;
      #13:
        begin
          DecEndSpaces;
          if Style = tlbsCRLF then
            if Source[1] = #10 then
              Inc(Source)
            else
              Inc(Result)
          else
            if Source[1] = #10 then
              Dec(Result);
       end;
     #9 : Inc(Result, 5);
    else
      if Source^ in LeadBytes then
      begin
        Source := StrNextChar(Source);
        continue;
      end;
    end;
    Inc(Source);
  end;
  DecEndSpaces;
end;

function AdjustText(const Buf : Pointer; BufLen : integer; DestLen: integer; Style: TTextLineBreakStyle): string;
var
  Source, SourceEnd, Dest, DestEnd: PChar;
  L: Integer;

  procedure RollBackEndSpaces;
  var P: PChar;
  begin
    P := Source - 1;
    while (P > Buf) and (P^ <= ' ') and not (P^ in [#13,#10]) do
    begin
      Dec(Dest);
      Dec(P);
    end;
  end;

begin
  Source := Buf;
  SetString(Result , PChar(Buf), DestLen);
  Dest   := Pointer(Result);
  DestEnd:= Dest + DestLen;
  SourceEnd := PChar(Buf) + BufLen;
  while Source < SourceEnd do
  begin
    case Source^ of
      #10:
        begin
          RollBackEndSpaces;
          if Style = tlbsCRLF then
          begin
            Dest^ := #13;
            Inc(Dest);
          end;
          Dest^ := #10;
          Inc(Dest);
          Inc(Source);
        end;
      #13:
        begin
          RollBackEndSpaces;
          if Style = tlbsCRLF then
          begin
            Dest^ := #13;
            Inc(Dest);
          end;
          Dest^ := #10;
          Inc(Dest);
          Inc(Source);
          if Source^ = #10 then Inc(Source);
        end;
      #9 :
       begin
         L := 6;
         while L > 0 do
         begin
           Dest^ := ' ';
           Inc(Dest);
           Dec(L);
         end;
         Inc(Source);
       end;
    else
      if Source^ in LeadBytes then
      begin
        L := StrCharLength(Source);
        Move(Source^, Dest^, L);
        Inc(Dest, L);
        Inc(Source, L);
        continue;
      end;
      if Dest < DestEnd then
        Dest^ := Source^;
      Inc(Dest);
      Inc(Source);
    end;
  end;
end;

function TCustomTextViewer.LoadFile(AInfo : TSourceInfo) : boolean;
var S   : TMemoryStream;
    P   : PChar;
    Len, DestLen : integer;
    Str, Buf : string;
begin
  Result := False;
  if not CloseFile then
    Exit;
  Info := AInfo;
  MousePos := -1;
  MoveForw := True;
  S := TMemoryStream.Create;
  try
    Result := GetFile(S);
    if not Result then
    begin
      Info := nil;
      Exit;
    end;
    if Assigned(Info.Item) then
      Info.Item.Enabled := False;
    DataChanged := True;
    CurrTok := nil;
    P := PChar(S.Memory);
    Len := S.Size;
    Info.Unicode := IsTextUnicode(S.Memory, Len, nil);
    if Info.Unicode then
    begin
      if (P^ = Chr($FE)) and ((P + 1)^ = Chr($FF)) then
      begin
        Inc(P);
        Dec(Len, 2);
      end;
      Buf := WideCharLenToString(PWideChar(P), Len div 2);
      DestLen := AdjustLen(Pointer(Buf), Length(Buf), tlbsCRLF);
      if Len <> DestLen then
        Lines.S := AdjustText(Pointer(Buf), Length(Buf), DestLen, tlbsCRLF)
      else
        Lines.S := Buf;
    end else if (P^ = Chr($ef)) and ((P + 1)^ = Chr($bb)) and
                     ((P + 2)^ = Chr($bf)) then
    begin
      SetLength(Str, Len - 3);
      S.Position := 3;
      S.Read(Str[ 1 ], Len - 3);
      Buf := Utf8toAnsi(Str);
      DestLen := AdjustLen(Pointer(Buf), Length(Buf), tlbsCRLF);
      if Len <> DestLen then
        Lines.S := AdjustText(Pointer(Buf), Length(Buf), DestLen, tlbsCRLF)
      else
        Lines.S := Buf;
      Info.UTF8 := True;
    end else
    begin
      DestLen := AdjustLen(P, Len, tlbsCRLF);
      if Len <> DestLen then
        Lines.S := AdjustText(P, Len, DestLen, tlbsCRLF)
      else
        SetString(Lines.S, P, Len);
    end;
    SetLang;
    Lang.TokenList(Lines);
    Modified   := False;
  finally
    S.Free;
  end;
end;

function TCustomTextViewer.GetFile(Str : TMemoryStream) : boolean;
begin
  Result := True;
  try
    if Assigned(Info.OnGetFile) then
      Info.OnGetFile(Str, Info)
    else
    begin
      Str.LoadFromFile(Info.FileName);
      Info.FileDate := FileDate(Info.FileName);
    end;
  except
    on E:Exception do
    begin
      Result := False;
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
end;

function TCustomTextViewer.CanClose : Boolean;
begin
  Result := True;
  if (Info <> nil) and Modified then with Info  do
    case MessageDlg(FileName + ' changed, save ?', mtConfirmation, [ mbYes, mbNo, mbCancel], 0) of
     mrYes :
       SaveToFile;
     mrCancel :
       Result := False;
   end;
end;

type
  TMemStream = class(TMemoryStream);

procedure TCustomTextViewer.SaveToFile;
var Stream : TMemStream;
    Utf : UTF8String;
    Len : integer;
    Buffer: PWideChar;
begin
  if not Assigned(Info.OnPutFile) then
  begin
    with TSaveDialog.Create(nil) do
    try
      FileName := Info.FileName;
      if not Execute then
        Exit;
      Info.FileName := FileName;
    finally
      Free;
    end;
  end;
  try
    Buffer := nil;
    Stream := TMemStream.Create;
    try
      with Info do
      begin
        if Unicode then
        begin
          Len := Length(Lines.S);
          GetMem(Buffer, (Len + 1) * SizeOf(WideChar));
          StringToWideChar(Lines.S, Buffer, Len + 1);
          Len := 0;
          if Buffer <> nil then
            while Buffer[ Len ] <> #0 do
              Inc(Len);
          Stream.SetPointer(Buffer, Len * 2);
        end else if UTF8 then
        begin
          Utf := Chr($ef)+ Chr($bb) + Chr($bf) + AnsiToUtf8(Lines.S);
          Stream.Write(Utf[ 1 ], Length(Utf));
        end else
          Lines.SaveToStream(Stream);
      end;
      if Assigned(Info.OnPutFile) then
        Info.OnPutFile(Stream, Info)
      else
        Stream.SaveToFile(Info.FileName);
    finally
      if Buffer <> nil then
        FreeMem(Buffer);
      Stream.Free;
    end;
    Modified := False;
  except
    on E:Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TCustomTextViewer.Apply;
var OverChr : boolean;
    Hst    : PHistRec;
    nLines : integer;
    SL     : string;
    SameLines : boolean;
    pStart, pEnd : TPoint;
begin
  Hst := PHistRec(Hist.Last);
  with Hst^, Lines do
  begin
    pStart:= PointByPos(Pos);
    pEnd  := PointByPos(Pos + Length(Old));
    SL    := RangeText(Point(0, pStart.Y), pStart) + New
           + RangeText(pEnd, Point(MaxLineLen, pEnd.Y));
    nLines  := Lang.Rescan(Lines, pStart.Y, pEnd.Y - pStart.Y + 1, SL);
    OverChr := (Msg = VK_CHAR) and OverWrite and (Length(Old) = 1) and (Length(New) = 1);
    if OverChr then
      S[ Pos ] := New[ 1 ]
    else
      S := StuffString(S, Pos, Length(Old), New);
    SameLines := pEnd.Y - pStart.Y + 1 = nLines;
    InvalidateLines(pStart.Y, ifthen(not Samelines, -1, pEnd.Y));
    pStart := PointByPos(Pos + Length(New));
    MoveCurrent(pStart, True, True);
    if not SameLines then
      UpdateScrollRange;
    Abort;
  end;
end;

procedure TCustomTextViewer.DoEdit(aMsg : DWORD; const aNew : string; aPos : DWORD = 0; const aOld : string = '');
var PHist : PHistRec;
begin
  if (AMsg <> VK_POS) and FReadOnly then
    Exit;
  New(PHist);
  with PHist^ do
  begin
    Msg := aMsg;
    New := aNew;
    Pos := aPos;
    Old := aOld;
    Over:= OverWrite;
  end;
  Hist.Add(PHist);
  if PHist^.Msg <> VK_POS then
    Apply;
end;

procedure THistList.DeleteLast;
var I : integer;
begin
  I := Count - 1;
  Dispose(Items[ I ]);
  Delete(I);
end;

destructor THistList.Destroy;
var I : integer;
begin
  for I := 0 to Count - 1 do
    Dispose(Items[ I ]);
  inherited;
end;

function THistList.GetItem(Index: Integer): PHistRec;
begin
  Result := PHistRec(inherited Items[Index]);
end;

procedure Register;
begin
  RegisterComponents('IT', [TTextViewer]);
end;

end.
