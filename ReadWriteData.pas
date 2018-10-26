unit ReadWriteData;

interface

uses SysUtils, Variants, VarUtils, StrUtils, Math, ComObj,
     Classes, ActiveX, DB, DBClient, Logger, TypInfo, SConnect;
const
  asCallBack  = $15;   
  asPing      = $16;   
type
  PIntArray = ^TIntArray;
  TIntArray = array[0..0] of Integer;
  PVariantArray = ^TVariantArray;
  TVariantArray = array[0..0] of OleVariant;

  TVarFlag = (vfByRef, vfVariant);
  TVarFlags = set of TVarFlag;

//  PBytes = ^TBytes;
  function GetVariantPointer(const Value: OleVariant): Pointer;
  procedure CopyDataByRef(const Source: TVarData; var Dest: TVarData);
  function ReadArray(VType: Integer; const Data: IDataBlock): OleVariant;
  procedure WriteArray(const Value: OleVariant; const Data: IDataBlock);
  function ReadVariant(out Flags: TVarFlags; const Data: IDataBlock): OleVariant;
  procedure WriteVariant(const Value: OleVariant; const Data: IDataBlock);


implementation

const

  EasyArrayTypes = [varSmallInt, varInteger, varSingle, varDouble, varCurrency,
                    varDate, varBoolean, varByte];

  VariantSize: array[0..varByte] of Word  = (0, 0, SizeOf(SmallInt), SizeOf(Integer),
    SizeOf(Single), SizeOf(Double), SizeOf(Currency), SizeOf(TDateTime), 0, 0,
    SizeOf(Integer), SizeOf(WordBool), 0, 0, 0, 0, 0, SizeOf(Byte));

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

procedure CopyDataByRef(const Source: TVarData; var Dest: TVarData);
var
  VType: Integer;
begin
  VType := Source.VType;
  if Source.VType and varArray = varArray then
  begin
    VarClear(OleVariant(Dest));
    SafeArrayCheck(SafeArrayCopy(PSafeArray(Source.VArray), PSafeArray(Dest.VArray)));
  end else
    case Source.VType and varTypeMask of
      varEmpty, varNull: ;
      varOleStr:
      begin
        if (Dest.VType and varTypeMask) <> varOleStr then
          Dest.VOleStr := SysAllocString(Source.VOleStr)
        else if (Dest.VType and varByRef) = varByRef then
          SysReallocString(PBStr(Dest.VOleStr)^,Source.VOleStr)
        else
          SysReallocString(Dest.VOleStr,Source.VOleStr);
      end;
      varDispatch: Dest.VDispatch := Source.VDispatch;
      varVariant: CopyDataByRef(PVarData(Source.VPointer)^, Dest);
      varUnknown: Dest.VUnknown := Source.VUnknown;
    else
      if Dest.VType = 0 then
        OleVariant(Dest) := OleVariant(Source)
      else if Dest.VType and varByRef = varByRef then
      begin
        VType := VType or varByRef;
        Move(Source.VPointer, Dest.VPointer^, VariantSize[Source.VType and varTypeMask]);
      end
      else
        Move(Source.VPointer, Dest.VPointer, VariantSize[Source.VType and varTypeMask]);
    end;
  Dest.VType := VType;
end;

function ReadArray(VType: Integer; const Data: IDataBlock): OleVariant;
var
  Flags: TVarFlags;
  LoDim, HiDim, Indices, Bounds: PIntArray;
  DimCount, VSize, i: Integer;
  {P: Pointer;}
  V: OleVariant;
  LSafeArray: PSafeArray;
  P: Pointer;
begin
  VarClear(Result);
  Data.Read(DimCount, SizeOf(DimCount));
  VSize := DimCount * SizeOf(Integer);
  GetMem(LoDim, VSize);
  try
    GetMem(HiDim, VSize);
    try
      Data.Read(LoDim^, VSize);
      Data.Read(HiDim^, VSize);
      GetMem(Bounds, VSize * 2);
      try
        for i := 0 to DimCount - 1 do
        begin
          Bounds[i * 2] := LoDim[i];
          Bounds[i * 2 + 1] := HiDim[i];
        end;
        Result := VarArrayCreate(Slice(Bounds^,DimCount * 2), VType and varTypeMask);
      finally
        FreeMem(Bounds);
      end;
      if VType and varTypeMask in EasyArrayTypes then
      begin
        Data.Read(VSize, SizeOf(VSize));
        P := VarArrayLock(Result);
        try
          Data.Read(P^, VSize);
        finally
          VarArrayUnlock(Result);
        end;
      end else
      begin
        LSafeArray := PSafeArray(TVarData(Result).VArray);
        GetMem(Indices, VSize);
        try
          FillChar(Indices^, VSize, 0);
          for I := 0 to DimCount - 1 do
            Indices[I] := LoDim[I];
          while True do
          begin
            V := ReadVariant(Flags, Data);
            if VType and varTypeMask = varVariant then
              SafeArrayCheck(SafeArrayPutElement(LSafeArray, Indices^, V))
            else
              SafeArrayCheck(SafeArrayPutElement(LSafeArray, Indices^, TVarData(V).VPointer^));
            Inc(Indices[DimCount - 1]);
            if Indices[DimCount - 1] > HiDim[DimCount - 1] then
              for i := DimCount - 1 downto 0 do
                if Indices[i] > HiDim[i] then
                begin
                  if i = 0 then Exit;
                  Inc(Indices[i - 1]);
                  Indices[i] := LoDim[i];
                end;
          end;
        finally
          FreeMem(Indices);
        end;
      end;
    finally
      FreeMem(HiDim);
    end;
  finally
    FreeMem(LoDim);
  end;
