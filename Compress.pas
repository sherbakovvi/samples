unit Compress;

interface

uses Windows, Messages, SysUtils, Variants, Classes, Masks, ZLibEx;

type
  PCompressedItem = ^TCompressedItem;
  TCompressedItem = record
    Name : string;
    Position, Count, SrcCount : integer;
  end;

  TCompressor = class(TObject)
  private
    FileList  : TList;
    FStream   : TFileStream;
  public
    procedure   Compress(Mask : string);
    constructor Create(FileName : string);
    destructor  Destroy; override;
  end;

  TDeCompressor = class(TObject)
  private
    FileList  : TList;
    FStream   : TFileStream;
    FOnProgress: TNotifyEvent;
    FPosition : integer;
    FCompressedItem : PCompressedItem;
    procedure   DoProgress(Sender: TObject);
    procedure   DoDeCompress(Mask : string);
  public
    procedure   DeCompress(Mask : string);
    procedure   GetFiles(Mask : string; List : TStrings);
    constructor Create(FileName : string);
    destructor  Destroy; override;
    property    OnProgress: TNotifyEvent read FOnProgress write FOnProgress;
    property    CompressedItem : PCompressedItem read FCompressedItem;
    property    Position : integer read FPosition;
  end;

  TMyMemoryStream = class(TMemoryStream)
  public
    property Capacity;
  end;

implementation

{ TCompressor }

procedure TDeCompressor.GetFiles(Mask : string; List : TStrings);
var I : integer;
begin
  for I := 0 to FileList.Count - 1 do  with PCompressedItem(FileList[ I ])^ do
    if MatchesMask(Name, Mask) then
      List.Add(Name);
end;

procedure TDeCompressor.DoProgress(Sender: TObject);
begin
  if Assigned(OnProgress) then
  begin
    FPosition := (FStream.Position - CompressedItem.Position) * 100 div CompressedItem.SrcCount;
    OnProgress(Self);
  end;
end;

procedure TDeCompressor.DeCompress(Mask : string);
var MaskPtr : PChar;
    Ptr : PChar;
begin
  MaskPtr := PChar(Mask);
  while MaskPtr <> nil do
  begin
    Ptr := StrScan(MaskPtr, ';');
    if Ptr <> nil then
      Ptr^ := #0;
    DoDeCompress(MaskPtr);
    if Ptr <> nil then
    begin
      Ptr^ := ';';
      Inc(Ptr);
    end;
    MaskPtr := Ptr;
  end;
end;

procedure TDeCompressor.DoDeCompress(Mask : string);
var I : integer;
    Str : TFileStream;
    CmpStr : TZDeCompressionStream;
begin
  for I := 0 to FileList.Count - 1 do  with PCompressedItem(FileList[ I ])^ do
    if MatchesMask(Name, Mask) then
    begin
      FPosition := 0;
      FCompressedItem := PCompressedItem(FileList[ I ]);
      DoProgress(Self);
      FStream.Seek(Position, soBeginning);
      CmpStr := TZDeCompressionStream.Create(FStream);
      try
        CmpStr.OnProgress := DoProgress;
        Str := TFileStream.Create(Name, fmCreate);
        try
          Str.CopyFrom(CmpStr, SrcCount);
        finally
          Str.Free;
        end;
      finally
        CmpStr.Free;
      end;
    end;
end;

constructor TDeCompressor.Create(FileName: string);
var I, L, DirPos, Count : integer;
    Item : PCompressedItem;
begin
  inherited Create;
  FileList := TList.Create;
  FStream  := TFileStream.Create(FileName, fmOpenRead);
  FStream.Seek(-SizeOf(Integer), soEnd);
  FStream.Read(DirPos, SizeOf(DirPos));
  FStream.Seek(DirPos, soBeginning);
  FStream.Read(Count, SizeOf(Count));
  for I := 0 to Count - 1 do
  begin
    New(Item);
    FileList.Add(Item);
    FStream.Read(L, SizeOf(L));
    with Item^ do
    begin
      SetLength(Name, L);
      FStream.Read(Name[ 1 ], L);
      FStream.Read(Position, SizeOf(Position));
      FStream.Read(Count, SizeOf(Count));
      FStream.Read(SrcCount, SizeOf(SrcCount));
    end;
  end;
end;

procedure TCompressor.Compress(Mask : string);
var MaskPtr : PChar;
    Ptr : PChar;
    FileInfo : TSearchRec;
    Item : PCompressedItem;
begin
  MaskPtr := PChar(Mask);
  while MaskPtr <> nil do
  begin
    Ptr := StrScan (MaskPtr, ';');
    if Ptr <> nil then
      Ptr^ := #0;
    if FindFirst(MaskPtr, faArchive, FileInfo) = 0 then
    begin
      repeat
        New(Item);
        Item.Name := FileInfo.Name;
        FileList.Add(Item);
      until FindNext(FileInfo) <> 0;
      FindClose(FileInfo);
    end;
    if Ptr <> nil then
    begin
      Ptr^ := ';';
      Inc(Ptr);
    end;
    MaskPtr := Ptr;
  end;
end;

constructor TCompressor.Create(FileName: string);
begin
  inherited Create;
  FileList := TList.Create;
  FStream  := TFileStream.Create(FileName, fmCreate);
end;

destructor TCompressor.Destroy;
var I : integer;
    Str : TFileStream;
    CmpStr : TZCompressionStream;
    DirPos, L : integer;
begin
  for I := 0 to FileList.Count - 1 do with PCompressedItem(FileList[ I ])^ do
  begin
    Str := TFileStream.Create(Name, fmOpenRead);
    SrcCount := Str.Size;
    Position := FStream.Position;
    try
      CmpStr := TZCompressionStream.Create(FStream, zcDefault);
      try
        CmpStr.CopyFrom(Str, Str.Size);
      finally
        CmpStr.Free;
      end;
    finally
      Str.Free;
    end;
    Count := FStream.Position - Position;
  end;
  DirPos := FStream.Position;
  FStream.Write(FileList.Count, SizeOf(Integer));
  for I := 0 to FileList.Count - 1 do with PCompressedItem(FileList[ I ])^ do
  begin
    L := Length(Name);
    FStream.Write(L, SizeOf(Integer));
    FStream.Write(Name[ 1 ], L);
    FStream.Write(Position, SizeOf(Position));
    FStream.Write(Count, SizeOf(Count));
    FStream.Write(SrcCount, SizeOf(SrcCount));
    Dispose(FileList[ I ]);
  end;
  FStream.Write(DirPos, SizeOf(DirPos));
  FileList.Free;
  FStream.Free;
  inherited;
end;

destructor TDeCompressor.Destroy;
var I : integer;
begin
  for I := 0 to FileList.Count - 1 do
    Dispose(FileList[ I ]);
  FileList.Free;
  FStream.Free;
  inherited;
end;

end.