end;

procedure WriteArray(const Value: OleVariant; const Data: IDataBlock);
var
  LVarData: TVarData;
  VType: Integer;
  VSize, i, DimCount, ElemSize: Integer;
  LSafeArray: PSafeArray;
  LoDim, HiDim, Indices: PIntArray;
  V: OleVariant;
  P: Pointer;
begin
  LVarData := FindVarData(Value)^;
  VType := LVarData.VType;
  LSafeArray := PSafeArray(LVarData.VPointer);

  Data.Write(VType, SizeOf(Integer));
  DimCount := VarArrayDimCount(Value);
  Data.Write(DimCount, SizeOf(DimCount));
  VSize := SizeOf(Integer) * DimCount;
  GetMem(LoDim, VSize);
  try
    GetMem(HiDim, VSize);
    try
      for i := 1 to DimCount do
      begin
        LoDim[i - 1] := VarArrayLowBound(Value, i);
        HiDim[i - 1] := VarArrayHighBound(Value, i);
      end;
      Data.Write(LoDim^,VSize);
      Data.Write(HiDim^,VSize);
      if VType and varTypeMask in EasyArrayTypes then
      begin
        ElemSize := SafeArrayGetElemSize(LSafeArray);
        VSize := 1;
        for i := 0 to DimCount - 1 do
          VSize := (HiDim[i] - LoDim[i] + 1) * VSize;
        VSize := VSize * ElemSize;
        P := VarArrayLock(Value);
        try
          Data.Write(VSize, SizeOf(VSize));
          Data.Write(P^,VSize);
        finally
          VarArrayUnlock(Value);
        end;
      end else
      begin
        GetMem(Indices, VSize);
        try
          for I := 0 to DimCount - 1 do
            Indices[I] := LoDim[I];
          while True do
          begin
            if VType and varTypeMask <> varVariant then
            begin
              SafeArrayCheck(SafeArrayGetElement(LSafeArray, Indices^, TVarData(V).VPointer));
              TVarData(V).VType := VType and varTypeMask;
            end else
              SafeArrayCheck(SafeArrayGetElement(LSafeArray, Indices^, V));
            WriteVariant(V, Data);
            Inc(Indices[DimCount - 1]);
            if Indices[DimCount - 1] > HiDim[DimCount - 1] then
              for i := DimCount - 1 downto 0 do
                if Indices[i] > HiDim[i] then
                begin
                  if i = 0 then Exit;
                  Inc(Indices[i - 1]);
                  Indices[i] := LoDim[i];
                end;
          end;
        finally
          FreeMem(Indices);
        end;
      end;
    finally
      FreeMem(HiDim);
    end;
  finally
    FreeMem(LoDim);
  end;
end;

function ReadVariant(out Flags: TVarFlags; const Data: IDataBlock): OleVariant;
var
  I, VType: Integer;
  W: WideString;
  TmpFlags: TVarFlags;
begin
  VarClear(Result);
  Flags := [];
  Data.Read(VType, SizeOf(VType));
  if VType and varByRef = varByRef then
    Include(Flags, vfByRef);
  if VType = varByRef then
  begin
    Include(Flags, vfVariant);
    Result := ReadVariant(TmpFlags, Data);
    Exit;
  end;
  if vfByRef in Flags then
    VType := VType xor varByRef;
  if (VType and varArray) = varArray then
    Result := ReadArray(VType, Data) else
  case VType and varTypeMask of
    varEmpty: VarClear(Result);
    varNull: Result := NULL;
    varOleStr:
    begin
      Data.Read(I, SizeOf(Integer));
      SetLength(W, I);
      Data.Read(W[1], I * 2);
      Result := W;
    end;
    varDispatch, varUnknown:
      raise EInterpreterError.Create('BadVariantType = ' + IntToHex(VType,4));
  else
    TVarData(Result).VType := VType;
    Data.Read(TVarData(Result).VPointer, VariantSize[VType and varTypeMask]);
  end;
end;

procedure WriteVariant(const Value: OleVariant; const Data: IDataBlock);
var
  I, VType: Integer;
  W: WideString;
begin
  VType := VarType(Value);
  if VType and varArray <> 0 then
    WriteArray(Value, Data)
  else
    case (VType and varTypeMask) of
      varEmpty, varNull:
        Data.Write(VType, SizeOf(Integer));
      varOleStr:
      begin
        W := WideString(Value);
        I := Length(W);
        Data.Write(VType, SizeOf(Integer));
        Data.Write(I,SizeOf(Integer));
        Data.Write(W[1], I * 2);
      end;
      varDispatch:
        raise EInterpreterError.Create('BadVariantType = '+ IntToHex(VType,4));
      varVariant:
      begin
        if VType and varByRef <> varByRef then
          raise EInterpreterError.Create('BadVariantType = '+ IntToHex(VType,4));
        I := varByRef;
        Data.Write(I, SizeOf(Integer));
        WriteVariant(Variant(TVarData(Value).VPointer^), Data);
      end;
      varUnknown:
        raise EInterpreterError.Create('BadVariantType = ' + IntToHex(VType,4));
    else
      Data.Write(VType, SizeOf(Integer));
      if VType and varByRef = varByRef then
        Data.Write(TVarData(Value).VPointer^, VariantSize[VType and varTypeMask])
      else
        Data.Write(TVarData(Value).VPointer, VariantSize[VType and varTypeMask]);
    end;
end;

end.
